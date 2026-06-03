# Feature Landscape: v0.7 Async & Delivery Reliability

**Project:** Parapet
**Milestone:** v0.7 Async & Delivery Reliability
**Domain:** Elixir/Phoenix reliability for background work and provider-mediated delivery
**Researched:** 2026-05-17
**Overall confidence:** HIGH

## What Operators Typically Expect

In a product like Parapet, async and delivery reliability should answer four operator questions fast:

1. Did we accept the work?
2. Is the work moving, delayed, or stalled?
3. Did the external provider accept, reject, defer, bounce, or suppress it?
4. What is the safe next action: wait, retry, drain backlog, fix provider config, or stop sending?

The standard expectation is not "more queue graphs." It is phase-aware evidence across the full path: enqueue -> execute -> provider handoff -> provider callback/reconciliation -> terminal outcome. Existing Parapet features already cover incident, UI, alerts, and runbooks, so v0.7 should add new signal families and operator decision points rather than rebuild those surfaces.

## Table Stakes

These are must-haves for v0.7. Missing them makes async and delivery coverage feel incomplete.

| Feature | Why Expected | Complexity | Depends On Existing Parapet | Milestone Guidance |
|---------|--------------|------------|-----------------------------|-------------------|
| Queue backlog and age SLIs per async lane | Operators need to know when jobs are accumulating or starving before outright failure spikes. | Medium | Telemetry/SLO core, Grafana/Prometheus artifacts, alert routing | Must ship for `Rindle` and built-in stalled-job coverage. Prefer bounded labels such as queue, worker family, adapter, status class. |
| Stuck/executing rescue visibility | Background systems are expected to surface orphaned or long-running jobs separately from normal retries. | Medium | Oban health integration, incident evidence timeline, runbooks | Must distinguish `retryable`, `discarded`, and "stuck executing past threshold". Map cleanly to stalled-job incidents. |
| Retry exhaustion and dead-letter visibility | Operators expect a clear count of work that will not self-heal. | Medium | SLO core, Operator UI, runbooks | Must treat exhausted/discarded work as a first-class failure mode, not just another error counter. |
| Provider acceptance vs final delivery split | For mail/SMS/push-style delivery, "accepted by provider" is not the same as "delivered". Operators expect both. | Medium | Existing Mailglass/Chimeway optional integrations, telemetry contract | Must define distinct SLIs for submit success, callback-confirmed delivery, and terminal failure. |
| Suppression and bounce anomaly detection | Deliverability products are expected to catch rising hard bounces, complaints, and suppression-list drift. | Medium | Alert routing, incident correlation, Mailglass adapter seam | Must focus on rates and drift, not per-recipient detail. Especially important for `Mailglass`. |
| Webhook ingest health and delay monitoring | Provider-driven systems are expected to show when receipts are not arriving, failing signature verification, or arriving too late. | Medium | Existing webhook/incident ingestion model, notifications, runbooks | Must cover `Mailglass`, `Chimeway`, and `Rindle` provider callbacks. Distinguish provider outage from local ingest failure. |
| Incident context that separates internal backlog from provider failure | Operators need enough evidence to decide whether to scale workers, pause retries, or open vendor status pages. | Medium | Operator UI, timeline entries, trace exemplars, existing runbook attachments | Must ship as incident enrichment, not a new dashboard concept. |
| Built-in stalled-job runbook templates | Reliability tooling is expected to tell operators how to safely inspect, retry, pause, or drain async work. | Medium | Runbook DSL, one-click mitigations, ToolAudit auditing | Must ship with guardrails and explicit preconditions. Avoid auto-execution by default. |

## Differentiators

These are valuable v0.7 additions, but they are nice-to-have after the table stakes above.

