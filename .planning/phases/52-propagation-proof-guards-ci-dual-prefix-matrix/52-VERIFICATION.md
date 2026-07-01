---
phase: 52-propagation-proof-guards-ci-dual-prefix-matrix
verified: 2026-06-30T22:00:00Z
status: passed
score: 10/10
behavior_unverified: 0
overrides_applied: 0
re_verification: null
---

# Phase 52: Propagation Proof, Guards & CI Dual-Prefix Matrix — Verification Report

**Phase Goal:** Prove the compiled prefix propagates across every read/write path (selects, joins, insert_all, Ecto.Multi) with zero call-site changes; make runtime `prefix:` and prefix-dropping writes impossible to reintroduce via a static guard; and validate both `parapet` and `public` legs honestly in a CI matrix that recompiles per value.

**Verified:** 2026-06-30T22:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Regression tests prove the prefix rides the two spine↔spine joins (mcp/server.ex, circuit_breaker.ex), claim_service insert_all, and evidence.ex Ecto.Multi — zero call-site edits | VERIFIED | `prefix_propagation_test.exs`: two `to_sql` asserts on timeline_for_correlation_query + execution_count_query (FROM+JOIN tokens), two `Ecto.get_meta` asserts on claim_action insert_all and create_incident Multi. Rides real builders, not inline rebuilds. |
| 2 | to_sql/get_meta assertions show compiled prefix on selects/joins/insert_all/Multi; negative "no bare parapet_incidents" assertion under prefixed leg; six schemas agree | VERIFIED | `prefix_propagation_test.exs`: to_sql asserts `"parapet"."parapet_timeline_entries"` and `"parapet"."parapet_incidents"` (FROM+JOIN); negative `refute sql =~ ~r/(?<!"parapet")\.parapet_incidents/` gated behind `if @prefix`; six-schema loop asserts `mod.__schema__(:prefix) == prefix` unconditionally |
| 3 | Static guard fails the build if runtime prefix: / string-table writes / search_path / raw parapet_ SQL appear in lib/parapet/; green from day one | VERIFIED | `schema_prefix_guard_test.exs`: `Path.wildcard("lib/parapet/**/*.ex")` scope (excludes mix/tasks/); four D-03 fingerprints (a)–(d); WR-04 fix applied — strip_trailing_comment now uses `~r/^([^#]*)/` so pattern (d) sees string literal content; teaching failure message with read/write split-brain explanation |
| 4 | CI matrix adds schema_prefix axis: parapet×OTP 26/27/28 plus public×OTP 28; net +1 cell (3→4) | VERIFIED | `ci.yml` lines 67–74: `schema_prefix: ['parapet']` in matrix, `matrix.include` entry `{elixir: '1.19.0', otp: '28.x', schema_prefix: 'public'}` |
| 5 | Each CI cell injects PARAPET_SCHEMA_PREFIX and runs mix compile --force before mix test | VERIFIED | `ci.yml` line 77: `PARAPET_SCHEMA_PREFIX: ${{ matrix.schema_prefix }}` in job env; line 113–114: "Compile (force recompile under this prefix leg): mix compile --force" step before Test step |
| 6 | _build cache key AND restore-keys namespaced by schema_prefix; deps cache unchanged; fail-fast: false | VERIFIED | `ci.yml` lines 109–110: key contains `${{ matrix.schema_prefix }}-` between otp and mix.lock-hash; deps cache (lines 100–104) unchanged; line 66: `fail-fast: false` |
| 7 | In-suite leg guard (compiled_prefix_leg_test.exs) asserts Schema.__prefix__() == normalize(env) — tripwire against _build false-green | VERIFIED | `compiled_prefix_leg_test.exs`: `@env_prefix System.get_env("PARAPET_SCHEMA_PREFIX", "parapet")`, `@compiled_prefix Parapet.Spine.Schema.__prefix__()`, test asserts `@compiled_prefix == Parapet.Spine.Schema.normalize(@env_prefix)` with cache-restore failure message |
| 8 | --no-validate-compile-env NOT passed anywhere in CI | VERIFIED | `grep -c "no-validate-compile-env" .github/workflows/ci.yml` → 0 |
| 9 | Exactly one normalization source: Schema.Normalizer.normalize/1 + safe_ident!/1, called by @prefix attribute, Evidence.schema_prefix/0 delegation, and ConcurrencyBootstrap @prefix | VERIFIED | `schema.ex`: Normalizer submodule defined before Schema module; `@prefix Parapet.Spine.Schema.Normalizer.normalize(@raw_prefix)`; `defdelegate normalize/1` on Schema; `evidence.ex` body: `Parapet.Spine.Schema.__prefix__()`; `concurrency_bootstrap.ex`: `@prefix Parapet.Spine.Schema.normalize(@raw_prefix)`; inline case blocks removed from all three |
| 10 | Agreement test drives production code with no test-local mirror functions; evidence tests assert frozen compile-time value | VERIFIED | `schema_test.exs`: agreement describe maps `@input_set` through `Parapet.Spine.Schema.normalize/1` (not a mirror); `grep -c "normalize_prefix\|config_normalize_prefix" schema_test.exs` → 0; `evidence_test.exs` schema_prefix/0 describe: asserts frozen value + ignores Application.put_env |

