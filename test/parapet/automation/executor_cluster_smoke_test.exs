defmodule Parapet.Automation.ExecutorClusterSmokeTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Automation.Executor
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry, ToolAudit}

  defmodule ClusterRunbook do
    use Parapet.Runbook

    step(:auto_step,
      type: :mitigation,
      auto_execute: true
    )

    def execute_mitigation(:auto_step, _incident) do
      if pid = Application.get_env(:parapet, :executor_test_pid) do
        send(pid, {:cluster_mitigated, node()})
      end

      Process.sleep(75)
      {:ok, :mitigated}
    end
  end

  @tag :unboxed
  test "shared claim semantics survive one local-plus-peer race canary" do
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
            title: "Cluster canary",
            correlation_key: "corr-cluster",
            runbook_data: %{"module" => to_string(ClusterRunbook)}
          })
          |> ConcurrencyRepo.insert()

        incident
      end)

    case start_distributed_node_for_peer_canary() do
      {:ok, started_node?} ->
        {:ok, peer, node} = :peer.start_link(%{name: :peer.random_name()})

        try do
          assert Node.ping(node) == :pong
          :ok = :erpc.call(node, :code, :add_paths, [:code.get_path()])
          {:ok, _apps} = :erpc.call(node, Application, :ensure_all_started, [:elixir])
          {:ok, _apps} = :erpc.call(node, Application, :ensure_all_started, [:ecto_sql])

          repo_keeper = """
          if Process.whereis(Parapet.TestSupport.ConcurrencyRepo) do
            :ok
          else
            spawn(fn ->
              Process.flag(:trap_exit, true)
              {:ok, _pid} =
                Parapet.TestSupport.ConcurrencyRepo.start_link(
                  Parapet.TestSupport.ConcurrencyRepo.database_config()
                )

              receive do
                :stop -> :ok
              end
            end)

            Process.sleep(200)
            :ok
          end
          """

          {_value, _binding} = :erpc.call(node, Code, :eval_string, [repo_keeper])

          :ok = :erpc.call(node, Application, :put_env, [:parapet, :repo, ConcurrencyRepo])

          :ok =
            :erpc.call(node, Application, :put_env, [:parapet, :automation, [max_executions: 3, within: 3600]])

          :ok = :erpc.call(node, Application, :put_env, [:parapet, :executor_test_pid, self()])

          remote_setup = """
          unless Code.ensure_loaded?(#{inspect(ClusterRunbook)}) do
            defmodule #{inspect(ClusterRunbook)} do
              use Parapet.Runbook

              step(:auto_step, type: :mitigation, auto_execute: true)

              def execute_mitigation(:auto_step, _incident) do
                if pid = Application.get_env(:parapet, :executor_test_pid) do
                  send(pid, {:cluster_mitigated, node()})
                end

                Process.sleep(75)
                {:ok, :mitigated}
              end
            end
          end
          """

          {_value, _binding} = :erpc.call(node, Code, :eval_string, [remote_setup])

          job = %Oban.Job{args: %{"incident_id" => incident.id, "step_id" => "auto_step"}}
          parent = self()

          local_task =
            Task.async(fn ->
              unboxed_run(fn ->
                send(parent, {:ready, :local})

                receive do
                  :go -> Executor.perform(job)
                end
              end)
            end)

          remote_task =
            Task.async(fn ->
              send(parent, {:ready, :peer})

              receive do
                :go ->
                  script = """
                  Ecto.Adapters.SQL.Sandbox.unboxed_run(Parapet.TestSupport.ConcurrencyRepo, fn ->
                    Parapet.Automation.Executor.perform(%Oban.Job{
                      args: %{"incident_id" => "#{incident.id}", "step_id" => "auto_step"}
                    })
                  end)
                  """

                  {result, _binding} = :erpc.call(node, Code, :eval_string, [script])
                  result
              end
            end)

          assert_receive {:ready, :local}, 1_000
          assert_receive {:ready, :peer}, 1_000

          send(local_task.pid, :go)
          send(remote_task.pid, :go)

          results = [Task.await(local_task, 5_000), Task.await(remote_task, 5_000)]

          assert Enum.count(results, &(&1 == :ok)) == 1

          assert Enum.count(results, fn
                   {:discard, "Automation claim conflicted for step auto_step"} -> true
                   _ -> false
                 end) == 1

          assert_receive {:cluster_mitigated, _node}, 1_000
          refute_receive {:cluster_mitigated, _node}, 200

          unboxed_run(fn ->
            claim =
              ConcurrencyRepo.one!(
                from(claim in ActionClaim,
                  where:
                    claim.incident_id == ^incident.id and claim.action_kind == "automation" and
                      claim.action_key == "auto_step"
                )
              )

            assert claim.status == "executed"
            assert claim.idempotency_key == "auto_exec_#{incident.id}_auto_step"

            timeline_types =
              ConcurrencyRepo.all(
                from(entry in TimelineEntry,
                  where: entry.incident_id == ^incident.id,
                  select: entry.type
                )
              )

            assert Enum.count(timeline_types, &(&1 == "mitigation_executed")) == 1
            assert Enum.count(timeline_types, &(&1 == "automation_claim_conflicted")) == 1
            assert ConcurrencyRepo.aggregate(ToolAudit, :count, :id) == 1
          end)
        after
          :peer.stop(peer)
          :ok = stop_distributed_node_for_peer_canary(started_node?)
        end

      {:skip, reason} ->
        assert reason != ""

        assert String.contains?(
                 reason,
                 "peer-node canary was skipped because distributed Erlang is unavailable in this environment"
               )

        assert String.contains?(reason, "DB-backed contention suite remains the closure-grade proof")
        refute_receive {:cluster_mitigated, _node}, 200
        assert String.contains?(reason, "SCALE-02")
    end
  end
end
