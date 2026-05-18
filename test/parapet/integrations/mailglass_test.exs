defmodule Parapet.Integrations.MailglassTest do
  use ExUnit.Case, async: false

  @integration_handler_ids [
    "parapet-mailglass-delivery-outbound",
    "parapet-mailglass-delivery-feedback",
    "parapet-mailglass-delivery-webhook"
  ]

  @parapet_events [
    [:parapet, :delivery, :outbound],
    [:parapet, :delivery, :provider_feedback],
    [:parapet, :delivery, :webhook_ingest]
  ]

  setup do
    test_pid = self()

    Enum.each(@integration_handler_ids, &:telemetry.detach/1)

    handler_ids =
      Enum.map(@parapet_events, fn event_name ->
        handler_id = "test-#{Enum.join(event_name, "-")}-mailglass"

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
      Enum.each(@integration_handler_ids, &:telemetry.detach/1)
    end)

    :ok
  end

  describe "setup/0 and handle_event/4" do
    test "emits normalized outbound delivery events with bounded metadata" do
      Parapet.Integrations.Mailglass.setup()

      :telemetry.execute(
        [:mailglass, :outbound, :send, :stop],
        %{duration: 200_000_000},
        %{
          provider: :ses,
          stream: :transactional,
          status: :accepted,
          message_id: "msg-123",
          delivery_id: "del-123",
          tenant_id: "tenant-9",
          recipient_count: 2,
          recipient: "person@example.com"
        }
      )

      assert_receive {:telemetry_event, [:parapet, :delivery, :outbound], measurements, metadata}

      assert measurements.duration_ms == 200
      assert metadata == %{
               integration: :mailglass,
               provider: :ses,
               channel: :email,
               outcome: :attempted,
               fault_plane: :provider,
               refs: %{message_ref: "msg-123", delivery_ref: "del-123"}
             }
    end

    test "emits normalized provider feedback outcomes without exposing exact identifiers" do
      Parapet.Integrations.Mailglass.setup()

      :telemetry.execute(
        [:mailglass, :reconcile, :stop],
        %{duration: 125_000_000},
        %{
          provider: :ses,
          status: :delivered,
          delivery_id: "del-555",
          provider_message_id: "provider-888",
          event_id: "evt-123"
        }
      )

      assert_receive {:telemetry_event, [:parapet, :delivery, :provider_feedback], measurements,
                      metadata}

      assert measurements.duration_ms == 125
      assert metadata.integration == :mailglass
      assert metadata.provider == :ses
      assert metadata.channel == :email
      assert metadata.outcome == :delivered
      assert metadata.fault_plane == :provider
      assert metadata.refs == %{
               delivery_ref: "del-555",
               provider_message_ref: "provider-888"
             }

      refute Map.has_key?(metadata, :event_id)
      refute Map.has_key?(metadata, :tenant_id)
    end

    test "keeps webhook ingest delay and failure distinct from provider failures" do
      Parapet.Integrations.Mailglass.setup()

      :telemetry.execute(
        [:mailglass, :webhook, :ingest, :exception],
        %{duration: 80_000_000},
        %{
          provider: :ses,
          event_id: "evt-404",
          delivery_id: "del-404",
          latency_ms: 42_000,
          error: :signature_invalid
        }
      )

      assert_receive {:telemetry_event, [:parapet, :delivery, :webhook_ingest], measurements,
                      metadata}

      assert measurements.duration_ms == 80
      assert metadata == %{
               integration: :mailglass,
               provider: :ses,
               channel: :email,
               outcome: :failed,
               failure_class: :signature_invalid,
               delay_bucket: :under_5m,
               fault_plane: :webhook,
               refs: %{delivery_ref: "del-404"}
             }
    end
  end
end
