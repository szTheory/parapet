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
      assert router_content =~ "Default mount: /parapet"
      assert router_content =~ "Scoped mount: /ops/parapet"
      assert router_content =~ ~S|scope "/ops"|
      assert task_content =~ "Default mount: /parapet"
      assert task_content =~ "Scoped mount: /ops/parapet"
      assert task_content =~ ~S|scope "/ops"|
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
      assert content =~ "Default mount: `/parapet`"
      assert content =~ "Scoped mount: `/ops/parapet`"
      assert content =~ ~S|scope "/ops", MyAppWeb do|
      assert content =~ "generated `operator_base_path` helper"

      assert content =~
               "Host app scopes, pipelines, authentication, and authorization remain owner-controlled"
    end

    test "generated queue rows render bounded triage fields instead of raw ids only" do
      content = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")

      assert content =~ "incident.secondary_line"
      assert content =~ "incident.updated_at_label"
      assert content =~ "incident.attention_chip"
      assert content =~ "incident.severity"
    end

    test "generated and demo route emitters do not bypass scoped route helpers" do
      for path <- generated_and_demo_operator_sources() do
        content = File.read!(path)

        assert_no_direct_local_route_emitters!(path, content)
      end
    end

    test "external link surfaces stay external and do not use operator_base_path" do
      for path <- [
            "priv/templates/parapet.gen.ui/operator_components.ex.eex",
            "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex"
          ] do
        content = File.read!(path)

        assert content =~ "external_link_url"
        assert content =~ ~S|target="_blank"|
        assert content =~ ~S|rel="noopener noreferrer"|

        for external_surface <-
              Regex.scan(~r/<a [^>]*(external_link_url|href=\{@url\})[^>]*>/, content)
              |> Enum.map(fn [surface | _captures] -> surface end) do
          assert external_surface =~ ~S|target="_blank"|
          assert external_surface =~ ~S|rel="noopener noreferrer"|
          refute external_surface =~ "operator_base_path"
        end
      end
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

      assert content =~ "Escalation status"
      assert content =~ "Escalation Chain"
      assert content =~ "Time Until Next Escalation"
      assert content =~ "@detail.escalation_summary"
      assert content =~ "@detail.timeline_entries"

      assert index_of(content, "Escalation status") <
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

      assert index_of(components_content, "Escalation status") <
               index_of(components_content, "Trigger Next Escalation"),
             "Escalation controls should appear after summary context"

      assert index_of(components_content, "def incident_timeline") <
               index_of(components_content, "Trigger Next Escalation"),
             "Escalation controls should stay below the canonical timeline"
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 48 — RED source-string gate set (FLOW/COPY/A11Y).
  #
  # Wave-1 scaffold (48-01): these assertions pin the exact source-string facts
  # wave-2/3 must satisfy. They are EXPECTED to fail RED against unchanged
  # sources until 48-02/48-03 land. Routing per D-18: template-text facts live
  # here (source-string), rendered-state facts live in the demo smoke test.
  # ---------------------------------------------------------------------------
  describe "Phase 48 source-string gates (RED until wave-2/3)" do
    @router_snippet_path "priv/templates/parapet.gen.ui/router_snippet.ex.eex"
    @demo_router_path "examples/demo_app/lib/demo_app_web/router.ex"

    @operator_live_paths [
      "priv/templates/parapet.gen.ui/operator_live.ex.eex",
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
    ]

    @operator_detail_paths [
      "priv/templates/parapet.gen.ui/operator_detail_live.ex.eex",
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
    ]

    @operator_components_paths [
      "priv/templates/parapet.gen.ui/operator_components.ex.eex",
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex"
    ]

    # COPY-04 bounded refutes scope: every operator-copy-bearing source surface.
    @all_operator_paths @operator_live_paths ++
                          @operator_detail_paths ++ @operator_components_paths

    test "FLOW-04: /parapet/incidents/:id route declared before /parapet/:id catch-all (D-04)" do
      for path <- [@router_snippet_path, @demo_router_path] do
        content = File.read!(path)

        # Scope ordering to the OperatorDetailLive route DECLARATION lines only.
        # A bare /parapet/:id substring also appears inside explanatory comments
        # (e.g. the demo gallery's "declare before the /parapet/:id catch-all"
        # note), which must NOT count as a declaration. A declaration line names
        # OperatorDetailLive AND carries a `live` macro for the route.
        decl_lines =
          content
          |> String.split("\n")
          |> Enum.filter(fn line ->
            line =~ "OperatorDetailLive" and line =~ ~r/\blive[\s(]/ and line =~ "/parapet/"
          end)

        incidents_decl =
          Enum.find(decl_lines, fn line -> line =~ "/parapet/incidents/:id" end)

        catch_all_decl =
          Enum.find(decl_lines, fn line ->
            line =~ "/parapet/:id" and not (line =~ "/parapet/incidents/:id")
          end)

        assert is_binary(incidents_decl),
               "#{path} must declare the /parapet/incidents/:id route on an OperatorDetailLive live line"

        assert is_binary(catch_all_decl),
               "#{path} must declare the /parapet/:id catch-all route on an OperatorDetailLive live line"

        incidents_idx = index_of(content, incidents_decl)
        catch_all_idx = index_of(content, catch_all_decl)

        assert incidents_idx < catch_all_idx,
               "#{path}: /parapet/incidents/:id must be declared before the /parapet/:id catch-all (D-04)"
      end
    end

    test "FLOW-04: route map keeps the explanatory catch-all-last comment (D-04)" do
      router_content = File.read!(@router_snippet_path)
      demo_router_content = File.read!(@demo_router_path)

      # Catch-all-last intent must be documented so a reorder doesn't silently
      # swallow /parapet/actions|history into the detail LiveView.
      assert router_content =~ ~r/:id.*(catch-all|catch all).*(last|LAST)/is or
               router_content =~ ~r/(last|LAST).*:id catch-all/is,
             "router_snippet must document the :id catch-all-last ordering rule"

      assert demo_router_content =~ ~r/(catch-all|catch all)/i,
             "demo router must document the catch-all ordering rule"
    end

    test "FLOW-02: operator_live + operator_detail templates assign :page_title via a page_title/ helper (D-07)" do
      for path <- @operator_live_paths ++ @operator_detail_paths do
        content = File.read!(path)

        assert content =~ ":page_title",
               "#{path} must assign :page_title for the host <.live_title> to consume (FLOW-02/D-07)"

        assert content =~ "page_title(",
               "#{path} must define/use a page_title/ helper that derives the per-page title (FLOW-02/D-07)"
      end
    end

    test "COPY-01: nav labels Respond / Actions / History kept verbatim (D-14)" do
      for path <- @operator_components_paths do
        content = File.read!(path)

        assert content =~ "Respond"
        assert content =~ "Actions"
        assert content =~ "History"
      end
    end

    test "COPY-02/COPY-05: pinned Phase-47 action-rail / preview strings survive (voice-consistency check 6, D-15)" do
      for path <- @operator_components_paths do
        content = File.read!(path)

        assert content =~
                 "Preview scoped changes before execution. No recovery action runs until confirm."

        assert content =~
                 "Execute bounded recovery. Writes a durable audit record with actor, reason, correlation id, and outcome."

        assert content =~
                 "Request the next escalation only after reviewing current status and the canonical timeline. Every request is audited."

        assert content =~
                 "Suppress pending escalation for the displayed bounded window. Every request is audited."
      end
    end

    test "COPY-03: the 10+1 re-authored microcopy strings are pinned verbatim (D-13)" do
      components = File.read!("priv/templates/parapet.gen.ui/operator_components.ex.eex")
      detail = File.read!("priv/templates/parapet.gen.ui/operator_detail_live.ex.eex")

      # runbook_card + preview_panel strings live in operator_components.
      assert components =~ "Untitled runbook"

      assert components =~
               "No runbook description was recorded. Follow the steps below; each one previews before it runs."

      assert components =~
               "This preview reflects scoped changes only — nothing has run. Confirm to execute, or close to discard."

      # Flash + validation strings live in operator_detail_live.
      assert detail =~
               "Incident acknowledged. Audit record and timeline entry written."

      assert detail =~
               "Acknowledge didn't complete — no audit record was written. The incident is unchanged; refresh the timeline, then retry."

      assert detail =~
               "Resolve didn't complete — the incident stays in its current state and no audit record was written. Refresh the timeline, then retry."

      assert detail =~
               "Couldn't record the escalation request — no escalation was triggered. Refresh to confirm current status, then retry."

      assert detail =~
               "Couldn't record the suppression — pending escalation is unchanged. Refresh current status, then retry."

      assert detail =~
               "Suppression window must be a whole number of minutes greater than zero."

      assert detail =~
               "Preview couldn't be generated — nothing has run and the incident is unchanged. Refresh the timeline, then retry."

      assert detail =~
               "Recovery did not execute — nothing was changed and no audit record was written. Refresh the timeline to confirm current state before retrying."
    end

    test "COPY-03: not-found heading + body copy pinned verbatim (D-02)" do
      for path <- @operator_components_paths do
        content = File.read!(path)

        assert content =~ "This incident isn't in the evidence store"

        assert content =~
                 "No durable incident matches this link. It may have been pruned by retention, or the link is stale. Active incidents stay in the response queue until resolved."
      end
    end

    test "COPY-04: bounded-regex refutes — no TODO/FIXME/lorem/placeholder-text leaks (D-18)" do
      for path <- @all_operator_paths do
        content = File.read!(path)

        # Word-boundary placeholder markers. Bounded so the refute does not trip
        # on legitimate substrings (e.g. "today" must NOT match a bare /todo/i).
        refute content =~ ~r/\b(TODO|FIXME|XXX|HACK)\b/,
               "#{path} must not contain TODO/FIXME/XXX/HACK placeholder markers (COPY-04)"

        refute content =~ ~r/\blorem ipsum\b/i,
               "#{path} must not contain lorem ipsum filler (COPY-04)"

        # "placeholder text" only — must NOT match a placeholder= HTML attribute.
        refute content =~ ~r/placeholder text/i,
               "#{path} must not contain literal placeholder text (COPY-04)"
      end
    end

    test "COPY-04: bounded refutes do not match a placeholder= attribute or the word today (D-18)" do
      # Self-check the regex bounds the plan mandates: these legitimate strings
      # must survive the COPY-04 refutes so the gate cannot false-positive.
      legit = ~s(<input placeholder="Search" /> Updated today.)

      refute legit =~ ~r/placeholder text/i
      refute legit =~ ~r/\b(TODO|FIXME|XXX|HACK)\b/
    end

    test "COPY/voice: no inspect( inside user-facing flash strings; no banned constructions (D-15)" do
      detail = File.read!("priv/templates/parapet.gen.ui/operator_detail_live.ex.eex")

      # D-13/D-15 check 1: drop every #{inspect(reason)} from user-facing flashes
      # (Logger.error(inspect(...)) is still allowed server-side).
      refute detail =~ ~r/put_flash\([^)]*inspect\(/s,
             "operator_detail_live must not interpolate inspect(...) into a put_flash user-facing string (D-15)"

      # D-15 check 2: banned tone/bare-verb constructions in operator copy surfaces.
      for path <- @all_operator_paths do
        content = File.read!(path)

        refute content =~ ~r/\bOops\b/i, "#{path}: banned tone word 'Oops' (D-15)"
        refute content =~ ~r/\bSorry\b/i, "#{path}: banned tone word 'Sorry' (D-15)"
        refute content =~ "successfully", "#{path}: filler 'successfully' is banned (D-15)"
        refute content =~ ~r/something went wrong/i, "#{path}: banned phrase (D-15)"
        refute content =~ ~r/\bFailed to\b/, "#{path}: bare 'Failed to' construction banned (D-15)"
      end
    end

    test "A11Y-06: main id + nav landmarks + aria-current + Incident context nav present (source)" do
      for path <- @operator_detail_paths do
        content = File.read!(path)

        assert content =~ ~S|id="parapet-main"|,
               "#{path} must keep the #parapet-main landmark target (A11Y-06)"

        assert content =~ "aria-label",
               "#{path} must keep a labeled nav landmark (A11Y-06)"

        assert content =~ ~S|aria-label="Incident context"|,
               "#{path} must wrap the detail context strip in nav[aria-label=\"Incident context\"] (D-08/A11Y-06)"
      end

      for path <- @operator_components_paths do
        content = File.read!(path)

        assert content =~ ~S|aria-current={if @active, do: "page", else: nil}|,
               "#{path} must keep aria-current on the active nav item (A11Y-06)"
      end
    end
  end

  defp generated_and_demo_operator_sources do
    [
      "priv/templates/parapet.gen.ui/operator_live.ex.eex",
      "priv/templates/parapet.gen.ui/operator_detail_live.ex.eex",
      "priv/templates/parapet.gen.ui/operator_components.ex.eex",
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex",
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex",
      "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex"
    ]
  end

  defp assert_no_direct_local_route_emitters!(path, content) do
    forbidden_patterns = [
      ~r/(navigate|patch|href)="\/parapet/,
      ~r/(navigate|patch|href)=\{"\/parapet/,
      ~r/push_(patch|navigate)\([^)]*"\/parapet/s,
      ~r/push_(patch|navigate)\([^)]*to:\s*"\/parapet/s,
      ~r/(navigate|patch|href)=\{[^}]*operator_base_path[^}]*<>/s
    ]

    for pattern <- forbidden_patterns do
      refute content =~ pattern,
             "expected #{path} not to contain a direct local route emitter matching #{inspect(pattern)}"
    end
  end
end
