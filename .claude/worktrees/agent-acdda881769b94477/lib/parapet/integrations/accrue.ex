defmodule Parapet.Integrations.Accrue do
  @moduledoc """
  Parapet integration for the Accrue billing library.
  Listens to Accrue telemetry events and translates them into standard Parapet billing journey metrics.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @behaviour Parapet.Integration

  require Logger

  @doc """
  Attaches telemetry handlers for Accrue billing events.
  """
  @impl true
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

    :telemetry.attach_many(
      "parapet-accrue-billing-checkout-webhook",
      [
        [:accrue, :billing, :checkout, :stop],
        [:accrue, :billing, :checkout, :exception],
        [:accrue, :billing, :webhook, :stop],
        [:accrue, :billing, :webhook, :exception]
      ],
      &__MODULE__.handle_event/4,
      nil
    )

    Parapet.Metrics.Accrue.setup()
  end

  @doc """
  Handles Accrue telemetry events safely and emits Parapet billing journey events.
  """
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
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

  defp process_event([:accrue, :billing, :checkout, state], measurements, metadata)
       when state in [:stop, :exception] do
    outcome = if state == :stop, do: :success, else: :failure
    plan = Map.get(metadata, :plan, "unknown")

    parapet_metadata = %{outcome: outcome, plan: plan}

    :telemetry.execute(
      [:parapet, :journey, :billing, :checkout],
      measurements,
      parapet_metadata
    )
  end

  defp process_event([:accrue, :billing, :webhook, state], measurements, metadata)
       when state in [:stop, :exception] do
    outcome = if state == :stop, do: :success, else: :failure
    event_type = Map.get(metadata, :event_type, "unknown")

    parapet_metadata = %{outcome: outcome, event_type: event_type}

    :telemetry.execute(
      [:parapet, :journey, :billing, :webhook],
      %{duration: Map.get(measurements, :duration, 0)},
      parapet_metadata
    )
  end

  # Catch-all
  defp process_event(_event, _measurements, _metadata), do: :ok
end
