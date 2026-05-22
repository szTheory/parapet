# Phase 4: Operator UI Surfacing - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose automated actions and pending escalations to human operators inside the generated Phoenix LiveView Incident detail surface.

This phase adds operator-facing escalation and automation visibility, distinct system-action styling, and bounded manual escalation controls. It does not turn Parapet into a full incident-management control plane, a second scheduler, or a vendor-style NOC console.

</domain>

<decisions>
## Implementation Decisions

### Page structure and information hierarchy
- **D-01:** Use an **action/status summary first, evidence timeline immediately below** layout on the Incident detail page.
- **D-02:** The above-the-fold summary should answer present-tense operator questions first: current incident state, likely fault plane, impact, next safe action, whether the system already acted, and time until next escalation when applicable.
- **D-03:** The full timeline remains the durable chronological record and should stay immediately below the summary rather than being buried behind tabs or separate screens.
- **D-04:** Dangerous controls should appear **after** enough current-state context is visible, not ahead of it.

### Escalation chain surfacing
- **D-05:** Use a **hybrid escalation presentation**: a small current-status escalation panel in the summary area plus the full durable escalation evidence in the canonical timeline.
- **D-06:** The escalation panel must be a **read-only projection of durable truth** derived from incident state plus timeline/evidence data. It must not become a second state machine.
- **D-07:** The panel should surface only bounded current-state facts such as current escalation status, next planned escalation step, relevant suppression state, and countdown/time-until-next-escalation where available.
- **D-08:** Countdown or “next escalation” UI must never be authoritative on its own. Worker execution and durable evidence remain the source of truth.

### System-vs-human action distinction
- **D-09:** Keep **one canonical timeline**, not a separate equal-weight “automation history” narrative.
- **D-10:** Within that single timeline, use **stronger but calm card-level visual distinction** for system-executed entries and escalation-related events.
- **D-11:** Differentiate actor classes explicitly in the UI and payload semantics: human operator, system automation, and AI/copilot-style assistance must not blur together.
- **D-12:** Do not rely on subtle badges or color alone. Distinction should remain obvious under stress and accessible without turning the UI into “incident war room” theater.

### Manual escalation controls
- **D-13:** Provide a bounded manual control surface with:
  - manual `trigger next escalation`
  - temporary `suppress/cancel pending escalation` behavior
- **D-14:** Do **not** ship a full override control plane in this phase. No rescheduling, rerouting, or deep manual policy editing from the UI.
- **D-15:** “Suppress/cancel” must mean a **durable, expiring command state** checked by workers at execution time, not direct Oban job surgery and not hidden UI-only state.
- **D-16:** Every risky manual control must require explicit actor/reason metadata and must write durable timeline and audit evidence atomically through the existing audited operator seam.
- **D-17:** Manual escalation and manual suppression are distinct operator intents and should be modeled separately from acknowledge/resolve.

### Product posture and planning preference
- **D-18:** This phase should optimize for **evidence-first operator clarity**, not generic dashboard flexibility and not enterprise-style control-plane breadth.
- **D-19:** Preserve the host-owned, generator-first posture: Parapet supplies the paved road and derived workbench contract, while adopters retain inspectable LiveView code and policy ownership.
- **D-20:** For this phase and similar future planning work, downstream agents should default to **deep recommendation-first synthesis** using repo doctrine and prior art, and only escalate ambiguities to the user when they are genuinely high-impact.

### the agent's Discretion
- **D-21:** Exact naming of workbench projection fields and component/module names.
- **D-22:** Exact HEEx structure, spacing, iconography, and styling tokens, as long as the overall visual tone stays calm, legible, and non-theatrical.
- **D-23:** Exact timeline row taxonomy and grouping strategy, as long as the single-chronology rule and explicit actor distinction remain intact.
- **D-24:** Exact suppression expiry UX and optimistic-locking details, as long as durable truth and audited commands remain the underlying control seam.

</decisions>

<specifics>
## Specific Ideas

- Prefer a workbench that feels like an operator tool, not a Datadog clone and not a pager-vendor console.
- The right mental model is:
  - current truth first
  - durable chronology second
  - risky controls after understanding
