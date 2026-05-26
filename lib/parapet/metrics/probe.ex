defmodule Parapet.Metrics.Probe do
  use Parapet.Metrics.Validator

  @moduledoc """
  Defines Prometheus distributions and counters for synthetic probes.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  require Logger

  alias Parapet.Internal.LabelPolicy

  @doc """
  Sets up the Probe metrics by attaching telemetry handlers.
  """
  def setup do
    Parapet.attach(%{
      handler_id: "parapet-probe-run-stop",
      event_name: [:parapet, :probe, :run, :stop],
      handler_module: __MODULE__,
      function_name: :handle_event
    })

    Parapet.attach(%{
      handler_id: "parapet-probe-run-exception",
      event_name: [:parapet, :probe, :run, :exception],
      handler_module: __MODULE__,
      function_name: :handle_event
    })
  end

  @doc """
  Defines the metrics for the telemetry events.
  """
  def metrics do
    import Telemetry.Metrics

    LabelPolicy.assert_safe!([:probe, :status])

    [
      counter("parapet.probe.run.total",
        event_name: [:parapet, :probe, :run],
        tags: [:probe, :status],
        description: "Total number of probe executions"
      ),
      distribution("parapet.probe.run.duration.ms",
        event_name: [:parapet, :probe, :run],
        measurement: :duration_ms,
        tags: [:probe, :status],
        description: "Distribution of probe execution times",
        reporter_options: [
          buckets: [10, 50, 100, 250, 500, 1000, 2000, 5000]
        ]
      )
    ]
  end

  @doc false
  def handle_event(_event, measurements, metadata, _config) do
    duration = Map.get(measurements, :duration)

    duration_ms =
      if duration, do: System.convert_time_unit(duration, :native, :millisecond), else: 0

    probe = to_string(Map.get(metadata, :probe, "unknown"))
    status = to_string(Map.get(metadata, :status, "unknown"))

    :telemetry.execute(
      [:parapet, :probe, :run],
      %{duration_ms: duration_ms},
      %{probe: probe, status: status}
    )
  end
end
