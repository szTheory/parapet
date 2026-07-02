---
phase: 59-ci-caching-lint-once-release-gate-hardening
plan: "02"
subsystem: ci
tags: [ci, sha-pins, supply-chain, github-actions, security]
status: complete

dependency_graph:
  requires:
    - phase-59-plan-01 (PLT cache step added — must also receive repinned cache SHA)
  provides:
    - All GitHub Actions SHA-pinned to D-13 proven-recent commits (CI-06)
    - Supply-chain integrity hardened across lint-once, test, demo jobs
  affects:
    - .github/workflows/ci.yml

tech_stack:
  added: []
  patterns:
    - "SHA-pinned GitHub Actions with inline # vX.Y.Z version comments for Dependabot and human readability"

key_files:
  created: []
  modified:
    - .github/workflows/ci.yml

decisions:
  - "actions/checkout pinned to df4cb1c069e1874edd31b4311f1884172cec0e10 (v6.0.3) across all 3 jobs"
  - "erlef/setup-beam pinned to 54075bcc5e249e4758d363f27d099f55d843f124 (v1.24.1) across all 3 jobs"
  - "actions/cache pinned to caa296126883cff596d87d8935842f9db880ef25 (v5.1.0) across 7 steps including the 59-01 PLT cache step"
  - "Newest-major tiers (checkout v7, cache v6) deferred to Dependabot (D-14)"
  - "CI-05 dual-prefix invariant untouched — schema_prefix _build key and mix compile --force byte-for-byte unchanged (D-12)"

metrics:
  duration: 1
  completed: "2026-07-02"
  tasks_completed: 1
  files_modified: 1
---

# Phase 59 Plan 02: SHA-Pin Refresh Summary

Repinned all GitHub Actions across every job in `.github/workflows/ci.yml` to the three D-13 proven-recent commit hashes with matching `# vX.Y.Z` version comments — completing the supply-chain integrity hardening for the release-critical CI backbone.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Repin all SHA-pinned actions to the D-13 commits with version comments | fcf8509 | .github/workflows/ci.yml |

## What Was Built

### Task 1 — SHA Pin Refresh (CI-06)

Replaced every `uses:` SHA across all four jobs (`lint-once`, `test`, `demo`, `release_gate`) with the D-13 proven-recent pins:

| Action | Old SHA | New SHA | Version |
|--------|---------|---------|---------|
| `actions/checkout` | `34e114876b0b...` (v4-era) | `df4cb1c069e1874edd31b4311f1884172cec0e10` | `# v6.0.3` |
| `erlef/setup-beam` | `fc68ffb90438...` (v1.24.0) | `54075bcc5e249e4758d363f27d099f55d843f124` | `# v1.24.1` |
| `actions/cache` | `0057852bfaa8...` (v4-era) | `caa296126883cff596d87d8935842f9db880ef25` | `# v5.1.0` |

**Scope of replacements:**
- `actions/checkout`: 3 occurrences (lint-once, test, demo)
- `erlef/setup-beam`: 3 occurrences (lint-once, test, demo)
- `actions/cache`: 7 occurrences (lint-once: deps + _build + PLT; test: deps + _build; demo: deps + _build)

The PLT cache step added in 59-01 (previously pinned to the old v4-era cache SHA `0057852bfaa...`) received the v5.1.0 pin alongside all other cache steps — the sequential wave ordering guaranteed it was present before this pin sweep.

**Version comments:** `# vX.Y.Z` added inline on every `uses:` line, enabling Dependabot to read the intended version and humans to understand the pin without looking up the SHA.

**CI-05 invariant (D-12):** The `test` job was touched only for SHA bumps. `${{ matrix.schema_prefix }}`-namespaced `_build` cache key and `run: mix compile --force` step remain byte-for-byte unchanged.

**Newest-major tiers not adopted (D-14):** `checkout@v7.0.0` and `cache@v6.1.0` deferred to Dependabot's normal cadence — the <2-week-old newest majors carry node24/ESM runtime changes not appropriate for the release-critical CI backbone.

## Verification

All automated checks passed:

```
YAML: valid (python3 yaml.safe_load)
checkout old SHA 34e114...: absent
setup-beam old SHA fc68ff...: absent
cache old SHA 0057852...: absent
actions/checkout@df4cb1c...: present
erlef/setup-beam@54075bc...: present
actions/cache@caa2961...: present (7 occurrences — >= 5 required)
# v6.0.3: present
# v1.24.1: present
# v5.1.0: present
test job schema_prefix _build key: intact (CI-05)
mix compile --force: present (CI-05)
```

## Deviations from Plan

None — plan executed exactly as written. All D-13 commit hashes applied verbatim. All D-14 version comments added. CI-05 dual-prefix invariant verified intact. Newest-major tiers not adopted per D-14 prohibition.

## Known Stubs

None — this plan makes no data-wiring or UI changes.

## Threat Surface Scan

No new trust boundaries introduced. The two threat mitigations from the plan's `<threat_model>` are implemented:
- **T-59-SC (Tampering — SHA-pin integrity):** All 13 `uses:` lines across all jobs now carry immutable full commit SHA pins at D-13 proven-recent hashes. Verify step confirmed old SHAs absent and new SHAs present (including cache count >= 5).
- **T-59-05 (Tampering — dual-prefix false-green):** SHA bumps are the only edit to the `test` job; `${{ matrix.schema_prefix }}` _build key and `mix compile --force` unchanged.

## Self-Check: PASSED

- `.github/workflows/ci.yml` — verified (YAML valid, all grep assertions pass, 7 cache occurrences)
- Commit `fcf8509` — Task 1 (SHA-pin refresh across all jobs)
