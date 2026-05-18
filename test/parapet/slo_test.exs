defmodule Parapet.SLOTest do
  use ExUnit.Case, async: false

  alias Parapet.SLO
  alias Parapet.SLO.Generator

  setup do
    # Clear the SLOs before each test
    Application.put_env(:parapet, :slos, [])
    Application.put_env(:parapet, :providers, [])

    on_exit(fn ->
      Application.put_env(:parapet, :slos, [])
      Application.put_env(:parapet, :providers, [])
    end)

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
        apply(SLO, :define, [
          :api_availability,
          [
            objective: 99.9,
            good_events: "http_requests_total",
            total_events: "http_requests_total"
          ]
        ])
      end
    end
  end

  describe "all/0" do
    defmodule DummyProvider do
      @behaviour Parapet.SLO.Provider

      def slos do
        [
          %Parapet.SLO{
            name: :provider_slo,
            objective: 99.0,
            good_events: "provider_good",
            total_events: "provider_total",
            runbook: "provider_runbook"
          }
        ]
      end
    end

    test "merges legacy environment state and data-first providers" do
      # Set up legacy
      SLO.define(:legacy_slo,
        objective: 99.9,
        good_events: "legacy_good",
        total_events: "legacy_total",
        runbook: "legacy_runbook"
      )

      # Set up provider
      Application.put_env(:parapet, :providers, [DummyProvider])

      all_slos = SLO.all()

      assert length(all_slos) == 2
      assert Enum.any?(all_slos, &(&1.name == :legacy_slo))
      assert Enum.any?(all_slos, &(&1.name == :provider_slo))
    end

    test "attach does not silently activate providers" do
      Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])
      assert SLO.provider_catalog() == []
      assert SLO.all() == []
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

      assert yaml =~ "parapet:api_availability:error_ratio:5m"
      assert yaml =~ "sum(rate(http_requests_total{status=~\\\"5..\\\"}[5m]))"
      assert yaml =~ "clamp_min(sum(rate(http_requests_total[5m])), 1)"
      assert yaml =~ "parapet:api_availability:error_ratio:30m"
      assert yaml =~ "parapet:api_availability:error_ratio:1h"

      # Optional: check with promtool if available
      if System.find_executable("promtool") do
        File.write!("tmp_rules.yaml", yaml)
        assert {_, 0} = System.cmd("promtool", ["check", "rules", "tmp_rules.yaml"])
        File.rm!("tmp_rules.yaml")
      end
    end
  end
end
