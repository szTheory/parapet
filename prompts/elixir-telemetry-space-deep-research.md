My take

For an Elixir/Phoenix SaaS in 2026, observability is viable, mature enough, and cheap enough without Datadog.

But the stack is uneven:

Signal	Elixir/Phoenix maturity	2026 practical answer
Metrics	Strong	Use Phoenix Telemetry + Telemetry.Metrics + PromEx or Peep → Prometheus/Grafana.
Traces	Good	Use OpenTelemetry Phoenix/Cowboy/Ecto/LiveView instrumentation → OTLP collector/backend.
Logs	Okay, but less elegant	Use structured JSON logs → Grafana Alloy / Fluent Bit / Vector → Loki/OpenObserve/SigNoz. Do not start new installs with Promtail.
Dashboards	Good	Grafana can absolutely give you RED, SLO, infra, app, and business dashboards. Some assembly required.
SLOs / SRE workflows	Good tooling, nontrivial design	Prometheus + Grafana alerting can do it. The hard part is choosing SLIs/SLOs and avoiding noisy alerts.
“Dead simple Phoenix observability kit”	Still a gap	This is where your OSS-library instincts are probably correct. Not a new backend. A generated, host-owned, opinionated integration kit.

Given your Hex profile, you are not “just another user trying to plug in a SaaS widget.” You have recently published a meaningful amount of Elixir OSS, including Phoenix/Ecto-oriented libraries like sigra, and your package list shows a pattern of filling application-layer gaps with host-owned tooling. Hex currently shows your profile with 16 packages and roughly 29k+ total downloads; sigra in particular is described as Phoenix 1.8+/Ecto auth with generators that emit host-owned code. That matters: the observability opportunity for you is probably not “build an observability platform.” It is “generate the boring, correct Phoenix observability wiring that everyone keeps re-discovering.”  ￼

⸻

The memorable mental model

Think of observability as four pipes leaving your app:

flowchart LR
  App["Phoenix app"]
  App -->|Telemetry events| Metrics["Metrics<br/>rates, counts, durations"]
  App -->|OpenTelemetry spans| Traces["Traces<br/>request lifecycle, DB calls, jobs"]
  App -->|Logger JSON| Logs["Logs<br/>human/debug breadcrumbs"]
  App -->|Domain events| Biz["Business KPIs<br/>MRR, signups, churn, conversion"]
  Metrics --> Prom["Prometheus / Mimir / Grafana Cloud"]
  Traces --> Tempo["Tempo / Jaeger / SigNoz / OpenObserve"]
  Logs --> Loki["Loki / OpenObserve / SigNoz"]
  Biz --> DB["Postgres / ClickHouse / warehouse"]
  Biz --> Prom
  Prom --> Grafana["Grafana dashboards + alerts"]
  Tempo --> Grafana
  Loki --> Grafana
  DB --> Grafana

The key intuition:

Metrics tell you that something is wrong.
Traces tell you where time went.
Logs tell you weird details.
Business events tell you whether the company is healthy.

For a solo SaaS founder, you want all four, but you do not want to operate four separate science projects.

⸻

The 2026 answer: plug in most of it, build glue only where it hurts

The ecosystem has enough pieces:

* Phoenix already emits Telemetry events.
* Ecto emits Telemetry events.
* Phoenix LiveDashboard gives you a local/dev observability baseline.
* PromEx turns common Elixir/Phoenix Telemetry events into Prometheus metrics and ships Grafana dashboards.
* Peep is a newer, actively maintained Telemetry.Metrics reporter aimed at efficient Prometheus/StatsD reporting.
* OpenTelemetry has working Erlang/Elixir tracing support and official Phoenix getting-started docs.
* Grafana, Prometheus, Loki, Tempo, OpenObserve, and SigNoz can all be used without Datadog.

But there is still a real gap: the “happy path” is fragmented. Recent ElixirForum discussion still shows people asking how to stitch together OpenTelemetry, PromEx, Prometheus, Loki, Tempo, OpenObserve, Promtail, etc.; one useful reply emphasized that :telemetry and OpenTelemetry are different tools, and another pointed out that OTel tracing works better than OTel metrics/logs in the Erlang/Elixir world right now.  ￼

So the correct strategic answer is:

Use existing OSS infrastructure. Build an opinionated Phoenix observability integration layer only after you feel the pain yourself.

Not a backend. Not a Datadog clone. Not a metrics database.

Build the thing that says:

mix my_obs.install --backend grafana_cloud
mix my_obs.install --backend self_hosted_grafana_stack
mix my_obs.install --backend openobserve
mix my_obs.install --backend signoz

…and emits host-owned code, Docker Compose, Grafana dashboards, Prometheus recording rules, alert rules, and sane Telemetry conventions.

