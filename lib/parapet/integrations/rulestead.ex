defmodule Parapet.Integrations.Rulestead do
  @moduledoc """
  Parapet integration for the Rulestead feature flag library.
  Listens to Rulestead telemetry events and registers flag toggling capabilities.
  """

  require Logger

  @doc """
  Attaches telemetry handlers for Rulestead events and registers capabilities.
  """
  def setup do
    :telemetry.attach(
      "parapet-rulestead-flag",
      [:rulestead, :flag, :changed],
      &__MODULE__.handle_event/4,
      nil
    )

    Parapet.Capabilities.register_mitigation(
      :rulestead,
      "toggle_flag",
      %{name: "Toggle Feature Flag", schema: [flag_name: :string, state: :boolean]}
    )
  end

  @doc """
  Handles Rulestead telemetry events safely and emits Parapet telemetry.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
      )
  end

  defp process_event([:rulestead, :flag, :changed], measurements, metadata) do
    # Extract safe fields only (strip PII)
    parapet_metadata = %{
      flag_name: Map.get(metadata, :flag_name),
      state: Map.get(metadata, :state)
    }

    :telemetry.execute(
      [:parapet, :mitigation, :rulestead, :flag, :changed],
      measurements,
      parapet_metadata
    )
  end

  # Catch-all for events we didn't explicitly expect but were routed here
  defp process_event(_event, _measurements, _metadata), do: :ok
end
