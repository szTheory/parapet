---
phase: 55-demo-app-upgrade-docs
plan: "02"
subsystem: docs
tags: [hexdocs, schema-prefix, upgrade-guide, migration, elixir, ecto]

requires:
  - phase: 54-upgrade-path-doctor
    provides: "Locked Track A/B mechanics (D-04/D-17/D-18), doctor schema check, verbatim copy strings"
  - phase: 55-demo-app-upgrade-docs-plan-01
    provides: "Sentinel migration and SAFE-03 smoke assertions; mix.exs and ci.yml already clean"

provides:
  - "docs/upgrade-1.x.md — single-source upgrade guide with D-07 section order and verbatim Phase-54 copy"
  - "mix.exs registered upgrade-1.x.md in both extras: and groups_for_extras Guides:"
  - "docs/migration-v1.md — new Step 3 (schema location), Steps 3-6 renumbered to Steps 4-7"
  - "docs/deployment.md — net-new schema subsection under Step 4"
  - "README.md — one-line Installation schema note routing to migration-v1.md Step 3"

affects: [56-contract-release-hardening, verify-work, hexdocs-publish]

tech-stack:
  added: []
  patterns:
    - "Single-source doc pattern: upgrade-1.x.md is the sole mechanics home; all secondary surfaces route only"
    - "HexDocs double-registration: extras: AND groups_for_extras both required for cross-link integrity under --warnings-as-errors"

key-files:
  created:
    - "docs/upgrade-1.x.md"
  modified:
    - "mix.exs"
    - "docs/migration-v1.md"
    - "docs/deployment.md"
    - "README.md"

key-decisions:
  - "Single-source rule (D-05): upgrade-1.x.md is the only place Track A/B mechanics live; all other surfaces route to it and never restate"
  - "Both mix.exs extras: AND groups_for_extras Guides: updated in one task to avoid broken cross-links under mix docs --warnings-as-errors (Landmine 3)"
  - "migration-v1.md Step 3 inserted as a top-level step (not a checklist bullet) so do-nothing upgrader sees it before hitting the error (D-09)"
  - "Verbatim copy from 54-CONTEXT D-04/D-17/D-18 so doc, doctor output, and generated migration tell one identical story (D-06)"
  - "Pre-existing mix docs --warnings-as-errors warnings (docs/demo-app.md missing from extras, __prefix__/0 hidden function reference) are out of scope — no new warnings introduced by Plan 02"

patterns-established:
  - "Route-not-restate: secondary doc surfaces reassure + route to single-source guide without duplicating mechanics"
  - "Per-block recompile: every config block in upgrade-1.x.md immediately followed by mix deps.compile parapet --force"

requirements-completed: [DOC-01, DOC-02]

