---
phase: 51-prefix-core-test-seam
plan: 01
subsystem: database
tags: [ecto, schema-prefix, postgres, compile-time, config, test-seam]

requires: []
provides:
  - "Parapet.Spine.Schema base macro with __using__/1 and __prefix__/0 (compile-time prefix resolution)"
  - "config/config.exs env seam reading PARAPET_SCHEMA_PREFIX (D-06)"
  - "Parapet.Evidence.schema_prefix/0 runtime prefix helper (D-08)"
  - "RED test scaffold: schema_test.exs (PREFIX-01/02/03) + evidence_test.exs extension (PREFIX-04)"
  - "Normalization agreement test encoding D-05 contract: both copies map canonical input set identically"
affects:
  - "52-propagation-proof-guards-ci-dual-prefix-matrix"
  - "53-generators-library-migrations"
  - "54-upgrade-path-doctor"

tech-stack:
  added: []
  patterns:
    - "Compile-time @schema_prefix via module attribute reading Application.compile_env at module load (not function body — Elixir restriction)"
    - "Physically-duplicated normalization rule in __prefix__/0 and config/config.exs with mandatory agreement test (D-05)"
    - "Runtime prefix helper schema_prefix/0 colocated with repo/0 in Parapet.Evidence (D-08 shape)"
    - "RED-first TDD: test scaffold committed before implementation; compiled-prefix-across-six block stays RED until Plan 02"

key-files:
  created:
    - lib/parapet/spine/schema.ex
    - config/config.exs
    - test/parapet/spine/schema_test.exs
  modified:
    - lib/parapet/evidence.ex
    - test/parapet/evidence_test.exs

key-decisions:
  - "Application.compile_env/3 must be read at module attribute level (not inside def body); normalize via @prefix module attribute at compile time"
  - "__prefix__/0 is kept public (@doc false but callable) so Phase 54 doctor can introspect without edit (D-01 note)"
  - "config normalizer maps nil env var -> parapet (default-on); __prefix__/0 maps nil CONFIG VALUE -> nil (unprefixed); distinction is env-var input vs config-value input — agreement test operates on CONFIG VALUES"
  - "Compiled-prefix-across-six test block intentionally RED until Plan 02 (schemas still use Ecto.Schema directly); resolver/agreement/schema_prefix tests are GREEN"

patterns-established:
  - "Pattern 1 (base macro): @raw_prefix = Application.compile_env at module level; @prefix = normalized case; __prefix__/0 returns @prefix"
  - "Pattern 3 (runtime helper): schema_prefix/0 mirrors repo/0 shape using Application.get_env + same normalization case"
  - "Pattern 4 (config seam): import Config; case System.get_env on env var; config :parapet, schema_prefix: result"
  - "Agreement test: Enum.map on canonical input set through both resolver helpers; assert outputs identical"

requirements-completed: [PREFIX-01, PREFIX-02, PREFIX-03, PREFIX-04, TEST-01]

coverage:
  - id: D1
    description: "Parapet.Spine.Schema module with __using__/1 macro and __prefix__/0 resolver returning parapet by default"
    requirement: "PREFIX-01"
    verification:
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs#resolver legacy-nil cases __prefix__/0 returns nil for empty string"
        status: pass
    human_judgment: false
  - id: D2
    description: "Normalization agreement: both __prefix__/0 and config.exs copy map canonical input set to [parapet, nil, nil, nil, custom]"
    requirement: "PREFIX-03"
    verification:
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs#normalization agreement both normalization copies produce identical output"
        status: pass
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs#normalization agreement normalization_resolver/1 maps canonical input set"
        status: pass
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs#normalization agreement config_normalizer/1 maps canonical input set"
        status: pass
    human_judgment: false
  - id: D3
    description: "config/config.exs reading PARAPET_SCHEMA_PREFIX with default-on parapet; excluded from package.files"
    requirement: "TEST-01"
    verification:
      - kind: unit
        ref: "mix compile --warnings-as-errors (0 warnings); grep -c '\"config\"' mix.exs == 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Parapet.Evidence.schema_prefix/0 runtime helper: returns parapet by default, nil for empty/public/nil"
    requirement: "PREFIX-04"
    verification:
      - kind: unit
        ref: "test/parapet/evidence_test.exs#schema_prefix/0 returns parapet by default"
        status: pass
      - kind: unit
        ref: "test/parapet/evidence_test.exs#schema_prefix/0 returns nil when runtime config is empty string"
        status: pass
      - kind: unit
        ref: "test/parapet/evidence_test.exs#schema_prefix/0 returns nil when runtime config is public"
        status: pass
      - kind: unit
        ref: "test/parapet/evidence_test.exs#schema_prefix/0 returns nil when runtime config is nil"
        status: pass
    human_judgment: false
  - id: D5
    description: "RED test scaffold for compiled-prefix-across-six (stays RED until Plan 02 switches schemas)"
    requirement: "PREFIX-02"
    verification:
      - kind: unit
        ref: "test/parapet/spine/schema_test.exs#compiled prefix across six spine schemas (6 tests, intentionally failing)"
        status: fail
    human_judgment: true
    rationale: "Compiled-prefix assertions are intentionally RED until Plan 02 switches six spine schemas to use Parapet.Spine.Schema. Human confirms this is expected RED, not a regression."

duration: 6min
completed: 2026-06-30
status: complete
---

# Phase 51 Plan 01: Prefix Core & Test Seam Summary

**Compile-time `@schema_prefix` seam via `Parapet.Spine.Schema` macro + `config/config.exs` env seam + `Evidence.schema_prefix/0` runtime mirror + RED-first test scaffold encoding the D-05 normalization-agreement contract**

## Performance

