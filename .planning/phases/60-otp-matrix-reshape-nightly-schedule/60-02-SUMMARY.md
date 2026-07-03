---
phase: 60-otp-matrix-reshape-nightly-schedule
plan: "02"
subsystem: infra
tags: [ci, github-actions, otp, elixir, release-please, contributing, tech-debt]

requires:
  - phase: 60-01
    provides: ci.yml reshaped with matrix-config resolver, schedule trigger, Elixir 1.20.2 / OTP {27,28,29}

provides:
  - release-please.yml publish-hex toolchain bumped to Elixir 1.20.2 / OTP 28.x (SHA pin unchanged)
  - README factual CI sentence corrected to name 1.20.2 / OTP 27, 28, 29
  - CONTRIBUTING 4th Local-vs-CI-deltas bullet explaining PR-trimmed vs main+nightly full gate
  - PROJECT.md canonical D-11 resolution row (single-sourced, dated 2026-07-02)
  - v1.7-MILESTONE-AUDIT.md register row 3 dated one-line pointer
  - MILESTONES.md D-11 row dated one-line pointer

affects: [future-CI-phases, milestone-audit-readers, adopters-reading-README]

tech-stack:
  added: []
  patterns:
    - "Single-sourced dated D-11 retirement: canonical rationale in PROJECT.md Key Decisions; all other spots carry one-line pointer only (anti-drift)"
    - "Append-only frozen-audit edits: register rows get dated suffix; frozen frontmatter and prose bodies are byte-for-byte untouched"

key-files:
  created: []
  modified:
    - .github/workflows/release-please.yml
    - README.md
    - CONTRIBUTING.md
    - .planning/PROJECT.md
    - .planning/milestones/v1.7-MILESTONE-AUDIT.md
    - .planning/MILESTONES.md

key-decisions:
  - "D-06a: publish-hex toolchain bumped to 1.20.2/28.x so published Hex artifact is built on a toolchain CI actually tests; setup-beam SHA fc68ffb9 left unchanged"
  - "D-06b: README CI sentence corrected to name Elixir 1.20.2/OTP 27,28,29+nightly note; adopter support matrix (1.19+/OTP 26-28) left untouched"
  - "D-05b: CONTRIBUTING (d) bullet added explaining PR trimmed cell vs main+nightly full matrix + release_gate gate"
  - "D-04b: PROJECT.md is the single canonical explanation for D-11 retirement; every other location carries a one-line dated pointer, not re-derived rationale"
  - "D-04c/e: frozen v1.7 audit body (frontmatter line ~1-10, Seam-7 prose ~line 132) not touched; STATE.md line 115 unrelated @concurrency_hold_ms D-11 not touched"

patterns-established:
  - "Single-source dated retirement pattern: one canonical explanation row in PROJECT.md Key Decisions + one-line pointers everywhere else — prevents rationale drift across docs"

requirements-completed: [MATRIX-02, MATRIX-03]

coverage:
  - id: D1
    description: "release-please.yml publish-hex job uses Elixir 1.20.2 / OTP 28.x; setup-beam SHA fc68ffb9 unchanged"
    requirement: MATRIX-03
    verification:
      - kind: other
        ref: "grep -c '1\\.19\\.0' .github/workflows/release-please.yml == 0; grep -Fq 'fc68ffb9' .github/workflows/release-please.yml"
        status: pass
    human_judgment: false
  - id: D2
    description: "README factual CI sentence names Elixir 1.20.2 across OTP 27, 28, 29; adopter support matrix row intact"
    requirement: MATRIX-03
    verification:
      - kind: other
        ref: "grep -c 'Elixir 1.19 across OTP 26, 27, and 28' README.md == 0; grep -q '| Elixir    | 1.19+     |' README.md"
        status: pass
    human_judgment: false
  - id: D3
    description: "CONTRIBUTING.md Local-vs-CI-deltas list has a (d) bullet explaining PR trimmed cell and release_gate as the real multi-OTP gate"
    requirement: MATRIX-03
    verification:
      - kind: other
        ref: "grep -Eiq 'release_gate.*(main|multi-OTP)|trimmed cell' CONTRIBUTING.md"
        status: pass
    human_judgment: false
  - id: D4
    description: "PROJECT.md Key Decisions contains exactly one canonical D-11 resolution row (RESOLVED 2026-07-02/Phase60/MATRIX-02); v1.7-debt Revisit row resolved to Good"
    requirement: MATRIX-02
    verification:
      - kind: other
        ref: "grep -c 'RESOLVED 2026-07-02 (Phase 60 / MATRIX-02)' .planning/PROJECT.md == 1"
        status: pass
    human_judgment: false
  - id: D5
    description: "v1.7-MILESTONE-AUDIT.md register row 3 carries dated pointer; frozen frontmatter and Seam-7 prose untouched"
    requirement: MATRIX-02
    verification:
      - kind: other
        ref: "grep -Fq 'RESOLVED 2026-07-02 (Phase 60)' .planning/milestones/v1.7-MILESTONE-AUDIT.md"
        status: pass
    human_judgment: false
  - id: D6
    description: "MILESTONES.md D-11 row carries dated pointer; STATE.md line 115 @concurrency_hold_ms D-11 untouched"
    requirement: MATRIX-02
    verification:
      - kind: other
        ref: "grep -Fq 'RESOLVED 2026-07-02 (Phase 60)' .planning/MILESTONES.md"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-07-02
