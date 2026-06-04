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
    assert conn.resp_body =~ "resolved history smoke incident"
  end

  test "GET /ops/parapet/history returns 200", %{conn: conn} do
    {:ok, _incident} =
      Parapet.Evidence.create_incident(%{
        title: "scoped resolved history smoke incident",
        state: "resolved"
      })

    conn = get(conn, "/ops/parapet/history")
    assert conn.status == 200
    assert conn.resp_body =~ "scoped resolved history smoke incident"
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
end
