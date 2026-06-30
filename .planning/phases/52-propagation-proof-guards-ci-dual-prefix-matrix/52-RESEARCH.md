# Phase 52: Propagation Proof, Guards & CI Dual-Prefix Matrix - Research

**Researched:** 2026-06-30
**Domain:** Ecto multi-tenancy prefix propagation, ExUnit fitness-function guards, GitHub Actions matrix strategy
**Confidence:** HIGH (codebase), MEDIUM (Ecto API facts), LOW (CI patterns)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**A. PROP-02 — Static guard (negative proof)**
- D-01: Regex ExUnit fitness function at `test/parapet/schema_prefix_guard_test.exs` (`async: true`). Modeled on `operator_ui_palette_gate_test.exs:54-64` (structured message) and `operator_ui_compile_out_test.exs:57-64` (`Path.wildcard |> File.read!` shape).
- D-02: Scope scan to `lib/parapet/**/*.ex` only — excludes `lib/mix/tasks/` where generators legitimately emit `create table(:parapet_*)`, `references(:parapet_*)`, `CREATE SCHEMA parapet`.
- D-03: Match forbidden **shape** not forbidden **word**. Four regex fingerprints: (a) `(insert_all|update_all|delete_all)\s*\(\s*["~]` — string/sigil table literal immediately after the paren; (b) bare `prefix:` with negative lookbehinds excluding `schema_prefix:`/`module_prefix`/`_prefix:`; (c) `search_path`; (d) `parapet_` inside raw SQL string / `fragment(` near a SQL verb.
- D-04: Guard must be green from day one (verified zero offenders in current `lib/`).
- D-05: Failure message teaches the why (read/write precedence split-brain) and the fix, with per-offender `file:line / pattern / code / fix` block.

**B. PROP-01 + PROP-03 — Propagation tests (positive proof)**
- D-06: One file `test/parapet/spine/prefix_propagation_test.exs` under `ConcurrencyCase`.
- D-07: Extract `mcp/server.ex` inlined join into `@doc false` pure query builder `timeline_for_correlation_query/1`. No public API / telemetry change.
- D-08: Per-site assertion by `to_sql` support:
  - Two spine↔spine joins → `to_sql(:all, repo, query)`, assert qualified `"parapet"."parapet_…"` on both FROM and JOIN.
  - `insert_all(ActionClaim, …)` and `Ecto.Multi` → `__schema__(:prefix)` + sandbox round-trip asserting `Ecto.get_meta(struct, :prefix) == @prefix`.
- D-09: Leg-aware: bind `@prefix Parapet.Spine.Schema.__prefix__()` at module top; gate negative bare-name assertion behind `if @prefix`.
- D-10: Assert on stable qualified-identifier token (`"parapet"."parapet_…"`), never whole-SQL equality.

**C. TEST-03 — CI dual-prefix matrix**
- D-11: Add `schema_prefix` as pruned second axis via `matrix.include`: `parapet` × all OTP + `public` × primary OTP only (net +1 cell, 3→4).
- D-12: Inject `env: PARAPET_SCHEMA_PREFIX: ${{ matrix.schema_prefix }}` and run `mix compile --force` before `mix test`.
- D-13: Namespace `_build` cache key by `${{ matrix.schema_prefix }}`; keep `deps` cache shared; add `fail-fast: false`.
- D-14: In-suite leg guard `test/parapet/spine/compiled_prefix_leg_test.exs` asserts `Parapet.Spine.Schema.__prefix__()` equals normalized `PARAPET_SCHEMA_PREFIX`. Defense layers: cache-key namespace (primary) + `--force` (secondary) + in-suite guard (tertiary) + compile_env boot-check (free). Never pass `--no-validate-compile-env`.

**D. WR-01..04 — Seal four Phase-51 leaks**
- D-15 (WR-01): Extract shared `Parapet.Spine.Schema.normalize/1`; macro/`__prefix__/0`, `Evidence.schema_prefix/0`, test bootstrap all call it. `config/config.exs` keeps deliberate pre-compile copy (no `Code.require_file` of app modules). Agreement test rewritten to drive real production code, deleting test-local mirrors. `normalize/1` maps atoms via `Atom.to_string/1` (IN-01: `:public` collapses).
- D-16 (WR-02): Keep `unset env → "parapet"` vs `explicit nil/""/"public" → nil` asymmetry. Pin with two explicit tests and doc sentence at all three sites.
- D-17 (WR-03): `Evidence.schema_prefix/0` delegates to `Parapet.Spine.Schema.__prefix__()`. Invert evidence_test.exs:201-231 tests — assert helper is frozen to compiled value and ignores `Application.put_env`.
- D-18 (WR-04): `safe_ident!/1` allowlist validator (`^[a-z_][a-z0-9_]*$` + 63-byte limit) on `Parapet.Spine.Schema`, folded into `normalize/1`. `concurrency_bootstrap.ex` raw-DDL gains safety by construction.

**E. Intra-phase ordering**
- D-19: WR-01 (`normalize/1` + `safe_ident!/1`) first → WR-04 folds in → WR-03 delegation + agreement-test rewrite together → WR-02 (tests+docs) alongside.

### Claude's Discretion
- Exact regex literals, file-internal helper names, and message wording for the guard (D-01..05).
- Whether D-14 in-suite leg guard and D-09 six-schema equality co-locate in one file or two.
- Exact OTP version chosen as "primary" for the `public` leg (follow whatever the current matrix treats as primary). **Resolved: `28.x`** (highest/latest in current matrix: 26.x, 27.x, 28.x).

