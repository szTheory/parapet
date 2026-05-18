defmodule Parapet.SLO.ResolvableTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO
  alias Parapet.SLO.SliceSpec

  defmodule CustomSLO do
    defstruct [:name]
  end

  test "resolves a standard Parapet.SLO without changes" do
    slo = %SLO{
      name: :test_slo,
      objective: 99.9,
      good_events: "good",
      total_events: "total",
      runbook: "http://runbook"
    }

    assert %SLO{} = Parapet.SLO.Resolvable.to_slo(slo)
  end

  test "slice specs validate required bounded fields" do
    assert_raise ArgumentError, ~r/requires objective/, fn ->
      SliceSpec.new(
        name: :missing_objective,
        integration: :mailglass,
        kind: :ratio,
        source_metric: "parapet_delivery_outbound_total",
        good_matchers: [outcome: :attempted],
        total_matchers: [outcome: :attempted],
        alert_class: :page,
        runbook: "https://example.com/runbooks/missing-objective"
      )
    end
  end

  test "slice specs resolve into compatibility slo structs without raw ad hoc promql in providers" do
    slice =
      SliceSpec.new(
        name: :mailglass_confirmed_delivery,
        integration: :mailglass,
        kind: :ratio,
        source_metric: "parapet_delivery_provider_feedback_total",
        good_matchers: [integration: :mailglass, outcome: :delivered],
        total_matchers: [integration: :mailglass],
        objective: 99.0,
        alert_class: :page,
        runbook: "https://example.com/runbooks/mailglass-confirmed-delivery"
      )

    slo = Parapet.SLO.Resolvable.to_slo(slice)

    assert %SLO{} = slo
    assert slo.name == :mailglass_confirmed_delivery
    assert slo.objective == 99.0
    assert slo.good_events =~ "parapet_delivery_provider_feedback_total"
    assert slo.total_events =~ "parapet_delivery_provider_feedback_total"
    assert slo.runbook =~ "mailglass-confirmed-delivery"
  end
end
