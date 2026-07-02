---
phase: 56-contract-release-hardening
plan: "03"
subsystem: documentation
tags: [changelog, release-please, schema-prefix, upgrade-path, conventional-commits]

requires:
  - phase: 55-demo-app-upgrade-docs
    provides: "docs/upgrade-1.x.md single-source Track A/B guide; D-07 locked 'action required' framing"
  - phase: 56-contract-release-hardening
    provides: "56-CONTEXT.md D-01/D-02 two-part banner decision; D-03 single-story consistency; D-04 feat/schema scope"

provides:
  - "CHANGELOG.md feat(schema) two-part entry: headline reassurance (data never moves automatically) + existing-adopter action-required line (config :parapet, schema_prefix: nil)"
  - "Structural guarantee that release-please inherits both banner parts in the generated GitHub release note"

affects: [release-please, v1.7-release-note, SAFE-04]

tech-stack:
  added: []
  patterns:
    - "Two-part CHANGELOG banner: universal reassurance first, then distinct existing-adopter action-required line — honest for all adopter classes while satisfying SAFE-04 spirit (additive/semver-minor)"

key-files:
  created: []
  modified:
    - "CHANGELOG.md — new ### Features block under ## Unreleased with feat(schema) two-part entry"

key-decisions:
  - "D-02 two-part banner: headline reassurance ('no data migrated automatically') + distinct action-required line for existing adopters (schema_prefix: nil + recompile + link to docs/upgrade-1.x.md)"
  - "D-03 single-story: CHANGELOG links to docs/upgrade-1.x.md, never restates Track A/B mechanics — single source of truth preserved"
  - "Task 2 is a static structural verification (both parts adjacent in same feat/schema bullet); live release-note rendering is enforced by the existing release-please CI workflow (D-10 — no new job added)"

patterns-established:
  - "CHANGELOG feat entry: place ### Features before ### Changed (Keep-a-Changelog ordering); use continuation-line body for multi-part bullets so release-please lifts both parts together"

requirements-completed: [SAFE-04]

coverage:
  - id: D1
    description: "CHANGELOG.md has a feat(schema) two-part entry under ## Unreleased / ### Features: headline reassurance that data never moves automatically + distinct existing-adopter action-required line with schema_prefix: nil + link to docs/upgrade-1.x.md"
    requirement: SAFE-04
    verification:
      - kind: other
        ref: "grep -q 'feat' CHANGELOG.md && grep -q 'schema_prefix: nil' CHANGELOG.md && grep -q 'docs/upgrade-1.x.md' CHANGELOG.md && ! grep -q 'No action required for existing installs' CHANGELOG.md && echo OK"
        status: pass
      - kind: other
        ref: "awk '/^### Features/{f=1} f&&/schema_prefix: nil/{a=1} f&&/never move|not migrated|migrated automatically|does not move/{r=1} END{exit (a&&r)?0:1}' CHANGELOG.md && echo BOTH_PARTS_PRESENT"
        status: pass
    human_judgment: false
  - id: D2
    description: "Both banner parts (reassurance + action-required) are structurally adjacent within the same ### Features feat/schema bullet body so release-please renders them together in the GitHub release note"
    requirement: SAFE-04
    verification:
      - kind: other
        ref: "awk '/^### Features/{f=1} f&&/schema_prefix: nil/{a=1} f&&/never move/{r=1} END{exit (a&&r)?0:1}' CHANGELOG.md && echo BOTH_PARTS_PRESENT"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-02
status: complete
---

# Phase 56 Plan 03: Contract Release Hardening (SAFE-04) Summary

**Honest two-part feat(schema) CHANGELOG entry: universal reassurance that data never moves automatically, plus a distinct existing-adopter action-required line pointing to `config :parapet, schema_prefix: nil` and `docs/upgrade-1.x.md`**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-02T18:23:00Z
- **Completed:** 2026-07-02T18:28:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `### Features` block before `### Changed` in `## Unreleased` (Keep-a-Changelog ordering) with a `* **schema:**` two-part bullet
- Part 1 (everyone): "No data is migrated automatically — your evidence tables never move unless you choose" — true for new installs AND existing adopters, satisfying SAFE-04 spirit (additive, semver-minor, reassuring)
- Part 2 (existing adopters): explicit action-required sentence with `config :parapet, schema_prefix: nil` + link to `docs/upgrade-1.x.md` — consistent with Phase-54 D-18 and Phase-55 D-07 "action required" framing
- Verified the false unqualified banner "No action required for existing installs" (D-01/D-02 prohibition) is absent (`grep -c` returns 0)
- Verified both parts appear adjacent within the same `### Features` entry body, structuring the release-please inheritance guarantee (D-03)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the two-part feat(schema) CHANGELOG entry** - `73ec64c` (feat)
2. **Task 2: Verify the release-note callout inherits both parts** - verification only, no new commit (static structural check passed; note: release-please live rendering enforced by existing CI, D-10 — no new job added)

## Files Created/Modified

- `CHANGELOG.md` — new `### Features` block under `## Unreleased` with `feat(schema)` two-part entry (11 lines inserted)

## Decisions Made

- D-02 LOCKED: used the verbatim two-part banner from 56-CONTEXT.md as starting point, adjusting only Markdown link syntax for the `docs/upgrade-1.x.md` reference
- Config key spelled `schema_prefix` (verified against `config/config.exs:31`) — never bare `:prefix`
- Task 2 requires no commit: static structural checks (`awk` + `grep`) pass; the release-please CI workflow is the live enforcement backstop (D-10)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. This plan is documentation-only (CHANGELOG.md edit). The mitigated threat (T-56-04: misleading release copy) is addressed by the two-part banner and the automated grep prohibition on the false banner string.

## Next Phase Readiness

- Plan 56-04 (final plan of Phase 56) can proceed: SAFE-04 is satisfied
- The `feat(schema)` entry is in place for release-please to generate the v1.7 semver-minor GitHub release note
- All three SAFE requirements (SAFE-01 via 56-01, SAFE-02 via 56-02, SAFE-04 via 56-03) are now complete

## Self-Check

- [x] `CHANGELOG.md` modified with `### Features` block — file exists and contains entry
- [x] Commit `73ec64c` exists in git log
- [x] Automated verification greps all pass (OK + BOTH_PARTS_PRESENT)
- [x] False unqualified banner absent (`grep -c` returns 0)

---
*Phase: 56-contract-release-hardening*
*Completed: 2026-07-02*
