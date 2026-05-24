defmodule Mix.Tasks.Parapet.Gen.RunbooksTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Runbooks

  describe "mix parapet.gen.runbooks" do
    test "creates fixed runbook files under lib/<host>/parapet/runbooks/" do
      igniter =
        test_project(app_name: :test)
        |> Runbooks.igniter()

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))

      assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/stalled_executor.ex"))
      assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/dead_letter.ex"))
      assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/provider_outage.ex"))
      assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/callback_delay.ex"))
      assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/retry_storm.ex"))
      assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/suppression_drift.ex"))
      assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/partial_backlog_drain.ex"))

      stalled_executor_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/stalled_executor.ex")
        |> Rewrite.Source.get(:content)

      assert stalled_executor_source =~ "defmodule Test.Parapet.Runbooks.StalledExecutor do"
      assert stalled_executor_source =~ "use Parapet.Runbook"
      assert stalled_executor_source =~ "capability: :retry_async_item"
      assert stalled_executor_source =~ "warning:"

      dead_letter_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/dead_letter.ex")
        |> Rewrite.Source.get(:content)

      assert dead_letter_source =~ "defmodule Test.Parapet.Runbooks.DeadLetter do"
      assert dead_letter_source =~ "capability: :requeue_dead_letter"
      assert dead_letter_source =~ "warning:"

      provider_outage_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/provider_outage.ex")
        |> Rewrite.Source.get(:content)

      assert provider_outage_source =~ "defmodule Test.Parapet.Runbooks.ProviderOutage do"
      assert provider_outage_source =~ "capability: :request_manual_provider_check"
      assert provider_outage_source =~ "warning:"

      callback_delay_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/callback_delay.ex")
        |> Rewrite.Source.get(:content)

      assert callback_delay_source =~ "defmodule Test.Parapet.Runbooks.CallbackDelay do"
      assert callback_delay_source =~ "preview_only: true"
      assert callback_delay_source =~ "warning:"

      retry_storm_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/retry_storm.ex")
        |> Rewrite.Source.get(:content)

      assert retry_storm_source =~ "defmodule Test.Parapet.Runbooks.RetryStorm do"
      assert retry_storm_source =~ "warning:"

      suppression_drift_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/suppression_drift.ex")
        |> Rewrite.Source.get(:content)

      assert suppression_drift_source =~ "defmodule Test.Parapet.Runbooks.SuppressionDrift do"
      assert suppression_drift_source =~ "warning:"

      partial_backlog_drain_source =
        Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/partial_backlog_drain.ex")
        |> Rewrite.Source.get(:content)

      assert partial_backlog_drain_source =~ "defmodule Test.Parapet.Runbooks.PartialBacklogDrain do"
      assert partial_backlog_drain_source =~ "capability: :retry_async_item"
      assert partial_backlog_drain_source =~ "warning:"
    end
  end
end
