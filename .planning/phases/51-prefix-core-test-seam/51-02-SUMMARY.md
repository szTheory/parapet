---
phase: 51-prefix-core-test-seam
plan: 02
subsystem: database
tags: [ecto, schema-prefix, postgres, compile-time, spine-schemas]

requires:
  - "51-01 (Parapet.Spine.Schema macro, config/config.exs seam, schema_test.exs RED scaffold)"

provides:
  - "All six spine schemas use use Parapet.Spine.Schema (PREFIX-01 deduplication)"
  - "__schema__(:prefix) == \"parapet\" for Incident, ActionItem, SystemEvent, ToolAudit, TimelineEntry, ActionClaim (PREFIX-02)"
  - "Compiled-prefix-across-six test block is fully GREEN (16/16 schema_test.exs tests pass)"

affects:
  - "52-propagation-proof-guards-ci-dual-prefix-matrix"
  - "53-generators-library-migrations"
  - "54-upgrade-path-doctor"

tech-stack:
  added: []
  patterns:
    - "Pure subtraction: replace use Ecto.Schema + 3 boilerplate lines with use Parapet.Spine.Schema; macro re-injects all four plus @schema_prefix"
    - "Surgical line deletion preserving interleaved module attributes (@triage_fields, @triage_snapshot_fields, @kinds, @statuses, alias)"

key-files:
  created: []
  modified:
    - lib/parapet/spine/incident.ex
    - lib/parapet/spine/action_item.ex
    - lib/parapet/spine/action_claim.ex
    - lib/parapet/spine/system_event.ex
    - lib/parapet/spine/tool_audit.ex
    - lib/parapet/spine/timeline_entry.ex

key-decisions:
  - "Macro injection order: use Parapet.Spine.Schema expands to use Ecto.Schema + import Ecto.Changeset + @primary_key + @foreign_key_type + @schema_prefix — so all five directives come from the macro; none must remain in the callee"
  - "lib/parapet/operator/action_payload.ex intentionally left on bare use Ecto.Schema (D-03: macro scoped to lib/parapet/spine/ only)"

requirements-completed: [PREFIX-01, PREFIX-02]

coverage:
  - id: T1
    description: "Incident, ActionItem, ActionClaim switched to use Parapet.Spine.Schema; boilerplate deduped; interleaved attrs preserved"
    requirement: "PREFIX-01"
    verification:
      - kind: unit
        ref: "test/parapet/spine/incident_test.exs (12 tests, 0 failures)"
        status: pass
      - kind: compile
        ref: "mix compile --warnings-as-errors — 0 warnings after 3-file switch"
        status: pass
    human_judgment: false
  - id: T2
    description: "SystemEvent, ToolAudit, TimelineEntry switched to use Parapet.Spine.Schema; interleaved attrs preserved"
    requirement: "PREFIX-01"
    verification:
      - kind: unit
        ref: "test/parapet/spine/timeline_entry_test.exs + tool_audit_test.exs (6 tests, 0 failures)"
        status: pass
      - kind: compile
        ref: "mix compile --warnings-as-errors — 0 warnings after second 3-file switch"
        status: pass
    human_judgment: false
  - id: T3
    description: "compiled-prefix-across-six block GREEN: all 6 modules return __schema__(:prefix) == \"parapet\""
    requirement: "PREFIX-02"
    verification:
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs (16 tests, 0 failures — all three describe blocks GREEN)"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-06-30
status: complete
---

# Phase 51 Plan 02: Prefix Core & Test Seam — Spine Schema Propagation Summary

**Pure subtraction across all six `lib/parapet/spine/` schemas: swap `use Ecto.Schema` for `use Parapet.Spine.Schema`, delete three duplicated boilerplate lines per file; the Plan 01 macro re-injects them plus `@schema_prefix "parapet"`.**

## Performance

- **Duration:** 4 min
- **Completed:** 2026-06-30
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Switched `lib/parapet/spine/incident.ex`, `action_item.ex`, `action_claim.ex` from `use Ecto.Schema` to `use Parapet.Spine.Schema`; surgically deleted `import Ecto.Changeset`, `@primary_key {:id, :binary_id, autogenerate: true}`, `@foreign_key_type :binary_id` from each; preserved all interleaved attributes (`@triage_fields`, `@kinds`, `@statuses`, `alias`)
- Switched `lib/parapet/spine/system_event.ex`, `tool_audit.ex`, `timeline_entry.ex` identically; preserved `@triage_snapshot_fields` and `alias` in each
- `mix test test/parapet/spine/schema_test.exs` → 16/16 GREEN including the six `compiled-prefix-across-six` assertions that were intentionally RED in Plan 01
- `lib/parapet/operator/action_payload.ex` left untouched (D-03 confirmed — still uses bare `use Ecto.Schema`)
- `mix compile --warnings-as-errors` clean after both batches