That fits your existing OSS style much better than trying to compete with Grafana Labs, SigNoz, OpenObserve, or Sentry.

⸻

The domain language, lightly

Here is the minimum vocabulary that makes the whole space less fuzzy.

Metrics

Numbers over time.

Examples:

http_requests_total
http_request_duration_seconds_bucket
oban_job_errors_total
checkout_succeeded_total
stripe_webhook_duration_ms

Metrics are great for:

* “Are we healthy?”
* “How many requests per second?”
* “What is p95 latency?”
* “Did deploy X increase errors?”
* “How many checkouts happened today?”

Metrics are bad for:

* Per-user debugging.
* Arbitrary high-cardinality analysis.
* Exact financial reporting.

Logs

Text records.

Examples:

{
  "level": "error",
  "message": "Stripe webhook verification failed",
  "request_id": "abc123",
  "trace_id": "4bf92f...",
  "customer_id": "cus_123",
  "event_type": "invoice.paid"
}

Logs are great for:

* Debug breadcrumbs.
* Rare weird behavior.
* Human-readable context.

Logs are bad for:

* Primary alerting.
* High-volume analytics unless you control ingestion costs.
* Storing PII casually.

Traces

A trace is a tree of spans for one unit of work.

HTTP POST /checkout
├── load current_user
├── create checkout session
│   └── Stripe API call
├── insert order
└── render response

Traces are great for:

* “Why was this request slow?”
* “Did time go to Ecto, Stripe, Oban, or rendering?”
* “What happened inside this specific request?”

SLI, SLO, error budget

An SLI is the measurement.

“Percentage of API requests that complete successfully under 500ms.”

An SLO is the target.

“99.5% of API requests should be successful and under 500ms over 30 days.”

An error budget is the allowed failure.

If your SLO is 99.5%, your error budget is 0.5%.

Google’s SRE guidance frames SLOs around good events divided by total events, with error budgets used to balance reliability and feature velocity. Their examples use Prometheus-style SLIs for availability and latency, then derive error-budget-based alerting from those SLIs.  ￼

RED metrics

For request-serving systems, the classic dashboard is:

R = Rate      requests/sec
E = Errors    error ratio
D = Duration  latency p50/p95/p99

For a Phoenix SaaS, your default top-level dashboard should start with:

Requests by route
5xx error rate
p95 latency
DB query time
Oban queue latency
LiveView mount/handle_event latency
Stripe/webhook failures

⸻

What is mature in Elixir/Phoenix today?

1. Phoenix Telemetry is solid

Phoenix has first-class Telemetry docs. Phoenix emits Telemetry events during the application lifecycle, and those events can be turned into metrics by reporters. The Phoenix docs describe the generated Telemetry supervisor, Telemetry.Metrics, :telemetry_poller, endpoint events, Ecto integration, and metric reporters.  ￼

The key concept:

:telemetry.execute(
  [:my_app, :billing, :checkout, :succeeded],
  %{count: 1, amount_cents: 2999},
  %{plan: "pro", currency: "usd"}
)

That event can feed:

* Prometheus metrics
* Grafana dashboards
* internal analytics
* tests
* maybe later a warehouse sink

This is one of Elixir’s underrated superpowers.

⸻

2. Phoenix LiveDashboard is good for dev and small internal visibility

Phoenix LiveDashboard can render Telemetry metrics for your app, including VM metrics, endpoint metrics, and custom metrics. The docs show configuring live_dashboard "/dashboard", metrics: MyAppWeb.Telemetry and mapping metric types to charts.  ￼

Use it for:

local dev
staging
admin-only internal debugging
basic VM visibility

Do not treat it as your production observability backend.

It is a cockpit, not a black box recorder.

⸻

3. PromEx is probably the default Phoenix metrics starting point

PromEx describes itself as “Prometheus metrics and Grafana dashboards for all of your favorite Elixir libraries.” It provides plugins for common Elixir/Phoenix libraries and ships Grafana dashboard support. The project’s README says its goal is to provide Prometheus metrics and Grafana dashboards for many popular Elixir libraries, while giving you a framework for your own metrics and dashboards.  ￼

PromEx also has stable plugins for common pieces like Application, BEAM, Phoenix, Ecto, Oban, and Phoenix LiveView.  ￼

A sketch:

defmodule MyApp.PromEx do
  use PromEx, otp_app: :my_app
  @impl true
  def plugins do
    [
      PromEx.Plugins.Application,
      PromEx.Plugins.Beam,
      {PromEx.Plugins.Phoenix,
       router: MyAppWeb.Router,
       endpoint: MyAppWeb.Endpoint},
      {PromEx.Plugins.Ecto, repos: [MyApp.Repo]},
      PromEx.Plugins.PhoenixLiveView
    ]
  end
  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"}
    ]
  end
end

