defmodule Parapet.Metrics.ExemplarStore do
  @moduledoc """
  An ETS-backed store for holding the latest trace ID associated with a metric and its tags.
  This allows Prometheus formatters to quickly fetch the recent trace exemplar.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  use GenServer

  @table_name :parapet_exemplar_store

  # --- API ---

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_trace(metric_name, tags, trace_id) when is_binary(metric_name) and is_map(tags) and is_binary(trace_id) do
    if :ets.info(@table_name) != :undefined do
      :ets.insert(@table_name, {{metric_name, tags}, trace_id})
    end
    :ok
  end

  def get_trace(metric_name, tags) when is_binary(metric_name) and is_map(tags) do
    if :ets.info(@table_name) != :undefined do
      case :ets.lookup(@table_name, {metric_name, tags}) do
        [{_, trace_id}] -> trace_id
        [] -> nil
      end
    else
      nil
    end
  end

  # --- Callbacks ---

  @impl true
  def init(_opts) do
    :ets.new(@table_name, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    {:ok, %{}}
  end
end
