# Phase 7: Host-Owned Recovery Runbooks - Context

**Gathered:** 2026-05-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Generate safe, inspectable, host-owned recovery runbooks and narrow recovery seams for async and delivery incidents, on top of the Phase 6 evidence and triage model.

This phase is about operator guidance, preview-first recovery, bounded host-wired execution, and auditability. It does **not** add autonomous remediation, a generic workflow engine, a broad approval system, provider-console-style forensics, or broad bulk replay controls.

</domain>

<decisions>
## Implementation Decisions

### Runbook catalog shape
- **D-01:** Phase 7 should ship a **small fixed catalog of generated host-owned runbook modules**, not a generic end-user template composition API.
- **D-02:** The canonical built-in runbook classes for v0.7 are:
  - `stalled_executor`
  - `dead_letter`
  - `provider_outage`
  - `callback_delay`
- **D-03:** Parapet may use private helper macros/builders internally to avoid duplication, but the blessed public surface remains **concrete generated modules** with stable identities and stable step ids.
- **D-04:** The host owns the generated modules and may edit copy, links, thresholds, and which host-wired mitigation capabilities are enabled.
- **D-05:** Runbook schemas must stay bounded and predictable so the Phase 6 workbench contract remains deterministic and chronology-first.

### Recovery action contract
- **D-06:** Phase 7 should bless a **small named capability contract** as the public recovery API, not arbitrary runbook callback hooks as the primary surface.
- **D-07:** Parapet owns the **recovery vocabulary**; the host owns whether a capability exists, how preview is computed, and whether execution is allowed.
- **D-08:** Recovery capabilities remain **optional and host-wired**. If the host does not register a capability, Parapet shows guidance only.
- **D-09:** Runbook steps should reference **capability names**, not raw `{module, step}` pairs, as the blessed path.
- **D-10:** Initial v0.7 capability set should stay intentionally tiny:
  - `retry_async_item`
  - `requeue_dead_letter`
  - `request_manual_provider_check`
- **D-11:** Keep a compatibility escape hatch for bespoke host actions, but treat it as secondary/internal rather than the public Phase 7 contract.

### Preview and execution flow
- **D-12:** Default Phase 7 recovery flow is **preview -> confirm in Parapet -> execute**.
- **D-13:** `preview only -> execute elsewhere` remains a supported fallback for investigate-only actions or actions that Parapet should not execute directly.
- **D-14:** Native `request approval -> execute after approval` is **not** the default v0.7 Parapet operator flow. If approvals are required, prefer host-native or external approval systems.
- **D-15:** Every executable mitigation must expose a **preview contract** before it can expose an execute contract.
- **D-16:** Confirm must execute against a **reviewed preview token or snapshot** and fail closed if the preview is stale or the target set changed.
- **D-17:** The LiveView UI should use a dedicated preview/confirm panel or modal for mutating recovery actions. Plain `data-confirm`-style prompts are insufficient.

### Incident-level guidance vs exact-item recovery
- **D-18:** Runbooks remain primarily **incident-level guidance**. `ActionItem` remains the **exact-item recovery seam** and must not become a generic incident-task system.
- **D-19:** Retry, replay, resend, requeue, unsuppress, and any other object-level recovery must require an **exact target reference** and should default to `ActionItem`-scoped execution.
- **D-20:** Phase 7 may permit incident-level executable mitigations only in two categories:
  - read-only evidence collection
  - reversible bounded control-plane actions
- **D-21:** Incident-level executable steps must be explicitly host-wired, preview-first, idempotency-aware, and denied when the host cannot provide a bounded selector and preflight summary.
- **D-22:** Incident labels, titles, and free-form triage prose are never sufficient selectors for mutation. Execution must use declared bounded inputs from the runbook schema or exact item refs.
- **D-23:** Broad bulk replay, queue-wide retry, or provider-wide mutation should stay manual or host-specific unless the host can preview exact scope and prove safety.

### Preview, audit, and evidence shape
- **D-24:** A mitigation preview must include exact scope and bounded safety context, including:
  - capability
  - target kind
  - target refs or `ActionItem` refs
  - count / estimated scope
  - preconditions
  - warnings
  - idempotency caveats
  - staleness / expiry information