- **Duration:** 6 min
- **Started:** 2026-06-30T04:21:18Z
- **Completed:** 2026-06-30T04:27:14Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Created `lib/parapet/spine/schema.ex` (`Parapet.Spine.Schema`) with `defmacro __using__/1` and `def __prefix__/0`; `Application.compile_env` read at module attribute level (Elixir restriction: cannot call inside function body); normalization runs at compile time via `@prefix` module attribute
- Created `config/config.exs` reading `PARAPET_SCHEMA_PREFIX` env var with default-on `"parapet"`; normalization maps `nil` -> `"parapet"`, `""` -> `nil`, `"public"` -> `nil`, other -> itself; `config` confirmed absent from `mix.exs` `package.files` (D-07)
- Added `Parapet.Evidence.schema_prefix/0` immediately after `repo/0`; mirrors `repo/0` shape with `Application.get_env` + identical normalization case; `@doc since: "1.7.0"`
- Created `test/parapet/spine/schema_test.exs` RED-first with three `describe` blocks: compiled-prefix-across-six (RED until Plan 02), resolver-legacy-nil (GREEN), normalization-agreement (GREEN, encodes D-05 contract on canonical input set `["parapet","","public",nil,"custom"]` → `["parapet", nil, nil, nil, "custom"]`)
- Extended `test/parapet/evidence_test.exs` with `schema_prefix/0` describe block (5 runtime-config scenarios, all GREEN); `on_exit` restores `:schema_prefix` to prevent test bleed; `async: false` preserved

## Task Commits

1. **Task 1: Wave 0 test scaffold RED** - `92fe5da` (test)
2. **Task 2: config/config.exs + Parapet.Spine.Schema macro** - `d0e5368` (feat)
3. **Task 3: Evidence.schema_prefix/0 + GREEN resolver/agreement tests** - `28c50a5` (feat)

## Files Created/Modified

- `lib/parapet/spine/schema.ex` — new `Parapet.Spine.Schema` base macro; `__using__/1` + `__prefix__/0`
- `config/config.exs` — new compile-time env seam; reads `PARAPET_SCHEMA_PREFIX`; excluded from package.files
- `lib/parapet/evidence.ex` — added `schema_prefix/0` after `repo/0`
- `test/parapet/spine/schema_test.exs` — new test file; three describe blocks; RED-first scaffold
- `test/parapet/evidence_test.exs` — extended with `schema_prefix/0` describe block

## Decisions Made

- `Application.compile_env/3` must be read at module attribute level (not inside a `def` body — Elixir raises `RuntimeError: cannot be called inside functions, only in the module body`). Normalization is computed in a second `@prefix` attribute via a `case` expression. `__prefix__/0` returns `@prefix` as a simple accessor. This differs from the synthesis §2 verbatim body but is the correct Elixir pattern.
- `__prefix__/0` kept public (callable) so the Phase 54 doctor can introspect the compiled prefix without a future edit (D-01 note: "Claude's Discretion").
- The agreement test encodes contract on CONFIG VALUES (not env var inputs). Config.exs maps `nil` env var → `"parapet"` (default-on); `__prefix__/0` maps `nil` CONFIG VALUE → `nil` (unprefixed). The test helper `config_normalize_prefix/1` operates on config values, not env var strings — both copies agree that `nil` config value → `nil` output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Application.compile_env/3 cannot be called inside function body**
- **Found during:** Task 2 (Parapet.Spine.Schema macro implementation)
- **Issue:** The synthesis §2 reference body placed `Application.compile_env(:parapet, :schema_prefix, "parapet")` inside `def __prefix__/0`. Elixir raises `RuntimeError: Application.compile_env/3 cannot be called inside functions, only in the module body` at compile time.
- **Fix:** Read `compile_env` at module attribute level (`@raw_prefix`), normalize via a second attribute (`@prefix`), and have `__prefix__/0` return `@prefix`. All compile-time semantics preserved; the normalization still runs at module-load time.
- **Files modified:** `lib/parapet/spine/schema.ex`
- **Verification:** `mix compile --warnings-as-errors` passes; `Parapet.Spine.Schema.__prefix__()` returns `"parapet"`
- **Committed in:** `d0e5368` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug: compile_env restriction)
**Impact on plan:** Required fix for compilation. No scope creep; semantics identical to plan intent.

## Issues Encountered

- Pre-existing test failure in `Parapet.DocsPhase33Test` ("demo app docs describe the reproducible Compose smoke path") was present before this plan's changes and is unrelated. Logged as out-of-scope per deviation scope boundary rules.

## Next Phase Readiness

- Plan 02 (spine schema propagation) can proceed: `Parapet.Spine.Schema` macro exists and compiles; `config/config.exs` seam is in place
- The six `compiled-prefix-across-six` assertions in `schema_test.exs` are staged RED, waiting for Plan 02 to switch the schemas to `use Parapet.Spine.Schema`
- Phase 54 doctor can call `Parapet.Spine.Schema.__prefix__/0` and `Parapet.Evidence.schema_prefix/0` without any future edits

## Self-Check: PASSED

- `lib/parapet/spine/schema.ex`: FOUND
- `config/config.exs`: FOUND
- `lib/parapet/evidence.ex`: FOUND (schema_prefix/0 added)
- `test/parapet/spine/schema_test.exs`: FOUND
- `test/parapet/evidence_test.exs`: FOUND (schema_prefix/0 describe block added)
- Commit `92fe5da`: FOUND (test scaffold RED)
- Commit `d0e5368`: FOUND (macro + config seam)
- Commit `28c50a5`: FOUND (runtime helper + GREEN tests)

---
*Phase: 51-prefix-core-test-seam*
*Completed: 2026-06-30*