## Task Commits

1. **Task 1: Switch Incident, ActionItem, ActionClaim** - `d2b797f` (feat)
2. **Task 2: Switch SystemEvent, ToolAudit, TimelineEntry** - `256a06e` (feat)
3. **Task 3: GREEN compiled-prefix-across-six** — verification only; no code change; 16/16 schema_test.exs tests GREEN

## Files Modified

- `lib/parapet/spine/incident.ex` — `use Parapet.Spine.Schema`; deleted `import Ecto.Changeset`, `@primary_key`, `@foreign_key_type`; `@triage_fields` preserved
- `lib/parapet/spine/action_item.ex` — same swap; `alias` + `@kinds` preserved
- `lib/parapet/spine/action_claim.ex` — same swap; `alias` + `@statuses` preserved
- `lib/parapet/spine/system_event.ex` — same swap; no interleaved attributes
- `lib/parapet/spine/tool_audit.ex` — same swap; `alias` preserved
- `lib/parapet/spine/timeline_entry.ex` — same swap; `alias` + `@triage_snapshot_fields` preserved

## Decisions Made

- The macro injection order in `Parapet.Spine.Schema.__using__/1` is: `use Ecto.Schema`, then `import Ecto.Changeset`, then `@primary_key`, then `@foreign_key_type`, then `@schema_prefix` — so all five must be absent from the callee modules. No partial keep.
- `lib/parapet/operator/action_payload.ex` is intentionally excluded per D-03 (macro scoped to `lib/parapet/spine/` only).

## Deviations from Plan

None — plan executed exactly as written. The pure-subtraction pattern was straightforward; no interleaved attribute was disrupted; no edge case triggered.

## Threat Coverage

- **T-51-04 (Tampering — accidental interleaved attr deletion):** Mitigated. All `@triage_fields`, `@triage_snapshot_fields`, `@kinds`, `@statuses`, and `alias` statements verified intact after each batch; per-schema tests pass.
- **T-51-05 (DoS — missed swap leaving one schema unprefixed):** Mitigated. The compiled-prefix-across-six test asserts `"parapet"` for all six explicitly; all six passed (0 missed swaps).

## Known Stubs

None — this plan produces no UI-rendered output and no data stubs.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. This plan only re-routes the compile-time `@schema_prefix` attribute through the shared macro.

## Next Phase Readiness

- Phase 52 (Propagation Proof, Guards & CI Dual-Prefix Matrix) can proceed: all six schemas are prefixed by default, `__schema__(:prefix) == "parapet"` is verified for each, and the test seam is fully GREEN
- The dual-prefix CI matrix in Phase 52 will now produce a meaningful distinction (prefixed vs. unprefixed) across both Ecto schema and migration paths

## Self-Check: PASSED

- `lib/parapet/spine/incident.ex` uses `use Parapet.Spine.Schema`, no bare `use Ecto.Schema`: VERIFIED
- `lib/parapet/spine/action_item.ex` uses `use Parapet.Spine.Schema`, no bare `use Ecto.Schema`: VERIFIED
- `lib/parapet/spine/action_claim.ex` uses `use Parapet.Spine.Schema`, no bare `use Ecto.Schema`: VERIFIED
- `lib/parapet/spine/system_event.ex` uses `use Parapet.Spine.Schema`, no bare `use Ecto.Schema`: VERIFIED
- `lib/parapet/spine/tool_audit.ex` uses `use Parapet.Spine.Schema`, no bare `use Ecto.Schema`: VERIFIED
- `lib/parapet/spine/timeline_entry.ex` uses `use Parapet.Spine.Schema`, no bare `use Ecto.Schema`: VERIFIED
- `lib/parapet/operator/action_payload.ex` still uses `use Ecto.Schema` (D-03): VERIFIED
- Commit `d2b797f` (Task 1): FOUND
- Commit `256a06e` (Task 2): FOUND
- `mix test test/parapet/spine/schema_test.exs`: 16 tests, 0 failures — VERIFIED GREEN

---
*Phase: 51-prefix-core-test-seam*
*Completed: 2026-06-30*
