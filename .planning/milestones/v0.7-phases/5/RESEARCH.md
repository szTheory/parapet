# Phase 5: Built-In Async & Delivery SLOs - Research

**Researched:** 2026-05-17
**Domain:** Elixir async and delivery SLO productization over normalized Telemetry events
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Product shape
- **D-01:** Phase 5 should be moderately opinionated: ship strong built-ins, explicit opt-in seams, and host-owned generated artifacts.
- **D-02:** Do **not** ship Phase 5 as thin primitives only. The library should provide a paved road, not just ingredients.
- **D-03:** Do **not** auto-discover or auto-enable async/delivery SLOs or alerts. Explicit host registration remains the default.
- **D-04:** Preserve the existing host-owned activation model:
  - adapters are attached explicitly;
  - providers are registered explicitly;
  - generated artifacts stay inspectable and editable in the host app.

### Built-in slice catalog
- **D-05:** Ship one explicit provider module per integration, not one broad generic delivery provider and not a maximal state-by-state matrix.
- **D-06:** The built-in provider modules for Phase 5 should be:
  - `Parapet.SLO.MailglassDelivery`
  - `Parapet.SLO.ChimewayDelivery`
  - `Parapet.SLO.RindleAsync`
- **D-07:** Each provider should expose a **small catalog** of built-in slices so the surface feels complete without becoming a provider-console clone.

### Mailglass slices
- **D-08:** `Mailglass` should ship these default slices:
  - `mailglass_submit_acceptance` — `provider_accepted / attempted`
  - `mailglass_confirmed_delivery` — `delivered / provider_accepted` when provider feedback exists
  - `mailglass_webhook_freshness` — webhook/callback delay slice
  - `mailglass_suppression_drift` — diagnostic alert slice, not a paging-budget SLO
- **D-09:** `provider_accepted` must remain distinct from `delivered`. Delivery confirmation is not the same as upstream acceptance.

### Chimeway slices
- **D-10:** `Chimeway` should ship these default slices:
  - `chimeway_provider_acceptance` — `provider_accepted / attempted`
  - `chimeway_callback_confirmation` — confirmed delivered vs confirmed failed
  - `chimeway_callback_freshness` — callback delay slice
- **D-11:** Chimeway should stay aligned with the currently proven upstream surface in this repo. Do not invent unsupported richer public semantics only to make the catalog look symmetric.

### Rindle slices
- **D-12:** `Rindle` should ship these default slices:
  - `rindle_terminal_success` — `succeeded / (succeeded + discarded)`
  - `rindle_queue_freshness` — queue age/latency slice
  - `rindle_callback_freshness` — external callback or reconciliation delay slice
  - `rindle_long_running_stage` — diagnostic alert slice by `pipeline_stage`, not a default paging SLO
  - `rindle_funnel_regression` — diagnostic recording or alert slice using stage counts, not a default page
- **D-13:** `retryable_failed` is not a paging symptom by default. Treat it as noise unless paired with sustained backlog or callback burn.
- **D-14:** `discarded` is the terminal, user-harming async failure state for default alerting purposes.
- **D-15:** Queue freshness should be based on delay or age, not raw depth alone. Raw depth may be recorded, but it is not the primary operator signal.

### Alert semantics
- **D-16:** Use a plane-specific, terminality-aware alert taxonomy rather than a generic burn-rate-only model.
- **D-17:** Page on user-harming or terminal symptoms:
  - `discarded` async work burn
  - sustained delivery failure that impacts the user-facing slice
  - sustained callback/webhook delay beyond tolerated freshness
  - sustained queue freshness burn that indicates real backlog harm
- **D-18:** Ticket on sustained but not yet urgent degradation:
  - suppression drift
  - provider acceptance shortfall
  - callback delay that is degrading but not yet clearly user-harming
  - backlog growth that is notable but not yet page-worthy
- **D-19:** Keep normal retries and single transient provider failures at warning or muted-by-default severity. They should not page humans by default.
- **D-20:** Generated alerts should group on bounded operator labels such as:
  - `alertname`
  - `integration`
  - `fault_plane`
  - coarse `queue`, `channel`, or `pipeline_stage` when relevant
- **D-21:** Phase 5 generated alerts should assume Alertmanager-style inhibition and grouping:
  - symptom pages suppress lower-level cause alerts
  - warning does not route like page
- **D-22:** Add `for` durations and minimum-volume guards to generated alerts so transient spikes and low-volume noise do not create false pages.

### API and artifact shape
- **D-23:** Keep `Parapet.attach(adapters: [...])` as the integration activation seam. Do not overload attachment with silent SLO activation.
- **D-24:** Register built-in SLO providers explicitly through configuration, for example:
  - `config :parapet, providers: [...]`
- **D-25:** Prefer provider modules and behaviour callbacks over legacy `register/1` mutation APIs as the long-term Phase 5 direction.
- **D-26:** Split responsibilities clearly:
  - integration adapters normalize bounded telemetry events;
  - metrics modules define Telemetry metrics and selectors;
  - provider modules declare built-in slices and alert metadata;
  - generators render host-owned Prometheus artifacts.
- **D-27:** `mix parapet.gen.prometheus` should generate artifacts from active providers only.
- **D-28:** Prefer separate host-owned artifact files for recording rules and alerts over one opaque mixed output if the implementation cost is reasonable.
- **D-29:** Built-ins may use an internal bounded slice spec rather than raw arbitrary PromQL everywhere. The generator should own most of the PromQL shape for shipped defaults.
- **D-30:** Keep one escape hatch for advanced custom providers, but do not optimize the default API around arbitrary raw PromQL strings.

### Metrics and label policy
- **D-31:** Continue treating metrics safety as a non-negotiable. New Phase 5 metrics must preserve the low-cardinality contract from Phase 4.
- **D-32:** Do not emit `message_id`, `job_id`, `recipient`, `webhook_id`, provider request IDs, or similar exact identifiers into labels.
- **D-33:** Prefer Prometheus-native naming and units for new metrics:
  - counters end in `_total`
  - durations should move toward base-unit `_seconds`
  - ratios should stay interpretable as `0..1`
