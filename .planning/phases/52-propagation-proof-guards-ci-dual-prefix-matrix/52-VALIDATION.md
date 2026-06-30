---
phase: 52
slug: propagation-proof-guards-ci-dual-prefix-matrix
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 52 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.x / Ecto 3.13.x) |
| **Config file** | `test/test_helper.exs` + `test/support/concurrency_bootstrap.ex` (`ConcurrencyCase`) |
| **Quick run command** | `mix test test/parapet/schema_prefix_guard_test.exs test/parapet/spine/prefix_propagation_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~60 seconds (full suite); dual-leg CI ≈ 2× per matrix cell |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (guard + propagation legs)
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite green on the `parapet` leg locally; CI proves both legs
- **Max feedback latency:** ~60 seconds local

---

## Per-Task Verification Map

> Filled by the planner from PLAN.md tasks. Each task maps to an automated `mix test` leg or a guard assertion.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 52-XX-XX | XX | N | PROP-01/02/03, TEST-03 | — | compiled prefix rides every read/write path; no runtime `prefix:`; identifier-safe | unit / fitness | `mix test ...` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/parapet/schema_prefix_guard_test.exs` — PROP-02 static guard (green from day one, zero offenders)
- [ ] `test/parapet/spine/prefix_propagation_test.exs` — PROP-01/PROP-03 positive proof (`to_sql` + `get_meta`)
- [ ] `test/parapet/spine/compiled_prefix_leg_test.exs` — TEST-03 in-suite false-green tripwire

*Existing infrastructure (`ConcurrencyCase`, leg-aware `q/1`) covers the harness; these stub files are net-new.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dual-leg CI matrix green on both `parapet` and `public` | TEST-03 | Requires GitHub Actions runner; cannot run both legs in one local `mix test` pass | Push branch; confirm both `test (… parapet)` and `test (… public)` cells pass with prefix-namespaced `_build` cache keys |

*All other phase behaviors have automated verification in the local `mix test` lane.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