coverage:
  - id: D1
    description: "docs/upgrade-1.x.md exists with D-07 section order: TL;DR -> action-required -> Track A -> Track B -> GRANTs -> recompile-order -> rollback incl. half-migrated -> FAQ"
    requirement: DOC-01
    verification:
      - kind: manual_procedural
        ref: "test -f docs/upgrade-1.x.md — confirmed present"
        status: pass
    human_judgment: true
    rationale: "Doc-content quality (verbatim copy accuracy, reassure->instruct tone, FAQ completeness) requires human review; automation only confirms file existence and cross-link integrity"
  - id: D2
    description: "Every config block in upgrade-1.x.md is immediately followed by mix deps.compile parapet --force"
    requirement: DOC-01
    verification: []
    human_judgment: true
    rationale: "Requires reading each config block in sequence to verify the recompile line follows — cannot be expressed as a grep without false positives"
  - id: D3
    description: "upgrade-1.x.md registered in BOTH mix.exs extras: and groups_for_extras Guides: (DOC-01 D-08)"
    requirement: DOC-01
    verification:
      - kind: other
        ref: "grep -c 'upgrade-1.x.md' mix.exs → 2"
        status: pass
    human_judgment: false
  - id: D4
    description: "migration-v1.md has new Step 3 (Choose your schema location) and old Steps 3-6 renumbered to Steps 4-7; mix parapet.doctor --ci in Step 7 unchanged"
    requirement: DOC-02
    verification:
      - kind: manual_procedural
        ref: "grep -n '^## Step' docs/migration-v1.md → 7 steps, Step 3 = schema location, Step 7 = safe-upgrade checklist"
        status: pass
    human_judgment: false
  - id: D5
    description: "deployment.md has net-new schema subsection under Step 4 routing to upgrade-1.x.md with no Track A/B mechanics restated"
    requirement: DOC-02
    verification:
      - kind: manual_procedural
        ref: "grep -q 'upgrade-1.x.md' docs/deployment.md — confirmed present"
        status: pass
    human_judgment: true
    rationale: "Single-source compliance (no mechanics restated) requires human review of the subsection prose"
  - id: D6
    description: "README Installation section carries a one-line schema note routing to migration-v1.md Step 3"
    requirement: DOC-02
    verification:
      - kind: manual_procedural
        ref: "grep -q 'migration-v1.md' README.md — confirmed present"
        status: pass
    human_judgment: true
    rationale: "Reassure-then-route tone and correct placement after mix parapet.install block require human review"
  - id: D7
    description: "mix docs --warnings-as-errors produces no new warnings from Plan 02 changes (all cross-links from new file resolve)"
    requirement: DOC-02
    verification:
      - kind: other
        ref: "mix docs --warnings-as-errors 2>&1 | grep -v 'demo-app|__prefix__' | grep 'warning:' → empty (no new warnings)"
        status: pass
    human_judgment: false

duration: 6min
completed: "2026-07-01"
status: complete
---

# Phase 55 Plan 02: Demo App & Upgrade Docs Summary

**Single-source Track A/B schema upgrade guide (`docs/upgrade-1.x.md`) with HexDocs registration and three routing pointers closing the audited #1 adopter documentation gap**

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-01T20:26:53Z
- **Completed:** 2026-07-01T20:32:41Z
- **Tasks:** 3 of 3
- **Files modified:** 5 (1 created, 4 extended)

## Accomplishments

- Created `docs/upgrade-1.x.md` as the sole home for Track A/B mechanics (DOC-01): TL;DR reassurance, honest "action required" caveat (D-18 verbatim), Track A config + force-recompile, Track B migration description, least-privilege GRANTs, recompile-order, rollback incl. half-migrated recovery, FAQ
- Registered `docs/upgrade-1.x.md` in BOTH `mix.exs` `extras:` and `groups_for_extras` `Guides:` (Landmine 3 / D-08) so HexDocs publishes it and cross-links from secondary surfaces resolve under `mix docs --warnings-as-errors`
- Inserted new `docs/migration-v1.md` Step 3 "Choose your schema location (v1.7+)" as a top-level step (not a buried checklist bullet) with a Track A one-liner and route to `upgrade-1.x.md` for Track B; renumbered old Steps 3-6 to Steps 4-7 (D-09)
- Added `docs/deployment.md` schema subsection under Step 4 routing to `upgrade-1.x.md` with no mechanics restated (D-10)
- Added one-line schema note to `README.md` Installation section routing to `migration-v1.md` Step 3 (D-11)

## Task Commits

1. **Task 1: Create docs/upgrade-1.x.md and register it in mix.exs (both lists)** - `3f6a1bc` (feat)
2. **Task 2: Insert migration-v1.md Step 3 and renumber Steps 3-6 -> 4-7** - `634da80` (docs)
3. **Task 3: Add deployment.md schema subsection and README Installation note** - `066d484` (docs)

## Files Created/Modified

