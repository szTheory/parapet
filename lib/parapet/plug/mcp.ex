defmodule Parapet.Plug.MCP do
  @moduledoc """
  A Plug to handle incoming MCP connections via HTTP SSE.
  Accepts JSON-RPC POST requests and streams responses back as SSE chunks.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.

  **Security Note:**
  Authentication and authorization to the MCP endpoint must be handled by the
  host application's router pipeline *before* requests reach `Parapet.Plug.MCP`.
  This plug does not perform any authentication checks internally.
  """

  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%{method: "POST"} = conn, _opts) do
    # Ensure chunked response headers are set for SSE
    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> send_chunked(200)

    payload = conn.body_params || %{}

    # Basic JSON-RPC handling
    id = Map.get(payload, "id")
    method = Map.get(payload, "method")

    cond do
      method == "tools/call" ->
        params = Map.get(payload, "params", %{})
        tool_name = Map.get(params, "name")
        tool_args = Map.get(params, "arguments", %{})

        case Parapet.MCP.Server.execute_tool(tool_name, tool_args) do
          {:ok, result} ->
            response = %{
              "jsonrpc" => "2.0",
              "id" => id,
              "result" => result
            }

            send_sse_response(conn, response)

          {:error, :unknown_tool} ->
            response = %{
              "jsonrpc" => "2.0",
              "id" => id,
              "error" => %{
                "code" => -32601,
                "message" => "Method not found"
              }
            }

            send_sse_response(conn, response)

          {:error, _reason} ->
            response = %{
              "jsonrpc" => "2.0",
              "id" => id,
              "error" => %{
                "code" => -32000,
                "message" => "Internal error"
              }
            }

            send_sse_response(conn, response)
        end

      method == "ping" ->
        response = %{
          "jsonrpc" => "2.0",
          "id" => id,
          "result" => %{}
        }

        send_sse_response(conn, response)

      true ->
        response = %{
          "jsonrpc" => "2.0",
          "id" => id,
          "error" => %{
            "code" => -32601,
            "message" => "Method not found"
          }
        }

        send_sse_response(conn, response)
    end
  end

  @impl true
  def call(conn, _opts) do
    conn
    |> send_resp(405, "Method Not Allowed")
  end

  defp send_sse_response(conn, response) do
    data = Jason.encode!(response)
    {:ok, conn} = chunk(conn, "event: message\ndata: #{data}\n\n")
    conn
  end
end
