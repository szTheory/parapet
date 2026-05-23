# Phase 6: Fault-Domain Incident Enrichment - Research

**Researched:** 2026-05-17
**Domain:** Durable incident enrichment and operator-facing classification for async and delivery alerts
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Phase Boundary

Enrich Parapet incidents and operator context for async and delivery reliability so operators can tell which plane is failing before reaching for logs.

This phase is about durable classification, ordered evidence, and exact operator-owned follow-up seams for async and delivery incidents. It does **not** add broad task management, provider-console forensics, raw event persistence, or autonomous recovery behavior. Recovery templates and host-owned actions remain Phase 7 work.

### Locked Decisions

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

### Claude's Discretion
- **D-37:** Exact internal module names, helper layout, and validation plumbing for Phase 6 enrichment.
- **D-38:** Exact bounded field names within the current incident summary map, as long as they remain coherent with the Phase 4 and 5 taxonomy.
- **D-39:** Exact timeline entry payload keys and rendering components, as long as chronology stays authoritative and UI inference does not become a second classification engine.
- **D-40:** Exact narrow schema additions to `ActionItem`, if needed, as long as it remains an exact-item follow-up seam rather than a generic task system.

### Deferred Ideas (OUT OF SCOPE)
- Broad incident task management with owners, SLA, and generic diagnostic todos.
- Provider-console-style message forensics or per-item dashboards.
- Writing raw async/provider event streams into Ecto.
- Automatic or hidden remediation, replay, or retry flows.
- Broadening incident titles into mutable inferred root-cause narratives.
- Any UI-driven classification engine that reverse-engineers fault domains from alert strings instead of durable evidence.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TRIAGE-02 | System enriches async and delivery incidents with fault-domain context that clearly separates internal backlog, worker failure, provider degradation, webhook delay, and suppression drift. | `## Summary`, `## Architecture Patterns`, `## File Recommendations`, `## Common Pitfalls`, `## Validation Architecture` |
| TRIAGE-03 | Operator can inspect async and delivery incidents with ordered evidence and clear classification before choosing a recovery path. | `## Summary`, `## Architecture Patterns`, `## File Recommendations`, `## Code Examples`, `## Validation Architecture` |
| RNBK-03 | System can create durable follow-up items only for exact operator-owned async or delivery work that requires manual action, without storing raw high-volume event streams in Ecto. | `## Summary`, `## Standard Stack`, `## Architecture Patterns`, `## Don't Hand-Roll`, `## Validation Architecture` |
</phase_requirements>

## Summary

Phase 6 should extend the existing alert-ingestion spine rather than add a parallel incident-classification subsystem. `Parapet.Spine.AlertProcessor` already owns alert correlation and `incident.runbook_data` writes, `TimelineEntry` already owns append-only evidence, and `Parapet.Operator.WorkbenchContract` already exists as the deterministic derivation seam for UI-facing state. The missing work is to make those seams speak the Phase 4 and Phase 5 async/delivery vocabulary directly: enrich every relevant firing alert with a bounded current summary, append a matching `triage_snapshot`, and derive a structured top-of-page triage block from durable evidence instead of from UI heuristics. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: docs/telemetry.md] [VERIFIED: docs/slo-reference.md] [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: lib/parapet/operator/workbench_contract.ex]

The current code is close enough to support this with small, deliberate changes. `Incident` already has a `:map` `runbook_data` field, `TimelineEntry` already supports typed map payloads, and `Evidence.run_operator_command/1` already demonstrates the repo transaction pattern the phase needs. At the same time, the current implementation has three concrete gaps that Phase 6 must close: firing alerts only insert and never refresh incident summaries, `WorkbenchContract` still derives generic severity/journey fields instead of fault-domain triage fields, and `ActionItem` has no incident linkage or bounded kind for rendering exact follow-up work under a specific incident. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: lib/parapet/spine/timeline_entry.ex] [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: lib/parapet/operator/workbench_contract.ex]

The implementation should stay evidence-first and phase-bounded. Do not persist raw async/provider events into Ecto, do not widen `ActionItem` into a ticketing system, and do not push plane inference into LiveView templates. Instead, treat Phase 5 alert labels and annotations as the bounded input contract, translate them into a validated incident summary plus ordered triage facts, and only create `ActionItem`s when the alert payload or follow-up callback points at one exact object that needs manual intervention. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: docs/operator-ui.md] [VERIFIED: lib/parapet/integrations/scoria.ex]