- `docs/upgrade-1.x.md` (NEW) — Single-source Track A/B upgrade guide with D-07 section order; verbatim copy from 54-CONTEXT D-04/D-17/D-18
- `mix.exs` (EXTENDED) — `docs/upgrade-1.x.md` added to `extras:` and `groups_for_extras` `Guides:` (2 lines)
- `docs/migration-v1.md` (EXTENDED) — New Step 3 inserted; old Steps 3-6 renumbered to Steps 4-7
- `docs/deployment.md` (EXTENDED) — Net-new "Schema location" subsection under Step 4
- `README.md` (EXTENDED) — One-line schema note in Installation section after `mix parapet.install` block

## Decisions Made

- Used D-07 section order exactly (TL;DR -> action-required -> Track A -> Track B -> GRANTs -> recompile-order -> rollback -> FAQ) per must_haves truths
- Copied Track A/B content verbatim from 54-CONTEXT D-04/D-17/D-18 / 55-RESEARCH "Verbatim Phase-54 Copy" section to satisfy D-06 single-story requirement
- Placed contributor stale-DB note (`mix demo.reset`) in the FAQ section only — not in the main flow (Landmine 7)
- migration-v1.md Step 3 includes the command name `mix parapet.gen.schema.move` in the Track B routing sentence — this is a name mention to route the reader, not a restatement of mechanics (matches RESEARCH sketch lines 865-873)

## Deviations from Plan

### Pre-existing `mix docs --warnings-as-errors` failures (out of scope, not introduced by Plan 02)

`mix docs --warnings-as-errors` exits with code 1 locally due to TWO pre-existing warnings that were present before any Plan 02 changes:

1. `docs/demo-app.md` referenced in `README.md`, `docs/operator-ui.md`, `docs/getting-started.md` — file exists on disk but is NOT in `mix.exs` `extras:` so HexDocs cannot resolve the relative links
2. `Parapet.Spine.Schema.__prefix__/0` — referenced in `lib/parapet/evidence.ex:32` doc string, but the function is `@doc false` (hidden)

**Verification that Plan 02 introduced zero new warnings:** `mix docs --warnings-as-errors 2>&1 | grep -v 'demo-app|__prefix__' | grep 'warning:'` returns empty. All `upgrade-1.x.md` cross-links from `migration-v1.md`, `deployment.md`, and `README.md` resolve correctly.

**Action:** Logged to `deferred-items.md`. The `demo-app.md` warning can be resolved by adding `docs/demo-app.md` to `mix.exs` `extras:` in a future plan. The `__prefix__/0` warning requires un-hiding the function or removing the doc string reference.

None of the above deviations are introduced by Plan 02.

---

**Total deviations:** 0 plan deviations (1 pre-existing environment issue noted and deferred)
**Impact on plan:** All acceptance criteria met. No plan scope changes.

## Issues Encountered

- Local `MIX_ENV` had stale compile-time `:schema_prefix` set to `nil` (from CI test matrix run), causing `Application.validate_compile_env` error when first running `mix docs`. Resolved by running `MIX_ENV=dev mix compile --force` to recompile under the standard dev default.

## Known Stubs

None — all routes in secondary surfaces point to the existing `docs/upgrade-1.x.md` which was created in this plan.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced. The `docs/upgrade-1.x.md` GRANT examples use least-privilege patterns (GRANT USAGE/CREATE on schema only) as specified by T-55-03 mitigation.

## User Setup Required

None — documentation change only, no external service configuration required.

## Next Phase Readiness

- DOC-01 and DOC-02 satisfied: adopters have a copy-paste upgrade story; the three secondary surfaces route without drift
- Phase 56 (Contract & Release Hardening — SAFE-01, SAFE-02, SAFE-04) can proceed
- Pre-existing `mix docs --warnings-as-errors` warnings (`demo-app.md`, `__prefix__/0`) should be resolved before Phase 56 ships to HexDocs; log as a Phase 56 blocker or pre-work item

---
*Phase: 55-demo-app-upgrade-docs*
*Completed: 2026-07-01*
