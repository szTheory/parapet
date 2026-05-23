defmodule Mix.Tasks.Parapet.DoctorTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Parapet.Doctor

  @router_path "lib/parapet_web/router.ex"
  @endpoint_path "lib/parapet_web/endpoint.ex"
  @worker_path "lib/parapet/escalation/worker.ex"

  setup do
    Mix.shell(Mix.Shell.Process)
    Application.put_env(:parapet, :slos, [])
    Application.delete_env(:parapet, :escalation_policy)
    Application.delete_env(:parapet, :doctor_cluster_probe)
    Application.delete_env(:parapet, :repo)

    File.mkdir_p!(Path.dirname(@router_path))
    File.mkdir_p!(Path.dirname(@endpoint_path))

    worker_source = File.read!(@worker_path)

    on_exit(fn ->
      Application.put_env(:parapet, :slos, [])
      Application.delete_env(:parapet, :escalation_policy)
      Application.delete_env(:parapet, :doctor_cluster_probe)
      Application.delete_env(:parapet, :repo)
      File.rm(@router_path)
      File.rm(@endpoint_path)
      File.write!(@worker_path, worker_source)
    end)

    :ok
  end

  defp get_all_shell_messages(acc \\ []) do
    receive do
      {:mix_shell, _type, msg} ->
        msg_str = if is_list(msg), do: Enum.join(msg), else: to_string(msg)
        get_all_shell_messages([msg_str | acc])
    after
      0 -> Enum.join(Enum.reverse(acc), "\n")
    end
  end

  defp rewrite_worker(transform) do
    source = File.read!(@worker_path)
    File.write!(@worker_path, transform.(source))
  end

  test "local runs fail only on error findings while --ci raises warn to failure threshold" do
    File.write!(
      @router_path,
      """
        defmodule ParapetWeb.Router do
          use Phoenix.Router

          scope "/", ParapetWeb do
            live_dashboard "/dashboard", metrics: ParapetWeb.Telemetry
          end
        end
      """
    )

    assert Doctor.run(["router"]) == :ok

    messages = get_all_shell_messages()
    assert String.contains?(messages, "==> router: warn")

    assert catch_exit(Doctor.run(["--ci", "router"])) == {:shutdown, 1}
  end

  test "--threshold warn and --threshold error override the default threshold" do
    File.write!(
      @router_path,
      """
        defmodule ParapetWeb.Router do
          use Phoenix.Router

          scope "/", ParapetWeb do
            live_dashboard "/dashboard", metrics: ParapetWeb.Telemetry
          end
        end
      """
    )

    assert catch_exit(Doctor.run(["--threshold", "warn", "router"])) == {:shutdown, 1}
    assert Doctor.run(["--threshold", "error", "router"]) == :ok
  end

  describe "operator_ui security checks" do
    test "reports a warning for unauthenticated operator UI and keeps machine-readable status stable" do
      File.write!(
        @router_path,
        """
        defmodule ParapetWeb.Router do
          use Phoenix.Router

          scope "/", ParapetWeb do
            live "/parapet", Parapet.OperatorLive.Index, :index
            live "/parapet/:id", Parapet.OperatorDetailLive.Show, :show
          end
        end
        """
      )

      assert Doctor.run(["operator_ui"]) == :ok

      messages = get_all_shell_messages()
      assert String.contains?(messages, "==> operator_ui: warn")
      assert String.contains?(messages, "Unsecured operator UI LiveView found")

      assert catch_exit(Doctor.run(["--ci", "operator_ui"])) == {:shutdown, 1}
      assert_receive {:mix_shell, :info, output}

      json_output = Jason.decode!(output)
      assert json_output["checks"]["operator_ui"]["status"] == "warn"
    end

    test "passes when generated Parapet LiveViews are mounted in an authenticated live_session" do
      File.write!(
        @router_path,
        """
        defmodule ParapetWeb.Router do
          use Phoenix.Router

          scope "/", ParapetWeb do
            live_session :parapet_operator, on_mount: [{ParapetWeb.UserAuth, :ensure_authenticated}] do
              live "/parapet", Parapet.OperatorLive.Index, :index
              live "/parapet/:id", Parapet.OperatorDetailLive.Show, :show
            end
          end
        end
        """
      )

      assert Doctor.run(["operator_ui"]) == :ok

      messages = get_all_shell_messages()
      assert String.contains?(messages, "==> operator_ui: info")
    end
  end

  describe "cardinality security checks" do
    test "passes when SLO queries use safe labels" do
      Parapet.SLO.define(:safe_slo,
        objective: 99.9,
        good_events: "rate(http_requests_total{status=~\"2..\"}[5m])",
        total_events: "sum by (route) (rate(http_requests_total[5m]))",
        runbook: "https://example.com/runbook"
      )

      assert Doctor.run(["cardinality"]) == :ok
    end

    test "fails when SLO uses a high-cardinality label in by() clause" do
      Parapet.SLO.define(:bad_by_slo,
        objective: 99.9,
        good_events: "rate(events[5m])",
        total_events: "sum by (user_id) (rate(events[5m]))",
        runbook: "https://example.com/runbook"
      )

      assert catch_exit(Doctor.run(["cardinality"])) == {:shutdown, 1}

      messages = get_all_shell_messages()
      assert String.contains?(messages, "SLO :bad_by_slo has unsafe labels")
      assert String.contains?(messages, "user_id")
    end
  end

  describe "cluster posture" do
    test "flags missing escalation uniqueness as an error and states the static uncertainty boundary" do
      rewrite_worker(
        &String.replace(&1, "    unique: [period: 3600, keys: [:incident_id]]\n", "")
      )

      assert catch_exit(Doctor.run(["cluster_static"])) == {:shutdown, 1}

      messages = get_all_shell_messages()
      assert String.contains?(messages, "missing Oban uniqueness")
      assert String.contains?(messages, "Static check cannot prove distributed correctness")
    end

    test "warns when the worker source no longer appears to use the DB-backed claim layer" do
      rewrite_worker(&String.replace(&1, "ClaimService.claim_action", "claim_action_missing"))

      assert Doctor.run(["cluster_static"]) == :ok

      messages = get_all_shell_messages()
      assert String.contains?(messages, "DB-backed claim layer")
      assert String.contains?(messages, "real proof surface")
    end

    test "cluster mode can report live facts as skip when repo config is unavailable" do
      assert Doctor.run(["cluster"]) == :ok

      messages = get_all_shell_messages()
      assert String.contains?(messages, "==> cluster_runtime: skip")
      assert String.contains?(messages, "cannot prove distributed correctness")
    end

    test "cluster probe failures use exit code 2" do
      Application.put_env(:parapet, :doctor_cluster_probe, fn -> {:error, "probe failed"} end)

      assert catch_exit(Doctor.run(["cluster"])) == {:shutdown, 2}

      messages = get_all_shell_messages()
      assert String.contains?(messages, "probe failed")
    end
  end
end
