defmodule Parapet.Operator.ConfirmConcurrencyTest do
  @moduledoc """
  Multi-node race proof for the operator-confirm path (UI-02 + UI-04).

  Two operators take the same Preview and race a Confirm against the same
  `(incident_id, action_kind: "operator", action_key: "op_step")` claim row.
  Exactly one must see `{:ok, _}` (the winner; ClaimService awards the claim,
  capability.execute runs, mark_executed flips the row to "executed"), and
  exactly one must see `{:conflicted, claim_id}` (the loser; ClaimService's
  insert_all hits the unique constraint, the row already exists). The
  `claim_id` in the conflict tuple matches the winner's DB row.

  Uses the established multi-node test harness:
  `Parapet.TestSupport.ConcurrencyCase` + `unboxed_run` + `Task.async`
  rendezvous + `:go` broadcast — the same pattern proven by
  `test/parapet/automation/executor_concurrency_test.exs` (the Oban auto-exec
  path's claim test) and `test/parapet/automation/claim_service_test.exs`
  (the ClaimService-direct test).
  """
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Operator
  alias Parapet.Operator.ActionPayload
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry}

  @concurrency_hold_ms 75

  defmodule ConcurrencyRunbook do
    @moduledoc false
    # The operator path uses the Recovery capability registered via
    # `Parapet.Capabilities.register_recovery/2` (NOT the Runbook's
    # `execute_mitigation/2` callback — that's for the Oban auto-exec path).
    # The inline runbook only declares the step shape.
    use Parapet.Runbook

    step(:op_step,
      type: :mitigation,
      capability: :retry_async_item,
      target_kind: "async_item"
    )
  end

  @tag :unboxed
  test "two operators racing Confirm produce exactly one execution and one conflict" do
    Application.put_env(:parapet, :automation, max_executions: 3, within: 3600)
    Application.put_env(:parapet, :operator_test_pid, self())

    on_exit(fn ->
      Application.delete_env(:parapet, :automation)
      Application.delete_env(:parapet, :operator_test_pid)
      Application.delete_env(:parapet, :repo)
    end)

    {incident, preview_token} =
      unboxed_run(fn ->
        ConcurrencyBootstrap.reset!()

        # CRITICAL (Pitfall 4): ConcurrencyCase resets DB tables only; the
        # Parapet.Capabilities Agent is process-global and survives between
        # tests. Explicitly clear it before registering this test's
        # capability to avoid leak-from-prior-test flakes.
        Parapet.Capabilities.checkout()

        Parapet.Capabilities.register_recovery(:retry_async_item,
          name: "Retry Async Item",
          target_kind: "async_item",
          preview: fn _incident, _step ->
            {:ok, %{"target_refs" => ["item-1"]}}
          end,
          execute: fn _incident, _refs ->
            if pid = Application.get_env(:parapet, :operator_test_pid) do
              send(pid, {:executed, node()})
            end

            # INTENTIONAL HOLD: keeps the winner mid-execute so the loser's claim_action/1 races the unique-constraint insert.
            # NOT a lazy wait — do not replace with assert_eventually/the start-barrier.
            Process.sleep(@concurrency_hold_ms)
            {:ok, :executed}
          end
        )

        {:ok, incident} =
          %Incident{}
          |> Incident.changeset(%{
            title: "Operator-confirm race",
            correlation_key: "corr-operator-race",
            runbook_data: %{"module" => to_string(ConcurrencyRunbook)}
          })
          |> ConcurrencyRepo.insert()

        preview_payload = %ActionPayload{
          actor: "operator_ui",
          reason: "Preview before race",
          correlation_id: "corr-preview",
          action_type: :preview_mitigation
        }

        {:ok, %{preview: preview}} =
          Operator.preview_runbook_step(incident, :op_step, preview_payload)

        {incident, preview["preview_token"]}
      end)

    parent = self()

    # Both contenders use the SAME idempotency_key — that's what makes them
    # race for the SAME (incident_id, action_kind, action_key) unique-constraint
    # row in parapet_action_claims. Different keys would not collide.
    shared_idempotency_key = "operator_confirm_#{incident.id}_op_step"

    contenders =
      for _ <- 1..2 do
        Task.async(fn ->
          unboxed_run(fn ->
            payload = %ActionPayload{
              actor: "operator_ui",
              reason: "Confirm",
              correlation_id: "corr-confirm-#{System.unique_integer([:positive])}",
              idempotency_key: shared_idempotency_key,
              action_type: :execute_mitigation
            }

            send(parent, {:ready, self()})

            receive do
              :go ->
                Operator.confirm_runbook_step(incident, :op_step, preview_token, payload)
            end
          end)
        end)
      end

    for _ <- 1..2 do
      assert_receive {:ready, _pid}, 1_000
    end

    Enum.each(contenders, fn task -> send(task.pid, :go) end)

    results = Enum.map(contenders, &Task.await(&1, 5_000))

    assert Enum.count(results, &match?({:ok, _}, &1)) == 1,
           "expected exactly one {:ok, _} winner, got: #{inspect(results)}"

    assert Enum.count(results, &match?({:conflicted, _}, &1)) == 1,
           "expected exactly one {:conflicted, _} loser, got: #{inspect(results)}"

    # Exactly one execute side-effect — the winner's capability.execute
    # callback fired, the loser's never did (claim conflict short-circuited
    # before reaching capability.execute).
    assert_receive {:executed, _node}, 1_000
    refute_receive {:executed, _node}, 200

    # The conflicted claim_id is a UUID string — it matches the winner's
    # claim row in parapet_action_claims. Confirms the public 2-tuple
    # wrap-from-internal-3-tuple translation at the operator-API boundary.
    [{:conflicted, conflicted_claim_id}] =
      Enum.filter(results, &match?({:conflicted, _}, &1))

    assert is_binary(conflicted_claim_id),
           "conflict claim_id must be a UUID string, got: #{inspect(conflicted_claim_id)}"

    unboxed_run(fn ->
      claim = ConcurrencyRepo.get(ActionClaim, conflicted_claim_id)

      assert claim != nil,
             "winner's claim row must exist at id=#{conflicted_claim_id}"

      # The claim_id surfaced to the loser maps to the WINNER's row — the
      # row that ClaimService awarded the claim to, which then transitioned
      # through mark_executed/1 to "executed".
      assert claim.status == "executed",
             "winner's claim must be in status=executed (after mark_executed); got: #{claim.status}"

      assert claim.action_kind == "operator",
             "operator-path claim must carry action_kind=\"operator\"; got: #{claim.action_kind}"

      assert claim.action_key == "op_step",
             "claim action_key must match the step id; got: #{claim.action_key}"

      # Sanity: there's only one row for this (incident_id, action_kind, action_key)
      # because the unique constraint at parapet_action_claims (incident_id,
      # action_kind, action_key) blocked the second insert.
      all_claims =
        ConcurrencyRepo.all(
          from(c in ActionClaim,
            where:
              c.incident_id == ^incident.id and c.action_kind == "operator" and
                c.action_key == "op_step"
          )
        )

      assert length(all_claims) == 1,
             "unique constraint must keep exactly one claim row; got: #{length(all_claims)}"

      # AUD-03 negative: the conflict arm must write zero recovery TimelineEntries.
      # If the loser regressed and wrote one, the count here would be 2.
      recovery_entries =
        ConcurrencyRepo.all(
          from(t in TimelineEntry,
            where:
              t.incident_id == ^incident.id and
                t.type in ["recovery_confirmed", "recovery_failed"]
          )
        )

      assert length(recovery_entries) == 1,
             "conflict arm must write no recovery TimelineEntry: expected exactly 1 (winner's recovery_confirmed), got #{length(recovery_entries)}"

      assert hd(recovery_entries).type == "recovery_confirmed"
    end)
  end
end
