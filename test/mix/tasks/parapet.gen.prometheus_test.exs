defmodule Mix.Tasks.Parapet.Gen.PrometheusTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Prometheus
  alias Parapet.SLO.MailglassDelivery

  describe "mix parapet.gen.prometheus" do
    setup do
      Application.put_env(:parapet, :providers, [MailglassDelivery])
      on_exit(fn -> Application.put_env(:parapet, :providers, []) end)
      :ok
    end

    test "generates split provider-first prometheus files" do
      igniter =
        test_project(app_name: :test)
        |> Prometheus.igniter()

      assert_creates(igniter, "priv/parapet/prometheus/recording_rules.yml")
      assert_creates(igniter, "priv/parapet/prometheus/alerts.yml")
      assert_creates(igniter, "priv/parapet/prometheus/rules.yml")

      rules_content =
        Rewrite.source!(igniter.rewrite, "priv/parapet/prometheus/rules.yml")
        |> Rewrite.Source.get(:content)

      recording_content =
        Rewrite.source!(igniter.rewrite, "priv/parapet/prometheus/recording_rules.yml")
        |> Rewrite.Source.get(:content)

      alerts_content =
        Rewrite.source!(igniter.rewrite, "priv/parapet/prometheus/alerts.yml")
        |> Rewrite.Source.get(:content)

      assert recording_content =~ "groups:"
      assert alerts_content =~ "groups:"
      assert rules_content =~ "groups:"

      # Write to a temp file and check with promtool
      temp_file = Path.join(System.tmp_dir!(), "rules_#{System.unique_integer()}.yml")
      File.write!(temp_file, rules_content)

      try do
        case System.cmd("promtool", ["check", "rules", temp_file], stderr_to_stdout: true) do
          {output, 0} ->
            assert output =~ "SUCCESS"

          {output, status} ->
            flunk("promtool check rules failed with status #{status}:\n#{output}")
        end
      rescue
        e in ErlangError ->
          if e.original == :enoent do
            # Skip checking if promtool isn't available in the test environment (e.g., CI without it)
            IO.warn("promtool not found, skipping prometheus rules validation")
          else
            reraise e, __STACKTRACE__
          end
      after
        File.rm(temp_file)
      end
    end
  end
end
