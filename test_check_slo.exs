defmodule Parapet.DoctorTestHarness do
  def run do
    Parapet.SLO.Registry.checkout()
    Parapet.SLO.Registry.store(%Parapet.SLO{
      name: :test_slo_unregistered_cap,
      objective: 99.9,
      good_events: "rate(events[5m])",
      total_events: "sum(rate(events[5m]))",
      runbook: "some_runbook"
    })
    IO.inspect(Parapet.SLO.all(), label: "ALL SLOS")
  end
end
Parapet.DoctorTestHarness.run()