Endpoint ordering matters. PromEx’s own setup guidance puts the PromEx plug before Plug.Telemetry so metrics scrape requests do not pollute the request metrics.  ￼

# endpoint.ex
plug PromEx.Plug, prom_ex_module: MyApp.PromEx
plug Plug.RequestId
plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

That is the kind of footgun an opinionated generator could save people from.

⸻

4. Peep is worth knowing about, especially for high-volume metrics

Peep is an opinionated Telemetry.Metrics reporter supporting Prometheus and StatsD. It is actively updated, with Hex showing version 5.0.1 updated in April 2026. Its README says it differs from some older reporters by using histograms instead of sampling/on-demand aggregation and by batching StatsD datagrams.  ￼

The important community signal: the author introduced it after performance issues with existing Telemetry metrics reporters, and discussion mentions production use at very high request rates. Another forum reply said Supavisor saw a large latency improvement after replacing telemetry_metrics_prometheus_core.  ￼

For your likely SaaS stage:

Start with PromEx.
Remember Peep exists.
Reach for Peep if PromEx/Prometheus exposition becomes a bottleneck or you want a leaner reporter.

⸻

OpenTelemetry in Elixir: good, but know the boundary

The official OpenTelemetry Erlang/Elixir docs list signal status as:

Traces: Stable
Metrics: Development
Logs: Development

They also show packages published to Hex, including opentelemetry_api, opentelemetry, and opentelemetry_exporter, with Erlang 23+ and Elixir 1.13+ support.  ￼

That means your practical 2026 stance should be:

Use OpenTelemetry for traces.
Use PromEx/Peep/Telemetry.Metrics for metrics.
Use structured logs + an agent/collector for logs.

Do not try to force everything through OpenTelemetry in Elixir just because that is aesthetically pleasing.

A recent ElixirForum thread landed in basically this zone too: traces are handled through opentelemetry, opentelemetry_exporter, and instrumentation like opentelemetry_phoenix; metrics were commonly handled through PromEx; logs were usually shipped through stack tools.  ￼

⸻

Basic OpenTelemetry Phoenix setup

Official OpenTelemetry Phoenix docs show adding packages like:

{:opentelemetry_exporter, "~> 1.8"},
{:opentelemetry, "~> 1.5"},
{:opentelemetry_api, "~> 1.4"},
{:opentelemetry_phoenix, "~> 2"},
{:opentelemetry_cowboy, "~> 1"},
{:opentelemetry_ecto, "~> 1.2"}

and then setting up Cowboy, Phoenix, and Ecto instrumentation during application startup. The docs also note that the Phoenix endpoint needs Plug.Telemetry, and they show marking :opentelemetry as :temporary in releases so OpenTelemetry termination does not bring down the application.  ￼

Sketch:

def start(_type, _args) do
  :ok = :opentelemetry_cowboy.setup()
  :ok = OpentelemetryPhoenix.setup(adapter: :cowboy2)
  :ok = OpentelemetryEcto.setup([:my_app, :repo])
  children = [
    MyAppWeb.Telemetry,
    MyApp.Repo,
    MyAppWeb.Endpoint
  ]
  Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
end

For manual spans:

def create_checkout_session(user, plan) do
  require OpenTelemetry.Tracer, as: Tracer
  Tracer.with_span "billing.create_checkout_session" do
    Tracer.set_attribute("billing.plan", plan.slug)
    Tracer.set_attribute("billing.provider", "stripe")
    # Call Stripe, insert DB rows, enqueue jobs, etc.
    Billing.Stripe.create_checkout_session(user, plan)
  end
end

Official docs show this same general pattern: require OpenTelemetry.Tracer, use Tracer.with_span, and set span attributes.  ￼

⸻

Logs: the annoying middle child

For logs, I would not start with Promtail in 2026.

A useful September 2025 ElixirForum tutorial wired tracing via OpenTelemetry, metrics via PromEx/Prometheus, and logs via LoggerJSON + Promtail/Filebeat into OpenObserve. But the logging part is now dated for new deployments because Grafana’s Promtail docs say Promtail entered EOL on March 2, 2026, with future development moved to Grafana Alloy or other supported clients.  ￼

So the modern logging stance:

Phoenix Logger
  -> JSON logs to stdout
  -> Docker/systemd/Kubernetes log stream
  -> Grafana Alloy / Fluent Bit / Vector
  -> Loki / OpenObserve / SigNoz / Grafana Cloud

Use logs for rich context, not for primary metric math.

Good log metadata:

Logger.metadata(
  request_id: request_id,
  trace_id: trace_id,
  user_id: user.id,
  account_id: account.id
)

But be careful:

Good in logs/traces:
  request_id
  trace_id
  user_id
  account_id
  stripe_event_id
Bad as Prometheus labels:
  request_id
  trace_id
  user_id
  email
  order_id
  arbitrary path params

