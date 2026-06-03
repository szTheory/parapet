# Phase 6: Fault-Domain Incident Enrichment - Context

**Gathered:** 2026-05-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Enrich Parapet incidents and operator context for async and delivery reliability so operators can tell which plane is failing before reaching for logs.

This phase is about durable classification, ordered evidence, and exact operator-owned follow-up seams for async and delivery incidents. It does **not** add broad task management, provider-console forensics, raw event persistence, or autonomous recovery behavior. Recovery templates and host-owned actions remain Phase 7 work.

</domain>

<decisions>
## Implementation Decisions

### Incident enrichment shape
- **D-01:** Use a **hybrid split** for incident enrichment.
- **D-02:** Store the **current bounded classification summary** in `incident.runbook_data`, optimized for list/detail reads and generated operator UI surfaces.
- **D-03:** Store the **append-only classification history and evidence rationale** in `TimelineEntry` records of type `triage_snapshot`.
- **D-04:** `runbook_data` is the current-state summary only. It must not become a hidden timeline or a dumping ground for wide evidence.
- **D-05:** `triage_snapshot` entries explain why the current classification was made or changed, including bounded evidence facts and refs to wider evidence when needed.
- **D-06:** `Parapet.Spine.AlertProcessor` should own the summary write and snapshot append in one transactional path so the two layers cannot drift.
- **D-07:** The bounded current summary should include fields in this shape, or an equivalent validated shape:
  - `integration`
  - `symptom`
  - `fault_plane`
  - `impact`
  - `queue`
  - `pipeline_stage`
  - `delay_bucket`
  - `failure_class`
  - `next_safe_action`
  - `confidence`
- **D-08:** If the Phase 6 incident summary contract hardens further, it may later graduate from a free-form map into an embedded Ecto structure. Phase 6 should keep the external operator semantics stable either way.

### Operator-facing classification
- **D-09:** The incident detail surface should show a **compact structured triage block** at the top, not plane badges alone and not free-form root-cause prose.
- **D-10:** The top block should answer, in order:
  - `Symptom`
  - `Likely plane`
  - `Why we think that`
  - `Safe next step`
- **D-11:** The `Why we think that` section should use **2-4 ordered bounded facts**, not an essay.
- **D-12:** Plane badges such as `provider`, `webhook`, `suppression`, `worker`, and `backlog` should remain visible, but only as supporting labels inside the structured triage block.
- **D-13:** The top block should be explicitly evidence-backed and deterministic. Avoid AI-ish freeform summaries and avoid any UI-only inference that cannot be traced back to durable evidence.
- **D-14:** The operator surface should optimize for decision speed while still preserving the project rule that Grafana and provider consoles remain external, linked tools rather than reimplemented dashboards.

### Ordered evidence model
- **D-15:** Use a **hybrid evidence presentation**:
  - a stable top card for current incident state;
  - immediately followed by a normalized chronology block as the primary evidence surface.
- **D-16:** The chronology block is the **authoritative source for sequence**. The top card is an index into that evidence, not a second source of truth.
- **D-17:** The chronology should emphasize typed, explicit rows over prose whenever possible, for example:
  - `alert_fired`
  - `triage_snapshot`
  - `provider_feedback_missing`
  - `queue_age_bucket_changed`
  - `callback_delay_observed`
  - `action_item_created`
  - `operator_action_taken`
- **D-18:** The chronology should preserve async and delivery causality cleanly enough that an operator can distinguish:
  - provider acceptance vs confirmed delivery
  - retryable failure vs discarded work
  - webhook delay vs internal backlog
  - suppression drift vs provider degradation
- **D-19:** Do not make operators reconstruct sequence from mutable summary prose. Sequence belongs in the durable timeline.

### Durable follow-up policy
- **D-20:** Create `ActionItem`s **only for exact async or delivery objects that require manual operator intervention**.
- **D-21:** Do **not** use `ActionItem` as a generic incident-task system and do **not** create diagnostic todos for every alert symptom.
- **D-22:** Broad investigation guidance belongs in runbooks, timeline entries, or linked external systems, not in `ActionItem`.
- **D-23:** Good Phase 6 `ActionItem` candidates include:
  - discarded or dead-lettered exact work items
  - stale workflow or exact execution records
  - orphaned callback or reconciliation objects
  - exact suppressed delivery records needing manual follow-up
