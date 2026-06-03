---
phase: 21
slug: runnable-demo-app
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (demo app's own suite) |
| **Config file** | `examples/demo_app/test/test_helper.exs` |
| **Quick run command** | `cd examples/demo_app && mix test` |
| **Full suite command** | `cd examples/demo_app && mix test` (library suite separate: `mix test`) |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/demo_app && mix compile`
- **After every plan wave:** Run `cd examples/demo_app && mix test`
- **Before `/gsd:verify-work`:** Full suite + `mix hex.build --dry-run` must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | DEMO-01 | — | N/A | integration | `cd examples/demo_app && mix compile` | ✅ W0 | ⬜ pending |
| 21-02-01 | 02 | 1 | DEMO-02 | — | N/A | integration | `cd examples/demo_app && mix ecto.migrate && mix run priv/repo/seeds.exs` | ✅ W0 | ⬜ pending |
| 21-02-02 | 02 | 2 | DEMO-02/03 | — | N/A | smoke | `cd examples/demo_app && mix test` | ✅ W0 | ⬜ pending |
| 21-03-01 | 03 | 3 | DEMO-03 | — | N/A | ci | `gh act -j demo` / verify ci.yml syntax | ✅ W0 | ⬜ pending |
| 21-03-02 | 03 | 3 | DEMO-04 | — | N/A | cli | `mix hex.build --dry-run 2>&1 | grep -v examples` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/demo_app/test/test_helper.exs` — ExUnit bootstrap
- [ ] `examples/demo_app/test/demo_smoke_test.exs` — smoke test stubs for DEMO-03

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `mix setup && mix phx.server` serves populated UI at `/parapet` | DEMO-01/02 | Requires running Phoenix server and browser | `cd examples/demo_app && mix setup && mix phx.server` then visit http://localhost:4000/parapet; verify incidents visible |
| `release_gate` branch protection wired in GitHub | DEMO-03 | Branch protection settings are not automated | Verify `release_gate` in GitHub Settings → Branches → required status checks |
| `mix hex.build --dry-run` confirms `examples/` absent | DEMO-04 | One-off publish verification | Run from parapet root: `mix hex.build --dry-run` and scan output for `examples/` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
