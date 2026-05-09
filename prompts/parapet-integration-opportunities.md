# Parapet integration opportunities

> Purpose: capture where Parapet can create real value for sibling libraries and their users, so the project is planned with ecosystem leverage instead of as an isolated observability add-on.

## Reader and intended use

Reader: the Parapet planner or maintainer deciding what to integrate now, later, or never.

Post-read action: choose Tier-1 integration seams for v0.1 and later milestones without re-deriving the jobs-to-be-done overlap.

## Tiering

- **Tier 1:** active planning inputs for Parapet. These should shape v0.1 and early milestones.
- **Tier 2:** real opportunities, but likely after the initial wedge.
- **Tier 3:** future ecosystem or speculative opportunities to keep in view.

## Tier 1

### Sigra

- Persona / JTBD: Phoenix teams need confidence in login, signup, MFA, session, passkey, and auth-admin reliability.
- Parapet value: auth is one of the clearest user-harm surfaces in a SaaS. Parapet can turn Sigra events into SLOs, burn-rate alerts, and investigation context.
- Likely seam:
  - login and signup journey SLIs;
  - MFA and passkey error-rate monitoring;
  - account lockout or suspicious-login signals;
  - deploy and feature correlation on auth regressions.
- v0.1 posture: design as a first-class reference integration, even if the shipped implementation is initially minimal.

### Chimeway

- Persona / JTBD: teams need reliable, explainable notification delivery and operator confidence.
- Parapet value: notification systems naturally produce retry, suppression, queue, and provider-health signals that benefit from reliability layering.
- Likely seam:
  - delivery latency and failure SLIs;
  - queue backlog / stuck delivery diagnostics;
  - provider or channel degradation markers;
  - “why wasn’t this sent?” evidence links between Parapet and Chimeway traces.
- v0.1 posture: treat notifications as one of the most natural Parapet domain examples.

### Threadline

- Persona / JTBD: teams need durable evidence for debugging, support, and audits.
- Parapet value: Threadline can provide durable incident context where telemetry alone is insufficient.
- Likely seam:
  - incident bundles linking metrics/traces to durable action/change history;
  - exportable evidence for customer-impact investigations;
  - health or coverage surfaces that explain what data can be trusted.
- v0.1 posture: plan for conceptual compatibility from day one, even if the integration is later than the first release.

### Mailglass

- Persona / JTBD: teams need transactional email that is explainable and operable.
- Parapet value: email deliverability and critical-email flows are user-harm domains, not just infrastructure domains.
- Likely seam:
  - password-reset and magic-link email health;
  - provider failure and suppression drift detection;
  - email deliverability diagnostics folded into broader reliability posture.
- v0.1 posture: use as a reference journey for user-facing harm and operator workflows.

### Rulestead

- Persona / JTBD: teams need deterministic runtime decisions and clear change provenance.
- Parapet value: feature flags and config changes are common incident causes. Correlating reliability regressions with config state is high leverage.
- Likely seam:
  - deploy and flag correlation markers;
  - exposure-aware reliability views;
  - change timelines and rollback guidance.
- v0.1 posture: plan for flag/change correlation as part of the Parapet mental model.

### Accrue

- Persona / JTBD: revenue-critical billing flows must fail loudly and explainably.
- Parapet value: billing is one of the strongest “page on user harm” examples.
- Likely seam:
  - checkout / subscription / webhook journey SLIs;
  - provider incident correlation;
  - revenue-impacting alert and runbook templates.
- v0.1 posture: include billing-path SLOs as an early milestone candidate or reference integration.

### Rindle

- Persona / JTBD: media uploads, processing, and delivery need durable operational confidence.
- Parapet value: async processing and external media provider workflows are rich reliability targets.
- Likely seam:
  - upload or processing funnel health;
  - provider webhook and job pipeline diagnostics;
  - operator runbooks for stalled processing or streaming-provider failures.
- v0.1 posture: use as a reference for async/operator-heavy workflows rather than a mandatory first shipped integration.

## Tier 2

### Lockspire

- Strong fit once Parapet expands into OAuth/OIDC-provider reliability, conformance, and operator visibility.
- Useful later for token, consent, and auth-provider operational journeys.

### Relyra

- Strong future fit for enterprise SSO login reliability, metadata lifecycle health, and certificate rollover diagnostics.
- Better as a later-phase integration after Parapet’s initial wedge is proven.

### Scrypath

- Useful for indexing drift, reindex operations, and search-availability SLIs.
- Valuable, but less universal than auth, notifications, billing, or email for the initial Parapet positioning.

## Tier 3

### Rendro and other narrower domain libs

- Potential later opportunities for document-generation reliability or workflow-specific observability.
- Not initial planning drivers.

### Scoria (AI App Quality & Observability)

- Persona / JTBD: Teams building chat, agents, and RAG need to treat AI operations with the same operational rigor as web requests — tracking token costs, latency, tool execution success, and eval regression rates.
- Parapet value: AI pipelines are notoriously flaky and expensive. Parapet can turn Scoria's OpenInference traces and eval scores into strict SLIs and burn-rate alerts, ensuring that prompt changes or model degradation trigger operator pages before users complain.
- Likely seams:
  - **OpenInference Metrics:** Parapet catching Scoria's `:telemetry` spans (LLM, RETRIEVER, TOOL) to generate token-count, cost-burn, and time-to-first-token Prometheus metrics.
  - **Eval-Driven SLOs:** Using Scoria's Evaluation Flywheel scores as a Parapet SLO (e.g., "95% of RAG answers score > 0.8 in LLM-as-a-judge").
  - **Prompt/Model Deploy Markers:** When Scoria changes an active prompt or model version, emitting a Parapet deploy marker to correlate with subsequent SLO burn rates.
  - **HITL Queue Health:** Tracking the depth and wait-time of Scoria's Human-in-the-Loop tool approval queues as an operational SLI.
- Posture: Mention in project context so Parapet's telemetry contract remains compatible with OpenInference conventions, but do not treat as a v0.1 requirement.

## Cross-lib patterns Parapet should deliberately support

- host-owned install and runtime;
- explicit telemetry contracts;
- durable evidence where it matters;
- doctor/diagnostics posture;
- deploy/change/flag correlation;
- operator-first explanation of failures;
- safe redaction across all surfaces.

## Planning defaults

- Treat `sigra`, `chimeway`, `mailglass`, `threadline`, `rulestead`, `accrue`, and `rindle` as active planning inputs.
- Use auth, notifications/email, and billing as the strongest early user-harm domains.
- Keep Threadline compatibility in mind if Parapet grows durable evidence or incident bundles.
- Record Lockspire, Relyra, Scrypath, and the future AI library as explicit follow-on opportunities, not silent assumptions.
