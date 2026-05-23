---
phase: 10-tighten-archive-retention-semantics
verified: 2026-05-22T11:10:10Z
status: verified
score: 4/4 truths verified
human_verification: []
---

# Phase 10: Tighten Archive Retention Semantics Verification Report

**Phase Goal:** Bring archival behavior back into line with the milestone contract so active work never gets pruned.
**Verified:** 2026-05-22T11:10:10Z
**Status:** verified
**Re-verification:** Yes - the archive runtime and proof surfaces were corrected in this session and rechecked against the targeted archive lanes.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `Parapet.Evidence.Archiver.archive/3` archives only resolved incidents older than the retention window. | ✓ VERIFIED | `lib/parapet/evidence/archiver.ex` now uses `state == "resolved"` with the existing `inserted_at < ^cutoff` retention filter. |
| 2 | `investigating` remains active work and is excluded from the archive output and delete path. | ✓ VERIFIED | `test/parapet/evidence/archiver_test.exs` now keeps an old `investigating` fixture in repo state and out of the JSONL export after archival. |
| 3 | The public CLI and optional Oban worker still delegate to the same bounded archive path without a contract change. | ✓ VERIFIED | `lib/mix/tasks/parapet.archive.ex` and `lib/parapet/evidence/archive_worker.ex` still delegate to `Parapet.Evidence.Archiver.archive/3`, and their targeted tests prove the corrected retention rule through each entry surface. |
| 4 | The active milestone proof chain now points at rerunnable archive evidence instead of the contradicted non-open story. | ✓ VERIFIED | `.planning/v0.9-phases/2/VERIFICATION.md`, `.planning/REQUIREMENTS.md`, and `.planning/ROADMAP.md` were reconciled in the same session to the resolved-only contract. |

**Score:** 4/4 truths verified

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core archiver resolved-only proof | `mix test test/parapet/evidence/archiver_test.exs` | 1 test, 0 failures | ✓ PASS |
| CLI and worker entry-surface proof | `mix test test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs` | 5 tests, 0 failures | ✓ PASS |
| Full targeted archive suite | `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs` | 6 tests, 0 failures | ✓ PASS |

### Plan Output Check

| Plan | Summary | Status | Notes |
| --- | --- | --- | --- |
| 10-01 | `.planning/phases/10-tighten-archive-retention-semantics/10-01-SUMMARY.md` | ✓ VERIFIED | Runtime retention semantics and all three targeted test surfaces were repaired and rerun. |
| 10-02 | `.planning/phases/10-tighten-archive-retention-semantics/10-02-SUMMARY.md` | ✓ VERIFIED | Verification, roadmap, and requirement truth surfaces now point to the corrected archive contract without rewriting the historical audit. |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| `SCALE-01.b` archive/export scope | ✓ SATISFIED | The runtime now archives only resolved incidents older than the retention window, and the three targeted archive tests passed in this session. |
| `AC-02` archive acceptance path | ✓ SATISFIED | `mix parapet.archive --days 90` remains contract-stable while the targeted CLI and worker tests prove active `investigating` incidents remain untouched. |

### Human Verification Required

None. The remaining work was proof reconciliation and targeted archive verification, both of which are covered by rerunnable commands and artifact checks.

### Gaps Summary

No known Phase 10 execution gaps remain inside the archive-retention scope. The historical milestone audit remains intentionally unchanged and still requires a fresh rerun before milestone closure is claimed.

---

_Verified: 2026-05-22T11:10:10Z_
_Verifier: Codex_
