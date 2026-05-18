defmodule Mix.Tasks.Parapet.Gen.ScoriaTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Scoria

  describe "mix parapet.gen.scoria" do
    test "info/2 schema has no required args" do
      info = Scoria.info([], nil)
      assert info.schema == []
    end

    test "creates scoria_dashboard.json and rules.yml" do
      igniter =
        test_project(app_name: :test)
        |> Scoria.igniter()

      assert_creates(igniter, "priv/parapet/grafana/dashboards/scoria_dashboard.json")
      assert_creates(igniter, "priv/parapet/prometheus/rules.yml")

      # Verify contents
      dashboard_content =
        Rewrite.source!(igniter.rewrite, "priv/parapet/grafana/dashboards/scoria_dashboard.json")
        |> Rewrite.Source.get(:content)

      rules_content =
        Rewrite.source!(igniter.rewrite, "priv/parapet/prometheus/rules.yml")
        |> Rewrite.Source.get(:content)

      assert dashboard_content =~ "{}"
      assert rules_content =~ "scoria_llm_token_count_total"
    end
  end
end
