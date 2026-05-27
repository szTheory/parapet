defmodule Mix.Tasks.Parapet.Gen.GrafanaTest do
  use ExUnit.Case, async: false
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Grafana

  setup do
    previous_slos = Application.get_env(:parapet, :slos)
    previous_providers = Application.get_env(:parapet, :providers)

    Application.delete_env(:parapet, :slos)
    Application.delete_env(:parapet, :providers)

    on_exit(fn ->
      restore_env(:slos, previous_slos)
      restore_env(:providers, previous_providers)
    end)

    :ok
  end

  defp restore_env(key, nil), do: Application.delete_env(:parapet, key)
  defp restore_env(key, value), do: Application.put_env(:parapet, key, value)

  describe "mix parapet.gen.grafana" do
    test "generates a grafana dashboard and provisioning file" do
      igniter =
        test_project(app_name: :test_app)
        |> Grafana.igniter()

      assert_creates(igniter, "priv/parapet/grafana/provisioning/dashboards.yml")
      assert_creates(igniter, "priv/parapet/grafana/dashboards/main.json")

      dashboard_json =
        Rewrite.source!(igniter.rewrite, "priv/parapet/grafana/dashboards/main.json")
        |> Rewrite.Source.get(:content)

      assert dashboard_json =~ "TestApp Executive Health & SLOs"
      assert dashboard_json =~ "parapet_deploy_info"
      assert dashboard_json =~ "slo:error_ratio:rate5m{slo=\\\"http\\\"}"
      assert dashboard_json =~ "slo:error_ratio:rate5m{slo=\\\"oban\\\"}"
      assert dashboard_json =~ "slo:error_ratio:rate5m{slo=\\\"login_journey\\\"}"
      assert dashboard_json =~ "DS_POSTGRES"
      assert dashboard_json =~ "AI Config Changes"

      provisioning_yml =
        Rewrite.source!(igniter.rewrite, "priv/parapet/grafana/provisioning/dashboards.yml")
        |> Rewrite.Source.get(:content)

      assert provisioning_yml =~ "TestApp Dashboards"
    end
  end
end
