---
phase: 8
slug: close-day-1-install-and-doctor-verification
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-21
---

# Phase 8 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + shell/doc proof lane |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs` |
| **Doc contract command** | `rg -n 'mix parapet\\.install|mix parapet\\.doctor|--with-ui|--skip-ui|cluster' README.md docs/operator-ui.md` |
| **Estimated runtime** | ~30-60 seconds plus fresh-host smoke setup |

## Sampling Rate

- **After each proof-task commit in 08-01:** rerun the targeted install/doctor task tests and any affected doc-contract grep checks.
- **Before closing 08-01:** rerun the full targeted proof suite and capture one fresh Phoenix host smoke transcript for `mix parapet.install` -> `mix parapet.doctor`.
- **Before closing 08-02:** verify the reconciled planning artifacts point directly at the new Phase 4 verification report and only the intended traceability rows changed.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 08-01-01 | 01 | 1 | `DX-01.a` | unit | `mix test test/mix/tasks/parapet.install_test.exs` | planned |
| 08-01-02 | 01 | 1 | `DX-01.b` | unit | `mix test test/mix/tasks/parapet.doctor_test.exs` | planned |
| 08-01-03 | 01 | 1 | `DX-01.a`, `DX-01.b`, `AC-01` | doc-check | `rg -n 'mix parapet\\.install|mix parapet\\.doctor|--with-ui|--skip-ui|cluster' README.md docs/operator-ui.md` | planned |
| 08-01-04 | 01 | 1 | `DX-01.a`, `AC-01` | manual smoke capture | `test -x scripts/setup_sandbox.sh || true` | planned |
| 08-02-01 | 02 | 2 | `DX-01.a`, `DX-01.b`, `AC-01` | doc reconciliation | `rg -n 'VERIFICATION.md|DX-01.a|DX-01.b|AC-01|Verified|Phase 8' .planning/phases/04-unified-install-path-dx/04-VALIDATION.md .planning/REQUIREMENTS.md .planning/ROADMAP.md` | planned |

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh Phoenix host can adopt Parapet through the public Day-1 command and reach the documented doctor follow-up honestly | `DX-01.a`, `AC-01` | This requires a disposable adopter app, local generator output inspection, and human judgment about whether the docs handoff matches the shipped behavior | Create a fresh Phoenix host, add local `:parapet` as a path dependency, run `mix deps.get`, run `mix parapet.install`, inspect generated host-owned files and summary output, run `mix parapet.doctor`, optionally run `mix parapet.doctor cluster` as an honesty check, and record the exact command/results transcript in `.planning/v0.9-phases/4/VERIFICATION.md` |
| AC-01 wording correction preserves the optional operator UI boundary instead of widening product scope | `AC-01` | This is a scope-truthfulness judgment, not just a mechanical grep | Review `.planning/REQUIREMENTS.md`, `README.md`, and `docs/operator-ui.md` together; confirm the corrected acceptance wording says core install by default and optional UI only when explicitly requested and available |

## Validation Sign-Off

- [x] All tasks have an automated verification path or an explicit manual-proof reason
- [x] No watch-mode flags
- [x] Proof surfaces are rerunnable in this repo
- [x] Fresh-host smoke remains a manual closure artifact, not a permanent test gate
- [x] Reconciliation scope is narrow and directly traceable

**Approval:** ready for planning
