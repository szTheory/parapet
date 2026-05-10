OKAY SO THIS IS SOME DEEP RESAERCH I DID ON ELIXIR LIBS BUT KEEP IN MIND THAT WE ARE NOT CALLING IT RELIABILITYKIT WE ARE GOING TO CALL IT PARAPET!!!!!!! PARAPET!!!!!


# Research brief: an opinionated Phoenix/Ecto/Plug SRE + observability platform library

Working name in this brief: **ReliabilityKit**.

## 0. Product thesis

Build a **reliability substrate**, not another observability backend.

The Elixir ecosystem already has strong raw ingredients: `:telemetry`, `Telemetry.Metrics`, Phoenix/Ecto/Plug/Oban telemetry events, LiveDashboard, PromEx, OpenTelemetry, LoggerJSON, Sentry/AppSignal integrations, Prometheus/Grafana, and job/email/webhook instrumentation points. The gap is that a Phoenix SaaS developer still has to assemble all of this into a coherent SRE control loop: user journeys, SLIs/SLOs, burn-rate alerts, dashboards, wide events, incident notes, runbooks, deploy correlation, email deliverability, cardinality safety, and AI-readable operational context. Phoenix’s telemetry docs make this clear: telemetry events are emitted by the framework and `Telemetry.Metrics` defines metrics, but reporters do the aggregation and storage, so the developer still has to decide what to define, where to send it, and how to use it.  [oai_citation:0‡hexdocs.pm](https://hexdocs.pm/phoenix/telemetry.html)

The opportunity is an opinionated Phoenix-first library that generates the boring correct pieces:

- safe default instrumentation;
- low-cardinality metrics;
- context-rich wide events;
- SLO and error-budget definitions;
- Prometheus alert rules;
- Grafana dashboards;
- LiveDashboard/admin UI pages;
- runbook and postmortem templates;
- deploy/change markers;
- email deliverability monitoring;
- `doctor` checks for common footguns;
- AI/MCP read-only investigation context with approval-gated actions.

The north star:

> A Phoenix SaaS can briefly hurt users, but not silently, not confusingly, and not without leaving evidence, a mitigation path, and a learning loop.

---

## 1. Personas and jobs-to-be-done

### 1.1 Solo SaaS founder

**Job:** “Tell me when users are actually hurt, help me mitigate calmly, and do not wake me for noise.”

Needs:

- less than 10 paging alerts;
- SLOs for checkout, login, email, webhooks, API, jobs;
- deploy correlation;
- one health screen;
- daily reliability digest;
- clear runbooks;
- strong defaults;
- low ops burden.

Success looks like:

- checkout breaks → alert says checkout completion SLO is burning;
- dashboard shows `checkout_started` normal but `checkout_completed` collapsed;
- wide events show feature flag/deploy/provider/error class;
- runbook recommends rollback or flag disable;
- AI copilot summarizes evidence without taking unsafe actions.

### 1.2 Phoenix app developer

**Job:** “Give me idiomatic Phoenix/Ecto/Oban instrumentation without turning my codebase into observability soup.”

Needs:

- minimal install;
- DSL that feels like Phoenix router/context style;
- no vendor lock-in;
- composable modules;
- compile-time validation where possible;
- generated code that the host app owns;
- clean docs and examples.

### 1.3 SRE/devops consultant

**Job:** “Install a paved-road SRE baseline in a client’s Phoenix app quickly, then customize it.”

Needs:

- SLO templates;
- dashboard provisioning;
- alert rule generation;
- incident/runbook templates;
- environment-aware config;
- support for Prometheus/Grafana/OpenTelemetry;
- policy checks for cardinality, PII, exposed endpoints, missing auth.

### 1.4 AI coding agent / AI ops copilot

**Job:** “Give me structured, source-cited operational context so I can investigate without hallucinating.”

Needs:

- exact deploy SHA;
- recent changes;
- routes/components/schemas involved;
- metrics/logs/traces with stable names;
- runbook Markdown;
- SLO definitions;
- allowed and blocked actions;
- evidence bundles;
- explicit distinction between fact, hypothesis, and recommendation.

MCP-style integrations are becoming mainstream in observability: Grafana’s MCP server exposes tools for querying metrics/logs, dashboards, alert rules, incidents, and related resources, while Datadog describes its MCP server as a bridge between observability data and AI assistants such as Cursor, Codex, and Claude Code.  [oai_citation:1‡Grafana Labs](https://grafana.com/docs/grafana/latest/developer-resources/mcp/)

### 1.5 Support/customer success

**Job:** “When customers complain, tell me whether the app, email, payment, webhook, or provider path failed.”

Needs:

- account/user-scoped investigation without leaking PII into metrics;
- incident timeline;
- affected-customer estimates;
- email/webhook delivery status;
- customer-safe status updates.

### 1.6 Security/compliance maintainer

**Job:** “Make sure observability does not become a data leak or production-control backdoor.”

Needs:

- redaction policy;
- PII classification;
- webhook authenticity checks;
- signed/replayed event protection;
- MCP tool permissions;
- audit log of AI and human operational actions;
- secure LiveDashboard/admin access.

Phoenix supports parameter filtering in logs and defaults to filtering values whose keys contain `password` or `secret`, but production-grade reliability tooling should treat that as a baseline, not a complete privacy policy.  [oai_citation:2‡hexdocs.pm](https://hexdocs.pm/phoenix/Phoenix.Logger.html)

---

## 2. Existing Elixir ecosystem: what to compose, what to avoid duplicating, where the gap remains

### 2.1 Core telemetry stack

| Piece | What it already does well | Tradeoffs / gaps | Build implication |
|---|---|---|---|
| `:telemetry` | Common event mechanism across Phoenix, Ecto, Oban, Plug, Absinthe, Broadway, Tesla, and more. Phoenix docs explicitly list many ecosystem libraries using Telemetry.  [oai_citation:3‡hexdocs.pm](https://hexdocs.pm/phoenix/telemetry.html) | It is an event substrate, not an SRE product. Developers still need event naming, metric definitions, reporters, SLOs, dashboards, alerts, and docs. | Build on it. Do not replace it. |
| `Telemetry.Metrics` | Defines metric specs such as counter, sum, last value, summary, and distribution; provides a common interface for aggregating Telemetry events.  [oai_citation:4‡hexdocs.pm](https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html) | Does not aggregate by itself; reporters do that. Phoenix docs explicitly note that metric definitions are not responsible for aggregation.  [oai_citation:5‡hexdocs.pm](https://hexdocs.pm/phoenix/telemetry.html) | Library should generate metric definitions plus reporter-specific adapters. |
| Phoenix Telemetry | Emits rich endpoint/router events and exposes route metadata such as route, plug, path params, and pipeline information.  [oai_citation:6‡hexdocs.pm](https://hexdocs.pm/phoenix/telemetry.html) | User still has to classify routes, avoid high-cardinality tags, and map routes to journeys/SLOs. | Add route classification and journey DSL. |
| Ecto Telemetry | Repo events include query time, queue time, idle time, decode time, and total time, which are perfect for DB latency/pool saturation.  [oai_citation:7‡hexdocs.pm](https://hexdocs.pm/ecto/Ecto.Repo.html) | Raw query telemetry can become noisy; labels must avoid query text/user/account IDs. Pool settings like `:pool_count` have subtle behavior and should be surfaced carefully.  [oai_citation:8‡hexdocs.pm](https://hexdocs.pm/ecto/Ecto.Repo.html) | Provide safe DB metrics, pool saturation panels, and warnings. |
| Oban Telemetry | Emits job `start`, `stop`, and `exception` events with job metadata and supports structured telemetry logging.  [oai_citation:9‡hexdocs.pm](https://hexdocs.pm/oban/Oban.Telemetry.html) | Retry semantics make “one job failed” a bad page. Need queue latency, critical job SLOs, retries/discards, and stuck-queue detection. | Provide job SLO templates, queue health, and retry-aware alerting. |
| Plug.Telemetry | Instruments pipelines with start/stop events and duration.  [oai_citation:10‡hexdocs.pm](https://hexdocs.pm/plug/Plug.Telemetry.html) | Its docs warn that the stop event is not guaranteed in all error cases and cannot be used as a full Telemetry span; placement affects what duration includes.  [oai_citation:11‡hexdocs.pm](https://hexdocs.pm/plug/Plug.Telemetry.html) | Do not model Plug telemetry as a complete request trace boundary. Use it carefully and enrich Phoenix/router events. |

### 2.2 Existing observability libraries and tools

| Tool/library | Pros | Cons / footguns | Lesson for ReliabilityKit |
|---|---|---|---|
| Phoenix LiveDashboard | Excellent real-time operational/debug UI for Phoenix apps: home, OS data, metrics, request logging, processes, ports, sockets, ETS, Ecto stats, and cross-node visibility.  [oai_citation:12‡GitHub](https://github.com/phoenixframework/phoenix_live_dashboard) | It is not a durable metrics backend, alerting system, or SLO engine. In production it must be protected by proper authorization or basic auth.  [oai_citation:13‡GitHub](https://github.com/phoenixframework/phoenix_live_dashboard) | Integrate with it. Add SRE pages: SLOs, error budgets, incidents, runbooks, deploys, email, jobs, doctor. |
| PromEx | Strongest existing “batteries included” Prometheus/Grafana layer for Elixir. It offers plugins, dashboard callbacks, PromEx.Plug, Phoenix/Ecto/Oban/BEAM-style plugin coverage, and Grafana dashboard automation.  [oai_citation:14‡hexdocs.pm](https://hexdocs.pm/prom_ex/PromEx.html) | Primarily metrics/dashboards. Does not fully solve journey modeling, SLO policy, incidents, runbooks, wide events, email deliverability, AI context, or alert-quality review. Community discussion also surfaced metrics endpoint auth concerns.  [oai_citation:15‡Elixir Programming Language Forum](https://elixirforum.com/t/promex-prometheus-metrics-and-grafana-dashboards-for-all-of-your-favorite-elixir-libraries/37642) | Reuse or interoperate. Do not build a shallow PromEx clone. Build SRE workflow on top. |
| `telemetry_metrics_prometheus` | Simple reporter that exposes Prometheus metrics from `Telemetry.Metrics`; defaults to port `9568` and `/metrics`.  [oai_citation:16‡hexdocs.pm](https://hexdocs.pm/telemetry_metrics_prometheus/overview.html) | Docs note HTTPS is not supported, histograms aggregate at scrape time, and scrape duration can grow with many distributions or high cardinality.  [oai_citation:17‡hexdocs.pm](https://hexdocs.pm/telemetry_metrics_prometheus/overview.html) | Offer adapter support, endpoint protection guidance, cardinality linting, and scrape-cost warnings. |
| Peep | Performance-oriented metrics reporter; community reports emphasize lower overhead and production use at high request volume. The author notes bounded storage depends on bounded metric labels.  [oai_citation:18‡Elixir Programming Language Forum](https://elixirforum.com/t/peep-efficient-telemetrymetrics-reporter-supporting-prometheus-and-statsd/55901) | Reporter choice and storage design are subtle. Peep discussion included route/plug placement footguns and memory/lock-contention tradeoffs.  [oai_citation:19‡Elixir Programming Language Forum](https://elixirforum.com/t/peep-efficient-telemetrymetrics-reporter-supporting-prometheus-and-statsd/55901) | Make reporter pluggable. Add tests/docs for endpoint placement. Validate bounded labels. |
| LoggerJSON | Gives JSON structured log formatters, including basic formatter and formats aimed at Google Cloud, Datadog, and Elastic/ECS.  [oai_citation:20‡hexdocs.pm](https://hexdocs.pm/logger_json/LoggerJSON.html) | Structured logs are not automatically good wide events. You still need event shape, redaction, sampling, and consistent fields. | Integrate as a sink. Provide a wide-event schema and redaction policy. |
| OpenTelemetry Erlang/Elixir | Provides tracing/exporter path and Phoenix setup guidance; API calls are no-ops without the SDK, exporter, and configuration.  [oai_citation:21‡OpenTelemetry](https://opentelemetry.io/docs/languages/erlang/getting-started/) | OTel is a standard and transport layer, not a product model. HTTP semantic conventions have stabilization/migration concerns and opt-in compatibility modes.  [oai_citation:22‡OpenTelemetry](https://opentelemetry.io/docs/specs/semconv/http/) | Offer OTel mapping with version-aware semantic conventions and compatibility config. |
| Sentry/AppSignal-style integrations | Great for exception reporting/APM and common Phoenix/Plug/Oban integrations. Sentry search results show Plug/Phoenix, Oban, Telemetry, tracing, and test helper support; AppSignal search results show automatic Phoenix request/error/performance monitoring.  [oai_citation:23‡Sentry Docs](https://docs.sentry.io/platforms/elixir/integrations/plug_and_phoenix/?utm_source=chatgpt.com) | Vendor APM/error tools do not replace local SLO definitions, runbooks, alert quality, email deliverability, or OSS dashboard/rule generation. | Integrate. Do not force users to abandon their error tracker. |

### 2.3 Community pain signals

Elixir community discussions show a recurring theme: the primitives exist, but production-grade assembly is still more work than expected. One forum thread says a developer spent more time than expected getting production logging/error reporting working, that Phoenix/Oban often expect Telemetry hooks, and that there is room for opinionated production-grade logging “in minutes.”  [oai_citation:24‡Elixir Programming Language Forum](https://elixirforum.com/t/simplify-adding-production-grade-logging-to-your-standard-phoenix-webapp/62802)

Another forum discussion about OpenTelemetry and Telemetry advised starting with Telemetry and LiveDashboard before layering OpenTelemetry, and noted that a proper OpenTelemetry knowledge base for Elixir was overdue.  [oai_citation:25‡Elixir Programming Language Forum](https://elixirforum.com/t/how-are-you-using-open-telemetry-in-your-elixir-applications/70667)

**Product interpretation:** the ecosystem does not need yet another raw metrics library. It needs a composed, opinionated, Phoenix-native “reliability layer” that turns primitives into operational outcomes.

---

## 3. Cross-ecosystem lessons to steal

### 3.1 Page symptoms, not causes

Google SRE guidance emphasizes that paging should be based on symptoms and real/imminent user problems, while causes are useful for debugging; it also warns that noisy alerts create overload and that email alerts have limited value when they are noisy.  [oai_citation:26‡Google SRE](https://sre.google/sre-book/monitoring-distributed-systems/)

Prometheus alerting best practices say the same thing in operational form: keep alerts simple, alert on symptoms, include slack for blips, and page only on user-visible errors or issues that need action.  [oai_citation:27‡prometheus.io](https://prometheus.io/docs/practices/alerting/)

**Library implication:**

ReliabilityKit should ship a small default page set:

- API availability fast burn;
- API “fast enough” latency fast burn;
- login success collapse;
- checkout success collapse;
- payment webhook processing stopped/delayed;
- transactional email acceptance failure;
- DB unavailable/disk nearly full;
- critical job queue stuck;
- deploy health failed;
- security-critical anomaly.

Everything else should default to dashboard, digest, or ticket.

### 3.2 Generate SLO rules instead of hand-writing PromQL

Google’s SLO alerting workbook explains burn rate as the speed at which an error budget is consumed and gives multi-window, multi-burn-rate parameters such as 1h/5m and 6h/30m paging windows.  [oai_citation:28‡Google SRE](https://sre.google/workbook/alerting-on-slos/)

Sloth’s positioning is exactly the lesson: creating Prometheus SLI/SLO rules manually is hard, error-prone, and toil-heavy, so it generates recording and alerting rules from a simpler spec.  [oai_citation:29‡sloth.dev](https://sloth.dev/?utm_source=chatgpt.com) Pyrra follows a similar pattern: define objectives in YAML, generate recording rules, multi-window burn-rate alerts, and dashboards, then show SLOs, error budgets, and burn rates in a UI.  [oai_citation:30‡GitHub](https://github.com/pyrra-dev/pyrra?utm_source=chatgpt.com)

**Library implication:**

The SLO API should compile to:

- Prometheus recording rules;
- Prometheus alert rules;
- Grafana dashboard panels;
- LiveDashboard/admin UI;
- Markdown SLO docs;
- AI-readable context.

A developer should not be forced to write burn-rate PromQL by hand.

### 3.3 Cardinality safety must be designed in

Prometheus docs warn that every unique label set is a separate time series and advise against high-cardinality labels such as user IDs, email addresses, and unbounded values.  [oai_citation:31‡prometheus.io](https://prometheus.io/docs/practices/naming/)

Honeycomb’s guidance points in the complementary direction: high-cardinality fields such as user ID, cart ID, order ID, and request ID are valuable for investigation in events/traces, where they can narrow down what went wrong.  [oai_citation:32‡docs.honeycomb.io](https://docs.honeycomb.io/get-started/basics/observability/concepts/high-cardinality)

**Library implication:**

ReliabilityKit must teach and enforce the split:

```text
Metrics:
  low-cardinality, aggregate, alertable
  route, method, status_class, provider, operation, queue, worker, environment

Wide events / traces:
  high-cardinality, explorable, investigatory
  request_id, trace_id, user_id, account_id, order_id, invoice_id, deployment_id


...
```






You’re right — I cut it off. Here is the missing continuation. You can paste this after the previous section 21.

## 22. Competitive landscape: existing Elixir ecosystem
### 22.1 The important conclusion
Do **not** build a generic observability backend.
Build the Phoenix/Ecto/Plug/Oban **SRE operating layer** that sits above the existing primitives.
The Elixir ecosystem already has the right low-level substrate:
- `:telemetry` for event emission and handler attachment.
- `Telemetry.Metrics` for metric definitions.
- Phoenix, Ecto, Plug, and Oban telemetry events.
- LiveDashboard for real-time Phoenix-native inspection.
- PromEx for Prometheus/Grafana integration.
- OpenTelemetry for traces and cross-vendor observability.
- LoggerJSON for structured logs.
- Sentry/AppSignal-style integrations for exceptions/APM.
The gap is that none of these by itself gives a Phoenix SaaS founder a complete SRE control loop: critical journeys, SLOs, burn-rate alerts, wide events, deploy correlation, email deliverability, runbooks, incidents, postmortems, AI evidence bundles, and “do not page me for noise” defaults.
Phoenix’s telemetry guide shows the current shape well: Phoenix apps have a Telemetry supervisor and a `metrics/0` function where the app defines `Telemetry.Metrics`, but the developer still has to choose the metrics, reporters, dashboards, alert rules, and operating model.  [oai_citation:0‡Hexdocs](https://hexdocs.pm/phoenix/telemetry.html?utm_source=chatgpt.com)
### 22.2 What each existing Elixir tool teaches us
| Tool | What it does well | What it does not solve | Product lesson |
|---|---|---|---|
| `:telemetry` | Lightweight event substrate used throughout the BEAM ecosystem. | Not a metrics store, SLO engine, dashboard system, runbook system, or alerting policy. | Build on it, never replace it. |
| `Telemetry.Metrics` | Common interface for defining metrics from telemetry events. | Metrics definitions are not enough; users still need reporters, naming, labels, dashboards, alerting, and SLOs. | Generate safe metric definitions and pair them with output adapters. |
| Phoenix Telemetry | Emits Phoenix endpoint/router events and supports Phoenix-native telemetry workflows. | Developers still need to classify routes, avoid raw-path cardinality, map routes to journeys, and define user-harm signals. | Provide Phoenix route classification and journey mapping. |
| Ecto telemetry | Ecto exposes query timing data such as queue time, query time, decode time, idle time, and total time. | Developers still need to interpret queue time as DB/pool saturation and avoid noisy query-level metrics. | Provide DB pool saturation panels and SLO guardrails. |
| Oban telemetry | Oban emits job start/stop/exception events and includes job metadata. | A single job failure is usually not a page; queue latency, retry/discard patterns, and critical-job SLOs matter more. | Build retry-aware job health, not naive job-failed pages. |
| Plug.Telemetry | Useful for measuring plug pipeline duration. | Its docs warn that the stop event is not guaranteed in all error cases, so it should not be treated as a complete span boundary. | Use it carefully; do not build correctness on false span guarantees. |
| LiveDashboard | Excellent Phoenix-native operational UI with real-time pages for system, OS, metrics, request logging, sockets, ETS, Ecto stats, and more. | Not durable observability, not SLO/burn-rate alerting, not incident management. | Add SRE pages to LiveDashboard rather than competing with it. |
| PromEx | Strong plugin-based Prometheus/Grafana integration; ships plugin dashboards and captures telemetry events for Prometheus. | Mostly metrics/dashboards; it does not fully model SLOs, runbooks, incidents, email deliverability, deploy correlation, or AI context. | Interoperate with or build on PromEx; do not clone it. |
| OpenTelemetry Erlang/Elixir | Important tracing/exporter path; contrib instrumentation includes Phoenix, Ecto, Cowboy, and Req. | OTel does not decide which journeys matter, what “good” means, or what should wake a founder. | Treat OTel as an interoperability layer, not the domain model. |
| LoggerJSON | Gives JSON log formatters for common log-processing ecosystems. | Structured JSON is not automatically a useful wide event. | Provide event shape, redaction, sampling, and consistency rules. |
| Sentry/AppSignal | Useful exception/APM/vendor integrations for Phoenix, Ecto, Oban, Plug, and tracing-like workflows. | Does not replace local SLO definitions, OSS dashboards, runbooks, or founder-specific alert policy. | Integrate with them; do not make users choose. |
Ecto’s telemetry event metadata is especially important because `queue_time` tells you the time spent waiting for a DB connection, while `query_time` and `decode_time` describe database execution/decoding; this gives the library a native way to distinguish “the query is slow” from “the pool is saturated.”  [oai_citation:1‡Hexdocs](https://hexdocs.pm/ecto/Ecto.Repo.html?utm_source=chatgpt.com)
Oban’s telemetry events are also ideal for reliability modeling because successful jobs emit `:stop`, while error/exception/crash outcomes emit `:exception`; the library should convert this into queue SLOs, retry/discard metrics, and stuck-critical-job detection rather than paging on every exception.  [oai_citation:2‡Hexdocs](https://hexdocs.pm/oban/Oban.Telemetry.html?utm_source=chatgpt.com)
Plug.Telemetry is useful but must be documented carefully: its stop event is not guaranteed in every error case, and the docs explicitly say it cannot be used as a Telemetry span.  [oai_citation:3‡Hexdocs](https://hexdocs.pm/plug/Plug.Telemetry.html?utm_source=chatgpt.com)
### 22.3 PromEx: friend, not enemy
PromEx already provides a plugin-based library for capturing telemetry events and reporting them for Prometheus, and it is explicitly designed around consistent plugin interfaces.  [oai_citation:4‡Hexdocs](https://hexdocs.pm/prom_ex/PromEx.html?utm_source=chatgpt.com)
PromEx also ships Grafana dashboards with plugins, which is exactly the kind of “boring generated artifact” DX this new library should copy. Grafana’s PromEx writeup says PromEx ships dashboards that visualize metrics captured by its plugins and can automatically upload dashboards as new PromEx versions are published.  [oai_citation:5‡Grafana Labs](https://grafana.com/blog/get-instant-grafana-dashboards-for-prometheus-metrics-with-the-elixir-promex-library/?utm_source=chatgpt.com)
So the new library should not say:
> “Use us instead of PromEx.”
It should say:
> “PromEx is great for metrics and dashboards. ReliabilityKit adds SLOs, journey modeling, runbooks, incidents, deploy correlation, email reliability, alert policy, doctor checks, and AI-ready evidence.”
Possible integration modes:
```elixir
config :my_app, MyAppReliability,
  metrics_adapter: :prom_ex,
  dashboards: [:prom_ex, :reliability_kit],
  slo_rules: :prometheus,
  live_dashboard: true

22.4 LiveDashboard: use as the embedded admin UI

LiveDashboard already gives Phoenix developers a familiar operational surface for real-time system and app inspection, including OS data, metrics, request logging, processes, sockets, ETS, and Ecto stats.  ￼

This library should add LiveDashboard pages:

Reliability
  Health
  SLOs
  Error budgets
  Critical journeys
  Deploys
  Incidents
  Runbooks
  Jobs
  Email
  External dependencies
  Doctor
  AI evidence

But LiveDashboard should not be the only UI. Production teams need durable Grafana dashboards and Prometheus rules, while solo founders need a quick embedded view.

22.5 telemetry_metrics_prometheus: useful, but endpoint/security docs must be explicit

telemetry_metrics_prometheus exposes metrics on port 9568 at /metrics by default, and its docs note HTTPS is not supported by its included server.  ￼

That creates a concrete library requirement:

mix reliability.doctor
  [warn] telemetry_metrics_prometheus server exposes /metrics without HTTPS.
  [warn] Ensure scrape endpoint is private, protected, or exposed only on an internal network.

The install guide should include three safe deployment patterns:

1. private metrics port scraped inside the same network;
2. Phoenix route protected by auth/IP allowlist;
3. sidecar/exporter mode in container/Kubernetes/Fly/Render style deployments.

22.6 LoggerJSON: structured log output is not enough

LoggerJSON provides JSON formatters for basic JSON logging and specific ecosystems such as Google Cloud, Datadog, and Elastic/ECS.  ￼

The library should not merely say “use JSON logs.” It should generate wide event schemas that work with LoggerJSON or another sink.

Bad:

Logger.info("checkout failed")

Better:

ReliabilityKit.event(:checkout_completed,
  outcome: :failed,
  account_id: account.id,
  user_id: user.id,
  request_id: request_id,
  trace_id: trace_id,
  deployment_id: deployment_id,
  provider: :stripe,
  error_class: "StripeRateLimitError",
  feature_flags: ["new_checkout"]
)

LoggerJSON is the formatter. ReliabilityKit should define the semantics.

22.7 OpenTelemetry: trace support, not SRE policy

OpenTelemetry’s Erlang/Elixir docs cover SDK setup, and the Erlang/Elixir contrib repository lists automatic tracing support for libraries such as Cowboy, Phoenix, Ecto, and Req.  ￼

The new library should map its domain events to OTel attributes/spans where useful:

journey=checkout
slo=checkout_completion
deployment_id=...
feature_flags=...
business_flow=checkout
provider=stripe

But OpenTelemetry should remain an output/integration, not the core product. The core product is:

What user journey is harmed?
How fast is the error budget burning?
What changed?
What is the safest mitigation?
What evidence supports that?

⸻

23. Cross-ecosystem lessons

23.1 Google SRE: page on symptoms, not causes

Google’s SRE material defines the four golden signals as latency, traffic, errors, and saturation. That maps cleanly to Phoenix apps: request latency, route traffic, 5xx/error outcomes, DB/job/provider saturation.  ￼

Prometheus alerting best practices are aligned: keep alerting simple, alert on symptoms, have consoles for diagnosis, and avoid pages where there is nothing to do.  ￼

Library principle:

Page on user harm.
Dashboard on system behavior.
Log wide context.
Use traces for causality.
Use AI for investigation, not unbounded production action.

23.2 SLO tooling: Sloth, Pyrra, OpenSLO

Sloth’s main lesson is that hand-writing Prometheus SLO rules is complex enough that teams benefit from a generator. Its positioning is “fast, easy and reliable Prometheus SLO generator.”  ￼

Pyrra’s main lesson is that SLOs need a UI and rule-generation pipeline: its README describes a UI for SLOs, error budgets, burn rates, plus a backend that creates Prometheus recording rules for SLO objects.  ￼

OpenSLO’s main lesson is that SLO definitions should be code, reviewable in Git, and vendor-neutral. Its spec is designed to make SLOs ergonomic for modern developer Git workflows.  ￼

ReliabilityKit should steal all three ideas:

From Sloth:
  Simple SLO spec -> Prometheus rules.
From Pyrra:
  SLO UI -> error budget and burn-rate visibility.
From OpenSLO:
  SLOs as code -> GitOps/reviewable definitions.

23.3 Prometheus: cardinality and ratio math are non-negotiable

Prometheus explicitly warns that every unique label set creates a separate time series and says not to use high-cardinality labels such as user IDs, email addresses, or unbounded values.  ￼

Prometheus recording-rule guidance also says to aggregate ratio numerators and denominators separately, then divide, and not to average ratios.  ￼

That gives two hard correctness requirements:

Requirement 1:
  The library must lint metric labels.
Requirement 2:
  The SLO generator must store and aggregate good/total counts separately.

23.4 Honeycomb/wide-events lesson: high cardinality belongs in events, not metric labels

Honeycomb’s docs explain that high-cardinality fields can help identify a specific request and narrow down what caused something to go wrong.  ￼

So the library should not teach “never capture user_id.” It should teach:

Do not put user_id in metric labels.
Do put user_id/account_id/request_id/trace_id in redacted, controlled wide events.

23.5 Grafana: dashboard-as-code and provisioning matter

Grafana supports provisioning dashboards and data sources from files that can be version-controlled, which is the right model for a serious open-source library.  ￼

ReliabilityKit should generate both:

priv/reliability/grafana/dashboards/*.json
priv/reliability/grafana/provisioning/*.yml
priv/reliability/prometheus/rules/*.yml

and optionally upload dashboards via API for fast setup.

23.6 MCP/AI observability: read-only first, audited always

Grafana’s MCP server exposes tools for dashboards, data sources such as Prometheus and Loki, alerting, incidents, OnCall, and more.  ￼

Datadog’s MCP docs show an important operating pattern: track MCP Server tool calls in an audit trail.  ￼

OWASP’s MCP Tool Poisoning page describes malicious MCP servers whose tools look normal but return hidden instructions that influence the model to leak data or call restricted tools.  ￼

Therefore:

Default AI posture:
  read-only investigation
  cited evidence bundles
  no production mutations
Advanced AI posture:
  approval-required narrow tools
  audited tool calls
  reversible actions only
  tool allowlists
  rate limits
  explicit incident binding

⸻

24. Product shape: what the library actually is

24.1 One-line description

ReliabilityKit is a Phoenix-native SRE layer for critical journey SLOs, burn-rate alerts, wide events, deploy correlation, email deliverability, runbooks, incident notes, dashboards, and AI-ready evidence.

24.2 What it is not

Not a Prometheus replacement.
Not a Grafana replacement.
Not a Datadog clone.
Not a generic logger.
Not a generic tracing SDK.
Not an autonomous production agent.
Not an enterprise incident-management suite.

24.3 Core package promise

Given a Phoenix app, generate the boring correct reliability baseline:
- metrics
- SLOs
- Prometheus recording rules
- Prometheus alert rules
- Grafana dashboards
- LiveDashboard pages
- wide event schema
- runbooks
- incident templates
- deploy markers
- email deliverability monitors
- doctor/lint checks
- AI evidence bundles

24.4 Install command

mix archive.install hex reliability_new
mix reliability.install

Generated files:

lib/my_app/reliability.ex
lib/my_app/reliability/surfaces/http.ex
lib/my_app/reliability/surfaces/database.ex
lib/my_app/reliability/surfaces/jobs.ex
lib/my_app/reliability/surfaces/email.ex
priv/reliability/slo/*.exs
priv/reliability/prometheus/rules/*.yml
priv/reliability/grafana/dashboards/*.json
priv/reliability/runbooks/*.md
priv/reliability/incidents/templates/*.md
priv/reliability/ai/AGENTS.reliability.md
test/support/reliability_case.ex

⸻

25. Architecture

25.1 High-level modules

ReliabilityKit.Core
  DSL, structs, validation, domain model, compile-time checks.
ReliabilityKit.Telemetry
  Telemetry handlers, attach/detach lifecycle, event normalization.
ReliabilityKit.Metrics
  Telemetry.Metrics generation, metric naming, label policy.
ReliabilityKit.Phoenix
  Endpoint/router integration, route classification, request wide events.
ReliabilityKit.Plug
  Plug integration, pipeline observations, caveat-aware instrumentation.
ReliabilityKit.Ecto
  Repo query/pool metrics, DB saturation, migration markers.
ReliabilityKit.Oban
  Job metrics, queue SLOs, critical job monitoring.
ReliabilityKit.Email
  Email send attempts, provider accepted/rejected/delivered/bounced/complained events.
ReliabilityKit.External
  External dependency calls, provider SLOs, retry/rate-limit context.
ReliabilityKit.SLO
  SLI/SLO model, burn-rate math, rule generation.
ReliabilityKit.Alerts
  Alert policy, severity, routing metadata, rule generation.
ReliabilityKit.Dashboards
  Grafana JSON, provisioning files, LiveDashboard pages.
ReliabilityKit.Incident
  Incident notes, timeline, status, mitigation, postmortem.
ReliabilityKit.Runbooks
  Markdown runbooks, generated templates, query snippets.
ReliabilityKit.AI
  Evidence bundles, AGENTS.md, MCP read-only tools, approval gates.
ReliabilityKit.Doctor
  Lints, security checks, cardinality checks, config validation.
ReliabilityKit.Test
  ExUnit helpers, telemetry assertions, SLO fixture helpers.
ReliabilityKit.Release
  Version/deploy marker support, CI/CD integration helpers.

25.2 Supervision tree

children = [
  MyAppWeb.Telemetry,
  MyApp.Repo,
  MyAppWeb.Endpoint,
  {ReliabilityKit.Supervisor,
   otp_app: :my_app,
   config: MyApp.Reliability,
   exporters: [:prometheus, :logger, :opentelemetry],
   live_dashboard: true}
]

25.3 Handler lifecycle

Telemetry handlers can be detached when a handler crashes, which is a real operational footgun discussed in the Elixir community. The library should make handlers small, safe, and observable rather than hiding crashes.  ￼

Rules:

- Never block inside telemetry handlers.
- Never perform network I/O inside telemetry handlers.
- Catch/report handler exceptions.
- Emit health metrics for handler attach/detach.
- Provide tests for handler idempotency.
- Avoid duplicate handler attachment in dev/reload scenarios.

⸻

26. Domain DSL

26.1 Top-level config

defmodule MyApp.Reliability do
  use ReliabilityKit,
    otp_app: :my_app,
    service: :web,
    endpoint: MyAppWeb.Endpoint,
    router: MyAppWeb.Router,
    repo: MyApp.Repo
  environment from: {:config, :my_app, :environment}
  service_version from: {:env, "RELEASE_VERSION"}
  deployment_id from: {:env, "RELEASE_SHA"}
  exporters do
    prometheus path: "/metrics", protect: :private_network
    logger_json enabled: true
    opentelemetry enabled: true
  end
  defaults do
    route_cardinality :phoenix_route_pattern
    redact :standard_secrets
    sample :standard_saas
    page_policy :user_harm_only
  end
end

26.2 Critical journeys

journey :checkout do
  description "Customer can start and complete checkout."
  owner :founder
  criticality :critical
  surface :payment
  started event: [:my_app, :checkout, :started]
  completed event: [:my_app, :checkout, :completed]
  failed event: [:my_app, :checkout, :failed]
  labels [:plan, :currency]
  event_fields [:account_id, :user_id, :checkout_session_id, :deployment_id, :feature_flags]
  slo :completion do
    total :started
    good :completed
    objective 99.5
    window :days_30
    volume_gate min: 20, window: :minutes_5
    synthetic_check :checkout_sandbox, every: :minutes_5
    alert :fast_burn, notify: :page
    alert :slow_burn, notify: :ticket
    runbook "priv/reliability/runbooks/checkout_failure.md"
    dashboard :critical_journeys
  end
end

26.3 HTTP surface

surface :http do
  phoenix endpoint: MyAppWeb.Endpoint, router: MyAppWeb.Router
  classify_routes do
    ignore "/health"
    ignore "/metrics"
    customer_facing ~r"^/(app|checkout|signup|login)"
    admin ~r"^/admin"
  end
  metrics do
    counter :requests_total,
      event: [:phoenix, :router_dispatch, :stop],
      labels: [:route, :method, :status_class]
    distribution :request_duration_seconds,
      event: [:phoenix, :router_dispatch, :stop],
      measurement: :duration,
      labels: [:route, :method],
      buckets: :http_default
  end
  wide_event :request_completed do
    include [
      :request_id,
      :trace_id,
      :route,
      :method,
      :status,
      :duration_ms,
      :account_id,
      :user_id,
      :deployment_id,
      :feature_flags,
      :error_class
    ]
    emit_once :on_completion
    redact :default
  end
end

26.4 Email surface

surface :email do
  provider :postmark do
    webhook "/reliability/webhooks/postmark"
    verify :basic_auth
  end
  provider :sendgrid do
    webhook "/reliability/webhooks/sendgrid"
    verify :ecdsa_signature
  end
  provider :ses do
    source :sns
    verify :sns_signature
  end
  message_type :password_reset, criticality: :critical, transactional: true
  message_type :magic_link, criticality: :critical, transactional: true
  message_type :invoice_receipt, criticality: :critical, transactional: true
  message_type :marketing_newsletter, criticality: :low, transactional: false
  slo :transactional_acceptance do
    total event: :email_send_attempted, where: [transactional: true]
    good event: :email_provider_accepted
    objective 99.5
    window :days_30
    alert :fast_burn, notify: :page
  end
end

Google’s sender guidance says to monitor spam rates and keep spam rates below 0.10%, avoiding 0.30% or higher; that should be encoded into email dashboard warnings and runbooks for deliverability-sensitive SaaS apps.  ￼

Postmark, SendGrid, and SES all expose event/webhook models for message events such as delivery, bounce, complaint, dropped/rejected, open, click, and delay-style events, so the email module should normalize provider-specific events into a common email reliability event model.  ￼

⸻

27. SLO engine design

27.1 SLO struct

defmodule ReliabilityKit.SLO do
  @type t :: %__MODULE__{
          name: atom(),
          surface: atom(),
          journey: atom() | nil,
          objective: float(),
          window: atom(),
          total: ReliabilityKit.SLI.Query.t(),
          good: ReliabilityKit.SLI.Query.t(),
          alerts: [ReliabilityKit.AlertPolicy.t()],
          volume_gate: ReliabilityKit.VolumeGate.t() | nil,
          synthetic_check: atom() | nil,
          runbook: String.t() | nil,
          labels: keyword()
        }
  defstruct [
    :name,
    :surface,
    :journey,
    :objective,
    :window,
    :total,
    :good,
    :alerts,
    :volume_gate,
    :synthetic_check,
    :runbook,
    labels: []
  ]
end

27.2 Burn-rate rule generation

For a 99.9% SLO:

allowed_error_ratio = 1 - 0.999 = 0.001

Generated Prometheus expression shape:

(
  (
    sum(rate(reliability_slo_bad_events_total{slo="api_availability"}[5m]))
    /
    sum(rate(reliability_slo_total_events_total{slo="api_availability"}[5m]))
  ) > (14.4 * 0.001)
)
and
(
  (
    sum(rate(reliability_slo_bad_events_total{slo="api_availability"}[1h]))
    /
    sum(rate(reliability_slo_total_events_total{slo="api_availability"}[1h]))
  ) > (14.4 * 0.001)
)

Google’s SRE workbook recommends burn-rate alerting and describes multi-window, multi-burn-rate alerts as a way to catch significant error-budget consumption while reducing false positives.  ￼

27.3 SLO output formats

Generate:

Prometheus recording rules
Prometheus alert rules
Grafana SLO dashboard panels
LiveDashboard SLO page
OpenSLO-compatible YAML
Markdown SLO docs
AI evidence schema

OpenSLO should be treated as the interop format:

apiVersion: openslo/v1
kind: SLO
metadata:
  name: checkout-completion
spec:
  service: my_app
  indicator:
    ratioMetric:
      good:
        metricSource:
          type: Prometheus
          spec:
            query: sum(rate(reliability_checkout_completed_total[5m]))
      total:
        metricSource:
          type: Prometheus
          spec:
            query: sum(rate(reliability_checkout_started_total[5m]))
  budgetingMethod: Occurrences
  objectives:
    - target: 0.995
      timeWindow:
        - duration: 30d
          isRolling: true

⸻

28. Dashboard set

28.1 Generate only six dashboards by default

Do not create dashboard sprawl.

1. Executive health
2. RED service dashboard
3. Saturation dashboard
4. Critical journeys
5. Deploy/change dashboard
6. Business pulse + email

Google’s golden signals suggest latency, traffic, errors, and saturation as the core monitoring foundation for user-facing systems.  ￼

28.2 Executive health

Panels:

current deploy SHA/version
open incidents
API availability SLO
API fast-enough SLO
checkout SLO
login SLO
transactional email SLO
critical jobs SLO
error-budget remaining
last deploy health

28.3 RED service dashboard

Panels:

request rate by route
5xx ratio by route
p50/p95/p99 latency by route
slowest routes
top error classes
deploy overlay
feature flag overlay

28.4 Saturation dashboard

Panels:

DB pool in use
DB queue time
DB query time
CPU/memory/disk
Oban queue depth
Oban wait time
external provider latency
external provider rate limits

28.5 Critical journeys

Panels:

signup started/completed
login success/failure
checkout started/completed/failed
payment webhook lag
transactional email accepted/delivered/bounced/complained
core action completion
critical job completion

28.6 Deploy/change dashboard

Panels:

deploy markers
current SHA
migrations
feature flag changes
before/after 5xx
before/after latency
new exception classes
new failed journeys

28.7 Business pulse

Panels:

subscription created/canceled
invoice paid/failed
checkout conversion
trial activated
support/contact spike
email deliverability

⸻

29. Incident and postmortem layer

29.1 Incident lifecycle

alert.fired
  -> incident.opened
  -> timeline.started
  -> impact.assessed
  -> mitigation.selected
  -> mitigation.applied
  -> recovery.verified
  -> incident.mitigated
  -> incident.resolved
  -> postmortem.created
  -> action_items.tracked

29.2 Incident states

:open
:investigating
:mitigating
:monitoring
:mitigated
:resolved
:reopened

29.3 Incident commands

mix reliability.incident.open checkout_failure --severity sev1
mix reliability.incident.timeline inc_123 "Disabled new_checkout flag"
mix reliability.incident.evidence inc_123 --slo checkout_completion
mix reliability.incident.mitigate inc_123 --action disable_feature_flag:new_checkout
mix reliability.incident.resolve inc_123
mix reliability.postmortem.draft inc_123

29.4 Postmortem principle

Postmortems should be blameless and focused on contributing causes and system improvement, not personal fault. Google’s postmortem culture chapter explicitly frames blameless postmortems as focusing on contributing causes without indicting individuals or teams.  ￼

Generated template:

# Postmortem: <incident>
## Summary
## Customer impact
## Timeline
## Detection
## Mitigation
## What went well
## What went poorly
## Contributing factors
## Where we got lucky
## Follow-up actions
| Action | Owner | Priority | Verification |
|---|---|---|---|

⸻

30. AI/LLM-assisted operations

30.1 AGENTS.md generated block

# Reliability context for AI agents
This Phoenix app uses ReliabilityKit.
Operating doctrine:
- Page only on urgent, actionable, user-visible or imminent user-visible harm.
- SLOs are good_events / total_events.
- Use error-budget burn, not raw twitchy metrics.
- Metrics are low-cardinality and alertable.
- Wide events are high-cardinality and investigatory.
- Traces show causal paths.
- Email deliverability is production reliability.
- Prefer rollback or feature flag disable during active incidents.
- Do not run destructive production actions.
Allowed AI actions:
- Query SLO status.
- Query recent deploys.
- Query logs/wide events.
- Query traces.
- Summarize evidence.
- Draft incident notes.
- Draft postmortems.
- Draft status updates.
Blocked without human approval:
- Rollback deploy.
- Disable feature flag.
- Pause queue.
- Scale workers.
Always blocked:
- Delete data.
- Run arbitrary SQL.
- Modify IAM/secrets.
- Disable auth.
- Modify billing.
- Send mass emails.

30.2 MCP tools

read-only tools:
  reliability.get_slo_status
  reliability.get_error_budget
  reliability.get_recent_deploys
  reliability.get_recent_alerts
  reliability.get_incident
  reliability.query_metrics
  reliability.query_wide_events
  reliability.lookup_trace
  reliability.read_runbook
  reliability.create_evidence_bundle
draft-only tools:
  reliability.draft_status_update
  reliability.draft_postmortem
  reliability.draft_github_issue
approval-required tools:
  reliability.rollback_deploy
  reliability.disable_feature_flag
  reliability.pause_queue
  reliability.resume_queue
blocked tools:
  reliability.run_sql
  reliability.delete_data
  reliability.modify_auth
  reliability.modify_billing
  reliability.rotate_secret

30.3 Tool call audit schema

%ReliabilityKit.AI.ToolCall{
  id: "toolcall_...",
  session_id: "copilot_...",
  actor: "founder@example.com",
  client: "cursor",
  tool_name: "reliability.query_metrics",
  risk_level: :read_only,
  incident_id: "inc_...",
  input_hash: "...",
  output_hash: "...",
  approved_by: nil,
  started_at: ~U[2026-05-09 14:03:00Z],
  completed_at: ~U[2026-05-09 14:03:01Z]
}

30.4 Evidence bundle prompt

You are an SRE copilot for a Phoenix SaaS.
Rules:
- Separate facts from hypotheses.
- Cite every metric/log/trace/deploy/runbook claim.
- Prefer safe reversible mitigations.
- Do not recommend destructive actions.
- Do not invent causes.
- Do not ignore volume gates.
- Do not page on non-user-impacting anomalies.
Task:
1. State likely user impact.
2. Check deploy correlation.
3. Compare traffic, errors, latency, saturation.
4. Identify top 3 hypotheses.
5. Provide exact evidence for each.
6. Recommend safest mitigation.
7. List unknowns.
8. Draft status update if SEV-1/SEV-2.

⸻

31. Email deliverability module details

31.1 Why this matters

For SaaS, email is infrastructure. If password resets, magic links, invoices, team invites, security notifications, and receipts stop working, the product is broken even when HTTP looks healthy.

31.2 Provider event normalization

%ReliabilityKit.Email.Event{
  provider: :postmark,
  event_type: :bounced,
  message_type: :password_reset,
  transactional?: true,
  criticality: :critical,
  message_id: "msg_123",
  provider_message_id: "postmark_456",
  recipient_domain: "gmail.com",
  bounce_class: :hard,
  occurred_at: ~U[2026-05-09 14:03:00Z],
  metadata: %{}
}

31.3 Email metrics

reliability_email_send_attempts_total{provider,message_type,criticality}
reliability_email_provider_accepted_total{provider,message_type}
reliability_email_provider_rejected_total{provider,message_type,reason_class}
reliability_email_delivered_total{provider,message_type}
reliability_email_bounced_total{provider,message_type,bounce_class}
reliability_email_complained_total{provider,message_type}
reliability_email_delivery_duration_seconds_bucket{provider,message_type}
reliability_email_webhook_events_total{provider,event_type}
reliability_email_webhook_verification_failed_total{provider}

31.4 Email alerts

Page:

password reset send acceptance collapses
magic link send acceptance collapses
invoice/receipt acceptance collapses
provider reject rate fast burn
email provider webhook processing stopped
spam complaint rate near dangerous threshold

Ticket:

marketing bounce rate elevated
delivery delay rising but critical transactional mail is OK
open/click metrics changed
one recipient domain degraded without critical journey failure

31.5 Email runbook

# Runbook: Transactional email acceptance failure
## Symptoms
- email transactional acceptance SLO fast burn
- provider rejected events elevated
- password reset or magic link failures reported
- provider API errors elevated
## First checks
1. Check provider status.
2. Check API key/secret rotation.
3. Check provider reject reasons.
4. Check domain authentication: SPF/DKIM/DMARC.
5. Check recent deploy/config changes.
6. Check recipient-domain-specific failures.
7. Check provider webhook verification failures.
## Mitigations
- switch provider if fallback configured
- rollback config/deploy
- pause noncritical marketing sends
- use alternate login/support path
- communicate with affected users

⸻

32. mix reliability.doctor

32.1 Doctor checks

Configuration
  [ok] Reliability module found
  [ok] endpoint/router/repo detected
  [warn] no deployment_id configured
  [warn] no service_version configured
Metrics
  [ok] route labels use Phoenix route patterns
  [warn] metric label :user_id is high-cardinality
  [warn] metric label :request_id is high-cardinality
  [warn] custom metric uses raw path
SLOs
  [ok] api_availability SLO found
  [warn] checkout journey has no SLO
  [warn] transactional email has no SLO
  [warn] SLO checkout_completion has no runbook
  [warn] SLO has no volume gate and low observed traffic
Security
  [warn] /metrics appears publicly mounted
  [warn] LiveDashboard mounted in prod without auth plug
  [warn] email webhook lacks signature verification
  [warn] MCP approval-required tools enabled in prod without audit sink
Performance
  [ok] telemetry handlers attach once
  [warn] handler performs synchronous network call
  [warn] high-cardinality label observed with 10k+ values
AI
  [ok] read-only tools enabled
  [warn] rollback tool enabled without approval policy
  [warn] run_sql tool must remain blocked

32.2 Doctor as CI gate

mix reliability.doctor --ci

Exit behavior:

0 = ok
1 = warnings above configured threshold
2 = hard safety failure

Hard failures:

public /metrics in prod without explicit allow
public LiveDashboard in prod without auth
PII metric labels
unsafe MCP tool enabled without approval/audit
email webhook without verification in prod

⸻

33. Security and privacy model

33.1 Redaction policy

redact keys_matching: [
  ~r/password/i,
  ~r/passwd/i,
  ~r/secret/i,
  ~r/token/i,
  ~r/api[_-]?key/i,
  ~r/session/i,
  ~r/cookie/i,
  ~r/authorization/i,
  ~r/credit[_-]?card/i
]

Phoenix already has log parameter filtering support, but ReliabilityKit should treat Phoenix filtering as one layer and add its own event/wide-log redaction checks.  ￼

33.2 PII policy

Never allowed in metric labels:
  email
  phone
  full_name
  ip_address
  user_id
  account_id
  session_id
  request_id
  trace_id
  payment_id
  invoice_id
Allowed in wide events only with policy:
  user_id
  account_id
  request_id
  trace_id
  provider_message_id
Usually redact/hash:
  email
  phone
  ip_address
  auth tokens

33.3 MCP policy

- Read-only by default.
- Approval required for production-changing tools.
- Every tool call audited.
- Tool outputs treated as untrusted evidence.
- Tool descriptions reviewed and pinned.
- No arbitrary remote MCP servers in production context.
- No destructive tools.

33.4 Endpoint protection

Generated docs should cover:

/metrics
/dashboard
/reliability/webhooks/*
/reliability/mcp
/reliability/admin/*

Each endpoint should have explicit environment-specific guidance.

⸻

34. Performance model

34.1 Hot path principles

Telemetry handler:
  classify
  normalize
  enqueue/export
  return
Do not:
  perform network calls
  perform slow DB queries
  serialize huge payloads
  compute expensive labels
  call LLMs

Phoenix telemetry docs warn that metric tag value functions run on every event, which means expensive tag functions are a real hot-path cost.  ￼

34.2 Sampling

sample :standard_saas do
  keep :errors
  keep :slow_requests
  keep journey: :checkout
  keep journey: :login
  keep surface: :payment_webhook
  keep surface: :email
  keep :admin_actions
  keep :security_events
  rate successes: 0.10
  drop route: "/health"
  drop route: "/metrics"
end

34.3 Backpressure

If exporter queue fills:
  keep errors
  keep SLO-relevant events
  drop sampled successes first
  emit reliability_exporter_dropped_events_total
  never block request path indefinitely

34.4 Benchmarks

Benchmarks should include:

request telemetry handler overhead
wide event construction overhead
redaction overhead
metric label validation overhead
export queue throughput
large route table classification
high-volume Oban job events
email webhook burst processing

⸻

35. Testing strategy

35.1 Unit tests

DSL validation
redaction
label linting
route classification
SLO math
burn-rate threshold generation
OpenSLO export
Prometheus rule generation
Grafana JSON generation
email provider event normalization
AI tool policy

35.2 Integration tests

Use sample Phoenix apps:

examples/minimal_phoenix
examples/phoenix_ecto
examples/phoenix_ecto_oban
examples/phoenix_email
examples/full_prometheus_grafana

Test:

Phoenix request emits metrics and wide event
Ecto query emits DB metrics
Oban success/failure/retry/discard metrics
email webhook verifies and normalizes provider events
LiveDashboard pages render
Prometheus rules pass promtool
Grafana dashboards are valid JSON
doctor catches public dashboard/metrics
MCP tools enforce read-only/approval policy

35.3 ExUnit helpers

defmodule MyApp.ReliabilityTest do
  use MyApp.ConnCase
  import ReliabilityKit.Test
  test "checkout emits started and completed events" do
    assert_emits_reliability_event :checkout_started do
      post(conn, ~p"/checkout", valid_params())
    end
  end
  test "no high-cardinality metric labels are configured" do
    assert_no_metric_labels [:user_id, :account_id, :request_id, :email]
  end
  test "checkout SLO compiles to Prometheus rules" do
    assert_valid_prometheus_rules MyApp.Reliability
  end
end

35.4 Property tests

redaction never leaks configured secret keys
SLO good count never exceeds total count
label sanitizer never produces unbounded raw path
provider webhook dedupe is idempotent
sampling keeps all errors

⸻

36. CI/CD and release process

36.1 CI checks

name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          otp-version: "27"
          elixir-version: "1.18"
      - run: mix deps.get
      - run: mix format --check-formatted
      - run: mix compile --warnings-as-errors
      - run: mix test
      - run: mix credo --strict
      - run: mix dialyzer
      - run: mix docs
      - run: mix reliability.test.generated_artifacts

The common Elixir CI pattern includes formatting, Credo, Dialyzer/Dialyxir, and ExUnit tests; multiple Elixir CI guides converge on those as standard quality checks.  ￼

36.2 Compatibility matrix

Elixir:
  1.16
  1.17
  1.18
  1.19 when stable/needed
OTP:
  26
  27
  28 when stable/needed
Phoenix:
  latest stable
  previous stable
Ecto:
  latest stable
  previous stable
Oban:
  optional; current stable
Plug:
  current stable

36.3 Release automation

Publishing to Hex requires package metadata in mix.exs and submission with mix hex.publish; Hex also documents package/docs size limits.  ￼

ExDoc is the standard documentation generator for Elixir/Erlang projects.  ￼

Release checklist:

[ ] CI green
[ ] generated dashboards valid
[ ] generated Prometheus rules valid
[ ] generated OpenSLO specs valid
[ ] example apps pass
[ ] docs build
[ ] changelog generated
[ ] semver version bumped
[ ] mix hex.build passes
[ ] mix hex.publish --dry-run passes
[ ] mix hex.publish
[ ] mix hex.publish docs

⸻

37. Documentation plan

37.1 Docs table of contents

Getting Started
  Installation
  Phoenix quickstart
  What this library does and does not do
Concepts
  Reliability surfaces
  Critical journeys
  SLIs and SLOs
  Error budgets
  Burn-rate alerts
  Metrics vs wide events vs traces
  Cardinality
  Alert policy
  Incidents and runbooks
Guides
  Phoenix HTTP reliability
  Ecto/database reliability
  Oban/job reliability
  Email deliverability
  External dependency monitoring
  Prometheus setup
  Grafana setup
  LiveDashboard setup
  OpenTelemetry setup
  Sentry/AppSignal integration
  AI/MCP setup
  Security hardening
  Deploy markers
  Synthetic checks
Recipes
  Checkout SLO
  Login SLO
  Transactional email SLO
  Payment webhook SLO
  Critical job SLO
  DB saturation alert
  Feature-flag deploy correlation
  Daily reliability digest
Reference
  DSL
  Structs
  Events
  Metrics
  Alert policies
  Mix tasks
  Test helpers
  Adapter API

37.2 README shape

# ReliabilityKit
Phoenix-native SLOs, dashboards, wide events, runbooks, email reliability, and AI-ready incident context.
## Why
Phoenix gives you Telemetry.
PromEx gives you metrics and dashboards.
OpenTelemetry gives you traces.
LoggerJSON gives you structured logs.
ReliabilityKit gives you the SRE control loop:
journeys -> SLOs -> alerts -> dashboards -> incidents -> runbooks -> learning.
## Install
## First SLO
## First dashboard
## First runbook
## Doctor
## Security
## Philosophy

⸻

38. Community and OSS strategy

38.1 Design principles

Small core.
Optional adapters.
No vendor lock-in.
Generated artifacts are readable.
Host app owns generated files.
Idiomatic Phoenix/Ecto/Plug style.
Docs before magic.
Security warnings by default.
AI features behind rails.

38.2 Contribution strategy

- Public roadmap.
- Small RFC process for DSL changes.
- Compatibility policy.
- Adapter authoring guide.
- Dashboard contribution guide.
- Event schema contribution guide.
- Security disclosure policy.
- Example apps as integration test targets.

38.3 Avoiding ecosystem conflict

Position the package as complementary:

With PromEx:
  use PromEx for metrics/dashboards; ReliabilityKit adds SLOs/runbooks/incidents.
With LiveDashboard:
  add SRE pages.
With OpenTelemetry:
  enrich traces and correlate evidence.
With LoggerJSON:
  provide wide event shape and redaction.
With Sentry/AppSignal:
  link errors/APM to SLOs and incidents.

⸻

39. Roadmap

Phase 0: research spike

- confirm Phoenix/Ecto/Oban telemetry event names
- prototype route classification
- prototype wide request event
- prototype SLO DSL
- generate one Prometheus rule
- generate one Grafana dashboard
- render one LiveDashboard page

Phase 1: Phoenix baseline

Features:
- install generator
- HTTP RED metrics
- Ecto metrics
- Oban metrics
- wide request/job event schema
- cardinality linter
- LiveDashboard Health page
- Grafana RED dashboard
- doctor command

Phase 2: SLO engine

Features:
- SLO DSL
- good/total metric generation
- burn-rate rule generation
- volume gates
- SLO dashboard
- runbook links
- OpenSLO export

Phase 3: critical journeys

Features:
- journey DSL
- signup/login/checkout templates
- payment webhook template
- critical job template
- synthetic check interface
- deploy markers

Phase 4: email reliability

Features:
- email event API
- Postmark normalizer
- SendGrid normalizer
- SES normalizer
- transactional email SLOs
- bounce/complaint dashboard
- deliverability runbooks

Phase 5: incident layer

Features:
- incident state model
- timeline entries
- evidence bundles
- postmortem draft
- action items
- status update draft

Phase 6: AI/MCP

Features:
- AGENTS.md generation
- read-only MCP tools
- AI evidence bundle
- approval-gated action framework
- tool-call audit log
- MCP security doctor checks

⸻

40. The wedge MVP

The first public version should be narrow and excellent.

MVP name

ReliabilityKit Phoenix SLO Starter

MVP features

1. Install generator.
2. Phoenix route metrics with safe labels.
3. Ecto query/pool metrics.
4. Oban job/queue metrics.
5. SLO DSL for API availability and latency.
6. Prometheus recording/alert rule generation.
7. Grafana dashboard generation.
8. LiveDashboard SLO page.
9. Wide request event schema.
10. mix reliability.doctor.

MVP non-features

No full incident system yet.
No full MCP server yet.
No every-provider email support yet.
No autonomous mitigation.
No vendor-specific paid-platform assumptions.

Why this wedge works

It solves immediate pain:

“I have a Phoenix app. Tell me whether users are hurting, generate sane dashboards/alerts, and keep me from doing cardinality/security mistakes.”

It does not require the user to buy into every future part of the platform.

⸻

41. Example complete user flow

41.1 Day 0

mix reliability.install
mix reliability.doctor

Output:

ReliabilityKit installed.
Detected:
  Phoenix endpoint: MyAppWeb.Endpoint
  Router: MyAppWeb.Router
  Repo: MyApp.Repo
  Oban: yes
  LiveDashboard: yes
Generated:
  lib/my_app/reliability.ex
  priv/reliability/prometheus/rules/api_availability.yml
  priv/reliability/grafana/dashboards/reliability_health.json
  priv/reliability/runbooks/api_availability.md
Warnings:
  [warn] deployment_id not configured
  [warn] /metrics protection not confirmed
  [warn] checkout journey not configured

41.2 Day 1

Developer adds:

journey :checkout do
  started event: [:my_app, :checkout, :started]
  completed event: [:my_app, :checkout, :completed]
  failed event: [:my_app, :checkout, :failed]
  slo :completion do
    total :started
    good :completed
    objective 99.5
    window :days_30
    alert :fast_burn, notify: :page
  end
end

41.3 Day 2 incident

Alert fires:

SEV-1 CheckoutCompletionFastBurn
Impact:
  checkout_started normal
  checkout_completed near zero
  payment provider errors elevated
  started 7 minutes after deploy abc123
Recommended first mitigation:
  disable feature flag new_checkout

Evidence bundle:

SLO:
  checkout_completion 82.3% over 5m
Deploy:
  abc123 at 14:02
Wide events:
  top error_class StripeInvalidRequestError
  feature_flags=["new_checkout"]
Trace:
  external call stripe.checkout_session.create failing
Runbook:
  priv/reliability/runbooks/checkout_failure.md

This is the product experience.

⸻

42. Hard design decisions

42.1 Build on PromEx or independent?

Recommendation:

Core should be independent.
PromEx adapter should be first-class.

Reason:

* Some users already use PromEx.
* Some users want only telemetry_metrics_prometheus.
* Some users want OpenTelemetry metrics.
* Some users want StatsD, AppSignal, Datadog, or custom reporters.
* The domain model should not be tied to one metrics reporter.

42.2 Store incidents in app DB or generated files?

Recommendation:

Support both:
  file/Markdown mode for solo/simple apps
  Ecto persistence mode for richer admin UI

MVP:

Markdown incident notes + generated evidence bundle.

Later:

Ecto schema for incidents, timeline entries, action items, tool calls.

42.3 Should the library send pages?

Recommendation:

No direct paging in MVP.
Generate alert rules and routing metadata.

Reason:

* Alertmanager, Grafana Alerting, PagerDuty, Opsgenie, Slack, email, and custom systems differ.
* Library should generate policy, not own notification plumbing.

42.4 Should AI be included in core?

Recommendation:

Core emits AI-readable context.
MCP server is optional.

Reason:

* AI users need context now.
* Security-conscious teams may not want MCP enabled.
* Read-only evidence bundles are useful even without MCP.

⸻

43. Deep footgun list

43.1 Metrics footguns

- raw path label instead of Phoenix route pattern
- user_id/account_id/request_id/email labels
- status code labels too granular when status_class is enough
- error_message label
- SQL query label
- unbounded provider operation labels
- generating histograms for too many dimensions
- no minimum-volume gates on low-traffic SLOs
- averaging ratios
- alerting on p99 with tiny sample size

43.2 Alerting footguns

- page on CPU without user impact
- page on single 500
- page on single failed job
- page on log line containing "error"
- page on business KPI anomaly without system evidence
- duplicate pages for same incident
- no runbook link
- no dashboard link
- no deploy correlation
- no silence/mute policy for maintenance

43.3 Phoenix/Ecto/Oban footguns

- LiveDashboard public in prod
- metrics endpoint public in prod
- Plug.Telemetry treated as complete span
- telemetry handler crashes and detaches
- blocking telemetry handlers
- Ecto queue time ignored
- Oban retry treated as immediate user harm
- Oban critical and noncritical queues mixed
- migrations not marked in deploy timeline

43.4 Email footguns

- no provider webhook verification
- no dedupe/idempotency
- raw recipient email in metric labels
- treating opens/clicks as reliability
- ignoring bounces/complaints
- not separating transactional and marketing mail
- no password-reset/magic-link SLO

43.5 AI footguns

- AI allowed to mutate prod without approval
- arbitrary SQL tool exposed
- tool calls not audited
- MCP tool descriptions trusted blindly
- hidden prompt injection in tool output
- evidence not cited
- status update invented without facts
- long logs dumped into context window without filtering

⸻

44. Ideal generated AGENTS.md context

# ReliabilityKit context
This app is a Phoenix SaaS.
## Reliability doctrine
- Page only on urgent, actionable, user-visible or imminent user-visible harm.
- Use SLOs and error-budget burn, not random metric twitchiness.
- Metrics are low-cardinality and alertable.
- Wide events/logs are high-cardinality and investigatory.
- Traces show causal paths.
- Email deliverability is production reliability.
- Incidents prioritize mitigation before explanation.
- Prefer rollback or feature-flag disable over deep debugging during active incidents.
## Critical journeys
- signup
- login
- checkout
- payment_webhook
- transactional_email
- core_product_action
- critical_jobs
## AI safety
Allowed:
- query SLOs
- query metrics
- query logs/wide events
- inspect traces
- read runbooks
- summarize evidence
- draft postmortems
- draft status updates
Requires approval:
- rollback deploy
- disable feature flag
- pause queue
- scale workers
Blocked:
- delete data
- arbitrary SQL
- modify IAM/secrets
- disable auth
- modify billing
- send mass emails
## Evidence rules
Every factual claim must cite:
- metric query
- log/wide event
- trace ID
- deploy marker
- runbook
- provider event

⸻

45. Open-source polish checklist

Package quality

[ ] idiomatic Mix project
[ ] clear module boundaries
[ ] optional adapters
[ ] no surprise dependencies
[ ] semantic versioning
[ ] Hex metadata complete
[ ] ExDoc complete
[ ] doctests where useful
[ ] examples tested
[ ] generated artifacts snapshotted
[ ] CI matrix
[ ] release automation

Phoenix conventions

[ ] generators behave like Phoenix generators
[ ] config examples for dev/test/prod
[ ] no hard-coded app module assumptions
[ ] works with umbrella apps
[ ] works with releases
[ ] works with LiveDashboard
[ ] works with verified routes where needed

Ecto conventions

[ ] supports one or many repos
[ ] supports migrations/deploy markers
[ ] does not inspect sensitive query params by default
[ ] distinguishes queue/query/decode/total time

Oban conventions

[ ] Oban optional
[ ] supports queues/workers/attempts
[ ] retry-aware semantics
[ ] critical queue config
[ ] no page on one retry

Docs polish

[ ] "Why not just PromEx?"
[ ] "Why not just OpenTelemetry?"
[ ] "Why not just Sentry/AppSignal?"
[ ] "Metrics vs wide events vs traces"
[ ] "Low-cardinality labels"
[ ] "Solo founder SRE guide"
[ ] "Security hardening guide"
[ ] "AI/MCP safety guide"

⸻

46. Suggested package/module names

Possible package names:

reliability_kit
phoenix_reliability
sre_kit
phoenix_sre
beacon_sre
slo_kit
slo_kit_phoenix

Best practical name:

reliability_kit

Why:

* broader than Phoenix, but Phoenix-first;
* easy to explain;
* supports future Plug/Ecto/Oban/general Elixir use;
* does not imply it is only an SLO generator;
* does not imply enterprise SRE theater.

Module namespace:

ReliabilityKit
ReliabilityKit.Phoenix
ReliabilityKit.Ecto
ReliabilityKit.Oban
ReliabilityKit.Email
ReliabilityKit.SLO
ReliabilityKit.AI

⸻

47. Final product doctrine

ReliabilityKit should make the right thing the easy thing:
- classify important user journeys
- emit good metrics
- avoid cardinality explosions
- produce wide events
- generate SLO rules
- generate dashboards
- generate runbooks
- correlate deploys
- monitor email reliability
- help incidents stay calm
- help AI investigate safely
- avoid alert fatigue

The best version is not “more data.”

The best version is:

better-shaped data
fewer pages
clearer user impact
safer mitigation
faster learning

⸻

48. What to build first, concretely

The first 30 days of development should produce:

1. Core DSL.
2. Phoenix route metrics.
3. Ecto DB metrics.
4. Oban job metrics.
5. Cardinality linter.
6. API availability SLO.
7. API latency SLO.
8. Prometheus rule generation.
9. Grafana health dashboard.
10. LiveDashboard SLO page.
11. Wide request event.
12. mix reliability.doctor.
13. Example Phoenix app.
14. ExUnit helpers.
15. ExDoc quickstart.

The first public demo should show:

A Phoenix checkout route breaks after deploy.
ReliabilityKit:
  - fires checkout SLO fast burn
  - shows deploy correlation
  - shows feature flag correlation
  - shows DB/provider health
  - links the runbook
  - generates an evidence bundle
  - recommends disabling the feature flag

That demo will sell the package better than a thousand generic “observability” claims.

⸻

49. Final README pitch

# ReliabilityKit
Phoenix-native reliability for SaaS apps.
ReliabilityKit turns Phoenix, Ecto, Oban, Plug, and email/provider events into a small SRE control loop:
- critical journey SLOs
- error-budget burn alerts
- low-cardinality Prometheus metrics
- context-rich wide events
- Grafana dashboards
- LiveDashboard SRE pages
- deploy and feature-flag correlation
- email deliverability monitoring
- runbooks and incident notes
- AI-ready evidence bundles
- safety checks for cardinality, PII, dashboards, metrics endpoints, and MCP tools
It does not replace Prometheus, Grafana, OpenTelemetry, LiveDashboard, Sentry, AppSignal, or PromEx.
It makes them work together around the thing that matters:
Are users being harmed, what changed, and what should I safely do next?