# Architecture Guidance: Parapet v0.7 Async & Delivery Reliability

**Milestone:** v0.7 Async & Delivery Reliability  
**Project:** Parapet  
**Researched:** 2026-05-17  
**Confidence:** HIGH for internal integration seams, MEDIUM for sibling-library event surface details

## What v0.7 Changes

Parapet already has the right top-level shape for v0.7: low-cardinality telemetry for systemic detection, durable Ecto evidence for operator work, and generated host-owned UI/runbook surfaces for action. The mistake would be adding a parallel subsystem for async work. v0.7 should instead deepen the existing architecture by normalizing `Chimeway`, `Mailglass`, and `Rindle` into richer bounded telemetry, then projecting only the operator-relevant subset into the evidence spine.

The architectural goal is not "store more async state." It is "detect async/provider failure modes early, classify them correctly, and hand operators enough context to act without violating telemetry safety or host ownership."

## Non-Negotiables For v0.7

1. Preserve the bifurcated architecture.
   `telemetry -> metrics/SLOs -> alerts` stays separate from `incidents/timeline/action items`.
2. Keep telemetry labels low-cardinality.
   Safe tags are things like `integration`, `provider`, `channel`, `queue`, `pipeline_stage`, `outcome`, `failure_class`, and coarse `delay_bucket`. Do not label with `job_id`, `message_id`, `recipient`, `webhook_id`, or provider request ids.
3. Keep optional integrations compiled out cleanly.
   New integration code must remain behind `Code.ensure_loaded?` or equivalent adapter activation checks.
4. Keep host ownership generator-first.
   Built-in stalled-job runbooks should be generated into the host app or exposed as inspectable templates/helpers, not hidden inside opaque library callbacks.

## Recommended v0.7 Shape

```text
Sibling telemetry
  -> Parapet.Integrations.{Chimeway,Mailglass,Rindle}
  -> normalized Parapet events
     - [:parapet, :delivery, ...]
     - [:parapet, :async, ...]
  -> Parapet.Metrics.{Chimeway,Mailglass,Rindle}
  -> Parapet.SLO.Provider implementations
  -> generated Prometheus/Grafana artifacts
  -> Alertmanager webhook
  -> Parapet.Spine.AlertProcessor
  -> Incident + TimelineEntry + optional ActionItem
  -> Parapet.Operator + WorkbenchContract + generated runbook UI
  -> audited host-owned mitigations / retries
```

The important change is the addition of a **normalized async/delivery event layer** between sibling adapters and Parapet metrics. Current adapters emit very thin `:journey` events. That is adequate for generic success/failure visibility, but not for provider drift vs internal backlog classification, suppression anomalies, or webhook delay diagnosis.

## New vs Modified Components

| Component | Status | Responsibility in v0.7 |
|-----------|--------|-------------------------|
| `Parapet.Integrations.Chimeway` | Modified | Expand from generic failure translation into normalized notification-delivery events with bounded metadata such as `provider`, `channel`, `outcome`, `failure_class`, `backlog_state`. |
| `Parapet.Integrations.Mailglass` | Modified | Expand from generic mail failure translation into normalized email-delivery and suppression-health events with bounded metadata such as `provider`, `outcome`, `failure_class`, `suppression_state`. |
| `Parapet.Integrations.Rindle` | Modified | Expand from generic media journey events into normalized async pipeline events covering processing outcome, webhook delay, long-running stage duration, and backlog/funnel drift. |
| `Parapet.Metrics.Chimeway` | New | Define Telemetry metrics for notification delivery reliability and provider/backlog split. |
| `Parapet.Metrics.Mailglass` | New | Define Telemetry metrics for email delivery reliability, suppression anomaly counts, and provider health. |
| `Parapet.Metrics.Rindle` | New | Define Telemetry metrics for media pipeline success/failure, delay buckets, stage latency, and webhook lag. |
| `Parapet.SLO.Provider` impls for async/delivery | New | Ship built-in provider modules that expose concrete SLIs/SLOs for Chimeway, Mailglass, and Rindle using the new metric families. |
| `Parapet.SLO.Generator` | Modified | Ensure generated rules/dashboards handle the new built-in async/delivery SLO families cleanly. |
| `Parapet.Spine.AlertProcessor` | Modified | Enrich incidents from async/delivery alerts with classification metadata in `runbook_data`, and optionally create durable `ActionItem`s for exact stalled work that needs manual follow-up. |
| `Parapet.Spine.ActionItem` | Reused/Modified in usage | Reuse for high-cardinality "one concrete thing needs attention" cases such as dead-lettered work or retry-required items. Do not create one for every metric event. |
| `Parapet.Operator.WorkbenchContract` | Modified | Derive async-specific operator fields such as `integration`, `failure_plane` (`provider` vs `internal_backlog`), `queue`, `pipeline_stage`, `delay_bucket`, and `retryable?` from timeline/runbook evidence. |
| `Parapet.Operator` | Modified | Add audited operator commands for host-approved async/delivery mitigations and safe retry flows. |
| `Parapet.Runbook` | Modified/Extended | Support template schemas for stalled-job and delivery-recovery runbooks, while keeping generated modules host-owned. |
| `Parapet.Capabilities` | Modified | Register optional async/delivery mitigation capabilities only when the host has explicitly enabled the integration and mitigation callback. |
| `mix` generator surface | New/Modified | Add a generator for host-owned async/delivery runbooks and mitigation stubs instead of hardcoding operational behavior inside the library. |

