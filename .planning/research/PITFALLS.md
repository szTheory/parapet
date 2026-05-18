# Domain Pitfalls: Parapet v0.7 Async & Delivery Reliability

**Domain:** Async job reliability, external delivery reliability, and operator incident handling for Elixir/Phoenix
**Milestone:** v0.7 Async & Delivery Reliability
**Researched:** 2026-05-17

## Milestone Framing

v0.7 is not adding generic observability. It is extending Parapet into the hardest part of reliability work: delayed, retried, provider-mediated, and often ambiguous failures. The main risk is not "missing a metric". The main risk is teaching operators the wrong story about what is broken.

For this milestone, the sharp edges cluster in three places:

1. **Integration semantics:** `Chimeway`, `Mailglass`, and `Rindle` events do not automatically mean user harm in the same way.
2. **Alert noise:** async and delivery systems naturally retry, delay, and self-heal; naive paging will be noisy.
3. **Operator UX:** if the Operator UI cannot separate provider degradation from internal backlog, operators will take the wrong action.

## Critical Pitfalls

### Pitfall 1: Treating provider acceptance, provider delivery, and user-visible success as the same event
**What goes wrong:** Parapet emits a single success/failure story for mail or notification delivery, even though the real system has at least three stages: app enqueue/attempt, provider accept/reject, and eventual delivery/bounce/complaint.
**Why it happens:** The current adapters are thin telemetry shims. It is easy to map one provider event into one Parapet outcome and call it "deliverability".
**Consequences:** False confidence during partial outages, wrong SLI math, and incidents that resolve before the operator realizes users still never received the message.
**Prevention:** Normalize delivery into explicit stages such as `attempted`, `provider_accepted`, `provider_rejected`, `delivered`, `bounced`, `complained`, and `suppressed`. Keep "provider health" SLIs separate from "user received message" SLIs.
**Detection:** Dashboards show healthy success rates while support reports missing password resets or invites; incident timelines contain only provider acceptance events with no downstream disposition.
**Mitigation phase:** Adapter event model and SLI semantics phase.

### Pitfall 2: Paging on retries instead of paging on exhausted or user-harming failures
**What goes wrong:** Every transient job failure, provider timeout, or webhook retry looks like an incident.
**Why it happens:** Async systems fail normally. Oban retries by design, and provider webhooks are often at-least-once or delayed. Naive failure counters overstate harm.
**Consequences:** Alert fatigue, muted channels, ignored pages, and loss of confidence in Parapet-generated alerts.
**Prevention:** Make retry-aware semantics a hard requirement. Distinguish `retryable` from `discarded`, and distinguish transient provider failures from sustained burn. Page only on sustained burn, dead-letter growth, max-attempt exhaustion, or critical journey impact.
**Detection:** Alert volume rises during brief provider turbulence but user-facing symptoms disappear before human action; operators repeatedly close incidents as "self-healed retry noise".
**Mitigation phase:** SLI/alert generation phase.

### Pitfall 3: Misclassifying backlog as provider degradation, or provider degradation as backlog
**What goes wrong:** Operators see "delivery is late" but cannot tell whether the cause is internal queue saturation, paused workers, webhook lag, or upstream provider trouble.
**Why it happens:** Async reliability is a pipeline problem. If the UI collapses queue depth, execution lag, provider rejects, and webhook delay into one red badge, it destroys diagnosability.
**Consequences:** Wrong runbook execution, unsafe retries, wasted incident time, and repeated regressions because the actual bottleneck stays hidden.
**Prevention:** Surface separate evidence lanes for:
- internal backlog and queue age
- worker failure/discard trends
- provider API errors/rejections
- provider callback/webhook delay
- suppression/reputation drift
Use "likely fault domain" as a first-class operator concept.
**Detection:** Operators need to click into logs or external dashboards before they can answer "is this our queue or their provider?"; the same incident repeatedly bounces between app and infrastructure owners.
**Mitigation phase:** Operator UI evidence and correlation phase.

### Pitfall 4: Building stalled-job runbooks that are not idempotent or scope-safe
**What goes wrong:** A built-in retry or replay flow re-runs the wrong jobs, duplicates user-visible actions, or retries jobs that are currently healthy but delayed.
**Why it happens:** "Retry everything" is tempting, and Oban exposes bulk retry capabilities. But stalled-work recovery is only safe when state filters and idempotency assumptions are explicit.
**Consequences:** Duplicate emails, duplicate notifications, duplicate media processing, customer confusion, and avoidable incident expansion caused by the mitigation itself.
**Prevention:** Ship runbooks that require narrow filters by queue, worker, state, age, tenant, or correlation key. Prefer preview/query-first flows over blind actions. State clearly when a retry is safe, unsafe, or requires host-app knowledge.
**Detection:** Incident timelines show recovery actions followed by duplicate downstream effects; operators cannot explain which jobs were retried or why.
**Mitigation phase:** Runbook template and operator action safety phase.

