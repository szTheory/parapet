---
phase: 59-ci-caching-lint-once-release-gate-hardening
verified: 2026-07-02T00:00:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 59: CI Caching, Lint-Once & release_gate Hardening — Verification Report

**Phase Goal:** Structurally reshape `.github/workflows/ci.yml` so the Dialyzer PLT is cached (lint-once only, prefix-agnostic key), lint/quality runs once on OTP 28, PR runs cancel superseded in-flight runs (main/nightly never cancelled), `release_gate` can never silently pass on an upstream failure/skip, the v1.7 dual-prefix false-green invariant stays intact, and SHA-pinned actions are refreshed.
**Verified:** 2026-07-02
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Step 0: Previous Verification

No previous `59-VERIFICATION.md` found. Proceeding with initial verification.

---

## Step 1: Context

Phase directory: `.planning/phases/59-ci-caching-lint-once-release-gate-hardening/`
Plans: `59-01-PLAN.md` (wave 1), `59-02-PLAN.md` (wave 2)
Summaries: `59-01-SUMMARY.md`, `59-02-SUMMARY.md`
Live artifact: `.github/workflows/ci.yml`
Requirements: CI-01, CI-02, CI-03, CI-04, CI-05, CI-06

---

## Step 2: Must-Haves

### From REQUIREMENTS.md (roadmap contract)

- **CI-01**: Dialyzer PLT cached in `priv/plts` with prefix-agnostic OTP+Elixir+mix.lock key in `lint-once` only.
- **CI-02**: Lint/quality steps run exactly once in a single OTP-28 `lint-once` job; `mix docs --warnings-as-errors` and operator-UI manifest diff steps intact.
- **CI-03**: Top-level `concurrency:` block with group scoped to PR number (or ref fallback), `cancel-in-progress` true only for PR events.
- **CI-04**: `release_gate` has `if: always()`, `needs: [lint-once, test, demo]`, explicit per-job aggregation that exits 1 on any non-`success` result (including `skipped`/`cancelled`). No `contains(needs.*.result, ...)` one-liner.
- **CI-05**: `test` job `_build` cache key retains `${{ matrix.schema_prefix }}`; `mix compile --force` step retained byte-for-byte.
- **CI-06**: All `uses:` lines pinned to exact D-13 SHAs: `actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10` (v6.0.3), `erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124` (v1.24.1), `actions/cache@caa296126883cff596d87d8935842f9db880ef25` (v5.1.0). No old SHAs remain. `# vX.Y.Z` comments present on every pin. Newest-major tiers (checkout v7 / cache v6) NOT adopted.

### Prohibitions (from plan frontmatter)

- MUST NOT alter the test job's `_build` cache key — it MUST retain `${{ matrix.schema_prefix }}` (CI-05/D-12)
- MUST NOT remove or weaken the test job's `mix compile --force` step (CI-05/D-12)
- MUST NOT add a PLT cache to the `test` or `demo` jobs (D-01)
- MUST NOT add a `schema_prefix` component to the PLT cache key (D-03)
- MUST NOT re-architect `lint-once` or remove `mix docs --warnings-as-errors` / manifest-diff steps (D-05/D-06)
- MUST NOT change any pin to a value other than the three exact D-13 commit hashes (59-02)
- MUST NOT adopt newest-major tiers (checkout v7 / cache v6) (D-14)
- MUST NOT use `contains(needs.*.result, ...)` one-liner in `release_gate` (D-11)

---

