defmodule Parapet.CapabilitiesTest do
  use ExUnit.Case, async: false

  alias Parapet.Capabilities

  setup do
    case start_supervised(Capabilities) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        Agent.update(Capabilities, fn _ -> %{recovery: %{}} end)
        :ok
    end

    :ok
  end

  describe "register_recovery/2" do
    test "adds capability to list without duplicates" do
      attrs = [name: "Retry Async", target_kind: :async_item, preview: &(&1), execute: &(&1)]

      assert :ok = Capabilities.register_recovery(:retry_async_item, attrs)
      assert :ok = Capabilities.register_recovery(:retry_async_item, attrs)

      capabilities = Capabilities.capabilities(:recovery)
      assert length(capabilities) == 1
      assert hd(capabilities).id == :retry_async_item
      assert hd(capabilities).name == "Retry Async"
    end

    test "raises on invalid capability id" do
      assert_raise ArgumentError, ~r/Invalid recovery capability id/, fn ->
        Capabilities.register_recovery(:invalid_capability, name: "Invalid")
      end
    end
  end

  describe "get_recovery/1" do
    test "returns nil for unwired capability" do
      assert Capabilities.get_recovery(:retry_async_item) == nil
    end

    test "supports preview-only capability" do
      attrs = [name: "Check Provider", preview_only: true, preview: &(&1)]
      assert :ok = Capabilities.register_recovery(:request_manual_provider_check, attrs)

      cap = Capabilities.get_recovery(:request_manual_provider_check)
      assert cap.preview_only == true
      assert cap.execute == nil
    end
  end
end