- **D-25:** The execute contract should require `ActionPayload` audit context plus an `idempotency_key` for mutating recovery actions.
- **D-26:** Preview and execution must both be auditable. Timeline should record reviewed scope and execution result, and `ToolAudit` should capture actor, reason, capability, selector/scope, and outcome.
- **D-27:** Ecto evidence stays compact:
  - incident summary in `runbook_data`
  - chronology in `TimelineEntry`
  - exact work in `ActionItem`
- **D-28:** Do **not** persist broad target sets or raw provider/job streams in Ecto just to support runbook execution.
- **D-29:** Exact high-cardinality targets belong in `ActionItem.external_id`, preview payload refs, or timeline/audit payloads, never metrics labels.

### Safety and product posture
- **D-30:** Phase 7 must optimize for **safe investigation and scoped recovery**, not “fewer clicks at any cost.”
- **D-31:** The library should not normalize generic automation-engine behavior, arbitrary script execution, or opaque recovery magic.
- **D-32:** Exact-item recovery is the default built-in action unit because idempotency and blast radius usually live at the object level, not the incident-summary level.
- **D-33:** Incident-scoped capabilities are acceptable only when they are reversible or read-only, have explicit success criteria, and do not depend on inferred exact targets.

### GSD decision policy
- **D-34:** Shift routine implementation decisions left within GSD by default for Phase 7 and adjacent work.
- **D-35:** Downstream agents should auto-decide ordinary implementation details when they preserve the locked doctrine:
  - explicit over magical
  - host-owned over opaque
  - preview-first over fire-and-forget
  - exact-item mutation over broad inferred mutation
  - evidence-first over control-plane sprawl
- **D-36:** Escalate only decisions with real blast radius, especially:
  - public capability vocabulary changes
  - changes to preview/confirm safety rules
  - any expansion toward bulk or autonomous recovery
  - any change that weakens auditability, host ownership, or exact-item discipline

### the agent's Discretion
- **D-37:** Exact internal module names, helper layout, and generator structure for the built-in runbook catalog.
- **D-38:** Exact preview payload field names, as long as the semantics above remain stable and explicit.
- **D-39:** Exact UI layout, copy, and modal/panel mechanics for preview and confirm flows, as long as the workflow remains evidence-backed and review-first.
- **D-40:** Whether to add one extra named built-in runbook class such as `safe_retry_decision`, provided it stays within the same fixed-catalog philosophy and does not broaden scope.

</decisions>

<specifics>
## Specific Ideas

- The desired operator experience is:
  - triage explains the failing plane;
  - runbook explains the safe next step;
  - preview shows the exact scope and risks;
  - confirm executes only the reviewed scope;
  - chronology records what was reviewed and what happened.
- The desired developer experience is:
  - generated host-owned modules;
  - a tiny named capability vocabulary;
  - explicit preview and execute callbacks;
  - no callback soup and no generic workflow DSL.
- Good incident-scoped executable steps:
  - collect bounded callback evidence
  - open or sync external provider status context
  - pause or resume a clearly bounded path when the host can preview the selector
- Good exact-item steps:
  - retry one dead-lettered job
  - requeue one exact async item
  - request manual follow-up on one suppressed or orphaned object

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked upstream decisions
- `.planning/ROADMAP.md` — active v0.7 roadmap and Phase 7 scope boundary
- `.planning/REQUIREMENTS.md` — `RNBK-01` and `RNBK-02`
- `.planning/PROJECT.md` — host-owned install model, evidence-first product posture, and out-of-scope autonomy boundaries
- `.planning/STATE.md` — current milestone position
- `.planning/v0.7-phases/4/4-CONTEXT.md` — locked async/delivery contract and bounded telemetry taxonomy
- `.planning/v0.7-phases/5/5-CONTEXT.md` — locked fixed-catalog and explicit provider posture from the SLO layer
- `.planning/v0.7-phases/6/6-CONTEXT.md` — locked triage, chronology, and exact `ActionItem` semantics

