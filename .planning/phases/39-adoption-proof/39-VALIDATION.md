---
phase: 39
slug: adoption-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
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
| **Quick run command** | `mix test test/mix/tasks/parapet.archive_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds for focused docs/route/archive guard lane; full suite varies |

---

## Sampling Rate

- **After every task commit:** Run the focused guard command relevant to touched files.
- **After every plan wave:** Run `mix format --check-formatted && mix test test/mix/tasks/parapet.archive_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs`.
- **Before `$gsd-verify-work`:** Run `mix format --check-formatted && mix compile --warnings-as-errors && mix test`.
- **Max feedback latency:** 60 seconds for the focused docs/route/archive guard lane.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 39-01-01 | 01 | 1 | ADOPT-01 | T-39-01 | Archive docs do not imply backup/restore ownership and name stage-aware failure fields. | docs guard / manual review | `mix test test/mix/tasks/parapet.archive_test.exs` plus any new focused docs assertion | Partial | pending |
| 39-01-02 | 01 | 1 | ADOPT-02 | T-39-02 | Scoped UI docs keep Operator UI inside host-owned authenticated scope examples. | docs guard | `mix test test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` | yes | pending |
| 39-01-03 | 01 | 1 | ADOPT-03 | T-39-03 | Quality closeout records only named v1.4 top-risk closures and preserves unrelated future risks. | artifact review / optional text guard | Manual review; optional focused assertion if planner adds one | Partial | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Add a focused docs assertion for archive adoption copy if planning wants automated ADOPT-01 proof beyond manual review. Candidate file: `test/parapet/adoption_docs_test.exs`.
- [ ] Add a focused artifact assertion for ADOPT-03 only if planning chooses automated planning-artifact tests; otherwise verify manually because `.planning` files are not product runtime.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Quality evaluation closeout preserves original audit snapshot while adding dated closure evidence. | ADOPT-03 | `.planning/QUALITY-EVALUATION.md` is a planning artifact, not runtime product behavior. | Confirm the closeout names Phase 37 archive proof, Phase 38 scoped route proof, and Phase 39 adoption docs proof without claiming every ranked quality issue is closed. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 60s for focused lane.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
