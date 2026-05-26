defmodule Parapet.Metrics.MailglassTest do
  use ExUnit.Case, async: true

  alias Parapet.Metrics.AsyncDelivery

  test "mailglass selectors bind to shared delivery families without new metric names" do
    assert AsyncDelivery.selector(:outbound, integration: :mailglass, channel: :email) ==
             ~s(parapet_delivery_outbound_total{channel="email", integration="mailglass"})

    assert AsyncDelivery.selector(:provider_feedback,
             integration: :mailglass,
             outcome: :delivered
           ) ==
             ~s(parapet_delivery_provider_feedback_total{integration="mailglass", outcome="delivered"})
  end
end
