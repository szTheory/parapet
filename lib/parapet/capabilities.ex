defmodule Parapet.Capabilities do
  @moduledoc """
  Registry for dynamic capabilities (e.g., UI mitigations) provided by activated adapters.
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{mitigation: %{}} end, name: __MODULE__)
  end

  def register_mitigation(id, name, schema) do
    Agent.update(__MODULE__, fn state ->
      capability = %{id: id, name: name, schema: schema}
      put_in(state, [:mitigation, id], capability)
    end)
  end

  def capabilities(:mitigation) do
    Agent.get(__MODULE__, fn state ->
      state.mitigation |> Map.values()
    end)
  end
end
