if Code.ensure_loaded?(Rindle) do
  defmodule Parapet.Integrations.Rindle do
    @moduledoc """
    Parapet integration for the Rindle media processing library.
    Listens to Rindle telemetry events and translates them into standard Parapet media journey metrics.
    """

    require Logger

    @doc """
    Attaches telemetry handlers for Rindle media events.
    """
    def setup do
      :telemetry.attach(
        "parapet-rindle-media-processed",
        [:rindle, :media, :processed],
        &__MODULE__.handle_event/4,
        nil
      )

      :telemetry.attach(
        "parapet-rindle-media-failed",
        [:rindle, :media, :failed],
        &__MODULE__.handle_event/4,
        nil
      )
    end

    @doc """
    Handles Rindle telemetry events safely and emits Parapet media journey events.
    """
    def handle_event(event, measurements, metadata, _config) do
      process_event(event, measurements, metadata)
    rescue
      e ->
        Logger.error(
          "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}"
        )
    end

    defp process_event([:rindle, :media, state], measurements, metadata)
         when state in [:processed, :failed] do
      outcome = if state == :processed, do: :success, else: :failure

      parapet_metadata = Map.put(metadata, :outcome, outcome)

      :telemetry.execute(
        [:parapet, :journey, :media],
        measurements,
        parapet_metadata
      )
    end

    # Catch-all
    defp process_event(_event, _measurements, _metadata), do: :ok
  end
end
