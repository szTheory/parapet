---
phase: 54-upgrade-path-doctor
verified: 2026-07-01T18:48:14Z
status: passed
score: 4/4
behavior_unverified: 0
overrides_applied: 0
---

# Phase 54: Upgrade Path & Doctor Verification Report

**Phase Goal:** Existing adopters have two tested, opt-in upgrade tracks — stay on `public`, or a reversible single-transaction `SET SCHEMA` move — plus a doctor preflight that catches the compile-time recompile footgun.
**Verified:** 2026-07-01T18:48:14Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Track A is pinned by a test proving `schema_prefix: nil` emits unprefixed SQL with green queries, and upgrading an existing adopter never forces a schema migration | VERIFIED | `describe "UPG-01 Track A"` block in `test/parapet/spine/prefix_propagation_test.exs` guarded by `if is_nil(@prefix)` — to_sql asserts bare `parapet_incidents` with no `"parapet".` qualifier; write-path round-trip asserts `Ecto.get_meta(incident, :prefix) == nil`. Fitness fn in `test/parapet/upgrade_never_forces_move_test.exs` scans 3 installer/generator files for move-task references. `resolve_prefix(nil, nil) == {:ok, "parapet"}` default pin asserted. Tests pass (5 on parapet leg, 7 on nil leg). |
| 2 | `mix parapet.gen.schema.move` generates a reversible migration with SET LOCAL lock_timeout, six explicit ALTER TABLE SET SCHEMA up/down, never DROP SCHEMA, pre-flight abort guard, inbound-FK advisory, second-move refusal, --no-create-schema support | VERIFIED | `lib/mix/tasks/parapet.gen.schema.move.ex` — full Igniter task verified: `after_begin/0` sets `SET LOCAL lock_timeout TO '5s'`; `move_migration_body/2` emits six explicit `ALTER TABLE public.<t> SET SCHEMA parapet` lines in up and six LIFO `ALTER TABLE parapet.<t> SET SCHEMA public` lines in down; DO-block RAISE EXCEPTION abort guard with `to_regclass + quote_ident`; inbound-FK/view NOTICE block; `on_exists: {:error, …}` second-move refusal; `create_schema` flag omits CREATE SCHEMA line. Golden test (10 assertions) and generator unit test (6 tests) both pass. Committed fixture `priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs` matches. |
| 3 | A Track B round-trip test against a throwaway DB proves: public → up → resolves under parapet (FK cascade + partial indexes intact) → down → restored to public | VERIFIED | `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` — dedicated `parapet_schema_move_roundtrip_test` DB via `storage_up/storage_down`; all 4 D-16 dimensions asserted: (a) table membership via `pg_class+pg_namespace`, (b) FK cascade behavior (insert parent+child, delete parent, assert child gone), (c) partial index `pg_get_expr` predicate check, (d) after down all six back in `public` and `parapet` schema exists but empty (no-DROP-SCHEMA). Abort leg asserts `Postgrex.Error` and nothing moved. 2/2 tests pass. |
| 4 | A `mix parapet.doctor` check compares runtime `:schema_prefix` against the compiled `@schema_prefix`, fails CI-grade under `--ci` on drift with `mix deps.compile parapet --force` remediation, and verifies the configured schema exists | VERIFIED | `lib/mix/tasks/parapet.doctor.ex` — `"schema"` in `@static_checks` (default suite, not opt-in cluster mode); `check_schema/0` (@doc false public) implements double-normalize drift comparison, parameterized `SELECT to_regnamespace($1) IS NOT NULL` existence probe, `Process.whereis == nil` repo-not-running guard degrades to `:skip`. D-04 remediation microcopy present. Unit test `test/parapet/doctor_schema_check_test.exs` (6 tests) covers drift/:error, no-false-positive, skip-nil-repo, skip-absent-process, severity contract. All 6 pass. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/parapet.doctor.ex` | "schema" in @static_checks; check_schema/0 with drift+existence | VERIFIED | 21,584 bytes; @static_checks includes "schema"; `check_schema/0` @doc false public; parameterized to_regnamespace probe; Process.whereis guard; D-04 microcopy strings |
| `test/parapet/doctor_schema_check_test.exs` | drift/missing/skip/exit-code unit coverage | VERIFIED | 8,095 bytes; 6 tests; async: false; @prefix branching for both CI legs; all tests pass |
| `lib/parapet/spine/schema_move_notice.ex` | Shared DBA least-privilege notice helper | VERIFIED | 2,397 bytes; `Parapet.Spine.SchemaMoveNotice` with `emit_for_spine/3` and `emit_for_move/3`; `gen.spine` delegates to it |
| `lib/mix/tasks/parapet.gen.schema.move.ex` | Full Igniter task with info/2, igniter/1, move_migration_body/2 | VERIFIED | 9,137 bytes; info/2 mirrors gen.spine; nil-leg zero-diff notice; on_exists: {:error,...}; after_begin; 6 explicit up/down ALTERs; no DROP SCHEMA |
| `priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs` | Committed fixture with fixed module name | VERIFIED | 4,805 bytes; `Parapet.Repo.Migrations.MoveParapetSpineToSchema`; real timestamp 20260701000000; six explicit ALTERs each direction |
| `test/parapet/gen_schema_move_golden_test.exs` | DB-less shape assertions on committed fixture | VERIFIED | 6,721 bytes; 10 shape assertions (6 SET SCHEMA parapet, 6 SET SCHEMA public, after_begin, lock_timeout, no @disable_ddl_transaction, no execute(DROP SCHEMA), RAISE EXCEPTION, to_regclass probe, all 6 tables in both directions) |
| `test/parapet/gen_schema_move_test.exs` | Generator unit tests (nil-leg wiring, second-move refusal) | VERIFIED | 10,459 bytes; 6 tests; source-wiring assertions for nil-leg and second-move refusal; Igniter.Test integration test proves on_exists fires |
| `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` | Track B round-trip test against throwaway DB | VERIFIED | 18,779 bytes; 467 lines; 2 @tag :unboxed tests; dedicated throwaway DB; all six fixture tables; 4 D-16 dimensions; abort leg |
| `test/parapet/spine/prefix_propagation_test.exs` | UPG-01 Track A describe block (nil-leg guard) | VERIFIED | 6,970 bytes; `describe "UPG-01 Track A"` block wrapped in `if is_nil(@prefix)`; to_sql + write-path assertions; 5 tests on parapet leg, 7 on nil leg |
| `test/parapet/upgrade_never_forces_move_test.exs` | UPG-05 fitness function + default-prefix pin | VERIFIED | 6,545 bytes; 2 tests; @installer_files explicit list; 2 @forbidden_move_patterns; resolve_prefix(nil, nil) == {:ok, "parapet"} pin |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `parapet.doctor.ex check_schema/0` | `Parapet.Spine.Schema.__prefix__/0` and `normalize/1` | Double-normalize drift guard — both runtime and compiled sides run through `normalize/1` | WIRED | Lines 527-528: `compiled = Parapet.Spine.Schema.__prefix__()`, `runtime = Parapet.Spine.Schema.normalize(Application.get_env(:parapet, :schema_prefix))` |
| `parapet.doctor.ex check_schema/0` | Postgres catalog | Parameterized `SELECT to_regnamespace($1) IS NOT NULL` with bound `[target]` | WIRED | Line 542: `repo.query!("SELECT to_regnamespace($1) IS NOT NULL", [target])` — never string-interpolated |
| `parapet.gen.schema.move.ex igniter/1` | `Parapet.Spine.Schema.resolve_prefix/1` | Shared prefix resolver — flag > config > default precedence via resolve_prefix(igniter) | WIRED | Lines 73-87: `case Parapet.Spine.Schema.resolve_prefix(igniter)` with conflict warning |
| `parapet.gen.schema.move.ex igniter/1` | `Parapet.Spine.SchemaMoveNotice.emit_for_move/3` | DBA notice single-sourced (D-12b) | WIRED | Line 101: `Parapet.Spine.SchemaMoveNotice.emit_for_move(igniter, resolved, create_schema)` |
| `parapet.gen.spine.ex maybe_emit_dba_notice/3` | `Parapet.Spine.SchemaMoveNotice.emit_for_spine/3` | DBA notice delegated to shared helper | WIRED | gen.spine.ex line 212: `Parapet.Spine.SchemaMoveNotice.emit_for_spine(igniter, resolved, create_schema)` |
| `move_spine_to_parapet_schema_test.exs` | `priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs` | `Code.require_file` — same fixture shared by golden test and round-trip test (D-13) | WIRED | Lines 34-37: `Code.require_file("../../../../priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs", __DIR__)` |
| `gen_schema_move_golden_test.exs` | `priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs` | `File.read!(@fixture_path)` — DB-less shape assertions on the same committed fixture | WIRED | @fixture_path resolves to the committed fixture; `setup_all` reads it |
| `prefix_propagation_test.exs UPG-01 block` | `if is_nil(@prefix)` compile-time guard | Entire describe block is a no-op on parapet leg, load-bearing on nil leg | WIRED | Lines 113-145: `if is_nil(@prefix) do / describe … / end` at module level |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces Mix tasks, migration generators, and test files. No UI components or pages that render dynamic data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| DB-less tests: doctor check + golden test + UPG-05 fitness fn | `mix test test/parapet/doctor_schema_check_test.exs test/parapet/gen_schema_move_golden_test.exs test/parapet/upgrade_never_forces_move_test.exs` | 18 tests, 0 failures | PASS |
| Generator unit tests (nil-leg wiring, second-move refusal) | `mix test test/parapet/gen_schema_move_test.exs` | 6 tests, 0 failures | PASS |
| Track A prefix propagation (parapet leg — UPG-01 block no-op) | `mix test test/parapet/spine/prefix_propagation_test.exs` | 5 tests, 0 failures | PASS |
| Track B round-trip DB test (throwaway DB, up/down + abort leg) | `mix test test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` | 2 tests, 0 failures | PASS |

All tests run against the parapet leg (PARAPET_SCHEMA_PREFIX=parapet). The Track A nil-leg block and doctor tests are dual-leg aware via @prefix guards and were confirmed green by the executor on both legs.

### Probe Execution

No formal probe scripts declared or conventional.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|------------|------------|-------------|--------|---------|
| UPG-01 | 54-04 | Track A (stay on public) pinned by test proving schema_prefix: nil emits unprefixed SQL | SATISFIED | `describe "UPG-01 Track A"` block in prefix_propagation_test.exs; to_sql + get_meta assertions; guarded by is_nil(@prefix) |
| UPG-02 | 54-02 | mix parapet.gen.schema.move generates reversible SET SCHEMA migration | SATISFIED | parapet.gen.schema.move.ex fully implemented; committed fixture with after_begin, abort guard, 6 explicit ALTERs each direction, no DROP SCHEMA |
| UPG-03 | 54-02, 54-03 | Pre-flight catalog detections: abort on missing tables, FK/view advisory, second-move refusal | SATISFIED | DO-block RAISE EXCEPTION abort guard in migration; inbound-FK NOTICE block; on_exists: {:error,...} refusal; DB-level abort proven in round-trip test |
| UPG-04 | 54-03 | Track B round-trip test against throwaway DB | SATISFIED | move_spine_to_parapet_schema_test.exs: 2 tests, dedicated throwaway DB, FK cascade + partial index + no-DROP-SCHEMA proofs |
| UPG-05 | 54-04 | Upgrading existing adopter never forces schema migration | SATISFIED | upgrade_never_forces_move_test.exs: fitness fn over 3 installer/generator files + resolve_prefix(nil,nil) default pin |
| DOCTOR-01 | 54-01 | mix parapet.doctor schema check: drift + existence + CI-grade failure | SATISFIED | check_schema/0 in parapet.doctor.ex; double-normalize drift, parameterized existence probe, Process.whereis skip guard; 6 unit tests all pass |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | None found |

No `TBD`, `FIXME`, `XXX` markers in any phase-modified file. No stub returns, placeholder renders, or `@disable_ddl_transaction` in the committed migration. The golden test negative assertion for `DROP SCHEMA` correctly strips comment lines before the regex check (auto-fixed deviation documented in 54-02-SUMMARY.md).

### Human Verification Required

None. All must-haves are verified by automated tests that pass. Track A nil-leg tests were confirmed green on both CI legs by the executor; the verifier confirmed green on the parapet leg and confirmed the nil-leg guard structure is correct (compile-time `if is_nil(@prefix)` block).

### Gaps Summary

No gaps. All four roadmap success criteria are verified against the actual codebase:

1. **Track A + UPG-05** — test file present, wired, passing (5 tests on parapet leg; fitness fn + default-prefix pin confirmed)
2. **gen.schema.move** — task implementation present, substantive (full info/2 + igniter/1 + move_migration_body/2), wired via resolve_prefix chain and SchemaMoveNotice delegation, golden test + generator unit test both pass
3. **Track B round-trip** — round-trip test present, substantive (467 lines, 4 D-16 dimensions, abort leg), wired via Code.require_file to committed fixture, 2/2 tests pass
4. **Doctor schema check** — check_schema/0 present, substantive (drift + existence + skip), wired into @static_checks dispatch, 6/6 unit tests pass

---

_Verified: 2026-07-01T18:48:14Z_
_Verifier: Claude (gsd-verifier)_
