defmodule Parapet.Integrations.ChimewayTest do
  use ExUnit.Case, async: false

  setup do
    test_pid = self()
    handler_id = "test-parapet-journey-mail_delivery-chimeway"

    :telemetry.attach(
      handler_id,
      [:parapet, :journey, :mail_delivery],
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
    test "translates chimeway failed event to parapet failure event safely" do
      # Ensure the handler is attached
      Parapet.Integrations.Chimeway.setup()

      # Simulate a Chimeway event failed event
      :telemetry.execute(
        [:chimeway, :event, :failed],
        %{duration: 300_000_000},
        %{email: "test2@example.com", error: "rejected"}
      )

      assert_receive {:telemetry_event, [:parapet, :journey, :mail_delivery], measurements, metadata}

      assert measurements.duration == 300_000_000
      assert metadata.outcome == :failure
      refute Map.has_key?(metadata, :email)
    end
  end
end
