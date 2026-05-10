defmodule Parapet.Metrics.HTTPTest do
  use ExUnit.Case, async: false

  alias Parapet.Metrics.HTTP

  test "metrics/0 returns list of Telemetry.Metrics wrapped in try/rescue" do
    metrics = HTTP.metrics()

    assert is_list(metrics)

    assert Enum.all?(metrics, fn m ->
             m.__struct__ in [Telemetry.Metrics.Counter, Telemetry.Metrics.Distribution]
           end)
  end

  test "setup/0 handles ArgumentError smoothly" do
    assert HTTP.setup() == :ok
  end
end
