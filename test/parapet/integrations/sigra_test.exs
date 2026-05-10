defmodule Parapet.Integrations.SigraTest do
  use ExUnit.Case, async: false

  setup do
    # Attach a test handler to the Parapet journey event to verify it's emitted
    test_pid = self()

    handler_id = "test-parapet-journey-login"

    :telemetry.attach(
      handler_id,
      [:parapet, :journey, :login],
      fn name, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, name, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)
    end)

    :ok
  end

  describe "setup/0 and handle_event/4" do
    test "translates sigra stop event to parapet success event without PII" do
      # Ensure the handler is attached
      Parapet.Integrations.Sigra.setup()

      # Simulate a Sigra login stop event
      :telemetry.execute(
        [:sigra, :auth, :login, :stop],
        %{duration: 150_000_000}, # 150ms in native time
        %{user_id: 123, email: "test@example.com"} # PII should be stripped
      )

      assert_receive {:telemetry_event, [:parapet, :journey, :login], measurements, metadata}

      assert measurements.duration == 150_000_000
      assert metadata.outcome == :success
      
      # Threat Model T-03-02: Verify PII is NOT in metadata
      refute Map.has_key?(metadata, :user_id)
      refute Map.has_key?(metadata, :email)
    end

    test "translates sigra exception event to parapet failure event without PII" do
      Parapet.Integrations.Sigra.setup()

      # Simulate a Sigra login exception event
      :telemetry.execute(
        [:sigra, :auth, :login, :exception],
        %{duration: 50_000_000},
        %{user_id: 456, kind: :error, reason: "timeout"}
      )

      assert_receive {:telemetry_event, [:parapet, :journey, :login], measurements, metadata}

      assert measurements.duration == 50_000_000
      assert metadata.outcome == :failure
      refute Map.has_key?(metadata, :user_id)
    end
  end
end