This is one of the most important cost-control rules in observability:

High-cardinality data belongs in logs, traces, and databases. Low-cardinality dimensions belong in metrics.

⸻

Collector layer: use one

You generally want a collector/agent between your app and your backend.

The OpenTelemetry Collector is vendor-agnostic infrastructure for receiving, processing, and exporting telemetry. Its docs describe it as a way to avoid running multiple agents/collectors and to support open-source observability formats sent to one or more backends. Its configuration model is built from receivers, processors, exporters, connectors, and service pipelines.  ￼

Grafana Alloy is also important now. Grafana describes Alloy as supporting native pipelines for Prometheus/OpenTelemetry and databases like Loki and Pyroscope, across metrics, logs, traces, and profiles. It also combines Prometheus-native collection with OpenTelemetry collection.  ￼

In Grafana-land, I would now think:

Grafana Alloy = the modern collector/agent
Promtail = legacy / do not start here
Grafana Agent = legacy / migrate to Alloy

Grafana’s migration docs say Grafana Agent Static/Flow/Operator reached EOL on November 1, 2025, and recommend migrating to Alloy.  ￼

⸻

Backend choices for a bootstrapped solo SaaS

Option A: Grafana Cloud free tier first

This is probably the best starting point.

Grafana Cloud’s free tier currently includes limited metrics, logs, traces, profiles, k6, frontend observability, visualization, and incident-response usage. The pricing page lists 10k active metric series, 50GB logs, and 50GB traces on the free tier, each with 14-day retention. It also lists 3 active visualization users and 3 active IRM users on the free tier.  ￼

For a solo founder, that is very attractive:

Cost: likely $0 initially
Ops burden: low
Retention: short but okay early
Dashboards: excellent
Alerts: good
Vendor lock-in: moderate but manageable

The sane first architecture:

flowchart LR
  Phoenix["Phoenix app"]
  Alloy["Grafana Alloy<br/>on host/sidecar"]
  GC["Grafana Cloud<br/>Prometheus + Loki + Tempo"]
  Grafana["Grafana dashboards/alerts"]
  Phoenix -->|/metrics scrape| Alloy
  Phoenix -->|OTLP traces| Alloy
  Phoenix -->|JSON logs| Alloy
  Alloy --> GC
  GC --> Grafana

This keeps your app open-standard-ish while avoiding backend ops.

⸻

Option B: self-host Grafana stack on Hetzner

This is the “I am comfortable with infrastructure and want cheap control” option.

Grafana
Prometheus
Loki
Tempo
Grafana Alloy
Alertmanager
node_exporter
maybe cAdvisor
maybe Postgres datasource

A minimal self-hosted stack:

flowchart LR
  App["Phoenix app"]
  Alloy["Alloy"]
  Prom["Prometheus"]
  Loki["Loki"]
  Tempo["Tempo"]
  Grafana["Grafana"]
  Alert["Alertmanager"]
  App -->|metrics| Prom
  App -->|logs| Alloy --> Loki
  App -->|traces| Alloy --> Tempo
  Prom --> Grafana
  Loki --> Grafana
  Tempo --> Grafana
  Prom --> Alert

Good when:

you want infrastructure control
you want to learn/sell the recipe
you are comfortable maintaining disks/backups/upgrades
you are okay with fewer managed guardrails

Bad when:

you need to stay focused on product
you will ignore upgrades
you will forget retention limits
you will page yourself for your observability stack

For most solo founders, self-hosting observability too early is a trap. For you specifically, it may be reasonable because DevOps/SRE is part of your interest and OSS strategy — but only if the stack becomes a productized recipe, not a private yak shave.

⸻

Option C: OpenObserve

OpenObserve is interesting because it positions itself as an open-source observability platform for logs, metrics, traces, dashboards, and more, with OpenTelemetry compatibility and a cost/storage-efficiency pitch. The ElixirForum thread you pointed toward also had someone mention OpenObserve and SigNoz as self-hostable options, with OpenObserve having been used locally by that poster.  ￼

Why you might like it:

one UI
OTel-compatible
potentially simpler than running Grafana + Prometheus + Loki + Tempo
interesting for a cheap self-host story

Why I would be cautious:

smaller ecosystem than Grafana
less universal muscle memory
you need to verify alerting/SLO/dashboard depth
you need to test real retention/storage behavior yourself

I would evaluate it, not bet the company immediately.

⸻

Option D: SigNoz

SigNoz is an open-source, OpenTelemetry-native observability platform positioned as a Datadog/New Relic alternative. Its self-host docs list install paths including Docker Standalone, Docker Swarm, Kubernetes Helm, and Linux binary installation.  ￼

Why you might like it:

closer to all-in-one Datadog-ish experience
OTel-native
good conceptual fit for traces/metrics/logs in one place

Why I would be cautious:

