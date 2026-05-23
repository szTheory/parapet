# Research Summary: Parapet v0.7 Async & Delivery Reliability

**Milestone:** v0.7 Async & Delivery Reliability  
**Project:** Parapet  
**Researched:** 2026-05-17  
**Overall confidence:** HIGH

## Executive Summary

v0.7 should extend Parapet's existing reliability spine into async and provider-mediated paths without adding a new platform. The core move is to normalize `Chimeway`, `Mailglass`, and `Rindle` telemetry into bounded async and delivery event families, then reuse Parapet's existing metrics, SLO, alert, incident, runbook, and operator surfaces to classify failures as internal backlog, worker failure, provider degradation, webhook delay, or suppression drift.

The milestone should be built detection-first. Lock the normalized event contract, add low-cardinality metrics and built-in SLO providers, enrich incidents with fault-domain context, and then layer host-owned runbook templates and audited operator actions on top. The main risk is telling operators the wrong story: acceptance is not delivery, retries are not incidents, and callback lag is not the same as queue backlog.

## Stack Additions / Reuse Guidance

### Add or tighten

- `:oban` -> tighten to `~> 2.21` or `~> 2.22` so stalled, retryable, executing, and discarded semantics are stable.
- `:telemetry` -> widen toward `~> 1.4` for richer handler support and current ecosystem compatibility.
- `:telemetry_metrics` -> widen toward `~> 1.1` for the new async and delivery metric families.

### Reuse as-is

- Reuse `Req` for any Parapet-owned HTTP probes or reconciliation fetches. Do not add a second HTTP client.
- Reuse Ecto for durable incidents, timeline entries, action items, and tool audits only. Do not persist raw async event streams.
- Reuse the existing Operator UI, Runbook DSL, alert ingestion path, and capability registration model rather than inventing a parallel async subsystem.

### Internal additions recommended

- `Parapet.Integrations.DeliveryAdapter` for shared `Chimeway` and `Mailglass` normalization.
- `Parapet.Integrations.AsyncAdapter` for shared `Rindle` and stalled-work normalization.
- `Parapet.ObanInspector` for queue truth and runbook context.
- Built-in async runbook templates under the existing runbook/generator model.

## Feature Categories For This Milestone

### Must ship

- Queue backlog, queue age, long-running execution, retry exhaustion, and discarded-work visibility for `Rindle` and general stalled-job support.
- Provider acceptance vs callback-confirmed delivery vs terminal failure for `Mailglass` and `Chimeway`.
- Webhook ingest health, callback delay, orphan/duplicate drift, and suppression/bounce anomaly detection where supported.
- Incident enrichment that clearly separates internal backlog from provider or reconciliation failure.
- Built-in runbook templates for stale executors, dead-letter handling, safe retry, backlog drift, and provider/callback outages.

### Strong differentiators if they fit

- Async funnel SLIs by canonical business stage, especially for `Rindle`.
- Reconciliation lag SLIs for provider-driven delivery paths.
- Small, bounded root-cause taxonomies in incident summaries.
- A very limited set of audited one-click recovery actions for obviously safe retry/requeue flows.

### Defer

- Escalation-policy management.
- Autonomous remediation.
- Provider-console replacement.
- High-cardinality per-message or per-recipient forensics.
- Generic workflow orchestration or a new async runtime.

## Architecture Implications And Likely Build Order

v0.7 depends on a normalized event layer between sibling telemetry and Parapet metrics. That layer should emit bounded `[:parapet, :delivery, ...]` and `[:parapet, :async, ...]` events with safe metadata like `integration`, `provider`, `channel`, `queue`, `pipeline_stage`, `outcome`, `failure_class`, and coarse delay buckets. Exact identifiers belong in durable evidence or `ActionItem.external_id`, not metrics labels.

Recommended build order:

1. **Normalize integration contracts**
   Extend `Chimeway`, `Mailglass`, and `Rindle` adapters and freeze safe metadata/tag contracts first.
2. **Add metric families and built-in SLO providers**
   Implement provider-specific metrics and async/delivery SLO modules once the event contract is stable.
3. **Extend alert enrichment and durable evidence**
   Persist fault-domain classification into `incident.runbook_data`; create `ActionItem`s only for exact operator-owned follow-up work.
4. **Generate host-owned runbook templates**
   Scaffold stalled-job, dead-letter, retry, suppression-drift, and provider-outage runbooks into the host app.
5. **Add audited operator actions and final UI surfacing**
   Register safe capabilities after evidence shape and runbook ownership are stable; keep UI as the last consumer, not the place where classification logic lives.

## Critical Pitfalls To Protect Against

- Collapsing `attempted`, `provider_accepted`, `delivered`, `bounced`, `complained`, and `suppressed` into one success/failure story.
- Paging on normal retries instead of sustained burn, retry exhaustion, dead-letter growth, or user-harming failure.
- Misclassifying provider degradation, webhook delay, and internal backlog as the same incident type.
- Shipping broad retry/replay actions without preview, scope filters, and explicit idempotency guardrails.
- Letting telemetry handler crashes silently detach observability for an integration.
- Leaking PII or raw provider identifiers into metrics labels, incident summaries, or durable evidence.

## Recommended Milestone Scoping Guardrails

- Keep v0.7 focused on observability, classification, and operator guidance. Do not become a queue platform, deliverability product, or remediation daemon.
- Treat telemetry contracts as public API. Event names, safe metadata, and label policies need to be locked before downstream phases expand.
- Preserve compile-out discipline for all optional integrations. Base `parapet` installs must still work with no sibling libraries present.
- Default to detection-first and investigation-first flows. Recovery should be narrow, explicit, audited, and host-owned.
- Partition critical transactional delivery from lower-value message classes so alerting reflects actual user harm.
- Require low-volume gates and retry-aware semantics in generated alerts to avoid noisy rollout regressions.

## Milestone Slice Recommendation

Suggested roadmap structure for v0.7:

1. **Telemetry Contract Expansion**  
   `Integrations + normalization + metrics safety`
2. **Async / Delivery SLO Productization**  
   `Metrics + SLO providers + generated Prometheus/Grafana artifacts`
3. **Durable Operator Context**  
   `Alert enrichment + fault-domain classification + selective action items`
4. **Runbooks And Safe Actions**  
   `Host-generated templates + audited mitigations + final Operator UI surfacing`

This order matches both the architecture research and the milestone arc: detection primitives first, operator evidence second, guided response last.

## Sources

- [STACK.md](/Users/jon/projects/parapet/.planning/research/STACK.md)
- [FEATURES.md](/Users/jon/projects/parapet/.planning/research/FEATURES.md)
- [ARCHITECTURE.md](/Users/jon/projects/parapet/.planning/research/ARCHITECTURE.md)
- [PITFALLS.md](/Users/jon/projects/parapet/.planning/research/PITFALLS.md)
- [PROJECT.md](/Users/jon/projects/parapet/.planning/PROJECT.md)
- [MILESTONE-ARC.md](/Users/jon/projects/parapet/.planning/MILESTONE-ARC.md)
