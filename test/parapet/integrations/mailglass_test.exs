defmodule Parapet.Integrations.MailglassTest do
  use ExUnit.Case, async: false

  setup do
    test_pid = self()
    handler_id = "test-parapet-journey-mail_delivery-mailglass"

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
    test "translates mailglass delivery failure event to parapet failure event safely" do
      # Ensure the handler is attached
      Parapet.Integrations.Mailglass.setup()

      # Simulate a Mailglass delivery failure event
      :telemetry.execute(
        [:mailglass, :delivery, :failure],
        %{duration: 200_000_000},
        %{email: "test@example.com", reason: "bounce"}
      )

      assert_receive {:telemetry_event, [:parapet, :journey, :mail_delivery], measurements, metadata}

      assert measurements.duration == 200_000_000
      assert metadata.outcome == :failure

      # Threat Model T-3-03: PII should ideally not be in the metadata if we strip it,
      # but let's test what's required by the plan.
      refute Map.has_key?(metadata, :email)
    end
  end
end
