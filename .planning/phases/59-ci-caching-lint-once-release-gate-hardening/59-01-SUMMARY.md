---
phase: 59-ci-caching-lint-once-release-gate-hardening
plan: "01"
subsystem: ci
tags: [ci, caching, plt, dialyzer, concurrency, release-gate, github-actions]
status: complete

dependency_graph:
  requires:
    - phase-58-local-dx-mix-ci-contributing (plt_file path in mix.exs, mix ci alias)
  provides:
    - Dialyzer PLT cached across CI runs (CI-01)
    - PR concurrency cancellation (CI-03)
    - Hardened release_gate — skipped/cancelled/failed upstream blocks merge (CI-04)
  affects:
    - .github/workflows/ci.yml

tech_stack:
  added: []
  patterns:
    - "GitHub Actions top-level concurrency block (cancel PRs, never cancel main)"
    - "actions/cache for priv/plts with OTP+Elixir+mix.lock key"
    - "release_gate explicit per-job result aggregation with exit 1 on non-success"

key_files:
  created: []
  modified:
    - .github/workflows/ci.yml

decisions:
  - "PLT cache step placed in lint-once only, not test or demo (D-01)"
  - "PLT key is prefix-agnostic: plt-${{ runner.os }}-28.x-1.19.0-${{ hashFiles('**/mix.lock') }} (D-02/D-03)"
  - "Cache PLT step grouped with other cache steps, before Run mix ci (D-04)"
  - "Top-level concurrency block with dynamic cancel-in-progress boolean (D-07/D-08)"
  - "release_gate if: always() + explicit per-job checks, no contains() one-liner (D-09/D-10/D-11)"
  - "SHA pins kept as-is — bumps are plan 59-02's responsibility"

metrics:
  duration: 2
  completed: "2026-07-02"
  tasks_completed: 2
  files_modified: 1
---

# Phase 59 Plan 01: CI Caching, Lint-Once & release_gate Hardening Summary

Three structural edits to `.github/workflows/ci.yml`: Dialyzer PLT cache in lint-once with prefix-agnostic key, top-level PR concurrency cancellation that never touches main, and release_gate hardened to treat skipped/cancelled/failed upstreams as gate failures.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add PLT cache to lint-once and top-level concurrency block | 51ab11a | .github/workflows/ci.yml |
| 2 | Harden release_gate with if: always() + explicit per-job aggregation | c47ce88 | .github/workflows/ci.yml |

## What Was Built

### Task 1 — PLT Cache + Concurrency Block

**PLT Cache (CI-01):**
- Added `Cache PLT` step in `lint-once` job only, grouped with existing `Cache _build` step, placed before `Run mix ci`
- `path: priv/plts` (covers both dialyxir core and project PLTs)
- Key: `plt-${{ runner.os }}-28.x-1.19.0-${{ hashFiles('**/mix.lock') }}` — prefix-agnostic (D-03: lint-once is not matrixed by schema_prefix)
- `restore-keys: plt-${{ runner.os }}-28.x-1.19.0-` — same namespace fallback
- Same `actions/cache` SHA pin as existing cache steps (`0057852bfaa89a56745cba8c7296529d2fc39830`) — pin bump deferred to 59-02

**Concurrency Block (CI-03):**
- Added top-level (workflow-scoped, sibling of `on:` and `jobs:`) `concurrency:` block
- `group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}` — isolates PR runs by PR number, other branches by ref
- `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` — dynamic boolean; cancels only PR runs, never main or future nightly/scheduled runs
- Added explanatory comment above the block

**CI-05 Invariant (D-12):** The `test` job was not touched. `${{ matrix.schema_prefix }}` in the `_build` cache key and `mix compile --force` remain byte-for-byte unchanged.

### Task 2 — release_gate Hardening (CI-04)

- Kept `needs: [lint-once, test, demo]` — names all three upstream jobs
- Added `if: always()` to the job — gate runs even when an upstream fails or is skipped (previously default `if: success()` would silently skip the gate on upstream failure)
- Replaced bare `echo "All required CI checks passed"` with explicit per-job aggregation shell step:
  - Checks `needs.lint-once.result`, `needs.test.result`, `needs.demo.result` individually
  - Any value other than `success` (including `skipped` and `cancelled`) sets `FAILED=1`
  - `exit 1` at end if any job is non-success
  - No `contains(needs.*.result, 'failure')` one-liner (D-11: that form misses `skipped`)

## Verification

All automated checks passed:

```
YAML: valid
PLT path: priv/plts (lint-once only, 1 occurrence)
PLT key: plt-${{ runner.os }}-28.x-1.19.0-${{ hashFiles('**/mix.lock') }} (prefix-agnostic)
PLT restore-keys: plt-${{ runner.os }}-28.x-1.19.0-
Concurrency group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
cancel-in-progress: ${{ github.event_name == 'pull_request' }}
release_gate if: always() — present
needs.lint-once.result — referenced
needs.test.result — referenced
needs.demo.result — referenced
exit 1 — present
contains(needs.*) — absent
test job schema_prefix _build key — intact (CI-05)
mix compile --force — intact (CI-05)
PLT cache in test section — NONE (correct)
PLT cache in demo section — NONE (correct)
```

## Deviations from Plan

None — plan executed exactly as written. All D-01 through D-12 decisions honored verbatim. SHA pins left untouched per prohibition (59-02 will bump them).

## Known Stubs

None — this plan makes no data-wiring or UI changes.

## Threat Surface Scan

No new trust boundaries introduced beyond those already in the plan's `<threat_model>`. The three mitigations (T-59-01: PLT cache key scoped to mix.lock; T-59-02: release_gate explicit aggregation; T-59-03: dynamic cancel-in-progress; T-59-04: test job untouched) are all implemented and verified.

## Self-Check: PASSED

- `.github/workflows/ci.yml` — modified and verified (YAML valid, all grep checks pass)
- Commit `51ab11a` — Task 1 (PLT cache + concurrency)
- Commit `c47ce88` — Task 2 (release_gate hardening)
