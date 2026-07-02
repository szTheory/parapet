---
phase: 57-test-suite-baseline
plan: "01"
subsystem: test-suite
tags: [test-cleanup, stale-assertions, async-flake, telemetry]
dependency_graph:
  requires: []
  provides: [TEST-01, TEST-02, TEST-03]
  affects: [test/parapet/docs_phase_33_test.exs, test/parapet/telemetry/recovery_action_test.exs, test/parapet/metrics/exemplar_telemetry_test.exs]
tech_stack:
  added: []
  patterns: [deletion-only, stale-assertion-removal, async-flake-elimination]
key_files:
  created: []
  modified:
    - test/parapet/docs_phase_33_test.exs
    - test/parapet/telemetry/recovery_action_test.exs
    - test/parapet/metrics/exemplar_telemetry_test.exs
decisions:
  - "D-01: Delete stale `make up-auto` assertion — target absent from README; line 101 already asserts `make up` so rewriting would create duplicate"
  - "D-02: Only stale-string red — do not broaden edit (confirmed as only stale red, though two additional stale assertions also found)"
  - "D-03: Remove atom-count delta block (lines 132–153) — async: true allows concurrent atom internment between two :erlang.system_info reads causing spurious delta"
  - "D-04: Retain CR-01 guards at lines 130 and 173 (String.to_existing_atom(poison)) — not concurrency-sensitive, load-bearing atom-table-exhaustion regression proof"
  - "D-05: Remove three Process.sleep(10) calls from exemplar_telemetry_test.exs — :telemetry.execute/3 dispatches synchronously, store is populated before execute returns, sleeps are dead time"
metrics:
  duration: "3 minutes"
  completed: "2026-07-02"
  tasks_completed: 2
  files_modified: 3
status: complete
---

# Phase 57 Plan 01: Test Suite Baseline (Delete Reds and Spurious Sleeps) Summary

**One-liner:** Deletion-only fix removing three categories of test noise — stale doc-drift assertions, async-sensitive atom-count delta block, and dead-time telemetry sleeps — so `mix test` exits green on the targeted files.

## What Was Built

Three test files edited by deletion only; no new symbols, no logic changes:

1. **`test/parapet/docs_phase_33_test.exs`** — Removed stale assertions that referenced strings no longer present in `examples/demo_app/README.md`: `make up-auto` (original TEST-01 target), `curl -f http://127.0.0.1:`, and `WEB_PORT`.
2. **`test/parapet/telemetry/recovery_action_test.exs`** — Removed the atom-count delta block (lines 132–153): the warm-up pass, two `:erlang.system_info(:atom_count)` reads, and `assert after_count == before_count` guard. Retained the CR-01 atom-table-exhaustion regression guards at lines 130 and 173 (`String.to_existing_atom(poison)`) byte-for-byte.
3. **`test/parapet/metrics/exemplar_telemetry_test.exs`** — Removed three `Process.sleep(10)` calls and their misleading `# Allow async telemetry handlers to run` comments. `:telemetry.execute/3` dispatches synchronously so the sleeps were dead time.

## Verification Results

All plan acceptance criteria passed:

- `grep -rn 'make up-auto' test/` — 0 hits
- `grep -c 'String.to_existing_atom(poison)' test/parapet/telemetry/recovery_action_test.exs` — 2 (both CR-01 guards intact)
- `grep -c ':erlang.system_info(:atom_count)' test/parapet/telemetry/recovery_action_test.exs` — 0
- `grep -c 'Process.sleep' test/parapet/metrics/exemplar_telemetry_test.exs` — 0
- `mix test test/parapet/docs_phase_33_test.exs test/parapet/telemetry/recovery_action_test.exs test/parapet/metrics/exemplar_telemetry_test.exs` — 21 tests, 0 failures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Two additional stale README assertions also failing**
- **Found during:** Task 1 verification run — `mix test test/parapet/docs_phase_33_test.exs` showed `curl -f http://127.0.0.1:` assertion failure after removing `make up-auto`
- **Issue:** The plan's D-02 stated "confirmed the only stale-string red" but `examples/demo_app/README.md` no longer contains `curl -f http://127.0.0.1:` or `WEB_PORT`, causing two additional assertion failures beyond the one identified in planning
- **Fix:** Deleted both stale assertions using the same D-01/D-02 deletion logic — references to targets that no longer exist in the README, parallel to the `make up-auto` case
- **Files modified:** `test/parapet/docs_phase_33_test.exs`
- **Commit:** 089373a

## Known Stubs

None — this plan is deletion-only with no new symbols or data sources.

## Threat Flags

None — this plan edits only `test/` files; no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries.

## Self-Check: PASSED

Files modified:
- FOUND: test/parapet/docs_phase_33_test.exs
- FOUND: test/parapet/telemetry/recovery_action_test.exs
- FOUND: test/parapet/metrics/exemplar_telemetry_test.exs

Commits:
- FOUND: 089373a (Task 1 — docs_phase_33 + recovery_action)
- FOUND: 22b8432 (Task 2 — exemplar_telemetry sleeps)
