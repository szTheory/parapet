---
phase: 28
slug: demo-seed-ci-lane
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-28
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir standard — no version pin) |
| **Config file** | `examples/demo_app/test/test_helper.exs` (sandbox manual mode) |
| **Quick run command** | `cd examples/demo_app && mix test --only smoke` |
| **Full suite command** | `cd examples/demo_app && mix test --only smoke` (all demo tests are `:smoke`-tagged) |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/demo_app && mix test --only smoke`
- **After every plan wave:** Run `cd examples/demo_app && mix test --only smoke`
- **Before `/gsd:verify-work`:** Full `:smoke` suite green AND `cd examples/demo_app && mix run priv/repo/seeds.exs` exits 0
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

> Populated after planning assigns task IDs. Each DEMO-06 scenario is a discrete ExUnit assertion in `recovery_loop_test.exs`; DEMO-05 is the seed block + `mix demo.reset` alias.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| {N}-01-01 | 01 | 1 | DEMO-05 / DEMO-06 | — | N/A (no new trust boundary) | unit/smoke | `cd examples/demo_app && mix test --only smoke` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/demo_app/test/demo_app/recovery_loop_test.exs` — covers DEMO-06 all four scenarios (happy-path, expired-preview, resolved mid-flow, claim-conflict)
- [ ] `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex` — `use Parapet.Recovery` capability; required so boot-time `attach/1` does not crash (prereq for all tests)
- [ ] `examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex` — `use Parapet.Runbook`; required so `extract_module/1` resolves (DEMO-05/06 prereq)
- [ ] `examples/demo_app/priv/repo/seeds.exs` — 4th (capability-backed) incident block carrying `runbook_data["module"]` (DEMO-05 seed)
- [ ] `examples/demo_app/mix.exs` — `demo.reset` alias (DEMO-05 replayability)
- [ ] `examples/demo_app/lib/demo_app/application.ex` — add `Parapet.Capabilities` supervision child + boot-time `Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` (boot prereq for all tests)

*Existing infrastructure (`DemoAppWeb.ConnCase`, `test_helper.exs`, the CI `demo` job) is already present and correct — no changes needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser click-through Preview → Confirm executes the capability against demo DB state | DEMO-05 (Success Criterion #1) | Browser interaction; the deterministic contract is the headless ExUnit scenarios (DEMO-06). Wallaby/LiveViewTest deliberately out of scope (CONTEXT.md `<deferred>`). | `cd examples/demo_app && mix setup && mix phx.server`; open the seeded capability-backed incident; click Preview, then Confirm; observe the `ActionItem` mutation + a `recovery_confirmed` TimelineEntry. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
