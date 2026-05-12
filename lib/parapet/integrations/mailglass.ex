defmodule Parapet.Integrations.Mailglass do
  @moduledoc """
  Parapet integration for the Mailglass email library.
  Listens to Mailglass telemetry events and translates them into standard Parapet journey metrics.
  """

  require Logger

  @doc """
  Attaches telemetry handlers for Mailglass delivery events.
  """
  def setup do
    :telemetry.attach(
      "parapet-mailglass-delivery-failure",
      [:mailglass, :delivery, :failure],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Handles Mailglass telemetry events safely and emits Parapet mail delivery journey events.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
      )
  end

  defp process_event([:mailglass, :delivery, :failure], measurements, _metadata) do
    parapet_metadata = %{outcome: :failure}

    :telemetry.execute(
      [:parapet, :journey, :mail_delivery],
      %{duration: measurements.duration},
      parapet_metadata
    )
  end

  # Catch-all for events we didn't explicitly expect but were routed here
  defp process_event(_event, _measurements, _metadata), do: :ok
end
