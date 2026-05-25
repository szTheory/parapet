if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Metrics.Oban do
    use Parapet.Metrics.Validator
    @moduledoc """
    Defines Prometheus distributions and counters for Oban jobs conditionally.

    > #### Experimental {: .warning}
    >
    > This module is **experimental** in v1.x. Its API may change in a minor release with a
    > single-version notice in CHANGELOG.md. See
    > [Stability & Deprecation Policy](stability.html) for details.
    """
    require Logger

    alias Parapet.Internal.LabelPolicy

    @doc """
    Sets up the Oban metrics by attaching telemetry handlers.
    """
    def setup do
      Parapet.attach(%{
        handler_id: "parapet-oban-job-stop",
        event_name: [:oban, :job, :stop],
        handler_module: __MODULE__,
        function_name: :handle_event
      })

      Parapet.attach(%{
        handler_id: "parapet-oban-job-exception",
        event_name: [:oban, :job, :exception],
        handler_module: __MODULE__,
        function_name: :handle_event
      })

      :ok
    rescue
      e in [ArgumentError] ->
        Logger.error("Failed to register Oban metrics: #{Exception.message(e)}")
        {:error, e}
    end

    @doc """
    Returns a list of Telemetry.Metrics definitions for Oban events.
    """
    def metrics do
      import Telemetry.Metrics

      LabelPolicy.assert_safe!([:worker, :queue, :state])

      [
        counter("parapet.oban.jobs.total",
          event_name: [:parapet, :oban, :job],
          tags: [:worker, :queue, :state],
          description: "Total number of Oban jobs processed"
        ),
        distribution("parapet.oban.job.duration_ms",
          event_name: [:parapet, :oban, :job],
          measurement: :duration_ms,
          tags: [:worker, :queue, :state],
          description: "Duration of Oban jobs in milliseconds",
          reporter_options: [
            buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000, 10_000]
          ]
        )
      ]
    end

    @doc false
    def handle_event(_event, measurements, metadata, _config) do
      duration = Map.get(measurements, :duration)

      duration_ms =
        if duration, do: System.convert_time_unit(duration, :native, :millisecond), else: 0

      worker = to_string(Map.get(metadata, :worker, "unknown"))
      queue = to_string(Map.get(metadata, :queue, "unknown"))
      state = to_string(Map.get(metadata, :state, "unknown"))

      out_metadata = %{worker: worker, queue: queue, state: state}

      out_metadata =
        if trace_id = get_trace_id() do
          Map.put(out_metadata, :trace_id, to_string(trace_id))
        else
          out_metadata
        end

      :telemetry.execute(
        [:parapet, :oban, :job],
        %{duration_ms: duration_ms},
        out_metadata
      )
    end

    defp get_trace_id do
      if Code.ensure_loaded?(:opentelemetry) and function_exported?(OpenTelemetry.Tracer, :current_span_ctx, 0) do
        span_ctx = OpenTelemetry.Tracer.current_span_ctx()

        if span_ctx != :undefined do
          OpenTelemetry.Span.hex_trace_id(span_ctx)
        end
      end
    rescue
      _ -> nil
    end
  end
end
