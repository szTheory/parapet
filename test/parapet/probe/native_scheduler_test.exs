defmodule Parapet.Probe.NativeSchedulerTest do
  use ExUnit.Case, async: true

  alias Parapet.Probe.NativeScheduler

  defmodule TestProbe do
    use Parapet.Probe

    @impl true
    def run do
      send(:test_process, :probe_executed)
      if Process.get(:test_fail), do: {:error, :fail}, else: :ok
    end
  end

  test "starts and schedules probes" do
    Process.register(self(), :test_process)

    # Schedule TestProbe to run every 10ms
    probes = [{TestProbe, 10}]

    {:ok, pid} = start_supervised({NativeScheduler, probes})

    # Wait for the probe to execute
    assert_receive :probe_executed, 100

    # It should run continuously
    assert_receive :probe_executed, 100
  end
end