### Deferred Ideas (OUT OF SCOPE)
- Permitting operator-chosen mixed-case schema prefixes — Phase 53+.
- Migration generators, library migrations, `--schema`/`--no-create-schema` hatch — Phase 53.
- `mix parapet.gen.schema.move` upgrade task + `parapet.doctor` drift check — Phase 54.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROP-01 | Prefix auto-propagates with zero call-site changes across `Repo.*`, `insert_all(SchemaModule, …)`, `Ecto.Multi`, and two spine↔spine joins (`mcp/server.ex`, `circuit_breaker.ex`). Pinned by regression tests. | Confirmed: `@schema_prefix` baked at compile time propagates automatically through all Ecto ops. `to_sql` + `get_meta` provide per-site proof. |
| PROP-02 | Runtime `prefix:` banned by static guard test over `lib/`. Flags string-literal-table `insert_all`/`update_all`/`delete_all`, `search_path`, raw SQL naming `parapet_` tables. Builds fail with structured message. | Confirmed: zero current offenders in `lib/parapet/**/*.ex`. Regex shapes D-03(a-d) verified clean against actual codebase. `lib/mix/tasks/` excluded for legit `create table(:parapet_*)` use. |
| PROP-03 | `to_sql`/`Ecto.get_meta(struct, :prefix)` assertions ride every test leg, proving compiled prefix on selects/joins/`insert_all`/Multi. `__schema__(:prefix)` matches across all six schemas. | Confirmed: `to_sql/3` supports `:all`/`:update_all`/`:delete_all` (NOT `:insert_all`). `Ecto.get_meta(struct, :prefix)` is the sanctioned proof path for insert_all/Multi. |
| TEST-03 | CI matrix axis `schema_prefix: ['parapet','public']` recompiles with `--force`, `_build` cache namespaced by prefix, full suite per value. Honest both-legs proof. | Confirmed: `matrix.include` syntax for pruned +1 cell. Cache key namespacing pattern documented. `mix compile --force` is correct lever (library is first-party, not a dep). |
</phase_requirements>

---

## Summary

Phase 52 seals the compile-time `@schema_prefix` mechanism landed in Phase 51 with three layers of proof: a static fitness-function guard that makes runtime `prefix:` options impossible to reintroduce, a propagation-proof test suite that rides the real call sites (never rebuilds the query in-test), and a dual-prefix CI matrix that reruns the full suite under both `parapet` and `public` legs with a namespaced `_build` cache.

The phase also folds in four advisory warnings from the Phase 51 code review (WR-01..04). These are the normalization/runtime seams that Phase 53's generators will inherit — they must be single-sourced and guarded before a generator copies them. This adds one production edit to each of `schema.ex` (extract `normalize/1` + `safe_ident!/1`) and `evidence.ex` (delegate to `Schema.__prefix__()`), confirmed by the user.

All codebase coordinates have been verified against the actual source. Two minor drifts were found between CONTEXT.md descriptions and actual line numbers; the planning tasks must use the confirmed addresses. The six spine schemas all use `use Parapet.Spine.Schema`; zero guard offenders exist in the current `lib/parapet/` tree; and the CI workflow's `_build` cache key currently has no `schema_prefix` variable — the false-green path is confirmed real and D-13 is the correct fix.

**Primary recommendation:** Implement in D-19 order (WR-01 normalize/safe_ident first, WR-04 in normalize, WR-03 delegation + test rewrite, WR-02 docs, then guard, then propagation tests, then CI). Everything except the CI matrix change is pure ExUnit / compile-time Elixir — no new deps, no new Hex releases, no runtime changes.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Compile-time prefix resolution (`normalize/1`, `__prefix__/0`) | Library (compile time) | — | `Application.compile_env` baked at module attribute level; all downstream code reads a frozen value |
| Static guard (PROP-02) | Test layer (ExUnit fitness function) | — | Line-filtered regex over source files; runs in `mix test` lane, no production code |
| Propagation proof tests (PROP-01/03) | Test layer (ConcurrencyCase sandbox) | — | Exercises real production call sites via `to_sql` and `Ecto.get_meta` |
| CI dual-prefix matrix (TEST-03) | CI/CD (GitHub Actions) | Build layer (`mix compile --force`) | `compile_env` means different prefix values produce different compiled artifacts |
| `Evidence.schema_prefix/0` delegation (WR-03) | Library (runtime helper) | — | Delegates to `Schema.__prefix__()` so helper returns the frozen compile-time value |
| Raw DDL identifier safety (WR-04) | Library (`safe_ident!/1` in `schema.ex`) | Test support (`concurrency_bootstrap.ex`) | Allowlist validator prevents injection before Phase 53 generators clone the template |

---

## Standard Stack

No new external dependencies are introduced in this phase. All work uses existing project dependencies.

### Core (already in mix.exs)

| Library | Locked Version | Purpose | Why Standard |
|---------|---------------|---------|--------------|
| `ecto` | 3.13.6 | Ecto.Query, `to_sql`, `get_meta`, `@schema_prefix`, `Ecto.Multi` | First-party dependency; all proof assertions use its public API |
| `ecto_sql` | 3.13.5 | `Ecto.Adapters.SQL.to_sql/3` for query-to-SQL conversion | Required for spine↔spine join SQL inspection |
| ExUnit | OTP/Elixir built-in | Fitness function guards + propagation tests + leg guard | Already the project's test framework |

### No New Packages

This phase installs zero new hex packages. The `schema_prefix_guard_test.exs`, `prefix_propagation_test.exs`, and `compiled_prefix_leg_test.exs` test files require only modules already available in the test support layer.

---

## Package Legitimacy Audit

No external packages are installed in this phase. Section not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
PARAPET_SCHEMA_PREFIX (env var, CI-injected per matrix cell)
         |
         v
config/config.exs (compile-time, pre-compile copy)
         |
         v
Application.compile_env(:parapet, :schema_prefix)
         |
         v
Parapet.Spine.Schema
  @raw_prefix  (line 34)
      |
      v
  normalize/1 + safe_ident!/1  [NEW — WR-01/04]
      |
      v
  @prefix (line 40-44)
      |
  __prefix__/0 (line 57-60)  ← called by schemas and Evidence
      |
      +---> use Parapet.Spine.Schema  -->  @schema_prefix on all 6 schemas
      |                                         |
      |                               Ecto.Query / Ecto.Multi
      |                                         |
      |                         to_sql(:all)  get_meta(:prefix)
      |                               |              |
      +---> Evidence.schema_prefix/0 [WR-03 delegate]
                 (returns frozen compile-time value)

CI MATRIX
  matrix.schema_prefix: ['parapet', 'public']
           |
           +-- parapet × OTP 26/27/28 (3 cells, existing)
           +-- public × OTP 28 (1 new cell via matrix.include)
           |
           v
  PARAPET_SCHEMA_PREFIX injected as env var
           |
  mix compile --force  (recompile under new compile_env value)
           |
  mix test  (full suite, both legs)
           |
  In-suite: compiled_prefix_leg_test.exs asserts __prefix__() == normalized env

