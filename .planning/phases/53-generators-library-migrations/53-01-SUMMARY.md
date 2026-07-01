---
phase: 53-generators-library-migrations
plan: "01"
subsystem: database
tags: [elixir, postgres, schema-prefix, igniter, ecto, migrations, prefix-resolver]

# Dependency graph
requires:
  - phase: 52-propagation-proof-guards-ci-dual-prefix-matrix
    provides: normalize/1, safe_ident!/1 allowlist, PROP-02 static guard, dual-prefix CI matrix
  - phase: 51-prefix-core-test-seam
    provides: Parapet.Spine.Schema.__prefix__/0, compile-time prefix seam
provides:
  - Parapet.Spine.Schema.resolve_prefix/2 (pure core — generate-time prefix resolver)
  - Parapet.Spine.Schema.resolve_prefix/1 (thin Igniter-aware arity)
  - Pure-core unit tests proving precedence, conflict-warns-not-crashes, and safe_ident! rejection
affects:
  - 53-02 (gen.spine and gen.archive_indexes consume resolve_prefix)
  - 53-03 (install orchestrator consumes resolve_prefix)
  - 53-04 (generator output tests verify resolver behavior end-to-end)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure-core resolver pattern (flag, config) -> {:ok, v} | {:conflict, v1, v2} — table-testable with zero Igniter scaffolding"
    - "Compile-vs-runtime firewall documented in @doc: __prefix__/0 is compile-time; resolve_prefix/2 is generate-time; never cross the streams"
    - "TDD RED/GREEN: write failing tests before implementation; commit test as 'test(...)' then implementation as 'feat(...)'"

key-files:
  created: []
  modified:
    - lib/parapet/spine/schema.ex
    - test/parapet/spine/schema_test.exs

key-decisions:
  - "resolve_prefix/2 normalizes both args through normalize/1 unconditionally — safe_ident!/1 rejection is automatic (T-53-01 / ASVS V5 mitigation); no separate safe_ident! call needed"
  - "Default 'parapet' is produced by calling normalize('parapet') (not a bare literal) so D-00 single-normalization-source invariant holds by construction"
  - "resolve_prefix/1 (Igniter arity) is a thin reader only; the Igniter.add_warning call belongs in the task, not here, keeping this arity side-effect-free"
  - "D-09 firewall: resolve_prefix body never references @prefix or __prefix__/0 — proven by code inspection and test isolation"

patterns-established:
  - "Pure core (flag, config) -> {:ok, v} | {:conflict, v1, v2} split from Igniter arity: core is table-testable, Igniter arity is thin reader"
  - "Conflict returns tuple not raise — callers decide whether to warn, log, or surface (GEN-03 contract)"

requirements-completed: [GEN-05, GEN-03]

coverage:
  - id: D1
    description: "resolve_prefix/2 pure core with precedence flag > config > default, returns {:ok, normalized}"
    requirement: GEN-05
    verification:
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs#resolve_prefix/2 (pure core)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Conflict path {:conflict, flag, config} for divergent non-nil values — warns, does not crash (GEN-03)"
    requirement: GEN-03
    verification:
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs#conflict path does not raise — explicit non-raising assertion"
        status: pass
    human_judgment: false
  - id: D3
    description: "safe_ident!/1 rejection (ArgumentError) for malformed identifiers before any return (T-53-01)"
    requirement: GEN-05
    verification:
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs#malformed flag 'Bad-Name' raises ArgumentError"
        status: pass
    human_judgment: false
  - id: D4
    description: "resolve_prefix/1 Igniter arity: thin reader extracting schema option + Application.get_env"
    requirement: GEN-05
    verification: []
    human_judgment: true
    rationale: "Igniter arity requires an igniter struct at runtime; no pure-core unit test can exercise it without Igniter scaffolding. Wire-up is exercised in Plans 02/03."

# Metrics
duration: 5min
completed: 2026-07-01
status: complete
---

# Phase 53 Plan 01: Shared Prefix Resolver Foundation Summary

**Pure-core generate-time prefix resolver `resolve_prefix/2` added to `Parapet.Spine.Schema` with conflict-warns-not-crashes contract (GEN-03) and single-source-of-normalization invariant (GEN-05, D-00)**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-01T15:19:45Z
- **Completed:** 2026-07-01T15:24:00Z
- **Tasks:** 2 (TDD: RED + GREEN cycle)
- **Files modified:** 2

