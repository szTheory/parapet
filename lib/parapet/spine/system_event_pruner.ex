defmodule Parapet.Spine.SystemEventPruner do
  @moduledoc """
  A built-in GC pruner to prevent `Parapet.Spine.SystemEvent` storage bloat.
  Periodically deletes events older than a specified threshold.
  """
  use GenServer
  require Logger

  alias Parapet.Spine.SystemEvent
  import Ecto.Query, only: [from: 2]

  @prune_interval :timer.hours(6)
  @retention_days 7

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_prune()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:prune, state) do
    prune_old_events()
    schedule_prune()
    {:noreply, state}
  end

  defp schedule_prune do
    Process.send_after(self(), :prune, @prune_interval)
  end

  defp prune_old_events do
    repo = Application.get_env(:parapet, :repo)

    if repo do
      threshold =
        DateTime.utc_now()
        |> DateTime.add(-@retention_days, :day)

      query = from(e in SystemEvent, where: e.inserted_at < ^threshold)

      case repo.delete_all(query) do
        {count, _} ->
          Logger.info("[Parapet.Spine.SystemEventPruner] Pruned #{count} system events older than #{@retention_days} days.")

        error ->
          Logger.error("[Parapet.Spine.SystemEventPruner] Failed to prune system events: #{inspect(error)}")
      end
    else
      Logger.debug("[Parapet.Spine.SystemEventPruner] Parapet.Evidence.repo() not configured, skipping pruning.")
    end
  rescue
    e ->
      Logger.error("[Parapet.Spine.SystemEventPruner] Error during prune: #{Exception.message(e)}")
  end
end
