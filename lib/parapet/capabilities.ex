defmodule Parapet.Capabilities do
  @moduledoc """
  Registry for dynamic capabilities provided by activated adapters.
  This module serves as the Phase 7 named recovery contract.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
  use GenServer

  @valid_capabilities [
    :retry_async_item,
    :requeue_dead_letter,
    :request_manual_provider_check,
    :revert_feature_flag,
    :disable_metric_label
  ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def checkout do
    GenServer.call(__MODULE__, {:checkout, self()})
  end

  def init(:ok) do
    :ets.new(__MODULE__, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{}}
  end

  def handle_call({:checkout, pid}, _from, state) do
    :ets.insert(__MODULE__, {{:checkout, pid}, true})
    Process.monitor(pid)
    {:reply, :ok, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    :ets.match_delete(__MODULE__, {{:test, pid, :_}, :_})
    :ets.delete(__MODULE__, {:checkout, pid})
    {:noreply, state}
  end

  defp find_checkout_pid do
    pids = [self() | Process.get(:"$callers", [])]
    Enum.find(pids, fn pid ->
      case :ets.lookup(__MODULE__, {:checkout, pid}) do
        [{_, true}] -> true
        _ -> false
      end
    end)
  end

  @doc """
  Registers a named recovery capability.
  """
  def register_recovery(id, attrs) when id in @valid_capabilities do
    capability = %{
      id: id,
      name: Keyword.fetch!(attrs, :name),
      module: Keyword.get(attrs, :module),
      target_kind: Keyword.get(attrs, :target_kind),
      preview: Keyword.get(attrs, :preview),
      execute: Keyword.get(attrs, :execute),
      preview_only: Keyword.get(attrs, :preview_only, false)
    }

    pid = find_checkout_pid()
    key = if pid, do: {:test, pid, :recovery, id}, else: {:global, :recovery, id}
    :ets.insert(__MODULE__, {key, capability})
    :ok
  end

  def register_recovery(id, _attrs) do
    raise ArgumentError,
          "Invalid recovery capability id: #{inspect(id)}. Valid ids are: #{inspect(@valid_capabilities)}"
  end

  @doc """
  Returns all registered recovery capabilities.
  """
  def capabilities(:recovery) do
    case :ets.info(__MODULE__) do
      :undefined -> []
      _ ->
        pid = find_checkout_pid()
        pattern = if pid, do: {{:test, pid, :recovery, :_}, :"$1"}, else: {{:global, :recovery, :_}, :"$1"}
        :ets.match(__MODULE__, pattern) |> Enum.map(fn [cap] -> cap end)
    end
  end

  @doc """
  Gets a specific recovery capability by id.
  Returns nil if unwired.
  """
  def get_recovery(id) do
    case :ets.info(__MODULE__) do
      :undefined -> nil
      _ ->
        pid = find_checkout_pid()
        key = if pid, do: {:test, pid, :recovery, id}, else: {:global, :recovery, id}
        case :ets.lookup(__MODULE__, key) do
          [{^key, capability}] -> capability
          _ -> nil
        end
    end
  end
end
