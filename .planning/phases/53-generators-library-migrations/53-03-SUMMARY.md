---
phase: 53-generators-library-migrations
plan: "03"
subsystem: database
tags: [elixir, postgres, schema-prefix, igniter, mix-tasks, install, generators, flag-routing]

# Dependency graph
requires:
  - phase: 53-01
    provides: Parapet.Spine.Schema.resolve_prefix/2 (pure core), resolve_prefix/1 (Igniter arity)
  - phase: 53-02
    provides: gen.spine Info flag surface + compose_task flag forwarding pattern
provides:
  - "parapet.install Info{schema, create_schema, defaults [schema: 'parapet', create_schema: true], aliases [s: :schema], group: :parapet} (GEN-04, GEN-05, D-08, D-15)"
  - "install --schema routing: compose_task('parapet.gen.spine') (no argv arg) propagates argv_flags to composed gen.spine via Igniter's default forwarding (GEN-05)"
  - "GEN-05 install leg tests: --schema custom routes to gen.spine; --no-create-schema omits sentinel"
  - "Optional DBA remediation pointer in install_summary_notice under --no-create-schema (D-15 fold)"
affects:
  - 53-04 (committed library migrations — install orchestrates the full stack including gen.spine)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Igniter compose_task flag forwarding: pass nil (omit second arg) so Igniter uses igniter.args.argv_flags; passing [] as second arg blocks forwarding because [] is truthy and overrides the default"
    - "Test argv_flags construction: build raw ['--flag', 'value'] list from options keyword in with_options helper so composed tasks can re-parse via parse_argv/1"
    - "async: false for install tests because Application.put_env is global and not safe in concurrent tests"
    - "group: :parapet disambiguation: --parapet.schema disambiguates when multiple composed tasks declare schema:; plain --schema works when no conflict"

key-files:
  created: []
  modified:
    - lib/mix/tasks/parapet.install.ex
    - test/mix/tasks/parapet.install_test.exs

key-decisions:
  - "compose_task('parapet.gen.spine') without explicit [] arg: Igniter's compose_task uses argv_flags from the parent igniter when no explicit argv is given (argv || igniter.args.argv_flags). Passing [] blocked forwarding because empty list is truthy in Elixir."
  - "with_options test helper extended with argv_flags: options: [schema: 'custom'] only sets the parsed map; composed tasks call parse_argv(argv_flags) so the helper must also set argv_flags to the equivalent raw flag list"
  - "D-15 fold: minimal one-line DBA remediation pointer added to install_summary_notice under --no-create-schema; does NOT duplicate the full GRANT block (gen.spine owns that via Igniter.add_notice)"
  - "no_create_schema? = options[:create_schema] == false (explicit false, not nil) — same 'create_schema != false' guard philosophy from Plan 02"

patterns-established:
  - "compose_task flag forwarding: omit argv arg (or pass nil) to let parent's argv_flags flow into composed task's parse_argv"
  - "Test flag forwarding: with_options must set both options: and argv_flags: for composed task tests to work"

requirements-completed: [GEN-04, GEN-05]

coverage:
  - id: D1
    description: "install Info struct exposes --schema/-s and --no-create-schema flags with group: :parapet (GEN-04, D-08, D-15)"
    requirement: GEN-04
    verification:
      - kind: unit
        ref: "test/mix/tasks/parapet.install_test.exs#declares the unified install contract and composed generators"
        status: pass
    human_judgment: false
  - id: D2
    description: "install --schema custom routes through group: :parapet to composed gen.spine; migration has prefix: 'custom' and config has schema_prefix: 'custom' (GEN-05)"
    requirement: GEN-05
    verification:
      - kind: unit
        ref: "test/mix/tasks/parapet.install_test.exs#GEN-05: --schema custom routes to composed gen.spine"
        status: pass
    human_judgment: false
  - id: D3
    description: "install --no-create-schema forwarded to composed gen.spine omits sentinel; DDL still prefix-stamped (GEN-04, GEN-05)"
    requirement: GEN-04
    verification:
      - kind: unit
        ref: "test/mix/tasks/parapet.install_test.exs#GEN-04/GEN-05: --no-create-schema forwarded to composed gen.spine"
        status: pass
    human_judgment: false
  - id: D4
    description: "install has no configure_new(:schema_prefix) and no resolve_prefix call — single write path is gen.spine (D-00, D-07, RESEARCH Open Question #3)"
    requirement: GEN-05
    verification:
      - kind: static
        ref: "grep configure_new|resolve_prefix|schema_prefix lib/mix/tasks/parapet.install.ex → clean"
        status: pass
    human_judgment: false

# Metrics
duration: 5min
completed: 2026-07-01
status: complete
---

# Phase 53 Plan 03: Install Orchestrator Schema Flag Surface Summary

**parapet.install now exposes --schema/-s and --no-create-schema via Info{group: :parapet} and forwards them to composed gen.spine via Igniter's default argv_flags propagation — completing the GEN-05 install leg without any second config-write or resolution path**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-01T15:43:58Z
- **Completed:** 2026-07-01T15:49:19Z
- **Tasks:** 2 (Task 1: install Info + optional notice fold; Task 2: GEN-05 install leg tests)
- **Files modified:** 2

## Accomplishments

