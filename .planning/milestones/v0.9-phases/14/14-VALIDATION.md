---
phase: 14
slug: backstop-generated-operator-ui-closure-proof
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for generated operator UI closure-proof backstop reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + shell assertions + `python3` |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` |
| **Full suite command** | run the targeted `mix test` lane, then the `test -f`, `rg`, and `python3` cross-surface checks from this file |
| **Estimated runtime** | < 20 seconds |

---

## Canonical Verification Artifact

- Phase 14 does not create a competing runtime proof artifact.
- `.planning/v0.9-phases/3/VERIFICATION.md` remains the canonical runtime proof owner for generated operator UI behavior per D-01 and D-02.
- `.planning/v0.9-phases/7/VERIFICATION.md` and `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md` remain closure/index layers only per D-03 and D-14.
- This validation contract proves that the `generated resolve-flow proof lane` is named consistently, rerunnable through the existing targeted ExUnit lane, and promoted coherently across the active Phase 3, Phase 7, and Phase 12 surfaces.

---

## Sampling Rate

- **After every task commit in 14-01:** rerun `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs`.
- **Before closing 14-01:** run the Phase 3/7/12 `python3` coherence check and the `rg` proof-link checks for the named lane.
- **Before closing 14-02:** rerun the `rg` checks for `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md`.
- **Before `$gsd-verify-work`:** all targeted test, file-existence, and cross-surface coherence checks must pass.
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | milestone closure readiness | T-14-01 / T-14-04 | Phase 3 remains the canonical proof owner, and the named generated resolve-flow proof lane still passes in the existing targeted runtime plus source-contract test lane | integration | `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | ✅ | ⬜ pending |
| 14-01-02 | 01 | 1 | milestone closure readiness | T-14-02 / T-14-03 | Phase 7 and Phase 12 index the named Phase 3 lane without duplicating runtime proof or implying a fresh audit pass | cross-file assertion | `python3` coherence check across `.planning/v0.9-phases/3/{VERIFICATION.md,03-VALIDATION.md}`, `.planning/v0.9-phases/7/{VERIFICATION.md,07-VALIDATION.md}`, and `.planning/phases/12-backfill-closure-phase-verification-surfaces/{12-VERIFICATION.md,12-VALIDATION.md}` | ✅ | ⬜ pending |
| 14-02-01 | 02 | 2 | milestone closure readiness | T-14-05 / T-14-06 | `ROADMAP.md` and `REQUIREMENTS.md` promote current proof truth while keeping the historical audit explicitly separate | doc reconciliation | `rg -n 'SCALE-01\\.c|AC-03|milestone closure readiness|14-01-PLAN\\.md|14-02-PLAN\\.md|v0\\.9-phases/3/VERIFICATION\\.md|v0\\.9-phases/7/VERIFICATION\\.md|12-VERIFICATION\\.md|fresh .*audit rerun|historical.*audit|separate work' .planning/REQUIREMENTS.md .planning/ROADMAP.md` | ✅ | ⬜ pending |
| 14-02-02 | 02 | 2 | milestone closure readiness | T-14-07 | `STATE.md` matches the landed Phase 14 closure-proof posture and preserves chronology honesty | state assertion | `rg -n 'Phase: 14|Plan: 2 of 2 complete|Status: Execution complete|Phase 14 execution completed|completed_phases: 5|completed_plans: 13|percent: 100|fresh milestone audit rerun remains separate work|closure-proof backstop' .planning/STATE.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] Existing targeted proof lane already exists in `test/parapet/generated_operator_live_paging_test.exs`, `test/parapet/operator_ui_integration_test.exs`, and `test/mix/tasks/parapet.gen.ui_test.exs`.
- [x] Existing proof surfaces already exist for Phase 3, Phase 7, and Phase 12; this phase only reconciles and cross-checks them.
- [x] No new harness, browser runner, or runtime fixture is required.

---

## Cross-Surface Coherence Check

Run this before closing Plan 14-01 and again before final phase verification:

```bash
python3 - <<'PY'
from pathlib import Path

phase3_v = Path(".planning/v0.9-phases/3/VERIFICATION.md").read_text()
phase3_val = Path(".planning/v0.9-phases/3/03-VALIDATION.md").read_text()
phase7_v = Path(".planning/v0.9-phases/7/VERIFICATION.md").read_text()
phase7_val = Path(".planning/v0.9-phases/7/07-VALIDATION.md").read_text()
phase12_v = Path(".planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md").read_text()
phase12_val = Path(".planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md").read_text()

for text in (phase3_v, phase3_val, phase7_v, phase7_val, phase12_v, phase12_val):
    lowered = text.lower()
    assert "generated resolve-flow proof lane" in text
    assert "audit passed" not in lowered
    assert "milestone passed" not in lowered

