---
phase: 39-adoption-proof
plan: 01
subsystem: docs
tags: [adoption, archive, operator-ui, troubleshooting, exunit]

requires:
  - phase: 37-archive-durability
    provides: staged archive JSONL/manifest runtime, success JSON, failure fields, and retention boundary
  - phase: 38-scoped-ui-routes
    provides: scoped Operator UI route examples and generated operator_base_path behavior
provides:
  - README archive maintenance commands, cadence, boundary, and failure support path
  - README and operator UI default `/parapet` and scoped `/ops/parapet` router examples
  - troubleshooting recovery copy for archive failures and scoped UI mounting gotchas
  - focused ExUnit docs guard for ADOPT-01 and ADOPT-02
affects: [adoption-docs, archive-maintenance, operator-ui-docs, troubleshooting, ADOPT-01, ADOPT-02]

tech-stack:
  added: []
  patterns:
    - focused docs guards that assert support-critical strings without pinning full prose
    - first-contact README guidance with deeper troubleshooting links

key-files:
  created:
    - test/parapet/adoption_docs_test.exs
    - .planning/phases/39-adoption-proof/39-01-SUMMARY.md
  modified:
    - README.md
    - docs/operator-ui.md
    - docs/troubleshooting.md

key-decisions:
  - "Kept Phase 39 to documentation and ExUnit docs guards only; no runtime, API, dependency, auth, router ownership, or install-surface changes were introduced."
  - "Used exact archive boundary and retention-limit sentences from the Phase 39 UI contract in README and troubleshooting."
  - "Documented scoped UI mounting as host-owned router/auth guidance instead of adding generator flags or Parapet router abstractions."

patterns-established:
  - "Adoption docs guard: read Markdown files directly and assert only the operationally important tokens and phrases."
  - "Scoped UI troubleshooting: pair a short gotchas block in docs/operator-ui.md with fuller recovery sections in docs/troubleshooting.md."

requirements-completed: [ADOPT-01, ADOPT-02]

duration: 6min
completed: 2026-06-04
---

# Phase 39 Plan 01: Archive and Scoped UI Adoption Docs Summary

**Archive maintenance and scoped Operator UI mounting are now copy-pasteable from first-contact docs and guarded by focused ExUnit documentation tests.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-04T21:23:00Z
- **Completed:** 2026-06-04T21:28:51Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added README archive maintenance guidance for `mix parapet.archive`, `--days`, `--path`, default JSONL path, manifest, success fields, failure fields, cadence, and safe troubleshooting cross-link.
- Expanded troubleshooting with archive cadence, pre-prune failures, delete-stage failures, missing repo config, invalid retention/path usage, and safe rerun expectations.
- Added README default `/parapet` and scoped `/ops/parapet` Phoenix router examples with the complete generated route map.
- Added scoped Operator UI gotchas and troubleshooting for stale generated files, missing authenticated pipeline/live session protection, and partial `/ops/parapet` route maps.
- Created `Parapet.AdoptionDocsTest` to guard ADOPT-01 and ADOPT-02 docs claims.

## Task Commits

Each task was committed atomically:

1. **Task 39-01-01 RED: archive adoption docs guard** - `0ee4616` (test)
2. **Task 39-01-01 GREEN: archive maintenance adoption docs** - `d35bed7` (docs)
3. **Task 39-01-02 RED: scoped operator docs guard** - `e9944bc` (test)
4. **Task 39-01-02 GREEN: scoped Operator UI mounting docs** - `8c71433` (docs)

## Files Created/Modified

- `test/parapet/adoption_docs_test.exs` - Adds focused docs guards for archive maintenance and scoped Operator UI mounting claims.
- `README.md` - Adds scoped Operator UI router examples and archive maintenance first-contact guidance.
- `docs/operator-ui.md` - Adds exact host-owned responsibility language and scoped mount gotchas.
- `docs/troubleshooting.md` - Adds archive and scoped UI first-error recovery sections.

## Decisions Made

- Followed the plan's no-expansion boundary: documentation and tests only, with no package installs or runtime/source changes.
- Kept archive docs scoped to Parapet-owned evidence export/prune, not host backup/restore.
- Kept scoped UI docs scoped to host-owned router/auth configuration, not Parapet-owned route behavior.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The RED docs guards failed before docs edits as expected.
- During GREEN, a few exact guarded phrases needed contiguous Markdown wording; the docs were adjusted without changing scope.

## TDD Gate Compliance

- RED gate present for Task 39-01-01: `0ee4616 test(39-01): add archive adoption docs guard`
- GREEN gate present after RED for Task 39-01-01: `d35bed7 docs(39-01): document archive maintenance adoption path`
- RED gate present for Task 39-01-02: `e9944bc test(39-01): add scoped operator docs guard`
- GREEN gate present after RED for Task 39-01-02: `8c71433 docs(39-01): document scoped operator UI mounting`

## Verification

- `mix test test/parapet/adoption_docs_test.exs` - RED failed before docs edits for both task guards.
- `mix test test/parapet/adoption_docs_test.exs test/mix/tasks/parapet.archive_test.exs` - passed, 5 tests, 0 failures.
- `mix test test/parapet/adoption_docs_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` - passed, 28 tests, 0 failures.
- `mix format --check-formatted && mix test test/mix/tasks/parapet.archive_test.exs test/parapet/adoption_docs_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` - passed, 31 tests, 0 failures.

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

None. The plan threat model already covered the archive documentation and scoped UI documentation trust boundaries, and this plan introduced no new network endpoint, auth path, file access pattern, schema change, dependency surface, runtime route behavior, or stable public API surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 39-02 can use the docs guard as the ADOPT-01/ADOPT-02 proof surface while closing the quality-evaluation trail for ADOPT-03.

## Self-Check: PASSED

- Found created summary file path: `.planning/phases/39-adoption-proof/39-01-SUMMARY.md`.
- Found created docs guard: `test/parapet/adoption_docs_test.exs`.
- Found task commits `0ee4616`, `d35bed7`, `e9944bc`, and `8c71433`.
- Stub scan found no placeholder or hardcoded-empty UI stubs in files created or modified by this plan.

---
*Phase: 39-adoption-proof*
*Completed: 2026-06-04*