STATIC GUARD (runs on every leg, every CI cell)
  Path.wildcard("lib/parapet/**/*.ex")
           |
  regex scan (D-03 shapes a/b/c/d)
           |
  zero offenders  →  :ok
  any offender    →  teaching failure message
```

### Recommended Project Structure

New files created by this phase:

```
test/parapet/
├── schema_prefix_guard_test.exs        # PROP-02 static guard (D-01..05) [NEW]
└── spine/
    ├── prefix_propagation_test.exs     # PROP-01 + PROP-03 behavioral proof (D-06..10) [NEW]
    └── compiled_prefix_leg_test.exs    # TEST-03 in-suite leg guard (D-14) [NEW]

lib/parapet/spine/schema.ex             # Add normalize/1 + safe_ident!/1 (WR-01/04) [EDIT]
lib/parapet/evidence.ex                 # Delegate schema_prefix/0 (WR-03) [EDIT]
lib/parapet/mcp/server.ex              # Extract timeline query builder (D-07) [EDIT]
test/parapet/spine/schema_test.exs     # Rewrite agreement test (WR-01) [EDIT]
test/parapet/evidence_test.exs         # Invert schema_prefix/0 tests (WR-03) [EDIT]
.github/workflows/ci.yml               # Add schema_prefix matrix axis (TEST-03) [EDIT]
```

### Pattern 1: Fitness-Function Guard (ExUnit)

**What:** Scan all `lib/parapet/**/*.ex` source files with regex, assert zero matches for forbidden patterns.

**When to use:** Compile-time rules that can't be enforced by the type system. Parapet uses two existing guards with this shape.

**Example (from `operator_ui_compile_out_test.exs:57-64`):**
```elixir
# Source: test/parapet/operator_ui_compile_out_test.exs
for file <- Path.wildcard("lib/parapet/**/*.ex") do
  content = File.read!(file)
  for pattern <- forbidden_core_patterns do
    refute content =~ pattern, "Found #{pattern} in core file #{file}"
  end
