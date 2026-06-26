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
end
