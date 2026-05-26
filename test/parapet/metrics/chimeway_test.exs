defmodule Parapet.Metrics.ChimewayTest do
  use ExUnit.Case, async: true

  alias Parapet.Metrics.AsyncDelivery

  test "chimeway selectors stay on the shared delivery families" do
    assert AsyncDelivery.selector(:provider_feedback,
             integration: :chimeway,
             fault_plane: :provider
           ) ==
             ~s(parapet_delivery_provider_feedback_total{fault_plane="provider", integration="chimeway"})

    assert AsyncDelivery.selector(:webhook_ingest, integration: :chimeway, fault_plane: :webhook) ==
             ~s(parapet_delivery_webhook_ingest_total{fault_plane="webhook", integration="chimeway"})
  end
end
