defmodule Parapet.Capabilities do
  @moduledoc """
  Registry for dynamic capabilities (e.g., UI mitigations) provided by activated adapters.
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{mitigation: %{}} end, name: __MODULE__)
  end

  def register_mitigation(_id, _name, _schema) do
    :ok
  end

  def capabilities(:mitigation) do
    []
  end
end
