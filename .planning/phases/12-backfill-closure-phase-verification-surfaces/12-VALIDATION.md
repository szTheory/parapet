---
phase: 12
slug: backfill-closure-phase-verification-surfaces
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for documentation-proof backfill execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell assertions + `python3` |
| **Config file** | n/a |
| **Quick run command** | `test -f` and `rg` checks against `.planning/v0.9-phases/{6,7,8,9}/VERIFICATION.md` |
| **Full suite command** | run all per-plan verification commands plus one `python3` cross-file consistency check |
| **Estimated runtime** | < 10 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task's file-existence and `rg` proof-link assertions.
- **After every plan wave:** Run the full cross-file assertion set.
- **Before `$gsd-verify-work`:** All four new verification files must exist and all cross-link assertions must pass.
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | milestone closure readiness | T-12-01 | Phase 6 gains a canonical verification report that indexes the underlying Phase 1 proof and Phase 6 reconciliation surfaces | file assertion | `test -f .planning/v0.9-phases/6/VERIFICATION.md && rg -n "Phase 1:|06-VALIDATION|REQUIREMENTS.md|01-VERIFICATION|VERIFICATION.md" .planning/v0.9-phases/6/VERIFICATION.md` | ✅ | ⬜ pending |
| 12-02-01 | 02 | 1 | milestone closure readiness | T-12-02 | Phase 7 gains a canonical verification report that indexes the underlying Phase 3 proof and Phase 7 reconciliation surfaces | file assertion | `test -f .planning/v0.9-phases/7/VERIFICATION.md && rg -n "Phase 3:|07-VALIDATION|ROADMAP.md|REQUIREMENTS.md|VERIFICATION.md" .planning/v0.9-phases/7/VERIFICATION.md` | ✅ | ⬜ pending |
| 12-03-01 | 03 | 1 | milestone closure readiness | T-12-03 | Phase 8 gains a canonical verification report that indexes the underlying Phase 4 proof and preserves the fresh-host/manual boundary honestly | file assertion | `test -f .planning/v0.9-phases/8/VERIFICATION.md && rg -n "Phase 4:|08-VALIDATION|ROADMAP.md|REQUIREMENTS.md|fresh-host|VERIFICATION.md" .planning/v0.9-phases/8/VERIFICATION.md` | ✅ | ⬜ pending |
| 12-04-01 | 04 | 2 | milestone closure readiness | T-12-04 | Phase 9 gains a canonical verification report that indexes the reconciled tracker, audit-bridge, and doctrine surfaces without implying a new audit pass | file assertion | `test -f .planning/v0.9-phases/9/VERIFICATION.md && rg -n "05-VALIDATION|ROADMAP.md|REQUIREMENTS.md|STATE.md|v0.9-MILESTONE-AUDIT.md|AGENTS.md" .planning/v0.9-phases/9/VERIFICATION.md` | ✅ | ⬜ pending |
| 12-04-02 | 04 | 2 | milestone closure readiness | T-12-05 | All four new verification files exist and each uses the canonical verified report posture | cross-file assertion | `python3` consistency check across `.planning/v0.9-phases/{6,7,8,9}/VERIFICATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Phase 12 wording stays honest about "verification backfill" versus "milestone audit passed" | milestone closure readiness | This is a proof-honesty judgment, not just a grep | Read all four new `VERIFICATION.md` files together with `.planning/v0.9-MILESTONE-AUDIT.md` and confirm they claim only the missing phase-local verification surfaces were backfilled, not that a fresh audit already passed. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing infrastructure
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned
