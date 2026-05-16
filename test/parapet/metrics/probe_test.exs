defmodule Parapet.Metrics.ProbeTest do
  use ExUnit.Case, async: false

  alias Parapet.Metrics.Probe

  setup do
    on_exit(fn ->
      :telemetry.detach("parapet-probe-run-stop")
      :telemetry.detach("parapet-probe-run-exception")
    end)
    :ok
  end

  describe "setup/0" do
    test "attaches telemetry handlers" do
      Probe.setup()
      
      handlers_stop = :telemetry.list_handlers([:parapet, :probe, :run, :stop])
      assert Enum.any?(handlers_stop, &(&1.id == "parapet-probe-run-stop"))

      handlers_exception = :telemetry.list_handlers([:parapet, :probe, :run, :exception])
      assert Enum.any?(handlers_exception, &(&1.id == "parapet-probe-run-exception"))
    end
  end

  describe "metrics/0" do
    test "defines prometheus metrics safely" do
      metrics = Probe.metrics()
      assert Enum.any?(metrics, fn metric -> metric.name == [:parapet, :probe, :run, :duration, :ms] end)
      assert Enum.any?(metrics, fn metric -> metric.name == [:parapet, :probe, :run, :total] end)
      
      assert Enum.all?(metrics, fn metric -> metric.tags == [:probe, :status] end)
    end
  end

  describe "handle_event/4" do
    test "translates duration to ms and emits unified event" do
      ref = make_ref()
      parent = self()
      
      :telemetry.attach("probe-metrics-test", [:parapet, :probe, :run], fn event, measurements, metadata, _config -> 
        send(parent, {ref, event, measurements, metadata})
      end, nil)

      duration = System.convert_time_unit(100, :millisecond, :native)
      Probe.handle_event([:parapet, :probe, :run, :stop], %{duration: duration}, %{probe: "MyProbe", status: "success"}, %{})

      assert_receive {^ref, [:parapet, :probe, :run], %{duration_ms: 100}, %{probe: "MyProbe", status: "success"}}
      
      :telemetry.detach("probe-metrics-test")
    end

    test "handles exception event without duration" do
      ref = make_ref()
      parent = self()
      
      :telemetry.attach("probe-metrics-test-exception", [:parapet, :probe, :run], fn event, measurements, metadata, _config -> 
        send(parent, {ref, event, measurements, metadata})
      end, nil)

      Probe.handle_event([:parapet, :probe, :run, :exception], %{}, %{probe: "MyProbe", status: "error"}, %{})

      assert_receive {^ref, [:parapet, :probe, :run], %{duration_ms: 0}, %{probe: "MyProbe", status: "error"}}
      
      :telemetry.detach("probe-metrics-test-exception")
    end
  end
end
