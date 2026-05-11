defmodule Parapet.Plug.WebhookTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Parapet.Plug.Webhook

  @opts Webhook.init([])

  test "POST request with body returns 202 Accepted and JSON status 'accepted'" do
    conn =
      conn(:post, "/webhook", %{"alerts" => []})
      |> put_req_header("content-type", "application/json")
      |> Webhook.call(@opts)

    assert conn.state == :sent
    assert conn.status == 202
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert Jason.decode!(conn.resp_body) == %{"status" => "accepted"}
  end

  test "GET request returns 405 Method Not Allowed" do
    conn =
      conn(:get, "/webhook")
      |> Webhook.call(@opts)

    assert conn.state == :sent
    assert conn.status == 405
  end
end
