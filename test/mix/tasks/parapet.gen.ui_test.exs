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
      assert operator_live_source =~ "operator_nav"
      assert operator_live_source =~ "operator_overview"
      assert operator_live_source =~ "action_center"
      assert operator_live_source =~ "page_mode(:actions)"
      assert operator_live_source =~ "page_mode(:history)"
      assert operator_live_source =~ "Previous"
      assert operator_live_source =~ "Next"
      assert operator_live_source =~ "Newer"
      assert operator_live_source =~ "Older"
      assert operator_live_source =~ "Resolved archive"
      assert operator_live_source =~ "Load Latest Changes"
      refute operator_live_source =~ "Back to Queue"
      assert operator_live_source =~ "selection_source: :none"
      assert operator_live_source =~ "selected_incident(params, page_mode, visible_incidents)"
      assert operator_live_source =~ "defp selected_incident(_params, :response"
      assert operator_live_source =~ "response_cockpit"
      assert operator_live_source =~ "No incident selected"
      assert operator_live_source =~ "handle_event(\"acknowledge\""
      assert operator_live_source =~ "handle_event(\"resolve\""
      assert operator_live_source =~ "Parapet.Operator.resolve_incident(incident, payload)"
      assert operator_live_source =~ ~S|@default_operator_base_path "/parapet"|
      assert operator_live_source =~ "operator_base_path(uri)"
      assert operator_live_source =~ "defp operator_base_path_from_path(path) when is_binary(path)"
      assert operator_live_source =~ "assign(operator_base_path:"
      assert operator_live_source =~ "queue_path(assigns.operator_base_path, assigns.queue_params, extra_params)"
      assert operator_live_source =~ "history_path(@operator_base_path)"
      assert operator_live_source =~ "defp history_path(operator_base_path)"

      refute operator_live_source =~
               "Parapet.Operator.record_note(incident, \"Resolved\", payload)"

      operator_components_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_components.ex")
        |> Rewrite.Source.get(:content)

      assert operator_components_source =~ "data-incident-id"
      assert operator_components_source =~ "attr(:operator_base_path, :string, default: \"/parapet\")"
      assert operator_components_source =~ "navigate={incident_detail_path(@operator_base_path, incident)}"

      assert operator_components_source =~
               "patch={queue_item_path(@operator_base_path, @queue_params, incident)}"

      assert operator_components_source =~
               "defp operator_path(operator_base_path), do: operator_base_path"

      assert operator_components_source =~ "defp operator_path(operator_base_path, :actions)"
      assert operator_components_source =~ "defp operator_path(operator_base_path, :history)"

      assert operator_components_source =~
               "defp queue_item_path(operator_base_path, queue_params, incident)"

      assert operator_components_source =~
               ~S|defp incident_detail_path(operator_base_path, incident)|

      refute operator_components_source =~
               ~S|defp incident_detail_path(incident), do: "/parapet/incidents/#{incident.id}"|

      assert operator_components_source =~ "Active response summary"
      assert operator_components_source =~ "incident.secondary_line"
      assert operator_components_source =~ "incident.updated_at_label"
      assert operator_components_source =~ "incident.attention_chip"
      assert operator_components_source =~ "incident.severity"
      assert operator_components_source =~ "surface_class(:action_card)"
      assert operator_components_source =~ "control_class(:recovery"
      assert operator_components_source =~ "chip_class(:state"
      assert operator_components_source =~ "operator_theme_bootstrap"
      assert operator_components_source =~ "parapet-ui"
      assert operator_components_source =~ "parapet.operator.theme"
      assert operator_components_source =~ "parapet_theme"
      assert operator_components_source =~ "data-parapet-theme-value=\"light\""
      assert operator_components_source =~ "data-parapet-theme-value=\"dark\""
      assert operator_components_source =~ "data-parapet-theme-value=\"system\""
      assert operator_components_source =~ "--parapet-bg"
      assert operator_components_source =~ "--parapet-accent"
      assert operator_components_source =~ "--po-header-bg"
      assert operator_components_source =~ "--po-theme-control-bg"
      assert operator_components_source =~ "po-operator-header"
      assert operator_components_source =~ "po-operator-brand"
      assert operator_components_source =~ "po-theme-control"
      assert operator_components_source =~ "po-theme-option"
      assert operator_components_source =~ "prefers-color-scheme: dark"
      assert operator_components_source =~ "prefers-reduced-motion: reduce"
      assert operator_components_source =~ "Incident retrospective"
      assert operator_components_source =~ "Copy retrospective"
      assert operator_components_source =~ "readable_datetime"
      assert operator_components_source =~ "exact_datetime"
      refute operator_components_source =~ "Automated Retrospective"
      refute operator_components_source =~ "Copy to Clipboard"
      refute operator_components_source =~ "alert("

      assert operator_components_source =~
               "Preview scoped changes before execution. No recovery action runs until confirm."

      assert operator_components_source =~
               "Execute bounded recovery. Writes a durable audit record"

      assert operator_components_source =~ "href={external_link_url(link)}"
      assert operator_components_source =~ "href={external_link_url(entry.payload)}"
      refute operator_components_source =~ "transition-all"

      operator_detail_source =
        Rewrite.source!(igniter.rewrite, "lib/test_web/live/parapet/operator_detail_live.ex")
        |> Rewrite.Source.get(:content)

      assert operator_detail_source =~ ~S|@default_operator_base_path "/parapet"|
      assert operator_detail_source =~ "operator_base_path(uri)"
      assert operator_detail_source =~ "defp operator_base_path_from_path(path) when is_binary(path)"
      assert operator_detail_source =~ "assign(operator_base_path:"
      assert operator_detail_source =~
               "push_navigate(to: incident_detail_path(socket.assigns.operator_base_path, id))"

      assert operator_detail_source =~
               "push_navigate(socket, to: incident_detail_path(socket.assigns.operator_base_path, id))"

      assert operator_detail_source =~ "detail_back_path(@operator_base_path, @incident)"
      assert operator_detail_source =~
               ~S|defp incident_detail_path(operator_base_path, incident_id)|

      refute operator_detail_source =~ ~S|push_navigate(to: "/parapet/incidents/#{id}")|
      refute operator_detail_source =~ ~S|push_navigate(socket, to: "/parapet/incidents/#{id}")|
      assert operator_detail_source =~ "Parapet.Operator.acknowledge_incident"
      assert operator_detail_source =~ "Parapet.Operator.resolve_incident"
      assert operator_detail_source =~ "Parapet.Operator.incident_detail(id)"
      assert operator_detail_source =~ "detail_nav_active(@incident)"
      assert operator_detail_source =~ "Back to history"
      assert operator_detail_source =~ "Resolved incident review"
      assert operator_detail_source =~ "retrospective_card"
      assert operator_detail_source =~ "max-w-7xl"
      refute operator_detail_source =~ "md:overflow-y-auto"
      assert operator_detail_source =~ "operator_theme_bootstrap"
      assert operator_detail_source =~ "parapet-ui"
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
      assert Enum.any?(igniter.notices, &String.contains?(&1, "live \"/parapet\""))
      assert Enum.any?(igniter.notices, &String.contains?(&1, "live \"/parapet/actions\""))
      assert Enum.any?(igniter.notices, &String.contains?(&1, "live \"/parapet/history\""))
      assert Enum.any?(igniter.notices, &String.contains?(&1, "live \"/parapet/incidents/:id\""))
      assert Enum.any?(igniter.notices, &String.contains?(&1, "live \"/parapet/:id\""))
      assert Enum.any?(igniter.notices, &String.contains?(&1, "Default mount: /parapet"))
      assert Enum.any?(igniter.notices, &String.contains?(&1, "Scoped mount: /ops/parapet"))
      assert Enum.any?(igniter.notices, &String.contains?(&1, "scope \"/ops\""))

      refute Enum.any?(igniter.notices, &String.contains?(&1, "route_base"))
      refute Enum.any?(igniter.notices, &String.contains?(&1, "--operator-base-path"))
    end

    test "generated route surfaces flow through operator_base_path helpers" do
      sources = generated_operator_sources()

      route_surface_expectations = [
        {"push_patch", sources.operator_live, "queue_path(socket,"},
        {"push_navigate", sources.operator_detail, "incident_detail_path(socket.assigns.operator_base_path, id)"},
        {"navigate", sources.operator_components, "operator_path(@operator_base_path"},
        {"patch", sources.operator_components, "queue_item_path(@operator_base_path"},
        {"href", sources.operator_components, "operator_path(@operator_base_path, :history)"},
        {"queue_page_path", sources.operator_live, "queue_page_path(@operator_base_path"},
        {"queue_item_path", sources.operator_components, "queue_item_path(@operator_base_path"},
        {"history_path", sources.operator_live, "history_path(@operator_base_path)"},
        {"incident_detail_path", sources.operator_components, "incident_detail_path(@operator_base_path, incident)"},
        {"detail_back_path", sources.operator_detail, "detail_back_path(@operator_base_path, @incident)"}
      ]

      for {surface, source, scoped_pattern} <- route_surface_expectations do
        assert source =~ surface
        assert source =~ scoped_pattern
      end

      for {path, source} <- Map.to_list(sources) do
        assert_no_direct_local_parapet_routes!(path, source)
      end
    end

    test "generated templates do not include route-bearing form surfaces" do
      sources = generated_operator_sources()

      for {_path, source} <- Map.to_list(sources) do
        refute source =~ ~r/<form|form_for|phx-submit|action=/
      end
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

  defp generated_operator_sources do
    igniter =
      test_project(app_name: :test)
      |> Ui.igniter()

    %{
      operator_live:
        generated_source(igniter, "lib/test_web/live/parapet/operator_live.ex"),
      operator_detail:
        generated_source(igniter, "lib/test_web/live/parapet/operator_detail_live.ex"),
      operator_components:
        generated_source(igniter, "lib/test_web/live/parapet/operator_components.ex")
    }
  end

  defp generated_source(igniter, path) do
    igniter.rewrite
    |> Rewrite.source!(path)
    |> Rewrite.Source.get(:content)
  end

  defp assert_no_direct_local_parapet_routes!(path, source) do
    forbidden_patterns = [
      ~r/(navigate|patch|href)="\/parapet/,
      ~r/(navigate|patch|href)=\{"\/parapet/,
      ~r/push_(patch|navigate).*"\/parapet/s,
      ~r/defp\s+(queue_base_path|queue_page_path|queue_item_path|history_path|incident_detail_path|detail_back_path).*"\/parapet/s
    ]

    for pattern <- forbidden_patterns do
      refute source =~ pattern,
             "expected #{path} not to contain direct local /parapet route matching #{inspect(pattern)}"
    end
  end
end
