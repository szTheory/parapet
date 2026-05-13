defmodule Parapet.SLO.ResolvableTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO

  defmodule CustomSLO do
    defstruct [:name]
  end

  # We will mock an implementation inside the test or just test the fallback/default.
  # The task asks: "Test 1: Resolvable protocol falls back or implements to_slo/1 returning a Parapet.SLO.t()."

  test "Resolvable protocol falls back or implements to_slo/1 returning a Parapet.SLO.t() for Parapet.SLO" do
    slo = %SLO{
      name: :test_slo,
      objective: 99.9,
      good_events: "good",
      total_events: "total",
      runbook: "http://runbook"
    }

    assert %SLO{} = Parapet.SLO.Resolvable.to_slo(slo)
  end
end