assert "test/parapet/generated_operator_live_paging_test.exs" in phase3_v
assert "test/parapet/operator_ui_integration_test.exs" in phase3_v
assert "test/mix/tasks/parapet.gen.ui_test.exs" in phase3_v
assert ".planning/v0.9-phases/3/VERIFICATION.md" in phase7_v
assert ".planning/v0.9-phases/3/03-VALIDATION.md" in phase7_v
assert ".planning/v0.9-phases/7/VERIFICATION.md" in phase12_v
assert ".planning/v0.9-phases/3/VERIFICATION.md" in phase12_v

print("Phase 14 Phase 3/7/12 coherence check passed.")
PY
```

Required follow-up assertions:

```bash
test -f .planning/v0.9-phases/3/VERIFICATION.md \
  .planning/v0.9-phases/3/03-VALIDATION.md \
  .planning/v0.9-phases/7/VERIFICATION.md \
  .planning/v0.9-phases/7/07-VALIDATION.md \
  .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md \
  .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md

rg -n 'generated resolve-flow proof lane|resolve_incident|resolved history|fresh milestone audit rerun remains separate work|milestone audit rerun remains separate work' \
  .planning/v0.9-phases/3/VERIFICATION.md \
  .planning/v0.9-phases/3/03-VALIDATION.md \
  .planning/v0.9-phases/7/VERIFICATION.md \
  .planning/v0.9-phases/7/07-VALIDATION.md \
  .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md \
  .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md
```

---

## Manual-Only Verifications

None. This phase is intentionally bounded to rerunnable targeted tests and artifact-truth reconciliation.

---

## Source Coverage Audit

| Source Type | Item | Coverage |
|-------------|------|----------|
| GOAL | Extend the closure-proof chain so future milestone reruns catch generated operator UI runtime regressions | Covered by 14-01 Task 1 naming the canonical Phase 3 lane and 14-01 Task 2 promoting it through Phase 7 and Phase 12 |
| REQ | `milestone closure readiness` | Covered by both plans; 14-01 closes proof-chain coverage and 14-02 promotes live tracker truth |
| RESEARCH | Keep the existing two-layer backstop, no new browser harness, no new runtime scope | Covered by 14-01 Task 1 and Task 2 using only the existing `mix test`, `rg`, `test -f`, and `python3` paths |
| CONTEXT D-01 | Phase 3 is canonical runtime proof owner | Covered by 14-01 Task 1 |
| CONTEXT D-02 | Strengthen existing Phase 3 lane and promote upward | Covered by 14-01 Task 1 and Task 2 |
| CONTEXT D-03 | Closure phases index, do not duplicate runtime proof | Covered by 14-01 Task 2 |
| CONTEXT D-04 | `Parapet.Operator` remains the canonical mutation seam | Covered by 14-01 Task 1 proof wording over existing tests |
| CONTEXT D-05 | Generated UI remains thin host-owned wiring | Covered by 14-01 Task 1 and no runtime widening |
| CONTEXT D-06 | Generator/source-contract coverage is part of proof | Covered by 14-01 Task 1 targeted lane |
| CONTEXT D-07 | Two-layer backstop: source contract plus narrow runtime lifecycle | Covered by 14-01 Task 1 |
| CONTEXT D-08 | No new browser E2E harness | Covered by validation commands and 14-01 Task 1 |
| CONTEXT D-09 | Backstop must be clearly named and discoverable | Covered by 14-01 Task 1 and Task 2 |
| CONTEXT D-10 | Reconcile active truth surfaces after fresh canonical proof | Covered by 14-02 Task 1 and Task 2 |
| CONTEXT D-11 | `SCALE-01.c` and `AC-03` move out of pending in live trackers | Covered by 14-02 Task 1 |
| CONTEXT D-12 | `milestone closure readiness` remains pending until Phase 14 lands | Covered by sequencing: 14-02 depends on 14-01 |
| CONTEXT D-13 | Historical artifacts remain historical | Covered by both plans and all tracker checks |
| CONTEXT D-14 | Phase 12 active closure surfaces must be reconciled | Covered by 14-01 Task 2 |
| CONTEXT D-15 | Auto-decide low-impact reconciliation choices | Reflected in plan posture; no checkpoint tasks |
| CONTEXT D-16 | `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` tell current truth | Covered by 14-02 Task 1 and Task 2 |
| CONTEXT D-17 | `docs/operator-ui.md` changes only if wording alignment is needed | Covered by 14-01 Task 1 |
| DEFERRED | Resolved-history public seam cleanup, broader proof expansion, fresh milestone audit rerun | Explicitly excluded from both plans |

Result: all in-scope GOAL, REQ, RESEARCH, and CONTEXT items are covered; no deferred idea appears in the plan set.

---

## Validation Sign-Off

- [x] All tasks have an automated verification path
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all required proof infrastructure
- [x] No watch-mode flags
- [x] Validation uses only existing `mix test`, `rg`, `test -f`, and `python3` checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution
