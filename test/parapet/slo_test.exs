defmodule Parapet.SLOTest do
  use ExUnit.Case, async: false

  alias Parapet.SLO
  alias Parapet.SLO.Generator

  setup do
    # Clear the SLOs before each test
    Application.put_env(:parapet, :slos, [])
    :ok
  end

  describe "define/2" do
    test "creates a valid SLO and stores it" do
      slo =
        SLO.define(:api_availability,
          objective: 99.9,
          good_events: "http_requests_total{status=~\"5..\"}",
          total_events: "http_requests_total",
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
          good_events: "http_requests_total",
          total_events: "http_requests_total"
        )
      end
    end
  end

  describe "Parapet.SLO.Generator.generate_yaml/1" do
    test "generates multi-window PromQL avoiding rate(sum(...))" do
      slo = %SLO{
        name: :api_availability,
        objective: 99.9,
        good_events: "http_requests_total{status=~\"5..\"}",
        total_events: "http_requests_total",
        runbook: "https://runbook.example.com/api"
      }

      yaml = Generator.generate_yaml(slo)

      # Fast burn window 5m
      assert yaml =~
               "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))"

      # Fast burn window 30m
      assert yaml =~
               "sum(rate(http_requests_total{status=~\"5..\"}[30m])) / sum(rate(http_requests_total[30m]))"

      # Slow burn window 1h
      assert yaml =~
               "sum(rate(http_requests_total{status=~\"5..\"}[1h])) / sum(rate(http_requests_total[1h]))"

      # Optional: check with promtool if available
      if System.find_executable("promtool") do
        File.write!("tmp_rules.yaml", yaml)
        assert {_, 0} = System.cmd("promtool", ["check", "rules", "tmp_rules.yaml"])
        File.rm!("tmp_rules.yaml")
      end
    end
  end
end
