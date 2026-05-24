defmodule Parapet.SLO.StarterPack.WebSaaS do
  @moduledoc """
  Opinionated first-SLO pack for Phoenix SaaS teams.

  Register in one line:

      config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]

  Ships three slices with documented default objectives, each pinned to the real
  Prometheus series this codebase emits. These are opinionated, inspectable, and
  overridable defaults — not auto-generated targets.

  ## Slices

  ### HTTP Availability (`web_saas_http_availability`)

  - **Metric:** `parapet_http_request_count` — the real HTTP counter emitted by Parapet's
    plug (`parapet.http.request.count` → Prometheus underscores).
  - **Objective:** 99.5% — approximately 3.65 hours/month of non-2xx/3xx budget.
  - **Alert class:** `:ticket` — aggregate HTTP errors are noisy on first adoption;
    ticket-level keeps alert fatigue low. Upgrade to `:page` once you understand your
    actual traffic patterns.
  - **Matches:** `status_class` label (values `"2xx"`, `"3xx"`, `"4xx"`, `"5xx"`).
    The plug emits `status_class` as a low-cardinality tag; use it for label selectors.

  ### Login Journey (`web_saas_login_journey`)

  - **Metric:** `parapet_journey_login_count` — the Sigra integration counter
    (`parapet.journey.login.count` → Prometheus underscores).
  - **Objective:** 99.9% — approximately 43 minutes/month of user-impacting auth failures.
  - **Alert class:** `:page` — auth failures are silent revenue loss; worth paging.
    Login failures are low-volume and directly user-impacting.
  - **Matches:** `outcome` label (`:success` / `:failure`).

  ### Oban Job Success (`web_saas_oban_job_success`)

  - **Metric:** `parapet_oban_jobs_total` — the Oban integration counter
    (`parapet.oban.jobs.total` → Prometheus underscores).
  - **Objective:** 99.0% — approximately 7.3 hours/month of job-level failures.
  - **Alert class:** `:ticket` — jobs include retries, so transient failures are expected;
    99.0% accommodates retry-normal patterns. Adopters with critical-path jobs (e.g.
    payment processing) should override to 99.9% + `:page`.
  - **Matches:** `state` label (values `"success"`, `"failure"`, `"cancelled"`, `"discarded"`).

  ## Low-Traffic Safety

  All slices use the default `min_total_rate: 0.01` (~0.6 requests/minute over a 1-hour
  window), which the Generator renders as `... and <total_rate_record> > 0.01` in every
  alert expression. This prevents alert flapping on low-traffic services. Zero Generator
  changes are required.
  """

  @behaviour Parapet.SLO.Provider

  alias Parapet.SLO.SliceSpec

  @doc """
  Returns the three WebSaaS SLO slices: HTTP availability, login journey, and Oban job success.

  Each slice is pinned to the real Prometheus series emitted by this codebase, with an
  opinionated default objective and low-cardinality label matchers. Register this provider
  via `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]`.
  """
  @impl true
  def slos do
    [
      SliceSpec.new(
        name: :web_saas_http_availability,
        integration: :http,
        kind: :ratio,
        good_source_metric: "parapet_http_request_count",
        good_matchers: [status_class: ["2xx", "3xx"]],
        total_source_metric: "parapet_http_request_count",
        total_matchers: [status_class: ["2xx", "3xx", "4xx", "5xx"]],
        objective: 99.5,
        alert_class: :ticket,
        runbook: "https://parapet.dev/runbooks/http-availability",
        group_labels: [:integration, :method],
        summary: "HTTP availability is below 99.5%"
      ),
      SliceSpec.new(
        name: :web_saas_login_journey,
        integration: :auth,
        kind: :ratio,
        good_source_metric: "parapet_journey_login_count",
        good_matchers: [outcome: :success],
        total_source_metric: "parapet_journey_login_count",
        total_matchers: [outcome: [:success, :failure]],
        objective: 99.9,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/login-journey",
        group_labels: [:integration],
        summary: "Login journey success is below 99.9%"
      ),
      SliceSpec.new(
        name: :web_saas_oban_job_success,
        integration: :oban,
        kind: :ratio,
        good_source_metric: "parapet_oban_jobs_total",
        good_matchers: [state: "success"],
        total_source_metric: "parapet_oban_jobs_total",
        total_matchers: [state: ["success", "failure", "cancelled", "discarded"]],
        objective: 99.0,
        alert_class: :ticket,
        runbook: "https://parapet.dev/runbooks/oban-job-success",
        group_labels: [:integration, :queue],
        summary: "Oban job success is below 99.0%"
      )
    ]
  end
end
