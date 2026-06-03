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
end
