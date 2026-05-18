defmodule Parapet.Integrations.ChimewayTest do
  use ExUnit.Case, async: false

  @integration_handler_id "parapet-chimeway-delivery-events"
  @parapet_events [
    [:parapet, :delivery, :outbound],
    [:parapet, :delivery, :provider_feedback],
    [:parapet, :delivery, :webhook_ingest]
  ]

  setup do
    test_pid = self()

    :telemetry.detach(@integration_handler_id)

    handler_ids =
      Enum.map(@parapet_events, fn event_name ->
        handler_id = "test-#{Enum.join(event_name, "-")}-chimeway"

        :telemetry.attach(
          handler_id,
          event_name,
          fn name, measurements, metadata, _config ->
            send(test_pid, {:telemetry_event, name, measurements, metadata})
          end,
          nil
        )

        handler_id
      end)

    on_exit(fn ->
      Enum.each(handler_ids, &:telemetry.detach/1)
      :telemetry.detach(@integration_handler_id)
    end)

    :ok
  end

  describe "characterized chimeway telemetry surface" do
    test "pins the currently proven upstream event name and bounded metadata keys" do
      proven_event = [:chimeway, :event, :failed]
      proven_metadata = %{provider: :smtp, error: :rejected, message_id: "msg-77", delay_ms: 500}

      assert proven_event == [:chimeway, :event, :failed]
      assert Map.keys(proven_metadata) |> Enum.sort() == [:delay_ms, :error, :message_id, :provider]
      refute match?([:chimeway, :event, :accepted], proven_event)
    end
  end

  describe "setup/0 and handle_event/4" do
    test "normalizes the proven failed event into provider feedback telemetry" do
      Parapet.Integrations.Chimeway.setup()

      :telemetry.execute(
        [:chimeway, :event, :failed],
        %{duration: 300_000_000},
        %{provider: :smtp, error: :rejected, message_id: "msg-77"}
      )

      assert_receive {:telemetry_event, [:parapet, :delivery, :provider_feedback], measurements,
                      metadata}

      assert measurements.duration_ms == 300
      assert metadata == %{
               integration: :chimeway,
               provider: :smtp,
               channel: :notification,
               outcome: :failed,
               failure_class: :rejected,
               fault_plane: :provider,
               refs: %{message_ref: "msg-77"}
             }
    end

    test "maps proven callback delay cues to webhook-ingest telemetry instead of provider failure" do
      Parapet.Integrations.Chimeway.setup()

      :telemetry.execute(
        [:chimeway, :event, :failed],
        %{duration: 45_000_000},
        %{provider: :smtp, error: :callback_timeout, message_id: "msg-88", delay_ms: 90_000}
      )

      assert_receive {:telemetry_event, [:parapet, :delivery, :webhook_ingest], measurements,
                      metadata}

      assert measurements.duration_ms == 45
      assert metadata == %{
               integration: :chimeway,
               provider: :smtp,
               channel: :notification,
               outcome: :failed,
               failure_class: :callback_timeout,
               delay_bucket: :under_5m,
               fault_plane: :webhook,
               refs: %{message_ref: "msg-88"}
             }
    end
  end
end
