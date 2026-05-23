---
phase: 13
slug: repair-generated-operator-resolve-flow
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-23
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir `1.19.5` |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30-90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | `SCALE-01.c` | T-13-01 | Queue-side `"resolve"` delegates to `Parapet.Operator.resolve_incident/2` and never uses `record_note/3` for lifecycle mutation | generator integration | `mix test test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | ✅ | ⬜ pending |
| 13-01-02 | 01 | 1 | `SCALE-01.c` | T-13-01 | Resolved incidents leave the active queue and become visible in the resolved-history lane without breaking bounded paging | runtime integration | `mix test test/parapet/generated_operator_live_paging_test.exs` | ✅ | ⬜ pending |
| 13-02-01 | 02 | 2 | `AC-03` | T-13-02 | Phase 3 and Phase 7 proof surfaces explicitly reference the repaired resolve-flow lane and stop implying closure from an unexercised queue action | docs verification | `rg -n "resolve_incident|record_note|Generated operator resolve action|SCALE-01.c|AC-03" .planning/v0.9-phases/3/VERIFICATION.md .planning/v0.9-phases/3/03-VALIDATION.md .planning/v0.9-phases/7/VERIFICATION.md .planning/v0.9-phases/7/07-VALIDATION.md docs/operator-ui.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/parapet/generated_operator_live_paging_test.exs` — extend the fake repo beyond read-only active queue reads so it can persist `resolve_incident/2` effects and serve resolved-history queries.
- [ ] `test/parapet/operator_ui_integration_test.exs` and/or `test/mix/tasks/parapet.gen.ui_test.exs` — add explicit queue resolve seam assertions for `Parapet.Operator.resolve_incident/2` and absence of `record_note/3` in that path.
- [ ] `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/3/03-VALIDATION.md`, `.planning/v0.9-phases/7/VERIFICATION.md`, `.planning/v0.9-phases/7/07-VALIDATION.md` — update wording so these files point at the repaired runtime proof and stop implying closure from an unexercised resolve path.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | All planned phase behaviors have automated verification lanes | — |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for the targeted lane
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
