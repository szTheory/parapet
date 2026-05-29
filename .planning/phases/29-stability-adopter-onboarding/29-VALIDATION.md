---
phase: 29
slug: stability-adopter-onboarding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-28
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `29-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/mix/tasks/parapet.gen.recovery_test.exs test/mix/tasks/parapet_doctor_test.exs test/mix/tasks/verify_public_api_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15–30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit (Wave 1 — code surfaces):** Run the quick command above (gen.recovery + doctor + verify.public_api targeted tests).
- **After every plan wave:** `mix test && mix docs` (Wave 2 adds the ExDoc/doc-build gate).
- **Before `/gsd:verify-work`:** Full suite green (`mix test`) + `mix docs` clean + `mix verify.public_api` shows `Parapet.Recovery` as Stable.
- **Max feedback latency:** ~30 seconds.

---

## Per-Task Verification Map

> Plan/Wave/Task IDs are assigned by the planner; rows below are requirement-anchored and will be refined to task granularity during planning/execution.

| Item | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Recovery reclassifies to :stable after moduledoc flip | TBD | 1 | STAB-07 | — | N/A | unit | `mix test test/mix/tasks/verify_public_api_test.exs` | ✅ (add case) | ⬜ pending |
| stability.md Stable table contains Recovery row; Experimental does not | TBD | 1 | STAB-07 | — | N/A | grep gate | `grep "Parapet.Recovery" docs/stability.md` | ✅ | ⬜ pending |
| stability.md Deprecation Register has additive-variant note for `confirm_runbook_step/4` | TBD | 1 | STAB-07 | — | N/A | grep gate | `grep -n "short_circuited\|conflicted" docs/stability.md` | ✅ | ⬜ pending |
| gen.recovery scaffolds module with `use Parapet.Recovery` + 4 callbacks | TBD | 1 | ADOP-01 | — | N/A | unit (Igniter.Test) | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | ❌ W0 | ⬜ pending |
| gen.recovery scaffolds test stub | TBD | 1 | ADOP-01 | — | N/A | unit (Igniter.Test) | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | ❌ W0 | ⬜ pending |
| gen.recovery missing NAME arg raises ArgumentError | TBD | 1 | ADOP-01 | — | N/A | unit | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | ❌ W0 | ⬜ pending |
| gen.recovery `on_exists: :skip` does not overwrite | TBD | 1 | ADOP-01 | — | N/A | unit (Igniter.Test) | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | ❌ W0 | ⬜ pending |
| check_recovery zero capabilities → :skip/:info; `--ci` exits 0 | TBD | 1 | ADOP-02 | — | fresh install passes CI error gate | unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | ✅ (add case) | ⬜ pending |
| check_recovery N registered + healthy → :ok with count | TBD | 1 | ADOP-02 | — | N/A | unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | ✅ (add case) | ⬜ pending |
| check_recovery unregistered-capability-in-runbook → :warn | TBD | 1 | ADOP-02 | — | N/A | unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | ✅ (add case) | ⬜ pending |
| check_recovery URL runbook → SKIP (no error/warn) | TBD | 1 | ADOP-02 | — | tolerate non-module runbook string | unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | ✅ (add case) | ⬜ pending |
| check_recovery host module missing / missing callback → :warn | TBD | 1 | ADOP-02 | — | `Code.ensure_loaded?` tolerates absence | unit | `mix test test/mix/tasks/parapet_doctor_test.exs` | ✅ (add case) | ⬜ pending |
| recovery-actions.md builds in ExDoc; rendered in doc/ | TBD | 2 | ADOP-03 | — | N/A | integration (doc build) | `mix docs && ls doc/recovery-actions.html` | ✅ | ⬜ pending |
| recovery-actions.md in `extras` AND `groups_for_extras` Guides | TBD | 2 | ADOP-03 | — | N/A | config grep | `grep "recovery-actions" mix.exs` | ✅ | ⬜ pending |
| cross-links present in getting-started.md + operator-ui.md | TBD | 2 | ADOP-03 | — | N/A | grep gate | `grep "recovery-actions" docs/getting-started.md docs/operator-ui.md` | ✅ | ⬜ pending |
| no undefined/broken reference warnings in `mix docs` | TBD | 2 | ADOP-03 | — | N/A | integration | `mix docs 2>&1 \| grep -i "undefined\|broken"` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/parapet.gen.recovery_test.exs` — NEW file; `Igniter.Test` assertions for ADOP-01 (mirror `test/mix/tasks/parapet.gen.runbooks_test.exs`).
- [ ] `test/mix/tasks/parapet_doctor_test.exs` — NEW cases for ADOP-02 `check_recovery` (six signal conditions in the map above). File exists; add cases.
- [ ] `test/mix/tasks/verify_public_api_test.exs` — NEW case for STAB-07 Stable reclassification. File exists; add case.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| ExDoc Guides sidebar renders "Recovery Actions" entry | ADOP-03 | Visual HexDocs sidebar render not asserted by build exit code | After `mix docs`, open `doc/recovery-actions.html` and confirm it appears under the Guides group in the sidebar |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (3 test files above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
