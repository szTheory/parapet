defmodule Parapet.Plug.Metrics do
  @moduledoc """
  A plug for extracting HTTP metrics and emitting them as Telemetry events.
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    start_time = System.monotonic_time()

    register_before_send(conn, fn conn ->
      duration_native = System.monotonic_time() - start_time
      duration_ms = System.convert_time_unit(duration_native, :native, :millisecond)

      route = conn.private[:phoenix_route] || "_unknown"
      status_class = "#{div(conn.status, 100)}xx"

      # Validate labels through Parapet.Internal.LabelPolicy
      Parapet.Internal.LabelPolicy.assert_safe!([:route, :method, :status_class])

      :telemetry.execute(
        [:parapet, :http, :request],
        %{duration_ms: duration_ms, status_code: conn.status},
        %{route: route, method: conn.method, status_class: status_class}
      )

      conn
    end)
  end
end