## Normalized Event Layer

### Why add it

Current integration modules emit generic journey events:

- `Chimeway` and `Mailglass` collapse to `[:parapet, :journey, :mail_delivery]`
- `Rindle` collapses to `[:parapet, :journey, :media]`

That loses the distinction v0.7 needs:

- provider rejection vs internal queue backlog
- suppression drift vs single-message failure
- long-running worker stage vs downstream webhook lag
- system-wide regression vs one retryable external item

### Recommended event families

Use two bounded namespaces:

1. `[:parapet, :delivery, :event]`
   For `Chimeway` and `Mailglass`
2. `[:parapet, :async, :event]`
   For `Rindle` and stalled-job style async work

Recommended metadata contract:

| Field | Use | Cardinality rule |
|------|-----|------------------|
| `integration` | `chimeway` / `mailglass` / `rindle` | bounded |
| `provider` | coarse upstream backend or transport | bounded |
| `channel` | `email`, `notification`, `media_webhook`, etc. | bounded |
| `queue` | queue name if stable and finite | bounded |
| `pipeline_stage` | ingest/transcode/deliver/webhook/finalize | bounded |
| `outcome` | success/failure/delayed/suppressed/retried | bounded |
| `failure_class` | timeout/rejected/backlog/suppression/webhook_delay/provider_5xx | bounded |
| `delay_bucket` | coarse bucket string | bounded |

Recommended measurement contract:

| Measurement | Use |
|-------------|-----|
| `count` | aggregate events |
| `duration_ms` | provider call or stage duration |
| `delay_ms` | webhook or backlog lag before bucketing in metrics |

Do not pass through exact ids or PII. If the host needs exact identifiers for operator action, emit a separate durable event path that writes one `ActionItem`, not a high-cardinality metric label.

## Evidence Spine Changes

### Incident creation

`Parapet.Spine.AlertProcessor` should stay the only general alert-to-incident seam. Extend it, do not bypass it.

When async/delivery alerts arrive:

1. Correlate by alert fingerprint as today.
2. Copy only bounded alert labels into `incident.runbook_data`, for example:
   - `integration`
   - `provider`
   - `failure_plane`
   - `queue`
   - `pipeline_stage`
   - `delay_bucket`
   - `symptom`
3. Attach the generated or configured runbook schema.
4. Append an initial triage snapshot timeline entry if the alert payload already classifies the problem.

This keeps the operator UI from re-deriving everything from raw Prometheus labels later.

### Action items for exact stalled work

Use `Parapet.Spine.ActionItem` only for discrete follow-up items:

- a dead-lettered async object that needs retry
- a durable approval/retry decision
- a known external object waiting on manual replay

Do not create `ActionItem`s for every delayed job or every provider failure. The threshold is: "Would an operator act on this exact item by id?" If not, it belongs in metrics/alerts only.

