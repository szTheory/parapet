---
phase: 04
slug: unified-install-path-dx
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-20
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `ExUnit` |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs test/parapet_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **Closure rerun completed 2026-05-21:** `mix test test/mix/tasks/parapet.install_test.exs` and `mix test test/mix/tasks/parapet.doctor_test.exs`
- **Closure doc check completed 2026-05-21:** `rg -n 'mix parapet\\.install|mix parapet\\.doctor|--with-ui|--skip-ui|cluster|does \\*\\*not\\*\\* provide its own authentication system' README.md docs/operator-ui.md`
- **Closure manual proof completed 2026-05-21:** Fresh Phoenix host smoke transcript captured in `.planning/v0.9-phases/4/VERIFICATION.md`
- **Canonical closure artifact:** `.planning/v0.9-phases/4/VERIFICATION.md`

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 04-01-01 | 01 | 1 | DX-01 | T-04-01 / T-04-04 | Installer composes core generators in locked order and stays deterministic under flags | unit | `mix test test/mix/tasks/parapet.install_test.exs` | ✅ | ✅ verified via `.planning/v0.9-phases/4/VERIFICATION.md` |
| 04-01-02 | 01 | 1 | DX-01 | T-04-02 / T-04-03 | UI and integrations remain explicit opt-ins; absent optional deps stay compile-out clean in a fresh host | unit + manual smoke | `mix test test/mix/tasks/parapet.install_test.exs` plus fresh-host transcript in `.planning/v0.9-phases/4/VERIFICATION.md` | ✅ | ✅ verified |
| 04-02-01 | 02 | 1 | DX-01 | T-04-06 / T-04-08 | Doctor exposes severity, threshold, and exit-code semantics with stable JSON output | unit | `mix test test/mix/tasks/parapet.doctor_test.exs` | ✅ | ✅ verified via `.planning/v0.9-phases/4/VERIFICATION.md` |
| 04-02-02 | 02 | 1 | DX-01 | T-04-05 / T-04-07 | Doctor distinguishes static uncertainty from hard cluster contradictions and exposes runtime `cluster` mode honestly | unit + manual smoke | `mix test test/mix/tasks/parapet.doctor_test.exs` plus `mix parapet.doctor cluster` transcript in `.planning/v0.9-phases/4/VERIFICATION.md` | ✅ | ✅ verified |
| 04-03-01 | 03 | 2 | DX-01 | T-04-09 / T-04-11 | README documents the unified install path and immediate doctor follow-up accurately | doc-check | `rg -n 'mix parapet\\.install|mix parapet\\.doctor|Parapet\\.attach\\(adapters:' README.md` | ✅ | ✅ verified |
| 04-03-02 | 03 | 2 | DX-01 | T-04-10 | Operator UI guide preserves host-owned auth and honest doctor wording | doc-check | `rg -n 'mix parapet\\.install|Parapet does \\*\\*not\\*\\* provide its own authentication system|mix parapet\\.doctor' docs/operator-ui.md` | ✅ | ✅ verified |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/mix/tasks/parapet.install_test.exs` — existing harness for installer orchestration/idempotency assertions
- [x] `test/mix/tasks/parapet.doctor_test.exs` — existing harness for doctor CLI and JSON behavior
- [x] `test/parapet_test.exs` — existing proof surface to extend with compile-out cleanliness assertions for optional integrations

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh Phoenix host can adopt Parapet through the public Day-1 command and reach the documented doctor follow-up honestly | DX-01, AC-01 | Closure proof must show the public adopter path, generated host-owned artifacts, and doctor handoff in a real host app; that remains manual evidence rather than a permanent merge gate | Re-run the fresh-host transcript recorded in `.planning/v0.9-phases/4/VERIFICATION.md`: create a Phoenix app, add local `:parapet`, run `mix deps.get`, run `mix parapet.install`, confirm the generated host-owned files and install summary, then run `mix parapet.doctor` and `mix parapet.doctor cluster` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** satisfied by `.planning/v0.9-phases/4/VERIFICATION.md`
