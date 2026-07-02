defmodule Parapet.Automation.ExecutorClusterSmokeTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query

  alias Parapet.Automation.Executor
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry, ToolAudit}

  defmodule ClusterRunbook do
    use Parapet.Runbook

    @concurrency_hold_ms 75

    step(:auto_step,
      type: :mitigation,
      auto_execute: true
    )

    def execute_mitigation(:auto_step, _incident) do
      if pid = Application.get_env(:parapet, :executor_test_pid) do
        send(pid, {:cluster_mitigated, node()})
      end

      # INTENTIONAL HOLD: keeps the winner mid-mitigate so the loser's claim insert races the unique constraint.
      # NOT a lazy wait — do not replace with assert_eventually/the start-barrier.
      Process.sleep(@concurrency_hold_ms)
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

            # Bounded SELECT 1 readiness barrier (D-07/D-08): poll until a
            # trivial query succeeds — Process.whereis is true before
            # DBConnection has any live connections (lazy/async pool), so only
            # a completing query is an honest readiness signal.
            # 5_000ms deadline, ~25ms backoff; raises with a DX message on
            # expiry naming the repo, peer node(), and the relevant DB env vars.
            ready? = fn ready?, deadline ->
              try do
                Ecto.Adapters.SQL.Sandbox.unboxed_run(
                  Parapet.TestSupport.ConcurrencyRepo,
                  fn ->
                    Ecto.Adapters.SQL.query!(
                      Parapet.TestSupport.ConcurrencyRepo,
                      "SELECT 1",
                      []
                    )
                  end
                )

                :ok
              rescue
                _ ->
                  if System.monotonic_time(:millisecond) >= deadline do
                    raise "Parapet.TestSupport.ConcurrencyRepo readiness check timed out " <>
                            "on peer node \#{node()}. " <>
                            "Verify DB reachability and env vars: " <>
                            "PARAPET_CONCURRENCY_DB_HOST, PARAPET_CONCURRENCY_DB_PORT, " <>
                            "PARAPET_CONCURRENCY_DB_NAME, PARAPET_CONCURRENCY_DB_USER."
                  else
                    Process.sleep(25)
                    ready?.(ready?, deadline)
                  end
              end
            end

            ready?.(ready?, System.monotonic_time(:millisecond) + 5_000)
            :ok
          end
          """

          {_value, _binding} = :erpc.call(node, Code, :eval_string, [repo_keeper])

          :ok = :erpc.call(node, Application, :put_env, [:parapet, :repo, ConcurrencyRepo])

          :ok =
            :erpc.call(node, Application, :put_env, [
              :parapet,
              :automation,
              [max_executions: 3, within: 3600]
            ])

          :ok = :erpc.call(node, Application, :put_env, [:parapet, :executor_test_pid, self()])

          # NOTE: The local ClusterRunbook above (~line 22) and this eval'd twin are deliberate
          # duplicates that must stay in sync: same hold duration and the same intentional-hold
          # annotation shape. The twin uses a literal Process.sleep(75) because @concurrency_hold_ms
          # is a compile-time module attribute that does not exist on the fresh peer node where this
          # string is eval'd (D-11).
          remote_setup = """
          unless Code.ensure_loaded?(#{inspect(ClusterRunbook)}) do
            defmodule #{inspect(ClusterRunbook)} do
              use Parapet.Runbook

              step(:auto_step, type: :mitigation, auto_execute: true)

              def execute_mitigation(:auto_step, _incident) do
                if pid = Application.get_env(:parapet, :executor_test_pid) do
                  send(pid, {:cluster_mitigated, node()})
                end

                # INTENTIONAL HOLD: keeps the winner mid-mitigate so the loser's claim insert races the unique constraint.
                # NOT a lazy wait — do not replace with assert_eventually/the start-barrier.
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

        assert String.contains?(
                 reason,
                 "DB-backed contention suite remains the closure-grade proof"
               )

        refute_receive {:cluster_mitigated, _node}, 200
        assert String.contains?(reason, "SCALE-02")
    end
  end
end