`ActionItem.external_id` is the right place for high-cardinality identifiers that must survive into operator workflows. That keeps them out of labels and out of generic incident payloads.

## Operator Workbench Changes

The Operator UI already works best as an action surface, not a dashboard replacement. Keep that pattern.

Extend `Parapet.Operator.WorkbenchContract` to derive async/delivery-specific fields from evidence:

| Derived field | Source |
|---------------|--------|
| `integration` | incident `runbook_data` or latest triage snapshot |
| `failure_plane` | `provider`, `internal_backlog`, `suppression_state`, `webhook_delay` |
| `queue` | bounded incident metadata |
| `pipeline_stage` | bounded incident metadata |
| `retryable?` | runbook step schema plus capability registration |
| `has_action_items?` | open `ActionItem`s linked by integration/external id convention |

The key operator UX requirement for v0.7 is classification:

- "provider drift" should look different from
- "our queue is backed up" which should look different from
- "one exact thing is stuck and can be retried"

That classification should come from durable evidence derived at incident creation time, not from ad hoc UI heuristics.

## Runbook And Mitigation Architecture

### Built-in runbooks

Parapet should ship **runbook templates and helper modules**, but the host app should own the final runbook modules. The right shape is:

1. Parapet provides template EEx or helper modules for:
   - stalled queue backlog
   - dead-letter handling
   - safe retry / replay flow
   - provider outage / suppression drift triage
2. A generator writes host-visible runbook modules into the adopter app.
3. The host chooses which mitigation callbacks are enabled.

That preserves the project’s existing install model: generator for scaffolding, library for runtime behavior.

### One-click mitigations

Do not make Parapet directly mutate sibling library state by default. Instead:

1. Register mitigation capabilities only when the host explicitly wires them.
2. Route every mitigation through `Parapet.Operator` and `Parapet.Evidence.run_operator_command/1`.
3. Record both timeline entry and tool audit for every retry, replay, or queue operation.

Suggested capability families:

- `retry_async_item`
- `requeue_dead_letter`
- `pause_delivery_path`
- `resume_delivery_path`
- `request_manual_provider_check`

These are capability names, not required implementation details. The important part is the audited, host-owned command seam.

## Data Flow Changes

### Chimeway / Mailglass delivery path

```text
Chimeway or Mailglass telemetry
  -> integration adapter normalizes event
  -> delivery metrics increment with bounded tags
  -> built-in delivery SLO burns
  -> Alertmanager fires
  -> AlertProcessor creates/updates incident
  -> incident runbook_data marks provider vs suppression vs backlog classification
  -> Operator UI shows runbook + optional action items + audited mitigation
```

### Rindle async path

```text
Rindle telemetry
  -> integration adapter normalizes pipeline-stage event
  -> async metrics record outcome, duration, and delay bucket
  -> built-in async SLO burns
  -> alert arrives through existing webhook path
  -> AlertProcessor creates incident, optionally durable action item for exact stuck object
  -> Operator UI distinguishes systemic lag from exact retryable item
```

### Stalled-job runbook support

```text
Oban / async-host signal
  -> bounded telemetry for systemic lag
  -> optional durable ActionItem for exact stalled object
  -> host-generated runbook module selects safe operator actions
  -> Operator command executes through audited transactional seam
```

## Suggested Module Boundaries

Use the existing naming pattern. Recommended additions:

- `lib/parapet/metrics/chimeway.ex`
- `lib/parapet/metrics/mailglass.ex`
- `lib/parapet/metrics/rindle.ex`
- `lib/parapet/slo/chimeway_delivery.ex`
- `lib/parapet/slo/mailglass_delivery.ex`
- `lib/parapet/slo/rindle_async.ex`
- `lib/parapet/operator/async_reliability.ex` or equivalent helper module
- `priv/templates/parapet.gen.runbooks/*`

Recommended extensions:

- `lib/parapet/integrations/chimeway.ex`
- `lib/parapet/integrations/mailglass.ex`
- `lib/parapet/integrations/rindle.ex`
- `lib/parapet/spine/alert_processor.ex`
- `lib/parapet/operator/workbench_contract.ex`
- `lib/parapet/operator.ex`
- `lib/parapet/capabilities.ex`
- `lib/parapet/runbook.ex`

