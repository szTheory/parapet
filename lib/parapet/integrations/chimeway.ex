defmodule Parapet.Integrations.Chimeway do
  @moduledoc """
  Parapet integration for the Chimeway email library.
  Listens to Chimeway telemetry events and translates them into the Phase 4
  Parapet delivery telemetry contract.
  """

  @behaviour Parapet.Integration

  alias Parapet.Telemetry.AsyncDelivery

  require Logger

  @handler_id "parapet-chimeway-delivery-events"

  @doc """
  Attaches telemetry handlers for Chimeway events.
  """
  @impl true
  def setup do
    :telemetry.detach(@handler_id)

    :telemetry.attach(
      @handler_id,
      [:chimeway, :event, :failed],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Handles Chimeway telemetry events safely and emits Parapet delivery telemetry.
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

  defp process_event([:chimeway, :event, :failed], measurements, metadata) do
    family = if callback_delay?(metadata), do: :webhook_ingest, else: :provider_feedback

    emit_delivery(family, measurements, metadata, %{
      integration: :chimeway,
      provider: Map.get(metadata, :provider, :unknown),
      channel: :notification,
      outcome: :failed,
      failure_class: Map.get(metadata, :error, :failed),
      fault_plane: fault_plane_for(metadata),
      delay_bucket: delay_bucket_for(metadata)
    })
  end

  defp process_event(_event, _measurements, _metadata), do: :ok

  defp emit_delivery(family, measurements, metadata, public_metadata) do
    telemetry_metadata =
      metadata
      |> Map.take([:message_id])
      |> Map.merge(public_metadata)
      |> drop_nil_values()

    telemetry_metadata = AsyncDelivery.shape_metadata(family, telemetry_metadata)

    :telemetry.execute(
      AsyncDelivery.event_name(family),
      %{count: Map.get(measurements, :count, 1), duration_ms: native_duration_ms(measurements)},
      telemetry_metadata
    )
  end

  defp native_duration_ms(measurements) do
    measurements
    |> Map.get(:duration, 0)
    |> System.convert_time_unit(:native, :millisecond)
  end

  defp callback_delay?(metadata) do
    Map.get(metadata, :error) in [:callback_timeout, "callback_timeout"] and
      is_integer(Map.get(metadata, :delay_ms))
  end

  defp fault_plane_for(metadata) do
    if callback_delay?(metadata), do: :webhook, else: :provider
  end

  defp delay_bucket_for(metadata) do
    case Map.get(metadata, :delay_ms) do
      value when is_integer(value) and value >= 0 -> AsyncDelivery.delay_bucket(value)
      _ -> nil
    end
  end

  defp drop_nil_values(map) do
    Enum.reduce(map, %{}, fn
      {_key, nil}, acc -> acc
      {key, value}, acc -> Map.put(acc, key, value)
    end)
  end
end
