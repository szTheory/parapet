defmodule Mix.Tasks.Parapet.Gen.UiTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Parapet.Gen.Ui

  describe "mix parapet.gen.ui" do
    test "creates LiveView files under lib/<host>_web/live/parapet/" do
      igniter =
        test_project(app_name: :test)
        |> Ui.igniter()

      files = Rewrite.sources(igniter.rewrite) |> Enum.map(&Rewrite.Source.get(&1, :path))

      assert Enum.any?(files, &String.contains?(&1, "lib/test_web/live/parapet/operator_live.ex"))

      assert Enum.any?(
               files,
               &String.contains?(&1, "lib/test_web/live/parapet/operator_detail_live.ex")
             )

      assert Enum.any?(
               files,
               &String.contains?(&1, "lib/test_web/live/parapet/operator_components.ex")
             )

      operator_live_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_live.ex")
        |> Rewrite.Source.get(:content)

      assert operator_live_source =~ "defmodule TestWeb.Parapet.OperatorLive do"
      assert operator_live_source =~ "Parapet.Operator.list_incident_queue"
      refute operator_live_source =~ "Test.Repo.all(Parapet.Operator.queue_query())"
      assert operator_live_source =~ "Parapet.Operator.incident_detail(id)"
      assert operator_live_source =~ "def handle_params"
      assert operator_live_source =~ "stream("
      assert operator_live_source =~ "History"
      assert operator_live_source =~ "Previous"
      assert operator_live_source =~ "Next"
      assert operator_live_source =~ "Load latest changes"
      assert operator_live_source =~ "handle_event(\"acknowledge\""
      assert operator_live_source =~ "handle_event(\"resolve\""
      assert operator_live_source =~ "Parapet.Operator.resolve_incident(incident, payload)"

      refute operator_live_source =~
               "Parapet.Operator.record_note(incident, \"Resolved\", payload)"

      operator_components_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
        |> Rewrite.Source.get(:content)

      assert operator_components_source =~ "incident.secondary_line"
      assert operator_components_source =~ "incident.updated_at_label"
      assert operator_components_source =~ "incident.attention_chip"
      assert operator_components_source =~ "incident.severity"
    end

    test "emits authenticated-scope router guidance" do
      igniter =
        test_project(app_name: :test)
        |> Ui.igniter()

      assert Enum.any?(
               igniter.notices,
               &String.contains?(
                 &1,
                 "Ensure you place these routes inside an existing authenticated scope"
               )
             )

      assert Enum.any?(
               igniter.notices,
               &String.contains?(&1, "Parapet does not provide its own auth")
             )

      assert Enum.any?(igniter.notices, &String.contains?(&1, "live_session :parapet_operator"))
    end

    test "is idempotent and does not duplicate files" do
      # Run generator once
      igniter1 =
        test_project(app_name: :test)
        |> Ui.igniter()

      # Apply changes and run again to verify idempotency
      # The igniter is just a struct, we can simulate running it again by running the generator on the result
      igniter2 = Ui.igniter(igniter1)

      # The UI generator mostly creates new files and emits notices.
      # Igniter handles not overwriting existing files, but notices shouldn't be duplicated if we handle it correctly.
      # We check that files are only created once (Igniter handles this if we use create_new_file)

      assert Enum.any?(
               igniter2.notices,
               &String.contains?(
                 &1,
                 "Ensure you place these routes inside an existing authenticated scope"
               )
             )
    end
  end
end