**Primary recommendation:** implement Phase 6 by adding a validated incident-summary embed inside `Incident.runbook_data`, moving async/delivery enrichment into a single `AlertProcessor` transaction that updates the summary and appends `triage_snapshot`, and narrowing `ActionItem` to incident-linked exact follow-up records with dedupe by `(incident_id, integration, external_id, kind)`. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: lib/parapet/spine/action_item.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Alert-to-incident enrichment | API / Backend | Database / Storage | `AlertProcessor` already correlates firing and resolved alerts and is the locked seam for writing incident state and timeline evidence. [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Current triage summary storage | Database / Storage | API / Backend | The current bounded summary belongs in `Incident.runbook_data` for cheap queue/detail reads and stable generated UI consumption. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Ordered classification history | Database / Storage | API / Backend | `TimelineEntry` is the authoritative append-only chronology surface and is already linked to incidents. [VERIFIED: lib/parapet/spine/timeline_entry.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Operator-ready triage derivation | API / Backend | Frontend Server (SSR) | `WorkbenchContract` is the existing deterministic projection seam; generated LiveView should consume that projection instead of inferring from strings. [VERIFIED: lib/parapet/operator/workbench_contract.ex] [VERIFIED: docs/operator-ui.md] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Exact follow-up work for one stuck object | Database / Storage | API / Backend | `ActionItem` is already the durable exact-object seam and Phase 6 explicitly keeps it narrow. [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: lib/parapet/integrations/scoria.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Dashboards, vendor consoles, and runbook pages | External dependency | Frontend Server (SSR) | The operator surface links outward instead of replacing Grafana or provider consoles. [VERIFIED: docs/operator-ui.md] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Ecto` | lockfile `3.13.6` in this repo. [VERIFIED: mix.lock] | Schema validation and durable writes for `Incident`, `TimelineEntry`, and `ActionItem`. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: lib/parapet/spine/timeline_entry.ex] [VERIFIED: lib/parapet/spine/action_item.ex] | Phase 6 only needs stronger schema structure and transaction composition, not a new persistence library. [VERIFIED: lib/parapet/evidence.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] |
| `Ecto.Multi` | bundled with `Ecto 3.13.6`. [VERIFIED: mix.lock] | Atomic summary update plus `triage_snapshot` append plus optional exact-item creation. [VERIFIED: lib/parapet/evidence.ex] | The phase’s locked decision is “one transactional path so the two layers cannot drift,” which maps directly to `Ecto.Multi`. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `Parapet.Spine.AlertProcessor` | in-repo seam. [VERIFIED: lib/parapet/spine/alert_processor.ex] | Canonical ingestion point for Alertmanager alerts. [VERIFIED: lib/parapet/spine/alert_processor.ex] | Reusing this seam preserves Phase 1 and Phase 6 doctrine and avoids a second incident path. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: test/parapet/spine/alert_processor_test.exs] |
| `Parapet.Operator.WorkbenchContract` | in-repo seam. [VERIFIED: lib/parapet/operator/workbench_contract.ex] | Deterministic view-model for queue/detail surfaces. [VERIFIED: lib/parapet/operator/workbench_contract.ex] | The generated Operator UI is supposed to consume durable facts, not invent them. [VERIFIED: docs/operator-ui.md] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `Parapet.Evidence` | in-repo seam. [VERIFIED: lib/parapet/evidence.ex] | Existing transactional wrapper and durable evidence API. [VERIFIED: lib/parapet/evidence.ex] | Extract a Phase 6 helper here if `AlertProcessor` needs a reusable transaction boundary instead of open-coding multiple repo calls. [VERIFIED: lib/parapet/evidence.ex] |
| `Parapet.Spine.ActionItem` | in-repo schema. [VERIFIED: lib/parapet/spine/action_item.ex] | Exact follow-up records for one delivery or async object. [VERIFIED: lib/parapet/spine/action_item.ex] | Use only when there is one concrete object needing manual follow-up, mirroring the existing Scoria stale workflow pattern. [VERIFIED: lib/parapet/integrations/scoria.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| `ExUnit` | bundled with Elixir `1.19.5` available locally. [VERIFIED: test/test_helper.exs] [VERIFIED: local command] | Schema, transaction, and derivation tests without a real DB. [VERIFIED: test/parapet/spine/alert_processor_test.exs] [VERIFIED: test/parapet/operator/workbench_contract_test.exs] | Keep using the repo’s DummyRepo pattern for Phase 6 transactional behavior tests. [VERIFIED: test/parapet/spine/alert_processor_test.exs] [VERIFIED: test/parapet/operator/workbench_contract_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Validated `runbook_data` summary plus `triage_snapshot` timeline | Timeline-only classification | Rejected because Phase 6 needs cheap current-state reads for queue/detail pages and the context explicitly locks a hybrid split. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| `embeds_one`-style validated summary over a `:map` column | Continue using a totally free-form summary map | Rejected because the current code has no enforced shape and Phase 6 semantics are already stable enough to validate while keeping storage in the existing map column. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] |
| Narrow `ActionItem` additions (`incident_id`, `kind`) | Separate generic task table or wide task metadata blob | Rejected by locked Phase 6 scope because it would broaden the product into task management. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: lib/parapet/spine/action_item.ex] |
| Refresh or insert incident summaries on firing alerts | Keep current `on_conflict: :nothing` insert-only flow | Rejected because it cannot append summary changes or new `triage_snapshot` rows when an incident’s classification changes over time. [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |

**Installation:**

```bash
mix deps.get
```

No new Hex dependency is required for Phase 6; the repo already includes Ecto and ExUnit and the phase should reuse existing spine/operator modules. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

## File Recommendations

| File | Recommendation | Why |
|------|----------------|-----|
| `lib/parapet/spine/incident.ex` | Add a validated embed or equivalent changeset helper for the Phase 6 current summary shape while keeping storage in `runbook_data`. [VERIFIED: lib/parapet/spine/incident.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] | The schema already stores a `:map`, and Phase 6 explicitly allows the summary contract to harden behind stable operator semantics. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| `lib/parapet/spine/alert_processor.ex` | Replace insert-only firing handling with a transaction that inserts or updates the incident summary, appends `triage_snapshot`, and optionally creates exact `ActionItem`s. [VERIFIED: lib/parapet/spine/alert_processor.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] | This file already owns correlation and is the locked transactional enrichment seam. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| `lib/parapet/spine/timeline_entry.ex` | Add narrow payload validation helpers for Phase 6 typed rows like `triage_snapshot`, `provider_feedback_missing`, `queue_age_bucket_changed`, and `action_item_created`. [VERIFIED: lib/parapet/spine/timeline_entry.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] | The current schema accepts any `type` and any `payload`, which is too loose for deterministic operator chronology. [VERIFIED: lib/parapet/spine/timeline_entry.ex] |
| `lib/parapet/spine/action_item.ex` | Add `belongs_to :incident`, bounded `kind`, and a dedupe-friendly unique constraint strategy. [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] | The current shape cannot attach exact follow-up work to an incident detail page without query-time heuristics. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/spine/action_item.ex] |
| `lib/parapet/operator/workbench_contract.ex` | Replace generic severity/journey derivation with explicit Phase 6 triage fields such as `symptom`, `fault_plane`, `impact`, `top_facts`, `next_safe_action`, `confidence`, and `action_items`. [VERIFIED: lib/parapet/operator/workbench_contract.ex] [VERIFIED: test/parapet/operator/workbench_contract_test.exs] | The current struct does not expose the data the locked triage block needs. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| `lib/parapet/operator.ex` | Fetch timeline entries in chronological order for evidence rendering or expose both `latest_first` and chronological projections, and preload incident-linked action items. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] | The context makes chronology authoritative, while the current query orders entries descending. [VERIFIED: lib/parapet/operator.ex] |
| `test/parapet/spine/alert_processor_test.exs` | Add coverage for insert-vs-update enrichment, triage snapshot append, exact-item dedupe, and no-item cases. [VERIFIED: test/parapet/spine/alert_processor_test.exs] | The current tests stop at incident creation, correlation, and runbook schema attachment. [VERIFIED: test/parapet/spine/alert_processor_test.exs] |
| `test/parapet/operator/workbench_contract_test.exs` | Replace or extend current derivation expectations to assert the compact triage block and chronology semantics. [VERIFIED: test/parapet/operator/workbench_contract_test.exs] | This is the existing contract test seam for deterministic operator projection. [VERIFIED: test/parapet/operator/workbench_contract_test.exs] |
| `test/parapet/evidence/action_item_test.exs` | Add incident-linked dedupe and resolution-by-key tests once `incident_id` and `kind` exist. [VERIFIED: test/parapet/evidence/action_item_test.exs] | Phase 6 requires exact-item follow-up to stay idempotent and narrow. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |

## Architecture Patterns

### System Architecture Diagram

```text
Phase 5 Prometheus alert
  -> Alertmanager webhook payload
  -> Parapet.Spine.AlertProcessor
     -> derive correlation key
     -> parse bounded async/delivery labels + annotations
     -> build current triage summary
     -> decide whether exact ActionItem is warranted
  -> one Ecto transaction
     -> insert or update Incident.runbook_data summary
     -> append TimelineEntry(type: "triage_snapshot")
     -> append typed chronology rows for observed evidence
     -> insert/dedupe ActionItem only for exact work
  -> Parapet.Operator.incident_detail/1
     -> fetch incident
     -> fetch chronological timeline
     -> fetch incident-linked action items
     -> Parapet.Operator.WorkbenchContract.derive/2
  -> generated Operator UI
     -> compact triage block
     -> authoritative chronology
     -> external links to Grafana/provider/runbook
```

The input contract for this flow is Phase 5 alert taxonomy plus bounded Phase 4 telemetry fields, not raw provider payloads. [VERIFIED: docs/telemetry.md] [VERIFIED: docs/slo-reference.md] [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

### Recommended Project Structure

```text
lib/parapet/spine/
├── alert_processor.ex             # transactional incident enrichment
├── incident.ex                    # embeds Phase 6 current summary in runbook_data
├── incident_summary.ex            # optional embedded schema / validator
├── timeline_entry.ex              # typed chronology helpers
└── action_item.ex                 # narrow exact-item follow-up schema

lib/parapet/operator/
└── workbench_contract.ex          # triage block + chronology projection

priv/repo/migrations/
├── *_add_incident_summary_shape.exs
└── *_link_action_items_to_incidents.exs
```

This structure preserves the repo’s existing spine/operator separation and keeps Phase 6 changes local to the durable evidence path. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: lib/parapet/spine/timeline_entry.ex] [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: lib/parapet/operator/workbench_contract.ex]

### Pattern 1: Transactional Hybrid Enrichment

**What:** Build the current summary and the append-only `triage_snapshot` from the same parsed alert facts and persist them in one repo transaction. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

**When to use:** Every async or delivery firing alert that maps to the Phase 4 and 5 fault-plane taxonomy. [VERIFIED: docs/telemetry.md] [VERIFIED: docs/slo-reference.md] [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**Implementation guidance:** Parse labels like `integration`, `fault_plane`, `queue`, `pipeline_stage`, `delay_bucket`, and `failure_class` directly from the alert payload; derive `symptom`, `impact`, `next_safe_action`, and 2-4 bounded evidence facts in code; update or insert the incident; append `triage_snapshot`; and only then broadcast. Reuse the same transaction posture the repo already uses for operator commands and alert auto-resolution. [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

### Pattern 2: Validated Summary Stored in Existing `runbook_data`

**What:** Keep `Incident.runbook_data` as the storage column, but cast a Phase 6 summary embed or equivalent nested changeset into that map so fields like `symptom`, `fault_plane`, `top_facts`, and `confidence` are validated instead of free-form. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]

**When to use:** Any code path that writes or updates the current incident summary, including future Phase 7 runbook/recovery updates. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]

**Implementation guidance:** Treat the existing runbook snapshot keys and the new triage summary as one bounded operator payload rather than as an unstructured blob. If backward compatibility with existing runbook data matters, use a nested key like `"triage"` or `"incident_summary"` under `runbook_data`, but keep the top-of-page Operator semantics stable. [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: test/parapet/spine/alert_processor_test.exs]

### Pattern 3: Exact-Item Follow-Up Only

**What:** Create a durable `ActionItem` only when the incident is about one exact object that a human may need to retry, inspect, or repair. Use `integration`, `external_id`, `incident_id`, and bounded `kind` as the durable routing key. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: lib/parapet/integrations/scoria.ex]

**When to use:** `discarded` work, dead-letter items, orphaned callbacks, exact suppressed delivery records, or similar exact-object failures. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

**Implementation guidance:** Mirror the Scoria stale-workflow posture, but stop short of creating items for every delayed queue symptom. Prefer a unique index plus `on_conflict: :nothing` or an explicit get-or-insert helper so repeated alerts do not spam duplicate items. [VERIFIED: lib/parapet/integrations/scoria.ex] [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

### Pattern 4: Chronology Is a First-Class Projection

**What:** Render the current triage block from the latest summary and render sequence from ordered timeline rows. Do not derive sequence from summary prose or mutable fields. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

**When to use:** Incident detail pages and any future retrospective/reporting view that needs operator-trustworthy ordering. [VERIFIED: docs/operator-ui.md] [VERIFIED: lib/parapet/operator.ex]

**Implementation guidance:** Keep `WorkbenchContract` free to look at the latest snapshot for summary fields, but give `Operator.incident_detail/1` a chronological entry list for rendering. The current descending query is fine for finding the latest record, but it is the wrong default for the authoritative chronology block. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/operator/workbench_contract.ex]

### Anti-Patterns to Avoid

- **UI-only fault inference:** Do not parse `incident.title` or ad hoc annotations in LiveView to guess the likely plane; persist that conclusion as durable evidence first. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: docs/operator-ui.md]
- **Runbook data as a hidden timeline:** Do not keep appending wide evidence blobs into `runbook_data`; the summary is current state only. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]
- **Generic task sprawl:** Do not create `ActionItem`s for “investigate provider” or “check Grafana”; those belong in runbooks or timeline facts. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]
- **Insert-only enrichment:** Do not keep `on_conflict: :nothing` as the only firing-alert path for async/delivery incidents because it prevents classification refresh. [VERIFIED: lib/parapet/spine/alert_processor.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-step durable write path | Ad hoc `Repo.insert` and `Repo.update` calls spread across the processor | One `Ecto.Multi` transaction or a helper in `Parapet.Evidence` | Phase 6 explicitly requires summary and history to remain in lockstep. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: lib/parapet/evidence.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Summary shape validation | Hand-checked maps in controller or UI code | `Ecto.Schema` embed or nested changeset | The repo already uses changesets as the contract layer, and this keeps summary semantics stable. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: lib/parapet/operator/action_payload.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| Incident-linked task tracking | A new generic task subsystem | Narrow `ActionItem` extensions | The existing schema already fits the exact-object follow-up use case and Phase 6 scope forbids generic task management. [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Fault-plane heuristics | String parsing over alert titles in templates | Alert-label parsing in `AlertProcessor` + durable summary fields | Phase 4 and 5 already locked the taxonomy as bounded metadata and alert semantics. [VERIFIED: docs/telemetry.md] [VERIFIED: docs/slo-reference.md] [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md] |

**Key insight:** Phase 6 succeeds by tightening the existing spine seams, not by adding another operational data model. [VERIFIED: .planning/research/ARCHITECTURE.md] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Summary and timeline drift

**What goes wrong:** `runbook_data` says the incident is a webhook delay while the latest timeline facts still point at backlog or provider degradation. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

**Why it happens:** The current firing-alert path inserts incidents and optionally correlates old system events, but it does not have a single transaction for summary refresh plus snapshot append. [VERIFIED: lib/parapet/spine/alert_processor.ex]

**How to avoid:** Parse the alert once, build one summary struct plus one `triage_snapshot` payload, and persist both through the same `Ecto.Multi`. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

**Warning signs:** Repeated firing alerts update operator meaning in Grafana or Alertmanager annotations but incident detail pages never change after creation. [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: docs/operator-ui.md]

### Pitfall 2: Chronology rendered in reverse or with mixed type semantics

**What goes wrong:** Operators see the newest event first, but the interface claims chronology is authoritative, or resolution and status-change events use inconsistent types. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/operator/workbench_contract.ex]

**Why it happens:** `Operator.incident_detail/1` currently fetches entries descending, while `WorkbenchContract` looks for `"incident_resolved"` even though operator commands currently write `"status_change"` for resolution. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/operator/workbench_contract.ex]

**How to avoid:** Standardize the typed chronology vocabulary in Phase 6 and either query chronological rows directly for rendering or derive a second chronological projection from the fetched entries. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

**Warning signs:** Tests need exceptions for one event type or the UI starts special-casing timeline rows by source rather than by explicit type. [VERIFIED: test/parapet/operator/workbench_contract_test.exs] [VERIFIED: lib/parapet/operator.ex]

### Pitfall 3: `ActionItem` explosion from systemic symptoms

**What goes wrong:** A queue freshness burn or callback delay alert generates one `ActionItem` per alert evaluation or per retried object, turning the follow-up queue into noise. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

**Why it happens:** The current `create_action_item/1` path is a plain insert with no built-in dedupe and no incident linkage. [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: lib/parapet/spine/action_item.ex]

**How to avoid:** Gate item creation behind an exact-object predicate, add a unique key for the narrow object identity, and keep broad guidance in `triage_snapshot` and runbook links. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: lib/parapet/integrations/scoria.ex]

**Warning signs:** Incident detail pages show many near-identical follow-up items with no distinct `external_id` or operator action path. [VERIFIED: lib/parapet/spine/action_item.ex]

### Pitfall 4: Free-form operator prose that breaks the bounded taxonomy

**What goes wrong:** Titles or summaries collapse “provider accepted” and “delivered,” or call a callback delay “backlog,” which destroys the point of Phase 5’s semantics. [VERIFIED: docs/telemetry.md] [VERIFIED: docs/slo-reference.md] [VERIFIED: .planning/v0.7-phases/5/5-CONTEXT.md]

**Why it happens:** Human-friendly wording is generated without a stable field model, so operators or templates fall back to prose shortcuts. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

**How to avoid:** Treat `symptom`, `fault_plane`, `impact`, and 2-4 `top_facts` as the operator contract and keep titles symptom-first rather than conclusion-first. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

**Warning signs:** The same alert class receives different incident titles depending on which annotation was present or which developer touched the template. [VERIFIED: lib/parapet/spine/alert_processor.ex]

## Code Examples

Verified patterns adapted to this phase:

### Validated incident summary over the existing map field

```elixir
# Source: lib/parapet/spine/incident.ex + https://hexdocs.pm/ecto/Ecto.Schema.html
defmodule Parapet.Spine.Incident do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parapet_incidents" do
    embeds_one :incident_summary, IncidentSummary, source: :runbook_data, on_replace: :update do
      field :integration, :string
      field :symptom, :string
      field :fault_plane, Ecto.Enum, values: [:provider, :webhook, :suppression, :worker, :backlog]
      field :impact, :string
      field :queue, :string
      field :pipeline_stage, :string
      field :delay_bucket, :string
      field :failure_class, :string
      field :next_safe_action, :string
      field :confidence, Ecto.Enum, values: [:high, :medium, :low]
      field :top_facts, {:array, :map}, default: []
    end
  end
end
```

This keeps the existing storage column while validating the Phase 6 operator contract. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html]

### One transaction for summary refresh, snapshot append, and exact-item follow-up

```elixir
# Source: lib/parapet/evidence.ex + lib/parapet/spine/alert_processor.ex + https://hexdocs.pm/ecto/Ecto.Multi.html
multi =
  Ecto.Multi.new()
  |> Ecto.Multi.insert_or_update(:incident, incident_changeset)
  |> Ecto.Multi.insert(:triage_snapshot, fn %{incident: incident} ->
    Parapet.Spine.TimelineEntry.changeset(%Parapet.Spine.TimelineEntry{}, %{
      incident_id: incident.id,
      type: "triage_snapshot",
      payload: snapshot_payload
    })
  end)
  |> maybe_insert_action_item(action_item_attrs)
  |> Ecto.Multi.run(:broadcast, fn _repo, %{incident: incident} ->
    Parapet.Notifier.broadcast(incident)
    {:ok, incident}
  end)

Evidence.repo().transaction(multi)
```

This is the correct Phase 6 shape because chronology and current state must remain synchronized. [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Generic incident creation with optional runbook snapshot only | Fault-domain summary plus ordered `triage_snapshot` evidence | Phase 6 target after Phase 5 alerts exist. [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: .planning/ROADMAP.md] | Operators see the failing plane before reading logs. [VERIFIED: .planning/ROADMAP.md] |
| Free-form `runbook_data` blob | Validated summary contract stored in the same map column | Recommended for Phase 6. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] | Stable queue/detail semantics without a new table. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Global action-item queue keyed only by `integration` and `external_id` | Incident-linked exact follow-up keyed by incident plus bounded kind | Recommended for Phase 6. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] | Incident detail pages can show one concrete object that needs human action without generic task sprawl. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Generic workbench derivations (`severity`, `affected_journey`) | Explicit async/delivery triage block (`symptom`, `fault_plane`, `why`, `next_safe_action`) | Recommended for Phase 6. [VERIFIED: lib/parapet/operator/workbench_contract.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] | The operator surface matches the milestone’s “what plane is failing?” goal. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**

- Insert-only firing-alert processing for async and delivery incidents is outdated for Phase 6 because it cannot express classification change over time. [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]
- Treating `ActionItem` as an unscoped queue item with no incident linkage is insufficient for Phase 6 detail rendering. [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

## Assumptions Log

All major claims in this research were verified against the repo’s current planning and code context or official Ecto documentation. No user confirmation is required before planning. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: lib/parapet/operator/workbench_contract.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | schema, transaction, and test execution | ✓ | `1.19.5` [VERIFIED: local command] | — |
| Mix | `mix test` and migration/test workflow | ✓ | `1.19.5` [VERIFIED: local command] | — |

No extra service dependency was identified for the planning scope of Phase 6 because the phase is code-and-schema work on the existing spine/operator path. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: test/test_helper.exs] [VERIFIED: local command] |
| Config file | none detected beyond `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/parapet/spine/alert_processor_test.exs test/parapet/operator/workbench_contract_test.exs test/parapet/evidence/action_item_test.exs -x` [VERIFIED: test/parapet/spine/alert_processor_test.exs] [VERIFIED: test/parapet/operator/workbench_contract_test.exs] [VERIFIED: test/parapet/evidence/action_item_test.exs] |
| Full suite command | `mix test` [VERIFIED: test/ directory] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TRIAGE-02 | Firing alerts create or refresh a bounded summary that distinguishes provider, webhook, suppression, worker, and backlog planes. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/parapet/spine/alert_processor_test.exs -x` | ✅ |
| TRIAGE-03 | Operator detail derives the structured triage block and preserves ordered chronology. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/parapet/operator/workbench_contract_test.exs -x` | ✅ |
| RNBK-03 | Exact-object follow-up items are created only when warranted and are dedupable/resolvable by key. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/parapet/evidence/action_item_test.exs -x` | ✅ |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/spine/alert_processor_test.exs test/parapet/operator/workbench_contract_test.exs test/parapet/evidence/action_item_test.exs -x` [VERIFIED: test/parapet/spine/alert_processor_test.exs] [VERIFIED: test/parapet/operator/workbench_contract_test.exs] [VERIFIED: test/parapet/evidence/action_item_test.exs]
- **Per wave merge:** `mix test` [VERIFIED: test/ directory]
- **Phase gate:** Full suite green before verification. [VERIFIED: .planning/config.json]

### Wave 0 Gaps

- [ ] `test/parapet/spine/incident_test.exs` — add summary embed or nested changeset validation coverage once the Phase 6 shape exists. [VERIFIED: test/parapet/spine/incident_test.exs] [VERIFIED: lib/parapet/spine/incident.ex]
- [ ] `test/parapet/spine/alert_processor_test.exs` — add cases for summary refresh on repeated firing alerts, `triage_snapshot` append, and exact-item creation/deduping. [VERIFIED: test/parapet/spine/alert_processor_test.exs]
- [ ] `test/parapet/operator/workbench_contract_test.exs` — add expectations for `symptom`, `fault_plane`, `top_facts`, `next_safe_action`, and chronological evidence projection. [VERIFIED: test/parapet/operator/workbench_contract_test.exs]
- [ ] `test/parapet/evidence/action_item_test.exs` — add incident-linked dedupe and resolve-by-key coverage after `incident_id`/`kind` land. [VERIFIED: test/parapet/evidence/action_item_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Host application auth continues to own Operator UI access; Phase 6 should not introduce new auth paths. [VERIFIED: docs/operator-ui.md] |
| V3 Session Management | no | Session handling remains in the host app’s LiveView/router scope. [VERIFIED: docs/operator-ui.md] |
| V4 Access Control | yes | Continue routing all mutating operator work through `ActionPayload` validation and `Evidence.run_operator_command/1` audit seams. [VERIFIED: lib/parapet/operator/action_payload.ex] [VERIFIED: lib/parapet/evidence.ex] |
| V5 Input Validation | yes | Validate summary payloads, timeline payloads, and action-item keys through changesets instead of trusting alert maps. [VERIFIED: lib/parapet/spine/incident.ex] [VERIFIED: lib/parapet/spine/timeline_entry.ex] [VERIFIED: lib/parapet/spine/action_item.ex] [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html] |
| V6 Cryptography | no | Phase 6 does not add cryptographic primitives or secret handling beyond existing operator audit context. [VERIFIED: lib/parapet/operator/action_payload.ex] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Alert label tampering writes misleading plane classification | Tampering | Only consume bounded label keys already locked by Phase 4/5 and validate the incident summary shape before writing. [VERIFIED: docs/telemetry.md] [VERIFIED: docs/slo-reference.md] [VERIFIED: lib/parapet/spine/incident.ex] |
| High-cardinality identifiers leak into durable summaries or timeline facts | Information Disclosure | Keep exact ids in `refs` or `ActionItem.external_id`, not in label-safe summary fields. [VERIFIED: docs/telemetry.md] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| Duplicate exact follow-up items flood operators | Denial of Service | Add incident-linked uniqueness and create items only from exact-object predicates. [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |
| UI performs hidden inference that cannot be audited | Repudiation | Derive triage from durable `runbook_data` and `TimelineEntry`, not template heuristics. [VERIFIED: docs/operator-ui.md] [VERIFIED: lib/parapet/operator/workbench_contract.ex] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/v0.7-phases/6/6-CONTEXT.md` - locked decisions, scope boundary, operator semantics, and exact-item policy. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]
- `.planning/ROADMAP.md` - Phase 6 goal and success criteria. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - `TRIAGE-02`, `TRIAGE-03`, and `RNBK-03` requirement text. [VERIFIED: .planning/REQUIREMENTS.md]
- `docs/telemetry.md` - bounded async/delivery taxonomy that Phase 6 must preserve. [VERIFIED: docs/telemetry.md]
- `docs/operator-ui.md` - evidence-first and external-link operator doctrine. [VERIFIED: docs/operator-ui.md]
- `docs/slo-reference.md` - Phase 5 alert/slice semantics that become Phase 6 input. [VERIFIED: docs/slo-reference.md]
- `lib/parapet/spine/alert_processor.ex` - existing ingestion seam and current insert-only limitation. [VERIFIED: lib/parapet/spine/alert_processor.ex]
- `lib/parapet/spine/incident.ex` - current summary storage field. [VERIFIED: lib/parapet/spine/incident.ex]
- `lib/parapet/spine/timeline_entry.ex` - current chronology schema. [VERIFIED: lib/parapet/spine/timeline_entry.ex]
- `lib/parapet/spine/action_item.ex` - current exact follow-up schema. [VERIFIED: lib/parapet/spine/action_item.ex]
- `lib/parapet/operator.ex` - incident detail query ordering and operator command path. [VERIFIED: lib/parapet/operator.ex]
- `lib/parapet/operator/workbench_contract.ex` - current deterministic derivation contract. [VERIFIED: lib/parapet/operator/workbench_contract.ex]
- `lib/parapet/integrations/scoria.ex` - existing exact-item creation pattern. [VERIFIED: lib/parapet/integrations/scoria.ex]
- `lib/parapet/evidence.ex` - transactional and durable evidence patterns. [VERIFIED: lib/parapet/evidence.ex]
- `test/parapet/spine/alert_processor_test.exs` - existing test seam for alert ingestion. [VERIFIED: test/parapet/spine/alert_processor_test.exs]
- `test/parapet/operator/workbench_contract_test.exs` - existing test seam for deterministic derivation. [VERIFIED: test/parapet/operator/workbench_contract_test.exs]
- `test/parapet/evidence/action_item_test.exs` - existing test seam for durable exact-item behavior. [VERIFIED: test/parapet/evidence/action_item_test.exs]

### Secondary (MEDIUM confidence)

- Ecto.Schema docs - embedded schemas and `embeds_one` over a map-backed field. [CITED: https://hexdocs.pm/ecto/Ecto.Schema.html]
- Ecto.Changeset docs - validated casting for external maps and nested data. [CITED: https://hexdocs.pm/ecto/Ecto.Changeset.html]
- Ecto.Multi docs - atomic multi-step persistence and dependent operations. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 6 reuses existing repo modules plus current Ecto primitives already present in the lockfile. [VERIFIED: mix.lock] [VERIFIED: lib/parapet/evidence.ex]
- Architecture: HIGH - The phase context is unusually explicit about ownership, chronology, and exact-item boundaries. [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md]
- Pitfalls: HIGH - The current code reveals concrete mismatches the phase must resolve, especially insert-only enrichment, reverse chronology defaults, and thin `ActionItem` linkage. [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/spine/action_item.ex]

**Research date:** 2026-05-17
**Valid until:** 2026-06-16

## RESEARCH COMPLETE