self-hosting can be heavier than Grafana Cloud free
ClickHouse-backed systems need operational care
you may be trading Datadog cost for backend maintenance

Good evaluation candidate. Not my first default for your earliest production phase.

⸻

Option E: Sentry or GlitchTip for errors

Even if you build the rest with Grafana/Prometheus/Loki/Tempo, error tracking is its own category.

The official Sentry Elixir client is current, with Hex showing sentry version 13.0.1 updated May 2026. Sentry’s Elixir docs describe support for manual capture, logger integration, Plug/Phoenix, Oban, Quantum, tracing via OpenTelemetry packages, and logs.  ￼

Sentry self-hosting is possible, but their docs explicitly say self-hosted users run all of Sentry on their own server, do not get dedicated support/uptime guarantees, and need to keep up with monthly CalVer releases and migrations.  ￼

GlitchTip is worth a look if you want cheaper/self-hosted Sentry-compatible error tracking. It describes itself as open-source error tracking compatible with Sentry client SDKs, with error tracking, performance, uptime, logs, hosted and self-hosted options, and a free hosted tier.  ￼

My practical recommendation:

Use Sentry SDK shape.
Start with Sentry free/cheap or GlitchTip.
Do not self-host full Sentry unless you really want that maintenance burden.

⸻

Can this give you Datadog-like SRE dashboards?

Yes.

Not identical polish out of the box, but functionally yes.

A good Grafana home dashboard for your SaaS should look like this:

Top row
  uptime
  request rate
  5xx error rate
  p95 latency
  current deploy version
API health
  requests by route
  error rate by route
  p95/p99 latency by route
  slowest routes
  top 5 exception classes
Database
  query duration p95
  queue time p95
  connection pool saturation
  slow queries
  Ecto repo errors
Jobs
  Oban queue depth
  job success/error rate
  job latency
  retries
  dead/discarded jobs
External dependencies
  Stripe latency/error rate
  email provider latency/error rate
  object storage latency/error rate
Business
  signups
  activations
  checkout starts
  checkout successes
  MRR-ish trend
  churn/cancel events
  webhook failures

PromEx gets you a lot of the app/runtime side. Custom Telemetry gets you the domain side.

⸻

Example: RED metrics in PromQL

Metric names vary by reporter/plugin, so treat these as shapes, not copy-paste gospel.

Request rate:

sum(rate(phoenix_endpoint_stop_duration_count[5m]))

5xx error ratio:

sum(rate(phoenix_endpoint_stop_duration_count{status=~"5.."}[5m]))
/
sum(rate(phoenix_endpoint_stop_duration_count[5m]))

p95 latency:

histogram_quantile(
  0.95,
  sum by (le) (
    rate(phoenix_endpoint_stop_duration_bucket[5m])
  )
)

Per-route p95 latency:

histogram_quantile(
  0.95,
  sum by (route, le) (
    rate(phoenix_endpoint_stop_duration_bucket[5m])
  )
)

The SRE move is to turn those into SLIs:

availability_sli = good_requests / total_requests
latency_sli      = fast_requests / total_requests

Then SLOs:

API availability: 99.9% over 30 days
Checkout success endpoint: 99.5% over 30 days
Webhook processing: 99.0% within 5 minutes

Google’s SRE workbook shows this exact style: define good/total events, use Prometheus recording rules, then alert on error-budget burn rates rather than raw error spikes.  ￼

⸻

SLO alerting: the sane version

Naive alert:

5xx rate > 1%

Problem:

fires during tiny traffic
fires during harmless blips
does not map to user harm
does not map to your reliability promise

Better alert:

We are burning the 30-day error budget too quickly.

Sketch:

groups:
  - name: api-slo
    rules:
      - record: api:requests:rate5m
        expr: sum(rate(http_requests_total[5m]))
      - record: api:errors:rate5m
        expr: sum(rate(http_requests_total{status=~"5.."}[5m]))
      - record: api:error_ratio:rate5m
        expr: api:errors:rate5m / api:requests:rate5m
      - alert: ApiHighErrorBudgetBurn
        expr: |
          api:error_ratio:rate5m > 14.4 * 0.001
        for: 5m
        labels:
          severity: page
        annotations:
          summary: "API is burning error budget too quickly"

For production, you would use multi-window, multi-burn-rate alerts. Google’s SRE alerting guidance explains burn rate as how quickly the service consumes its error budget, and gives examples of multi-window alerting for different urgency levels.  ￼

Solo-founder translation:

Page me only when user harm is real.
Ticket me when something is degrading.
Dashboard everything else.

⸻

Business KPIs: yes, but split “metrics” from “analytics”

Elixir Telemetry is great for business events.

Example:

defmodule MyApp.Billing.Events do
  def checkout_succeeded(invoice, plan) do
    :telemetry.execute(
      [:my_app, :billing, :checkout, :succeeded],
      %{
        count: 1,
        amount_cents: invoice.amount_due
      },
      %{
        plan: plan.slug,
        currency: invoice.currency
      }
    )
  end
end

Metrics definitions:

def metrics do
  [
    counter(
      "my_app.billing.checkout.succeeded.count",
      tags: [:plan, :currency]
    ),
    sum(
      "my_app.billing.checkout.succeeded.amount_cents",
      tags: [:plan, :currency]
    )
  ]
end

This is good for Grafana panels like:

checkouts/min
checkout success rate
revenue-ish cents/min
webhook failures by provider
trial starts by plan

But for exact business reporting, also write durable domain records:

invoices
subscriptions
subscription_events
account_events
ledger_entries

Why?

Prometheus is not your accounting system. It is a time-series monitoring system.

Good Prometheus labels:

plan = pro | team | enterprise
currency = usd | eur
environment = prod | staging
provider = stripe | paddle

Bad Prometheus labels:

user_id
email
customer_id
invoice_id
subscription_id
request_id
trace_id

So the pattern is:

flowchart LR
  Event["Business event"]
  Telemetry["Telemetry metric<br/>low cardinality"]
  Ledger["Postgres ledger<br/>exact facts"]
  Grafana["Grafana"]
  Warehouse["Optional warehouse"]
  Event --> Telemetry --> Grafana
  Event --> Ledger --> Grafana
  Ledger --> Warehouse

Use metrics for operational business pulse.

Use Postgres/warehouse for exact truth.

⸻

The cheapest sane stack I would run first

For your situation, I would start here:

App:
  Phoenix Telemetry
  PromEx
  OpenTelemetry Phoenix/Cowboy/Ecto
  JSON logs
  Sentry SDK or GlitchTip-compatible error tracking
Agent:
  Grafana Alloy
Backend:
  Grafana Cloud free tier initially
Dashboards:
  PromEx dashboards
  custom RED dashboard
  custom business pulse dashboard
Alerts:
  uptime
  5xx burn
  checkout/webhook failures
  Oban queue stuck
  DB pool saturation
  disk/memory

That gives you:

Datadog-like dashboards: yes
SLOs: yes
logs/traces/metrics correlation: yes
low cost: likely yes
migration path to self-hosting: yes
OSS extraction opportunity: yes

You can later swap:

Grafana Cloud -> self-host Grafana stack
Grafana Cloud -> OpenObserve
Grafana Cloud -> SigNoz

without rewriting most app instrumentation, assuming you keep OTLP, Prometheus, and structured logs.

⸻

A realistic implementation path

Week 1: make the app observable locally

Add:

{:prom_ex, "~> 1.11"},
{:opentelemetry, "~> 1.7"},
{:opentelemetry_api, "~> 1.5"},
{:opentelemetry_exporter, "~> 1.10"},
{:opentelemetry_phoenix, "~> 2.0"},
{:opentelemetry_cowboy, "~> 1.0"},
{:opentelemetry_ecto, "~> 1.2"},
{:opentelemetry_liveview, "~> 1.0"},
{:opentelemetry_logger_metadata, "~> 0.3"}

The exact versions should be checked against Hex when installing, but the current Hex pages show recent releases for the core OTel packages and Phoenix instrumentation, while the official OTel docs show the Phoenix setup shape.  ￼

Add:

# application.ex
:ok = :opentelemetry_cowboy.setup()
:ok = OpentelemetryPhoenix.setup(adapter: :cowboy2)
:ok = OpentelemetryEcto.setup([:my_app, :repo])
:ok = OpentelemetryLiveView.setup()
:ok = OpentelemetryLoggerMetadata.setup()

Then add PromEx:

children = [
  MyApp.PromEx,
  MyAppWeb.Telemetry,
  MyApp.Repo,
  MyAppWeb.Endpoint
]

Add a /metrics endpoint through PromEx.

Then verify:

curl localhost:4000/metrics

You should see Phoenix/BEAM/Ecto metrics.

⸻

Week 2: connect Grafana Cloud or local Grafana

For the simplest path:

Grafana Alloy on host
  scrapes /metrics
  tails logs
  receives OTLP traces
  sends to Grafana Cloud

For local development:

docker compose up grafana prometheus loki tempo alloy

This is where a generated recipe would be valuable.

Most developers do not want to hand-author:

prometheus.yml
alloy config
tempo config
loki config
grafana datasource provisioning
dashboard provisioning
alert rules
docker-compose.yml

That is your likely OSS gap.

⸻

Week 3: build your first real dashboards

Start with five dashboards.

1. SaaS health

request rate
error rate
p95 latency
deploy version
uptime

2. Phoenix internals

BEAM memory
process count
reductions
run queue
scheduler utilization-ish signals

3. Database

