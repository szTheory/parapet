defmodule Parapet.SLO.HTTP do
  @moduledoc """
  Provides an out-of-the-box SLO definition for HTTP request serving.
  """

  @doc """
  Registers the HTTP SLO with the Parapet.SLO registry.

  ## Options

    * `:objective` - The target objective percentage (default: `99.9`).
    * `:good_events` - PromQL string for good events.
      (default: `"sum(rate(parapet_http_server_duration_milliseconds_count{status_code=~\"2..|3..\"}[5m]))"`)
    * `:total_events` - PromQL string for total events.
      (default: `"sum(rate(parapet_http_server_duration_milliseconds_count[5m]))"`)
    * `:runbook` - URL to the runbook for this SLO. (default: `"https://example.com/runbooks/http-slo"`)
  """
  def register(opts \\ []) do
    objective = Keyword.get(opts, :objective, 99.9)

    good_events =
      Keyword.get(
        opts,
        :good_events,
        "parapet_http_server_duration_milliseconds_count{status_code=~\"2..|3..\"}"
      )

    total_events =
      Keyword.get(
        opts,
        :total_events,
        "parapet_http_server_duration_milliseconds_count"
      )

    runbook = Keyword.get(opts, :runbook, "https://example.com/runbooks/http-slo")

    Parapet.SLO.define(:http,
      objective: objective,
      good_events: good_events,
      total_events: total_events,
      runbook: runbook
    )
  end
end
