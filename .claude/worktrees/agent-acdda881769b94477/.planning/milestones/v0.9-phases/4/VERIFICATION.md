---
phase: 04-unified-install-path-dx
verified: 2026-05-21T21:46:00Z
status: verified
score: 3/3 requirements verified
human_verification:
  - Fresh Phoenix host adoption transcript captured on 2026-05-21 in `/Users/jon/parapet_phase8_smoke`
---

# Phase 4: Unified Install Path Verification Report

**Phase Goal:** Prove the shipped Day-1 Parapet install surface honestly: `mix parapet.install` composes the core paved road by default, `mix parapet.doctor` reports severity and cluster posture without overclaiming, and the public docs describe that contract accurately.
**Verified:** 2026-05-21T21:46:00Z
**Status:** verified
**Re-verification:** Yes - this session re-ran the install and doctor proof lanes, fixed fresh-host optional-dependency compile leaks exposed by the smoke lane, and then re-ran the adopter flow successfully.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | `mix parapet.install` remains the single Day-1 entrypoint and composes only the core paved road by default, while leaving UI and delivery integrations explicit opt-ins. | ✓ VERIFIED | `test/mix/tasks/parapet.install_test.exs` passed; the fresh-host transcript printed the installer summary with `Selected extras: none`, `UI not selected`, and `Run mix parapet.doctor next.` |
| 2 | `mix parapet.doctor` exposes severity-aware local checks and keeps the runtime `cluster` mode honest about certainty boundaries instead of implying distributed correctness. | ✓ VERIFIED | `test/mix/tasks/parapet.doctor_test.exs` passed; the fresh-host transcript reported `router: warn`, `endpoint: info`, `cluster_static: skip`, and `cluster_runtime: warn` with explicit "cannot prove distributed correctness" wording. |
| 3 | The README and Operator UI guide match the shipped posture: core install by default, optional UI only on explicit opt-in, and host-owned auth for generated routes. | ✓ VERIFIED | `rg -n 'mix parapet\\.install|mix parapet\\.doctor|--with-ui|--skip-ui|cluster|does \\*\\*not\\*\\* provide its own authentication system' README.md docs/operator-ui.md` hit the expected command and auth-boundary lines in both docs. |

**Score:** 3/3 truths verified

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Installer contract and composition order | `mix test test/mix/tasks/parapet.install_test.exs` | 3 tests, 0 failures | ✓ PASS |
| Doctor severity and runtime cluster posture | `mix test test/mix/tasks/parapet.doctor_test.exs` | 10 tests, 0 failures | ✓ PASS |
| Public doc contract | `rg -n 'mix parapet\.install|mix parapet\.doctor|--with-ui|--skip-ui|cluster|does \*\*not\*\* provide its own authentication system' README.md docs/operator-ui.md` | README and `docs/operator-ui.md` both expose install, doctor, opt-in UI, and host-owned auth wording | ✓ PASS |
| Fresh-host smoke lane, first attempt | `mix phx.new parapet_phase8_smoke --database sqlite3 --no-mailer --install` → add local `:parapet` path dep → `mix deps.get` → `mix parapet.install` | First rerun exposed optional Oban-backed modules that still leaked into no-Oban host compilation; the lane was blocked until those modules and call sites were compile-guarded correctly. | ✓ DEVIATION AUTO-FIXED |
| Fresh-host smoke lane, passing rerun | `mix phx.new parapet_phase8_smoke --database sqlite3 --no-mailer --install` → add local `:parapet` path dep and `:igniter` → `mix deps.get` → `mix parapet.install` → answer `Y` to Igniter's dirty-worktree confirmation | Install completed and printed `Parapet install summary`, generated `config :parapet, repo: ParapetPhase8Smoke.Repo`, `instrumenter: ParapetPhase8Smoke.ParapetInstrumenter`, `lib/parapet_phase8_smoke/parapet_instrumenter.ex`, endpoint wiring, Prometheus rules, a spine migration, and the deploy hook. | ✓ PASS |
| Fresh-host doctor follow-up | `mix parapet.doctor` | `runbooks: skip`, `router: warn`, `operator_ui: info`, `endpoint: info`, `cardinality: skip`, `cluster_static: skip`; warning text stayed explicit that static checks cannot prove distributed correctness without an escalation worker. | ✓ PASS |
| Fresh-host runtime cluster honesty check | `mix parapet.doctor cluster` | `cluster_runtime: warn` with `repo=ParapetPhase8Smoke.Repo, oban_started=false, escalation_policy=nil`; output explicitly says runtime cluster checks still cannot prove distributed correctness in isolation. | ✓ PASS |

### Plan Output Check

| Plan | Summary | Status | Notes |
| --- | --- | --- | --- |
| 04-01 | `.planning/phases/04-unified-install-path-dx/04-01-SUMMARY.md` | ✓ VERIFIED | Summary matches the shipped install command, explicit extras, and trust summary. |
| 04-02 | `.planning/phases/04-unified-install-path-dx/04-02-SUMMARY.md` | ✓ VERIFIED | Summary matches the current doctor threshold and runtime-cluster posture. |
| 04-03 | `.planning/phases/04-unified-install-path-dx/04-03-SUMMARY.md` | ✓ VERIFIED | Summary matches the README and operator UI doc contract that was re-grepped in this session. |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| `DX-01.a` | ✓ SATISFIED | The installer contract test passed, and the fresh-host lane generated the spine migration, instrumenter module, endpoint plug wiring, Prometheus artifacts, and the install summary before handing off to `mix parapet.doctor`. |
| `DX-01.b` | ✓ SATISFIED | The doctor test suite passed, and the fresh-host doctor reruns showed severity-aware `warn/info/skip` output plus explicit runtime `cluster` honesty. |
| `AC-01` | ✓ SATISFIED | The passing fresh-host lane proved the corrected shipped posture: `mix parapet.install` delivered the spine and default Prometheus artifacts in one guided flow, while UI remained explicitly opt-in and absent from the default run. |

### Human Verification Required

The fresh-host adoption transcript remains a human-proof artifact, not a permanent ExUnit merge gate. The recorded lane is:

`mix phx.new parapet_phase8_smoke --database sqlite3 --no-mailer --install`
`mix deps.get`
`mix parapet.install` (confirmed with `Y` when Igniter warned about uncommitted host-app files)
`mix parapet.doctor`
`mix parapet.doctor cluster`

Human review should confirm the generated host-owned files and notices still match the public adoption story:

- `config/config.exs` wires `config :parapet, repo: ParapetPhase8Smoke.Repo, instrumenter: ParapetPhase8Smoke.ParapetInstrumenter`
- `lib/parapet_phase8_smoke/parapet_instrumenter.ex` remains host-owned
- `priv/parapet/prometheus/*.yml` exists after install
- the installer summary keeps UI optional and points to `mix parapet.doctor`

### Gaps Summary

No Phase 4 proof gaps remain for the Day-1 install, doctor, and docs handoff that Parapet owns. This verification intentionally does **not** claim:

- Prometheus or Grafana runtime setup beyond generated artifact creation
- provider-specific delivery/async integrations in a fresh host unless explicitly opted in
- distributed-correctness proof from `mix parapet.doctor cluster`; that command remains an honesty/reporting surface, while Phase 5 is the real multi-node proof surface

---

_Verified: 2026-05-21T21:46:00Z_
_Verifier: Codex_
