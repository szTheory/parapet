defmodule Parapet.Automation.ExecutorConcurrencyTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Automation.Executor
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry, ToolAudit}

  defmodule ConcurrencyRunbook do
    use Parapet.Runbook

    step(:auto_step,
      type: :mitigation,
      auto_execute: true
    )

    def execute_mitigation(:auto_step, _incident) do
      if pid = Application.get_env(:parapet, :executor_test_pid) do
        send(pid, {:mitigated, node()})
      end

      Process.sleep(75)
      {:ok, :mitigated}
    end
  end

  @tag :unboxed
  test "concurrent executor attempts produce one executed effect path and one conflict no-op" do
    Application.put_env(:parapet, :automation, max_executions: 3, within: 3600)
    Application.put_env(:parapet, :executor_test_pid, self())

    on_exit(fn ->
      Application.delete_env(:parapet, :automation)
      Application.delete_env(:parapet, :executor_test_pid)
      Application.delete_env(:parapet, :repo)
    end)

    incident =
      unboxed_run(fn ->
        ConcurrencyBootstrap.reset!()

        {:ok, incident} =
          %Incident{}
          |> Incident.changeset(%{
            title: "Concurrent automation",
            correlation_key: "corr-concurrency",
            runbook_data: %{"module" => to_string(ConcurrencyRunbook)}
          })
          |> ConcurrencyRepo.insert()

        incident
      end)

    parent = self()
    job = %Oban.Job{args: %{"incident_id" => incident.id, "step_id" => "auto_step"}}

    contenders =
      for _ <- 1..2 do
        Task.async(fn ->
          unboxed_run(fn ->
            send(parent, {:ready, self()})

            receive do
              :go -> Executor.perform(job)
            end
          end)
        end)
      end

    for _ <- 1..2 do
      assert_receive {:ready, _pid}, 1_000
    end

    Enum.each(contenders, fn task -> send(task.pid, :go) end)

    results = Enum.map(contenders, &Task.await(&1, 5_000))

    assert Enum.count(results, &(&1 == :ok)) == 1

    assert Enum.count(results, fn
             {:discard, "Automation claim conflicted for step auto_step"} -> true
             _ -> false
           end) == 1

    assert_receive {:mitigated, _node}, 1_000
    refute_receive {:mitigated, _node}, 200

    unboxed_run(fn ->
      claims =
        ConcurrencyRepo.all(
          from(claim in ActionClaim,
            where:
              claim.incident_id == ^incident.id and claim.action_kind == "automation" and
                claim.action_key == "auto_step"
          )
        )

      assert length(claims) == 1
      assert hd(claims).status == "executed"
      assert hd(claims).idempotency_key == "auto_exec_#{incident.id}_auto_step"

      timeline_types =
        ConcurrencyRepo.all(
          from(entry in TimelineEntry,
            where: entry.incident_id == ^incident.id,
            select: entry.type
          )
        )

      assert Enum.count(timeline_types, &(&1 == "mitigation_executed")) == 1
      assert Enum.count(timeline_types, &(&1 == "automation_claim_conflicted")) == 1

      conflict_entry =
        ConcurrencyRepo.one!(
          from(entry in TimelineEntry,
            where: entry.incident_id == ^incident.id and entry.type == "automation_claim_conflicted"
          )
        )

      assert conflict_entry.payload == %{"step_id" => "auto_step"}

      executed_entry =
        ConcurrencyRepo.one!(
          from(entry in TimelineEntry,
            where: entry.incident_id == ^incident.id and entry.type == "mitigation_executed"
          )
        )

      assert executed_entry.payload["step_id"] == "auto_step"
      assert executed_entry.payload["actor"] == "system:automation:executor"

      assert ConcurrencyRepo.aggregate(ToolAudit, :count, :id) == 1

      audit =
        ConcurrencyRepo.one!(
          from(audit in ToolAudit,
            select: %{tool_name: audit.tool_name, input: audit.input}
          )
        )

      assert audit.tool_name == "operator_execute_mitigation"
      assert audit.input["idempotency_key"] == "auto_exec_#{incident.id}_auto_step"
    end)
  end
end