query duration
queue time
connection pool pressure
errors
slow queries

4. Jobs

queue depth
job duration
job errors
retries
discarded jobs

5. Business pulse

signups
checkout started
checkout succeeded
checkout failed
new subscriptions
cancellations
webhook lag/failures

⸻

Week 4: add SLOs and alerts

Start with only a few alerts:

API availability burn
API latency burn
checkout failure spike
Stripe webhook failures
Oban queue stuck
DB pool saturation
host disk almost full

Avoid:

alert on every 500
alert on every exception
alert on p99 twitchiness
alert on CPU alone
alert on logs containing "error"

As a solo founder, alerts should be rare and meaningful.

⸻

Sidecars, agents, or direct export?

There are three patterns.

Pattern 1: direct from app to backend

flowchart LR
  App["Phoenix app"] --> Backend["Grafana Cloud / SigNoz / OpenObserve"]

Simple, but less flexible.

Use only for tiny setups or temporary experiments.

Pattern 2: app → collector/agent → backend

flowchart LR
  App["Phoenix app"] --> Agent["Alloy / OTel Collector"]
  Agent --> Backend["Grafana Cloud / Loki / Tempo / OpenObserve"]

This is the sweet spot.

Benefits:

central config
sampling
redaction
batching
retry
backend swapping
multiple exports

Pattern 3: sidecar per service

flowchart LR
  App1["Phoenix container"] --> Sidecar1["Alloy sidecar"]
  App2["Worker container"] --> Sidecar2["Alloy sidecar"]
  Sidecar1 --> Backend
  Sidecar2 --> Backend

Useful in ECS/Kubernetes.

For a small VPS, I would usually run one Alloy per host instead.

⸻

The big footguns

Footgun 1: using user IDs as metric labels

This will explode your cardinality and cost.

Bad:

counter("checkout.succeeded.count", tags: [:user_id])

Good:

counter("checkout.succeeded.count", tags: [:plan, :currency])

Put user_id in logs/traces, not Prometheus labels.

⸻

Footgun 2: treating logs as metrics

Bad alert:

page when log message contains "error"

Better:

page when 5xx error-budget burn is high
page when checkout success ratio drops
page when webhook processing lag exceeds threshold

Logs explain. Metrics alert.

⸻

Footgun 3: tracing everything at 100% forever

Early on, 100% trace sampling is fine.

Later, sample.

For example:

100% traces for errors
100% traces for checkout/webhooks/admin critical flows
5-10% traces for normal traffic
lower if traffic grows

⸻

Footgun 4: self-hosting too early

Self-hosting Grafana/Loki/Tempo/Prometheus can be cheap in dollars and expensive in attention.

For you, I would phrase it like this:

Use Grafana Cloud first unless self-hosting itself becomes part of your product/OSS learning loop.

⸻

Footgun 5: believing OpenTelemetry means “one library does everything”

In Elixir/Erlang, OTel tracing is the strong part. Metrics/logs are less finished compared with traces, and official docs still mark Metrics and Logs as Development while Traces are Stable.  ￼

So do not overfit to OTel purity.

A pragmatic stack is better:

Telemetry/PromEx for metrics
OTel for traces
JSON logs + Alloy for logs
Postgres/warehouse for exact business facts
Grafana for visualization

⸻

Should you build an OSS library?

Do not build this

A metrics backend
A tracing backend
A log database
A Grafana replacement
A Datadog clone

That is infrastructure quicksand.

Maybe build this

An opinionated Phoenix observability starter kit.

Something like:

mix sightline.install --stack grafana_cloud
mix sightline.install --stack self_hosted
mix sightline.install --stack openobserve
mix sightline.install --stack signoz

Generated files:

