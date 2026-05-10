defmodule Parapet.Metrics.EctoTest do
  use ExUnit.Case, async: true

  alias Parapet.Metrics.Ecto

  setup do
    # Clear any previous telemetry handlers for clean slate
    :telemetry.detach("parapet-ecto-handler")
    :ok
  end

  test "Test 1: Handle event from [:my_app, :repo, :query] converting native to ms" do
    # Attach the handler
    Ecto.setup([:my_app, :repo])

    test_pid = self()

    # We will attach to the event Ecto handler emits
    :telemetry.attach(
      "test-ecto-emitted",
      [:parapet, :ecto, :query],
      fn _event, measurements, _metadata, _config ->
        send(test_pid, {:telemetry_measurements, measurements})
      end,
      nil
    )

    query_time_native = System.convert_time_unit(10, :millisecond, :native)
    queue_time_native = System.convert_time_unit(5, :millisecond, :native)

    :telemetry.execute(
      [:my_app, :repo, :query],
      %{query_time: query_time_native, queue_time: queue_time_native},
      %{source: "users"}
    )

    assert_receive {:telemetry_measurements, measurements}, 1000
    assert measurements.query_time_ms == 10
    assert measurements.queue_time_ms == 5

    :telemetry.detach("test-ecto-emitted")
  end

  test "Test 2: Set source label to metadata.source or \"_raw\"" do
    Ecto.setup([:my_app, :repo])

    test_pid = self()

    :telemetry.attach(
      "test-ecto-emitted-source",
      [:parapet, :ecto, :query],
      fn _event, _measurements, metadata, _config ->
        send(test_pid, {:telemetry_metadata, metadata})
      end,
      nil
    )

    :telemetry.execute(
      [:my_app, :repo, :query],
      %{query_time: 1000, queue_time: 500},
      %{}
    )

    assert_receive {:telemetry_metadata, metadata}, 1000
    assert metadata.source == "_raw"

    :telemetry.execute(
      [:my_app, :repo, :query],
      %{query_time: 1000, queue_time: 500},
      %{source: "accounts"}
    )

    assert_receive {:telemetry_metadata, metadata2}, 1000
    assert metadata2.source == "accounts"

    :telemetry.detach("test-ecto-emitted-source")
  end

  test "Test 3: Defines separate distributions for query_time_ms and queue_time_ms, wrapped in try/rescue ArgumentError" do
    metrics = Ecto.metrics()

    # Find the distributions
    query_metric =
      Enum.find(metrics, fn m -> m.name == [:parapet, :ecto, :query, :query_time_ms] end)

    queue_metric =
      Enum.find(metrics, fn m -> m.name == [:parapet, :ecto, :query, :queue_time_ms] end)

    assert query_metric.__struct__ == Telemetry.Metrics.Distribution
    assert queue_metric.__struct__ == Telemetry.Metrics.Distribution

    assert query_metric.measurement == :query_time_ms
    assert queue_metric.measurement == :queue_time_ms

    assert :source in query_metric.tags
    assert :source in queue_metric.tags

    assert Ecto.setup([:my_app, :repo]) == :ok
  end
end
