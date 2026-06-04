defmodule Parapet.OperatorUIIntegrationTest do
  use ExUnit.Case, async: true

  defp index_of(content, needle) do
    case :binary.match(content, needle) do
      {index, _length} -> index
      :nomatch -> nil
    end
  end

  describe "UI generator integration" do
    test "generated UI templates align with bounded Parapet.Operator queue actions" do
      template_path = "priv/templates/parapet.gen.ui/operator_live.ex.eex"
      content = File.read!(template_path)

      assert content =~ "Parapet.Operator.list_incident_queue"
      assert content =~ "Parapet.Operator.incident_detail(id)"
      assert content =~ "handle_event(\"resolve\""
      assert content =~ "Parapet.Operator.resolve_incident(incident, payload)"
      refute content =~ "Parapet.Operator.record_note(incident, \"Resolved\", payload)"
      refute content =~ "Repo.all(Parapet.Operator.queue_query())"
      assert content =~ "def handle_params"
      assert content =~ "stream("
    end

    test "doctor check enforces authenticated mount for generated UI" do
      # We know doctor expects OperatorLive and OperatorDetailLive to be behind auth.
      # Let's verify that Mix.Tasks.Parapet.Doctor check_operator_ui behaves as expected.
      # Doctor looks for "OperatorLive" or "OperatorDetailLive" in a live() macro and checks for scopes.

      # We verify the doctor code handles it by reading its source.
      doctor_code = File.read!("lib/mix/tasks/parapet.doctor.ex")
      assert doctor_code =~ "check_operator_ui"
      assert doctor_code =~ "OperatorLive"
      assert doctor_code =~ "OperatorDetailLive"
      assert doctor_code =~ "has_auth_plug?"
    end

    test "generated workbench uses calm active-response cockpit copy" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_live.ex.eex")
      components = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert content =~ "response_cockpit"
      assert content =~ "Next Safe Actions"
      assert components =~ "Active response summary"
      assert components =~ "Next Safe Action"
      refute content =~ "Back to Queue"
    end

    test "generated direct detail prefers incident detail route after actions" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_detail_live.ex.eex")

      assert content =~
               ~S|push_navigate(to: incident_detail_path(socket.assigns.operator_base_path, id))|

      assert content =~
               ~S|push_navigate(socket, to: incident_detail_path(socket.assigns.operator_base_path, id))|

      assert content =~ "defp incident_detail_path(operator_base_path, incident_id)"
      assert content =~ "operator_base_path_from_path"
      assert content =~ "Parapet.Operator.acknowledge_incident"
      assert content =~ "Parapet.Operator.resolve_incident"
      assert content =~ "Parapet.Operator.incident_detail(id)"
    end

    test "generated router guidance pins the active-response route map" do
      router_content = File.read!("priv/templates/parapet.gen.ui/router_snippet.ex.eex")
      task_content = File.read!("lib/mix/tasks/parapet.gen.ui.ex")
      components_content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      for route <- [
            ~S|live "/parapet"|,
            ~S|live "/parapet/actions"|,
            ~S|live "/parapet/history"|,
            ~S|live "/parapet/incidents/:id"|,
            ~S|live "/parapet/:id"|
          ] do
        assert router_content =~ route
      end

      assert task_content =~ ~S|live "/parapet/incidents/:id"|
      assert task_content =~ ~S|live "/parapet/:id"|
      assert components_content =~ "Respond"
      assert components_content =~ "Actions"
      assert components_content =~ "History"
      assert components_content =~ ~S|aria-current={if @active, do: "page", else: nil}|
    end

    test "generated UI templates enforce calm responsive layout contracts" do
      template_path = "priv/templates/parapet.gen.ui/operator_live.ex.eex"
      content = File.read!(template_path)

      assert content =~ "min-h-screen"
      assert content =~ "max-w-7xl"
      assert content =~ "response_cockpit"
      assert content =~ "lg:grid-cols-[minmax(0,22rem)_minmax(0,1fr)]"
      refute content =~ "md:w-80"
      refute content =~ "hidden md:flex"
      refute content =~ "h-screen flex-col overflow-hidden"
    end

    test "generated queue exposes explicit refresh, paging, and history affordances" do
      live_content = File.read!("priv/templates/parapet.gen.ui/operator_live.ex.eex")
      components_content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")
      content = live_content <> "\n" <> components_content

      assert content =~ "New incidents or queue changes are available."
      assert content =~ "Load Latest Changes"
      assert content =~ "History"
      assert content =~ "Respond"
      assert content =~ "Actions"
      assert content =~ "Active response"
      assert content =~ "Previous"
      assert content =~ "Next"
      assert content =~ "Newer"
      assert content =~ "Older"
      assert content =~ "Resolved archive"
      assert content =~ "selected_incident(params, page_mode, visible_incidents)"
      assert content =~ "selection_source"
      assert content =~ "No incident selected"

      assert components_content =~
               "navigate={incident_detail_path(@operator_base_path, incident)}"

      assert components_content =~
               ~S|defp incident_detail_path(operator_base_path, incident),|

      assert components_content =~ ~S|do: operator_base_path <> "/incidents/#{incident.id}"|

      assert live_content =~ "page_mode={@page_mode}"
    end

    test "generated UI exposes polished IA and audit-safe action copy" do
      live_content = File.read!("priv/templates/parapet.gen.ui/operator_live.ex.eex")
      components_content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")
      detail_content = File.read!("priv/templates/parapet.gen.ui/operator_detail_live.ex.eex")
      content = live_content <> "\n" <> components_content <> "\n" <> detail_content

      assert content =~ "Parapet Operator"
      assert content =~ "Active response"
      assert content =~ "Action center"
      assert content =~ "Resolved history"
      assert content =~ "Writes a durable audit record"
      assert content =~ "Every request is audited"
      assert content =~ "Next Safe Action"
      assert content =~ "Latest Evidence"
      assert content =~ "Back to history"
      assert content =~ "Resolved incident review"
      assert content =~ "detail_nav_active(@incident)"
      assert content =~ "retrospective_card"
      assert content =~ "Incident retrospective"
      assert content =~ "Copy retrospective"
      assert content =~ "readable_datetime"
      assert content =~ "exact_datetime"
      assert content =~ "surface_class(:action_card)"
      assert content =~ "control_class(:recovery"
      assert content =~ "chip_class(:state"
      assert content =~ "focus:outline-none focus:ring-2"
      assert content =~ "operator_theme_bootstrap"
      assert content =~ "theme_control"
      assert content =~ "parapet.operator.theme"
      assert content =~ "parapet_theme"
      assert content =~ "--parapet-bg"
      assert content =~ "--parapet-panel"
      assert content =~ "--parapet-accent"
      assert content =~ "--po-link"
      assert content =~ "--po-header-bg"
      assert content =~ "--po-theme-control-bg"
      assert content =~ "--po-chip-warning-bg"
      assert content =~ "po-operator-header"
      assert content =~ "po-operator-brand"
      assert content =~ "po-theme-control"
      assert content =~ "po-theme-option"
      assert content =~ "po-button-warning"
      assert content =~ "po-chip-warning"
      assert content =~ "aria-label=\"Close Recovery Preview\""
      assert content =~ "prefers-color-scheme: dark"
      assert content =~ "prefers-reduced-motion: reduce"

      assert content =~
               "Preview scoped changes before execution. No recovery action runs until confirm."

      assert content =~
               "Execute bounded recovery. Writes a durable audit record with actor, reason, correlation id, and outcome."

      assert content =~
               "Request the next escalation only after reviewing current status and the canonical timeline. Every request is audited."

      assert content =~
               "Suppress pending escalation for the displayed bounded window. Every request is audited."

      refute content =~ "transition-all"
      refute components_content =~ "border-stone-900/10 bg-stone-950 text-stone-50"
      refute components_content =~ "text-white\">Active response workbench"
      refute components_content =~ "bg-stone-900 px-1 py-1 ring-1 ring-stone-700"
      refute components_content =~ "bg-white shadow-sm ring-1 ring-stone-900/5 bg-white"
      refute detail_content =~ "md:hidden"
      refute detail_content =~ "md:overflow-y-auto"
      refute content =~ "Automated Retrospective"
      refute content =~ "Copy to Clipboard"
      refute content =~ "alert("
    end

    test "demo copied LiveViews stay aligned with generated IA contract" do
      live_content =
        File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex")

      detail_content =
        File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex")

      components_content =
        File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex")

      assert live_content =~ "response_cockpit"
      assert live_content =~ "Next Safe Actions"
      refute live_content =~ "Back to Queue"
      assert live_content =~ "@default_operator_base_path"
      assert live_content =~ "operator_base_path_from_path"
      assert live_content =~ "operator_base_path: @default_operator_base_path"
      assert live_content =~ "queue_page_path(@operator_base_path"
      assert live_content =~ "history_path(@operator_base_path)"

      assert detail_content =~
               ~S|push_navigate(to: incident_detail_path(socket.assigns.operator_base_path, id))|

      assert detail_content =~
               ~S|push_navigate(socket, to: incident_detail_path(socket.assigns.operator_base_path, id))|

      assert detail_content =~ "def handle_params(%{\"id\" => id}, uri, socket)"
      assert detail_content =~ "detail_back_path(@operator_base_path, @incident)"
      assert detail_content =~ "operator_base_path_from_path"
      assert components_content =~ "surface_class(:action_card)"
      assert components_content =~ "control_class(:recovery"
      assert components_content =~ "chip_class(:state"
      assert components_content =~ "operator_theme_bootstrap"
      assert components_content =~ "parapet.operator.theme"
      assert live_content =~ "selection_source"
      assert live_content =~ "response_cockpit"
      assert live_content =~ "Next Safe Actions"
      assert components_content =~ "po-operator-header"
      assert components_content =~ "po-theme-control"
      assert components_content =~ "po-chip-warning"
      assert components_content =~ "po-link"
      assert components_content =~ "attr(:operator_base_path, :string, default: \"/parapet\")"
      assert components_content =~ "href={operator_path(@operator_base_path, :history)}"

      assert components_content =~
               "navigate={incident_detail_path(@operator_base_path, incident)}"

      assert components_content =~
               "patch={queue_item_path(@operator_base_path, @queue_params, incident)}"

      assert components_content =~ "defp operator_path(operator_base_path)"

      assert components_content =~
               "defp queue_item_path(operator_base_path, queue_params, incident)"

      assert components_content =~ "defp incident_detail_path(operator_base_path, incident)"
      assert live_content =~ "Resolved archive"
      assert detail_content =~ "Back to history"
      assert detail_content =~ "Resolved incident review"
      assert detail_content =~ "retrospective_card"
      assert components_content =~ "Copy retrospective"
      assert components_content =~ "readable_datetime"
      refute detail_content =~ "md:overflow-y-auto"

      assert components_content =~
               "Preview scoped changes before execution. No recovery action runs until confirm."

      assert components_content =~
               "Execute bounded recovery. Writes a durable audit record with actor, reason, correlation id, and outcome."

      refute components_content =~ "bg-white shadow-sm ring-1 ring-stone-900/5 bg-white"
      refute live_content =~ ~S|navigate="/parapet"|
      refute components_content =~ ~S|href="/parapet/history"|
      refute detail_content =~ ~S|push_navigate(to: "/parapet/incidents/#{id}")|
      refute detail_content =~ ~S|push_navigate(socket, to: "/parapet/incidents/#{id}")|
    end

    test "demo copied LiveViews preserve workbench presentation while using scoped route helpers" do
      live_content =
        File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex")

      detail_content =
        File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex")

      components_content =
        File.read!("examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex")

      content = live_content <> "\n" <> detail_content <> "\n" <> components_content

      for marker <- [
            "Active response workbench",
            "Next Safe Actions",
            "Load Latest Changes",
            "Back to history",
            "Resolved incident review",
            "response_cockpit",
            "lg:grid-cols-[minmax(0,22rem)_minmax(0,1fr)]",
            "po-operator-header",
            "po-theme-control",
            "focus:outline-none focus:ring-2"
          ] do
        assert content =~ marker
      end

      for helper <- [
            "operator_base_path",
            "operator_base_path_from_path",
            "queue_page_path(@operator_base_path",
            "history_path(@operator_base_path)",
            "detail_back_path(@operator_base_path, @incident)",
            "operator_path(@operator_base_path",
            "queue_item_path(@operator_base_path",
            "incident_detail_path(@operator_base_path"
          ] do
        assert content =~ helper
      end

      for explanatory_copy <- ["Default mount:", "Scoped mount:", "/ops/parapet"] do
        refute content =~ explanatory_copy
      end
    end

    test "operator UI docs show preferred and compatibility route map" do
      content = File.read!("docs/operator-ui.md")

      for route <- [
            ~S|live "/parapet", MyAppWeb.Parapet.OperatorLive, :index|,
            ~S|live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions|,
            ~S|live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history|,
            ~S|live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show|,
            ~S|live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show|
          ] do
        assert content =~ route
      end

      assert content =~ "/parapet/incidents/:id is the preferred incident detail route"
      assert content =~ "/parapet/:id remains available for compatibility"
      assert content =~ "Parapet does **not** provide its own authentication system"
    end

    test "generated queue rows render bounded triage fields instead of raw ids only" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert content =~ "incident.secondary_line"
      assert content =~ "incident.updated_at_label"
      assert content =~ "incident.attention_chip"
      assert content =~ "incident.severity"
    end

    test "UI stays generator-first and host-owned" do
      # Parapet must not define its own Plug.Router or Phoenix.Router for the UI.
      # Let's verify no router modules exist in Parapet core.
      core_files = Path.wildcard("lib/parapet/**/*.ex")

      for file <- core_files do
        content = File.read!(file)
        refute content =~ "use Phoenix.Router", "Found Phoenix.Router in core file: \#{file}"
        refute content =~ "use Plug.Router", "Found Plug.Router in core file: \#{file}"
      end
    end

    test "detail components render escalation summary before the canonical timeline" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert content =~ "Escalation Status"
      assert content =~ "Escalation Chain"
      assert content =~ "Time Until Next Escalation"
      assert content =~ "@detail.escalation_summary"
      assert content =~ "@detail.timeline_entries"

      assert index_of(content, "Escalation Status") <
               index_of(content, "def incident_timeline"),
             "Escalation summary should be defined ahead of timeline rendering in the template"
    end

    test "timeline rows render typed system and escalation evidence without generic payload dumps" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert content =~ "timeline_entry_title"
      assert content =~ "timeline_entry_body"
      assert content =~ "external_link_entry?"
      assert content =~ ~S|href={external_link_url(entry.payload)}|
      assert content =~ "title={exact_datetime(entry.inserted_at)}"
      assert content =~ "readable_datetime(entry.inserted_at)"
      assert content =~ "presentation.actor_class"
      refute content =~ "inspect(entry.payload)"
    end

    test "manual escalation controls appear after summary context inside the generated component surface" do
      components_content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert components_content =~ "Trigger Next Escalation"
      assert components_content =~ "Suppress Pending Escalation"

      assert components_content =~
               "Escalation controls are available only while the incident is open."

      assert index_of(components_content, "Escalation Status") <
               index_of(components_content, "Trigger Next Escalation"),
             "Escalation controls should appear after summary context"

      assert index_of(components_content, "def incident_timeline") <
               index_of(components_content, "Trigger Next Escalation"),
             "Escalation controls should stay below the canonical timeline"
    end
  end
end
