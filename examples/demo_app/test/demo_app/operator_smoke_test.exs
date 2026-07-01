defmodule DemoApp.OperatorSmokeTest do
  use DemoAppWeb.ConnCase

  @moduletag :smoke

  test "GET /parapet returns 200", %{conn: conn} do
    conn = get(conn, "/parapet")
    assert conn.status == 200
  end

  test "GET /parapet/actions returns 200", %{conn: conn} do
    conn = get(conn, "/parapet/actions")
    assert conn.status == 200
  end

  test "GET /ops/parapet returns 200", %{conn: conn} do
    conn = get(conn, "/ops/parapet")
    assert conn.status == 200
  end

  test "GET /ops/parapet/actions returns 200", %{conn: conn} do
    conn = get(conn, "/ops/parapet/actions")
    assert conn.status == 200
  end

  test "GET /parapet/history returns 200", %{conn: conn} do
    {:ok, _incident} =
      Parapet.Evidence.create_incident(%{
        title: "resolved history smoke incident",
        state: "resolved"
      })

    conn = get(conn, "/parapet/history")
    assert conn.status == 200

    # 48-03 (D-09/D-10): the History list now renders behind the connected-keyed
    # skeleton, so the seeded incident appears on the connected render (not the
    # disconnected static body, which shows the skeleton-or-nothing affordance).
    {:ok, _view, connected_html} = live(conn, "/parapet/history")
    assert connected_html =~ "resolved history smoke incident"
  end

  test "GET /ops/parapet/history returns 200", %{conn: conn} do
    {:ok, _incident} =
      Parapet.Evidence.create_incident(%{
        title: "scoped resolved history smoke incident",
        state: "resolved"
      })

    conn = get(conn, "/ops/parapet/history")
    assert conn.status == 200

    {:ok, _view, connected_html} = live(conn, "/ops/parapet/history")
    assert connected_html =~ "scoped resolved history smoke incident"
  end

  test "at least one seeded incident exists" do
    # Insert an incident within the sandboxed connection so this test is
    # self-contained and does not depend on `mix run priv/repo/seeds.exs`
    # having populated the (separate, non-sandbox) dev DB (RESEARCH.md Pitfall 3).
    {:ok, _} =
      Parapet.Evidence.create_incident(%{
        title: "smoke test incident",
        state: "open"
      })

    assert DemoApp.Repo.aggregate(Parapet.Spine.Incident, :count) > 0
  end

  test "preferred and compatibility incident detail routes render", %{conn: conn} do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "detail route smoke incident",
        state: "open"
      })

    preferred = get(conn, "/parapet/incidents/#{incident.id}")
    assert preferred.status == 200
    assert preferred.resp_body =~ "detail route smoke incident"

    compatibility = get(recycle(conn), "/parapet/#{incident.id}")
    assert compatibility.status == 200
    assert compatibility.resp_body =~ "detail route smoke incident"
  end

  test "scoped preferred and compatibility incident detail routes render", %{conn: conn} do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "scoped detail route smoke incident",
        state: "open"
      })

    preferred = get(conn, "/ops/parapet/incidents/#{incident.id}")
    assert preferred.status == 200
    assert preferred.resp_body =~ "scoped detail route smoke incident"

    compatibility = get(recycle(conn), "/ops/parapet/#{incident.id}")
    assert compatibility.status == 200
    assert compatibility.resp_body =~ "scoped detail route smoke incident"
  end

  test "resolved incident detail is read-only and retrospective friendly", %{conn: conn} do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "resolved detail review incident",
        state: "resolved",
        runbook_data: %{
          "retrospective" => """
          # Resolved detail review incident

          Impact stopped after the provider recovered. Follow-up: keep the SLO threshold unchanged.
          """
        }
      })

    conn = get(conn, "/parapet/incidents/#{incident.id}")

    assert conn.status == 200
    assert conn.resp_body =~ "Resolved incident review"
    assert conn.resp_body =~ "Incident retrospective"
    assert conn.resp_body =~ "Copy retrospective"
    assert conn.resp_body =~ "Resolved incident"
    refute conn.resp_body =~ "Resolve Incident"
    refute conn.resp_body =~ "Trigger Next Escalation"
    refute conn.resp_body =~ "Suppress Pending Escalation"
    refute conn.resp_body =~ "Automated Retrospective"
    refute conn.resp_body =~ "Copy to Clipboard"
    refute conn.resp_body =~ "alert("
  end

  # ---------------------------------------------------------------------------
  # Phase 55 — SAFE-03 smoke assertions: schema-prefix round-trip + six-table
  # existence. These tests are top-level (not inside a describe block) so the
  # module @moduletag :smoke applies and mix test --only smoke picks them up.
  # ---------------------------------------------------------------------------

  test "schema prefix: evidence round-trip carries compiled prefix on returned struct" do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "schema prefix smoke proof",
        state: "open"
      })

    assert Ecto.get_meta(incident, :prefix) == Parapet.Evidence.schema_prefix(),
           "create_incident round-trip: expected prefix #{inspect(Parapet.Evidence.schema_prefix())}, " <>
             "got #{inspect(Ecto.get_meta(incident, :prefix))}"
  end

  test "schema existence: all six spine tables exist in the configured schema" do
    prefix = Parapet.Evidence.schema_prefix() || "public"

    result =
      Ecto.Adapters.SQL.query!(
        DemoApp.Repo,
        "SELECT table_name FROM information_schema.tables WHERE table_schema = $1",
        [prefix]
      )

    found = result.rows |> Enum.map(fn [name] -> name end) |> MapSet.new()

    expected =
      MapSet.new([
        "parapet_action_items",
        "parapet_incidents",
        "parapet_timeline_entries",
        "parapet_tool_audits",
        "parapet_system_events",
        "parapet_action_claims"
      ])

    missing = MapSet.difference(expected, found)

    assert MapSet.size(missing) == 0,
           "Expected all six Parapet spine tables in schema #{inspect(prefix)}, " <>
             "missing: #{inspect(MapSet.to_list(missing))}"
  end

  # ---------------------------------------------------------------------------
  # Phase 48 — RED rendered-state gate set (FLOW-02/03, A11Y-06).
  #
  # Wave-1 scaffold (48-01): rendered-state facts that source greps are
  # structurally blind to (single-h1 composition, in-page not-found, page_title
  # assign, disconnected skeleton, empty-during-load gate, landmarks). EXPECTED
  # to fail RED against unchanged sources until 48-02/48-03 land. Routing per
  # D-18: rendered-state facts live here in the demo Phoenix.LiveViewTest
  # harness, NOT in the lib source-string loops.
  #
  # h1 counting uses Regex.scan over rendered html — NOT Floki (DOM backend is
  # lazy_html, element/2 raises on >1 match) and NOT a source grep (two legit
  # h1 definitions compose onto one page).
  # ---------------------------------------------------------------------------
  # The apostrophe is HTML-escaped to &#39; in the rendered LiveView output, so
  # the rendered-state assertion must match the escaped form (48-03 Rule 1 fix —
  # a literal-apostrophe match can never pass against render/1 HTML output).
  @not_found_copy "This incident isn&#39;t in the evidence store"

  describe "Phase 48 rendered-state gates (RED until wave-2/3)" do
    test "FLOW-02: each operator page renders exactly one h1", %{conn: conn} do
      # Seed a resolved incident so the History page has content, and an open
      # incident so the queue-with-selected-incident state composes the detail
      # summary h1 onto the response page.
      {:ok, resolved} =
        Parapet.Evidence.create_incident(%{
          title: "single-h1 resolved incident",
          state: "resolved"
        })

      {:ok, active} =
        Parapet.Evidence.create_incident(%{
          title: "single-h1 active incident",
          state: "open"
        })

      static_paths = [
        "/parapet",
        "/parapet/actions",
        "/parapet/history",
        "/parapet/incidents/#{active.id}",
        # queue-with-a-selected-incident: detail summary embeds in the cockpit
        "/parapet/#{active.id}"
      ]

      for path <- static_paths do
        conn = get(conn, path)
        html = conn.resp_body
        h1_count = length(Regex.scan(~r/<h1[\s>]/, html))

        assert h1_count == 1,
               "Expected exactly one <h1> on #{path}, got #{h1_count} (FLOW-02/D-06)"
      end

      _ = resolved
    end

    test "FLOW-03: detail with unknown UUID renders the not-found panel in-page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/parapet/incidents/#{Ecto.UUID.generate()}")

      assert render(view) =~ @not_found_copy,
             "An unknown but well-formed UUID must render the designed in-page not-found panel (FLOW-03/D-02)"
    end

    test "FLOW-03: detail with a malformed id renders the not-found panel in-page (not a 500)",
         %{conn: conn} do
      # /parapet/123 is the common stale-link/scanner case: a malformed binary_id
      # currently raises Ecto.Query.CastError → uncaught 500. The designed
      # not-found panel must absorb it (D-01 Ecto.UUID.cast precheck collapses
      # the CastError class), rendering the same in-page copy.
      {:ok, view, _html} = live(conn, "/parapet/123")

      assert render(view) =~ @not_found_copy,
             "A malformed id must collapse to the in-page not-found panel, not a 500 (FLOW-03/D-01/D-02)"
    end

    test "FLOW-02: page titles are assigned per page via page_title(view)", %{conn: conn} do
      {:ok, view, _} = live(conn, "/parapet")

      assert page_title(view) =~ "Active response",
             "Response page must assign :page_title 'Active response' (read via page_title/1, never the host <title>) (FLOW-02/D-07)"

      {:ok, view, _} = live(conn, "/parapet/actions")
      assert page_title(view) =~ "Action queue", "Actions page :page_title (FLOW-02/D-07)"

      {:ok, view, _} = live(conn, "/parapet/history")
      assert page_title(view) =~ "Resolved history", "History page :page_title (FLOW-02/D-07)"

      {:ok, incident} =
        Parapet.Evidence.create_incident(%{title: "page-title detail incident", state: "open"})

      {:ok, view, _} = live(conn, "/parapet/incidents/#{incident.id}")

      assert page_title(view) =~ "Incident:",
             "Detail page :page_title must be 'Incident: <title>' (FLOW-02/D-07)"
    end

    test "FLOW-03: disconnected static render carries the uniform skeleton on all list pages",
         %{conn: conn} do
      for path <- ["/parapet", "/parapet/actions", "/parapet/history"] do
        html = get(conn, path).resp_body

        assert html =~ "animate-pulse",
               "#{path} static (disconnected) render must include the animate-pulse skeleton (FLOW-03/D-09)"

        assert html =~ ~s(aria-busy="true"),
               "#{path} static render must mark the loading region aria-busy=\"true\" (FLOW-03/D-09)"

        refute html =~ ~r/>\s*Loading\b/,
               "#{path} skeleton must not bake a literal Loading… string — ARIA only (D-09)"
      end
    end

    test "FLOW-03: empty state renders only on the connected render, not during disconnected load",
         %{conn: conn} do
      # With no resolved incidents seeded, History's connected render shows the
      # designed empty state, while the disconnected static render must NOT (the
      # @socket_connected and Enum.empty? gate closes the empty-during-load lie).
      static_html = get(conn, "/parapet/history").resp_body
      {:ok, view, _} = live(conn, "/parapet/history")
      connected_html = render(view)

      assert connected_html =~ ~r/No\b.*\b(resolved|incidents|history)/i,
             "Connected History render with no items must show the designed empty state (FLOW-03/D-10/D-11)"

      refute static_html =~ ~r/No\b.*\b(resolved|incidents|history)/i,
             "Disconnected static render must NOT show the empty state during load (FLOW-03/D-10)"
    end

    test "A11Y-06: connected detail mount exposes the main + nav landmarks", %{conn: conn} do
      {:ok, incident} =
        Parapet.Evidence.create_incident(%{title: "landmark detail incident", state: "open"})

      {:ok, view, _} = live(conn, "/parapet/incidents/#{incident.id}")

      assert has_element?(view, "main#parapet-main"),
             "Detail page must expose main#parapet-main landmark (A11Y-06)"

      assert has_element?(view, "nav[aria-label]"),
             "Detail page must expose a labeled nav landmark (A11Y-06)"
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 49 — gallery render contract + fixture-existence pins (GALLERY-02,
  # FIXTURE-01..05).
  #
  # D-12 RED cadence: Task 1 (gallery route test) is expected to pass GREEN
  # immediately — the route already exists. Tasks 2 and 3 are RED scaffold
  # assertions written BEFORE the seed scenarios are implemented (49-02) or
  # the capture script is updated (49-03). The aggregate non-zero exit at the
  # end of 49-01 is the intended RED state.
  # ---------------------------------------------------------------------------

  describe "Phase 49 gallery + fixture coverage" do
    # ── Task 1: GALLERY-02 route render contract ──────────────────────────────
    # Asserts GET /parapet/_gallery returns 200 with operator-component markers
    # against an empty (unseeded) sandbox — proving the route is DB-independent
    # and is NOT swallowed by the /parapet/:id catch-all.  This test passes
    # green immediately (the route and GalleryLive already exist).
    test "GET /parapet/_gallery returns 200 with operator-component markers (GALLERY-02)", %{conn: conn} do
      conn = get(conn, "/parapet/_gallery")

      assert conn.status == 200,
             "GET /parapet/_gallery must return 200 — route must not be swallowed by /parapet/:id catch-all (GALLERY-02)"

      assert conn.resp_body =~ "parapet-ui",
             "/parapet/_gallery must render the .parapet-ui wrapper class (GALLERY-02)"

      assert conn.resp_body =~ "Parapet Operator UI Gallery",
             "/parapet/_gallery must render the gallery heading text (GALLERY-02)"

      assert conn.resp_body =~ "po-operator-title",
             "/parapet/_gallery must render the po-operator-title nav class (GALLERY-02)"

      assert conn.resp_body =~ "po-chip",
             "/parapet/_gallery must render the po-chip status-chip class (GALLERY-02)"
    end

    # ── Task 2: FIXTURE-01..05 fixture-existence pins (RED until 49-02) ──────
    # Each test self-seeds inside the Ecto sandbox (rolled back after the test)
    # and asserts the expected shape.  All five will fail RED with an
    # ArgumentError until plan 49-02 adds the seed clauses.

    # FIXTURE-05 registry: every new scenario name must be registered in
    # DemoSeedScenarios.scenarios/0 so the typo-guard clause cannot fire.
    test "FIXTURE-05: all five new scenario names are registered in DemoSeedScenarios.scenarios/0" do
      registered = DemoApp.DemoSeedScenarios.scenarios()

      for name <- ~w(long_string empty max_items mixed_status stress) do
        assert name in registered,
               "scenario #{inspect(name)} must appear in DemoSeedScenarios.scenarios/0 (FIXTURE-05)"
      end
    end

    # FIXTURE-02: empty scenario seeds zero incidents and zero action items.
    test "FIXTURE-02: seed('empty') produces 0 incidents and 0 action items" do
      DemoApp.DemoSeedScenarios.seed("empty")

      assert DemoApp.Repo.aggregate(Parapet.Spine.Incident, :count) == 0,
             "seed('empty') must leave Incident table empty (FIXTURE-02)"

      assert DemoApp.Repo.aggregate(Parapet.Spine.ActionItem, :count) == 0,
             "seed('empty') must leave ActionItem table empty (FIXTURE-02)"
    end

    # FIXTURE-03: max_items scenario seeds more than 30 active (open/investigating)
    # incidents so the default queue page boundary is crossed.
    test "FIXTURE-03: seed('max_items') seeds >30 active incidents (crosses page boundary)" do
      import Ecto.Query

      DemoApp.DemoSeedScenarios.seed("max_items")

      active_count =
        DemoApp.Repo.aggregate(
          from(i in Parapet.Spine.Incident, where: i.state in ["open", "investigating"]),
          :count
        )

      assert active_count > 30,
             "seed('max_items') must produce >30 active (open/investigating) incidents for page-boundary crossing (FIXTURE-03); got #{active_count}"
    end

    # FIXTURE-04: mixed_status scenario seeds incidents covering all three states
    # (open, investigating, resolved) and at least one open action item.
    test "FIXTURE-04: seed('mixed_status') covers all three incident states and has open action items" do
      import Ecto.Query

      DemoApp.DemoSeedScenarios.seed("mixed_status")

      seeded_states =
        DemoApp.Repo.all(from(i in Parapet.Spine.Incident, select: i.state))
        |> MapSet.new()

      required_states = MapSet.new(["open", "investigating", "resolved"])

      assert MapSet.subset?(required_states, seeded_states),
             "seed('mixed_status') must seed incidents covering open, investigating, AND resolved states (FIXTURE-04); got #{inspect(seeded_states)}"

      open_item_count =
        DemoApp.Repo.aggregate(
          from(ai in Parapet.Spine.ActionItem, where: ai.state == "open"),
          :count
        )

      assert open_item_count >= 1,
             "seed('mixed_status') must seed at least one open action item (FIXTURE-04); got #{open_item_count}"
    end

    # FIXTURE-01: long_string scenario seeds at least one incident with a title
    # longer than 60 characters confirming machine-shaped long-string fields.
    test "FIXTURE-01: seed('long_string') seeds at least one incident with a title >60 chars" do
      DemoApp.DemoSeedScenarios.seed("long_string")

      total = DemoApp.Repo.aggregate(Parapet.Spine.Incident, :count)

      assert total >= 1,
             "seed('long_string') must seed at least one incident (FIXTURE-01)"

      titles = DemoApp.Repo.all(Parapet.Spine.Incident) |> Enum.map(& &1.title)

      long_title_exists = Enum.any?(titles, fn t -> is_binary(t) and String.length(t) > 60 end)

      assert long_title_exists,
             "seed('long_string') must seed at least one incident whose title exceeds 60 chars (FIXTURE-01); longest was #{titles |> Enum.map(&String.length/1) |> Enum.max(fn -> 0 end)}"
    end

    # FIXTURE-05: stress scenario seeds at least one active (open/investigating)
    # incident — the precondition for the capture-script DETAIL_ID query.
    test "FIXTURE-05: seed('stress') seeds at least one active (open/investigating) incident" do
      import Ecto.Query

      DemoApp.DemoSeedScenarios.seed("stress")

      active_count =
        DemoApp.Repo.aggregate(
          from(i in Parapet.Spine.Incident, where: i.state in ["open", "investigating"]),
          :count
        )

      assert active_count >= 1,
             "seed('stress') must produce at least one active incident for DETAIL_ID capture (FIXTURE-05); got #{active_count}"
    end

    # ── Task 3: GALLERY-02 capture-script static grep pin (RED until 49-03) ──
    # Reads the capture script from disk and counts lines that contain both
    # "capture" and "_gallery" (plain `_gallery` comments excluded).
    # Fails RED until plan 49-03 adds the four gallery capture lines.
    test "GALLERY-02 script: capture_operator_ui_screenshots.sh covers /parapet/_gallery 4 times (desktop+mobile, light+dark)" do
      script_path =
        Path.join([File.cwd!(), "scripts", "capture_operator_ui_screenshots.sh"])

      assert File.exists?(script_path),
             "capture_operator_ui_screenshots.sh not found at #{script_path}"

      gallery_capture_lines =
        script_path
        |> File.read!()
        |> String.split("\n")
        |> Enum.count(fn line -> String.contains?(line, "capture") and String.contains?(line, "_gallery") end)

      assert gallery_capture_lines >= 4,
             "capture_operator_ui_screenshots.sh must contain at least 4 lines with both 'capture' and '_gallery' (desktop-light, desktop-dark, mobile-light, mobile-dark); found #{gallery_capture_lines} (GALLERY-02 script coverage)"
    end
  end
end
