---
phase: 39
slug: adoption-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
---

# Phase 39 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Mix 1.19.5 |
| **Config file** | None specific to this phase; standard `test/**/*_test.exs` layout |
| **Quick run command** | `mix test test/mix/tasks/parapet.archive_test.exs test/parapet/adoption_docs_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds for focused docs/route/archive guard lane; full suite varies |

---

## Sampling Rate

- **After every task commit:** Run the focused guard command relevant to touched files.
- **After every plan wave:** Run `mix format --check-formatted && mix test test/mix/tasks/parapet.archive_test.exs test/parapet/adoption_docs_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs`.
- **Before `$gsd-verify-work`:** Run `mix format --check-formatted && mix compile --warnings-as-errors && mix test`.
- **Max feedback latency:** 60 seconds for the focused docs/route/archive guard lane.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | ADOPT-01 | T-39-01, T-39-02 | Archive docs do not imply backup/restore ownership, explain when to run archive maintenance, and name stage-aware failure fields. | docs guard | `mix test test/parapet/adoption_docs_test.exs test/mix/tasks/parapet.archive_test.exs` | W0 | pending |
| 39-01-02 | 01 | 1 | ADOPT-02 | T-39-03, T-39-04 | Scoped UI docs keep Operator UI inside host-owned authenticated scope examples and cover stale/partial scoped mounts. | docs guard | `mix test test/parapet/adoption_docs_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` | W0 | pending |
| 39-02-01 | 02 | 2 | ADOPT-03 | T-39-05, T-39-06 | Quality closeout records only named v1.4 top-risk closures and preserves unrelated future risks. | artifact text guard | `mix test test/parapet/adoption_docs_test.exs` | W0 | pending |
| 39-02-02 | 02 | 2 | ADOPT-03 | T-39-07, T-39-SC | Final verification proves closeout and docs proof without runtime, API, dependency, auth, router, migration, object-store, generator flag, or visual redesign expansion. | focused + full suite | `mix test test/mix/tasks/parapet.archive_test.exs test/parapet/adoption_docs_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs && mix format --check-formatted && mix compile --warnings-as-errors && mix test` | W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing plan tasks cover all Wave 0 needs:

- [x] `test/parapet/adoption_docs_test.exs` is created in Plan 39-01 and guards ADOPT-01 archive adoption copy.
- [x] `test/parapet/adoption_docs_test.exs` is extended in Plan 39-01 and Plan 39-02 to guard ADOPT-02 scoped UI docs and ADOPT-03 quality closeout copy.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Quality evaluation closeout preserves original audit snapshot while adding dated closure evidence. | ADOPT-03 | `.planning/QUALITY-EVALUATION.md` is a planning artifact, not runtime product behavior. | Confirm the closeout names Phase 37 archive proof, Phase 38 scoped route proof, and Phase 39 adoption docs proof without claiming every ranked quality issue is closed. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references through planned adoption docs assertions.
- [x] No watch-mode flags.
- [x] Feedback latency < 60s for focused lane.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
