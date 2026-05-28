defmodule Parapet.Operator.PreviewLifecycleTest do
  @moduledoc """
  Unit coverage for the Phase 25 short-circuit branches of
  `Parapet.Operator.confirm_runbook_step/4`:

    * `{:short_circuited, :preview_expired}` — preview's `expires_at` is past
    * `{:short_circuited, :target_refs_drift}` — stored `target_refs` no longer
      hash to the recorded `target_refs_hash`
    * Backward-compat — a stored preview without a `target_refs_hash` field
      (pre-Phase-25 write) skips the drift gate and proceeds normally

  Uses the same DummyRepo + `Process.put(:mock_entries, [entry])` mock pattern
  as `test/parapet/operator_test.exs:495-541`. This file is the canonical
  lifecycle home; the legacy assertion in operator_test.exs remains as a
  regression marker against accidental contract drift.
  """
  use ExUnit.Case, async: false

  alias Parapet.Operator
  alias Parapet.Operator.ActionPayload
  alias Parapet.Spine.{Incident, TimelineEntry}

  defmodule DummyRepo do
    @moduledoc false

    # Mirrors the DummyRepo in `test/parapet/operator_test.exs` (extended for
    # ClaimService's raw-fun transaction protocol). Pulled into this file so
    # the lifecycle tests stay decoupled from the legacy OperatorTest module
    # but share the same synchronous Process-dictionary-backed shape.

    def all(query) do
      send(self(), {:repo_all, query})

      source = query.from |> Map.fetch!(:source) |> elem(1)

      case source do
        Parapet.Spine.Incident -> Process.get(:mock_incidents, [])
        Parapet.Spine.TimelineEntry -> Process.get(:mock_entries, [])
        Parapet.Spine.ActionItem -> Process.get(:mock_action_items, [])
        _ -> []
      end
    end

    def one(_query), do: nil

    def one!(_query) do
      Process.get(:mock_incident) ||
        %Incident{
          id: Ecto.UUID.generate(),
          state: "open",
          updated_at: ~U[2026-05-10 10:00:00Z]
        }
    end

    def get!(Parapet.Spine.Incident, id) do
      Process.get(:mock_incident) ||
        %Incident{id: id, state: "open", updated_at: ~U[2026-05-10 10:00:00Z]}
    end

    def insert(changeset, _opts \\ []) do
      {:ok, Ecto.Changeset.apply_changes(changeset) |> Map.put(:id, Ecto.UUID.generate())}
    end

    def update!(changeset) do
      Ecto.Changeset.apply_changes(changeset)
    end

    def update(changeset, _opts \\ []) do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def insert_all(Parapet.Spine.ActionClaim, [attrs], _opts) do
      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      claim = %Parapet.Spine.ActionClaim{
        id: Ecto.UUID.generate(),
        incident_id: attrs.incident_id,
        action_kind: attrs.action_kind,
        action_key: attrs.action_key,
        status: attrs.status,
        idempotency_key: attrs.idempotency_key,
        attempt_count: attrs.attempt_count,
        claimed_at: attrs.claimed_at,
        lease_until: attrs.lease_until,
        inserted_at: attrs[:inserted_at] || now,
        updated_at: attrs[:updated_at] || now,
        error_metadata: %{}
      }

      {1, [claim]}
    end

    def aggregate(_query, :count, :id), do: 0

    def transaction(fun) when is_function(fun, 0) do
      {:ok, fun.()}
    end

    def transaction(multi) do
      # Simulate Ecto's Postgres adapter raising (not {:error, _}) on a
      # connection failure, so CR-01 can assert the audit write is rescued.
      if Process.get(:raise_on_transaction_multi) do
        raise "simulated DB connection failure"
      end

      result =
        multi
        |> Ecto.Multi.to_list()
        |> Enum.reduce_while({:ok, %{}}, fn
          {name, {:update, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
            {:cont, {:ok, Map.put(acc, name, Ecto.Changeset.apply_changes(changeset))}}

          {name, {:insert, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
            {:cont,
             {:ok,
              Map.put(
                acc,
                name,
                Ecto.Changeset.apply_changes(changeset) |> Map.put(:id, Ecto.UUID.generate())
              )}}

          {name, {:insert, fun, _opts}}, {:ok, acc} ->
            struct =
              fun.(acc) |> Ecto.Changeset.apply_changes() |> Map.put(:id, Ecto.UUID.generate())

            {:cont, {:ok, Map.put(acc, name, struct)}}

          {name, {:run, fun}}, {:ok, acc} ->
            case fun.(__MODULE__, acc) do
              {:ok, value} -> {:cont, {:ok, Map.put(acc, name, value)}}
              {:error, error} -> {:halt, {:error, name, error, acc}}
            end
        end)

      # Capture any timeline_entry / tool_audit inserts for AUD-03 assertions.
      case result do
        {:ok, acc} when is_map_key(acc, :timeline_entry) ->
          existing = Process.get(:captured_writes, [])
          Process.put(:captured_writes, existing ++ [acc])

        _ ->
          :ok
      end

      result
    end
  end

  defmodule LifecycleRunbook do
    use Parapet.Runbook
    title("Preview Lifecycle Runbook")
    step(:retry, capability: :retry_async_item, target_kind: "async_item")
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    Process.put(:mock_incidents, [])
    Process.put(:mock_entries, [])
    Process.put(:mock_action_items, [])
    Process.put(:captured_writes, [])

    # Capabilities Agent is process-global — manually reset before each test
    # (Pitfall 4: ConcurrencyCase only resets DB tables; the unit harness
    # doesn't use ConcurrencyCase but the Agent is still shared with other
    # tests in the suite, so explicit reset keeps ordering hazards out).
    Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)

    Parapet.Capabilities.register_recovery(:retry_async_item,
      name: "Retry Item",
      target_kind: "async_item",
      preview: fn _incident, _step -> {:ok, %{"target_refs" => ["item-a", "item-b"]}} end,
      execute: fn _incident, _refs -> {:ok, :executed} end
    )

    {:ok, payload} =
      ActionPayload.changeset(%ActionPayload{}, %{
        actor: "user_1",
        reason: "lifecycle test",
        correlation_id: "req_lifecycle",
        action_type: :execute_mitigation,
        idempotency_key: "idem_lifecycle"
      })
      |> Ecto.Changeset.apply_action(:insert)

    incident = %Incident{
      id: Ecto.UUID.generate(),
      state: "open",
      runbook_data: %{"module" => to_string(LifecycleRunbook)}
    }

    # Stash the incident for DummyRepo.one!/1 (used by ClaimService's
    # lock_incident path on the happy-path/backward-compat test).
    Process.put(:mock_incident, incident)

    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
      Process.delete(:mock_incident)
      Process.delete(:mock_entries)
      Process.delete(:captured_writes)
    end)

    %{payload: payload, incident: incident}
  end

  test "confirm_runbook_step returns :short_circuited with :preview_expired for expired tokens",
       %{payload: payload, incident: incident} do
    {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
    token = preview["preview_token"]

    expired_preview =
      Map.put(preview, "expires_at", DateTime.utc_now() |> DateTime.add(-10, :second))

    expired_entry = %TimelineEntry{
      incident_id: incident.id,
      type: "recovery_preview",
      payload: expired_preview,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [expired_entry])

    assert {:short_circuited, :preview_expired} =
             Operator.confirm_runbook_step(incident, :retry, token, payload)

    # AUD-03 negative: short-circuit arms write NO recovery_confirmed or recovery_failed entries
    captured = Process.get(:captured_writes, [])
    refute Enum.any?(captured, fn acc ->
      entry = Map.get(acc, :timeline_entry)
      entry && entry.type in ["recovery_confirmed", "recovery_failed"]
    end)
  end

  test "confirm_runbook_step returns :short_circuited with :target_refs_drift when stored target_refs no longer match recorded hash",
       %{payload: payload, incident: incident} do
    {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
    token = preview["preview_token"]

    # Sanity: the preview Phase 25 wrote includes a target_refs_hash.
    assert is_binary(preview["target_refs_hash"])
    assert preview["target_refs"] == ["item-a", "item-b"]

    # Tamper with target_refs post-write but keep the original target_refs_hash.
    # When confirm_runbook_step recomputes the hash over `["tampered-ref"]`
    # the result must differ from the stored hash → :target_refs_drift.
    tampered = Map.put(preview, "target_refs", ["tampered-ref"])

    entry = %TimelineEntry{
      incident_id: incident.id,
      type: "recovery_preview",
      payload: tampered,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [entry])

    assert {:short_circuited, :target_refs_drift} =
             Operator.confirm_runbook_step(incident, :retry, token, payload)
  end

  test "confirm_runbook_step skips the drift gate when stored preview lacks target_refs_hash (legacy preview compat)",
       %{payload: payload, incident: incident} do
    {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
    token = preview["preview_token"]

    # Simulate a pre-Phase-25 stored preview by deleting the hash field. The
    # drift gate's nil-safe guard at operator.ex:712 must skip the comparison
    # and the confirm path proceeds (open-state incident, gates pass, ClaimService
    # wins the claim, capability.execute returns {:ok, :executed}).
    legacy_preview = Map.delete(preview, "target_refs_hash")

    entry = %TimelineEntry{
      incident_id: incident.id,
      type: "recovery_preview",
      payload: legacy_preview,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [entry])

    result = Operator.confirm_runbook_step(incident, :retry, token, payload)

    # The exact non-error return depends on the capability's execute return,
    # but the drift gate MUST NOT short-circuit when the stored hash is nil.
    refute match?({:short_circuited, :target_refs_drift}, result),
           "legacy preview without target_refs_hash must not short-circuit on drift, got: #{inspect(result)}"

    # With DummyRepo's "first caller wins" insert_all stub the happy path runs
    # to completion: ClaimService wins, capability.execute returns {:ok, :executed},
    # Evidence.run_operator_command writes the recovery_confirmed TimelineEntry.
    assert {:ok, %{timeline_entry: %TimelineEntry{type: "recovery_confirmed"}}} = result
  end

  test "confirm_runbook_step succeeds while the incident is investigating (CR-01: ack-then-confirm)",
       %{payload: payload, incident: incident} do
    # An operator typically Acknowledges (state -> "investigating") before
    # Confirming. The claim must still be granted: confirm_runbook_step passes
    # allowed_states: ["open", "investigating"] so the ClaimService state gate
    # does NOT short-circuit. Regression guard for the CR-01 happy-path break.
    investigating = %{incident | state: "investigating"}
    Process.put(:mock_incident, investigating)

    {:ok, %{preview: preview}} = Operator.preview_runbook_step(investigating, :retry, payload)
    token = preview["preview_token"]

    entry = %TimelineEntry{
      incident_id: investigating.id,
      type: "recovery_preview",
      payload: preview,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [entry])

    assert {:ok, %{timeline_entry: %TimelineEntry{type: "recovery_confirmed"}}} =
             Operator.confirm_runbook_step(investigating, :retry, token, payload)
  end

  test "confirm_runbook_step short-circuits :incident_resolved when the incident is resolved",
       %{payload: payload, incident: incident} do
    # "resolved" is NOT in the operator allowed_states, so the gate short-circuits
    # with "already_resolved" -> :incident_resolved. This is the honest case the
    # :incident_resolved reason is meant for (contrast with CR-01's investigating).
    resolved = %{incident | state: "resolved"}
    Process.put(:mock_incident, resolved)

    {:ok, %{preview: preview}} = Operator.preview_runbook_step(resolved, :retry, payload)
    token = preview["preview_token"]

    entry = %TimelineEntry{
      incident_id: resolved.id,
      type: "recovery_preview",
      payload: preview,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [entry])

    assert {:short_circuited, :incident_resolved} =
             Operator.confirm_runbook_step(resolved, :retry, token, payload)
  end

  test "confirm_runbook_step returns the capability error and releases the claim on execute failure (CR-02)",
       %{payload: payload, incident: incident} do
    Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)

    Parapet.Capabilities.register_recovery(:retry_async_item,
      name: "Retry Item",
      target_kind: "async_item",
      preview: fn _incident, _step -> {:ok, %{"target_refs" => ["item-a"]}} end,
      execute: fn _incident, _refs -> {:error, :provider_unavailable} end
    )

    {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
    token = preview["preview_token"]

    entry = %TimelineEntry{
      incident_id: incident.id,
      type: "recovery_preview",
      payload: preview,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [entry])

    assert {:error, :provider_unavailable} =
             Operator.confirm_runbook_step(incident, :retry, token, payload)

    # AUD-03: a recovery_failed TimelineEntry + ToolAudit with success: false
    # are written before mark_failed (best-effort; captured via DummyRepo harness).
    captured = Process.get(:captured_writes, [])
    failed_write = Enum.find(captured, fn acc ->
      entry = Map.get(acc, :timeline_entry)
      entry && entry.type == "recovery_failed"
    end)
    assert failed_write != nil, "expected a recovery_failed write to be captured"
    assert failed_write.timeline_entry.type == "recovery_failed"
    assert failed_write.timeline_entry.payload["outcome"]["status"] == "failed"
    assert failed_write.tool_audit.success == false
    assert failed_write.tool_audit.output["status"] == "failed"
  end

  test "confirm_runbook_step releases the claim even when the failure-path audit write raises (CR-01 regression)",
       %{payload: payload, incident: incident} do
    Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)

    Parapet.Capabilities.register_recovery(:retry_async_item,
      name: "Retry Item",
      target_kind: "async_item",
      preview: fn _incident, _step -> {:ok, %{"target_refs" => ["item-a"]}} end,
      execute: fn _incident, _refs -> {:error, :provider_unavailable} end
    )

    {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
    token = preview["preview_token"]

    entry = %TimelineEntry{
      incident_id: incident.id,
      type: "recovery_preview",
      payload: preview,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [entry])

    # A raising DB error during the best-effort audit write must NOT prevent
    # ClaimService.mark_failed/2 from running: confirm_runbook_step/4 still
    # returns the original error rather than propagating the raise.
    Process.put(:raise_on_transaction_multi, true)

    assert {:error, :provider_unavailable} =
             Operator.confirm_runbook_step(incident, :retry, token, payload)
  end

  test "confirm_runbook_step converts a raised capability into a structured error (CR-03)",
       %{payload: payload, incident: incident} do
    Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)

    Parapet.Capabilities.register_recovery(:retry_async_item,
      name: "Retry Item",
      target_kind: "async_item",
      preview: fn _incident, _step -> {:ok, %{"target_refs" => ["item-a"]}} end,
      execute: fn _incident, _refs -> raise "boom from host" end
    )

    {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
    token = preview["preview_token"]

    entry = %TimelineEntry{
      incident_id: incident.id,
      type: "recovery_preview",
      payload: preview,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [entry])

    assert {:error, {:capability_raised, message}} =
             Operator.confirm_runbook_step(incident, :retry, token, payload)

    assert message =~ "boom from host"

    # AUD-03: raised capability also produces a recovery_failed write;
    # the {:capability_raised, msg} reason is normalized via inspect/1.
    captured = Process.get(:captured_writes, [])
    failed_write = Enum.find(captured, fn acc ->
      entry = Map.get(acc, :timeline_entry)
      entry && entry.type == "recovery_failed"
    end)
    assert failed_write != nil, "expected a recovery_failed write for the raised capability"
    assert failed_write.timeline_entry.type == "recovery_failed"
    assert failed_write.tool_audit.success == false
    reason_str = failed_write.timeline_entry.payload["outcome"]["reason"]
    assert reason_str =~ "capability_raised", "reason should contain capability_raised, got: #{reason_str}"
  end

  test "target_refs canonicalization is stable across atom-vs-string round-trip (Pitfall 5 regression guard)",
       %{payload: payload, incident: incident} do
    # The capability for this test returns atom target_refs; compute_preview/3
    # stringifies host_data KEYS but NOT VALUES, so the hash is computed over
    # the atoms in-memory. After jsonb round-trip the stored target_refs would
    # appear as strings; the canonicalization in target_refs_hash/1
    # (`Enum.map(&to_string/1) |> Enum.sort`) must produce the same hash for
    # `[:item_a, :item_b]` and `["item_a", "item_b"]`.
    Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)

    Parapet.Capabilities.register_recovery(:retry_async_item,
      name: "Retry Item",
      target_kind: "async_item",
      preview: fn _incident, _step -> {:ok, %{"target_refs" => [:item_a, :item_b]}} end,
      execute: fn _incident, _refs -> {:ok, :executed} end
    )

    {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :retry, payload)
    token = preview["preview_token"]

    # Simulate the jsonb round-trip by replacing atom target_refs with the
    # stringified equivalents. The recomputed hash on confirm must match the
    # original stored hash → no :target_refs_drift.
    rehydrated =
      Map.put(preview, "target_refs", ["item_a", "item_b"])

    entry = %TimelineEntry{
      incident_id: incident.id,
      type: "recovery_preview",
      payload: rehydrated,
      inserted_at: DateTime.utc_now()
    }

    Process.put(:mock_entries, [entry])

    result = Operator.confirm_runbook_step(incident, :retry, token, payload)

    refute match?({:short_circuited, :target_refs_drift}, result),
           "atom-vs-string round-trip must not trip the drift gate, got: #{inspect(result)}"

    assert {:ok, %{timeline_entry: %TimelineEntry{type: "recovery_confirmed"}}} = result
  end
end