## Step 3: Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | lint-once job caches `priv/plts` with prefix-agnostic key so PRs restore the Dialyzer PLT instead of rebuilding it (CI-01) | VERIFIED | `path: priv/plts` at line 41; key `plt-${{ runner.os }}-28.x-1.19.0-${{ hashFiles('**/mix.lock') }}` at line 42; restore-keys `plt-${{ runner.os }}-28.x-1.19.0-` at line 43; no `schema_prefix` in PLT key; PLT cache step absent from `test` and `demo` jobs |
| 2 | lint/quality still runs exactly once in the single OTP-28 `lint-once` job; `mix docs --warnings-as-errors` and operator-UI manifest diff intact (CI-02) | VERIFIED | `mix ci` step at line 47; `mix docs --warnings-as-errors` at line 51; `Operator UI manifest drift` diff block at lines 52-56; `mix ci` appears only once in the file and only in `lint-once` |
| 3 | A new push to an open PR cancels the prior in-flight run; pushes to main are never cancelled (CI-03) | VERIFIED | Top-level `concurrency:` block at lines 10-12 (sibling of `on:` at line 3 and `jobs:` at line 14); `group: ${{ github.workflow }}-${{ github.event.pull_request.number \|\| github.ref }}`; `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` |
| 4 | `release_gate` runs even when an upstream job fails or is skipped, and exits non-zero unless all three upstream jobs are exactly `success` (CI-04) | VERIFIED | `if: always()` at line 169; `needs: [lint-once, test, demo]` at line 167; explicit per-job checks referencing `needs.lint-once.result`, `needs.test.result`, `needs.demo.result` at lines 173-175; `FAILED=1` set on any non-`success`; `exit 1` at line 191; no `contains(needs.*.result, ...)` one-liner found anywhere |
| 5 | The `test` job still has `${{ matrix.schema_prefix }}` in its `_build` cache key AND `mix compile --force` per cell — byte-for-byte intact (CI-05) | VERIFIED | `_build` key at line 104: `${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-${{ hashFiles('**/mix.lock') }}`; `mix compile --force` at line 109; no PLT cache step in `test` job |
| 6 | Every `uses:` line is SHA-pinned to the exact D-13 commits with `# vX.Y.Z` version comments; no old SHAs remain; newest-major tiers not adopted (CI-06) | VERIFIED | `actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6.0.3` — 3 occurrences (lines 20, 88, 137); `erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124 # v1.24.1` — 3 occurrences (lines 22, 90, 139); `actions/cache@caa296126883cff596d87d8935842f9db880ef25 # v5.1.0` — 7 occurrences (lines 27, 33, 39, 95, 101, 144, 150); old SHAs `34e114...`, `fc68ff...`, `0057852...` all 0 occurrences; no `checkout@v7` or `cache@v6` |

**Score: 6/6 truths verified (0 present, behavior-unverified)**

---

## Step 4: Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/ci.yml` | Reshaped CI workflow with PLT cache, concurrency block, hardened release_gate, refreshed SHA pins | VERIFIED | File exists, 194 lines, valid YAML (python3 yaml.safe_load confirms), all 6 CI requirements encoded |

---

## Step 5: Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `release_gate.needs` | `lint-once`, `test`, `demo` jobs | `needs: [lint-once, test, demo]` at line 167 | VERIFIED | All three jobs named in `needs` match the three jobs checked in the aggregation script |
| PLT cache step | Before `Run mix ci` | Step ordering in `lint-once` job | VERIFIED | `Cache PLT` at lines 38-43 precedes `Install dependencies` (line 44) and `Run mix ci` (line 47) |
| `cancel-in-progress` | PR runs only | Dynamic boolean `${{ github.event_name == 'pull_request' }}` | VERIFIED | Expression evaluates false for push-to-main and future scheduled events |

---

## Step 6: Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CI-01 | 59-01-PLAN.md | Dialyzer PLT cached, prefix-agnostic key | SATISFIED | `path: priv/plts`, key `plt-${{ runner.os }}-28.x-1.19.0-...` in lint-once only |
| CI-02 | 59-01-PLAN.md | Lint/quality once on OTP-28 lint-once; CI-only steps intact | SATISFIED | Single `mix ci` invocation; `mix docs --warnings-as-errors`; manifest diff present |
| CI-03 | 59-01-PLAN.md | PR concurrency cancellation; main never cancelled | SATISFIED | Top-level concurrency block with dynamic `cancel-in-progress` |
| CI-04 | 59-01-PLAN.md | release_gate hardened with `if: always()` + explicit aggregation | SATISFIED | `if: always()`; per-job `!= "success"` checks; `exit 1`; no `contains()` one-liner |
| CI-05 | 59-01-PLAN.md + 59-02-PLAN.md | Dual-prefix invariant untouched | SATISFIED | `${{ matrix.schema_prefix }}` in `_build` key; `mix compile --force` intact |
| CI-06 | 59-02-PLAN.md | SHA pins refreshed to D-13 commits | SATISFIED | All 13 `uses:` lines carry D-13 SHAs + `# vX.Y.Z` comments; old SHAs absent |