| Feature | Value Proposition | Complexity | Depends On Existing Parapet | Scoping Guidance |
|---------|-------------------|------------|-----------------------------|-----------------|
| Async funnel SLIs by business stage | Goes beyond queue health and shows where an async pipeline regressed, e.g. uploaded -> promoted -> transformed -> webhook confirmed. | High | SLO DSL, Rindle integration, existing business-journey framing | Best differentiator for `Rindle`. Ship only for a few canonical stages, not arbitrary pipeline builders. |
| Reconciliation lag SLI | Detects "provider did work but our app has not reconciled state yet" as a separate blind spot. | Medium | Existing durable evidence model, webhook ingest, adapter telemetry | Strong fit for `Mailglass` and `Chimeway` if delivery callbacks can be matched to sent records. |
| Root-cause flavored incident summaries | Auto-classify incidents as backlog drift, callback outage, suppression spike, or provider terminal failure. | Medium | Existing incident correlation, trace exemplars, flag correlation | Useful because v0.6 already invested in correlation. Keep taxonomy small and bounded. |
| Safe one-click recovery actions for common async cases | Speeds recovery for paused queues, retryable dead letters, or replay-safe reconciliations. | High | Runbook actions, ToolAudit, Operator UI auth surface | Only for obviously reversible operations. Good differentiator, but not required for every failure mode in v0.7. |
| Multi-window burn-rate defaults for async/provider SLIs | Makes async failures alert like first-class SLOs instead of ad hoc threshold alarms. | Low | Existing Prometheus generation, alert routing | Worth including if cheap, because Parapet already has strong SLO machinery. |
| Cross-adapter "delivery state model" | Gives operators one normalized language across `Chimeway`, `Mailglass`, and `Rindle` for `accepted`, `delayed`, `delivered`, `failed`, `suppressed`, `orphaned`. | High | Telemetry contract discipline, optional adapter design | Valuable, but keep the normalized state set intentionally small. |

## Anti-Features

These should be explicitly avoided in v0.7.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Rebuilding vendor dashboards inside Parapet | Expensive and redundant. Twilio/SES/Postmark-style providers already expose detailed message views. | Surface operator-grade reliability signals and deep links, not per-message exploration UIs. |
| Per-recipient or per-message-cardinality metrics | Violates Parapet's low-cardinality contract and risks TSDB blow-up. | Track bounded labels and store detailed evidence only in durable, low-volume records when needed. |
| Autonomous retries or replay loops without operator intent | High risk of duplicates, user-impacting re-sends, and accidental escalation. | Provide runbooks and optional explicit recovery actions with audit logging. |
| A generic workflow engine for async orchestration | This milestone is about observing async systems, not becoming Temporal/Oban Pro/queue orchestration software. | Instrument the adopter's existing queues and provider callbacks. |
| Deep deliverability scoring or inbox-placement productization | Slips into ESP or deliverability-consultancy territory. | Focus on operational signals Parapet can observe directly: bounces, complaints, suppressions, webhook failures, lag. |
| Full escalation policy management in v0.7 | Already marked as a later milestone theme. | Emit better incidents now; layer escalation policy in v0.8. |

## Expected Operator Workflows

These workflows should shape feature boundaries more than raw metric lists.

### 1. Backlog Drift Triage

**Trigger:** Alert on queue age, queue depth, or "executing too long".

**Operator expects to see:**
- affected queue or pipeline stage
- current backlog age/depth trend
- retry/discard counts
- whether workers are saturated, paused, or stalled
- attached runbook for safe pause, resume, retry, or capacity change

**Primary milestone targets:** `Rindle`, built-in stalled-job runbooks

### 2. Delivery Failure Triage

**Trigger:** Alert on submit failures, delivery-confirmation drop, or provider terminal failure spike.

**Operator expects to see:**
- accepted by app vs accepted by provider vs confirmed delivered
- terminal failure class such as bounced, suppressed, failed, undelivered
- whether failures are isolated to one provider, stream, or tenant slice
- deep link to existing evidence and external provider console if available

**Primary milestone targets:** `Mailglass`, `Chimeway`

### 3. Callback / Reconciliation Outage Triage

**Trigger:** Webhook ingest errors, signature failures, rising orphan events, or callback lag.

**Operator expects to see:**
- callback volume dropped vs app send volume
- ingest failures vs provider silence
- duplicate vs orphaned events
- safe replay or reconciliation guidance

**Primary milestone targets:** `Mailglass`, `Chimeway`, `Rindle`

### 4. Dead-Letter / Discard Recovery

**Trigger:** Discarded jobs or exhausted retries cross threshold.

**Operator expects to see:**
- which job family exhausted
- whether retry is safe or likely to duplicate side effects
- dead-letter count and oldest age
- runbook steps for inspect -> verify idempotency -> retry subset -> confirm drain

**Primary milestone targets:** built-in stalled-job runbooks, `Rindle`

## Feature Categories By Adapter