lib/my_app/observability.ex
lib/my_app/prom_ex.ex
lib/my_app/telemetry/business_metrics.ex
config/runtime.exs additions
config/logger.exs additions
docker-compose.observability.yml
deploy/alloy/config.alloy
deploy/prometheus/prometheus.yml
deploy/grafana/datasources.yml
deploy/grafana/dashboards/*.json
deploy/prometheus/rules/slo.yml

Design principles:

host-owned code
idempotent generators
small surface area
works with Phoenix releases
works with Docker Compose first
optional Terraform modules later
no hidden magic
prompts users about cardinality
ships tests/lints for metric labels

This maps extremely well to your apparent sigra style: generated, host-owned, Phoenix-native code rather than a black-box dependency.  ￼

⸻

What the OSS library could uniquely solve

1. Correct package setup

Generate:

# mix.exs
{:prom_ex, "~> 1.11"},
{:opentelemetry, "~> 1.7"},
{:opentelemetry_api, "~> 1.5"},
{:opentelemetry_exporter, "~> 1.10"},
{:opentelemetry_phoenix, "~> 2.0"},
{:opentelemetry_cowboy, "~> 1.0"},
{:opentelemetry_ecto, "~> 1.2"},
{:opentelemetry_liveview, "~> 1.0"},
{:opentelemetry_logger_metadata, "~> 0.3"}

And the correct supervision/startup order.

2. Correct Endpoint ordering

Generate:

plug PromEx.Plug, prom_ex_module: MyApp.PromEx
plug Plug.RequestId
plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

PromEx’s own docs call out this ordering concern.  ￼

3. Backend recipes

Generate one of:

Grafana Cloud + Alloy
Self-host Grafana stack
OpenObserve
SigNoz

The September 2025 ElixirForum tutorial you linked is a great sign that people want recipes like this. It assembled OpenTelemetry, PromEx, Prometheus, logger JSON, Promtail/Filebeat, and OpenObserve — but parts of that stack already need 2026 updates, especially replacing Promtail.  ￼

That is exactly the kind of living recipe library people need.

4. Business metric conventions

Generate:

defmodule MyApp.BusinessTelemetry do
  def signup_succeeded(account, user) do
    :telemetry.execute(
      [:my_app, :account, :signup, :succeeded],
      %{count: 1},
      %{plan: account.plan}
    )
  end
  def checkout_succeeded(invoice) do
    :telemetry.execute(
      [:my_app, :billing, :checkout, :succeeded],
      %{count: 1, amount_cents: invoice.amount_due},
      %{plan: invoice.plan, currency: invoice.currency}
    )
  end
end

And include docs that say:

Do not tag by user_id.
Do not tag by email.
Do not tag by request_id.
Do not tag by invoice_id.

5. SLO templates

Generate rules like:

API availability SLO
API latency SLO
checkout success SLO
webhook processing SLO
background job latency SLO

With comments explaining how to tune them.

6. A “doctor” command

mix sightline.doctor

Checks:

/metrics route responds
PromEx plug is before Plug.Telemetry
OTel exporter env vars exist
Logger is JSON in prod
dangerous metric labels detected
Grafana datasource provisioning exists
Prometheus can scrape app
Alloy config includes logs/traces/metrics

This would be extremely useful.

⸻

My recommended decision tree

flowchart TD
  A["Do you need production observability now?"] -->|Yes| B["Use Grafana Cloud free + Alloy"]
  A -->|No, exploring| C["Local Docker Compose Grafana stack"]
  B --> D["Add PromEx metrics"]
  B --> E["Add OTel traces"]
  B --> F["Add JSON logs"]
  B --> G["Add Sentry/GlitchTip errors"]
  D --> H["Build RED dashboard"]
  E --> H
  F --> H
  G --> H
  H --> I["Add SLOs + burn alerts"]
  I --> J["Extract repeatable recipe"]
  J --> K["Maybe publish OSS generator"]

⸻

The actual answer to your core question

Is the ecosystem mature?

Yes, mostly.

For a serious Phoenix SaaS, you can get excellent observability today using existing OSS and cheap/free hosted services.

Is it plug-and-play?

Not quite.

The pieces are mature-ish, but the integration path is fragmented. Recent ElixirForum activity shows smart users still asking how to assemble OpenTelemetry, PromEx, Prometheus, logs, and backends into a coherent stack.  ￼

Should you build your own libraries?

Yes, but only glue/generators/recipes.

Do not build a new observability backend.

Do build the thing that makes this dead simple for Phoenix apps:

install
instrument
scrape
ship
dashboard
alert
SLO
business KPIs

What would I do in your shoes?

I would:

1. Instrument your SaaS with PromEx + OTel + JSON logs.
2. Use Grafana Cloud free tier first.
3. Add Sentry free/cheap or GlitchTip for error tracking.
4. Create RED + business dashboards.
5. Add 3–5 SLO alerts.
6. Keep notes on every annoying setup step.
7. After 2–4 weeks, extract the repeatable parts into a generated-code Phoenix observability kit.

That gives you immediate value, avoids infrastructure cosplay, and lets your OSS work emerge from real pain.

⸻

A concrete “starter stack” I would bless

Phoenix app
  ├─ Phoenix Telemetry
  ├─ PromEx
  ├─ OpenTelemetry Phoenix/Cowboy/Ecto/LiveView
  ├─ LoggerJSON or structured JSON logger
  ├─ Sentry SDK or GlitchTip-compatible setup
  └─ custom business Telemetry events
Host / container
  └─ Grafana Alloy
Backend, phase 1
  └─ Grafana Cloud free tier
Backend, phase 2 if needed
  ├─ self-host Grafana + Prometheus + Loki + Tempo
  ├─ or OpenObserve
  └─ or SigNoz

This is cheap, modern, reasonably portable, and SRE-compatible.

The one-line summary:

For your SaaS: plug in the observability primitives; build the Phoenix-native paved road.