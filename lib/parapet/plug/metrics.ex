defmodule Parapet.Plug.Metrics do
  @moduledoc """
  A plug for extracting HTTP metrics and emitting them as Telemetry events.
  """
  @behaviour Plug

  import Plug.Conn

  alias Parapet.Internal.LabelPolicy

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
      LabelPolicy.assert_safe!([:route, :method, :status_class])

      metadata = %{route: route, method: conn.method, status_class: status_class}

      metadata =
        if trace_id = get_trace_id() do
          Map.put(metadata, :trace_id, to_string(trace_id))
        else
          metadata
        end

      :telemetry.execute(
        [:parapet, :http, :request],
        %{duration_ms: duration_ms, status_code: conn.status},
        metadata
      )

      conn
    end)
  end

  defp get_trace_id do
    if Code.ensure_loaded?(:opentelemetry) and function_exported?(OpenTelemetry.Tracer, :current_span_ctx, 0) do
      span_ctx = OpenTelemetry.Tracer.current_span_ctx()

      if span_ctx != :undefined do
        OpenTelemetry.Span.hex_trace_id(span_ctx)
      end
    end
  rescue
    _ -> nil
  end
end