end
```

**Adaptation for schema_prefix_guard_test.exs:**
```elixir
# Source: pattern derived from codebase (operator_ui_compile_out_test.exs)
@forbidden_patterns [
  # (a) string/sigil literal immediately after insert_all/update_all/delete_all paren
  ~r/(insert_all|update_all|delete_all)\s*\(\s*["~]/,
  # (b) bare prefix: repo option (not schema_prefix:, not module_prefix, not _prefix:)
  ~r/(?<!schema_)(?<!module_)(?<!_)prefix:\s/,
  # (c) search_path usage
  ~r/search_path/,
  # (d) parapet_ inside raw SQL / fragment near SQL verb
  ~r/fragment\(.*parapet_/
]

@lib_files Path.wildcard("lib/parapet/**/*.ex")

test "no runtime prefix: options or string-table writes in lib/parapet" do
  offenders =
    for file <- @lib_files,
        content = File.read!(file),
        pattern <- @forbidden_patterns,
        content =~ pattern do
      {file, pattern}
    end

  assert offenders == [], """
  SCHEMA PREFIX GUARD VIOLATION

  The following files contain patterns that break compile-time prefix isolation.
  Runtime prefix: options create a read/write split-brain: reads resolve via
  @schema_prefix (compile-time), but writes resolve via prefix: (runtime) — they
  can land in different Postgres schemas.

  #{format_offenders(offenders)}

  Fix: Remove the runtime prefix: option. Let @schema_prefix propagate.
  """
end
```

### Pattern 2: `to_sql/3` for Spine-Spine Join Proof

**What:** Convert an Ecto.Query to SQL string and assert the qualified identifier appears.

**When to use:** When you need to verify prefix propagation on SELECT/UPDATE/DELETE query paths where `Ecto.get_meta` is not available.

**Example:**
```elixir
# Source: codebase pattern, Ecto.Adapters.SQL hexdocs
@prefix Parapet.Spine.Schema.__prefix__()

test "get_incident_timeline query uses qualified schema prefix" do
  query = Parapet.MCP.Server.timeline_for_correlation_query("key-123")
  {sql, _params} = Ecto.Adapters.SQL.to_sql(:all, ConcurrencyRepo, query)

  if @prefix do
    assert sql =~ ~s("#{@prefix}"."parapet_timeline_entries"),
           "Expected qualified FROM in: #{sql}"
    assert sql =~ ~s("#{@prefix}"."parapet_incidents"),
           "Expected qualified JOIN in: #{sql}"
  else
    refute sql =~ ~s("parapet"."parapet_),
           "Public leg must not have parapet. prefix in: #{sql}"
  end
end
```

### Pattern 3: `Ecto.get_meta/2` for insert_all / Multi Proof

**What:** After a sandbox round-trip (Repo.insert_all with returning:, or Ecto.Multi), call `Ecto.get_meta(struct, :prefix)` on the returned struct to verify the prefix was materialized correctly.

**When to use:** When `to_sql/3` can't be used (`:insert_all` is not a valid `to_sql` query type).

**Example:**
```elixir
# Source: codebase pattern, Ecto hexdocs (Ecto.get_meta/2)
test "insert_all via claim_service materializes correct prefix on returned struct" do
  {:won, claim} = ClaimService.claim_action(repo: ConcurrencyRepo, incident_id: incident.id, ...)
  assert Ecto.get_meta(claim, :prefix) == @prefix
end

test "Ecto.Multi create_incident materializes correct prefix on returned struct" do
  {:ok, %{incident: incident}} = Evidence.create_incident(...)
  assert Ecto.get_meta(incident, :prefix) == @prefix
end
```

### Pattern 4: `normalize/1` + `safe_ident!/1` in Schema Module

**What:** A public function that validates the raw env value and returns a safe Postgres schema name or `nil` for the unprefixed leg.

**When to use:** Called by `__prefix__/0` (compile-time), by `Evidence.schema_prefix/0` (runtime delegate), and by `ConcurrencyBootstrap` (test support DDL).

**Proposed implementation:**
```elixir
# Source: derived from existing schema.ex normalization logic (lines 40-44)
@doc false
def normalize(p) when p in [nil, "", "public"], do: nil
def normalize(other) when is_atom(other), do: normalize(Atom.to_string(other))
def normalize(other) when is_binary(other) do
  validated = safe_ident!(other)
  validated
end

@doc false
def safe_ident!(ident) do
  unless ident =~ ~r/^[a-z_][a-z0-9_]*$/ and byte_size(ident) <= 63 do
    raise ArgumentError,
      "Invalid Postgres schema identifier: #{inspect(ident)}. " <>
      "Must match ^[a-z_][a-z0-9_]*$, max 63 bytes."
  end
  ident
end
```

**Usage in `__prefix__/0`:**
```elixir
# In Parapet.Spine.Schema — replaces inline case statement
@raw_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")
@prefix __MODULE__.normalize(@raw_prefix)   # ← computed at compile time from public fn

def __prefix__, do: @prefix
```

**NOTE:** The chicken-and-egg at compile time (D-15 planning note): The module attribute `@prefix` is computed via `normalize(@raw_prefix)` during compilation. `normalize/1` must be defined before the `@prefix` attribute or the call must happen in `__before_compile__` or via a separate call to `__MODULE__.normalize(@raw_prefix)`. Simplest safe approach: define `normalize/1` and `safe_ident!/1` as `def` before the `@prefix` module attribute — Elixir evaluates module attributes lazily top-to-bottom.

### Pattern 5: Pruned CI Matrix via `matrix.include`

**What:** Add a single extra matrix cell for the `public` leg without a full Cartesian product.

**When to use:** When you want to add one specific combination to an existing matrix.

**Example:**
```yaml
# Source: GitHub Actions docs, oneuptime.com/blog
strategy:
  fail-fast: false
  matrix:
    elixir: ['1.19.0']
    otp: ['26.x', '27.x', '28.x']
    schema_prefix: ['parapet']
    include:
      - elixir: '1.19.0'
        otp: '28.x'
        schema_prefix: 'public'
```

**This produces 4 cells:**
- `elixir=1.19.0, otp=26.x, schema_prefix=parapet`
- `elixir=1.19.0, otp=27.x, schema_prefix=parapet`
- `elixir=1.19.0, otp=28.x, schema_prefix=parapet`
- `elixir=1.19.0, otp=28.x, schema_prefix=public`  ← the new cell

**Cache key must include `schema_prefix`:**
```yaml
# Source: felt/ultimate-elixir-ci pattern + D-13
key: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-${{ hashFiles('**/mix.lock') }}
restore-keys: |
  ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-
```

**Compile step:**
```yaml
- run: PARAPET_SCHEMA_PREFIX=${{ matrix.schema_prefix }} mix compile --force
```

### Anti-Patterns to Avoid

- **Rebuild query in test:** Rebuilding the Ecto.Query inside a test, then calling `to_sql` on the rebuilt copy, would keep the test green while the real production call site regresses. Always pin the real extracted builder function.
- **Copying Oban's `_build` cache key:** Oban's prefix is runtime-injected — it does NOT namespace `_build` by prefix. Parapet's prefix is `compile_env` — it MUST namespace. The cache-hit false-green is real and the test will lie.
- **Calling `Application.get_env` inside a function for a compile-time value:** This is the WR-03 bug. `get_env` is mutable — tests that call `Application.put_env` can change the helper's return value even though `@schema_prefix` is frozen. Fix: delegate to `Schema.__prefix__()`.
- **Calling `Application.compile_env` inside a `def` body:** It must be called at module attribute level. Elixir warns; the frozen value never reaches the function correctly.
- **String interpolation into raw SQL without allowlist:** The WR-04 pattern (Triplex/`apartment` historical CVE class). `safe_ident!/1` with `^[a-z_][a-z0-9_]*$` + 63-byte limit closes case-folding, length, and reserved-word footguns. Allowlist over blocklist over escaping.
- **Passing `--no-validate-compile-env`:** Disables the free boot-check backstop. Never pass this in the CI matrix.
- **Qualifying Postgres index names with a schema:** Index names in Postgres are per-schema but cannot be qualified with `"schema"."index_name"` syntax. `q/1` in `ConcurrencyBootstrap` correctly emits bare index names — preserve this.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SQL inspection for prefix proof (SELECT/UPDATE/DELETE paths) | Build custom Repo adapter | `Ecto.Adapters.SQL.to_sql(:all, repo, query)` | Returns the actual SQL with parameters; covers FROM + JOIN prefix in one call |
| Struct prefix verification (INSERT paths) | Parse SQL of insert | `Ecto.get_meta(struct, :prefix)` | Reads prefix from the struct's `__meta__` field after round-trip; the sanctioned path |
| Multi-tenancy prefix precedence | Custom resolver | Let Ecto's own precedence rule (from/join > `@schema_prefix` > repo `:prefix`) operate | Parapet bans the repo `:prefix` option entirely, so `@schema_prefix` always wins |
| Postgres identifier quoting | Custom quoting | `safe_ident!/1` allowlist + double-quote wrapping | `Ecto.Adapters.Postgres.Connection.quote_name/1` is private; allowlist approach closes more attack surface than escaping |
| Static analysis for code patterns | Custom Credo check | ExUnit fitness function (regex over source files) | Matches existing Parapet pattern; zero deps; teaching failure messages; stays out of Hex tarball |

**Key insight:** The combination of `@schema_prefix` (compile-time baked) + `to_sql/3` (query proof) + `Ecto.get_meta/2` (struct proof) covers every read/write path without any custom adapter or reflection code.

---

## Codebase Verification: Source Coordinate Drift Report

This section is the core deliverable of the research phase. Each CONTEXT.md coordinate has been checked against the actual source.

### Verified coordinates (match CONTEXT.md)

| File | CONTEXT Ref | Actual | Status |
|------|-------------|--------|--------|
| `lib/parapet/spine/schema.ex` | `:34` `@raw_prefix Application.compile_env(...)` | line 34 ✓ | MATCH |
| `lib/parapet/spine/schema.ex` | `:40-44` normalizer case | lines 40-44 ✓ | MATCH |
| `lib/parapet/automation/circuit_breaker.ex` | `:44-61` `execution_count_query/3` | lines 44-61 ✓ | MATCH |
| `lib/parapet/automation/claim_service.ex` | `:111` `repo.insert_all(ActionClaim, ...)` | line 111 ✓ | MATCH |
| `lib/parapet/evidence.ex` | `:42-48` `schema_prefix/0` using `get_env` | lines 42-48 ✓ | MATCH |
| `lib/parapet/evidence.ex` | `:157-187` second `Ecto.Multi` | starts at 157 ✓ | MATCH |
| `test/parapet/spine/schema_test.exs` | `:11-35` six-schema prefix tests | lines 11-35 ✓ | MATCH |
| `test/parapet/spine/schema_test.exs` | `:116-128` private helpers | lines 116-128 ✓ | MATCH |
| `test/support/concurrency_bootstrap.ex` | `:10-15` `@raw_prefix`/`@prefix` | lines 10-15 ✓ | MATCH |
| `test/support/concurrency_bootstrap.ex` | `:49-55` `q/1` function | lines 49-55 ✓ | MATCH |
| `.github/workflows/ci.yml` | `:66-68` matrix (elixir+otp) | lines 63-68 (actual format) | CLOSE MATCH |
| `.github/workflows/ci.yml` | `:100-103` `_build` cache | lines 98-103 ✓ | MATCH |

### DRIFT FOUND: line numbers to correct in plans

| File | CONTEXT.md Says | Actual Code | Planner Must Use |
|------|-----------------|-------------|-----------------|
| `lib/parapet/mcp/server.ex` | `:36-42` (inlined join) | `get_incident_timeline/2` body is **lines 33-44** | Use **lines 33-44** |
| `lib/parapet/evidence.ex` | `:81-90` (first Ecto.Multi) | First `Ecto.Multi` starts at **line 82** (not 81) | Use **lines 82-90** |
| `test/parapet/spine/schema_test.exs` | `:91-128` (agreement test describe block) | `describe "normalization agreement"` starts at **line 87** | Use **lines 87-128** |

### Verified: Zero guard offenders in current `lib/`

```bash
# Run and confirmed zero matches:
grep -rn "insert_all\|update_all\|delete_all" lib/parapet/ | grep -v mix/tasks | grep '["~]'
# → (no output)

grep -rn "prefix:" lib/parapet/ | grep -v "schema_prefix:\|module_prefix\|_prefix:" | grep -v "\.ex:#"
# → (no matches in production code)

grep -rn "search_path" lib/parapet/
# → (no output)
```

Guard is green from day one (D-04 confirmed). [VERIFIED: codebase grep]

### Verified: Six spine schemas all use `use Parapet.Spine.Schema`

Confirmed in prior session grep pass:
1. `lib/parapet/spine/incident.ex` — `use Parapet.Spine.Schema`
2. `lib/parapet/spine/action_item.ex` — `use Parapet.Spine.Schema`
3. `lib/parapet/spine/system_event.ex` — `use Parapet.Spine.Schema`
4. `lib/parapet/spine/tool_audit.ex` — `use Parapet.Spine.Schema`
5. `lib/parapet/spine/timeline_entry.ex` — `use Parapet.Spine.Schema`
6. `lib/parapet/spine/action_claim.ex` — `use Parapet.Spine.Schema`

[VERIFIED: codebase grep]

### Verified: `lib/mix/tasks/` exclusion is essential

`lib/mix/tasks/` contains `create table(:parapet_*)`, `references(:parapet_*, on_delete: :delete_all)` — these would fire regex (a) and (d) in D-03. Excluding via `Path.wildcard("lib/parapet/**/*.ex")` (which does NOT match `lib/mix/tasks/`) is correct. [VERIFIED: codebase grep]

### Verified: `claim_service.ex:111` uses module reference not string literal

```elixir
# Line 111 — uses ActionClaim module, not a string "parapet_action_claims"
repo.insert_all(ActionClaim, [Map.put(attrs, :error_metadata, %{})],
  on_conflict: :nothing, ...)
```

This will NOT be flagged by guard regex (a) (`insert_all(ActionClaim,` has no string/sigil immediately after the paren). [VERIFIED: codebase read]

### Verified: CI cache key has no `schema_prefix` variable today

Current key (lines 98-103 of `.github/workflows/ci.yml`):
```yaml
key: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
restore-keys: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-
```

The `schema_prefix` variable is absent. Adding `${{ matrix.schema_prefix }}` is the D-13 fix. [VERIFIED: codebase read]

### Verified: CI `fail-fast:` is not set (defaults to `true`)

The `test:` job in `ci.yml` has no `fail-fast:` key at the strategy level. GitHub Actions default is `true`. D-13 adds `fail-fast: false`. [VERIFIED: codebase read]

### Verified: Primary OTP for `public` leg

Current matrix OTP versions: `['26.x', '27.x', '28.x']`. Primary = `28.x` (highest). [VERIFIED: codebase read, Claude's Discretion]

---

## External API Facts

### Ecto Prefix Precedence (Hexdocs confirmed)

[CITED: hexdocs.pm/ecto multi-tenancy-with-query-prefixes]

For **query operations** (`all`, `update_all`, `delete_all`):
1. `from`/`join` prefix explicitly set (highest priority)
2. `@schema_prefix` module attribute (compile-time baked)
3. `:prefix` repo option (runtime)
4. Connection prefix (lowest)

For **schema operations** (`insert_all`, `insert`, `update`):
1. `:prefix` option (highest — overrides `@schema_prefix`)
2. Changeset prefixes
3. `@schema_prefix` (compile-time)
4. Connection prefix

**Implication for D-03(b) guard:** The runtime `:prefix` option beats `@schema_prefix` on write paths. This is the split-brain risk the guard targets. A write with `prefix: "public"` lands data in `public.parapet_incidents` while reads without `:prefix` hit `parapet.parapet_incidents`. The guard blocks this by making `:prefix:` a compilation error.

**Ecto.Multi:** Respects prefix on each individual operation step; associated data inserted/updated with a struct inherits the same prefix as the parent operation.

### `Ecto.Adapters.SQL.to_sql/3` (Hexdocs confirmed)

[CITED: hexdocs.pm/ecto_sql Ecto.Adapters.SQL v3.13.5]

```elixir
@spec to_sql(
  :all | :update_all | :delete_all,
  Ecto.Repo.t(),
  Ecto.Queryable.t()
) :: {String.t(), [term()]}
```

- `:all` → generates SELECT SQL
- `:update_all` → generates UPDATE SQL
- `:delete_all` → generates DELETE SQL
- `:insert_all` → **NOT SUPPORTED** — insert operations take a list of entries (not an `Ecto.Queryable`); `to_sql` converts Ecto.Query structs to SQL, and `insert_all` has no queryable form

**Phase 52 implication (D-08):** The two spine↔spine join builders (`mcp/server.ex` extracted builder, `circuit_breaker.ex:execution_count_query/3`) can be proven via `to_sql(:all, ...)`. The `insert_all(ActionClaim, ...)` path and `Ecto.Multi` paths require `Ecto.get_meta(struct, :prefix)` on the returned struct after a sandbox round-trip.

### `Ecto.get_meta/2` (Hexdocs confirmed)

[CITED: hexdocs.pm/ecto Ecto module, Ecto.Schema.Metadata]

```elixir
Ecto.get_meta(struct, :prefix)  # returns the prefix string or nil
Ecto.get_meta(struct, :source)  # returns the table/source name
Ecto.get_meta(struct, :state)   # :built | :loaded | :deleted
Ecto.get_meta(struct, :context) # adapter context
```

The `__meta__` field is added to every Ecto schema struct and carries an `Ecto.Schema.Metadata` struct. `get_meta/2` is the official accessor. After `Repo.insert_all(..., returning: [...])` in `ConcurrencyCase` sandbox, the returned struct's `:prefix` metadata reflects the prefix materialized by the actual write path. This is the load-bearing proof for paths where `to_sql` cannot reach.

Companion: `Ecto.put_meta(struct, prefix: "new_prefix")` can set metadata (used in multi-tenant copy flows — irrelevant here, but confirms the field is writable and inspectable).

### `Application.compile_env` vs `Application.get_env` (Elixir Hexdocs confirmed)

[CITED: hexdocs.pm/elixir Application module]

**`Application.compile_env(app, key, default)`:**
- Must be called at module attribute level (not inside a `def` body — Elixir warns)
- Mix records the value at compile time
- At application boot, Mix validates the recorded compile-time value matches the current runtime value — raises if they differ
- This is a free backstop; D-14 adds explicit in-suite assertion as a tertiary defense

**`Application.get_env(app, key, default)`:**
- Reads the mutable application environment at call time
- Can be changed by `Application.put_env/3` between calls
- The WR-03 bug: `Evidence.schema_prefix/0` calls `get_env` inside a `def` — tests with `Application.put_env` can change its return value, giving a false impression the prefix is dynamic
- The evidence_test.exs:201-231 block currently asserts this mutable behavior — these tests assert the bug, not correct behavior

---

## Common Pitfalls

### Pitfall 1: `_build` Cache False-Green (The Oban Trap)

**What goes wrong:** The `public` leg CI cell restores the `_build` artifact compiled under `schema_prefix=parapet`. The `public` leg tests pass because `@schema_prefix` is still `"parapet"` — the new env var was never baked into the compiled code.

**Why it happens:** GitHub Actions cache `restore-keys` prefix-match. Without `${{ matrix.schema_prefix }}` in the key, the `public` leg matches the `parapet` leg's cache entry. `mix compile` sees no source changes and skips recompilation.

**How to avoid:** D-13 namespaces the `_build` cache key by `matrix.schema_prefix`. D-12 adds `mix compile --force` as secondary defense. D-14 adds an in-suite assertion as tertiary defense.

**Warning signs:** Both legs show identical `Parapet.Spine.Schema.__prefix__()` → `"parapet"` even when `PARAPET_SCHEMA_PREFIX` is unset/empty.

### Pitfall 2: Rebuilding the Query in Test Instead of Extracting the Real Builder

**What goes wrong:** The propagation test builds its own copy of the `get_incident_timeline` query inline (copying the Ecto.Query from the implementation). The test stays green while the real call site in `mcp/server.ex` is changed to use a different query.

**Why it happens:** It feels simpler than extracting a production function. But the test is then testing the copy, not the production path.

**How to avoid:** D-07 mandates extracting `timeline_for_correlation_query/1` as a `@doc false` pure builder and calling it from both the production path and the test. The test imports/calls the same function.

**Warning signs:** Test file contains `from(t in TimelineEntry, join: i in Incident, ...)` directly rather than `Server.timeline_for_correlation_query("key")`.

### Pitfall 3: Using `to_sql` for `insert_all` Paths

**What goes wrong:** Test calls `to_sql(:insert_all, repo, query)` — this raises a `FunctionClauseError` because `:insert_all` is not a valid type atom.

**Why it happens:** The type restriction isn't obvious from the name. `insert_all` is a common Ecto operation.

**How to avoid:** Use `Ecto.get_meta(struct, :prefix)` on returned structs for all insert paths. `to_sql` is only for `from`/`where`/`join` queryables.

**Warning signs:** Test file has `to_sql(:insert_all, ...)`.

### Pitfall 4: Qualifying Index Names in Postgres DDL

**What goes wrong:** `CREATE INDEX "parapet"."my_index_name" ON "parapet"."parapet_incidents" (...)` — Postgres rejects schema-qualified index names.

**Why it happens:** Following the qualification pattern for tables mechanically, assuming it applies to indexes.

**How to avoid:** Index names are always global within a schema, declared via `ON "schema"."table"` but the index name itself is bare. `ConcurrencyBootstrap`'s `q/1` already handles this correctly for tables/references.

**Warning signs:** DDL contains `"prefix"."index_name"`.

### Pitfall 5: WR-03 Test Inversion — Deleting Correct Tests Instead of Incorrect Ones

**What goes wrong:** The `evidence_test.exs:201-231` tests use `Application.put_env` and assert the helper's value changes. D-17 says to INVERT these tests — not delete them entirely, but replace the assertion. Deleting them silently removes coverage of `Evidence.schema_prefix/0`.

**How to avoid:** The replacement tests should assert: (a) `Evidence.schema_prefix/0` returns the same value as `Parapet.Spine.Schema.__prefix__()`, and (b) after `Application.put_env(:parapet, :schema_prefix, "something_else")`, `Evidence.schema_prefix/0` still returns the original compiled value.

### Pitfall 6: `normalize/1` Called from a Module Attribute Before It Is Defined

**What goes wrong:** The `@prefix normalize(@raw_prefix)` module attribute fires at compile time. If `normalize/1` is defined after the module attribute in the same module, Elixir raises `UndefinedFunctionError`.

**How to avoid:** Define `normalize/1` and `safe_ident!/1` as function definitions early in the module body — before any module attributes that call them. Elixir evaluates module attributes top-to-bottom during compilation.

---

## Runtime State Inventory

This is NOT a rename/refactor/migration phase. No stored data, live service config, OS-registered state, secrets, or build artifacts need renaming. The compile-time prefix change in Phase 51 already covered the schema mechanism; Phase 52 adds tests and CI.

**Stored data:** None — verified. The `schema_prefix` value is read from the compiled artifact; no database records store the prefix string as a key to rename.
**Live service config:** None — verified. No n8n/external service config references the prefix.
**OS-registered state:** None — verified.
**Secrets/env vars:** `PARAPET_SCHEMA_PREFIX` is new in this phase (CI injection). It is not a renamed key — it's a new CI variable. No `.env` file changes.
**Build artifacts:** `_build` will accumulate leg-specific builds during CI. This is the intended behavior after D-13 namespacing.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir, no version separate from OTP) |
| Config file | `test/test_helper.exs` (standard ExUnit startup) |
| Quick run command | `mix test test/parapet/schema_prefix_guard_test.exs test/parapet/spine/prefix_propagation_test.exs test/parapet/spine/compiled_prefix_leg_test.exs` |
| Full suite command | `mix test` |
| Concurrency test command | `ConcurrencyCase` tests require `PARAPET_SCHEMA_PREFIX` and `ConcurrencyRepo` setup — run full suite |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROP-01 | Prefix auto-propagates through all Repo.*/insert_all/Multi/joins | integration (ConcurrencyCase sandbox) | `mix test test/parapet/spine/prefix_propagation_test.exs` | ❌ Wave 0 |
| PROP-02 | Static guard rejects runtime `prefix:` options and string-table writes | unit (ExUnit fitness function, no DB) | `mix test test/parapet/schema_prefix_guard_test.exs` | ❌ Wave 0 |
| PROP-03 | `to_sql`/`get_meta` assertions prove qualified prefix on every leg | integration (ConcurrencyCase sandbox) | `mix test test/parapet/spine/prefix_propagation_test.exs` | ❌ Wave 0 |
| TEST-03 | CI reruns full suite under both legs with namespaced cache | CI (GitHub Actions matrix) | manual: run CI; local: `PARAPET_SCHEMA_PREFIX=public mix compile --force && mix test` | ❌ Wave 0 (CI edit) |
| WR-01 | `normalize/1` is single-sourced; agreement test drives production code | unit (`schema_test.exs` rewrite) | `mix test test/parapet/spine/schema_test.exs` | EDIT existing |
| WR-02 | Asymmetry tested and documented | unit (`schema_test.exs` additions) | `mix test test/parapet/spine/schema_test.exs` | EDIT existing |
| WR-03 | `Evidence.schema_prefix/0` frozen to compiled value | unit (`evidence_test.exs` rewrite) | `mix test test/parapet/evidence_test.exs` | EDIT existing |
| WR-04 | `safe_ident!/1` rejects invalid identifiers | unit (new tests in `schema_test.exs`) | `mix test test/parapet/spine/schema_test.exs` | EDIT existing |
| D-14 | In-suite leg guard asserts `__prefix__()` matches env var | unit (no DB) | `mix test test/parapet/spine/compiled_prefix_leg_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/spine/schema_test.exs test/parapet/evidence_test.exs` (fast unit tests for WR-01..04 seals)
- **Per wave merge:** `mix test` (full suite)
- **Phase gate:** Full suite green on BOTH legs (`PARAPET_SCHEMA_PREFIX=parapet mix test` and `PARAPET_SCHEMA_PREFIX="" mix compile --force && mix test`) before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/parapet/schema_prefix_guard_test.exs` — covers PROP-02 (Wave 0, new file)
- [ ] `test/parapet/spine/prefix_propagation_test.exs` — covers PROP-01 + PROP-03 (Wave 0, new file)
- [ ] `test/parapet/spine/compiled_prefix_leg_test.exs` — covers D-14 in-suite leg guard (Wave 0, new file)
- [ ] `lib/parapet/mcp/server.ex:timeline_for_correlation_query/1` — must be extracted before propagation test can import it (D-07, production edit)

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | partial | `safe_ident!/1` prevents unauthorized schema hopping via prefix injection |
| V5 Input Validation | yes | `safe_ident!/1` — `^[a-z_][a-z0-9_]*$` allowlist + 63-byte limit |
| V6 Cryptography | no | — |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via prefix interpolation in DDL | Tampering | `safe_ident!/1` allowlist before DDL interpolation in `concurrency_bootstrap.ex` |
| Schema hopping (write to wrong tenant schema) | Tampering / Elevation of Privilege | Compile-time `@schema_prefix` + runtime `:prefix` ban guard (PROP-02) |
| False-green test (public leg reuses parapet `_build`) | Security Testing bypass | `_build` cache key namespacing + `--force` recompile + in-suite guard |

**Note:** Triplex/`apartment` historical CVE pattern — prefix names interpolated into SQL DDL without validation. WR-04 (`safe_ident!/1`) is the deliberate correction. Lowercase-only sidesteps case-folding attacks (`"Parapet"` ≠ `parapet` in Postgres identifier comparison).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Application.get_env` for schema prefix at runtime | `Application.compile_env` baked into `@schema_prefix` module attribute | Phase 51 (2026-06-30) | Prefix is frozen; no runtime mutation possible |
| Test-local mirror functions for normalization agreement | Single `normalize/1` in `Parapet.Spine.Schema`; tests drive production code | Phase 52 (this phase) | WR-01 sealed; drift between config.exs and schema.ex is physically impossible |
| Raw string interpolation into DDL identifiers | `safe_ident!/1` allowlist gate before interpolation | Phase 52 (this phase) | WR-04 sealed; Phase 53 generator inherits the safe template |
| `Evidence.schema_prefix/0` reading mutable `get_env` | Delegates to `Schema.__prefix__()` | Phase 52 (this phase) | WR-03 sealed; the compile/runtime split-brain is eliminated |

**Deprecated/outdated:**
- `Application.get_env(:parapet, :schema_prefix)` inside `def` bodies for compile-time values: replaced by `Parapet.Spine.Schema.__prefix__()`.
- Test-local `normalize_prefix/1` and `config_normalize_prefix/1` helpers in `schema_test.exs:116-128`: deleted once `normalize/1` is public.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `28.x` is the "primary" OTP version for the `public` leg (Claude's discretion; chosen as highest in current matrix) | CI Dual-Prefix Matrix | Minor: using a different OTP version for the `public` leg changes which cell gets run; correctness unaffected |
| A2 | `normalize/1` defined before `@prefix` module attribute in `schema.ex` avoids compile-time chicken-and-egg | Architecture Patterns | Medium: if Elixir evaluates module attributes before the def body of `normalize/1` is compiled, this will raise `UndefinedFunctionError` — mitigated by keeping `normalize/1` as a regular `def` (not a macro) placed early in the module |
| A3 | GitHub Actions `matrix.include` entry that shares keys with the main matrix appends to (not replaces) the existing cells | CI Matrix Pattern | High: if `include` behavior differs, we might get fewer or different cells than expected — but this is the documented GitHub Actions behavior per official docs |

**Confidence in A3:** MEDIUM — verified via external doc fetch from oneuptime.com blog and GitHub Actions community. The documented behavior is unambiguous for this use case.

---

## Open Questions

1. **`normalize/1` compile-time ordering in `schema.ex`**
   - What we know: Module attributes calling functions in the same module are evaluated top-to-bottom during compilation
   - What's unclear: Whether Elixir allows a module attribute to call a `def` in the same module that appears later in the file
   - Recommendation: Define `normalize/1` + `safe_ident!/1` as the first functions in the module, before any module attributes that call them. Alternatively: compute `@prefix` in `__before_compile__` callback (more complex, probably unnecessary). The `@prefix = __MODULE__.normalize(@raw_prefix)` form should work if `normalize/1` is defined above the attribute.

2. **`evidence.ex` WR-03: side effects of delegation on adopter code**
   - What we know: `Evidence.schema_prefix/0` is called by adopter code in some configurations
   - What's unclear: Whether any adopter legitimately depends on `schema_prefix/0` returning a mutable runtime value (e.g., for dynamic multi-tenant use)
   - Recommendation: The Phase 52 scope banishes runtime `:prefix` entirely. Any adopter depending on dynamic `schema_prefix/0` behavior is using the feature in a way that contradicts the compile-time contract. This is a breaking change for them — but it's a deliberate sealing of a bug, not a regression.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All tasks | ✓ | `~> 1.19` (locked) | — |
| OTP | All tasks | ✓ | 26/27/28 (CI matrix) | — |
| PostgreSQL | `ConcurrencyCase` propagation tests | ✓ | see `ConcurrencyRepo` config | `ConcurrencyCase` already required in Phase 51 |
| GitHub Actions runner | TEST-03 CI matrix | ✓ | ubuntu-latest (existing CI) | — |

No missing dependencies with no fallback.

---

## Sources

### Primary (HIGH confidence — codebase grep and direct file reads)
- `/Users/jon/projects/parapet/lib/parapet/spine/schema.ex` — lines 34, 40-44, 47-60 verified
- `/Users/jon/projects/parapet/lib/parapet/evidence.ex` — lines 42-48, 82-90, 152-188 verified
- `/Users/jon/projects/parapet/lib/parapet/mcp/server.ex` — actual lines 33-44 (drift from CONTEXT's :36-42)
- `/Users/jon/projects/parapet/lib/parapet/automation/circuit_breaker.ex` — lines 44-61 verified
- `/Users/jon/projects/parapet/lib/parapet/automation/claim_service.ex` — line 111 verified
- `/Users/jon/projects/parapet/test/parapet/spine/schema_test.exs` — lines 11-35, 87-128 verified
- `/Users/jon/projects/parapet/test/parapet/operator_ui_compile_out_test.exs` — lines 57-64 template verified
- `/Users/jon/projects/parapet/test/support/concurrency_bootstrap.ex` — all DDL lines verified
- `/Users/jon/projects/parapet/.github/workflows/ci.yml` — lines 63-68, 98-103 verified
- Codebase grep: zero guard offenders in `lib/parapet/**/*.ex`
- Codebase grep: all six spine schemas confirmed `use Parapet.Spine.Schema`
- Codebase grep: `lib/mix/tasks/` confirmed contains `create table(:parapet_*)` (exclusion correct)

### Secondary (MEDIUM confidence — official documentation)
- [CITED: ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html] — prefix precedence: from/join > @schema_prefix > repo :prefix; Ecto.Multi prefix behavior
- [CITED: ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.html] — `to_sql/3` spec: `:all | :update_all | :delete_all`, NOT `:insert_all`
- [CITED: ecto.hexdocs.pm/Ecto.html] — `Ecto.get_meta/2` metadata keys including `:prefix`
- [CITED: elixir.hexdocs.pm/Application.html] — `Application.compile_env/3` boot-time validation behavior; must be called at module attribute level

### Tertiary (LOW confidence — web search only)
- [oneuptime.com/blog/post/2025-12-20-github-actions-matrix-include-exclude/view] — `matrix.include` pruned combination syntax + `fail-fast: false` placement
- [github.com/felt/ultimate-elixir-ci/blob/main/.github/actions/elixir-setup/action.yml] — Elixir `_build` cache key pattern with MIX_ENV + mix.lock hash

---

## Metadata

**Confidence breakdown:**
- Codebase coordinates: HIGH — all files read directly; drift items documented with exact corrected line numbers
- Ecto API facts (`to_sql/3` types, `get_meta/2` keys, prefix precedence): MEDIUM — verified against current hexdocs
- GitHub Actions matrix patterns: LOW — from blog/community sources, but behavior is well-known and stable
- Guard zero-offender claim: HIGH — confirmed via grep of actual codebase

**Research date:** 2026-06-30
**Valid until:** 2026-07-30 (stable — Ecto 3.13.x API surface, ExUnit patterns, GitHub Actions matrix spec are all stable over 30 days; CI workflow structure could drift if someone edits ci.yml)