### Pitfall 5: Letting adapter handler failures silently remove observability
**What goes wrong:** A telemetry handler crashes on unexpected metadata shape, the handler is detached, and Parapet quietly stops seeing that integration's events.
**Why it happens:** Telemetry handlers run in the dispatching process and are removed on failure. Thin adapters can still crash on missing measurements, changed event names, or bad metadata assumptions.
**Consequences:** Silent blind spots exactly when new provider or app behavior appears; operators believe "nothing is failing" because the adapter stopped reporting.
**Prevention:** Defensive parsing, bounded metadata normalization, explicit tests for missing keys and shape drift, and a health signal for handler attach failures or zero-event suspicious silence.
**Detection:** Sudden flatline of one integration's metrics without a matching improvement in product behavior; `[telemetry, handler, failure]` events or duplicate attach errors during boot.
**Mitigation phase:** Adapter hardening and doctor/verification phase.

## Moderate Pitfalls

### Pitfall 1: Ignoring suppression drift and domain reputation until delivery is already damaged
**What goes wrong:** Email and notification delivery degrades gradually due to suppression growth, complaints, or sender reputation issues, but Parapet only notices hard rejects or outright failures.
**Prevention:** Track suppression additions, complaint/spam indicators, and bounce classes separately from immediate provider API failures. Treat gradual drift as early warning, not postmortem trivia.
**Detection:** Healthy provider API SLIs but worsening delivery outcomes or growing support reports. For email, complaint rates rise before operators see hard outages.
**Mitigation phase:** Delivery semantics and dashboard phase.

### Pitfall 2: Using one SLI for all message classes
**What goes wrong:** Marketing or low-value notifications dilute the signal for critical transactional flows such as password reset, magic link, invoice, invite, or security email.
**Prevention:** Partition SLIs by message criticality and journey type. Critical transactional delivery should alert differently from bulk or low-priority sends.
**Detection:** Overall delivery rate looks acceptable while a critical message type is badly degraded.
**Mitigation phase:** SLI catalog and alert policy phase.

### Pitfall 3: Alerting on low-volume percentages without volume gates
**What goes wrong:** One or two failures in a low-volume stream trip percentage alerts and page humans.
**Prevention:** Add volume gates and multi-window burn-rate rules. For async and delivery streams, "bad ratio" without meaningful denominator is not enough.
**Detection:** Pages fire overnight or in low-traffic environments from tiny sample sizes.
**Mitigation phase:** Prometheus rule generation phase.

### Pitfall 4: Treating webhook delay as the same problem as job execution delay
**What goes wrong:** `Rindle` or provider callback latency is modeled as worker slowness, leading to incorrect queue tuning or retry advice.
**Prevention:** Track async funnel stages separately: enqueue lag, execution duration, external processing wait, and callback/webhook arrival delay. Define where Parapet's clock starts and ends for each stage.
**Detection:** Queue saturation runbooks are used even though workers are idle and the real delay is external callback arrival.
**Mitigation phase:** `Rindle` adapter semantics and UI correlation phase.

### Pitfall 5: Shipping operator UX that answers "what happened?" but not "what should I do?"
**What goes wrong:** The Operator UI provides incident facts without next-action guidance, so operators still need tribal knowledge to choose between retrying, waiting, pausing a queue, or escalating to the provider.
**Prevention:** Every async/delivery incident view should answer:
- what stage is failing
- what evidence supports that conclusion
- what the safest next action is
- what action is unsafe right now
**Detection:** Incidents are acknowledged quickly but mitigations are inconsistent across operators.
**Mitigation phase:** Operator UI and runbook integration phase.

### Pitfall 6: Over-coupling new adapters to optional libraries
**What goes wrong:** `parapet` base installs break or boot paths become order-dependent when `Chimeway`, `Mailglass`, or `Rindle` are absent.
**Prevention:** Keep compile-out discipline strict. Guard on module presence, isolate adapter registration, and test base installs plus each optional integration independently.
**Detection:** CI passes only in the full dependency matrix; consumers without sibling libs see compile or startup failures.
**Mitigation phase:** Integration packaging and CI verification phase.

## Minor Pitfalls

### Pitfall 1: Leaking PII or raw provider payloads into metrics or incident summaries
**What goes wrong:** Email addresses, message bodies, webhook payloads, or provider IDs leak into labels, telemetry metadata, or operator summaries.
**Prevention:** Redact at emission time and preserve only bounded, operator-useful metadata such as message class, provider, queue, and normalized failure reason.
**Mitigation phase:** Adapter normalization phase.

