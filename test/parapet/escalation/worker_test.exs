defmodule Parapet.Escalation.WorkerTest do
  use ExUnit.Case, async: false

  alias Parapet.Spine.ActionClaim

  defmodule DummyRepo do
    def update(changeset, _opts \\ []) do
      send(self(), {:update, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def update!(changeset, _opts \\ []) do
      claim = Ecto.Changeset.apply_changes(changeset)
      put_claim(claim)
      claim
    end

    def insert(changeset, _opts \\ []) do
      send(self(), {:insert, changeset})
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    end

    def insert_all(ActionClaim, [attrs], opts) do
      key = claim_key(attrs.incident_id, attrs.action_kind, attrs.action_key)

      case get_claim(key) do
        nil ->
          claim =
            struct(ActionClaim, %{
              id: "claim-#{map_size(get_claims()) + 1}",
              incident_id: attrs.incident_id,
              action_kind: attrs.action_kind,
              action_key: attrs.action_key,
              status: attrs.status,
              idempotency_key: attrs.idempotency_key,
              attempt_count: attrs.attempt_count,
              claimed_at: attrs.claimed_at,
              finished_at: nil,
              short_circuit_reason: nil,
              last_error_kind: nil,
              last_error_message: nil,
              error_metadata: %{},
              inserted_at: attrs.inserted_at,
              updated_at: attrs.updated_at
            })

          put_claim(claim)

          if opts[:returning] do
            {1, [Map.take(Map.from_struct(claim), opts[:returning])]}
          else
            {1, []}
          end

        _claim ->
          {0, []}
      end
    end

    def transaction(%Ecto.Multi{} = multi) do
      multi
      |> Ecto.Multi.to_list()
      |> Enum.reduce_while({:ok, %{}}, fn
        {name, {:update, %Ecto.Changeset{} = changeset, _opts}}, {:ok, acc} ->
          updated = Ecto.Changeset.apply_changes(changeset)

          if match?(%ActionClaim{}, updated) do
            put_claim(updated)
          end

          send(self(), {:update, changeset})
          {:cont, {:ok, Map.put(acc, name, updated)}}

        {name, {:insert, fun, _opts}}, {:ok, acc} ->
          changeset = fun.(acc)
          send(self(), {:insert, changeset})
          inserted = Ecto.Changeset.apply_changes(changeset)
          {:cont, {:ok, Map.put(acc, name, inserted)}}

        {name, {:run, fun}}, {:ok, acc} ->
          case fun.(__MODULE__, acc) do
            {:ok, value} -> {:cont, {:ok, Map.put(acc, name, value)}}
            {:error, error} -> {:halt, {:error, name, error, acc}}
          end
      end)
    end

    def transaction(fun) when is_function(fun, 0), do: {:ok, fun.()}

    def get(Parapet.Spine.Incident, "not-found"), do: nil

    def get(Parapet.Spine.Incident, "open-id"),
      do: %Parapet.Spine.Incident{id: "open-id", state: "open"}

    def get(Parapet.Spine.Incident, "suppressed-id"),
      do: %Parapet.Spine.Incident{
        id: "suppressed-id",
        state: "open",
        runbook_data: %{
          "escalation" => %{
            "suppressed_until" =>
              DateTime.utc_now() |> DateTime.add(600, :second) |> DateTime.truncate(:second),
            "suppressed_by" => "operator-1",
            "suppression_reason" => "stabilizing downstream"
          }
        }
      }

    def get(Parapet.Spine.Incident, "manual-trigger-id"),
      do: %Parapet.Spine.Incident{
        id: "manual-trigger-id",
        state: "open",
        runbook_data: %{
          "escalation" => %{
            "pending_trigger" => true,
            "triggered_by" => "operator-2",
            "trigger_reason" => "page the next responder",
            "trigger_requested_at" => ~U[2026-05-21 12:00:00Z]
          }
        }
      }

    def get(Parapet.Spine.Incident, "inv-id"),
      do: %Parapet.Spine.Incident{id: "inv-id", state: "investigating"}

    def get(Parapet.Spine.Incident, "res-id"),
      do: %Parapet.Spine.Incident{id: "res-id", state: "resolved"}

    def get!(schema, id), do: get(schema, id) || raise("not found")

    def one!(%Ecto.Query{from: %{source: {_source, Parapet.Spine.Incident}}, wheres: wheres}) do
      [incident_id] = extract_params(wheres)
      get!(Parapet.Spine.Incident, incident_id)
    end

    def one!(%Ecto.Query{from: %{source: {_source, ActionClaim}}, wheres: wheres}) do
      [incident_id, action_kind, action_key] = extract_params(wheres)
      get_claim(claim_key(incident_id, action_kind, action_key)) || raise("claim not found")
    end

    defp extract_params(wheres) do
      Enum.flat_map(wheres, fn where ->
        Enum.map(where.params, fn {value, _meta} -> value end)
      end)
    end

    defp claim_key(incident_id, action_kind, action_key) do
      {incident_id, action_kind, action_key}
    end

    defp get_claims do
      Process.get(:dummy_claims, %{})
    end

    defp get_claim(key), do: Map.get(get_claims(), key)

    defp put_claim(%ActionClaim{} = claim) do
      claims = get_claims()

      Process.put(
        :dummy_claims,
        Map.put(claims, claim_key(claim.incident_id, claim.action_kind, claim.action_key), claim)
      )
    end
  end

  defmodule SuccessPolicy do
    @behaviour Parapet.Escalation.Policy
    def escalate(_incident, _opts), do: {:ok, "success"}
  end

  defmodule ErrorPolicy do
    @behaviour Parapet.Escalation.Policy
    def escalate(_incident, _opts), do: {:error, "failed"}
  end

  defmodule ExceptionPolicy do
    @behaviour Parapet.Escalation.Policy
    def escalate(_incident, _opts), do: raise("boom")
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    Process.delete(:dummy_claims)

    on_exit(fn ->
      Application.delete_env(:parapet, :repo)
      Application.delete_env(:parapet, :escalation_policy)
      Process.delete(:dummy_claims)
    end)

    :ok
  end

  test "returns {:discard, reason} if incident not found" do
    assert {:discard, "Incident not-found not found"} =
             Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "not-found"}})
  end

  test "returns {:discard, reason} and appends timeline if state is investigating" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})

    assert {:discard, "Short-circuited (already investigating)"} =
             Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "inv-id"}})

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "inv-id"
    assert entry.type == "escalation_short_circuited"
    assert entry.payload["reason"] == "already_investigating"
  end

  test "returns {:discard, reason} and appends timeline if state is resolved" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})

    assert {:discard, "Short-circuited (already resolved)"} =
             Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "res-id"}})

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "res-id"
    assert entry.type == "escalation_short_circuited"
    assert entry.payload["reason"] == "already_resolved"
  end

  test "short-circuits when a suppression window is active" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})

    assert {:discard, "Short-circuited (suppressed)"} =
             Parapet.Escalation.Worker.perform(%Oban.Job{
               args: %{"incident_id" => "suppressed-id"}
             })

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "suppressed-id"
    assert entry.type == "escalation_short_circuited"
    assert entry.payload["reason"] == "suppressed"
    assert entry.payload["suppressed_by"] == "operator-1"
    assert entry.payload["suppression_reason"] == "stabilizing downstream"
    assert %DateTime{} = entry.payload["suppressed_until"]
  end

  test "executes policy when state is open and returns :ok on success" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})

    assert :ok = Parapet.Escalation.Worker.perform(%Oban.Job{args: %{"incident_id" => "open-id"}})

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "open-id"
    assert entry.type == "escalation_executed"
    assert entry.payload["status"] == "success"
    assert entry.payload["details"] == inspect("success")
    assert entry.payload["mode"] == "scheduled"
    assert entry.payload["idempotency_key"] == "escalation_open-id_scheduled:default"
    assert entry.payload["action_key"] == "scheduled:default"
  end

  test "manual trigger execution records manual chronology without bypassing the worker" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})

    assert :ok =
             Parapet.Escalation.Worker.perform(%Oban.Job{
               args: %{"incident_id" => "manual-trigger-id"}
             })

    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.incident_id == "manual-trigger-id"
    assert entry.type == "escalation_executed"
    assert entry.payload["status"] == "success"
    assert entry.payload["mode"] == "manual"
    assert entry.payload["triggered_by"] == "operator-2"
    assert entry.payload["trigger_reason"] == "page the next responder"
    assert entry.payload["action_key"] == "manual:2026-05-21T12:00:00Z"
  end

  test "manual trigger execution consumes pending trigger state before later worker runs" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})

    assert :ok =
             Parapet.Escalation.Worker.perform(%Oban.Job{
               args: %{"incident_id" => "manual-trigger-id"}
             })

    assert_received {:update, claim_changeset}
    _claim = Ecto.Changeset.apply_changes(claim_changeset)
    assert_received {:update, incident_changeset}
    updated_incident = Ecto.Changeset.apply_changes(incident_changeset)
    escalation = get_in(updated_incident.runbook_data, ["escalation"])

    refute Map.has_key?(escalation, "pending_trigger")
    refute Map.has_key?(escalation, "triggered_by")
    refute Map.has_key?(escalation, "trigger_reason")
    refute Map.has_key?(escalation, "trigger_requested_at")
  end

  test "persists retryable failures with a typed outcome" do
    Application.put_env(:parapet, :escalation_policy, {ErrorPolicy, []})

    assert {:error, details} =
             Parapet.Escalation.Worker.perform(%Oban.Job{
               args: %{"incident_id" => "open-id"},
               attempt: 1,
               max_attempts: 3
             })

    assert details == inspect("failed")

    assert_received {:update, _claim_changeset}
    assert_received {:update, _incident_changeset}
    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.type == "escalation_failed_retryable"
    assert entry.payload["status"] == "error"
    assert entry.payload["error_kind"] == "policy_error"
  end

  test "persists terminal failures with a typed outcome" do
    Application.put_env(:parapet, :escalation_policy, {ExceptionPolicy, []})

    assert {:discard, "Terminal escalation failure: boom"} =
             Parapet.Escalation.Worker.perform(%Oban.Job{
               args: %{"incident_id" => "open-id"},
               attempt: 3,
               max_attempts: 3
             })

    assert_received {:update, _claim_changeset}
    assert_received {:update, _incident_changeset}
    assert_received {:insert, changeset}
    entry = Ecto.Changeset.apply_changes(changeset)
    assert entry.type == "escalation_failed_terminal"
    assert entry.payload["status"] == "error"
    assert entry.payload["error_kind"] == "exception"
    assert entry.payload["details"] == "boom"
  end
end
