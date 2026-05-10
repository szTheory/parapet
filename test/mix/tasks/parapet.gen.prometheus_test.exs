defmodule Mix.Tasks.Parapet.Gen.PrometheusTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Prometheus

  describe "mix parapet.gen.prometheus" do
    test "generates a valid prometheus rules file" do
      igniter =
        test_project(app_name: :test)
        |> Prometheus.igniter()

      # Assert file creation and capture the content
      assert_creates(igniter, "priv/parapet/prometheus/rules.yml")

      yaml_content =
        Rewrite.source!(igniter.rewrite, "priv/parapet/prometheus/rules.yml")
        |> Rewrite.Source.get(:content)

      # Check that some expected content is present
      assert yaml_content =~ "name: parapet_slo_http"
      assert yaml_content =~ "record: slo:error_ratio:rate5m"

      # Write to a temp file and check with promtool
      temp_file = Path.join(System.tmp_dir!(), "rules_#{System.unique_integer()}.yml")
      File.write!(temp_file, yaml_content)

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
