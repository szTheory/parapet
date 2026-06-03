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
  use Agent

  @valid_capabilities [
    :retry_async_item,
    :requeue_dead_letter,
    :request_manual_provider_check
  ]

  def start_link(_opts) do
    Agent.start_link(fn -> %{recovery: %{}} end, name: __MODULE__)
  end

  @doc """
  Registers a named recovery capability.
  """
  def register_recovery(id, attrs) when id in @valid_capabilities do
    Agent.update(__MODULE__, fn state ->
      capability = %{
        id: id,
        name: Keyword.fetch!(attrs, :name),
        target_kind: Keyword.get(attrs, :target_kind),
        preview: Keyword.get(attrs, :preview),
        execute: Keyword.get(attrs, :execute),
        preview_only: Keyword.get(attrs, :preview_only, false)
      }

      put_in(state, [:recovery, id], capability)
    end)
  end

  def register_recovery(id, _attrs) do
    raise ArgumentError,
          "Invalid recovery capability id: #{inspect(id)}. Valid ids are: #{inspect(@valid_capabilities)}"
  end

  @doc """
  Returns all registered recovery capabilities.
  """
  def capabilities(:recovery) do
    Agent.get(__MODULE__, fn state ->
      state.recovery |> Map.values()
    end)
  end

  @doc """
  Gets a specific recovery capability by id.
  Returns nil if unwired.
  """
  def get_recovery(id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state.recovery, id)
    end)
  end
end
