defmodule Mix.Tasks.Parapet.Gen.RecoveryTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Recovery

  # Helper: set up positional arg in igniter.args so igniter/1 sees it directly
  defp run_recovery(igniter, argv) do
    Igniter.Mix.Task.configure_and_run(igniter, Recovery, argv)
  end

  describe "mix parapet.gen.recovery" do
    test "scaffolds the recovery module and test stub" do
      igniter =
        test_project(app_name: :test)
        |> run_recovery(["RetryDLQ"])

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))

      assert Enum.any?(
               files,
               &String.contains?(&1, "lib/test/parapet/recovery/retry_dlq.ex")
             )

      assert Enum.any?(
               files,
               &String.contains?(&1, "test/test/parapet/recovery/retry_dlq_test.exs")
             )

      source_content =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/recovery/retry_dlq.ex")
        |> Rewrite.Source.get(:content)

      assert source_content =~ "use Parapet.Recovery"
      assert source_content =~ "def id"
      assert source_content =~ "def label"
      assert source_content =~ "def preview"
      assert source_content =~ "def execute"
      assert source_content =~ "Test.Parapet.Recovery.RetryDLQ"
    end

    test "missing NAME raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        test_project(app_name: :test)
        |> run_recovery([])
      end
    end

    test "on_exists: :skip does not overwrite existing module on second run" do
      igniter_first =
        test_project(app_name: :test)
        |> run_recovery(["RetryDLQ"])

      source_first =
        Rewrite.source!(igniter_first.rewrite, "lib/test/parapet/recovery/retry_dlq.ex")
        |> Rewrite.Source.get(:content)

      igniter_second =
        igniter_first
        |> run_recovery(["RetryDLQ"])

      source_second =
        Rewrite.source!(igniter_second.rewrite, "lib/test/parapet/recovery/retry_dlq.ex")
        |> Rewrite.Source.get(:content)

      assert source_first == source_second
    end
  end
end
