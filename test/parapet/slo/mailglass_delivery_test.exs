defmodule Parapet.SLO.MailglassDeliveryTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO.MailglassDelivery
  alias Parapet.SLO.SliceSpec

  test "exposes the locked mailglass slice catalog with provider acceptance distinct from delivery" do
    slices = MailglassDelivery.slos()

    assert Enum.map(slices, & &1.name) == [
             :mailglass_submit_acceptance,
             :mailglass_confirmed_delivery,
             :mailglass_webhook_freshness,
             :mailglass_suppression_drift
           ]

    acceptance = Enum.find(slices, &(&1.name == :mailglass_submit_acceptance))
    delivered = Enum.find(slices, &(&1.name == :mailglass_confirmed_delivery))

    assert %SliceSpec{} = acceptance
    assert acceptance.good_matchers[:outcome] == :provider_accepted
    assert delivered.good_matchers[:outcome] == :delivered
    assert acceptance.alert_class == :ticket
    assert delivered.alert_class == :page
  end

  test "suppression drift is diagnostic and not a default paging slo" do
    suppression = Enum.find(MailglassDelivery.slos(), &(&1.name == :mailglass_suppression_drift))
    assert suppression.kind == :diagnostic
    assert suppression.alert_class == :diagnostic
    assert suppression.labels[:fault_plane] == :suppression
  end
end