- `parapet.install` `info/2` now declares `schema: :string` and `create_schema: :boolean` with `defaults: [schema: "parapet", create_schema: true]`, `aliases: [s: :schema]`, and `group: :parapet` — all existing UI/adapter switches preserved
- `compose_task("parapet.gen.spine", [])` changed to `compose_task("parapet.gen.spine")` so Igniter's default argv_flags propagation routes `--schema`/`--no-create-schema` into the composed gen.spine (Rule 1 bug fix)
- Optional DBA remediation pointer added to `install_summary_notice` under `--no-create-schema` (D-15 Claude's-discretion fold) — one line pointer only, full GRANT block stays in gen.spine's notice
- 2 new GEN-05 install leg tests added; all 5 install tests green
- Verified: install has NO `configure_new(:schema_prefix)` and NO `resolve_prefix` call — single write path is gen.spine as required (D-00, RESEARCH Open Question #3)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add schema/create_schema flags + group: :parapet to parapet.install Info** - `67f9299` (feat)
2. **Task 2: GEN-05 install leg tests + Rule 1 compose_task fix** - `7b6226f` (test)

## Files Created/Modified

- `/Users/jon/projects/parapet/lib/mix/tasks/parapet.install.ex` — Added schema/create_schema flags + group: :parapet to Info; optional DBA notice pointer; changed compose_task to forward argv_flags
- `/Users/jon/projects/parapet/test/mix/tasks/parapet.install_test.exs` — Added async: false; 2 new GEN-05 tests; extended with_options to set argv_flags; added dasherize/1 helper

## Decisions Made

- **compose_task(task) vs compose_task(task, [])**: Igniter's `compose_task/4` does `argv || igniter.args.argv_flags`. Passing `[]` explicitly set argv to `[]` (empty list is truthy in Elixir), blocking forwarding. Omitting the second arg (or passing `nil`) uses the parent's argv_flags. This is the correct semantics for flag forwarding via `group: :parapet`.
- **Test with_options must also set argv_flags**: The composed task calls `parse_argv(argv_flags)` to build its options. Setting only `options:` on the parent igniter struct doesn't help the child parse; the raw string flag list must also be set.
- **D-15 fold is minimal**: The DBA remediation pointer in install_summary_notice is a single-line reference ("gen.spine printed the exact CREATE SCHEMA and GRANT SQL"). The full GRANT block is NOT duplicated — gen.spine's Igniter.add_notice owns that copy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] compose_task("parapet.gen.spine", []) blocked flag forwarding**
- **Found during:** Task 2 (writing and running the GEN-05 forwarding test)
- **Issue:** `Igniter.compose_task("parapet.gen.spine", [])` passes `[]` as argv. In Igniter's `compose_task/4`, `argv || igniter.args.argv_flags` evaluates to `[]` (not `argv_flags`) because empty list is truthy in Elixir. This prevents `--schema` and `--no-create-schema` from ever reaching the composed gen.spine.
- **Fix:** Changed to `Igniter.compose_task("parapet.gen.spine")` (no explicit argv arg) so Igniter uses the default `igniter.args.argv_flags`, which carries the parsed flags from the CLI.
- **Files modified:** `lib/mix/tasks/parapet.install.ex`
- **Commit:** `7b6226f` (Task 2 commit)

**2. [Rule 1 - Bug] with_options test helper didn't set argv_flags**
- **Found during:** Task 2 (first test run failed because composed task had no flags)
- **Issue:** `with_options` only set `options:` on the igniter struct. The composed task calls `parse_argv(argv_flags)` to build its own args — options map from the parent struct doesn't flow through.
- **Fix:** Extended `with_options` to also construct `argv_flags` from the options keyword list (e.g. `[schema: "custom"]` → `["--schema", "custom"]`, `[create_schema: false]` → `["--no-create-schema"]`). Added `dasherize/1` helper.
- **Files modified:** `test/mix/tasks/parapet.install_test.exs`
- **Commit:** `7b6226f` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (Rule 1 bugs)
**Impact on plan:** Both fixes were necessary for the GEN-05 install leg to work. Without them, --schema would silently be ignored when install composes gen.spine.

## Issues Encountered

- Elixir's truthiness: `[] || other` returns `[]`, not `other`. An empty list is truthy. This is different from many languages and caused the forwarding bug in the existing compose_task call.
- Igniter's compose_task re-parses argv via `parse_argv/1` — it does NOT inherit the parent's `options` map directly. Test helpers must simulate the full argv → parse flow.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced.
T-53-03: install `--schema` → forwarded to composed gen.spine. Disposition: mitigate. Install performs no interpolation; the forwarded value is validated by `resolve_prefix` → `safe_ident!/1` inside gen.spine (Plan 01/02). No new untrusted-input sink added.

## Known Stubs

None. The flag surface is fully wired: install Info declares flags → argv_flags propagate → gen.spine receives and resolves them. All paths exercised by tests.

## Self-Check: PASSED

- FOUND: `lib/mix/tasks/parapet.install.ex`
- FOUND: `test/mix/tasks/parapet.install_test.exs`
- FOUND commit `67f9299` (feat - install Info flags)
- FOUND commit `7b6226f` (test - GEN-05 install leg)
- 5 tests pass (3 existing + 2 new), `mix compile --warnings-as-errors` clean
- VERIFIED: no `configure_new`, `resolve_prefix`, or `schema_prefix` in install.ex

---
*Phase: 53-generators-library-migrations*
*Completed: 2026-07-01*
