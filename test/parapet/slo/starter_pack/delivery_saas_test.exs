defmodule Parapet.SLO.StarterPack.DeliverySaaSTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO.ChimewayDelivery
  alias Parapet.SLO.MailglassDelivery
  alias Parapet.SLO.StarterPack.DeliverySaaS
  alias Parapet.SLO.StarterPack.WebSaaS

  # Guaranteed-absent module atoms — intentionally never defined in this codebase.
  # Used to test the absent-branch of delivery_slices/2 without unloading stubs mid-suite.
  @absent Parapet.SLO.StarterPack.DeliverySaaSTest.Absent
  @absent2 Parapet.SLO.StarterPack.DeliverySaaSTest.Absent2

  # PRESENT branch: in :test env Mailglass and Chimeway stubs are loaded via test/support/
  # (elixirc_paths(:test) includes "test/support"), so Code.ensure_loaded? returns true for both.
  test "returns all 10 slices when both Mailglass and Chimeway stubs are loaded (test env)" do
    slices = DeliverySaaS.slos()
    # 3 WebSaaS + 4 MailglassDelivery + 3 ChimewayDelivery = 10
    assert length(slices) == 10
  end

  test "slice names equal WebSaaS ++ MailglassDelivery ++ ChimewayDelivery names in order (delegation, no drift)" do
    delivery_slices = DeliverySaaS.slos()

    expected_names =
      Enum.map(WebSaaS.slos(), & &1.name) ++
        Enum.map(MailglassDelivery.slos(), & &1.name) ++
        Enum.map(ChimewayDelivery.slos(), & &1.name)

    assert Enum.map(delivery_slices, & &1.name) == expected_names
  end

  test "first 3 names equal WebSaaS.slos/0 names exactly, in order" do
    delivery_slices = DeliverySaaS.slos()
    websaas_names = Enum.map(WebSaaS.slos(), & &1.name)

    actual_first_3 = delivery_slices |> Enum.take(3) |> Enum.map(& &1.name)

    assert actual_first_3 == websaas_names
  end

  test "every MailglassDelivery slice name appears in DeliverySaaS slices (delegation proven)" do
    delivery_slice_names = DeliverySaaS.slos() |> Enum.map(& &1.name)
    mailglass_names = MailglassDelivery.slos() |> Enum.map(& &1.name)

    Enum.each(mailglass_names, fn name ->
      assert name in delivery_slice_names,
             "Expected #{inspect(name)} from MailglassDelivery to be in DeliverySaaS slices"
    end)
  end

  test "every ChimewayDelivery slice name appears in DeliverySaaS slices (delegation proven)" do
    delivery_slice_names = DeliverySaaS.slos() |> Enum.map(& &1.name)
    chimeway_names = ChimewayDelivery.slos() |> Enum.map(& &1.name)

    Enum.each(chimeway_names, fn name ->
      assert name in delivery_slice_names,
             "Expected #{inspect(name)} from ChimewayDelivery to be in DeliverySaaS slices"
    end)
  end

  # ABSENT branch: pass guaranteed-absent atoms to delivery_slices/2 — the SLO-02 compile-out
  # core behavior. No module unloading required; both branches tested in the same suite run.
  test "delivery_slices/2 returns [] when both provider atoms are absent (absent-branch, SLO-02 compile-out)" do
    assert DeliverySaaS.delivery_slices(@absent, @absent2) == []
  end

  test "WebSaaS.slos() ++ delivery_slices(absent, absent) yields exactly 3 WebSaaS slices" do
    combined = WebSaaS.slos() ++ DeliverySaaS.delivery_slices(@absent, @absent2)
    assert length(combined) == 3
    assert Enum.map(combined, & &1.name) == Enum.map(WebSaaS.slos(), & &1.name)
  end

  # MIXED branch: one provider present, one absent — proves each guard is independent.
  test "delivery_slices/2 returns only 4 Mailglass slices when Chimeway atom is absent" do
    result = DeliverySaaS.delivery_slices(Mailglass, @absent2)
    assert length(result) == 4
    expected_names = MailglassDelivery.slos() |> Enum.map(& &1.name)
    assert Enum.map(result, & &1.name) == expected_names
  end

  # D-09 always-loadable guarantee: module is always defined regardless of host libs.
  test "DeliverySaaS module is defined and slos/0 is exported (always-loadable, D-09)" do
    assert function_exported?(DeliverySaaS, :slos, 0)
  end
end
