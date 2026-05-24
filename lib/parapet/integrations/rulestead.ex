defmodule Parapet.Integrations.Rulestead do
  @moduledoc """
  Telemetry adapter for buffering Rulestead flag changes natively inside Parapet's spine.
  """

  @behaviour Parapet.Integration

  require Logger
  alias Parapet.Spine.SystemEvent

  @doc """
  Activates the Rulestead integration via `Parapet.attach/1`.

  Delegates to `attach/0`, which attaches the telemetry handler for Rulestead flag mutations.
  """
  @impl true
  def setup, do: attach()

  @doc """
  Attaches telemetry handlers to buffer Rulestead flag mutations.
  """
  def attach do
    :telemetry.attach(
      "parapet-rulestead-telemetry",
      [:rulestead, :admin, :ruleset, :published],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc false
  def handle_event(_event, _measurements, metadata, _config) do
    if is_map(metadata) do
      repo = Application.get_env(:parapet, :repo)

      if repo do
        changeset =
          SystemEvent.changeset(%SystemEvent{}, %{
            type: "rulestead_flag_change",
            payload: stringify_keys(metadata)
          })

        case repo.insert(changeset) do
          {:ok, _} ->
            safe_metadata =
              metadata
              |> Map.put(:ruleset, metadata[:ruleset_id])
              |> Map.delete(:ruleset_id)

            :telemetry.execute([:parapet, :rulestead, :flag_change], %{}, safe_metadata)
            :ok

          {:error, error} ->
            Logger.warning(
              "[Parapet.Integrations.Rulestead] Failed to insert SystemEvent: #{inspect(error)}"
            )

            :ok
        end
      else
        :ok
      end
    else
      :ok
    end
  rescue
    e ->
      Logger.error(
        "[Parapet.Integrations.Rulestead] Error in telemetry handler: #{Exception.message(e)}"
      )

      :ok
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
