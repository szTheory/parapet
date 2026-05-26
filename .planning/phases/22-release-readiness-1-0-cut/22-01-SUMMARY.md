---
phase: 22-release-readiness-1-0-cut
plan: 01
subsystem: ci-release-gate
tags: [github-actions, ci, release-gate, rel-01]

requires:
  - "Existing ci.yml topology with test, demo, and release_gate"
provides:
  - "Dedicated lint job for release-quality gates"
  - "Test job narrowed to mix test"
  - "release_gate fan-in expanded to lint + test + demo"

requirements-completed: [REL-01, REL-03]
completed: 2026-05-26
---

# Phase 22 Plan 01 Summary

Split CI into explicit release-quality and test lanes without changing the operator-facing `release_gate` contract.

## What Changed

- Added a new `lint` job in `.github/workflows/ci.yml`.
- Moved `mix compile --warnings-as-errors`, `mix compile --no-optional-deps --warnings-as-errors`, `mix docs --warnings-as-errors`, `mix credo --strict`, `mix dialyzer`, and `mix verify.public_api` into `lint`.
- Narrowed `test` to dependency install plus `mix test`.
- Updated `demo` to wait on both `lint` and `test`.
- Updated `release_gate` to `needs: [lint, test, demo]`.

## Verification Results

| Check | Result |
|-------|--------|
| `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` | PASS |
| `rg -n "^  lint:" .github/workflows/ci.yml` | PASS |
| `rg -n "mix compile --warnings-as-errors|mix compile --no-optional-deps --warnings-as-errors|mix docs --warnings-as-errors|mix credo --strict|mix dialyzer|mix verify.public_api" .github/workflows/ci.yml` | PASS |
| `rg -n "run: mix test" .github/workflows/ci.yml` | PASS |
| `rg -n "needs: \\[lint, test, demo\\]" .github/workflows/ci.yml` | PASS |

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