### Pitfall 2: Attaching handlers with fixed IDs that collide across boot/test paths
**What goes wrong:** Repeated `setup/0` calls return `{:error, already_exists}` or attach behavior becomes environment-dependent.
**Prevention:** Make adapter setup idempotent or supervised, and test repeated attach scenarios explicitly.
**Mitigation phase:** Integration hardening phase.

### Pitfall 3: Treating "no events observed" as healthy
**What goes wrong:** A broken webhook route, disabled integration, or paused queue produces silence that looks like stability.
**Prevention:** Add doctor checks or synthetic expectations for critical async surfaces, especially where event absence itself is suspicious.
**Mitigation phase:** Doctor/runbook verification phase.

## Integration-Specific Failure Modes

### `Chimeway`
- Notification backlog drift hidden by eventual success metrics.
- Channel/provider degradation normalized into generic failure counts, losing which downstream path is sick.
- "Why wasn't this sent?" cannot be answered because queue evidence and provider evidence are not linked.

### `Mailglass`
- Provider acceptance counted as delivered mail.
- Suppression list growth and complaint drift left out of incident semantics.
- Critical transactional mail mixed with noncritical mail, creating noisy or diluted alerts.

### `Rindle`
- Long-running work treated as failed too early, or genuinely stalled work treated as merely slow.
- External processing time and webhook callback delay collapsed into one latency number.
- Recovery actions retry work that is still in-flight with an external provider.

## Operator UX Failure Modes

### Failure Mode 1: Ambiguous incident titles
Bad: "Mail delivery failure elevated"
Better: "Password reset email provider accepts are healthy, but bounce rate is burning budget"

### Failure Mode 2: Missing fault-domain labeling
If the UI does not label incidents as likely `internal backlog`, `worker failure`, `provider rejection`, `provider callback delay`, or `reputation/suppression drift`, operators lose time immediately.

### Failure Mode 3: Evidence without chronology
Async incidents need ordered evidence: enqueue spike, retry buildup, provider rejects, runbook action, recovery. Flat evidence lists make delayed systems hard to reason about.

### Failure Mode 4: One-click mitigations without preview
For async systems, preview and scope are part of safety. The UX should show what will be retried, resumed, or ignored before allowing execution.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Adapter event model | Conflating acceptance, delivery, bounce, suppression, and complaint into one outcome | Define a normalized state model per integration before generating any SLIs |
| SLI and alert rules | Paging on transient retries or low-volume ratios | Require retry-aware semantics, volume gates, and multi-window burn-rate rules |
| Operator UI | Failing to distinguish provider drift from internal backlog | Make fault-domain separation a top-level incident affordance, not a drill-down detail |
| Runbook templates | Unsafe broad retries or dead-letter recovery | Ship preview-first, scope-limited actions with explicit idempotency caveats |
| Doctor/verification | Silent handler detachments or missing event flows | Add attach/health verification, suspicious-silence checks, and matrix tests with/without optional deps |

## Roadmap Risk Implications

- The first v0.7 phase should lock the normalized async/delivery event vocabulary before UI or alert generation work expands.
- Alerting should not be considered "done" until it proves low-noise behavior for retries, low volume, and delayed callbacks.
- Operator UI scope must include fault-domain explanation, not just additional cards or badges.
- Built-in stalled-job runbooks need explicit safety boundaries and should default to investigation-first flows where host-app idempotency is unknown.

## Sources

- [.planning/PROJECT.md](/Users/jon/projects/parapet/.planning/PROJECT.md)
- [.planning/MILESTONE-ARC.md](/Users/jon/projects/parapet/.planning/MILESTONE-ARC.md)
- [README.md](/Users/jon/projects/parapet/README.md)
- [prompts/parapet-integration-opportunities.md](/Users/jon/projects/parapet/prompts/parapet-integration-opportunities.md)
- [prompts/parapet-engineering-dna-from-sibling-libs.md](/Users/jon/projects/parapet/prompts/parapet-engineering-dna-from-sibling-libs.md)
- [prompts/sre-observability-elixir-lib-deep-reseach.md](/Users/jon/projects/parapet/prompts/sre-observability-elixir-lib-deep-reseach.md)
- [prompts/sre-best-practices-solo-founder-deep-research.md](/Users/jon/projects/parapet/prompts/sre-best-practices-solo-founder-deep-research.md)
- Telemetry docs: https://hexdocs.pm/telemetry/telemetry.html
- Oban job lifecycle: https://hexdocs.pm/oban/job_lifecycle.html
- Oban telemetry: https://hexdocs.pm/oban/Oban.Telemetry.html
- Oban troubleshooting: https://hexdocs.pm/oban/troubleshooting.html
- Google sender guidelines FAQ: https://support.google.com/a/answer/14229414
