defmodule Parapet.Integrations.Rindle do
  @moduledoc """
  Parapet integration for the Rindle media processing library.
  Listens to Rindle telemetry events and translates them into the Phase 4
  Parapet async telemetry contract.
  """

  @behaviour Parapet.Integration

  alias Parapet.Telemetry.AsyncDelivery

  require Logger

  @handler_id "parapet-rindle-async"
  @events [
    [:rindle, :media, :started],
    [:rindle, :media, :processed],
    [:rindle, :media, :failed],
    [:rindle, :media, :discarded],
    [:rindle, :media, :backlog],
    [:rindle, :media, :callback_delayed],
    [:rindle, :media, :reconciliation_delayed]
  ]

  @doc """
  Attaches telemetry handlers for Rindle async lifecycle events.
  """
  @impl true
  def setup do
    :telemetry.detach(@handler_id)

    :telemetry.attach_many(
      @handler_id,
      @events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Handles Rindle telemetry events safely and emits Parapet async telemetry.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
      )

      :ok
  end

  defp process_event([:rindle, :media, :started], measurements, metadata) do
    emit_async(:stage, measurements, metadata, %{
      pipeline_stage: stage_from(metadata),
      outcome: :started,
      retry_state: retry_state_from(metadata),
      fault_plane: :worker
    })
  end

  defp process_event([:rindle, :media, :processed], measurements, metadata) do
    emit_async(:stage, measurements, metadata, %{
      pipeline_stage: stage_from(metadata),
      outcome: :succeeded,
      retry_state: retry_state_from(metadata),
      fault_plane: :worker
    })
  end

  defp process_event([:rindle, :media, :failed], measurements, metadata) do
    emit_async(:stage, measurements, metadata, %{
      pipeline_stage: stage_from(metadata),
      outcome: :retryable_failed,
      retry_state: :retrying,
      fault_plane: :worker
    })
  end

  defp process_event([:rindle, :media, :discarded], measurements, metadata) do
    emit_async(:stage, measurements, metadata, %{
      pipeline_stage: stage_from(metadata),
      outcome: :discarded,
      retry_state: :exhausted,
      fault_plane: :worker
    })
  end

  defp process_event([:rindle, :media, :backlog], measurements, metadata) do
    emit_async(:backlog, measurements, metadata, %{
      outcome: :delayed,
      delay_bucket: delay_bucket_from(measurements, metadata),
      fault_plane: :backlog
    })
  end

  defp process_event([:rindle, :media, :callback_delayed], measurements, metadata) do
    emit_async(:callback, measurements, metadata, %{
      pipeline_stage: stage_from(metadata),
      outcome: :delayed,
      delay_bucket: delay_bucket_from(measurements, metadata),
      fault_plane: :webhook
    })
  end

  defp process_event([:rindle, :media, :reconciliation_delayed], measurements, metadata) do
    emit_async(:callback, measurements, metadata, %{
      pipeline_stage: stage_from(metadata),
      outcome: :delayed,
      delay_bucket: delay_bucket_from(measurements, metadata),
      fault_plane: :webhook
    })
  end

  defp process_event(_event, _measurements, _metadata), do: :ok

  defp emit_async(family, measurements, metadata, normalized_fields) do
    telemetry_metadata =
      metadata
      |> Map.take([:job_id, :webhook_id])
      |> Map.merge(base_metadata(metadata))
      |> Map.merge(normalized_fields)

    telemetry_metadata = AsyncDelivery.shape_metadata(family, telemetry_metadata)

    :telemetry.execute(
      AsyncDelivery.event_name(family),
      normalize_measurements(family, measurements, metadata),
      telemetry_metadata
    )
  end

  defp base_metadata(metadata) do
    metadata
    |> Map.take([:provider, :queue])
    |> Map.put(:integration, :rindle)
  end

  defp normalize_measurements(family, measurements, metadata) do
    base = %{count: Map.get(measurements, :count, 1)}

    base
    |> maybe_put_duration(measurements)
    |> maybe_put_delay(family, measurements, metadata)
  end

  defp maybe_put_duration(measurements, source) do
    case Map.get(source, :duration_ms) || Map.get(source, :duration) do
      value when is_integer(value) and value >= 0 ->
        Map.put(measurements, :duration_ms, value)

      value when is_float(value) and value >= 0 ->
        Map.put(measurements, :duration_ms, round(value))

      _ ->
        measurements
    end
  end

  defp maybe_put_delay(measurements, family, source, fallback)
       when family in [:backlog, :callback] do
    case delay_value(source, fallback) do
      value when is_integer(value) and value >= 0 -> Map.put(measurements, :delay_ms, value)
      value when is_float(value) and value >= 0 -> Map.put(measurements, :delay_ms, round(value))
      _ -> measurements
    end
  end

  defp maybe_put_delay(measurements, _family, _source, _fallback), do: measurements

  defp delay_bucket_from(measurements, metadata) do
    measurements
    |> delay_value(metadata)
    |> AsyncDelivery.delay_bucket()
  end

  defp delay_value(primary, fallback) do
    Map.get(primary, :delay_ms) ||
      Map.get(primary, :delay) ||
      Map.get(fallback, :delay_ms) ||
      Map.get(fallback, :delay)
  end

  defp stage_from(metadata) do
    metadata
    |> Map.get(:pipeline_stage, :media_processing)
    |> normalize_stage()
  end

  defp retry_state_from(metadata) do
    cond do
      Map.has_key?(metadata, :retry_state) -> metadata.retry_state
      integer_attempt?(metadata[:attempt]) and metadata[:attempt] > 1 -> :retrying
      integer_attempt?(metadata[:attempt_number]) and metadata[:attempt_number] > 1 -> :retrying
      true -> :first_attempt
    end
  end

  defp normalize_stage(stage) when is_atom(stage), do: stage

  defp normalize_stage(stage) when is_binary(stage) do
    stage
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "_")
    |> String.trim("_")
    |> String.to_atom()
  end

  defp integer_attempt?(value), do: is_integer(value) and value >= 0
end