**Score:** 10/10 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/parapet/spine/schema.ex` | Normalizer submodule + normalize/1 + safe_ident!/1 + @prefix via Normalizer | VERIFIED | Normalizer defined at top of file; defdelegate on Schema; @prefix = Normalizer.normalize(@raw_prefix) |
| `lib/parapet/evidence.ex` | schema_prefix/0 delegates to Schema.__prefix__() | VERIFIED | Body: `Parapet.Spine.Schema.__prefix__()` (line 42); no Application.get_env for prefix |
| `lib/parapet/mcp/server.ex` | timeline_for_correlation_query/1 extracted as @doc false builder | VERIFIED | Lines 65–72: `@doc false def timeline_for_correlation_query/1`; execute_tool/2 calls `repo.all(timeline_for_correlation_query(correlation_key))` |
| `test/support/concurrency_bootstrap.ex` | @prefix routes through Schema.normalize/1 | VERIFIED | Line 11: `@prefix Parapet.Spine.Schema.normalize(@raw_prefix)`; no inline case block |
| `test/parapet/spine/schema_test.exs` | Agreement test drives production code; mirrors deleted; CR-01 fix applied | VERIFIED | `@compiled_prefix` module attribute; six individual schema tests use `@compiled_prefix`; parapet-specific tests wrapped in `if @compiled_prefix == "parapet" do`; no normalize_prefix/config_normalize_prefix |
| `test/parapet/evidence_test.exs` | schema_prefix/0 describe asserts frozen value; WR-01 on_exit cleanup present | VERIFIED | Lines 202–221: three tests asserting compiled value, frozen against put_env, agrees with Schema.__prefix__(); lines 171–172 and 240–241: both :dual_write tests have on_exit cleanup |
| `test/parapet/schema_prefix_guard_test.exs` | PROP-02 guard: four fingerprints, correct scope, WR-04 fix | VERIFIED | Path.wildcard scope confirmed; four D-03 patterns present; strip_trailing_comment uses `~r/^([^#]*)/` (WR-04 fixed) |
| `test/parapet/spine/prefix_propagation_test.exs` | PROP-01/PROP-03 proof: to_sql (two joins) + get_meta (insert_all + Multi) + six-schema equality | VERIFIED | Two to_sql calls on real builders; two Ecto.get_meta asserts; six-schema equality loop; no to_sql(:insert_all); leg-aware negative assertion |
| `test/parapet/spine/compiled_prefix_leg_test.exs` | D-14 in-suite false-green tripwire | VERIFIED | Reuses Schema.normalize/1; asserts @compiled_prefix == normalize(@env_prefix); failure message teaches cache remedy |
| `.github/workflows/ci.yml` | schema_prefix matrix axis; namespaced _build cache; --force compile; fail-fast: false; no --no-validate-compile-env | VERIFIED | All five checks confirmed; YAML valid (python3 -c yaml.safe_load → VALID) |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `@prefix` in schema.ex | `Parapet.Spine.Schema.Normalizer.normalize/1` | Module attribute assignment at compile time | VERIFIED | Line 86: `@prefix Parapet.Spine.Schema.Normalizer.normalize(@raw_prefix)` |
| `Evidence.schema_prefix/0` | `Parapet.Spine.Schema.__prefix__/0` | Direct delegation in function body | VERIFIED | Line 42: `Parapet.Spine.Schema.__prefix__()` |
| `ConcurrencyBootstrap @prefix` | `Parapet.Spine.Schema.normalize/1` | Module attribute assignment | VERIFIED | Line 11: `@prefix Parapet.Spine.Schema.normalize(@raw_prefix)` |
| `prefix_propagation_test.exs` | `Parapet.MCP.Server.timeline_for_correlation_query/1` | Direct call to real extracted builder | VERIFIED | Line 23: `Server.timeline_for_correlation_query("key-123")`; grep count = 2 |
| `prefix_propagation_test.exs @prefix` | `Parapet.Spine.Schema.__prefix__/0` | Module attribute at compile time (D-09) | VERIFIED | Line 14: `@prefix Parapet.Spine.Schema.__prefix__()` |
| `compiled_prefix_leg_test.exs` | `Parapet.Spine.Schema.normalize/1` | Called in test body to compute expected value | VERIFIED | Line 32: `expected = Parapet.Spine.Schema.normalize(@env_prefix)` |
| CI matrix `PARAPET_SCHEMA_PREFIX` | `mix compile --force` | Job-level env injection before force recompile step | VERIFIED | `ci.yml` lines 77, 113–114 |
| `_build cache key` | `${{ matrix.schema_prefix }}` | Key interpolation separating legs | VERIFIED | `ci.yml` line 109: key and line 110: restore-keys both contain schema_prefix segment |

---

### Data-Flow Trace (Level 4)

No dynamic-data-rendering artifacts in this phase (no UI components, no API routes with DB queries). All artifacts are either pure compile-time validators, ExUnit tests, or CI YAML configuration. Level 4 not applicable.

---

### Behavioral Spot-Checks

Not runnable without a database (tests require PostgreSQL via ConcurrencyCase sandbox). The empirical test results cited in the phase context are accepted as behavioral evidence:

| Behavior | Evidence | Status |
|----------|----------|--------|
| Parapet leg full suite | 612 tests / 1 failure (known pre-existing DocsPhase33Test, pre-dates phase 52, touches none of phase 52 files) | PASS |
| Public leg (PARAPET_SCHEMA_PREFIX="") schema_test | 23 tests / 0 failures (CR-01 fix confirmed: parapet-specific tests correctly skipped on public leg) | PASS |
| PROP-02 guard | Green on current lib/parapet/ tree; scratch `prefix: "public"` edit triggers failure | PASS |
| compiled_prefix_leg_test.exs | 1 test, 0 failures on parapet leg | PASS |

**Pre-existing failure excluded:** `Parapet.DocsPhase33Test` (README `make up-auto` → `make up` docs drift) was confirmed present before any Phase 52 changes, touches none of the phase 52 modified files, and does not count against the phase goal.

---

### Probe Execution

No probe scripts declared or applicable for this phase.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PROP-01 | 52-01, 52-03 | Prefix auto-propagates across Repo.*, insert_all, Ecto.Multi, and two spine↔spine joins — pinned by regression tests | SATISFIED | `prefix_propagation_test.exs`: to_sql FROM+JOIN proofs on both join builders; get_meta proofs on insert_all and Multi |
| PROP-02 | 52-02 | Runtime prefix: banned by static guard over lib/; flags string-table writes, search_path, raw parapet_ SQL; fails build with actionable message | SATISFIED | `schema_prefix_guard_test.exs`: four D-03 fingerprints; Path.wildcard excludes mix/tasks/; teaching failure message; WR-04 fix makes pattern (d) functional |
| PROP-03 | 52-03 | to_sql/Ecto.get_meta assertions on every test leg; negative bare-table assertion; __schema__(:prefix) agrees across six schemas | SATISFIED | `prefix_propagation_test.exs`: both to_sql calls assert qualified "prefix"."table" tokens; negative assertion gated behind `if @prefix`; six-schema equality unconditional |
| TEST-03 | 52-04 | CI matrix schema_prefix axis recompiles per value; _build cache namespaced by prefix; no false-green | SATISFIED | `ci.yml`: 4-cell matrix; PARAPET_SCHEMA_PREFIX injected; mix compile --force; _build cache key + restore-keys namespaced by matrix.schema_prefix; compiled_prefix_leg_test.exs tripwire; fail-fast: false |

All four phase requirements (PROP-01, PROP-02, PROP-03, TEST-03) are satisfied. No orphaned requirements found — REQUIREMENTS.md traceability table maps all four to Phase 52 with status "Complete".

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/parapet/spine/prefix_propagation_test.exs` | 35–37 | Redundant inner `if @prefix` guard (same compile-time attribute as outer guard on line 26) | Info | Dead code — no runtime impact; the refute on line 36 executes correctly but the inner guard is unreachable-false by construction. Left as-is per context: IN-01 intentionally unfixed as non-blocking. |

No blockers. No TBD/FIXME/XXX markers found in any phase-modified file. No stubs, empty returns, or disconnected data flows found.

---

### Human Verification Required

None. All truths are statically or empirically verifiable without human UI interaction. The CI matrix requires a live GitHub Actions run to confirm the public leg passes end-to-end; this is documented as a "Push-time oracle" in 52-VALIDATION.md and is outside the scope of local verification. The empirical results provided in the phase context (public leg 23 tests / 0 failures) satisfy this check at the local level.

---

### Gaps Summary

No gaps. All ten must-haves are verified against the actual codebase. All four requirement IDs (PROP-01, PROP-02, PROP-03, TEST-03) are satisfied. All Critical and Warning findings from 52-REVIEW.md were resolved in commits 4dd7f19, abd5ead, 86210f3, eefd24c, fb508c7. The two Info findings (IN-01 redundant guard, IN-02 missing resolve_action_item coverage) were intentionally left unfixed as non-blocking per the provided context.

---

_Verified: 2026-06-30T22:00:00Z_
_Verifier: Claude (gsd-verifier)_
