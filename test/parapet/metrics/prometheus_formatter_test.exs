defmodule Parapet.Metrics.PrometheusFormatterTest do
  use ExUnit.Case, async: false

  alias Parapet.Metrics.ExemplarStore
  alias Parapet.Metrics.PrometheusFormatter

  setup do
    start_supervised!(ExemplarStore)
    :ok
  end

  test "appends exemplars to prometheus lines when trace_id is found" do
    ExemplarStore.record_trace(
      "parapet_http_request_duration_ms",
      %{method: "GET", route: "/api", status_class: "2xx"},
      "trace-123"
    )

    input = """
    # HELP parapet_http_request_duration_ms Duration
    # TYPE parapet_http_request_duration_ms histogram
    parapet_http_request_duration_ms_bucket{method="GET",route="/api",status_class="2xx",le="10"} 0
    parapet_http_request_duration_ms_bucket{method="GET",route="/api",status_class="2xx",le="50"} 1
    parapet_http_request_duration_ms_count{method="GET",route="/api",status_class="2xx"} 1
    parapet_http_request_duration_ms_bucket{method="POST",route="/login",status_class="2xx",le="10"} 0
    """

    expected =
      """
      # HELP parapet_http_request_duration_ms Duration
      # TYPE parapet_http_request_duration_ms histogram
      parapet_http_request_duration_ms_bucket{method="GET",route="/api",status_class="2xx",le="10"} 0 # {trace_id="trace-123"}
      parapet_http_request_duration_ms_bucket{method="GET",route="/api",status_class="2xx",le="50"} 1 # {trace_id="trace-123"}
      parapet_http_request_duration_ms_count{method="GET",route="/api",status_class="2xx"} 1 # {trace_id="trace-123"}
      parapet_http_request_duration_ms_bucket{method="POST",route="/login",status_class="2xx",le="10"} 0
      """
      |> String.trim()

    output = PrometheusFormatter.process(input)
    assert output == expected
  end
end