- **D-34:** Shared label shapes across provider modules matter for coherent generated artifacts and least-surprise DX.

### GSD decision policy
- **D-35:** Shift routine implementation decisions left within GSD for this phase and later related work. Downstream agents should make coherent recommendations by default instead of escalating every gray area.
- **D-36:** Only escalate decisions that have real product, operator, or API blast radius:
  - public API naming that is hard to change
  - materially different operator alert semantics
  - changes that threaten low-cardinality or host-owned design constraints
  - anything that meaningfully broadens or narrows scope
- **D-37:** For ordinary implementation details, the preferred default is:
  - follow repo patterns;
  - preserve least surprise;
  - prefer explicit over magical;
  - optimize for operator-grade DX.

### Claude's Discretion
- **D-38:** Exact internal module names for metrics helpers, slice structs, template helpers, and provider plumbing.
- **D-39:** Exact `for` durations, burn windows, and traffic gates, as long as they follow the symptom-first and retry-aware rules above.
- **D-40:** Whether Phase 5 keeps short-term compatibility with legacy registration helpers while moving the blessed path to provider modules.
- **D-41:** Exact Prometheus file split and template layout, as long as generated artifacts stay host-owned and inspectable.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Auto-discovered provider registration or hidden auto-enabled alerts.
- Provider-console-style exhaustive state matrices and forensic dashboards.
- Exact-item alerting as a primary Phase 5 model rather than a later durable evidence or action-item concern.
- Final incident enrichment schema and operator workbench classification details — Phase 6.
- Recovery actions, retries, replay UX, and runbook command contracts — Phase 7.
- Broad autonomous remediation or opaque operational magic.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DELV-02 | System expands `Mailglass` integration to emit low-cardinality SLIs for outbound submit success, webhook ingest health, suppression drift, and delivery failure classes. | `## Summary`, `## Standard Stack`, `## Architecture Patterns`, `## Common Pitfalls` |
| DELV-03 | System expands `Chimeway` integration to emit low-cardinality SLIs for provider acceptance, callback-confirmed delivery or failure, and callback delay where the sibling telemetry contract supports it. | `## Summary`, `## Architecture Patterns`, `## Code Examples`, `## Common Pitfalls` |
| ASYNC-01 | System expands `Rindle` integration to emit low-cardinality SLIs for queue backlog, queue age, long-running work, discard visibility, and async funnel regressions. | `## Summary`, `## Architecture Patterns`, `## Standard Stack`, `## Code Examples` |
| ASYNC-02 | System distinguishes retryable async failures from exhausted or discarded work so generated alerts page on user-harming failure instead of normal retry noise. | `## Summary`, `## Architecture Patterns`, `## Common Pitfalls`, `## Validation Architecture` |
| ASYNC-03 | System detects webhook or reconciliation delay separately from internal queue backlog so operators can identify the failing plane without inspecting raw logs first. | `## Summary`, `## Architecture Patterns`, `## Don't Hand-Roll`, `## Validation Architecture` |
</phase_requirements>

## Summary

Phase 5 should not add a new async subsystem; it should productize the Phase 4 normalized event layer that already exists in [`lib/parapet/telemetry/async_delivery.ex`](/Users/jon/projects/parapet/lib/parapet/telemetry/async_delivery.ex), the three adapter seams under `lib/parapet/integrations/`, and the provider aggregation seam in [`lib/parapet/slo.ex`](/Users/jon/projects/parapet/lib/parapet/slo.ex). [VERIFIED: docs/telemetry.md][VERIFIED: lib/parapet/telemetry/async_delivery.ex][VERIFIED: lib/parapet/integrations/mailglass.ex][VERIFIED: lib/parapet/integrations/chimeway.ex][VERIFIED: lib/parapet/integrations/rindle.ex][VERIFIED: lib/parapet/slo.ex]

The repo is already pointing at the right direction: `Parapet.SLO.Provider` exists, `Parapet.SLO.all/0` already merges configured providers with legacy env-backed SLOs, and the adapters already distinguish `provider_accepted` from `delivered`, `retryable_failed` from `discarded`, and `backlog` from `callback`. The missing piece is a bounded slice spec plus metrics and generator support that let Phase 5 derive provider-backed Prometheus artifacts from those normalized semantics instead of from arbitrary raw PromQL strings. [VERIFIED: lib/parapet/slo/provider.ex][VERIFIED: lib/parapet/slo.ex][VERIFIED: test/parapet/integrations/mailglass_test.exs][VERIFIED: test/parapet/integrations/chimeway_test.exs][VERIFIED: test/parapet/integrations/rindle_test.exs]

