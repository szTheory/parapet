defmodule Parapet.SLO.ChimewayDeliveryTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO.ChimewayDelivery

  test "exposes the locked chimeway slice catalog aligned to the proven surface" do
    slices = ChimewayDelivery.slos()

    assert Enum.map(slices, & &1.name) == [
             :chimeway_provider_acceptance,
             :chimeway_callback_confirmation,
             :chimeway_callback_freshness
           ]

    provider_acceptance = Enum.find(slices, &(&1.name == :chimeway_provider_acceptance))
    callback_confirmation = Enum.find(slices, &(&1.name == :chimeway_callback_confirmation))
    callback_freshness = Enum.find(slices, &(&1.name == :chimeway_callback_freshness))

    assert provider_acceptance.labels[:fault_plane] == :provider
    assert callback_confirmation.labels[:fault_plane] == :webhook
    assert callback_freshness.labels[:fault_plane] == :webhook
    assert callback_freshness.kind == :freshness
  end
end