- **D-24:** `ActionItem.external_id` remains the seam for exact high-cardinality identifiers that must survive into operator workflows without entering metrics labels or generic incident metadata.
- **D-25:** The current `ActionItem` shape is intentionally too thin for broad task management. If Phase 6 needs more precision, prefer narrow additions such as:
  - `incident_id`
  - bounded `kind`
  rather than growing it into a full ticketing subsystem.
- **D-26:** Exact-item follow-up should be dedupable and resolvable by key. Preserve the existing idempotent posture.

### Incident wording
- **D-27:** Keep incident titles **compact, stable, and symptom-first**.
- **D-28:** Do **not** encode inferred fault-plane conclusions directly into the primary incident title unless the plane is directly observed and durable for the whole incident lifecycle.
- **D-29:** Use the title grammar:
  - `<integration> <symptom slice>`
- **D-30:** Put fault-plane separation and operator guidance in a **structured subtitle or summary**, not only in the title.
- **D-31:** The structured subtitle or summary should carry:
  - `Likely plane`
  - `Observed symptom`
  - `Impact`
  - `Why this is not the other plane`
  - `Next safe action`
- **D-32:** Title and summary wording must preserve the milestone’s core distinctions:
  - acceptance is not delivery;
  - callback delay is not backlog;
  - retryable failure is not discarded work;
  - suppression drift is not generic provider failure.

### GSD decision policy
- **D-33:** Shift routine implementation decisions left within GSD by default for this phase and adjacent work.
- **D-34:** Auto-decide internal, reversible, non-public choices when they preserve Parapet’s existing doctrine:
  - explicit over magical;
  - host-owned over opaque;
  - low-cardinality by default;
  - telemetry as public API;
  - evidence/actions kept separate from telemetry.
- **D-35:** Escalate only decisions with real blast radius, especially:
  - public or durable contract changes;
  - operator semantics or page-on-user-harm changes;
  - host-owned install/generator behavior changes;
  - broader autonomy or mutation authority;
  - anything that threatens compile-out, least surprise, or label safety.
- **D-36:** In practice, internal helper names, reversible implementation details, correlation heuristics, and view-model shaping are agent decisions unless they materially alter operator meaning or public stability.

### the agent's Discretion
- **D-37:** Exact internal module names, helper layout, and validation plumbing for Phase 6 enrichment.
- **D-38:** Exact bounded field names within the current incident summary map, as long as they remain coherent with the Phase 4 and 5 taxonomy.
- **D-39:** Exact timeline entry payload keys and rendering components, as long as chronology stays authoritative and UI inference does not become a second classification engine.
- **D-40:** Exact narrow schema additions to `ActionItem`, if needed, as long as it remains an exact-item follow-up seam rather than a generic task system.

</decisions>

<specifics>
## Specific Ideas

- The ideal incident detail page should feel like:
  - a compact triage card up top;
  - an explicit chronology underneath;
  - deep links outward to Grafana, provider consoles, and runbooks;
  - exact action items only when one concrete object needs human intervention.
- Use a bounded current-state summary plus append-only evidence history, similar to mature incident products that keep incident-level fields for routing/reporting and a separate authoritative timeline for chronology.
- Keep titles short and durable, for example:
  - `Mailglass callback freshness burn`
  - `Rindle queue freshness burn`
  - `Chimeway callback confirmation degradation`
- Keep richer operator guidance in structured summary fields, for example:
  - `Likely plane: webhook delay`
  - `Why: provider accepts normal, queue healthy, confirmations delayed >10m`
  - `Next safe action: inspect callback ingress and signature failures`
- Preserve the project posture that Parapet is an evidence-first operator layer, not a provider-console clone and not a mini ticketing platform.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked upstream decisions
- `.planning/ROADMAP.md` — active v0.7 roadmap and Phase 6 scope boundary
- `.planning/REQUIREMENTS.md` — `TRIAGE-02`, `TRIAGE-03`, and `RNBK-03`
- `.planning/PROJECT.md` — product thesis, evidence-first doctrine, host-owned stance, low-cardinality rules
- `.planning/STATE.md` — current milestone position
- `.planning/v0.7-phases/4/4-CONTEXT.md` — locked async/delivery contract, bounded taxonomy, and fault-plane semantics
- `.planning/v0.7-phases/5/5-CONTEXT.md` — locked alert semantics, provider slices, and operator-facing distinctions