Primary sources reinforce the locked decisions. Telemetry documents `attach_many/4`, `span/3`, and automatic handler detachment on failure, which means Phase 5 should continue to treat handler safety and explicit attachment as first-class concerns. Telemetry.Metrics documents that tags come from event metadata and every unique tag set creates separate aggregations, which matches Parapet's strict label policy. Oban's lifecycle still distinguishes `retryable` from `discarded`, matching the user-harm rule for async alerting. Prometheus docs still recommend base-unit metric names, `_total` suffixes for counters, `for` and `keep_firing_for` to damp noise, and bounded Alertmanager grouping and inhibition. [CITED: https://hexdocs.pm/telemetry/telemetry.html][CITED: https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://prometheus.io/docs/practices/naming/][CITED: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/][CITED: https://prometheus.io/docs/alerting/latest/alertmanager/]

**Primary recommendation:** implement Phase 5 as three explicit provider modules over shared normalized metric families, move the Prometheus generator to provider-owned slice specs rather than legacy `register/1` state, and ship symptom-first alert templates that page only on terminal delivery failure, discarded async work, or sustained freshness loss. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md][VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex][VERIFIED: priv/templates/parapet.gen.prometheus/rules.yml.eex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Normalized async and delivery event emission | API / Backend | — | The adapter modules under `lib/parapet/integrations/` are the authoritative seam for sibling telemetry translation. [VERIFIED: lib/parapet/integrations/mailglass.ex][VERIFIED: lib/parapet/integrations/chimeway.ex][VERIFIED: lib/parapet/integrations/rindle.ex] |
| Metric family definitions and label allowlists | API / Backend | — | Telemetry.Metrics definitions and label policy enforcement live in library code and act before Prometheus ingestion. [VERIFIED: lib/parapet/internal/label_policy.ex][VERIFIED: lib/parapet/metrics/oban.ex][CITED: https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html] |
| Built-in provider slice catalog | API / Backend | — | Provider registration already happens through `config :parapet, providers: [...]` and `Parapet.SLO.Provider`. [VERIFIED: lib/parapet/slo/provider.ex][VERIFIED: lib/parapet/slo.ex] |
| Prometheus rule rendering | API / Backend | CDN / Static | Mix tasks and EEx templates generate host-owned rule files; Prometheus and Alertmanager consume them later as static config. [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex][VERIFIED: priv/templates/parapet.gen.prometheus/rules.yml.eex] |
| Alert grouping and inhibition behavior | API / Backend | External dependency | Prometheus emits alerts, while Alertmanager owns deduplication, grouping, routing, and inhibition. [CITED: https://prometheus.io/docs/alerting/latest/alertmanager/][CITED: https://prometheus.io/docs/alerting/latest/configuration/] |
| Incident enrichment and operator classification | API / Backend | Frontend Server (SSR) | Phase 5 should only emit bounded labels and annotations for later ingestion; durable classification belongs to the Phase 6 incident path. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | Repo constraint `~> 1.2`; lockfile `1.4.1`; current Hex `1.4.2` published 2026-05-11. [VERIFIED: mix.exs][VERIFIED: mix.lock][CITED: https://hex.pm/packages/telemetry] | Event attachment, `attach_many/4`, failure handling, and `span/3` semantics. [CITED: https://hexdocs.pm/telemetry/telemetry.html] | Phase 5 consumes the normalized Telemetry contract rather than sibling libraries directly. [VERIFIED: docs/telemetry.md][VERIFIED: lib/parapet/telemetry/async_delivery.ex] |
| `:telemetry_metrics` | Repo constraint `~> 1.0`; lockfile `1.1.0`; current Hex `1.1.0` published 2025-01-24. [VERIFIED: mix.exs][VERIFIED: mix.lock][CITED: https://hex.pm/packages/telemetry_metrics] | Counter, distribution, and tag definitions for low-cardinality metric families. [CITED: https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html] | Existing metrics modules already use this API, so Phase 5 should extend it rather than invent a new metrics DSL. [VERIFIED: lib/parapet/metrics/http.ex][VERIFIED: lib/parapet/metrics/oban.ex][VERIFIED: lib/parapet/metrics/scoria.ex] |
| `:oban` | Repo optional dep `>= 0.0.0`; lockfile `2.22.1`; current Hex `2.22.1` published 2026-04-30. [VERIFIED: mix.exs][VERIFIED: mix.lock][CITED: https://hex.pm/packages/oban] | Canonical async lifecycle vocabulary for `retryable` versus `discarded`. [CITED: https://hexdocs.pm/oban/job_lifecycle.html] | Phase 5's async alert semantics intentionally mirror Oban terminality semantics. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md][VERIFIED: test/parapet/integrations/rindle_test.exs] |
| Prometheus / Alertmanager config model | `promtool` `3.11.3` locally; docs current as of 2026-05-17. [VERIFIED: local command][CITED: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/][CITED: https://prometheus.io/docs/alerting/latest/configuration/] | Rule syntax, validation, alert `for`, `keep_firing_for`, grouping, and inhibition. [CITED: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/][CITED: https://prometheus.io/docs/alerting/latest/alertmanager/] | The generator already emits Prometheus YAML and the test suite already validates with `promtool` when available. [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex][VERIFIED: test/mix/tasks/parapet.gen.prometheus_test.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Parapet.SLO.Provider` | In-repo seam. [VERIFIED: lib/parapet/slo/provider.ex] | Explicit provider registration contract. [VERIFIED: lib/parapet/slo/provider.ex] | Use for all new Phase 5 built-ins; do not add new `register/1`-only flows. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| `Parapet.SLO.Resolvable` | In-repo seam. [VERIFIED: lib/parapet/slo/resolvable.ex] | Converts provider-owned structs into `Parapet.SLO` output or future generator inputs. [VERIFIED: lib/parapet/slo/resolvable.ex] | Use for a bounded slice-spec struct so the generator can own PromQL shape. [VERIFIED: lib/parapet/slo.ex][VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| `Parapet.Internal.LabelPolicy` | In-repo guardrail. [VERIFIED: lib/parapet/internal/label_policy.ex] | Rejects unsupported or high-cardinality labels. [VERIFIED: lib/parapet/internal/label_policy.ex] | Extend with Phase 5 family-specific allowlists; do not bypass per-provider. [VERIFIED: test/parapet/internal/label_policy_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared normalized metric families filtered by `integration` | Separate metric namespaces per provider | Rejected because Prometheus recommends consistent naming and shared label meanings, and the repo already normalized the event vocabulary in Phase 4. [CITED: https://prometheus.io/docs/practices/naming/][VERIFIED: docs/telemetry.md] |
| Bounded slice spec rendered by the generator | Raw PromQL strings embedded in every provider | Rejected by locked decision D-29 because it would make shipped defaults opaque and harder to keep coherent across providers. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| Provider modules only for Phase 5 built-ins, legacy `register/1` retained short-term for older slices | Hard cutover removing env-backed SLOs immediately | Rejected because current `SLO.all/0` and tests still depend on mixed legacy and provider state. [VERIFIED: lib/parapet/slo.ex][VERIFIED: test/parapet/slo_test.exs] |

**Installation:**

```bash
mix deps.get
```

No new Hex dependency is required to execute Phase 5; the repo already contains Telemetry, Telemetry.Metrics, Oban, Mix tasks, and tests needed for the phase. [VERIFIED: mix.exs][VERIFIED: mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Mailglass / Chimeway / Rindle upstream telemetry
  -> explicit adapter setup via Parapet.attach(adapters: [...])
  -> normalized Parapet event families
     -> [:parapet, :delivery, :outbound]
     -> [:parapet, :delivery, :provider_feedback]
     -> [:parapet, :delivery, :webhook_ingest]
     -> [:parapet, :async, :stage]
     -> [:parapet, :async, :backlog]
     -> [:parapet, :async, :callback]
  -> shared Telemetry.Metrics families with bounded tags
  -> provider modules declare slice specs
     -> MailglassDelivery
     -> ChimewayDelivery
     -> RindleAsync
  -> generator renders recording rules + alert rules
  -> Prometheus evaluates
  -> Alertmanager groups / inhibits / routes
  -> Phase 6 consumes bounded labels and annotations
```

### Recommended Project Structure

```text
lib/parapet/
├── metrics/
│   ├── async_delivery.ex     # shared metric helpers or family builders
│   ├── mailglass.ex          # Mailglass metric entrypoint
│   ├── chimeway.ex           # Chimeway metric entrypoint
│   └── rindle.ex             # Rindle metric entrypoint
├── slo/
│   ├── slice_spec.ex         # bounded provider-owned slice spec
│   ├── mailglass_delivery.ex # provider module
│   ├── chimeway_delivery.ex  # provider module
│   ├── rindle_async.ex       # provider module
│   └── generator.ex          # renders recording and alert rules from slice specs
└── internal/
    └── label_policy.ex       # shared allowlists for normalized metric families

priv/templates/parapet.gen.prometheus/
├── recording_rules.yml.eex
└── alerts.yml.eex
```

This structure keeps the existing repo split in D-26: adapters emit events, metrics define selectors, providers declare slices, and generators render artifacts. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

### Pattern 1: Use Shared Metric Families With Stable Label Shapes

**What:** define one normalized metric family per event family and keep label sets fixed per family, then filter by `integration` inside provider rules instead of inventing provider-specific metric names. [VERIFIED: docs/telemetry.md][CITED: https://prometheus.io/docs/practices/naming/]

**When to use:** all Phase 5 counters and delay distributions for Mailglass, Chimeway, and Rindle. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**Recommended families:**

| Metric | Type | Event | Tags |
|--------|------|-------|------|
| `parapet_delivery_outbound_total` | counter | `[:parapet, :delivery, :outbound]` | `integration`, `provider`, `channel`, `outcome`, `fault_plane` |
| `parapet_delivery_provider_feedback_total` | counter | `[:parapet, :delivery, :provider_feedback]` | `integration`, `provider`, `channel`, `outcome`, `fault_plane`, `failure_class` |
| `parapet_delivery_webhook_ingest_total` | counter | `[:parapet, :delivery, :webhook_ingest]` | `integration`, `provider`, `channel`, `outcome`, `fault_plane`, `delay_bucket`, `failure_class` |
| `parapet_delivery_webhook_ingest_delay_seconds` | distribution | `[:parapet, :delivery, :webhook_ingest]` | `integration`, `provider`, `channel`, `fault_plane` |
| `parapet_async_stage_total` | counter | `[:parapet, :async, :stage]` | `integration`, `provider`, `queue`, `pipeline_stage`, `outcome`, `retry_state`, `fault_plane` |
| `parapet_async_stage_duration_seconds` | distribution | `[:parapet, :async, :stage]` | `integration`, `provider`, `queue`, `pipeline_stage`, `outcome`, `retry_state`, `fault_plane` |
| `parapet_async_backlog_total` | counter | `[:parapet, :async, :backlog]` | `integration`, `provider`, `queue`, `outcome`, `delay_bucket`, `fault_plane` |
| `parapet_async_backlog_delay_seconds` | distribution | `[:parapet, :async, :backlog]` | `integration`, `provider`, `queue`, `fault_plane` |
| `parapet_async_callback_total` | counter | `[:parapet, :async, :callback]` | `integration`, `provider`, `queue`, `pipeline_stage`, `outcome`, `delay_bucket`, `fault_plane` |
| `parapet_async_callback_delay_seconds` | distribution | `[:parapet, :async, :callback]` | `integration`, `provider`, `queue`, `pipeline_stage`, `fault_plane` |

These names align with Prometheus guidance: counters end in `_total`, durations move to `_seconds`, and ratios should be computed in rules rather than emitted as raw percentages. [CITED: https://prometheus.io/docs/practices/naming/]

### Pattern 2: Make Providers Return Slice Specs, Not Raw Strings

**What:** add a small internal struct such as `Parapet.SLO.SliceSpec` and let each Phase 5 provider return a catalog of slices with bounded fields like `:kind`, `:metric`, `:good_matchers`, `:bad_matchers`, `:objective`, `:alert_class`, `:runbook`, and `:group_labels`. The generator should turn those specs into recording and alert rules. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md][VERIFIED: lib/parapet/slo/resolvable.ex]

**When to use:** all new built-in Mailglass, Chimeway, and Rindle slices. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**Concrete provider shape:**

```elixir
defmodule Parapet.SLO.MailglassDelivery do
  @behaviour Parapet.SLO.Provider

  def slos do
    [
      %Parapet.SLO.SliceSpec{
        name: :mailglass_submit_acceptance,
        integration: :mailglass,
        kind: :ratio,
        source_metric: :parapet_delivery_provider_feedback_total,
        good_matchers: [outcome: :provider_accepted],
        total_matchers: [outcome: [:attempted, :provider_accepted, :failed]],
        labels: [provider: :*, channel: :email, fault_plane: :provider],
        objective: 99.0,
        alert_class: :ticketable_acceptance,
        runbook: "https://example.com/runbooks/mailglass-submit-acceptance"
      },
      %Parapet.SLO.SliceSpec{
        name: :mailglass_webhook_freshness,
        integration: :mailglass,
        kind: :freshness,
        source_metric: :parapet_delivery_webhook_ingest_total,
        good_matchers: [delay_bucket: [:subsecond, :under_30s, :under_5m]],
        total_matchers: [outcome: [:delivered, :failed]],
        labels: [provider: :*, channel: :email, fault_plane: :webhook],
        objective: 99.0,
        alert_class: :pageable_freshness,
        runbook: "https://example.com/runbooks/mailglass-webhook-freshness"
      }
    ]
  end
end
```

This preserves explicit provider modules while moving PromQL construction into the generator, which is the locked direction. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

### Pattern 3: Split Recording Rules From Alerts

**What:** generate `recording_rules.yml` and `alerts.yml` separately unless implementation friction is disproportionate. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**When to use:** the evolved `mix parapet.gen.prometheus` flow. [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex]

**Why:** the current template mixes ratio recordings and alerts in one opaque file and is generic to `Parapet.SLO` only. Splitting the files will let Phase 5 ship provider-backed recordings, diagnostic recordings, and terminality-aware alerts without making the template unreadable. [VERIFIED: priv/templates/parapet.gen.prometheus/rules.yml.eex]

### Anti-Patterns to Avoid

- **Mega-metric with optional tags:** one metric carrying `failure_class`, `delay_bucket`, `queue`, and `pipeline_stage` for every event would create sparse or incoherent series and violate D-34. Use one stable tag set per event family instead. [VERIFIED: docs/telemetry.md][CITED: https://prometheus.io/docs/practices/naming/]
- **Raw PromQL as the primary provider API:** this would reintroduce thin primitives and make shipped defaults hard to keep aligned. Keep one escape hatch, but make the built-in path data-first. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]
- **Generator reading all legacy env SLOs by default:** D-27 says Prometheus artifacts should come from active providers only, while `SLO.all/0` still merges legacy state. Phase 5 should introduce a provider-only path for generation. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md][VERIFIED: lib/parapet/slo.ex][VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex]
- **Paging on `retryable_failed`:** Oban semantics and the locked decisions both say retryable work is not terminal by default. Page on `discarded`, not on retries. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md][CITED: https://hexdocs.pm/oban/job_lifecycle.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-provider alert semantics | Three unrelated raw-PromQL modules | One bounded slice-spec struct plus generator helpers | The generator already owns host-owned YAML generation, and Prometheus recording rule naming is easier to keep coherent from one renderer. [VERIFIED: lib/parapet/slo/generator.ex][VERIFIED: priv/templates/parapet.gen.prometheus/rules.yml.eex][CITED: https://prometheus.io/docs/practices/rules/] |
| Alert flapping suppression | Ad hoc Elixir-side cool-down logic | Prometheus `for` / `keep_firing_for` plus Alertmanager grouping and inhibition | Those are native features built for this problem and already part of the current deployment model. [CITED: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/][CITED: https://prometheus.io/docs/alerting/latest/alertmanager/] |
| Retry/noise classification | Provider-specific boolean flags scattered through templates | Oban-style terminality categories plus bounded `alert_class` on slice specs | The repo already normalized `retryable_failed` and `discarded`; duplicating this logic in multiple templates will drift. [VERIFIED: lib/parapet/telemetry/async_delivery.ex][VERIFIED: test/parapet/integrations/rindle_test.exs][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Provider-specific metric labels | Special-case reporter code for each provider | Shared label policy helpers over normalized event families | Telemetry.Metrics tags come from metadata, and shared label policies keep cardinality coherent. [VERIFIED: lib/parapet/internal/label_policy.ex][CITED: https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html] |

**Key insight:** the repo already paid for the hard abstraction boundary in Phase 4; Phase 5 should consume that boundary, not tunnel around it with per-provider shortcuts. [VERIFIED: docs/telemetry.md][VERIFIED: .planning/v0.7-phases/4/RESEARCH.md]

## Common Pitfalls

### Pitfall 1: Treating `provider_accepted` as delivered

**What goes wrong:** Mailglass and Chimeway alert as healthy when the provider accepted a send but no callback-confirmed delivery exists. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**Why it happens:** generic success/failure SLO templates collapse acceptance and confirmation into one numerator. [VERIFIED: docs/slo-reference.md][VERIFIED: priv/templates/parapet.gen.prometheus/rules.yml.eex]

**How to avoid:** make `mailglass_submit_acceptance` and `mailglass_confirmed_delivery` separate slices, and keep Chimeway acceptance separate from callback confirmation. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**Warning signs:** rules only reference `attempted` and `failed`, or there is no provider-feedback selector in delivery slices. [VERIFIED: lib/parapet/telemetry/async_delivery.ex]

### Pitfall 2: Paging on retry noise

**What goes wrong:** Rindle pages on normal retries and trains operators to ignore async alerts. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**Why it happens:** templates use failure-count ratios without terminality awareness. [VERIFIED: priv/templates/parapet.gen.prometheus/rules.yml.eex]

**How to avoid:** page on `discarded` burn and sustained backlog or callback freshness burn, but keep `retryable_failed` at warning or diagnostic level. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md][CITED: https://hexdocs.pm/oban/job_lifecycle.html]

**Warning signs:** alert expressions match `outcome=~"retryable_failed|discarded"` or do not test `retry_state`. [VERIFIED: docs/telemetry.md]

### Pitfall 3: Conflating webhook delay with queue backlog

**What goes wrong:** operators cannot tell whether the provider plane is slow or the internal executor is backlogged. [VERIFIED: .planning/ROADMAP.md][VERIFIED: .planning/REQUIREMENTS.md]

**Why it happens:** one delay metric or one alert family is used for both `:backlog` and `:callback`. [VERIFIED: docs/telemetry.md]

**How to avoid:** keep separate delay metrics and separate freshness slices for `parapet_async_backlog_*` and `parapet_async_callback_*`, and separate delivery webhook freshness from provider failure counts. [VERIFIED: docs/telemetry.md][VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**Warning signs:** rule labels omit `fault_plane`, or the generator groups both delay alerts under one shared alertname. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

### Pitfall 4: Letting provider modules bypass shared label policy

**What goes wrong:** a provider sneaks `message_id`, `job_id`, or `webhook_id` into tags and explodes series cardinality. [VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: docs/telemetry.md]

**Why it happens:** providers construct Telemetry.Metrics tags directly without family-specific validation. [VERIFIED: lib/parapet/internal/label_policy.ex]

**How to avoid:** have metrics helpers call `LabelPolicy.assert_family_keys!/2` for every shared family and never derive tags from `refs`. [VERIFIED: lib/parapet/internal/label_policy.ex][VERIFIED: test/parapet/internal/label_policy_test.exs]

**Warning signs:** metrics tags contain `_id`, `recipient`, or provider request identifiers. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

## Code Examples

Verified patterns from official sources and current repo seams:

### Attach Related Events With One Handler

```elixir
# Source: https://hexdocs.pm/telemetry/telemetry.html
:telemetry.attach_many(
  "parapet-mailglass-delivery",
  [
    [:mailglass, :outbound, :send, :stop],
    [:mailglass, :reconcile, :stop],
    [:mailglass, :webhook, :ingest, :exception]
  ],
  &Parapet.Integrations.Mailglass.handle_event/4,
  nil
)
```

This matches both Telemetry guidance and the current Mailglass/Rindle adapter style. [CITED: https://hexdocs.pm/telemetry/telemetry.html][VERIFIED: lib/parapet/integrations/mailglass.ex][VERIFIED: lib/parapet/integrations/rindle.ex]

### Define Low-Cardinality Metrics From Event Metadata Tags

```elixir
# Source: https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html
import Telemetry.Metrics

[
  counter("parapet_delivery_provider_feedback_total",
    event_name: [:parapet, :delivery, :provider_feedback],
    tags: [:integration, :provider, :channel, :outcome, :fault_plane, :failure_class]
  ),
  distribution("parapet_delivery_webhook_ingest_delay_seconds",
    event_name: [:parapet, :delivery, :webhook_ingest],
    measurement: :delay_seconds,
    tags: [:integration, :provider, :channel, :fault_plane],
    reporter_options: [buckets: [1, 5, 30, 60, 300, 1800, 3600]]
  )
]
```

This uses the same Telemetry.Metrics API the repo already uses for HTTP, Oban, Probe, and Scoria. [CITED: https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html][VERIFIED: lib/parapet/metrics/http.ex][VERIFIED: lib/parapet/metrics/oban.ex][VERIFIED: lib/parapet/metrics/probe.ex][VERIFIED: lib/parapet/metrics/scoria.ex]

### Express Alert Damping With Native Prometheus Fields

```yaml
# Source: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
- alert: RindleQueueFreshnessPage
  expr: parapet:rindle_queue_freshness:ratio5m > 0.10
  for: 10m
  keep_firing_for: 5m
  labels:
    severity: page
    integration: rindle
    fault_plane: backlog
  annotations:
    summary: Sustained Rindle queue freshness burn
```

Prometheus documents `for` for pending time and `keep_firing_for` for flap damping, which is the right place to handle transient noise. [CITED: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Env-backed `register/1` helpers store raw `Parapet.SLO` structs in `:parapet, :slos` | Explicit provider modules aggregated through `config :parapet, providers: [...]` and `Parapet.SLO.Provider` | Already present in repo before 2026-05-17. [VERIFIED: lib/parapet/slo.ex][VERIFIED: lib/parapet/slo/provider.ex] | Phase 5 should extend the provider path and keep legacy flows only as compatibility, not as the blessed API. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| Generic burn-rate template over arbitrary `good_events` / `total_events` strings | Provider-backed slice specs rendered into ratio, freshness, and diagnostic rule families | Required by Phase 5 locked decisions on 2026-05-17. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] | Enables plane-specific alerts without teaching every adopter raw PromQL. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| Mixed `*_milliseconds*` and dotted metric names in existing repo metrics | Prometheus-native `_seconds` and `_total` names for new Phase 5 families | Recommended by current Prometheus naming guidance and locked decision D-33. [CITED: https://prometheus.io/docs/practices/naming/][VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] | New Phase 5 metrics should move to base units even if older metrics stay as compatibility baggage. [CITED: https://prometheus.io/docs/practices/naming/] |

**Deprecated/outdated:**

- Adding more `register/1`-style built-ins for new async or delivery slices is outdated for Phase 5 because the repo already has a provider seam and the context locks provider modules as the long-term path. [VERIFIED: lib/parapet/slo/http.ex][VERIFIED: lib/parapet/slo/login_journey.ex][VERIFIED: lib/parapet/slo/oban.ex][VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]
- One mixed `rules.yml` template is now a weak fit for provider-backed alert taxonomies because it couples generic recordings and alerts too tightly. [VERIFIED: priv/templates/parapet.gen.prometheus/rules.yml.eex][VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `delay_ms` values can be converted to `delay_seconds` in new metrics without breaking any installed reporter expectations because no existing tests assert a delay distribution metric name yet. [ASSUMED] | `## Architecture Patterns` | Low to medium; if a hidden reporter already depends on millisecond names, Phase 5 needs a compatibility alias. |
| A2 | The cleanest provider-only generator seam is a new `Parapet.SLO.provider_slos/0` or equivalent rather than changing `SLO.all/0` semantics. [ASSUMED] | `## Summary` | Medium; if downstream code expects `SLO.all/0` for all call sites, planner should schedule a narrow compatibility design first. |

## Open Questions (RESOLVED)

1. **Should Phase 5 emit dual unit metrics for compatibility or only new `_seconds` families?**
   - What we know: Prometheus recommends base units, and D-33 explicitly prefers `_seconds`. Existing repo metrics still use dotted names and millisecond suffixes. [CITED: https://prometheus.io/docs/practices/naming/][VERIFIED: lib/parapet/metrics/http.ex][VERIFIED: lib/parapet/metrics/probe.ex]
   - What's unclear: whether any external dashboard or reporter already depends on millisecond naming for async/delivery metrics. [ASSUMED]
   - Recommendation: generate only the new `_seconds` Phase 5 families and keep older naming untouched outside this phase unless a compatibility consumer is discovered during implementation. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]
   - **Resolution:** Phase 5 will emit only the new `_seconds` families for new async/delivery metrics and will not add dual-unit compatibility metrics by default. If execution uncovers a concrete downstream dependency, that will be handled as a targeted compatibility follow-up rather than broadening this phase.

2. **How much of suppression drift should be an SLO versus a pure diagnostic alert family?**
   - What we know: D-08 explicitly calls `mailglass_suppression_drift` a diagnostic alert slice, not a paging-budget SLO. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]
   - What's unclear: whether the provider slice spec should model diagnostic-only slices in the same struct or a sibling struct. [ASSUMED]
   - Recommendation: keep one slice-spec type with an `alert_class` or `budgeted?` field so the generator can render diagnostic-only alerts without inventing a second provider API. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]
   - **Resolution:** Phase 5 will model suppression drift in the same bounded slice-spec type as budgeted slices, using explicit metadata such as `alert_class` and `budgeted?` so the generator can render it as diagnostic or ticket-grade without introducing a second provider API.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | compiling and running Phase 5 tests | ✓ | `1.19.5` | — |
| Mix | running generator and test commands | ✓ | `1.19.5` | — |
| `promtool` | validating generated Prometheus rules | ✓ | `3.11.3` | test suite already skips promtool-specific checks when absent |
| Oban dep in repo | async terminology and optional local compilation path | ✓ | `2.22.1` in lockfile | Phase 5 tests can still exercise normalized Rindle events without starting Oban |

**Missing dependencies with no fallback:**

- None. [VERIFIED: local command]

**Missing dependencies with fallback:**

- None in the current environment. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: mix.exs][VERIFIED: local command] |
| Config file | none; repo uses standard Mix/ExUnit layout. [VERIFIED: mix.exs][VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/parapet/telemetry/async_delivery_test.exs test/parapet/internal/label_policy_test.exs test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs test/parapet/integrations/rindle_test.exs test/parapet/slo_test.exs test/mix/tasks/parapet.gen.prometheus_test.exs` [VERIFIED: test file inventory] |
| Full suite command | `mix test` [VERIFIED: test file inventory] |

### Implementation Split

| Plan | Scope | Verification |
|------|-------|--------------|
| Plan A | Add shared async/delivery metric families, helper modules, and label-policy assertions for the six normalized event families. [VERIFIED: docs/telemetry.md][VERIFIED: lib/parapet/internal/label_policy.ex] | Run the quick command subset for `async_delivery`, `label_policy`, and the three integration tests. [VERIFIED: test/parapet/telemetry/async_delivery_test.exs][VERIFIED: test/parapet/internal/label_policy_test.exs][VERIFIED: test/parapet/integrations/mailglass_test.exs][VERIFIED: test/parapet/integrations/chimeway_test.exs][VERIFIED: test/parapet/integrations/rindle_test.exs] |
| Plan B | Introduce provider slice specs plus `Parapet.SLO.MailglassDelivery`, `Parapet.SLO.ChimewayDelivery`, and `Parapet.SLO.RindleAsync`, with a provider-only generator input path that preserves legacy compatibility elsewhere. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md][VERIFIED: lib/parapet/slo.ex][VERIFIED: lib/parapet/slo/provider.ex] | Add or update `test/parapet/slo_test.exs` to cover provider-only aggregation and legacy coexistence, then run the SLO and integration subset. [VERIFIED: test/parapet/slo_test.exs] |
| Plan C | Evolve `mix parapet.gen.prometheus` into provider-backed recording and alert file generation with symptom-first alert taxonomy, volume gates, `for`, and optional `keep_firing_for`. [VERIFIED: lib/mix/tasks/parapet.gen.prometheus.ex][VERIFIED: priv/templates/parapet.gen.prometheus/rules.yml.eex][CITED: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/] | Run `mix test test/mix/tasks/parapet.gen.prometheus_test.exs test/parapet/slo_test.exs` and validate generated files with `promtool check rules`. [VERIFIED: test/mix/tasks/parapet.gen.prometheus_test.exs][VERIFIED: local command] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DELV-02 | Mailglass submit, feedback, webhook, and suppression slices stay bounded and provider-aware | unit | `mix test test/parapet/integrations/mailglass_test.exs test/mix/tasks/parapet.gen.prometheus_test.exs` | ✅ |
| DELV-03 | Chimeway accepts only the proven upstream surface and separates callback delay from provider failure | unit | `mix test test/parapet/integrations/chimeway_test.exs test/mix/tasks/parapet.gen.prometheus_test.exs` | ✅ |
| ASYNC-01 | Rindle exposes stage, backlog, callback, discard, and funnel-oriented slice inputs | unit | `mix test test/parapet/integrations/rindle_test.exs test/mix/tasks/parapet.gen.prometheus_test.exs` | ✅ |
| ASYNC-02 | Retryable failures remain non-pageable while discarded work becomes terminal | unit | `mix test test/parapet/integrations/rindle_test.exs test/parapet/slo_test.exs` | ✅ |
| ASYNC-03 | Callback delay and queue backlog render as distinct metrics and generated alerts | unit | `mix test test/parapet/integrations/rindle_test.exs test/parapet/integrations/chimeway_test.exs test/mix/tasks/parapet.gen.prometheus_test.exs` | ✅ |

### Sampling Rate

- **Per task commit:** run the quick command subset plus `promtool check rules` on generated artifacts. [VERIFIED: local command][VERIFIED: test/mix/tasks/parapet.gen.prometheus_test.exs]
- **Per wave merge:** run `mix test`. [VERIFIED: test file inventory]
- **Phase gate:** full suite green and generated Prometheus files validated by `promtool` before `/gsd-verify-work`. [VERIFIED: local command][VERIFIED: test/mix/tasks/parapet.gen.prometheus_test.exs]

### Wave 0 Gaps

- [ ] `test/parapet/metrics/mailglass_test.exs` — verifies shared metric family definitions and tag shapes for Mailglass. [VERIFIED: current test inventory]
- [ ] `test/parapet/metrics/chimeway_test.exs` — verifies provider feedback and webhook freshness metric definitions. [VERIFIED: current test inventory]
- [ ] `test/parapet/metrics/rindle_test.exs` — verifies stage, backlog, and callback metric definitions. [VERIFIED: current test inventory]
- [ ] Extend `test/mix/tasks/parapet.gen.prometheus_test.exs` — assert provider-only generation and two-file output if split is adopted. [VERIFIED: test/mix/tasks/parapet.gen.prometheus_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 5 is generator and metric work, not auth workflow logic. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| V3 Session Management | no | No session state changes are in Phase 5 scope. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| V4 Access Control | no | Provider registration stays explicit config, but Phase 5 does not add new access decisions. [VERIFIED: lib/parapet/slo.ex][VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| V5 Input Validation | yes | Enforce family-specific label allowlists and bounded slice-spec fields. [VERIFIED: lib/parapet/internal/label_policy.ex][VERIFIED: lib/parapet/slo/generator.ex] |
| V6 Cryptography | no | No cryptographic logic is introduced in this phase. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| High-cardinality identifier leakage into metrics labels | Denial of Service / Information Disclosure | Keep exact identifiers under `refs`, validate tags through `LabelPolicy.assert_family_keys!/2`, and never derive tags from `_ref` values. [VERIFIED: docs/telemetry.md][VERIFIED: lib/parapet/internal/label_policy.ex] |
| YAML or PromQL injection through provider-controlled strings | Tampering | Continue sanitizing generated query strings and prefer bounded slice specs over arbitrary user-provided PromQL for built-ins. [VERIFIED: lib/parapet/slo/generator.ex][VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |
| Alert storm amplification from unconstrained grouping | Denial of Service | Group on bounded labels only and rely on Alertmanager grouping and inhibition instead of per-identifier labels. [CITED: https://prometheus.io/docs/alerting/latest/alertmanager/][CITED: https://prometheus.io/docs/alerting/latest/configuration/] |

## Sources

### Primary (HIGH confidence)

- [`docs/telemetry.md`](/Users/jon/projects/parapet/docs/telemetry.md) - locked Phase 4 event families, metadata contract, and semantic guarantees.
- [`docs/slo-reference.md`](/Users/jon/projects/parapet/docs/slo-reference.md) - current SLO surface and generator posture.
- [`lib/parapet/telemetry/async_delivery.ex`](/Users/jon/projects/parapet/lib/parapet/telemetry/async_delivery.ex) - canonical normalized async/delivery helper behavior.
- [`lib/parapet/integrations/mailglass.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/mailglass.ex), [`lib/parapet/integrations/chimeway.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/chimeway.ex), [`lib/parapet/integrations/rindle.ex`](/Users/jon/projects/parapet/lib/parapet/integrations/rindle.ex) - actual adapter seams.
- [`lib/parapet/slo.ex`](/Users/jon/projects/parapet/lib/parapet/slo.ex), [`lib/parapet/slo/provider.ex`](/Users/jon/projects/parapet/lib/parapet/slo/provider.ex), [`lib/parapet/slo/resolvable.ex`](/Users/jon/projects/parapet/lib/parapet/slo/resolvable.ex) - current provider aggregation model.
- [`lib/mix/tasks/parapet.gen.prometheus.ex`](/Users/jon/projects/parapet/lib/mix/tasks/parapet.gen.prometheus.ex), [`priv/templates/parapet.gen.prometheus/rules.yml.eex`](/Users/jon/projects/parapet/priv/templates/parapet.gen.prometheus/rules.yml.eex) - generator baseline.
- [`test/parapet/integrations/mailglass_test.exs`](/Users/jon/projects/parapet/test/parapet/integrations/mailglass_test.exs), [`test/parapet/integrations/chimeway_test.exs`](/Users/jon/projects/parapet/test/parapet/integrations/chimeway_test.exs), [`test/parapet/integrations/rindle_test.exs`](/Users/jon/projects/parapet/test/parapet/integrations/rindle_test.exs), [`test/mix/tasks/parapet.gen.prometheus_test.exs`](/Users/jon/projects/parapet/test/mix/tasks/parapet.gen.prometheus_test.exs) - proven contract and validation surface.
- https://hexdocs.pm/telemetry/telemetry.html - `attach_many/4`, `span/3`, and handler failure semantics.
- https://hexdocs.pm/telemetry_metrics/Telemetry.Metrics.html - tags, counters, distributions, and reporter options.
- https://hexdocs.pm/oban/job_lifecycle.html - retryable versus discarded lifecycle semantics.
- https://prometheus.io/docs/practices/naming/ - metric units, `_total`, and label-cardinality guidance.
- https://prometheus.io/docs/practices/rules/ - recording-rule naming guidance.
- https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/ - `for`, `keep_firing_for`, labels, and annotations.
- https://prometheus.io/docs/alerting/latest/alertmanager/ - grouping and inhibition concepts.
- https://prometheus.io/docs/alerting/latest/configuration/ - `group_by`, route timing, and inhibition rule configuration.
- https://hex.pm/packages/telemetry
- https://hex.pm/packages/telemetry_metrics
- https://hex.pm/packages/oban

### Secondary (MEDIUM confidence)

- None. All external claims used here were verified against official docs or official package pages. [VERIFIED: source review]

### Tertiary (LOW confidence)

- None beyond items explicitly listed in `## Assumptions Log`. [VERIFIED: source review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the repo already uses the relevant libraries and current versions were verified from official Hex package pages. [VERIFIED: mix.exs][VERIFIED: mix.lock][CITED: https://hex.pm/packages/telemetry][CITED: https://hex.pm/packages/telemetry_metrics][CITED: https://hex.pm/packages/oban]
- Architecture: HIGH - Phase 5 locked decisions, local adapter code, and Phase 4 normalized telemetry contract point to one coherent implementation shape. [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md][VERIFIED: docs/telemetry.md][VERIFIED: lib/parapet/integrations/mailglass.ex][VERIFIED: lib/parapet/integrations/chimeway.ex][VERIFIED: lib/parapet/integrations/rindle.ex]
- Pitfalls: HIGH - the repo tests and official Telemetry, Oban, and Prometheus docs all converge on the same failure modes: handler detachment, terminality confusion, cardinality blowups, and alert noise. [VERIFIED: test/parapet/integrations/rindle_test.exs][VERIFIED: test/parapet/internal/label_policy_test.exs][CITED: https://hexdocs.pm/telemetry/telemetry.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html][CITED: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/]

**Research date:** 2026-05-17
**Valid until:** 2026-06-16 for repo-specific findings; 2026-05-24 for current upstream package-version checks and Prometheus docs freshness.

## RESEARCH COMPLETE
