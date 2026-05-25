defmodule DemoApp.ParapetInstrumenter do
  @moduledoc "Host-owned telemetry instrumentation for Parapet."

  def setup do
    Parapet.Metrics.Probe.setup()
    :ok
  end
end
