defmodule Parapet.Metrics.ExemplarTelemetry do
  @moduledoc """
  Attaches to Telemetry events to capture trace_ids and store them as exemplars.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  alias Parapet.Metrics.ExemplarStore

  def attach do
    events = [
      [:parapet, :http, :request],
      [:parapet, :oban, :job]
    ]

    :telemetry.attach_many(
      "parapet-exemplar-telemetry",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event([:parapet, :http, :request], _measurements, metadata, _config) do
    case Map.get(metadata, :trace_id) do
      nil -> :ok
      trace_id when is_binary(trace_id) ->
        tags = Map.take(metadata, [:route, :method, :status_class])
        ExemplarStore.record_trace("parapet_http_request_duration_ms", tags, trace_id)
    end
  end

  def handle_event([:parapet, :oban, :job], _measurements, metadata, _config) do
    case Map.get(metadata, :trace_id) do
      nil -> :ok
      trace_id when is_binary(trace_id) ->
        tags = Map.take(metadata, [:worker, :queue, :state])
        ExemplarStore.record_trace("parapet_oban_job_duration_ms", tags, trace_id)
    end
  end
end
