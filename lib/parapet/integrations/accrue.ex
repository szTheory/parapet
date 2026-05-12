defmodule Parapet.Integrations.Accrue do
  @moduledoc """
  Parapet integration for the Accrue billing library.
  Listens to Accrue telemetry events and translates them into standard Parapet billing journey metrics.
  """

  require Logger

  @doc """
  Attaches telemetry handlers for Accrue billing events.
  """
  def setup do
    :telemetry.attach(
      "parapet-accrue-billing-processed",
      [:accrue, :billing, :processed],
      &__MODULE__.handle_event/4,
      nil
    )

    :telemetry.attach(
      "parapet-accrue-billing-failed",
      [:accrue, :billing, :failed],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Handles Accrue telemetry events safely and emits Parapet billing journey events.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}"
      )
  end

  defp process_event([:accrue, :billing, state], measurements, metadata)
       when state in [:processed, :failed] do
    outcome = if state == :processed, do: :success, else: :failure

    parapet_metadata = Map.put(metadata, :outcome, outcome)

    :telemetry.execute(
      [:parapet, :journey, :billing],
      measurements,
      parapet_metadata
    )
  end

  # Catch-all
  defp process_event(_event, _measurements, _metadata), do: :ok
end