### Existing milestone research
- `.planning/research/ARCHITECTURE.md` — recommended v0.7 shape, generator-first runbook posture, and host-wired mitigations
- `.planning/research/FEATURES.md` — operator workflows and async/delivery recovery expectations
- `.planning/research/PITFALLS.md` — recovery safety and mis-scoping footguns
- `.planning/research/SUMMARY.md` — milestone arc and build-order guidance

### Product and engineering doctrine
- `prompts/PARAPET-GSD-IDEA.md` — product principles, especially evidence-first, host-owned, and page-on-user-harm
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — generator-first, explicit seam, diagnostics-first engineering defaults
- `prompts/parapet-integration-opportunities.md` — integration-specific operator goals for Mailglass, Chimeway, and Rindle
- `prompts/prior-art/SOURCE-CANONICAL.md` — prior-art index for mirrored doctrine
- `prompts/prior-art/threadline-audit-lib-domain-model-reference.md` — durable evidence, action semantics, and operator confidence layering
- `prompts/prior-art/chimeway-host-app-integration-seam.md` — embedded host-owned integration boundary

### Existing code and docs baseline
- `docs/operator-ui.md` — evidence-first operator UI doctrine and Phase 6 triage contract
- `lib/parapet/runbook.ex` — current runbook DSL and schema shape
- `lib/parapet/operator.ex` — current audited operator command seam and runbook execution path
- `lib/parapet/operator/action_payload.ex` — current audit payload contract
- `lib/parapet/operator/workbench_contract.ex` — current workbench-derived operator state
- `lib/parapet/spine/alert_processor.ex` — current triage summary and runbook attachment seam
- `lib/parapet/spine/action_item.ex` — exact-item durable follow-up seam
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — current operator detail flow to evolve for preview/confirm
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — current runbook and action rendering components
- `test/parapet/spine/alert_processor_test.exs` — triage and runbook attachment expectations
- `test/parapet/operator/workbench_contract_test.exs` — current workbench derivation expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Runbook` already provides a concrete module-based runbook schema, which favors a fixed generated catalog over a user-facing composition DSL.
- `Parapet.Operator.execute_runbook_step/3` already gives a narrow execution seam that can be tightened around preview-first capability execution.
- `Parapet.Operator.ActionPayload` already establishes the required audit metadata shape and should remain the basis for recovery commands.
- `Parapet.Spine.ActionItem` already gives the right exact-object seam for retries, requeues, and manual follow-up work.
- `Parapet.Operator.WorkbenchContract` already derives supporting operator state and can remain secondary to the chronology-first evidence surface.

### Established Patterns
- The repo consistently prefers explicit, host-owned seams over hidden runtime magic.
- Telemetry, durable evidence, and operator actions are already separated and should remain separate.
- Phase 5 already chose fixed catalogs and explicit registration over generic composition; Phase 7 should mirror that shape.
- Phase 6 already chose bounded summary + chronology + exact follow-up rather than broad task management.

### Integration Points
- Generated runbook modules should attach through the existing runbook module seam in incident `runbook_data`.
- Preview/confirm execution should evolve the current operator detail and runbook component templates instead of introducing a separate control-plane UI.
- Capability execution should flow through `Parapet.Operator` and `Parapet.Evidence.run_operator_command/1` so timeline and tool audit remain unified.
- Exact-item recovery should anchor to `ActionItem.external_id` or equivalent exact refs, not to inferred incident metadata.

</code_context>

<deferred>
## Deferred Ideas

- Generic end-user runbook composition DSL or mini workflow engine.
- Native Parapet approval queue as a first-class Phase 7 control plane.
- Broad bulk replay, queue-wide retry, or provider-wide mutation as normalized built-in actions.
- Autonomous remediation or auto-executed recovery policy.
- Persisting wide execution target sets or raw provider/job streams in Ecto to support operator actions.
- Provider-console-style forensic UIs or rich message-by-message dashboards.

</deferred>

---

*Phase: 7-host-owned-recovery-runbooks*
*Context gathered: 2026-05-18*
