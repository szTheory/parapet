---
phase: 09
slug: reconcile-milestone-closure-artifacts
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-22
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for reconciliation and documentation-only execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell assertions + `python3` |
| **Config file** | n/a |
| **Quick run command** | `python3` / `rg` checks against planning artifacts |
| **Full suite command** | Run the per-plan verification commands in `09-01-PLAN.md` through `09-04-PLAN.md` |
| **Estimated runtime** | < 10 seconds |

---

## Canonical Proof Inputs

- `.planning/v0.9-phases/1/VERIFICATION.md`
- `.planning/v0.9-phases/3/VERIFICATION.md`
- `.planning/v0.9-phases/4/VERIFICATION.md`
- `.planning/v0.9-phases/5/VERIFICATION.md`

These remain the closure-grade proof artifacts for milestone reconciliation. Phase 9 validation checks only that active truth surfaces, the stale Phase 5 validation map, the historical audit bridge, and the repo-root doctrine surface stay aligned to those proofs.

---

## Sampling Rate

- **After every task commit:** run the task’s `<automated>` verification block.
- **After every plan wave:** rerun the full set of file-assertion commands for that plan.
- **Before `$gsd-verify-work`:** confirm all four plan outputs are present and the live truth surfaces agree on the same verified/reconciled/re-audit-ready posture.
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | milestone closure readiness | T-09-01 / T-09-02 | Phase 5 validation reflects covered proof and points to canonical verification | file assertion | `python3` check from `09-01-PLAN.md` task 1 | ✅ | ⬜ pending |
| 09-01-02 | 01 | 1 | milestone closure readiness | T-09-02 | Phase 5 validation carries an explicit post-verification note without becoming the proof artifact | file assertion | `rg -n "reconciled post-verification|validation.*not the closure-grade proof|VERIFICATION.md" .planning/v0.9-phases/5/05-VALIDATION.md` | ✅ | ⬜ pending |
| 09-02-01 | 02 | 2 | milestone closure readiness | T-09-04 / T-09-05 / T-09-06 | `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` tell the same current-state story | cross-file assertion | combined `python3` coherence check from `09-02-PLAN.md` | ✅ | ⬜ pending |
| 09-02-02 | 02 | 2 | milestone closure readiness | T-09-04 / T-09-05 | Requirement checklist truth and traceability rows stay aligned to existing proof only | file assertion | `python3` check from `09-02-PLAN.md` task 2 | ✅ | ⬜ pending |
| 09-02-03 | 02 | 2 | milestone closure readiness | T-09-05 / T-09-06 | Project state moves to the same re-audit-ready posture without claiming milestone pass | file assertion | `python3` check from `09-02-PLAN.md` task 3 | ✅ | ⬜ pending |
| 09-03-01 | 03 | 3 | milestone closure readiness | T-09-07 / T-09-08 / T-09-09 | Historical audit remains intact while gaining a narrow readiness bridge | file assertion | strengthened `python3` preservation check from `09-03-PLAN.md` | ✅ | ⬜ pending |
| 09-03-02 | 03 | 3 | milestone closure readiness | T-09-08 / T-09-09 | Audit bridge points to later proof and ends with the explicit rerun command | file assertion | `rg -n "re-audit|\\$gsd-audit-milestone|05-VALIDATION.md|VERIFICATION.md" .planning/v0.9-MILESTONE-AUDIT.md` | ✅ | ⬜ pending |
| 09-04-01 | 04 | 4 | milestone closure readiness | T-09-10 / T-09-11 | Repo-root doctrine is centralized in `AGENTS.md` without changing product or workflow scope | doc assertion | `rg -n "recommendation-first|assumptions|escalate only|public CLI/API contract|durable evidence truth model" AGENTS.md` | ✅ | ⬜ pending |
| 09-04-02 | 04 | 4 | milestone closure readiness | T-09-10 / T-09-11 | Repo-root doctrine remains bounded to the locked planning posture and escalation rules only | doc assertion | `rg -n "recommendation-first|assumptions|escalate only|public CLI/API contract|default install contents|runtime behavior|durable evidence truth model|two medium-impact concerns" AGENTS.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] Existing canonical proof artifacts for Phases 1, 3, 4, and 5 are present.
- [x] Phase 9 plan files exist for validation reconciliation, live truth sync, historical audit bridging, and repo-root doctrine centralization.
- [x] This phase uses file assertions only; no runtime or dependency harness is required.

---

## Manual-Only Verifications

None. This phase is artifact reconciliation and documentation-only planning work.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification commands
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all phase outputs
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned
