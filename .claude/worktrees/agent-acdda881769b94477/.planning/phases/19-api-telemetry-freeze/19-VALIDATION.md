---
phase: 19
slug: api-telemetry-freeze
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in, Elixir 1.19.5) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/telemetry_contract_test.exs test/mix/tasks/verify.public_api_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~quick: a few seconds; full suite: project-dependent |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/telemetry_contract_test.exs test/mix/tasks/verify.public_api_test.exs`
- **After every plan wave:** Run `mix test && mix verify.public_api`
- **Before `/gsd:verify-work`:** `mix test && mix verify.public_api && mix docs --warnings-as-errors` must be green
- **Max feedback latency:** keep quick command under ~10s

---

## Per-Task Verification Map

Concrete task IDs are assigned by the planner. The requirement → behavior → command map below is the binding contract; every task must trace to one of these rows or be Wave 0.

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| STAB-01 | Every public module displays a Stable/Experimental ExDoc callout; Stable fns carry `@doc since: "1.0.0"` | Integration (gate) | `mix verify.public_api` | ✅ extend existing | ⬜ pending |
| STAB-02 | `docs/stability.md` exists, registered in `extras:`, builds | Smoke (docs build) | `mix docs --warnings-as-errors` | ❌ W0 (create file) | ⬜ pending |
| STAB-03 | `docs/telemetry.md` has stability-freeze header, cross-links stability.md | Smoke (docs build) | `mix docs --warnings-as-errors` | ✅ edit existing | ⬜ pending |
| STAB-04 | `mix verify.public_api` exits non-zero on any `:unclassified` module; alias no longer shadows the task | Unit (gate test) | `mix test test/mix/tasks/verify.public_api_test.exs` | ✅ extend existing | ⬜ pending |
| STAB-05 | Contract test fails on telemetry drift across all frozen `[:parapet, …]` families | Unit (contract test) | `mix test test/telemetry_contract_test.exs` | ❌ W0 (create file) | ⬜ pending |
| STAB-06 | `Parapet.SLO.define/2` emits compile-time deprecation warning naming `Parapet.SLO.Provider` | Unit (compile capture) | `mix test test/parapet/slo_test.exs` | ❌ W0 (add test) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/telemetry_contract_test.exs` — new contract test, covers STAB-05 (fixtures for ~27 `[:parapet, …]` families)
- [ ] `docs/stability.md` — new policy artifact, covers STAB-02 (must exist before `mix docs` passes)
- [ ] STAB-06 test — `Code.compile_string` capture pattern in `test/parapet/slo_test.exs` (assert deprecation warning fires)
- [ ] Extend `test/mix/tasks/verify.public_api_test.exs` — assert tier detection + non-zero exit on `:unclassified`

*Existing infrastructure (ExUnit, `test/parapet/telemetry/async_delivery_test.exs` pattern, `verify.public_api.ex`) covers the rest.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc admonition callouts render as `.info` / `.warning` blocks in generated hexdocs | STAB-01 | Visual rendering is not asserted by `mix docs` exit code | Run `mix docs`, open `doc/Parapet.html` and a Stable + an Experimental module; confirm the colored admonition box renders |

*All gate/contract behaviors have automated verification; only visual hexdoc rendering is manual.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < ~10s for quick command
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
