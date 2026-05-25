defmodule Parapet.Integrations.Sigra do
  @moduledoc """
  Parapet integration for the Sigra authentication library.
  Listens to Sigra telemetry events and translates them into standard Parapet login and signup journey metrics.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @behaviour Parapet.Integration

  require Logger

  @doc """
  Attaches telemetry handlers for Sigra login and signup events.
  """
  @impl true
  def setup do
    :telemetry.attach_many(
      "parapet-sigra-auth",
      [
        [:sigra, :auth, :login, :stop],
        [:sigra, :auth, :login, :exception],
        [:sigra, :auth, :signup, :stop],
        [:sigra, :auth, :signup, :exception]
      ],
      &__MODULE__.handle_event/4,
      nil
    )

    Parapet.Metrics.Sigra.setup()
  end

  @doc """
  Handles Sigra telemetry events safely and emits Parapet journey events.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
      )
  end

  defp process_event([:sigra, :auth, :login, state], measurements, _metadata)
       when state in [:stop, :exception] do
    outcome = if state == :stop, do: :success, else: :failure

    parapet_metadata = %{outcome: outcome}

    :telemetry.execute(
      [:parapet, :journey, :login],
      %{duration: measurements.duration},
      parapet_metadata
    )
  end

  defp process_event([:sigra, :auth, :signup, state], measurements, metadata)
       when state in [:stop, :exception] do
    outcome = if state == :stop, do: :success, else: :failure
    provider = Map.get(metadata, :provider, "unknown")

    # Strip PII from metadata, only tracking outcome and provider
    parapet_metadata = %{outcome: outcome, provider: provider}

    :telemetry.execute(
      [:parapet, :journey, :signup],
      %{duration: measurements.duration},
      parapet_metadata
    )
  end

  # Catch-all for events we didn't explicitly expect but were routed here
  defp process_event(_event, _measurements, _metadata), do: :ok
end