## Accomplishments

- Added `Parapet.Spine.Schema.resolve_prefix/2` — pure core `(flag, config) -> {:ok, normalized} | {:conflict, nf, nc}` with precedence `flag > existing config > default "parapet"` (D-06)
- Added `Parapet.Spine.Schema.resolve_prefix/1` — thin Igniter-aware arity that extracts `igniter.args.options[:schema]` and `Application.get_env(:parapet, :schema_prefix)` and delegates to pure core
- Both args normalized through `normalize/1` → `safe_ident!/1` unconditionally; malformed identifiers raise ArgumentError before any value is returned (T-53-01 / ASVS V5 mitigation)
- Added 20 new pure-core unit tests covering: full precedence matrix, conflict non-raising assertion, safe_ident! rejection, nil/""/public normalization in both argument positions
- D-09 firewall verified: `resolve_prefix` body references neither `@prefix` nor `__prefix__/0`
- All 45 tests pass; `mix compile --warnings-as-errors` clean

## Task Commits

Each task was committed atomically:

1. **TDD RED: Failing resolve_prefix/2 tests** - `f4b27bd` (test)
2. **TDD GREEN: resolve_prefix/2 + /1 implementation** - `a02ad61` (feat)

## Files Created/Modified

- `/Users/jon/projects/parapet/lib/parapet/spine/schema.ex` — Added `resolve_prefix/2` (pure core), `resolve_prefix/1` (Igniter arity), @doc with compile-vs-runtime firewall note
- `/Users/jon/projects/parapet/test/parapet/spine/schema_test.exs` — Added `describe "resolve_prefix/2 (pure core)"` block with 20 tests (precedence, conflict, safe_ident!, nil-leg normalization)

## Decisions Made

- **`normalize/1` called in both arg positions unconditionally:** Ensures safe_ident!/1 is always the gatekeeper — no path bypasses allowlist validation (T-53-01).
- **Default via `normalize("parapet")` not bare literal:** Keeps D-00 (single normalization source) enforceable by construction; if normalize ever changes, the default is affected too.
- **`resolve_prefix/1` is a thin reader:** The `Igniter.add_warning/2` call belongs in the calling mix task so this arity stays side-effect-free and testable in isolation.
- **Nil inputs handled by `if flag, do: normalize(flag), else: nil`:** Avoids calling `normalize(nil)` which returns `nil` already — the guard makes the nil-pass-through explicit and avoids confusing nil with an absent value.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed @doc string interpolation causing compile error**
- **Found during:** Task 1 (GREEN phase)
- **Issue:** `@doc` example code contained `#{prefix}` interpolation which Elixir interpreted as a runtime string interpolation inside the doc attribute, causing `(CompileError) undefined variable "prefix"`
- **Fix:** Replaced interpolated example with placeholder text (`<flag>`, `<existing>`) in the doc example
- **Files modified:** `lib/parapet/spine/schema.ex`
- **Verification:** `mix compile --warnings-as-errors` passes cleanly
- **Committed in:** `a02ad61` (same GREEN task commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 bug — compile error in @doc string)
**Impact on plan:** Minor doc string fix required; no scope creep, no logic changes.

## Issues Encountered

- Elixir interprets `#{...}` inside doc strings as string interpolation — required replacing the example's dynamic `#{prefix}` references with static placeholder text. Doc example remains illustrative and correct.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced.
The only trust boundary is CLI/config → `resolve_prefix/2`, which is fully mitigated by the existing `safe_ident!/1` allowlist (T-53-01, disposition: mitigate, verified by unit tests).

## Known Stubs

None. `resolve_prefix/1` (Igniter arity) reads from live runtime (`Application.get_env`); the pure core is fully wired. Plan 02 wires the Igniter arity into the mix tasks.

## Next Phase Readiness

- `resolve_prefix/2` (pure core) and `resolve_prefix/1` (Igniter arity) are ready for Plans 02 and 03 to consume
- All Wave 1 requirements (GEN-05, GEN-03) are satisfied
- Wave 2 plans (02: gen.spine + gen.archive_indexes, 03: install orchestrator) can proceed in parallel

---
*Phase: 53-generators-library-migrations*
*Completed: 2026-07-01*
