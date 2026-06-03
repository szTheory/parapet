defmodule Parapet.Probe.NativeScheduler do
  @moduledoc """
  A simple GenServer-based scheduler for executing synthetic probes.

  It uses `:timer.send_interval/2` to periodically trigger probe executions.
  Useful for standalone or non-clustered setups.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  use GenServer

  @doc """
  Starts the NativeScheduler.

  ## Options

  The first argument should be a list of probes and their intervals in milliseconds.
  For example: `[{MyProbe, 60_000}]`
  """
  def start_link(probes) when is_list(probes) do
    GenServer.start_link(__MODULE__, probes)
  end

  @impl true
  def init(probes) do
    Enum.each(probes, fn {probe_module, interval_ms} ->
      :timer.send_interval(interval_ms, {:run_probe, probe_module})
    end)

    {:ok, probes}
  end

  @impl true
  def handle_info({:run_probe, probe_module}, state) do
    apply(probe_module, :execute, [])
    {:noreply, state}
  end
end
