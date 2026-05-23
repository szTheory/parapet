defmodule Parapet.Automation.ClaimServiceTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Automation.ClaimService
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry, ToolAudit}

  @tag :unboxed
  test "one concurrent caller wins the logical claim and the loser is conflicted" do
    Application.put_env(:parapet, :automation, max_executions: 3, within: 3600)

    on_exit(fn ->
      Application.delete_env(:parapet, :automation)
      Application.delete_env(:parapet, :repo)
    end)

    incident =
      unboxed_run(fn ->
        ConcurrencyBootstrap.reset!()

        {:ok, incident} =
          %Incident{}
          |> Incident.changeset(%{title: "Racing mitigation"})
          |> ConcurrencyRepo.insert()

        incident
      end)

    parent = self()

    contenders =
      for _ <- 1..2 do
        Task.async(fn ->
          unboxed_run(fn ->
            send(parent, {:ready, self()})

            receive do
              :go -> :ok
            end

            ClaimService.claim_action(
              incident_id: incident.id,
              action_kind: "automation",
              action_key: "step-1",
              breaker_step_id: "step-1",
              idempotency_key: "auto_exec_#{incident.id}_step-1",
              gate: fn _repo, _incident, _claim ->
                Process.sleep(50)
                :ok
              end
            )
          end)
        end)
      end

    for _ <- 1..2 do
      assert_receive {:ready, _pid}, 1_000
    end

    Enum.each(contenders, fn task -> send(task.pid, :go) end)

    results = Enum.map(contenders, &Task.await(&1, 5_000))

    assert Enum.count(results, &match?({:won, %ActionClaim{}}, &1)) == 1
    assert Enum.count(results, &match?({:conflicted, %ActionClaim{}}, &1)) == 1

    unboxed_run(fn ->
      assert ConcurrencyRepo.aggregate(ActionClaim, :count, :id) == 1

      claim =
        ConcurrencyRepo.one!(
          from(claim in ActionClaim,
            where:
              claim.incident_id == ^incident.id and claim.action_kind == "automation" and
                claim.action_key == "step-1"
          )
        )

      assert claim.status == "claimed"
      assert claim.idempotency_key == "auto_exec_#{incident.id}_step-1"
    end)
  end

  @tag :unboxed
  test "short-circuits the winning claim when the breaker window is already exhausted" do
    Application.put_env(:parapet, :automation, max_executions: 1, within: 3600)

    on_exit(fn ->
      Application.delete_env(:parapet, :automation)
      Application.delete_env(:parapet, :repo)
    end)

    unboxed_run(fn ->
      ConcurrencyBootstrap.reset!()

      {:ok, incident} =
        %Incident{}
        |> Incident.changeset(%{title: "Breaker trip"})
        |> ConcurrencyRepo.insert()

      {:ok, timeline_entry} =
        %TimelineEntry{}
        |> TimelineEntry.changeset(%{
          incident_id: incident.id,
          type: "automation_executed",
          payload: %{
            "step_id" => "step-1",
            "idempotency_key" => "auto_exec_#{incident.id}_step-1"
          }
        })
        |> ConcurrencyRepo.insert()

      assert {:ok, _audit} =
               %ToolAudit{}
               |> ToolAudit.changeset(%{
                 timeline_entry_id: timeline_entry.id,
                 tool_name: "runbook_step",
                 input: %{"step_id" => "step-1"},
                 success: true
               })
               |> ConcurrencyRepo.insert()

      assert {:short_circuited, claim, "circuit_breaker_tripped"} =
               ClaimService.claim_action(
                 incident_id: incident.id,
                 action_kind: "automation",
                 action_key: "step-1",
                 breaker_step_id: "step-1",
                 idempotency_key: "auto_exec_#{incident.id}_step-1"
               )

      assert claim.status == "short_circuited"
      assert claim.short_circuit_reason == "circuit_breaker_tripped"
    end)
  end
end
