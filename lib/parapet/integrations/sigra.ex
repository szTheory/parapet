if Code.ensure_loaded?(Sigra) do
  defmodule Parapet.Integrations.Sigra do
    @moduledoc """
    Parapet integration for the Sigra authentication library.
    Listens to Sigra telemetry events and translates them into standard Parapet login journey metrics.
    """

    require Logger

    @doc """
    Attaches telemetry handlers for Sigra login events.
    """
    def setup do
      :telemetry.attach(
        "parapet-sigra-login-stop",
        [:sigra, :auth, :login, :stop],
        &__MODULE__.handle_event/4,
        nil
      )

      :telemetry.attach(
        "parapet-sigra-login-exception",
        [:sigra, :auth, :login, :exception],
        &__MODULE__.handle_event/4,
        nil
      )
    end

    @doc """
    Handles Sigra telemetry events safely and emits Parapet login journey events.
    """
    def handle_event(event, measurements, metadata, _config) do
      try do
        process_event(event, measurements, metadata)
      rescue
        e ->
          Logger.error(
            "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
          )
      end
    end

    defp process_event([:sigra, :auth, :login, state], measurements, _metadata) when state in [:stop, :exception] do
      outcome = if state == :stop, do: :success, else: :failure

      # Strip PII from metadata, but you can pass relevant non-PII if needed.
      # Right now we just send outcome.
      parapet_metadata = %{outcome: outcome}

      :telemetry.execute(
        [:parapet, :journey, :login],
        %{duration: measurements.duration},
        parapet_metadata
      )
    end
    
    # Catch-all for events we didn't explicitly expect but were routed here
    defp process_event(_event, _measurements, _metadata), do: :ok
  end
end
