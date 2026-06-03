# Phase 2: In-App Operator UI (LiveView) - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Provide a Phoenix LiveView surface for operators to view incident states and execute verifiable, secure mitigations. The UI is an action-and-explanation surface, not a Grafana replacement. External charts stay external; the LiveView owns incident workflow, evidence, approvals, and links.

</domain>

<decisions>
## Implementation Decisions

### UI shape
- **D-01:** Make the primary experience a desktop-first split-view incident workbench.
- **D-02:** Left pane shows incident queue and state counts; main pane shows the selected incident timeline and evidence; right rail shows compact actions, links, and operator context.
- **D-03:** On mobile, collapse to index/detail routes but keep the same URL-driven selection model.

### Operator signal density
- **D-04:** Show one-screen operational summary in LiveView: severity, state, affected journey, impact sentence, correlated change, top facts, top hypotheses, next safe action, approvals, and recent timeline events.
- **D-05:** Link to Grafana and runbooks instead of embedding charts or long procedure text in the primary view.
- **D-06:** Keep the UI calm and evidence-first. Do not make operators hunt through tabs for the basic answer to “what is hurting users and what should I do next?”

### Mitigation model
- **D-07:** Ship a small set of first-class, approval-gated mitigation flows rather than a generic action runner.
- **D-08:** The first-class flows should cover the obvious incident actions: mark investigating, open runbook, attach deploy/change marker, record note/hypothesis, request approval for flag disable, and approve/reject an AI recommendation.
- **D-09:** If more generality is needed later, keep it behind the scenes as a shared action envelope, not as the primary operator surface.

### Timeline model
- **D-10:** Treat the incident timeline as append-only for facts.
- **D-11:** Allow only lightweight curation of operator-authored narrative fields such as note title, note body, and manually added context entries.
- **D-12:** Never allow edits or deletes of factual records after execution. State transitions, approvals, tool actions, deploy markers, and flag toggles stay immutable.

### Security seam
- **D-13:** Use generator-first host-owned router scaffolding for mounting the LiveView.
- **D-14:** The host owns path, `pipe_through`, `live_session`, auth, and authorization.
- **D-15:** Parapet may provide thin route helpers or UI composition helpers, but they must not own auth or tenancy and must only be used inside an already-authenticated host scope.
- **D-16:** Expand the doctor surface/docs to validate that the operator UI is mounted behind host auth.

### Action auditing
- **D-17:** Every mutating mitigation must write state change, timeline entry, and audit record together in one transactional unit.
- **D-18:** Mutation payloads must carry actor, reason, correlation id, and idempotency semantics explicitly.
- **D-19:** Tool audits should never be treated as raw debug dumps; they are operator evidence with controlled exposure.

### the agent's Discretion
- **D-20:** Exact visual styling, spacing, loading states, and microcopy.
- **D-21:** Whether the first release includes inline approvals for a specific sibling integration, as long as the base incident console remains complete without sibling libs.
- **D-22:** Exact empty state copy and incident list sorting rules.

</decisions>

<specifics>
## Specific Ideas

- Keep Grafana as the exploration surface and LiveView as the decision/action surface.
- Keep runbooks as the procedure surface.
- Prefer explicit, human-readable incident summaries over dense telemetry blobs.
- Use the wording pattern from the research docs: facts, hypotheses, recommendation, action taken.
- Reference lessons from incident.io, FireHydrant, PagerDuty, and LiveDashboard, but do not copy their UI shapes wholesale.

</specifics>

<canonical_refs>
## Canonical References

### Phase scope
- `.planning/milestones/v0.2-ROADMAP.md` — phase goal, success criteria, and dependency boundary
- `.planning/milestones/v0.2-REQUIREMENTS.md` — UI requirements UI-01 through UI-04

### Existing project context
- `.planning/PROJECT.md` — product thesis, constraints, and non-goals
- `.planning/STATE.md` — current project priorities and locked decisions
- `.planning/research/SUMMARY.md` — durable evidence spine vs operator UI split
- `.planning/research/FEATURES.md` — operator UI expectations and anti-features
- `.planning/research/PITFALLS.md` — scope traps and implementation footguns
- `.planning/research/ARCHITECTURE.md` — implementation boundaries and layering

### Existing code
- `lib/parapet/evidence.ex` — public evidence boundary for incident/timeline/tool-audit writes
- `lib/parapet/spine/incident.ex` — incident schema and state machine
- `lib/parapet/spine/timeline_entry.ex` — incident timeline schema
- `lib/parapet/spine/tool_audit.ex` — audited tool-call schema
- `lib/mix/tasks/parapet.doctor.ex` — existing auth/router security checking pattern

### Product and engineering doctrine
- `prompts/PARAPET-GSD-IDEA.md` — product thesis, operator-grade DX, host-owned/composable stance
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — OSS discipline, host-owned setup, optional dependency posture
- `prompts/parapet-integration-opportunities.md` — Tier-1 ecosystem seams and follow-on boundaries
- `prompts/prior-art/threadline-audit-lib-domain-model-reference.md` — timeline, operator view, semantic action, and audit UX lessons
- `prompts/prior-art/chimeway-host-app-integration-seam.md` — host-owned auth, router mount, and LiveView seam guidance
- `prompts/prior-art/rulestead-telemetry-observability-and-audit.md` — audited action semantics and mutation trust model
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — SRE control-loop lessons, LiveDashboard/PromEx boundaries, and incident/runbook composition

### Decision inputs from prior discussion
- No exact sibling integration is required for Phase 2 to feel complete.
- Grafana remains external.
- The UI must be useful before Rulestead, Mailglass, Chimeway, or Threadline integrations are enabled.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Evidence` already gives a public boundary for incident and timeline writes.
- The three spine schemas already map cleanly to list, timeline, and audit surfaces.
- `Mix.Tasks.Parapet.Doctor` already models a host-mounted security check pattern for operator-facing surfaces.

### Established Patterns
- The repo already prefers host-owned generated setup over hidden magic.
- The project already separates ephemeral telemetry from durable evidence.
- Current research and prior art both favor explicit context and explicit audit trails for mutations.

### Integration Points
- Host router scopes and `live_session` are the correct mounting point.
- Incident list/detail data will come from the evidence spine.
- Mutations should flow through context functions that can be audited and tested independently of LiveView.

</code_context>

<deferred>
## Deferred Ideas

- Generic “run any action” mitigation framework.
- A board/Kanban-style incident layout.
- Rebuilding Grafana-style charts inside LiveView.
- Full autonomous AI operator behavior.
- Making sibling integrations required for the base UI.
- Richer incident states beyond `open`, `investigating`, and `resolved` unless the spine itself changes.

</deferred>

---

*Phase: 2-in-app-operator-ui*
*Context gathered: 2026-05-11*
