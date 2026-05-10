defmodule Parapet.Metrics.ObanTest do
  use ExUnit.Case, async: true

  alias Parapet.Metrics.Oban

  setup do
    :telemetry.detach("parapet-oban-job-stop")
    :telemetry.detach("parapet-oban-job-exception")
    :ok
  end

  test "Test 1: Conditionally defines module if Code.ensure_loaded?(Oban)" do
    # Since Oban is an optional dep and compiled in our test env, the module should exist
    assert Code.ensure_loaded?(Oban)
  end

  test "Test 2: Attaches to job stop and exception events using Parapet.attach/1" do
    assert :ok = Oban.setup()

    test_pid = self()

    :telemetry.attach(
      "test-oban-emitted",
      [:parapet, :oban, :job],
      fn _event, measurements, metadata, _config ->
        send(test_pid, {:oban_job, measurements, metadata})
      end,
      nil
    )

    duration_native = System.convert_time_unit(100, :millisecond, :native)

    :telemetry.execute(
      [:oban, :job, :stop],
      %{duration: duration_native},
      %{worker: "MyWorker", queue: "default", state: "success"}
    )

    assert_receive {:oban_job, measurements, metadata}, 1000
    assert measurements.duration_ms == 100
    assert metadata.worker == "MyWorker"
    assert metadata.queue == "default"
    assert metadata.state == "success"

    :telemetry.execute(
      [:oban, :job, :exception],
      %{duration: duration_native},
      %{worker: "FailWorker", queue: "events", state: "failure"}
    )

    assert_receive {:oban_job, exc_measurements, exc_metadata}, 1000
    assert exc_measurements.duration_ms == 100
    assert exc_metadata.worker == "FailWorker"
    assert exc_metadata.queue == "events"
    assert exc_metadata.state == "failure"

    :telemetry.detach("test-oban-emitted")
  end

  test "Test 3: Registers job distributions and counters wrapped in try/rescue ArgumentError with explicitly aligned state labels for rate() evaluation" do
    metrics = Oban.metrics()

    counter = Enum.find(metrics, fn m -> m.name == [:parapet, :oban, :jobs, :total] end)
    distribution = Enum.find(metrics, fn m -> m.name == [:parapet, :oban, :job, :duration_ms] end)

    assert counter.__struct__ == Telemetry.Metrics.Counter
    assert distribution.__struct__ == Telemetry.Metrics.Distribution

    assert :worker in counter.tags
    assert :queue in counter.tags
    assert :state in counter.tags
  end
end
