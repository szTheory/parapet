defmodule Parapet.Telemetry.AsyncDeliveryTest do
  use ExUnit.Case, async: true

  alias Parapet.Telemetry.AsyncDelivery

  test "exposes the six locked public event families" do
    assert AsyncDelivery.event_families() == [
             [:parapet, :delivery, :outbound],
             [:parapet, :delivery, :provider_feedback],
             [:parapet, :delivery, :webhook_ingest],
             [:parapet, :async, :stage],
             [:parapet, :async, :backlog],
             [:parapet, :async, :callback]
           ]
  end

  test "normalizes bounded delivery and async outcomes only" do
    assert AsyncDelivery.normalize_delivery_outcome(:accepted) == :provider_accepted
    assert AsyncDelivery.normalize_delivery_outcome("delivered") == :delivered
    assert AsyncDelivery.normalize_async_outcome(:completed) == :succeeded
    assert AsyncDelivery.normalize_async_outcome("retryable") == :retryable_failed

    assert_raise ArgumentError, ~r/Unsupported delivery outcome/, fn ->
      AsyncDelivery.normalize_delivery_outcome(:queued)
    end

    assert_raise ArgumentError, ~r/Unsupported async outcome/, fn ->
      AsyncDelivery.normalize_async_outcome(:failed)
    end
  end

  test "shapes exact identifiers into refs and drops unknown metadata" do
    shaped =
      AsyncDelivery.shape_metadata(:provider_feedback, %{
        integration: :mailglass,
        provider: :ses,
        channel: :email,
        outcome: :accepted,
        provider_message_id: "pm-123",
        recipient_id: "user-42",
        raw_payload: %{ignored: true},
        debug_reason: "ignored"
      })

    assert shaped.integration == :mailglass
    assert shaped.provider == :ses
    assert shaped.channel == :email
    assert shaped.outcome == :provider_accepted
    assert shaped.refs == %{provider_message_ref: "pm-123", recipient_ref: "user-42"}
    refute Map.has_key?(shaped, :raw_payload)
    refute Map.has_key?(shaped, :debug_reason)
  end

  test "buckets delay values into bounded labels" do
    assert AsyncDelivery.delay_bucket(500) == :subsecond
    assert AsyncDelivery.delay_bucket(20_000) == :under_30s
    assert AsyncDelivery.delay_bucket(120_000) == :under_5m
    assert AsyncDelivery.delay_bucket(1_200_000) == :under_1h
    assert AsyncDelivery.delay_bucket(7_200_000) == :over_1h
  end
end
