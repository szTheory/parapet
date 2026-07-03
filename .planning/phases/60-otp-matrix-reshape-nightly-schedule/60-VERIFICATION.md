---
phase: 60-otp-matrix-reshape-nightly-schedule
verified: 2026-07-03T00:00:00Z
status: passed
score: 11/11 must-haves verified
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "A nightly schedule trigger cron '17 3 * * *' exists — ROADMAP SC-4 shows illustrative '0 3 * * *'"
    reason: "D-03a explicitly locks '17 3 * * *' as the house :17 convention (matches verify-published-release.yml). CONTEXT.md documents this as an intentional refinement of the roadmap's illustrative value. Verifier accepts per D-03a."
    accepted_by: "gsd-verifier (D-03a documented)"
    accepted_at: "2026-07-03T00:00:00Z"
---

# Phase 60: OTP Matrix Reshape & Nightly Schedule — Verification Report

**Phase Goal:** Pull requests get fast single-cell feedback, pushes to `main` and a nightly cron get full multi-OTP coverage across both schema-prefix legs, and EOL OTP 26 / Elixir 1.19 are retired from CI — with D-11 tech-debt flag formally closed.
**Verified:** 2026-07-03T00:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## SC / Requirement Mapping

| SC | Requirement | Description |
|----|-------------|-------------|
| SC-1 | MATRIX-01 | PR run = 1 trimmed cell (OTP 28 · Elixir 1.20.2 · parapet) |
| SC-2 | MATRIX-02 | push/schedule = 4 full cells; OTP 26 + Elixir 1.19 retired |
| SC-3 | MATRIX-03 | demo skipped on PRs, plain OTP-28 job; toolchain docs aligned |
| SC-4 | MATRIX-04 | Nightly cron; release_gate hardened; D-11 flag retired |

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PR CI run resolves to exactly 1 test cell: OTP 28.x, Elixir 1.20.2, schema_prefix parapet (SC-1, MATRIX-01) | ✓ VERIFIED | `matrix-config` resolver PR branch: `{"include":[{"elixir":"1.20.2","otp":"28.x","schema_prefix":"parapet"}]}` — 1 cell, all 3 keys present |
| 2 | push/schedule resolves to exactly 4 cells: OTP {27,28,29}×parapet + OTP 28×public, all Elixir 1.20.2 (SC-2, MATRIX-02) | ✓ VERIFIED | else branch emits 4-object JSON: 27x/parapet, 28x/parapet, 29x/parapet, 28x/public — all with elixir:1.20.2 |
| 3 | Every include object carries all three keys: elixir, otp, schema_prefix (D-02d — blank-interp false-green guard) | ✓ VERIFIED | python3 JSON parse confirms all 5 objects (1 PR + 4 push) carry all 3 keys |
| 4 | matrix-config JSON is emitted single-line to $GITHUB_OUTPUT (D-02a) | ✓ VERIFIED | Both echo lines are single physical lines; `grep "test-matrix=" ci.yml \| wc -l` = 2 (one per branch) |
| 5 | test _build cache key retains ${{ matrix.schema_prefix }}; mix compile --force retained (D-02c invariant) | ✓ VERIFIED | `grep -c 'matrix.schema_prefix' ci.yml` = 3; `grep -c 'mix compile --force' ci.yml` = 1 |
| 6 | OTP 26 and Elixir 1.19 absent from all test/demo/lint-once pins and cache keys (SC-2, MATRIX-02) | ✓ VERIFIED | `grep -c '1\.19\.0' ci.yml` = 0; `grep -c "'26\.x'" ci.yml` = 0; lint-once pin reads elixir-version: '1.20.2' / otp-version: '28.x' |
| 7 | demo job is skipped on pull_request, runs on push+schedule, is a plain job (no strategy/matrix) on Elixir 1.20.2 / OTP 28.x (D-03b, SC-3, MATRIX-03) | ✓ VERIFIED | `if: github.event_name != 'pull_request'` present; no `strategy:` in demo; setup-beam uses literal '1.20.2'/'28.x'; demo cache keys contain no `${{ matrix.* }}` |
| 8 | Nightly schedule trigger cron '17 3 * * *' exists (D-03a, SC-4, MATRIX-04) | ✓ VERIFIED (override) | `cron: '17 3 * * *'` present; count=1. ROADMAP SC-4 shows illustrative '0 3' — D-03a locks '17 3' as house :17 convention; accepted per override |
| 9 | release_gate keeps if: always(); blocks skipped/failure/cancelled for lint-once and test; passes demo on success|skipped, blocks cancelled demo (D-03c, MATRIX-04) | ✓ VERIFIED | `if: always()` present; `if [ "$LINT_RESULT" != "success" ]` and `if [ "$TEST_RESULT" != "success" ]` — strict allowlist; `case "$DEMO_RESULT" in success\|skipped) : ;; *) FAILED=1 ;;` — blocks cancelled |
| 10 | concurrency.group includes github.event_name; cancel-in-progress stays PR-only (D-03d) | ✓ VERIFIED | group: `${{ github.workflow }}-${{ github.event_name }}-${{ github.event.pull_request.number \|\| github.ref }}`; `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` |
| 11 | Job names lint-once and release_gate are verbatim unchanged; lint-once has no if: (D-03e) | ✓ VERIFIED | `grep -c '^  lint-once:'` = 1; `grep -c '^  release_gate:'` = 1; lint-once block contains no `if:` key |

