defmodule Parapet.Plug.MetricsTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  alias Parapet.Plug.Metrics

  test "emits [:parapet, :http, :request] telemetry with route and status class" do
    parent = self()
    ref = make_ref()

    :telemetry.attach(
      "test-http-metrics-1",
      [:parapet, :http, :request],
      fn name, measurements, metadata, _config ->
        send(parent, {ref, name, measurements, metadata})
      end,
      nil
    )

    _conn =
      conn(:get, "/users/1")
      |> put_private(:phoenix_route, "/users/:id")
      |> Metrics.call(Metrics.init([]))
      |> send_resp(200, "ok")

    assert_receive {^ref, [:parapet, :http, :request], measurements, metadata}
    assert metadata.route == "/users/:id"
    assert metadata.status_class == "2xx"
    assert is_integer(measurements.duration_ms) or is_float(measurements.duration_ms)

    :telemetry.detach("test-http-metrics-1")
  end

  test "defaults route to _unknown if no route matched" do
    parent = self()
    ref = make_ref()

    :telemetry.attach(
      "test-http-metrics-2",
      [:parapet, :http, :request],
      fn name, measurements, metadata, _config ->
        send(parent, {ref, name, measurements, metadata})
      end,
      nil
    )

    _conn =
      conn(:get, "/random/path")
      |> Metrics.call(Metrics.init([]))
      |> send_resp(404, "not found")

    assert_receive {^ref, [:parapet, :http, :request], _measurements, metadata}
    assert metadata.route == "_unknown"
    assert metadata.status_class == "4xx"

    :telemetry.detach("test-http-metrics-2")
  end
end
