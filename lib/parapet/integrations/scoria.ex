defmodule Parapet.Integrations.Scoria do
  @moduledoc """
  Parapet integration for the Scoria AI library.
  Listens to Scoria telemetry events and translates them into Parapet metrics
  while stripping high-cardinality metadata and creating incidents for severe errors.
  """

  require Logger

  @safe_labels [:model, :provider, :tool_name]

  @doc """
  Attaches telemetry handlers for Scoria events.
  """
  def setup do
    :telemetry.attach(
      "parapet-scoria-telemetry",
      [:scoria, :sre, :telemetry],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Handles Scoria telemetry events, translates them to Parapet metrics,
  and logs incidents for AI tool failures.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}"
      )
      :ok
  end

  defp process_event([:scoria, :sre, :telemetry], measurements, metadata) do
    # Extract only low-cardinality labels
    safe_metadata = Map.take(metadata, @safe_labels)

    # Determine outcome based on :error presence
    has_error? = Map.has_key?(metadata, :error) and not is_nil(metadata.error)
    outcome = if has_error?, do: :failure, else: :success
    
    parapet_metadata = Map.put(safe_metadata, :outcome, outcome)

    # Emit translated event
    :telemetry.execute(
      [:parapet, :scoria, :metrics],
      measurements,
      parapet_metadata
    )

    # Route errors to Parapet.Evidence.create_incident/1
    if has_error? do
      Parapet.Evidence.create_incident(%{
        title: "Scoria AI Execution Failure: #{Map.get(metadata, :tool_name, "Unknown Tool")}",
        description: "An error occurred during AI execution:\n\n#{inspect(metadata.error)}",
        state: "open",
        severity: "high"
      })
    end

    :ok
  end

  # Catch-all
  defp process_event(_event, _measurements, _metadata), do: :ok
end
