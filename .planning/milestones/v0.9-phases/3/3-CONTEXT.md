# Phase 3: Operator UI Performance - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Keep the Operator UI incident queue responsive and calm under large-installation load. This phase covers incident-list query shape, queue browsing behavior, queue scope, bounded row density, live freshness behavior, and proof at 50k+ incidents. It does not add new operator capabilities or expand the incident domain model beyond what is needed to support scale-safe queue browsing.

</domain>

<decisions>
## Implementation Decisions

### Queue browsing model
- **D-01:** Use hybrid paged cursor navigation with streamed rows in-page, not offset pagination and not feed-style infinite scroll.
- **D-02:** Drive queue state from URL params via LiveView `handle_params/3` so views remain shareable, inspectable, and host-owned.
- **D-03:** Make the queue cursor deterministic with a stable tie-breaker. The intended ordering shape is active-state bucket first, then `updated_at`, then unique `id`.
- **D-04:** Stream only the current visible page/window into the DOM. Do not fetch or render the full incident list on mount.

### Default queue scope
- **D-05:** The default queue is active-only: `open` and `investigating`.
- **D-06:** Resolved incidents belong in a separate history view or explicit status filter, not inline in the default queue.
- **D-07:** Query and index design should optimize active queue and resolved history separately.

### Queue row density
- **D-08:** Use a medium-density, evidence-first row design for the primary queue.
- **D-09:** Each row should show bounded triage facts only: state, severity if present, symptom-first title, one compact secondary line from durable triage fields such as `integration`, `fault_plane`, `affected_journey`, or `queue`, plus a compact age/update indicator.
- **D-10:** Allow at most one compact attention chip per row such as correlated change, approval pending, or escalation waiting.
- **D-11:** Keep impact summary, next safe action, full evidence facts, escalation chain, external links, trace links, runbook steps, and chronology in the detail pane rather than the queue row.

### Freshness behavior under load
- **D-12:** Keep realtime awareness, but do not silently reorder the operator’s visible queue while they are reading it.
- **D-13:** Use an explicit "new incidents / changes available" affordance for background updates instead of fully live queue reordering.
- **D-14:** It is acceptable for selected-incident detail, counters, and status badges to update live while the queue itself stays operator-paced.

### Performance proof
- **D-15:** Phase 3 requires layered proof, not a single benchmark or a single test.
- **D-16:** Add a deterministic seeded integration test that proves the generated UI no longer loads the full queue and instead uses bounded cursor/stream behavior.
- **D-17:** Add a reproducible benchmark task for queue fetch plus first-render behavior at a 50k+ incident dataset. This benchmark is advisory or in a dedicated perf lane, not the default merge gate.
- **D-18:** Add telemetry instrumentation around queue/list behavior as a public proof surface, while keeping labels low-cardinality.

### Maintainer workflow preference
- **D-19:** For future gray-area discussions in this project, prefer research-first recommendation synthesis and recommended defaults over asking the user to decide every low-impact detail.
- **D-20:** Only escalate choices back to the user when they materially affect product posture, operator semantics, public API, or architectural direction.

### the agent's Discretion
- Exact cursor token encoding and helper API surface
- Exact page size inside the recommended bounded range
- Exact queue chip vocabulary and truncation rules
- Exact banner copy for "new incidents / changes available"
- Exact telemetry event names and benchmark harness layout, as long as they remain coherent with existing telemetry/API discipline

</decisions>

<specifics>
## Specific Ideas

- Recommendations should be coherent with Parapet’s evidence-first, calm, operator-grade posture rather than generic dashboard behavior.
- Prefer least-surprise behavior over "most LiveView-native" behavior when those differ for mutable operator queues.
- Developer ergonomics matter: generated host-owned UI should use explicit, inspectable Phoenix/Ecto patterns rather than magical abstractions.
- The user explicitly prefers research-first synthesis with subagent-backed recommendations and wants the builder to decide low-impact details by default.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements and project posture
- `.planning/ROADMAP.md` — Phase 3 scope and milestone intent
- `.planning/REQUIREMENTS.md` — active requirements and 50k+ acceptance criteria
- `.planning/PROJECT.md` — evidence-first product posture, constraints, and operator philosophy
- `.planning/config.json` — workflow defaults including research-first discussion preference

### Local research and product direction
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — OSS engineering defaults, host-owned posture, diagnostics-first product discipline
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — Parapet-specific observability/reliability product lessons and cardinality guardrails
- `prompts/elixir-telemetry-space-deep-research.md` — broader Elixir observability ecosystem lessons, telemetry posture, and generated integration strategy
- `prompts/parapet-brand-identity-deep-research.md` — calm, protective operator UX direction and brand-level least-surprise guidance
- `prompts/prior-art/SOURCE-CANONICAL.md` — prior-art index for sibling-library operational and evidence patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/parapet/operator.ex`: existing Phoenix-free queue/detail boundary; should own the scalable query API rather than pushing query logic into generated LiveViews
- `lib/parapet/operator/workbench_contract.ex`: already derives bounded operator-facing evidence fields suitable for medium-density queue rows and rich detail panes
- `lib/parapet/spine/incident.ex`: bounded triage summary contract gives a natural source for compact queue metadata without scanning full timelines per row
- `priv/templates/parapet.gen.ui/operator_live.ex.eex`: generated LiveView surface already provides the host-owned UI seam; it needs scalable queue loading rather than a conceptual rewrite
- `priv/templates/parapet.gen.ui/operator_components.ex.eex`: current three-pane IA remains reusable, but the queue component needs bounded row semantics and clearer active-only empty states

### Established Patterns
- Host-owned generated UI is a hard product posture; Parapet should expose clear query APIs and templates, not ship opaque runtime UI behavior
- Evidence-first detail rendering is already stronger than queue rendering; preserve that split instead of turning the queue into a second detail surface
- MCP and archiver surfaces already imply active-vs-history separation, which supports an active-only default queue
- Telemetry is treated as public API across the project, so operator performance instrumentation should follow the same discipline

### Integration Points
- Operator queue query API in `Parapet.Operator`
- Generated LiveView URL state and row rendering in `priv/templates/parapet.gen.ui/*`
- Phase 2 indexing/pruning work for queue/history query alignment
- Benchmark/test proof lanes in ExUnit plus an advisory perf harness

</code_context>

<deferred>
## Deferred Ideas

- Rich card-style queue variants or compact-vs-comfortable density toggles — defer unless active operator usage proves a real need
- History-focused analytics or retrospective browsing UX beyond a clean resolved-history view — separate phase/material scope
- Fully live reordering queues or feed-style incident browsing — intentionally out of scope for the primary operator workbench

</deferred>

---

*Phase: v0.9-phases/3*
*Context gathered: 2026-05-20*