All 6 phase requirements satisfied. REQUIREMENTS.md traceability table still shows CI-01 through CI-04 as `[ ]` Pending and CI-05/CI-06 as `[x]` Complete — the checkbox states predate execution and are documentation-only; the live ci.yml is authoritative.

---

## Step 7: Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | No anti-patterns found |

No `TBD`, `FIXME`, `XXX`, placeholder text, or empty implementations found in `.github/workflows/ci.yml`. No debt markers.

### Prohibition Compliance

| Prohibition | Status |
|-------------|--------|
| test `_build` key retains `${{ matrix.schema_prefix }}` | COMPLIANT — line 104 |
| test `mix compile --force` retained | COMPLIANT — line 109 |
| No PLT cache in `test` or `demo` jobs | COMPLIANT — `priv/plts` appears only in `lint-once` (line 41) |
| No `schema_prefix` in PLT cache key | COMPLIANT — key line 42 contains no `schema_prefix` |
| `lint-once` not re-architected; `mix docs` + manifest-diff intact | COMPLIANT — lines 48-56 |
| Only D-13 commit hashes used | COMPLIANT — all 3 D-13 SHAs present, no other SHA values |
| Newest-major tiers not adopted | COMPLIANT — no `checkout@v7` or `cache@v6` found |
| No `contains(needs.*.result, ...)` one-liner | COMPLIANT — grep confirmed absent |

---

## Step 7b: Behavioral Spot-Checks

This phase is CI-YAML-only. No runnable entry points. Verification is source-assertion based (YAML parse + grep). Step 7b: SKIPPED (CI workflow — behavioral verification requires GitHub Actions runner execution, not achievable locally without a server-side trigger).

YAML validity confirmed via `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` — exit code 0.

---

## Step 8: Human Verification Required

No human verification items identified. All truths are verifiable through static YAML analysis and grep. The CI behavior (PLT restore, PR cancellation, gate blocking) requires an actual GitHub Actions run to exercise end-to-end, but all structural preconditions are confirmed present and correctly wired.

---

## Step 9: Overall Status

Decision tree:
1. No truths FAILED, no artifacts MISSING/STUB, no key links NOT_WIRED, no blocker anti-patterns — rule 1 does not fire.
2. No human verification items — rule 2 does not fire.
3. All 6 truths VERIFIED, all artifacts pass all levels, all links wired, no blockers, no human items — **status: passed**.

**Status: PASSED**
**Score: 6/6**

---

## Goal Achievement Summary

The phase goal is fully achieved. `.github/workflows/ci.yml` has been structurally reshaped with every required change verified in the live file:

- **PLT caching (CI-01):** `Cache PLT` step in `lint-once` only, `path: priv/plts`, prefix-agnostic key `plt-${{ runner.os }}-28.x-1.19.0-${{ hashFiles('**/mix.lock') }}`, placed before `Run mix ci`.
- **Lint-once (CI-02):** Single `mix ci` invocation on OTP 28; `mix docs --warnings-as-errors` and operator-UI manifest diff steps unchanged.
- **PR concurrency (CI-03):** Top-level `concurrency:` block at the workflow level; `cancel-in-progress` is a dynamic boolean that is true only for `pull_request` events, never for main or future scheduled runs.
- **release_gate hardening (CI-04):** `if: always()` + three explicit per-job `!= "success"` checks + `exit 1` + no `contains()` one-liner; skipped/cancelled/failed upstreams all block the gate.
- **Dual-prefix invariant (CI-05):** `test` job `_build` key retains `${{ matrix.schema_prefix }}`; `mix compile --force` present; no PLT cache leaked into `test` or `demo`.
- **SHA pins (CI-06):** All 13 `uses:` lines carry the three D-13 SHA pins with `# vX.Y.Z` comments; all three old SHAs confirmed absent; no newest-major tiers adopted.

---

_Verified: 2026-07-02_
_Verifier: Claude (gsd-verifier)_
