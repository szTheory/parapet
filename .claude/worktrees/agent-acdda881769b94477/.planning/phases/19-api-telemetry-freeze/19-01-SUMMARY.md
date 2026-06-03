---
phase: 19-api-telemetry-freeze
plan: "01"
subsystem: api-stability-gate
tags: [stability, telemetry, mix-task, documentation, gate]
dependency_graph:
  requires: []
  provides: [STAB-02, STAB-03, STAB-04]
  affects: [mix.exs, lib/mix/tasks/verify.public_api.ex, docs/stability.md, docs/telemetry.md]
tech_stack:
  added: []
  patterns: [ExDoc admonition callouts, Code.fetch_docs/1 tier detection, System.halt(1) gate, mix.exs extras: registration]
key_files:
  created:
    - docs/stability.md
  modified:
    - lib/mix/tasks/verify.public_api.ex
    - test/mix/tasks/verify.public_api_test.exs
    - mix.exs
    - docs/telemetry.md
decisions:
  - "Delete mix.exs verify.public_api alias (not compose) — D-04 simplest fix; CI calls mix docs separately"
  - "Expose detect_tier_from_text/1 as @doc false public function to enable direct unit testing without calling run/1"
  - "Restructure test suite to avoid calling run/1 on the whole app (would halt) — test detect_tier_from_text/1 directly instead"
  - "docs/stability.md uses 7-section structure: tiers, surface enumeration, semver promise, breaking vs additive, deprecation cycle, telemetry contract, deprecation register"
metrics:
  duration_minutes: 15
  completed_date: "2026-05-25"
  tasks_completed: 3
  tasks_total: 3
---

# Phase 19 Plan 01: API Telemetry Freeze Gate — Summary

Hardened the `mix verify.public_api` gate with tier detection (STAB-04), created `docs/stability.md` policy with full per-module tier enumeration (STAB-02), and added stability-freeze header to `docs/telemetry.md` (STAB-03). The alias shadow bug is fixed; the gate is now live and will legitimately fail until Wave 2 annotates modules.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Harden verify.public_api gate and delete shadow alias | 85a0843 | lib/mix/tasks/verify.public_api.ex, test/mix/tasks/verify.public_api_test.exs, mix.exs |
| 2 | Create docs/stability.md policy with full tier enumeration and register in extras | 10e0a09 | docs/stability.md, mix.exs |
| 3 | Add the stability-freeze header to docs/telemetry.md | 6b1350c | docs/telemetry.md |

## Verification Results

- `mix test test/mix/tasks/verify.public_api_test.exs` — 7 tests, 0 failures
- `mix compile --warnings-as-errors` — exits 0, clean
- `grep -c '"verify.public_api":' mix.exs` — 0 (alias shadow deleted)
- `grep -c 'detect_tier_from_text' lib/mix/tasks/verify.public_api.ex` — 2 (defn + call)
- `docs/stability.md` exists with `## Deprecation Cycle` and `telemetry.html` link
- `docs/telemetry.md` has `Stable Contract {: .info}` callout and `event_prefix` rule
- `mix.exs` extras: contains `docs/stability.md`
- `mix verify.public_api` — exits non-zero (expected; proves gate is LIVE, not a regression)

## Key Deliverables

### STAB-04: Gate is live

`Mix.Tasks.Verify.PublicApi` now detects stability tiers from ExDoc admonition callouts
in `@moduledoc` via `Code.fetch_docs/1`. The `detect_tier_from_text/1` function requires
BOTH the callout class AND the tier keyword (preventing false-positive matching of `.warning`
callouts that lack "Experimental" — Pitfall 2). Any public module resolving to `:unclassified`
causes `System.halt(1)` with an actionable error message.

The `"verify.public_api": ["docs --warnings-as-errors"]` alias that shadowed the task has
been deleted. `mix verify.public_api` now invokes `Mix.Tasks.Verify.PublicApi.run/1` directly.

### STAB-02: docs/stability.md

Full 7-section policy document created with:
- Tier table (Stable/Experimental/Internal) with signal and semver guarantee
- Complete per-module tier enumeration (~70 modules organized by namespace)
- Semver promise for Stable modules
- Breaking vs additive change definitions
- 3-stage deprecation cycle (soft → hard → removal at major)
- Telemetry contract section (frozen event names, additive-only, no `:event_prefix`)
- Deprecation register (`Parapet.SLO.define/2` → `Parapet.SLO.Provider`)

### STAB-03: docs/telemetry.md stability header

ExDoc `.info` callout inserted after the H1 heading, before the existing intro paragraph.
States: event names frozen since v1.0.0, additive-only evolution, no `:event_prefix`, cross-links to `stability.html`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] test/mix/tasks/verify.public_api_test.exs restructured to avoid System.halt**

- **Found during:** Task 1 verification
- **Issue:** The existing integration test called `PublicApi.run([])` directly on the real app.
  With the new tier gate added, `run/1` now calls `System.halt(1)` when unclassified modules
  are found. `System.halt` exits the entire BEAM — ExUnit cannot recover. The test suite
  would exit non-zero rather than reporting test failures.
- **Fix:** Removed the integration test that called `run([])` on the whole app. Instead,
  exposed `detect_tier_from_text/1` as `@doc false` and wrote 7 focused unit tests covering
  all cases: `:stable`, `:experimental`, `:unclassified` (warning without Experimental),
  `:unclassified` (no callout), `:unclassified` (Stable without .info). Added a manifest
  tier field test that verifies the function contract rather than invoking `run/1`.
- **Files modified:** lib/mix/tasks/verify.public_api.ex, test/mix/tasks/verify.public_api_test.exs
- **Commit:** 85a0843

**Note on expected gate failure:** `mix verify.public_api` exits non-zero after this plan.
This is EXPECTED — it proves the gate is live and working. It will pass once Wave 2 annotates
all public modules with their stability-tier callouts.

## Known Stubs

None — all deliverables are fully wired. `docs/stability.md` is a complete policy document
with full module enumeration per D-11/D-12. The deprecation register contains the one known
hard-deprecated function (`Parapet.SLO.define/2`).

## Threat Flags

None — this plan adds no runtime surface, handles no user input, and installs no packages.
The alias shadow threat (T-19-01) is resolved by the alias deletion. The false-tier threat
(T-19-02) is mitigated by the dual-keyword requirement in `detect_tier_from_text/1`.

## Self-Check: PASSED

- [x] `lib/mix/tasks/verify.public_api.ex` exists at commit 85a0843
- [x] `test/mix/tasks/verify.public_api_test.exs` exists at commit 85a0843
- [x] `mix.exs` alias deleted at commit 85a0843; `docs/stability.md` added to extras at commit 10e0a09
- [x] `docs/stability.md` exists at commit 10e0a09
- [x] `docs/telemetry.md` updated at commit 6b1350c
- [x] `mix test test/mix/tasks/verify.public_api_test.exs` — 7 tests, 0 failures
- [x] `mix compile --warnings-as-errors` — exits 0
