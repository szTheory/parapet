defmodule Parapet.SLOTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

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
    # SLO.define/2 is intentionally @deprecated (see STAB-06 test below) but must
    # still be exercised here while the legacy path is supported. Call it via
    # apply/3 consistently so these tests do not emit deprecation warnings at
    # compile time and remain compatible with --warnings-as-errors. The dedicated
    # STAB-06 test above is where the deprecation warning itself is asserted.
    test "creates a valid SLO and stores it" do
      slo =
        apply(SLO, :define, [
          :api_availability,
          [
            objective: 99.9,
            good_events: "http_requests_total{status=~\"5..\"}",
            total_events: "http_requests_total",
            runbook: "https://runbook.example.com/api"
          ]
        ])

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
      # Set up legacy (deprecated path — call via apply/3, see note in describe "define/2")
      apply(SLO, :define, [
        :legacy_slo,
        [
          objective: 99.9,
          good_events: "legacy_good",
          total_events: "legacy_total",
          runbook: "legacy_runbook"
        ]
      ])

      # Set up provider
      Application.put_env(:parapet, :providers, [DummyProvider])

      all_slos = SLO.all()

      assert length(all_slos) == 2
      assert Enum.any?(all_slos, &(&1.name == :legacy_slo))
      assert Enum.any?(all_slos, &(&1.name == :provider_slo))
    end

    test "attach does not silently activate providers" do
      # Parapet.attach/1 resolves each adapter and runs its setup/0, which attaches
      # global :telemetry handlers (process-independent state). Detach the exact
      # handler ids these adapters register so they do not leak into other suites
      # running in the same VM.
      on_exit(fn ->
        for id <- [
              "parapet-mailglass-delivery",
              "parapet-chimeway-delivery-events",
              "parapet-rindle-async"
            ] do
          :telemetry.detach(id)
        end
      end)

      Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])
      assert SLO.provider_catalog() == []
      assert SLO.all() == []
    end
  end

  describe "Parapet.SLO.define/2 compile-time deprecation warning (STAB-06)" do
    # STAB-06: @deprecated is already in place at lib/parapet/slo.ex:29.
    # This test verifies that the compile-time warning fires and names the replacement.
    # No production code change is made here — this is verification only (D-14).
    test "emits compile-time deprecation warning naming Parapet.SLO.Provider" do
      # Use a unique module name per run so recompiling the probe never emits a
      # "redefining module" warning that would pollute the captured stderr.
      probe_module = "Parapet.SLOTest.DeprecationProbe#{System.unique_integer([:positive])}"

      output =
        capture_io(:stderr, fn ->
          Code.compile_string("""
          defmodule #{probe_module} do
            def check do
              Parapet.SLO.define(:test_slo, [
                objective: 99.0,
                good_events: "x",
                total_events: "y",
                runbook: "http://example.com"
              ])
            end
          end
          """)
        end)

      # Assert on the stable part of the message that WE control (the @deprecated
      # string), not the compiler-generated "deprecated" prefix whose format has
      # changed across Elixir versions. This also confirms the warning names the
      # replacement module.
      assert output =~ "Use a Parapet.SLO.Provider module instead",
             "Expected compile-time deprecation warning to carry the @deprecated message " <>
               "'Use a Parapet.SLO.Provider module instead'. The @deprecated attribute at " <>
               "lib/parapet/slo.ex:35 must fire when a call site is compiled and name the replacement."
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
