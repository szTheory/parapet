defmodule Parapet.SLOTest do
  use ExUnit.Case, async: false

  alias Parapet.SLO

  setup do
    # Clear the SLOs before each test
    Application.put_env(:parapet, :slos, [])
    :ok
  end

  describe "define/2" do
    test "creates a valid SLO and stores it" do
      slo = SLO.define(:api_availability,
        objective: 99.9,
        good_events: "sum(rate(http_requests_total{status=~\"5..\"}[5m]))",
        total_events: "sum(rate(http_requests_total[5m]))",
        runbook: "https://runbook.example.com/api"
      )

      assert %SLO{} = slo
      assert slo.name == :api_availability
      assert slo.objective == 99.9
      assert slo.runbook == "https://runbook.example.com/api"

      # Check if stored
      assert [%SLO{name: :api_availability}] = SLO.all()
    end

    test "raises ArgumentError when missing required fields" do
      assert_raise ArgumentError, ~r/missing required fields.*runbook/, fn ->
        SLO.define(:api_availability,
          objective: 99.9,
          good_events: "sum",
          total_events: "sum"
        )
      end
    end
  end
end