- Acknowledge, suppress, and escalate are different operator intents and should not be collapsed into one action cluster.
- “System acted” should be unmistakable, but the UI should still feel calm and protective rather than noisy or militarized.
- Future GSD/planning behavior should shift left toward stronger autonomous synthesis and fewer routine user questions; only truly consequential gray areas should surface.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and product constraints
- `.planning/ROADMAP.md` — active v0.8 roadmap and exact Phase 4 scope
- `.planning/REQUIREMENTS.md` — `UI-01` requirements and acceptance criteria
- `.planning/PROJECT.md` — product thesis, host-owned posture, evidence-first constraints, and operator-workbench philosophy
- `.planning/STATE.md` — current project state and recently locked v0.8 decisions

### Prior v0.8 phase decisions
- `.planning/research/PHASE-1-ESCALATION-DECISIONS.md` — escalation worker posture, graceful exit semantics, and evidence expectations
- `.planning/research/PHASE-1-ESCALATION-ENGINE.md` — escalation engine architecture context
- `.planning/research/PHASE-2-RECOMMENDATIONS.md` — prior operator UI recommendation for contextual incident timelines
- `.planning/research/PHASE-3-DECISIONS.md` — circuit-breaker, human override, and panic-button distinctions that constrain UI wording and controls

### Product and operator research
- `.planning/research/FEATURES.md` — operator expectations for evidence, next safe action, and incident framing
- `.planning/research/PITFALLS.md` — operator UX and reliability footguns to avoid
- `.planning/research/SUMMARY.md` — milestone arc and coherence with the broader product direction
- `prompts/PARAPET-GSD-IDEA.md` — core product doctrine and non-goals
- `prompts/parapet-brand-identity-deep-research.md` — calm/protective visual and product identity constraints
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned generator and operator-UX expectations
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — SRE/product lessons on symptom-first, evidence-rich operator tooling
- `prompts/sre-best-practices-solo-founder-deep-research.md` — low-noise, actionable, user-harm-oriented product posture

### Prior-art doctrine
- `prompts/prior-art/threadline-audit-lib-domain-model-reference.md` — action vs change vs timeline separation; durable evidence posture
- `prompts/prior-art/rulestead-telemetry-observability-and-audit.md` — telemetry-vs-audit separation and explicit event semantics

### Existing code and current UI baseline
- `lib/parapet/operator.ex` — existing audited operator command seam
- `lib/parapet/operator/workbench_contract.ex` — derived workbench projection layer to extend rather than bypass
- `lib/parapet/automation/executor.ex` — current system automation identity and breaker-triggered escalation behavior
- `lib/parapet/escalation/worker.ex` — escalation execution and short-circuit behavior
- `lib/parapet/evidence.ex` — transactional evidence-writing seam
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — current Incident detail LiveView generator baseline
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — current component baseline for summary, timeline, and actions
- `test/parapet/operator/workbench_contract_test.exs` — existing derived-workbench behavior that Phase 4 should extend
- `test/parapet/operator_ui_integration_test.exs` — generator/UI integration expectations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Operator.WorkbenchContract`: already centralizes derived operator-facing state and is the correct seam for summary-panel projection logic.
- `Parapet.Operator`: already provides the audited, Phoenix-free command boundary that new manual escalation controls should extend.
- `Parapet.Evidence.run_operator_command/1`: already gives the transactional incident/timeline/audit seam needed for risky controls.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`: already establishes the generated detail-page surface and event-handling pattern.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex`: already provides summary/timeline/action component structure that can be refactored rather than replaced.

### Established Patterns
- Host-owned generator output is the expected UI posture; Parapet should provide inspectable templates, not an opaque internal console.
- Timeline entries are the durable evidence spine; derived UI state should project from them rather than invent alternate truth sources.
- Automation already uses explicit reserved actor identity (`system:automation:executor`), which should remain visible and semantically distinct.
- Existing workbench tests already validate bounded derived fields and should be extended as the proof surface for new UI projections.

### Integration Points
- Extend `WorkbenchContract` with escalation-summary and actor-distinction fields.
- Extend `Parapet.Operator` with bounded manual escalation/suppression commands rather than embedding DB mutations in LiveView.
- Add new timeline/audit event types through the existing evidence seam so the summary panel can project from durable records.
- Update generated `operator_detail_live` and `operator_components` templates to use the new summary, timeline variants, and control surface.

</code_context>

<deferred>
## Deferred Ideas

- Full manual escalation policy editing or rerouting from the UI
- Direct job-level scheduler manipulation or Oban control-panel behavior
- A separate equal-weight automation console distinct from the canonical incident timeline
- Vendor-style incident-management breadth such as ownership workflows, comms orchestration, or advanced on-call routing features

</deferred>

---

*Phase: 4-operator-ui-surfacing*
*Context gathered: 2026-05-19*
