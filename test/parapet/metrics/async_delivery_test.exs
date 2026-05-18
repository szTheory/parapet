defmodule Parapet.Metrics.AsyncDeliveryTest do
  use ExUnit.Case, async: true

  alias Parapet.Metrics.AsyncDelivery

  test "exports one shared metric catalog for the six phase 4 families" do
    metrics = AsyncDelivery.metrics()

    assert length(metrics) == 12

    metric_names =
      metrics
      |> Enum.map(&Enum.join(&1.name, "_"))
      |> Enum.sort()

    assert metric_names == [
             "parapet_async_backlog_delay_seconds",
             "parapet_async_backlog_total",
             "parapet_async_callback_delay_seconds",
             "parapet_async_callback_total",
             "parapet_async_stage_duration_seconds",
             "parapet_async_stage_total",
             "parapet_delivery_outbound_duration_seconds",
             "parapet_delivery_outbound_total",
             "parapet_delivery_provider_feedback_duration_seconds",
             "parapet_delivery_provider_feedback_total",
             "parapet_delivery_webhook_ingest_delay_seconds",
             "parapet_delivery_webhook_ingest_total"
           ]
  end

  test "counter and duration naming follow prometheus conventions" do
    metrics = AsyncDelivery.metrics()

    assert Enum.any?(metrics, &(&1.name == [:parapet_delivery_provider_feedback_total]))
    assert Enum.any?(metrics, &(&1.name == [:parapet_async_callback_delay_seconds]))
    refute Enum.any?(metrics, &(&1.name == [:parapet_async_callback_delay_ms]))
  end

  test "backlog and callback stay separate shared families" do
    assert AsyncDelivery.metric_name(:backlog, :total) == "parapet_async_backlog_total"
    assert AsyncDelivery.metric_name(:callback, :total) == "parapet_async_callback_total"
    assert AsyncDelivery.metric_name(:backlog, :delay) == "parapet_async_backlog_delay_seconds"
    assert AsyncDelivery.metric_name(:callback, :delay) == "parapet_async_callback_delay_seconds"
  end
end
