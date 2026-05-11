defmodule Parapet.CapabilitiesTest do
  use ExUnit.Case, async: false

  alias Parapet.Capabilities

  setup do
    # Ensure it's started fresh or cleaned up? We will just start it if not started
    # In actual usage it will be started by application tree.
    case start_supervised(Capabilities) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        Agent.update(Capabilities, fn _ -> %{mitigation: %{}} end)
        :ok
    end

    :ok
  end

  describe "register_mitigation/3" do
    test "adds capability to list without duplicates" do
      schema = [flag_name: :string, state: :boolean]

      assert :ok = Capabilities.register_mitigation(:toggle_flag, "Toggle Feature Flag", schema)
      assert :ok = Capabilities.register_mitigation(:toggle_flag, "Toggle Feature Flag", schema)

      capabilities = Capabilities.capabilities(:mitigation)
      assert length(capabilities) == 1
      assert hd(capabilities).id == :toggle_flag
      assert hd(capabilities).name == "Toggle Feature Flag"
      assert hd(capabilities).schema == schema
    end
  end

  describe "capabilities/1" do
    test "returns list of registered capabilities" do
      assert Capabilities.capabilities(:mitigation) == []

      Capabilities.register_mitigation(:c1, "Cap 1", [])
      Capabilities.register_mitigation(:c2, "Cap 2", [])

      caps = Capabilities.capabilities(:mitigation)
      assert length(caps) == 2
      assert Enum.any?(caps, &(&1.id == :c1))
      assert Enum.any?(caps, &(&1.id == :c2))
    end
  end
end
