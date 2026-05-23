defmodule Parapet.Escalation.WorkerRetryTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Escalation.Worker
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry}

  defmodule FlakyPolicy do
    @behaviour Parapet.Escalation.Policy

    def escalate(_incident, opts) do
      agent = Application.fetch_env!(:parapet, :escalation_retry_agent)
      pid = Application.get_env(:parapet, :escalation_test_pid)

      attempt =
        Agent.get_and_update(agent, fn count ->
          next = count + 1
          {next, next}
        end)

      send(pid, {:policy_attempt, attempt, opts[:idempotency_key]})

      if attempt == 1 do
        {:error, :temporary_failure}
      else
        {:ok, :escalated}
      end
    end
  end

  setup do
    {:ok, agent} = Agent.start_link(fn -> 0 end)

    on_exit(fn ->
      if Process.alive?(agent) do
        Agent.stop(agent)
      end
    end)

    %{retry_agent: agent}
  end

  @tag :unboxed
  test "retry attempts resume the same durable claim and idempotency key", %{retry_agent: agent} do
    Application.put_env(:parapet, :escalation_policy, {FlakyPolicy, []})
    Application.put_env(:parapet, :escalation_retry_agent, agent)
    Application.put_env(:parapet, :escalation_test_pid, self())

    on_exit(fn ->
      Application.delete_env(:parapet, :escalation_policy)
      Application.delete_env(:parapet, :escalation_retry_agent)
      Application.delete_env(:parapet, :escalation_test_pid)
      Application.delete_env(:parapet, :repo)
    end)

    incident =
      unboxed_run(fn ->
        ConcurrencyBootstrap.reset!()

        {:ok, incident} =
          %Incident{}
          |> Incident.changeset(%{
            title: "Escalation retry",
            correlation_key: "corr-escalation-retry"
          })
          |> ConcurrencyRepo.insert()

        incident
      end)

    first_job = %Oban.Job{args: %{"incident_id" => incident.id}, attempt: 1, max_attempts: 3}
    retry_job = %Oban.Job{args: %{"incident_id" => incident.id}, attempt: 2, max_attempts: 3}

    assert {:error, details} = unboxed_run(fn -> Worker.perform(first_job) end)
    assert details == inspect(:temporary_failure)

    assert_receive {:policy_attempt, 1, idempotency_key}, 1_000
    assert idempotency_key == "escalation_#{incident.id}_scheduled:default"

    assert :ok = unboxed_run(fn -> Worker.perform(retry_job) end)

    assert_receive {:policy_attempt, 2, retry_idempotency_key}, 1_000
    assert retry_idempotency_key == idempotency_key

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
      assert claim.idempotency_key == idempotency_key

      timeline_types =
        ConcurrencyRepo.all(
          from(entry in TimelineEntry,
            where: entry.incident_id == ^incident.id,
            select: entry.type
          )
        )

      assert Enum.count(timeline_types, &(&1 == "escalation_failed_retryable")) == 1
      assert Enum.count(timeline_types, &(&1 == "escalation_executed")) == 1
    end)
  end
end