**Score: 11/11 truths verified (1 accepted override — SC-4 cron '17 3' vs illustrative '0 3' in ROADMAP)**

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/ci.yml` | matrix-config resolver, schedule trigger, plain demo, hardened release_gate | ✓ VERIFIED | All structural changes present; YAML valid (python3 safe_load exits 0) |
| `.github/workflows/release-please.yml` | publish-hex on Elixir 1.20.2 / OTP 28.x; SHA fc68ffb9 unchanged | ✓ VERIFIED | elixir-version: '1.20.2', otp-version: '28.x'; SHA `fc68ffb9` present |
| `README.md` | Factual CI sentence updated; adopter support matrix (1.19+, OTP 26–28) untouched | ✓ VERIFIED | CI sentence: "CI validates on Elixir 1.20.2 across OTP 27, 28, and 29"; support row `\| Elixir    \| 1.19+     \|` intact; `\| OTP       \| 26–28     \|` intact |
| `CONTRIBUTING.md` | 4th (d) Local-vs-CI-deltas bullet present; Elixir 1.19+ floor untouched | ✓ VERIFIED | `(d) **PR vs main multi-OTP breadth**` bullet at line 25; `Elixir 1.19+` at line 79 untouched |
| `.planning/PROJECT.md` | Single canonical D-11 resolution row; v1.7-debt Revisit resolved | ✓ VERIFIED | Row "Retire v1.7 D-11 CI-coverage prune (v1.8)" with `RESOLVED 2026-07-02 (Phase 60 / MATRIX-02): retired by design, not by fix.` — Outcome `✓ Good`; v1.7-debt row updated to reference it |
| `.planning/milestones/v1.7-MILESTONE-AUDIT.md` | Register row 3 dated pointer; frozen body untouched | ✓ VERIFIED | Row 3: `— RESOLVED 2026-07-02 (Phase 60); see PROJECT.md Key Decisions`; frozen frontmatter (~line 1-10) and Seam-7 prose (~line 132) intact |
| `.planning/MILESTONES.md` | Dated D-11 pointer at row 31 | ✓ VERIFIED | `— RESOLVED 2026-07-02 (Phase 60); see PROJECT.md Key Decisions` appended |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `matrix-config` outputs.test-matrix | `test` strategy.matrix | `fromJson(needs.matrix-config.outputs.test-matrix)` | ✓ WIRED | `test.needs: [matrix-config]`; `matrix: ${{ fromJson(needs.matrix-config.outputs.test-matrix) }}` present |
| test `_build` cache key | `${{ matrix.schema_prefix }}` | cache key interpolation | ✓ WIRED | Key: `${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-${{ hashFiles(...) }}` |
| `release_gate.needs` | `[lint-once, matrix-config, test, demo]` | job-level needs array | ✓ WIRED | `needs: [lint-once, matrix-config, test, demo]` exact match |

---

### Behavioral Spot-Checks

Step 7b: No server/runner available at verify time. All behavioral checks are static analysis of workflow YAML structure.

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| YAML is valid | `python3 -c "import yaml; yaml.safe_load(open('ci.yml'))"` | exit 0 | ✓ PASS |
| Schedule trigger present | `grep -c "cron: '17 3 \* \* \*'" ci.yml` | 1 | ✓ PASS |
| No OTP 26 / Elixir 1.19 in ci.yml | `grep -c '1\.19\.0' ci.yml && grep -c "'26\.x'" ci.yml` | 0, 0 | ✓ PASS |
| _build key retains schema_prefix | `grep -c 'matrix.schema_prefix' ci.yml` | 3 | ✓ PASS |
| mix compile --force present | `grep -c 'mix compile --force' ci.yml` | 1 | ✓ PASS |
| fromJson wiring present | `grep -c 'fromJson(needs.matrix-config.outputs.test-matrix)' ci.yml` | 1 | ✓ PASS |
| demo PR skip present | `grep -c "if: github.event_name != 'pull_request'" ci.yml` | 1 | ✓ PASS |
| release_gate if: always() | `grep -c 'if: always()' ci.yml` | 1 | ✓ PASS |
| No version-type: strict | `grep -c 'version-type: strict' ci.yml` | 0 | ✓ PASS |
| demo no strategy/matrix | awk on demo block \| grep strategy/matrix | 0 matches | ✓ PASS |
| release-please publish-hex Elixir 1.20.2 | `grep elixir-version release-please.yml` | '1.20.2' | ✓ PASS |
| release-please SHA fc68ffb9 unchanged | `grep fc68ffb9 release-please.yml` | present | ✓ PASS |
| D-11 canonical row in PROJECT.md | `grep -c 'RESOLVED 2026-07-02 (Phase 60 / MATRIX-02)' PROJECT.md` | 1 | ✓ PASS |
| STATE.md D-11 @concurrency_hold_ms line untouched | `sed -n '112,118p' STATE.md` | contains D-09/D-10/D-11 annotation | ✓ PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| MATRIX-01 | 60-01 | PR CI run = exactly 1 test cell (OTP 28 / Elixir 1.20.2 / parapet) | ✓ SATISFIED | matrix-config PR branch JSON: 1 object with all 3 keys |
| MATRIX-02 | 60-01, 60-02 | Full 4-cell matrix on push/schedule; OTP 26 + Elixir 1.19 retired; D-11 formally closed | ✓ SATISFIED | 4-cell JSON confirmed; 0 legacy tokens in ci.yml; PROJECT.md canonical row dated 2026-07-02 |
| MATRIX-03 | 60-01, 60-02 | demo plain OTP-28 job skipped on PR; toolchain docs aligned | ✓ SATISFIED | `if: github.event_name != 'pull_request'`; no strategy/matrix; publish-hex on 1.20.2/28.x; README/CONTRIBUTING corrected |
| MATRIX-04 | 60-01 | Nightly cron; release_gate hardened truth table; concurrency event-scoped | ✓ SATISFIED | `cron: '17 3 * * *'`; strict success for lint/test; case success\|skipped for demo; event_name in concurrency.group |

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| None found | — | — | — |

Scanned: `ci.yml`, `release-please.yml`, `README.md`, `CONTRIBUTING.md`, `PROJECT.md`, `v1.7-MILESTONE-AUDIT.md`, `MILESTONES.md`. No TBD, FIXME, XXX, placeholder, or stub patterns found. No unresolved debt markers.

---

### Cron Override Note (SC-4)

ROADMAP SC-4 states the illustrative cron value `'0 3 * * *'`. The implementation uses `'17 3 * * *'`. This is an explicitly documented intentional refinement:

- D-03a in `60-CONTEXT.md`: "Off-the-hour deliberately — GitHub delays top-of-hour crons under load; `:17` is already this repo's house convention (rulestead `verify-published-release.yml` uses `17 6 * * *`). Intentionally refines the roadmap SC-4 illustrative `'0 3 * * *'` — verifier should accept `17 3`."
- The plan's acceptance criteria for Task 1 explicitly state: "`17 3` accepted, not the illustrative `0 3`"
- The SUMMARY documents this as a deliberate decision, not a deviation.

The functional intent (nightly full-matrix run) is achieved. The deviation from the roadmap's illustrative value is documented and intentional. Accepted via override.

---

### Human Verification Required

None. All must-haves are verifiable via static analysis of workflow YAML and planning documents. The CI runtime behavior (actual GitHub Actions run producing 1 vs 4 cells) cannot be verified without triggering a live run, but the resolver logic is deterministic and fully confirmed via JSON parse.

---

## Gaps Summary

No gaps. All 11 truths verified. All 4 requirements satisfied. All 7 artifacts present and wired.

The single cron deviation (`'17 3'` vs roadmap's illustrative `'0 3'`) is documented as intentional in D-03a and plan acceptance criteria, and accepted via override. It does not represent a gap.

---

_Verified: 2026-07-03T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
