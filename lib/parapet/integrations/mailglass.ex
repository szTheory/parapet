defmodule Parapet.Integrations.Mailglass do
  @moduledoc """
  Parapet integration for the Mailglass email library.
  Listens to Mailglass telemetry events and translates them into the Phase 4
  Parapet delivery telemetry contract.
  """

  alias Parapet.Telemetry.AsyncDelivery

  require Logger

  @handler_id "parapet-mailglass-delivery"
  @events [
    [:mailglass, :outbound, :send, :stop],
    [:mailglass, :reconcile, :stop],
    [:mailglass, :webhook, :ingest, :exception]
  ]

  @doc """
  Attaches telemetry handlers for Mailglass delivery events.
  """
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
  Handles Mailglass telemetry events safely and emits Parapet delivery telemetry.
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

  defp process_event([:mailglass, :outbound, :send, :stop], measurements, metadata) do
    emit_delivery(:outbound, measurements, metadata, %{
      integration: :mailglass,
      provider: Map.get(metadata, :provider, :unknown),
      channel: :email,
      outcome: :attempted,
      fault_plane: :provider
    })
  end

  defp process_event([:mailglass, :reconcile, :stop], measurements, metadata) do
    emit_delivery(:provider_feedback, measurements, metadata, %{
      integration: :mailglass,
      provider: Map.get(metadata, :provider, :unknown),
      channel: :email,
      outcome: Map.get(metadata, :status, :failed),
      fault_plane: :provider
    })
  end

  defp process_event([:mailglass, :webhook, :ingest, :exception], measurements, metadata) do
    emit_delivery(:webhook_ingest, measurements, metadata, %{
      integration: :mailglass,
      provider: Map.get(metadata, :provider, :unknown),
      channel: :email,
      outcome: :failed,
      failure_class: Map.get(metadata, :error, :webhook_error),
      delay_bucket: AsyncDelivery.delay_bucket(Map.get(metadata, :latency_ms, 0)),
      fault_plane: :webhook
    })
  end

  defp process_event(_event, _measurements, _metadata), do: :ok

  defp emit_delivery(family, measurements, metadata, public_metadata) do
    telemetry_metadata =
      metadata
      |> Map.take([:message_id, :delivery_id, :provider_message_id])
      |> Map.merge(public_metadata)

    telemetry_metadata = AsyncDelivery.shape_metadata(family, telemetry_metadata)

    :telemetry.execute(
      AsyncDelivery.event_name(family),
      normalize_measurements(measurements, metadata),
      telemetry_metadata
    )
  end

  defp normalize_measurements(measurements, metadata) do
    duration_ms =
      measurements
      |> Map.get(:duration, 0)
      |> System.convert_time_unit(:native, :millisecond)

    base = %{count: Map.get(measurements, :count, 1), duration_ms: duration_ms}

    case Map.get(metadata, :latency_ms) do
      value when is_integer(value) and value >= 0 -> Map.put(base, :delay_ms, value)
      _ -> base
    end
  end
end
