defmodule Parapet.Plug.MCPTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Parapet.Plug.MCP

  defmodule DummyRepo do
    def all(_query), do: []
  end

  setup do
    Application.put_env(:parapet, :repo, DummyRepo)
    :ok
  end

  @opts MCP.init([])

  test "rejects non-POST requests with 405 Method Not Allowed" do
    conn = conn(:get, "/mcp") |> MCP.call(@opts)
    assert conn.status == 405
  end

  test "sets proper SSE headers on POST" do
    conn = conn(:post, "/mcp", %{"jsonrpc" => "2.0", "method" => "ping"}) 
    |> put_req_header("content-type", "application/json")
    |> MCP.call(@opts)

    assert conn.status == 200
    assert get_resp_header(conn, "content-type") == ["text/event-stream"]
    assert get_resp_header(conn, "cache-control") == ["no-cache"]
  end

  test "parses JSON-RPC request and returns appropriate JSON-RPC response over SSE" do
    # For a real integration we might use a mock, but Parapet.MCP.Server is available.
    # We can pass an unknown tool to trigger execute_tool behavior.
    payload = %{
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => %{
        "name" => "unknown_tool",
        "arguments" => %{}
      },
      "id" => 1
    }

    conn = conn(:post, "/mcp", payload)
    |> put_req_header("content-type", "application/json")
    |> MCP.call(@opts)

    assert conn.status == 200
    assert conn.state == :chunked

    # Extract chunk from test conn (Plug.Test accumulates chunks in conn.resp_body)
    # The response is sent using `chunk`, which adds to `conn.resp_body`.
    body = conn.resp_body
    assert body =~ "event: message\n"
    assert body =~ "data: "

    # Parse the data payload
    data_match = Regex.run(~r/data: (.*)\n\n/, body)
    assert [_full, data_str] = data_match

    response = Jason.decode!(data_str)
    assert response["jsonrpc"] == "2.0"
    assert response["id"] == 1
    # unknown_tool returns {:error, :unknown_tool}, which the plug should map to an error response
    assert response["error"]["code"] == -32601 # Method not found
  end

  test "formats successful Server response back into JSON-RPC over SSE" do
    # We will test a known tool, e.g., "list_incidents"
    payload = %{
      "jsonrpc" => "2.0",
      "method" => "tools/call",
      "params" => %{
        "name" => "list_incidents",
        "arguments" => %{}
      },
      "id" => 2
    }

    # To isolate, we might need a dummy repo, but since `list_incidents` returns `{:ok, []}` when db is empty.
    # We can just verify the structure.
    conn = conn(:post, "/mcp", payload)
    |> put_req_header("content-type", "application/json")
    |> MCP.call(@opts)

    assert conn.status == 200

    body = conn.resp_body
    data_match = Regex.run(~r/data: (.*)\n\n/, body)
    assert [_full, data_str] = data_match

    response = Jason.decode!(data_str)
    assert response["jsonrpc"] == "2.0"
    assert response["id"] == 2
    assert response["result"] != nil
  end
end