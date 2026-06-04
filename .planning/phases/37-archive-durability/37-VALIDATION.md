---
phase: 37
slug: archive-durability
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 37 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/parapet/evidence/archiver_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds for focused tests, repository-dependent for full suite |

---

## Sampling Rate

- **After every task commit:** Run the task's focused `mix test ...` command.
- **After every plan wave:** Run `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs`.
- **Before `$gsd-verify-work`:** `mix test`, `mix format --check-formatted`, and `mix compile --warnings-as-errors` must be green.
- **Max feedback latency:** one focused test command per task unless the task changes shared archive behavior.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 37-01-01 | 01 | 1 | ARCH-01, ARCH-03 | T-37-01 | Eligible incident selection is exact and active/investigating incidents are not pruned | unit | `mix test test/parapet/evidence/archiver_test.exs` | yes | pending |
| 37-01-02 | 01 | 1 | ARCH-01, ARCH-04 | T-37-02 | Archive artifact contains incident, timeline, tool audit, action item, and action claim counts | unit | `mix test test/parapet/evidence/archiver_test.exs` | yes | pending |
| 37-01-03 | 01 | 1 | ARCH-02, ARCH-04 | T-37-03 | Export/write/verify failures prevent prune and return actionable failure structs | unit | `mix test test/parapet/evidence/archiver_test.exs` | yes | pending |
| 37-01-04 | 01 | 1 | ARCH-02, ARCH-04 | T-37-04 | Delete failures return failure context with published archive details and exact counts | unit | `mix test test/parapet/evidence/archiver_test.exs` | yes | pending |
| 37-02-01 | 02 | 2 | ARCH-02, ARCH-04 | T-37-05 | CLI success prints summary JSON and CLI failure raises without success JSON | unit | `mix test test/mix/tasks/parapet.archive_test.exs` | yes | pending |
| 37-02-02 | 02 | 2 | ARCH-02, ARCH-04 | T-37-06 | Optional Oban worker passes through structured archive result tuples | unit | `mix test test/parapet/evidence/archive_worker_test.exs` | yes | pending |
| 37-03-01 | 03 | 3 | ARCH-01, ARCH-02, ARCH-03, ARCH-04 | T-37-07 | Experimental API contract and retention limitation are documented for maintainers | docs/static | `mix compile --warnings-as-errors && mix format --check-formatted` | yes | pending |

## Wave 0 Requirements

Existing test infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification. Manual review should still inspect the resulting manifest JSON and CLI JSON shape for operator usefulness.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Focused feedback latency is bounded by ExUnit file-level commands.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending execution

