---
phase: 25
slug: wire-confirm-through-claimservice-preview-confirm-ux
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 25 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18) |
| **Config file** | `test/test_helper.exs`, `test/support/concurrency_bootstrap.ex` |
| **Quick run command** | `mix test test/parapet/operator_test.exs test/parapet/operator/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~25 seconds (quick), ~90 seconds (full incl. concurrency) |

---

## Sampling Rate

- **After every task commit:** Run quick command for the file being modified
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd:verify-work`:** Full suite must be green, including `mix test --include unboxed`
- **Max feedback latency:** ~25 seconds

---

## Per-Task Verification Map

> Populated by the planner.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

> Populated by the planner during plan generation. Likely candidates from research:
> - `test/parapet/operator/confirm_concurrency_test.exs` — new concurrency test file using `ConcurrencyCase`
> - `test/parapet/operator/preview_lifecycle_test.exs` (optional) — new home for `:preview_expired` / `:target_refs_drift` unit tests
> - `test/parapet/operator_test.exs` — extend existing file with new return-arm assertions

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Demo LiveView renders the 4 confirm-arm flash strings + Re-Preview button | UI-01, UI-02, UI-03 | Demo app is not in default `mix test` path; LiveView visual states need browser confirmation | Boot the demo app per `examples/demo_app/README.md`, trigger Preview, force each branch (expire token via DB UPDATE, race two browsers, mutate `target_refs` in TimelineEntry payload) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 25s for quick command
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
