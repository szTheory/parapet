defmodule Parapet.SLO.GeneratorTest do
  use ExUnit.Case, async: true

  alias Parapet.SLO
  alias Parapet.SLO.Generator
  alias Parapet.SLO.MailglassDelivery

  test "generator distinguishes legacy slos from richer provider slice specs" do
    legacy = %SLO{
      name: :legacy_http,
      objective: 99.9,
      good_events: "phoenix_http_total{status=~\"2..|3..\"}",
      total_events: "phoenix_http_total",
      runbook: "https://example.com/runbooks/http"
    }

    [slice | _] = MailglassDelivery.slos()

    artifacts = Generator.build_artifacts([legacy, slice])

    assert artifacts.recording_rules =~ "parapet_legacy_http_recording"
    assert artifacts.recording_rules =~ "parapet_mailglass_submit_acceptance_recording"
    assert artifacts.alerts =~ "MailglassSubmitAcceptanceTicket"
    assert artifacts.alerts =~ "LegacyHttpSLOBurnRateWarning"
  end

  test "generated alerts include durations, volume guards, and separate severities" do
    pageable = Enum.find(MailglassDelivery.slos(), &(&1.name == :mailglass_confirmed_delivery))
    diagnostic = Enum.find(MailglassDelivery.slos(), &(&1.name == :mailglass_suppression_drift))
    artifacts = Generator.build_artifacts([pageable, diagnostic])

    assert artifacts.alerts =~ "for:"
    assert artifacts.alerts =~ "keep_firing_for:"
    assert artifacts.alerts =~ "severity: \"page\""
    assert artifacts.alerts =~ "severity: \"warning\""
    assert artifacts.alerts =~ "parapet:mailglass_confirmed_delivery:error_ratio:5m >"
    assert artifacts.alerts =~ "> 0.01"
  end

  test "provider artifacts use active providers only" do
    Application.put_env(:parapet, :slos, [
      %SLO{
        name: :legacy_only,
        objective: 99.0,
        good_events: "legacy_good",
        total_events: "legacy_total",
        runbook: "https://example.com/runbooks/legacy"
      }
    ])

    Application.put_env(:parapet, :providers, [MailglassDelivery])

    on_exit(fn ->
      Application.put_env(:parapet, :slos, [])
      Application.put_env(:parapet, :providers, [])
    end)

    artifacts = Generator.provider_artifacts()

    assert artifacts.recording_rules =~ "mailglass_submit_acceptance"
    refute artifacts.recording_rules =~ "legacy_only"
  end
end
