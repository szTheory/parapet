---
phase: 17
slug: recovery-depth-runbook-templates
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/runbook_test.exs test/parapet/operator/workbench_contract_test.exs test/mix/tasks/parapet.gen.runbooks_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5s (quick), full suite per project norm |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/runbook_test.exs test/parapet/operator/workbench_contract_test.exs test/mix/tasks/parapet.gen.runbooks_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite green **and** `mix verify.public_api` (`mix docs --warnings-as-errors`) passes — `Parapet.Runbook` is a documented public module (D-12); the new `warning:` option must be documented or CI breaks.
- **Max feedback latency:** ~5 seconds (quick run)

---

## Per-Task Verification Map

> Task IDs assigned at plan time. Rows below are requirement-anchored; the planner maps each `<automated>` verify to one of these commands. The three regression layers (schema / projection / generator content) exist because the `warning:` failure mode is **invisible at compile time** (Elixir silently swallows unknown macro keyword args).

| Layer | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| DSL/schema | 1 | RCV-01 | `__runbook_schema__/0` exposes `warning` | unit | `mix test test/parapet/runbook_test.exs` | ✅ extend ~`:57-112` | ⬜ pending |
| Projection | 1 | RCV-01 | `WorkbenchContract.derive_runbook_steps/3` carries `warning` (highest silent-drop risk) | unit | `mix test test/parapet/operator/workbench_contract_test.exs` | ✅ extend ~`:308-369` | ⬜ pending |
| UI render | 1 | RCV-01 / AC-03 | `runbook_card` renders a step-level warning block (amber/red), not via runtime `preview_panel` | manual smoke | open Operator UI against a deepened template | ❌ manual-only | ⬜ pending |
| Template content (existing ×4) | 2 | RCV-01 | each deepened template file contains its `warning:` line + precondition + scoped preview + verification | unit | `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` | ✅ extend ~`:8-48` | ⬜ pending |
| Template content (new ×3) | 2 | RCV-02 | `retry_storm`, `suppression_drift`, `partial_backlog_drain` files generated at depth, copied with `on_exists: :skip` | unit | `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` | ✅ extend same test | ⬜ pending |
| Capability allowlist | 2 | RCV-02 | no new `capability:` ids; wired mitigations reuse only the three real capabilities (`retry_storm` is guidance-only — RESEARCH correction) | unit | `mix test test/parapet/capabilities_test.exs` | ✅ guards `:8-12` / `:35-37` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All three regression layers extend **existing** test files — no new test files needed:

- [ ] `test/parapet/runbook_test.exs` — extend `DummyRunbook` with a `warning:` step, assert `__runbook_schema__()` exposes `warning` (RCV-01 DSL layer; mirror existing pattern ~`:57-112`).
- [ ] `test/parapet/operator/workbench_contract_test.exs` — extend the `runbook_data` step fixture with a `warning:` key, assert the projected step map includes `warning` (RCV-01 projection layer; the layer most likely to silently drop it — extend ~`:308-369`).
- [ ] `test/mix/tasks/parapet.gen.runbooks_test.exs` — add file-path + content assertions for the three new templates and the `warning:` line on deepened templates (RCV-01/RCV-02 generator layer; extend ~`:8-48`).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator visually sees the warning block + precondition + scoped preview + bounded mitigation on a deepened and a new template | AC-03 | Visual render of the LiveView `runbook_card` is not asserted by unit tests | Run the Operator UI against an alert whose `runbook_data` includes a Phase 17 template (≥1 deepened, ≥1 new); confirm the amber/red warning block renders distinctly from guidance, the scoped preview gates on `requires_preview: true`, and the verification step appears as a guidance step |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
