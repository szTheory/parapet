defmodule Parapet.SLO.Registry do
  @moduledoc false
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def checkout do
    GenServer.call(__MODULE__, {:checkout, self()})
  end

  def store(slo) do
    pid = find_checkout_pid()
    key = if pid, do: {:test, pid, :slo, slo.name}, else: {:global, :slo, slo.name}
    :ets.insert(__MODULE__, {key, slo})
    :ok
  end

  def all do
    case :ets.info(__MODULE__) do
      :undefined -> []
      _ ->
        pid = find_checkout_pid()
        pattern = if pid, do: {{:test, pid, :slo, :_}, :"$1"}, else: {{:global, :slo, :_}, :"$1"}
        :ets.match(__MODULE__, pattern) |> Enum.map(fn [slo] -> slo end)
    end
  end

  def clear do
    pid = find_checkout_pid()
    pattern = if pid, do: {{:test, pid, :slo, :_}, :_}, else: {{:global, :slo, :_}, :_}
    :ets.match_delete(__MODULE__, pattern)
  end

  def register_providers(providers) do
    pid = find_checkout_pid()
    key = if pid, do: {:test, pid, :providers}, else: {:global, :providers}
    :ets.insert(__MODULE__, {key, providers})
    :ok
  end

  def providers do
    case :ets.info(__MODULE__) do
      :undefined -> Application.get_env(:parapet, :providers, [])
      _ ->
        pid = find_checkout_pid()
        key = if pid, do: {:test, pid, :providers}, else: {:global, :providers}
        case :ets.lookup(__MODULE__, key) do
          [{^key, providers}] -> providers
          _ -> Application.get_env(:parapet, :providers, [])
        end
    end
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
end
