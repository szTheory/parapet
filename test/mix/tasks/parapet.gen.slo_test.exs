defmodule Mix.Tasks.Parapet.Gen.SloTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Slo

  defp run_slo(igniter, argv) do
    Igniter.Mix.Task.configure_and_run(igniter, Slo, argv)
  end

  describe "mix parapet.gen.slo" do
    test "scaffolds the SLO provider module and updates config" do
      igniter =
        test_project(app_name: :test)
        |> Igniter.Project.Config.configure("config.exs", :parapet, [:providers], [])
        |> run_slo(["TestJourney", "--objective", "99.9", "--good-metric", "http_requests_total", "--alert-class", "ticket"])

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))

      assert Enum.any?(
               files,
               &String.contains?(&1, "lib/test/slo/test_journey.ex")
             )

      source_content =
        Rewrite.source!(igniter.rewrite, "lib/test/slo/test_journey.ex")
        |> Rewrite.Source.get(:content)

      assert source_content =~ "defmodule Test.SLO.TestJourney do"
      assert source_content =~ "@behaviour Parapet.SLO.Provider"
      assert source_content =~ "def slices do"
      assert source_content =~ "Parapet.SLO.SliceSpec.new("
      assert source_content =~ "objective: 99.9"
      assert source_content =~ "good_source_metric: \"http_requests_total\""
      assert source_content =~ "alert_class: :ticket"

      config_content =
        Rewrite.source!(igniter.rewrite, "config/config.exs")
        |> Rewrite.Source.get(:content)

      assert config_content =~ "config :parapet,"
      assert config_content =~ "providers: [Test.SLO.TestJourney]"
    end

    test "requires objective or threshold" do
      assert_raise ArgumentError, ~r/Must provide either --objective or --threshold/, fn ->
        test_project(app_name: :test)
        |> run_slo(["TestJourney"])
      end
    end

    test "missing NAME raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        test_project(app_name: :test)
        |> run_slo(["--objective", "99.9"])
      end
    end
  end
end
