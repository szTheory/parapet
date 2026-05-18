# Architectural Research & Recommendations: Phase 1 (Durable Escalation Engine)

## Executive Summary
This report addresses the three gray areas for implementing the Durable Escalation Engine in Parapet. The recommendations are strictly grounded in Parapet's engineering DNA, as distilled from sibling libraries (Sigra, Rulestead, Threadline): keeping optional dependencies truly optional, favoring explicit runtime configuration over global state, and ensuring transactional durability for critical operator paths.

---

## 1. Oban Dependency Model
**Gray Area:** Should Oban be required, polymorphic (Native + Oban), or just an optional worker?

**Analysis:**
- **DNA Constraints:** "Keep optional dependencies truly optional; they must compile out cleanly and fail with structured guidance only when the related feature is enabled."
- **Goal Constraint:** A "Durable Escalation Engine" fundamentally requires a durable, retriable queue. Native BEAM schedulers (like `Task.Supervisor` or `Process.send_after`) are ephemeral and cannot guarantee escalations will survive node restarts or crashes.

**Recommendation: The Polymorphic Dispatcher Seam**
Keep Oban `optional: true` in `mix.exs`. Introduce a `Parapet.Escalation.Dispatcher` behaviour.
- **`Parapet.Escalation.ObanDispatcher`**: The official, production-grade implementation that leverages Oban. It compiles out if Oban is missing.
- **`Parapet.Escalation.InlineDispatcher` / `TaskDispatcher`**: A fallback implementation for dev/test environments or users who explicitly opt out of durability.

**Rationale:** This maintains the library's "batteries-included but optional" promise. Developers get the robust Oban implementation by default if Oban is present, but aren't forced to install a heavy dependency if they only want Parapet's core telemetry or lightweight features. It aligns perfectly with how `Parapet.Probe` is currently architected.

---

## 2. Escalation Policy Configuration
**Gray Area:** Should `Parapet.Escalation.Policy` be global (`config :parapet`), per-Runbook/Incident, or a mix?

**Analysis:**
- **DNA Constraints:** "Prefer runtime options and explicit adapter seams over hidden global config."
- **Solo Founder DX:** Solo founders need strong defaults but also require granular control (e.g., SEV-1 pages the founder, SEV-3 just creates a ticket). The Runbook is the natural domain entity that knows how to handle a specific class of incident.

**Recommendation: Runbook-Driven with a Unified Fallback**
Define the primary escalation policy directly within the `Parapet.Runbook` DSL (which maps well to the upcoming Phase 2 `auto_execute` goals). If an incident is created without a specific Runbook—or the Runbook lacks an explicit policy—it falls back to a default policy provided during Parapet's runtime initialization (e.g., passed to the Parapet Supervisor or Host module), *not* via `config :parapet`.

**Rationale:** This fulfills the principle of least surprise. The escalation path is explicitly declared right next to the mitigation instructions (`Parapet.Runbook`). It eliminates hidden global state while still providing a safety net (the default policy) so no incident is silently dropped.

---

## 3. Incident Lifecycle Integration
**Gray Area:** How should the escalation job be enqueued? Directly in Ecto Multi, via Telemetry, or explicitly by caller?

**Analysis:**
- **DNA Constraints:** Rulestead prior-art mandates atomic writes: "Every admin mutation uses Ecto.Multi with both the mutation and the audit insertion in the same transaction." Furthermore, the DNA states: "Separate telemetry from durable audit/evidence. They solve different problems." Telemetry is explicitly designated as ephemeral and lossy compared to durable control flows.
- **Transactional Guarantees:** If we enqueue via Telemetry, the node could crash between the DB commit and the event handler execution, permanently losing the escalation page. If we force explicit caller enqueuing, DX suffers and we risk human error.

**Recommendation: Direct Ecto.Multi Integration**
Enqueue the escalation job directly within the `Parapet.Evidence.create_incident/1` flow using `Ecto.Multi`. The `Parapet.Escalation.Dispatcher` behaviour should expose an `enqueue(multi, incident_changeset, policy)` callback.

**Rationale:** The idiomatic Elixir/Oban pattern is to use `Oban.insert/2` inside the same `Ecto.Multi` transaction that creates the source record. This guarantees transactional outbox semantics: the incident and the escalation job are committed atomically. Telemetry is purely for observation and should never be used for durable control flow. This approach guarantees zero lost pages while hiding the complexity from the caller.

---

## Synthesis: The "Perfect Recommendation"
By combining these three choices, we achieve a harmonious, robust architecture for Phase 1:

1. When `Parapet.Evidence.create_incident` is called, it initializes an `Ecto.Multi` transaction.
2. It inspects the associated `Runbook` for an `Escalation.Policy` (falling back to the runtime default if necessary).
3. It passes the `Multi`, the incident data, and the policy to the configured `Parapet.Escalation.Dispatcher`.
4. If the app uses Oban (the paved road), the `ObanDispatcher` injects an `Oban.insert` step directly into the `Multi`.
5. The Ecto transaction commits. The incident is durable, and Oban inherently guarantees the escalation is executed, retried, and tracked.

This design strictly adheres to Parapet's DNA: highly durable, transactionally safe, completely optional dependencies, and host-owned explicit configuration without magical global state.