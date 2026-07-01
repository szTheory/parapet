---
phase: 55
slug: demo-app-upgrade-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-01
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: 55-RESEARCH.md `## Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `examples/demo_app/test/test_helper.exs` |
| **Quick run command** | `cd examples/demo_app && mix test --only smoke` |
| **Full suite command** | `cd examples/demo_app && mix test` |
| **Estimated runtime** | ~15 seconds (demo smoke lane) |

---

## Sampling Rate

- **After every task commit:** `cd examples/demo_app && mix test --only smoke` (after sentinel migration exists)
- **After every plan wave:** `cd examples/demo_app && mix test` + `mix docs --warnings-as-errors` (from lib root)
- **Before `/gsd-verify-work`:** Full library suite green (`mix test`) + demo smoke green + `mix docs --warnings-as-errors` clean
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 55-01-01 | 01 | 0 | SAFE-03 | — | Demo `mix ecto.migrate` succeeds (schema exists) | integration | `cd examples/demo_app && mix ecto.create && mix ecto.migrate` | ❌ W0 | ⬜ pending |
| 55-01-02 | 01 | 1 | SAFE-03 | T-55-01 | Six spine tables present in resolved schema | smoke | `cd examples/demo_app && mix test --only smoke` | ❌ W0 | ⬜ pending |
| 55-01-03 | 01 | 1 | SAFE-03 | — | Round-trip `get_meta == schema_prefix()` | smoke | `cd examples/demo_app && mix test --only smoke` | ❌ W0 | ⬜ pending |
| 55-01-04 | 01 | 1 | SAFE-03 | — | Demo compile-out-clean | CI step | `cd examples/demo_app && mix compile --no-optional-deps --warnings-as-errors` | ✅ | ⬜ pending |
| 55-02-01 | 02 | 1 | DOC-01/DOC-02 | T-55-02 | Docs registered + cross-links resolve | docs gate | `mix docs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Planner refines this map to match final task IDs.*

---

## Wave 0 Requirements

- [ ] `examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs` — sentinel migration creating the `parapet` schema. **CRITICAL: the demo CI job cannot `mix ecto.migrate` without this** (drift flag from 55-RESEARCH). Must be leg-aware (no-op / `public` when `schema_prefix()` is nil).
- [x] No test-framework install needed — ExUnit already present.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reassure→instruct tone; "your data does not move unless you choose" TL;DR | DOC-01 | Prose quality not machine-checkable | Read `docs/upgrade-1.x.md` intro |
| Track A/B copy-paste blocks verbatim from Phase 54; each config block followed by `--force` recompile line | DOC-01 | Content-equivalence not machine-checkable | Diff blocks against 54-CONTEXT D-04/D-06/D-17 |
| FAQ present and covers half-migrated recovery | DOC-01 | Completeness judgment | Read FAQ + rollback sections |
| migration-v1.md Step 3 reassures-then-routes (not buried in a checklist) | DOC-02 | Placement judgment | Read new Step 3 |

*These are SAFE-03 / DOC-01 UAT review items — not CI-enforceable.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the sentinel-migration MISSING reference
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