| Area | Must-Have in v0.7 | Nice-to-Have in v0.7 | Avoid in v0.7 |
|------|-------------------|----------------------|---------------|
| `Mailglass` | outbound submit SLIs, webhook ingest health, bounce/complaint/suppression drift, reconciliation lag basics | stream-specific funnel views, normalized delivery-state taxonomy, one-click replay-safe reconciliation | inbox placement analytics, recipient-level dashboards |
| `Chimeway` | provider submit vs callback-confirmed delivery, callback delay/failure, failure status buckets | read/delivered channel nuance where available, cross-channel normalization | channel-by-channel product rebuild, marketing analytics |
| `Rindle` | queue age/depth, long-running job thresholds, discard visibility, webhook delay if external processors are involved | stage funnel SLIs, queue saturation hints, safe retry actions | arbitrary pipeline designer, full media-ops console |
| Built-in stalled-job runbooks | inspect stale executors, pause/resume queue, retry subset, dead-letter handling, operator warnings on non-idempotent work | audited one-click helpers for clearly safe actions | automatic replay, bulk mutation without review |

## Dependency Hints

Use these to keep milestone design realistic.

```text
Queue backlog/age SLIs -> existing Prometheus + SLO generation
Retry exhaustion incidents -> Oban state visibility + Operator UI evidence
Provider delivery SLIs -> Mailglass/Chimeway outbound telemetry + webhook ingest telemetry
Suppression drift -> Mailglass suppression and webhook normalization events
Webhook delay/orphan incidents -> adapter callback timestamps + durable correlation IDs
Safe retry runbooks -> Runbook DSL + ToolAudit + explicit idempotency guidance
Incident enrichment -> existing Incident/Timeline model, not a new storage subsystem
```

## Feature Dependencies

```text
Outbound submit metrics -> provider callback metrics -> delivery confirmation SLIs
Webhook ingest telemetry -> orphan/reconcile telemetry -> callback delay detection
Queue depth/age metrics -> stalled-job incidents -> built-in recovery runbooks
Discard visibility -> safe retry guidance -> optional one-click mitigations
Normalized status buckets -> cross-adapter incident summaries
```

## Milestone Scoping Guidance

Prioritize in this order:

1. **Detection primitives**
   Queue age/depth, long-running thresholds, retry exhaustion, submit/delivery/failure buckets, webhook ingest failure, callback lag.
2. **Operator evidence**
   Incident context that clearly answers internal backlog vs external provider vs reconciliation drift.
3. **Built-in runbooks**
   Safe, auditable recovery steps for stalled or discarded work.
4. **Differentiators**
   Funnel SLIs, normalized state models, selective one-click recovery.

Defer from v0.7:
- escalation policy engines
- autonomous remediation
- rich provider-console replacement
- high-cardinality forensics surfaces
- generic async orchestration abstractions

## MVP Recommendation

Ship these first:

1. `Rindle` async health slice: queue age/depth, long-running threshold, discard visibility, basic async funnel regression signals.
2. `Mailglass` delivery slice: outbound submit success, webhook ingest health, bounce/complaint/suppression drift, reconciliation lag.
3. `Chimeway` delivery slice: provider acceptance, callback-confirmed delivery/failure, callback delay.
4. Built-in stalled-job runbooks: stale executors, dead-letter handling, safe retry decision tree.

Defer:
- Cross-adapter normalized delivery model if it threatens milestone size.
- One-click recovery beyond a very small set of obviously safe actions.
- Any provider-specific nuance that needs large bespoke UI treatment.

## Sources

- Parapet project context: [`.planning/PROJECT.md`](/Users/jon/projects/parapet/.planning/PROJECT.md), [`.planning/MILESTONE-ARC.md`](/Users/jon/projects/parapet/.planning/MILESTONE-ARC.md), [`README.md`](/Users/jon/projects/parapet/README.md)
- Oban job lifecycle and rescue controls: https://hexdocs.pm/oban/Oban.Plugins.Lifeline.html, https://hexdocs.pm/oban/Oban.html, https://hexdocs.pm/oban/job_lifecycle.html
- Mailglass telemetry and webhook/reconciliation patterns: https://hexdocs.pm/mailglass/telemetry.html, https://hexdocs.pm/mailglass/webhooks.html, https://hexdocs.pm/mailglass/Mailglass.Suppression.html
- Rindle async processing and failure recovery patterns: https://hexdocs.pm/rindle/background_processing.html, https://hexdocs.pm/rindle/troubleshooting.html
- Webhook consumer reliability expectations: https://docs.github.com/en/webhooks/using-webhooks/best-practices-for-using-webhooks
- Deliverability suppression behavior: https://docs.aws.amazon.com/ses/latest/dg/sending-email-suppression-list.html
- Messaging delivery callback expectations: https://www.twilio.com/docs/usage/webhooks/messaging-webhooks, https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks
- Background job failure handling guidance: https://learn.microsoft.com/en-us/azure/architecture/best-practices/background-jobs
