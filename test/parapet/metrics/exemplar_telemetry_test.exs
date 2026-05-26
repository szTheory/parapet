defmodule Parapet.Metrics.ExemplarTelemetryTest do
  use ExUnit.Case, async: false

  alias Parapet.Metrics.ExemplarStore
  alias Parapet.Metrics.ExemplarTelemetry

  setup do
    start_supervised!(ExemplarStore)
    :ok
  end

  test "attaches telemetry handlers and records trace IDs for HTTP requests" do
    ExemplarTelemetry.attach()

    # Fire a telemetry event with a trace_id in metadata
    :telemetry.execute(
      [:parapet, :http, :request],
      %{duration_ms: 100},
      %{route: "/api", method: "GET", trace_id: "trace-http-123"}
    )

    # Allow async telemetry handlers to run
    Process.sleep(10)

    # Verify ExemplarStore recorded the trace_id
    assert ExemplarStore.get_trace("parapet_http_request_duration_ms", %{
             route: "/api",
             method: "GET"
           }) == "trace-http-123"
  end

  test "attaches telemetry handlers and records trace IDs for Oban jobs" do
    ExemplarTelemetry.attach()

    :telemetry.execute(
      [:parapet, :oban, :job],
      %{duration_ms: 50},
      %{worker: "MyWorker", queue: "default", state: "success", trace_id: "trace-oban-456"}
    )

    Process.sleep(10)

    assert ExemplarStore.get_trace("parapet_oban_job_duration_ms", %{
             worker: "MyWorker",
             queue: "default",
             state: "success"
           }) == "trace-oban-456"
  end

  test "does not crash or record if trace_id is missing" do
    ExemplarTelemetry.attach()

    :telemetry.execute(
      [:parapet, :http, :request],
      %{duration_ms: 100},
      %{route: "/no-trace", method: "GET"}
    )

    Process.sleep(10)

    assert ExemplarStore.get_trace("parapet_http_request_duration_ms", %{
             route: "/no-trace",
             method: "GET"
           }) == nil
  end
end
