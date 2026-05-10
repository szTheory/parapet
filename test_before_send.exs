defmodule TestPlug do
  import Plug.Conn
  def init(opts), do: opts
  def call(conn, _opts) do
    register_before_send(conn, fn conn ->
      IO.puts("Before send called! Status: #{conn.status}, Route: #{inspect(conn.private[:phoenix_route])}")
      conn
    end)
  end
end