### Existing milestone research
- `.planning/research/SUMMARY.md` — build order and v0.7 architecture priorities
- `.planning/research/ARCHITECTURE.md` — explicit recommendation to enrich incidents in `AlertProcessor`, classify fault domains durably, and keep `ActionItem` narrow
- `.planning/research/FEATURES.md` — operator expectations and async/delivery workflow framing
- `.planning/research/PITFALLS.md` — operator UX and classification footguns for this milestone

### Product and engineering doctrine
- `prompts/PARAPET-GSD-IDEA.md` — product principles: page on user harm, evidence-first, host-owned, operator-grade DX
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — inherited OSS and DX defaults
- `prompts/prior-art/threadline-audit-lib-domain-model-reference.md` — separation of capture, semantics, and exploration layers
- `prompts/sre-best-practices-solo-founder-deep-research.md` — incident, runbook, and operator-workflow guidance relevant to human-scale reliability operations

### Existing code and docs baseline
- `docs/operator-ui.md` — current evidence-first operator UI doctrine
- `docs/telemetry.md` — Phase 4 async/delivery public telemetry contract
- `docs/slo-reference.md` — Phase 5 slice semantics and runbook posture
- `lib/parapet/spine/alert_processor.ex` — incident creation and enrichment seam to extend
- `lib/parapet/spine/incident.ex` — current incident durable shape
- `lib/parapet/spine/timeline_entry.ex` — append-only evidence seam
- `lib/parapet/spine/action_item.ex` — exact-item follow-up seam
- `lib/parapet/operator.ex` — operator detail/action boundary
- `lib/parapet/operator/workbench_contract.ex` — derived operator-facing current-state contract
- `lib/parapet/integrations/scoria.ex` — prior exact-item action item pattern
- `test/parapet/operator/workbench_contract_test.exs` — current derivation expectations
- `test/parapet/evidence/action_item_test.exs` — current action item behavior
- `test/parapet/spine/alert_processor_test.exs` — current alert ingestion behavior

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Spine.AlertProcessor` is already the right seam for alert-to-incident enrichment and should remain the single general incident-ingestion path.
- `Parapet.Operator.WorkbenchContract` already provides the correct place to derive operator-ready fields from durable evidence rather than pushing classification into LiveView templates.
- `Parapet.Spine.ActionItem` already establishes the narrow exact-object follow-up pattern via `integration`, `external_id`, and `state`.
- `Parapet.Integrations.Scoria` already demonstrates the intended exact-item workflow pattern: create one durable object-scoped follow-up record when there is an exact stalled thing to act on.

### Established Patterns
- The repo consistently separates telemetry, durable evidence, and operator actions.
- Generated host-owned UI is a consumer of durable facts, not the inventor of operational truth.
- Optional integrations compile out cleanly and the project avoids hidden control-plane behavior.
- Phase 4 and 5 already locked the semantics that Phase 6 must preserve:
  - provider vs webhook vs suppression vs worker vs backlog;
  - acceptance vs delivery;
  - retryable vs discarded;
  - callback delay vs queue backlog.

### Integration Points
- `AlertProcessor` should write the Phase 6 current summary into `incident.runbook_data` and append `triage_snapshot` entries transactionally.
- `WorkbenchContract` should derive the compact top triage block from durable summary fields and timeline evidence, not from ad hoc string parsing.
- `Operator` and generated UI should render:
  - the compact structured triage block;
  - the normalized chronology block;
  - exact action items when present;
  - links out to external observability and runbook tools.
- `ActionItem` usage should stay narrow enough that Phase 7 runbooks can layer on top cleanly without inheriting a generic task-management subsystem.

</code_context>

<deferred>
## Deferred Ideas

- Broad incident task management with owners, SLA, and generic diagnostic todos.
- Provider-console-style message forensics or per-item dashboards.
- Writing raw async/provider event streams into Ecto.
- Automatic or hidden remediation, replay, or retry flows.
- Broadening incident titles into mutable inferred root-cause narratives.
- Any UI-driven classification engine that reverse-engineers fault domains from alert strings instead of durable evidence.

</deferred>

---

*Phase: 6-fault-domain-incident-enrichment*
*Context gathered: 2026-05-17*
