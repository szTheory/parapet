defmodule Parapet.Metrics.RindleTest do
  use ExUnit.Case, async: true

  alias Parapet.Metrics.AsyncDelivery

  test "rindle selectors stay on the shared async families" do
    assert AsyncDelivery.selector(:stage, [integration: :rindle, queue: "media", pipeline_stage: :transcode]) ==
             ~s(parapet_async_stage_total{integration="rindle", pipeline_stage="transcode", queue="media"})

    assert AsyncDelivery.selector(:backlog, [integration: :rindle, queue: "media"]) ==
             ~s(parapet_async_backlog_total{integration="rindle", queue="media"})

    assert AsyncDelivery.selector(:callback, [integration: :rindle, queue: "callbacks", pipeline_stage: :reconcile]) ==
             ~s(parapet_async_callback_total{integration="rindle", pipeline_stage="reconcile", queue="callbacks"})
  end
end
