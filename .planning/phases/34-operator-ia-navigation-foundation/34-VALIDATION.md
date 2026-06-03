---
phase: 34
slug: operator-ia-navigation-foundation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir Mix, ExUnit, Phoenix LiveView source-contract smoke tests |
| **Config file** | `mix.exs`, `examples/demo_app/mix.exs` |
| **Quick run command** | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs` |
| **Full suite command** | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs && cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` |
| **Estimated runtime** | ~120 seconds locally |

---

## Sampling Rate

- **After every task commit:** Run the quick command for generator/source-contract coverage.
- **After every plan wave:** Run the full suite command.
- **Before `$gsd-verify-work`:** Full suite must be green, plus `mix format --check-formatted`.
- **Max feedback latency:** 180 seconds for the targeted lanes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | UI-IA-01, UI-IA-02 | T-34-01 | Host-owned auth guidance remains unchanged | source + generator | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs` | ✅ | ⬜ pending |
| 34-01-02 | 01 | 1 | UI-IA-03, UI-IA-04 | T-34-02 | Compatibility detail route remains emitted | source + generator | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` | ✅ | ⬜ pending |
| 34-02-01 | 02 | 2 | UI-IA-01, UI-IA-02, UI-IA-03, UI-IA-04 | T-34-03 | Docs continue warning auth is host-owned | docs + demo smoke | `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing test infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All Phase 34 behaviors have automated source-contract or smoke-test verification. Browser screenshot proof is intentionally deferred to Phase 36.

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit Phase 36 deferral
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 180s for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** draft 2026-06-03
