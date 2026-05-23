defmodule Parapet.Escalation.WorkerConcurrencyTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Escalation.Worker
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry}

  defmodule SuccessPolicy do
    @behaviour Parapet.Escalation.Policy

    def escalate(_incident, opts) do
      if pid = Application.get_env(:parapet, :escalation_test_pid) do
        send(pid, {:escalated, node(), opts[:idempotency_key]})
      end

      Process.sleep(75)
      {:ok, :escalated}
    end
  end

  @tag :unboxed
  test "concurrent workers emit one alert path and one claim-conflicted no-op" do
    Application.put_env(:parapet, :escalation_policy, {SuccessPolicy, []})
    Application.put_env(:parapet, :escalation_test_pid, self())

    on_exit(fn ->
      Application.delete_env(:parapet, :escalation_policy)
      Application.delete_env(:parapet, :escalation_test_pid)
      Application.delete_env(:parapet, :repo)
    end)

    incident =
      unboxed_run(fn ->
        ConcurrencyBootstrap.reset!()

        {:ok, incident} =
          %Incident{}
          |> Incident.changeset(%{
            title: "Concurrent escalation",
            correlation_key: "corr-escalation"
          })
          |> ConcurrencyRepo.insert()

        incident
      end)

    job = %Oban.Job{args: %{"incident_id" => incident.id}, attempt: 1, max_attempts: 3}
    parent = self()

    contenders =
      for _ <- 1..2 do
        Task.async(fn ->
          unboxed_run(fn ->
            send(parent, {:ready, self()})

            receive do
              :go -> Worker.perform(job)
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
             {:discard, "Escalation claim conflicted"} -> true
             _ -> false
           end) == 1

    assert_receive {:escalated, _node, idempotency_key}, 1_000
    assert idempotency_key == "escalation_#{incident.id}_scheduled:default"
    refute_receive {:escalated, _node, _idempotency_key}, 200

    unboxed_run(fn ->
      claim =
        ConcurrencyRepo.one!(
          from(claim in ActionClaim,
            where:
              claim.incident_id == ^incident.id and claim.action_kind == "escalation" and
                claim.action_key == "scheduled:default"
          )
        )

      assert claim.status == "executed"
      assert claim.idempotency_key == "escalation_#{incident.id}_scheduled:default"

      timeline_types =
        ConcurrencyRepo.all(
          from(entry in TimelineEntry,
            where: entry.incident_id == ^incident.id,
            select: entry.type
          )
        )

      assert Enum.count(timeline_types, &(&1 == "escalation_executed")) == 1
      assert Enum.count(timeline_types, &(&1 == "escalation_claim_conflicted")) == 1
    end)
  end
end
