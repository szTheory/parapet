defmodule Mix.Tasks.Parapet.DoctorTest do
  use ExUnit.Case, async: false

  alias Mix.Tasks.Parapet.Doctor

  @router_path "lib/parapet_web/router.ex"

  setup do
    Mix.shell(Mix.Shell.Process)
    Application.put_env(:parapet, :slos, [])

    # Ensure directory exists for router
    File.mkdir_p!(Path.dirname(@router_path))

    on_exit(fn ->
      Application.put_env(:parapet, :slos, [])
      File.rm(@router_path)
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

  test "passes when no slos exist and no router exists" do
    assert Doctor.run([]) == :ok
  end

  test "passes when slos have valid runbooks" do
    Parapet.SLO.define(:good_slo,
      objective: 99.9,
      good_events: "rate(good)",
      total_events: "rate(total)",
      runbook: "https://example.com/runbook"
    )

    assert Doctor.run([]) == :ok
  end

  test "fails and halts when slo has empty runbook" do
    apply(Parapet.SLO, :define, [
      :bad_slo,
      [
        objective: 99.9,
        good_events: "rate(good)",
        total_events: "rate(total)",
        runbook: ""
      ]
    ])

    assert catch_exit(Doctor.run([])) == {:shutdown, 2}

    assert_receive {:mix_shell, :error, ["  - SLO :bad_slo is missing a valid runbook"]}
  end

  describe "operator_ui security checks" do
    test "reports warning when operator UI LiveViews appear in an unauthenticated scope" do
      router_content = """
      defmodule ParapetWeb.Router do
        use Phoenix.Router
        
        scope "/", ParapetWeb do
          live "/parapet", Parapet.OperatorLive.Index, :index
          live "/parapet/:id", Parapet.OperatorDetailLive.Show, :show
        end
      end
      """

      File.write!(@router_path, router_content)

      assert catch_exit(Doctor.run([])) == {:shutdown, 1}

      messages = get_all_shell_messages()
      assert String.contains?(messages, "==> operator_ui: warn")
      assert String.contains?(messages, "Unsecured operator UI LiveView found")
    end

    test "passes when generated Parapet LiveViews are mounted inside an authenticated host scope" do
      router_content = """
      defmodule ParapetWeb.Router do
        use Phoenix.Router
        
        scope "/admin", ParapetWeb do
          pipe_through [:browser, :require_authenticated_user]

          live "/parapet", Parapet.OperatorLive.Index, :index
          live "/parapet/:id", Parapet.OperatorDetailLive.Show, :show
        end
      end
      """

      File.write!(@router_path, router_content)

      assert Doctor.run([]) == :ok

      messages = get_all_shell_messages()
      assert String.contains?(messages, "==> operator_ui: ok")
    end

    test "passes when generated Parapet LiveViews are mounted inside an authenticated live_session" do
      router_content = """
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

      File.write!(@router_path, router_content)

      assert Doctor.run([]) == :ok

      messages = get_all_shell_messages()
      assert String.contains?(messages, "==> operator_ui: ok")
    end

    test "CI output includes operator_ui check as distinct key with stable machine-readable status" do
      router_content = """
      defmodule ParapetWeb.Router do
        use Phoenix.Router
        
        scope "/", ParapetWeb do
          live "/parapet", Parapet.OperatorLive.Index, :index
        end
      end
      """

      File.write!(@router_path, router_content)

      assert catch_exit(Doctor.run(["--ci"])) == {:shutdown, 1}

      assert_receive {:mix_shell, :info, output}

      json_output = Jason.decode!(output)
      assert Map.has_key?(json_output["checks"], "operator_ui")
      assert json_output["checks"]["operator_ui"]["status"] == "warn"

      assert "Unsecured operator UI LiveView found" in json_output["checks"]["operator_ui"][
               "messages"
             ]
    end
  end
end