## Anti-Patterns To Avoid In v0.7

### 1. Putting provider ids or job ids into metric labels

This breaks Parapet’s low-cardinality contract and makes the TSDB story worse exactly where v0.7 increases event volume.

### 2. Writing every async event into Ecto

The evidence spine is for incidents, timeline facts, audits, and exact action items. It is not an async event ledger.

### 3. Baking remediation logic into library internals

Parapet should not become the hidden owner of retry semantics. Generate host-owned runbook modules and let adopters keep operational intent visible.

### 4. Creating a second incident-ingestion path

Async/delivery alerts should still flow through `Parapet.Spine.AlertProcessor`. Extend that seam instead of inventing a parallel incident constructor.

### 5. Letting UI infer provider-vs-backlog from raw strings

Classify failure planes in the alert/incident enrichment layer and persist the result. UI should render durable facts, not parse accidental text.

## Suggested Build Order

1. **Normalize integration contracts first**
   - Extend `Chimeway`, `Mailglass`, and `Rindle` adapters with bounded metadata contracts.
   - Freeze event names and safe tags before adding metrics or UI.
   - This is the public telemetry API surface for v0.7.

2. **Add provider-specific metrics modules**
   - Implement `Parapet.Metrics.Chimeway`, `Mailglass`, and `Rindle`.
   - Validate label safety centrally.
   - Keep compile-out behavior identical to existing optional integrations.

3. **Add built-in SLO provider modules and artifact generation**
   - Ship concrete delivery/async SLIs on top of the new metric families.
   - Extend generated Prometheus/Grafana output once the metric contract is stable.

4. **Extend alert enrichment and durable evidence**
   - Modify `AlertProcessor` to persist async/delivery classification into `runbook_data`.
   - Introduce selective `ActionItem` creation only for exact stalled/retryable work.

5. **Add host-generated runbook templates**
   - Create generator output for stalled-job, dead-letter, retry, suppression drift, and provider outage runbooks.
   - Keep the host app as the owner of operational code and wording.

6. **Add audited operator actions and capability registration**
   - Extend `Operator`, `WorkbenchContract`, and `Capabilities` to support safe retries and queue/delivery mitigations.
   - These depend on stable evidence shape and host-generated runbook modules.

7. **Finish with UI surfacing**
   - Update the workbench rendering once durable classification and capabilities exist.
   - UI should be the last consumer, not the place where classification logic is invented.

## Phase Ordering Rationale

The roadmap should start with telemetry normalization because everything downstream depends on that contract:

- SLOs depend on metric names and safe labels.
- alerts depend on SLO output.
- incidents depend on alert classification.
- runbooks and UI depend on incident metadata and action-item semantics.
- mitigations depend on host-generated runbook ownership and audited operator seams.

If the order is reversed, v0.7 will hardcode UI assumptions before the async/delivery contract is stable.

## Recommendation For Roadmap Framing

Treat v0.7 as four dependency-aware architecture slices:

1. **Telemetry contract expansion**
   `Integrations + Metrics`
2. **Async/delivery SLO productization**
   `SLO providers + generated artifacts`
3. **Durable operator context**
   `Alert enrichment + ActionItem usage + runbook templates`
4. **Operator execution**
   `Capabilities + audited mitigations + UI rendering`

This sequencing matches Parapet’s existing architecture instead of fighting it.

## Sources

- `.planning/PROJECT.md`
- `.planning/MILESTONE-ARC.md`
- `README.md`
- `lib/parapet/integrations/chimeway.ex`
- `lib/parapet/integrations/mailglass.ex`
- `lib/parapet/integrations/rindle.ex`
- `lib/parapet/evidence.ex`
- `lib/parapet/operator.ex`
- `lib/parapet/operator/workbench_contract.ex`
- `lib/parapet/runbook.ex`
- `lib/parapet/capabilities.ex`
- `lib/parapet/spine/alert_processor.ex`
- `lib/parapet/spine/action_item.ex`