status: complete
---

# Phase 60 Plan 02: OTP Matrix Reshape — Toolchain + Doc Edits Summary

**Bumped publish-hex to Elixir 1.20.2/OTP 28.x, corrected README CI sentence, added CONTRIBUTING PR-vs-main gate bullet, and retired v1.7 D-11 CI-coverage flag single-sourced in PROJECT.md with dated one-line pointers in the audit register and MILESTONES.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-07-02T00:00:00Z
- **Completed:** 2026-07-02
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- `release-please.yml` publish-hex job now builds on Elixir 1.20.2 / OTP 28.x — matching the toolchain CI tests; setup-beam SHA `fc68ffb9` untouched (D-06a)
- README factual "CI validates..." sentence corrected to Elixir 1.20.2 / OTP 27, 28, 29 on main+nightly with trimmed PR note; adopter support matrix (1.19+, OTP 26–28) left intact (D-06b)
- CONTRIBUTING "Local vs CI deltas" list gains a 4th `(d)` bullet explaining PR trimmed cell (OTP 28 × `parapet`) vs main+nightly full matrix, and names `release_gate` as the real multi-OTP gate (D-05b)
- D-11 CI-coverage prune formally retired: canonical explanation row added to PROJECT.md Key Decisions (single-sourced, dated 2026-07-02/Phase60/MATRIX-02); existing v1.7-debt `⚠️ Revisit` row resolved to `✓ Good` (D-04b)
- Dated one-line pointer appended to v1.7-MILESTONE-AUDIT.md register row 3 and MILESTONES.md D-11 row — frozen frontmatter, Seam-7 prose, and the unrelated STATE.md `@concurrency_hold_ms` D-11 are byte-for-byte untouched (D-04c/e)

## Task Commits

1. **Task 1: Bump release-please publish-hex toolchain, fix README CI sentence, add CONTRIBUTING delta bullet** — `e572ddd` (chore)
2. **Task 2: Retire the D-11 CI-coverage flag — canonical PROJECT.md row + dated one-line pointers** — `77e0bbf` (docs)

## Files Created/Modified

- `.github/workflows/release-please.yml` — publish-hex setup-beam: elixir 1.19.0→1.20.2, otp 27.2→28.x; SHA unchanged
- `README.md` — factual CI sentence updated to Elixir 1.20.2 / OTP 27, 28, 29 + nightly note
- `CONTRIBUTING.md` — (d) bullet added to "Local vs CI deltas" list
- `.planning/PROJECT.md` — new canonical D-11 resolution row; v1.7-debt Revisit row resolved to Good
- `.planning/milestones/v1.7-MILESTONE-AUDIT.md` — register row 3 appended with dated pointer
- `.planning/MILESTONES.md` — D-11 tech-debt row appended with dated pointer

## Decisions Made

- Used single-source pattern for D-11 retirement: PROJECT.md Key Decisions is the one place with the full rationale; all other locations (AUDIT register, MILESTONES) carry only a one-line dated pointer referencing PROJECT.md — prevents rationale from diverging across doc surfaces.
- Left CONTRIBUTING's `Elixir 1.19+` floor claim and README's adopter support matrix table untouched — those are support claims, not CI-pin facts.

## Deviations from Plan

None — plan executed exactly as written. All anti-drift constraints honored (setup-beam SHA unchanged, frozen audit body untouched, STATE.md D-11 at line 115 untouched, v1.6 Revisit row untouched).

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Phase 60 plans 01 and 02 are both complete. The full phase-60 delivery is done:
- CI matrix reshaped (60-01): matrix-config resolver, schedule trigger, Elixir 1.20.2/OTP {27,28,29}, PR-trimmed, hardened release_gate
- Adjacent toolchain + doc edits (60-02): publish-hex bumped, README/CONTRIBUTING corrected, D-11 retired single-sourced

Requirements MATRIX-01 through MATRIX-04 are satisfied. Phase 60 is ready for closeout.

---

## Self-Check

**Files exist:**
- `.github/workflows/release-please.yml` — FOUND (modified)
- `README.md` — FOUND (modified)
- `CONTRIBUTING.md` — FOUND (modified)
- `.planning/PROJECT.md` — FOUND (modified)
- `.planning/milestones/v1.7-MILESTONE-AUDIT.md` — FOUND (modified)
- `.planning/MILESTONES.md` — FOUND (modified)

**Commits exist:**
- `e572ddd` — Task 1 chore(60-02) — FOUND
- `77e0bbf` — Task 2 docs(60-02) — FOUND

## Self-Check: PASSED

---
*Phase: 60-otp-matrix-reshape-nightly-schedule*
*Completed: 2026-07-02*
