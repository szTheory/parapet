defmodule Parapet.SLO.LoginJourney do
  @moduledoc """
  Provides an out-of-the-box SLO definition for the standard login journey.
  """

  @doc """
  Registers the login journey SLO with the Parapet.SLO registry.

  ## Options

    * `:objective` - The target objective percentage (default: `99.9`).
    * `:good_events` - PromQL string for good events.
      (default: `"sum(rate(parapet_journey_login_duration_milliseconds_count{outcome=\"success\"}[5m]))"`)
    * `:total_events` - PromQL string for total events.
      (default: `"sum(rate(parapet_journey_login_duration_milliseconds_count[5m]))"`)
    * `:runbook` - URL to the runbook for this SLO. (default: `"https://example.com/runbooks/login-journey"`)
  """
  def register(opts \\ []) do
    objective = Keyword.get(opts, :objective, 99.9)
    
    # We default to the Prometheus _count suffix generated for distributions/histograms
    good_events = Keyword.get(
      opts,
      :good_events,
      "sum(rate(parapet_journey_login_duration_milliseconds_count{outcome=\"success\"}[5m]))"
    )
    
    total_events = Keyword.get(
      opts,
      :total_events,
      "sum(rate(parapet_journey_login_duration_milliseconds_count[5m]))"
    )
    
    runbook = Keyword.get(opts, :runbook, "https://example.com/runbooks/login-journey")

    Parapet.SLO.define(:login_journey,
      objective: objective,
      good_events: good_events,
      total_events: total_events,
      runbook: runbook
    )
  end
end
