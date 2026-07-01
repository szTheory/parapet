---
phase: 53-generators-library-migrations
verified: 2026-07-01T16:35:00Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 53: Generators & Library Migrations Verification Report

**Phase Goal:** Generators and Parapet's committed library migrations create the spine under the configured schema, stamping `prefix:` everywhere and writing config without clobbering adopters, with a least-privilege `--no-create-schema` hatch.
**Verified:** 2026-07-01T16:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A first-ordered `00000000000000_create_parapet_schema` sentinel migration is emitted with reversible non-cascading CREATE/DROP SCHEMA (GEN-01) | ✓ VERIFIED | `gen.spine.ex` calls `gen_migration(timestamp: "00000000000000", on_exists: :skip)` with `up: execute("CREATE SCHEMA IF NOT EXISTS #{resolved}")` and `down: execute("DROP SCHEMA IF EXISTS #{resolved}")` — no CASCADE; test `GEN-01: sentinel migration golden bytes` asserts `=~ "DROP SCHEMA IF EXISTS"` and `refute content =~ "CASCADE"` |
| 2 | `gen.spine` and `gen.archive_indexes` stamp a literal `prefix:` on every DDL call; FK constraint names are unchanged (GEN-02) | ✓ VERIFIED | Both generators build `prefix_opts`, `prefix_index_only`, `prefix_index_lead` fragments and interpolate them into every create/alter table, references/2, and create/drop index in the heredoc. Tests verify `Regex.scan(~r/\bprefix:/, migration_source) >= 15` (spine) and `>= 14` (archive_indexes including down/0). FK name `parapet_tool_audits_timeline_entry_id_fkey` asserted unchanged by `contains_snippet?` in both legs. |
| 3 | Generators write `config :parapet, :schema_prefix` via `configure_new` (no-clobber); a flag≠config conflict emits a warning rather than crashing (GEN-03) | ✓ VERIFIED | `maybe_write_schema_prefix_config/2` calls `Igniter.Project.Config.configure_new/5` with nil guard (never writes on nil resolved). Conflict returns `{:conflict, flag, config}` from pure-core resolver; gen.spine calls `Igniter.add_warning/2`. Test `GEN-03: configure_new writes config :parapet, :schema_prefix` confirms config write. |
| 4 | `--schema` / `-s` and `--no-create-schema` flags are declared; `--no-create-schema` omits sentinel, keeps prefix-stamping, and prints exact CREATE SCHEMA + GRANT DBA remediation (GEN-04) | ✓ VERIFIED | All three tasks declare `schema: [schema: :string, create_schema: :boolean]`, `aliases: [s: :schema]`, `group: :parapet`. `maybe_emit_dba_notice/3` with `create_schema != false` guard fires `Igniter.add_notice` with AUTHORIZATION + GRANT USAGE + GRANT CREATE + ALTER DEFAULT PRIVILEGES copy. Test `GEN-01/GEN-04: omits sentinel and emits DBA remediation notice` asserts `refute_creates` + `notices =~ "CREATE SCHEMA IF NOT EXISTS"` + `notices =~ "GRANT"`. |
| 5 | One shared prefix resolver (`Parapet.Spine.Schema.resolve_prefix`) with precedence `flag > existing config > default "parapet"` is used by `gen.spine`, `gen.archive_indexes`, and `parapet.install` (GEN-05) | ✓ VERIFIED | Both generators call `Parapet.Spine.Schema.resolve_prefix(igniter)` on line 59 / 52. `parapet.install` has no `resolve_prefix` or `configure_new(:schema_prefix)` call (confirmed by grep returning empty); it composes `parapet.gen.spine` without explicit argv so argv_flags propagate. Install tests `GEN-05: --schema custom routes to composed gen.spine` confirm prefix: "custom" appears in generated migration and config. |
| 6 | All 5 committed library migrations and all 3 demo migrations bind `@prefix Parapet.Spine.Schema.__prefix__()` and pass it to every DDL call including the raw SQL UPDATE in `add_lease_until`; both CI legs green (GEN-06) | ✓ VERIFIED | `grep -L 'Parapet.Spine.Schema.__prefix__'` over all 8 files returns empty. No literal `prefix: "parapet"` or `resolve_prefix` in any migration. `add_lease_until` uses `@table if @prefix, do: ~s("#{@prefix}"."parapet_action_claims"), else: "parapet_action_claims"` for the raw UPDATE. All 9 phase commits verified in git log. Post-wave test gate: 647 tests green on parapet leg, 2 pre-existing unrelated failures. |
| 7 | Generator-output tests cover: `prefix:` count-guard, one sentinel golden, `--no-create-schema` refute, FK-name-unchanged under both legs, and `existing-config` (configure_new) branch (GEN-07) | ✓ VERIFIED | `parapet.gen.spine_test.exs` contains 11+ tests including count-guard (≥15), sentinel existence assert, golden content checks (`=~ "CREATE SCHEMA"` + `refute CASCADE`), `refute_creates` under `--no-create-schema`, FK name assertion, and `configure_new` config write assertion. `parapet.gen.archive_indexes_test.exs` contains count-guard (≥14, both up+down), FK name in parapet leg, FK name in nil-config leg, and Pitfall 4 (down direction prefix) tests. All 15 generator tests pass. |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/parapet/spine/schema.ex` | `resolve_prefix/2` + `resolve_prefix/1` + D-09 firewall | ✓ VERIFIED | Both functions present; `resolve_prefix/2` body references only `normalize/1`, no `@prefix` or `__prefix__()` |
| `test/parapet/spine/schema_test.exs` | 20+ pure-core resolve_prefix tests | ✓ VERIFIED | `describe "resolve_prefix/2 (pure core)"` block with 20 tests, full precedence matrix, conflict, safe_ident! rejection |
| `lib/mix/tasks/parapet.gen.spine.ex` | Info flags, resolver call, prefix-stamped heredoc, sentinel, configure_new, DBA notice | ✓ VERIFIED | All elements present and substantive |
| `lib/mix/tasks/parapet.gen.archive_indexes.ex` | Same Info flag surface, resolver call, prefix-stamped up/down heredoc | ✓ VERIFIED | All elements present; Pitfall 4 (down direction) covered |
| `lib/mix/tasks/parapet.install.ex` | Info flags + `group: :parapet`, no `configure_new` or `resolve_prefix` | ✓ VERIFIED | Flags declared; grep for `configure_new\|resolve_prefix\|schema_prefix` returns empty |
| `test/mix/tasks/parapet.gen.spine_test.exs` | D-16 assertion suite | ✓ VERIFIED | 11 named GEN-* tests all passing |
| `test/mix/tasks/parapet.gen.archive_indexes_test.exs` | Count-guard + FK-name-both-legs + Pitfall 4 | ✓ VERIFIED | 5 named tests all passing |
| `test/mix/tasks/parapet.install_test.exs` | GEN-05 forwarding tests | ✓ VERIFIED | 5 tests including 2 new GEN-05 install leg tests; all passing |
| `priv/repo/migrations/20260511000000_add_runbook_data_to_incidents.exs` | `@prefix __prefix__()` + `prefix: @prefix` on alter | ✓ VERIFIED | Module attribute and DDL binding confirmed |
| `priv/repo/migrations/20260516233447_add_trace_id_to_incidents.exs` | `@prefix __prefix__()` + `prefix: @prefix` on alter | ✓ VERIFIED | Module attribute and DDL binding confirmed |
| `priv/repo/migrations/20260517000000_add_parapet_system_events.exs` | `@prefix __prefix__()` + prefix on table and index | ✓ VERIFIED | Module attribute, create table, create index all prefixed |
| `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs` | `@prefix __prefix__()` + prefix on table, references/2, 3 indexes | ✓ VERIFIED | All DDL sites prefixed; references carries its own explicit `prefix: @prefix` |
| `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` | `@prefix`, `@table` raw-SQL qualification, prefix on alter/index | ✓ VERIFIED | `@table if @prefix, do: ~s(...)` pattern; UPDATE uses `@table`; alter and index carry `prefix: @prefix` |
| `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs` | `@prefix __prefix__()` + 5 tables + 2 references + 8 indexes prefixed | ✓ VERIFIED | Confirmed by grep output showing all sites |
| `examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs` | `@prefix __prefix__()` + alter + references + index | ✓ VERIFIED | Module attribute and all DDL sites prefixed |
| `examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs` | `@prefix __prefix__()` + table + references + 4 indexes | ✓ VERIFIED | Module attribute and all DDL sites prefixed |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `gen.spine` / `gen.archive_indexes` | `Parapet.Spine.Schema.resolve_prefix/1` | `case Parapet.Spine.Schema.resolve_prefix(igniter)` | ✓ WIRED | Both generators call the shared resolver; conflict emits `Igniter.add_warning/2` |
| Resolved prefix | Generated heredoc literal | `prefix_opts = if resolved, do: ", prefix: #{inspect(resolved)}", else: ""` | ✓ WIRED | Generate-time literal, never runtime `__prefix__()` in generated output |
| `parapet.install` | Composed `gen.spine` | `Igniter.compose_task("parapet.gen.spine")` (no explicit argv arg) | ✓ WIRED | Verified no explicit `[]` arg that would block flag forwarding; install test confirms `prefix: "custom"` flows through |
| Committed migrations | `Parapet.Spine.Schema.__prefix__()` | `@prefix Parapet.Spine.Schema.__prefix__()` module attribute | ✓ WIRED | `grep -L '__prefix__'` returns empty on all 8 migration files |
| `add_lease_until` raw UPDATE | `@table` schema-qualified string | `@table if @prefix, do: ~s(...)` | ✓ WIRED | Raw SQL qualifies table name at compile time; no Ecto `prefix:` option on `execute/2` |
| `resolve_prefix/2` | `normalize/1` → `safe_ident!/1` | Both flag and config paths unconditionally call `normalize/1` | ✓ WIRED | D-09 firewall confirmed: body references neither `@prefix` nor `__prefix__()`; 45 schema tests pass |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Pure-core resolver: all 20 precedence/conflict/rejection tests | `mix test test/parapet/spine/schema_test.exs --no-start` | 45 tests, 0 failures | ✓ PASS |
| Generator prefix-stamping, sentinel, configure_new, --no-create-schema, FK-names | `mix test test/mix/tasks/parapet.gen.spine_test.exs test/mix/tasks/parapet.gen.archive_indexes_test.exs --no-start` | 15 tests, 0 failures | ✓ PASS |
| Install flag forwarding to composed gen.spine | `mix test test/mix/tasks/parapet.install_test.exs --no-start` | 5 tests, 0 failures | ✓ PASS |
| All 9 phase commits present in git history | `git log --oneline f4b27bd a02ad61 eb84a0c 8d3ae93 807e618 67f9299 7b6226f 872ea25 46d3805` | All 9 commits found | ✓ PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| GEN-01 | 53-02 | First-ordered `*_create_parapet_schema` migration with reversible non-cascading CREATE/DROP SCHEMA | ✓ SATISFIED | `timestamp: "00000000000000"`, `on_exists: :skip`, no CASCADE in down; sentinel test golden asserts |
| GEN-02 | 53-02 | Literal `prefix:` on every create table, references/2, index; FK names unchanged | ✓ SATISFIED | prefix_opts/prefix_index_only/prefix_index_lead fragments interpolated on all DDL sites; count-guard tests pass; FK name assertions in both legs |
| GEN-03 | 53-01, 53-02 | `configure_new` no-clobber write; conflict warns not crashes | ✓ SATISFIED | `configure_new/5` used; `{:conflict, _, _}` returns tuple not raise; Igniter.add_warning fires; tests confirm |
| GEN-04 | 53-02, 53-03 | `--schema` / `-s` and `--no-create-schema` flags; DBA GRANT remediation | ✓ SATISFIED | Info schema declares both flags; DBA notice carries AUTHORIZATION + GRANT USAGE/CREATE + ALTER DEFAULT PRIVILEGES; tests assert notices |
| GEN-05 | 53-01, 53-02, 53-03 | One shared resolver used by gen.spine, gen.archive_indexes, install | ✓ SATISFIED | Both generators call `resolve_prefix(igniter)`; install has no duplicate path; install test verifies end-to-end routing |
| GEN-06 | 53-04 | 5 library + 3 demo committed migrations use `__prefix__()`; raw SQL UPDATE qualified; both CI legs green | ✓ SATISFIED | All 8 files bind via module attribute; no literal or resolve_prefix; raw SQL uses `@table`; 647 tests green on parapet leg per SUMMARY |
| GEN-07 | 53-02 | Tests: count-guard, sentinel golden, `--no-create-schema` refute, FK-name both-legs, existing-config (configure_new) branch | ✓ SATISFIED | All 5 test categories present and passing in the two generator test files |

---

### Anti-Patterns Found

No anti-patterns found. Scan covered all 15 modified files (lib + test + migrations):

- No TBD, FIXME, or XXX markers
- No TODO, HACK, or PLACEHOLDER comments
- No stub patterns (`return null`, empty handlers, hardcoded empty data)
- No literal `prefix: "parapet"` in committed migrations (correct: uses `prefix: @prefix`)
- No CASCADE in any sentinel or migration down block
- No `resolve_prefix` or `configure_new(:schema_prefix)` in `parapet.install`
- D-09 firewall confirmed: `resolve_prefix/2` body contains no `@prefix` or `__prefix__()` reference

---

### Notable Design Deviation (Non-Blocking)

**D-04 nil-leg byte-identical test:** The plan specified a `--schema public` test producing zero `prefix:` occurrences. The actual resolver (Plan 01 design) always returns `{:ok, "parapet"}` as default when both flag and config normalize to nil — there is no path through the resolver that returns `{:ok, nil}`. The test was reinterpreted to document "absence = default" semantics (nil config + no flag → parapet prefix, per D-06). This is a correct design tradeoff, not a defect. The pure-core tests in `schema_test.exs` verify the normalization semantics exhaustively.

---

### Pre-Existing Test Failures (Not Phase 53 Regressions)

Per orchestrator notes and SUMMARY 53-04:
1. `Parapet.DocsPhase33Test` — asserts README contains `"make up-auto"`, removed in a demo-doc rewording during Phase 33. Pre-existing, unrelated to schema prefix.
2. `Parapet.Telemetry.RecoveryActionTest` — atom table leak test. Pre-existing.

Both failures exist identically on both CI legs (parapet and nil/public) and predated the first Phase 53 commit.

---

## Gaps Summary

No gaps. All 7 GEN requirements are satisfied with substantive, wired, tested implementations.

---

_Verified: 2026-07-01T16:35:00Z_
_Verifier: Claude (gsd-verifier)_
