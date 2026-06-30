# Phase 51: Prefix Core & Test Seam - Research

**Researched:** 2026-06-29
**Domain:** Compile-time Ecto `@schema_prefix` isolation (Elixir/Ecto library internals + test bootstrap DDL)
**Confidence:** HIGH (all locked decisions verified against live code; one ⚠ count discrepancy found in D-09)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01 … D-11 — AUTHORITATIVE, do not re-open)
- **D-01:** Create `Parapet.Spine.Schema` with a `__using__/1` macro that `use Ecto.Schema`, `import Ecto.Changeset`, sets `@primary_key {:id, :binary_id, autogenerate: true}`, `@foreign_key_type :binary_id`, `@schema_prefix Parapet.Spine.Schema.__prefix__()`. Mirror the `defmacro __using__` mechanics in `runbook.ex`/`recovery.ex`/`probe.ex` (house style); schema-base concept itself is net-new.
- **D-02:** Switch all six spine schemas `use Ecto.Schema` → `use Parapet.Spine.Schema`, deleting the now-duplicated `@primary_key`/`@foreign_key_type`/`import Ecto.Changeset` lines. Pure subtraction; behavior unchanged.
- **D-03:** Do NOT apply the macro to `lib/parapet/operator/action_payload.ex` (non-table operator schema). Scope to `lib/parapet/spine/` only.
- **D-04:** `__prefix__/0` reads `Application.compile_env(:parapet, :schema_prefix, "parapet")` and normalizes: `p in [nil, "", "public"] -> nil`; binary -> itself; atom -> `Atom.to_string/1`.
- **D-05:** Normalization is single-sourced in intent but physically duplicated — lives in `__prefix__/0` AND in `config/config.exs`. Unit test asserts the two copies agree on `["parapet","","public",nil,"custom"]`. `__schema__(:prefix)` must return `"parapet"` for all six under default config.
- **D-06:** `config/` does not exist today — create net-new `config/config.exs` reading `PARAPET_SCHEMA_PREFIX` (default-on `"parapet"`) so `compile_env` has a real override source. Apply same `nil|""|"public" ⇒ nil` normalization at config layer.
- **D-07:** Do NOT add `config` to `mix.exs` `package.files` (`mix.exs:42-44`). Required action is the negative one of not touching the list.
- **D-08:** Add runtime `schema_prefix/0` helper colocated with `repo/0` in `Parapet.Evidence` (`lib/parapet/evidence.ex:22`), reading runtime config (mirrors `repo/0`'s `Application.get_env` shape). Distinct from compile-time `__prefix__/0`; the two must agree.
- **D-09:** Hand-qualify `test/support/concurrency_bootstrap.ex`: prepend `CREATE SCHEMA IF NOT EXISTS`, qualify every `CREATE TABLE` (6), inline `REFERENCES` (4), `CREATE INDEX ... ON <target>` (11 — qualify the *target table*, not the index name), and the `@tables`-driven `TRUNCATE`. Parameterize by the same resolved prefix the macro uses (not hardcoded `"parapet"`). Leave `schema_migrations` in `public`.
- **D-10:** Done-criterion: full suite green under `schema_prefix: parapet`. Dual-leg proof (green under both `parapet` AND `public` via recompiling CI matrix) is Phase 52 / TEST-03, not here.
- **D-11:** Library-migration prefixing is OUT of Phase 51 → Phase 53 (GEN-06). The five committed `priv/repo/migrations/*.exs` get their `prefix:` later. (User confirmed "Yes, proceed" 2026-06-29.)

### Claude's Discretion
- Exact module/function placement of the macro file (`lib/parapet/spine/schema.ex` is the natural home).
- Whether `__prefix__/0` exposes the compiled value publicly now or in Phase 54 (doctor check needs it; exposing here is harmless — planner's call).

### Deferred Ideas (OUT OF SCOPE — Phases 52/53/54/55/56)
- Propagation regression tests + `to_sql`/`get_meta` per-leg assertions + runtime-`prefix:` static ban guard + dual-prefix recompiling CI matrix → **Phase 52** (PROP-01..03, TEST-03).
- Generators, the `CREATE SCHEMA` migration, and prefixing the five committed `priv/repo/migrations/*.exs` → **Phase 53** (GEN-06).
- `mix parapet.doctor` drift check comparing runtime `schema_prefix/0` vs compiled `__prefix__/0` → **Phase 54** (DOCTOR-01).
- Demo/docs → Phase 55. Contract/release hardening → Phase 56.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PREFIX-01 | Shared `use Parapet.Spine.Schema` base macro for all six spine schemas | Verified all six share identical PK/FK/import lines (incident.ex:11-12,27-28 etc.); house-style `__using__` precedents read; reference macro body from synthesis §2 |
| PREFIX-02 | Compile-time prefix source via `Application.compile_env(:parapet, :schema_prefix, "parapet")` | Confirmed no `compile_env`/`schema_prefix` exists today (clean seam); `__prefix__/0` reference body captured |
| PREFIX-03 | Normalization `nil`/`""`/`"public"` ⇒ unprefixed, single-sourced + agreement test | Reference normalization captured; agreement-test surface specified (`["parapet","","public",nil,"custom"]`) |
| PREFIX-04 | Runtime `schema_prefix/0` helper colocated with `repo/0` in `Parapet.Evidence` | `repo/0` shape captured at evidence.ex:22-26 (`Application.get_env(:parapet, :repo)`) |
| TEST-01 | Net-new `config/config.exs` env seam reading `PARAPET_SCHEMA_PREFIX` | Confirmed `config/` does not exist; `package.files` excludes `config` (mix.exs:42-44) |
| TEST-02 | Test infra (ConcurrencyBootstrap) runs green under `schema_prefix: parapet` | Bootstrap read fully; exact DDL counts enumerated; `schema_migrations` absent from bootstrap (no handling needed) |
</phase_requirements>

## Summary

This phase introduces exactly one new module (`Parapet.Spine.Schema`, a `use Ecto.Schema` wrapper macro), rewires all six spine schemas to it (a net *deletion* of duplicated boilerplate), adds a colocated runtime `schema_prefix/0` to `Parapet.Evidence`, creates the library's first-ever `config/config.exs` as a compile-time env seam, and hand-qualifies the test bootstrap DDL so the full suite passes with the prefix baked in. Propagation to query/insert/Multi/join call sites is automatic and requires zero call-site edits — the live code uses schema *modules* everywhere, so `@schema_prefix` rides every operation. The single risk to watch: **the normalization rule is physically duplicated in `config/config.exs` and `__prefix__/0`** because `config.exs` evaluates before the lib is compiled and cannot call lib code — the two copies can silently drift, which is why D-05 mandates an agreement unit test. Everything is verifiable now except the honest dual-prefix proof, which is correctly deferred to Phase 52.

**Primary recommendation:** Implement the reference macro from synthesis §2 verbatim, switch the six schemas (pure subtraction), add `config/config.exs` + `schema_prefix/0`, and qualify the bootstrap by reading the *same resolved prefix* the macro computes. Then assert `__schema__(:prefix) == "parapet"` across all six and run the full suite green. **One correction to the locked text: the bootstrap has 12 CREATE INDEX statements, not 11 (D-09 undercounts by one).**

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Compile-time prefix resolution + normalization | Library compile-time (macro + `Application.compile_env`) | Config (`config/config.exs`) | `@schema_prefix` is baked into the BEAM module at compile; the env→config→compile_env path is the only seam |
| Prefix propagation to reads/writes | Database/ORM (Ecto schema struct) | — | `@schema_prefix` intrinsic to struct/queryable; rides `Repo.*`, `insert_all`, `Multi`, joins with zero call-site code |
| Runtime prefix introspection | Library runtime (`Evidence.schema_prefix/0`) | Config | Mirrors `repo/0`; consumed by later-phase generators/doctor, not by Phase 51 itself |
| Test schema/table provisioning | Test support (hand-written DDL in `ConcurrencyBootstrap`) | — | Suite uses no migrations; DDL strings must be qualified to match the compiled `@schema_prefix` |

## Locked-Decision Verification Table

| Decision | Status | Evidence (file:line) |
|----------|--------|----------------------|
| **D-01** Macro mirrors house-style `__using__` | ✅ VERIFIED | `runbook.ex:14`, `recovery.ex:63`, `probe.ex:17`, `metrics/validator.ex:12` all expose `defmacro __using__`. `probe.ex:18` and `runbook.ex:15` use the canonical `quote do … end` body. No existing macro wraps `Ecto.Schema` (confirmed — schema-base is net-new). |
| **D-02** Six schemas share identical 4 lines (pure subtraction) | ✅ VERIFIED | All six declare byte-identical `use Ecto.Schema` + `import Ecto.Changeset` + `@primary_key {:id, :binary_id, autogenerate: true}` + `@foreign_key_type :binary_id`. Lines: incident.ex:11-12,27-28; action_item.ex:11-12,24-25; system_event.ex:12-13,15-16; tool_audit.ex:11-12,16-17; timeline_entry.ex:11-12,30-31; action_claim.ex:11-12,27-28. **No deviation.** |
| **D-03** Exclude `action_payload.ex` | ✅ VERIFIED (by scope) | The six live in `lib/parapet/spine/`; `action_payload.ex` is under `lib/parapet/operator/` — outside the changed directory by construction. |
| **D-04** `__prefix__/0` reads `compile_env` + normalizes | ✅ VERIFIED (no conflict) | No existing `Application.compile_env(:parapet, :schema_prefix, …)` anywhere (grep clean). Reference body in synthesis §2 lines 49-56 is the spec. |
| **D-05** Normalization duplicated + agreement test | ✅ VERIFIED (constraint real) | `config/config.exs` runs pre-compile and cannot call lib modules (04-TEST-STRATEGY F0b, line 87) → physical duplication is mandatory, not optional. Agreement test over `["parapet","","public",nil,"custom"]` is the only guard. |
| **D-06** `config/` net-new | ✅ VERIFIED | `ls config` → "No such file or directory". No `config/` references in `mix.exs`. |
| **D-07** `config` NOT in `package.files` | ✅ VERIFIED | `mix.exs:42-44` whitelist = `~w(lib priv priv/static/parapet/fonts/*.woff2 priv/static/parapet/fonts/LICENSE.txt .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* LICENSE* docs)`. **`config` absent.** Action = do not touch. |
| **D-08** `schema_prefix/0` mirrors `repo/0` shape | ✅ VERIFIED | `evidence.ex:22-26`: `def repo do Application.get_env(:parapet, :repo) || raise ArgumentError, …`. Colocation home confirmed. `schema_prefix/0` mirrors with `Application.get_env(:parapet, :schema_prefix, "parapet")` + same normalization. |
| **D-09** Bootstrap counts (6 CREATE TABLE / 4 REFERENCES / 11 CREATE INDEX) | ⚠ CONFLICT (index count) | CREATE TABLE = **6** ✅; REFERENCES = **4** ✅; `CREATE INDEX` = **12** (2 UNIQUE + 10 plain), **not 11**. See `concurrency_bootstrap.ex` lines 46,51,56,84,88,105,109,122,146,150,154,159 — twelve `ON parapet_*` targets, all needing qualification. `@tables` TRUNCATE at line 23 ✅. **schema_migrations: 0 occurrences in bootstrap** — the bootstrap never creates it, so "keep schema_migrations in public" requires *no action here* (it's a concern for the demo app / Track B in later phases). |
| **D-10** Done = suite green under `parapet`; dual-leg = Phase 52 | ✅ VERIFIED (scope) | `test_helper.exs` boots `ConcurrencyRepo` + `ConcurrencyBootstrap.bootstrap!()` + Sandbox manual mode. No CI-matrix machinery exists today; correctly deferred. |
| **D-11** Library-migration prefixing OUT (→ Phase 53) | ✅ VERIFIED (scope) | The five `priv/repo/migrations/*.exs` and generator DDL (`gen.spine.ex`, `gen.archive_indexes.ex`) carry raw `parapet_*` — explicitly left untouched this phase. |

## Standard Stack

This phase adds **zero new dependencies.** It uses only `Ecto.Schema` / `Application.compile_env` / `Application.get_env` already present.

### Core (existing, no install)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` / `ecto_sql` | `~> 3.x` (existing) | `@schema_prefix` compile-time attribute; `__schema__(:prefix)` introspection; `Ecto.get_meta/2` | Native Ecto multi-tenancy-by-prefix mechanism; `__schema__(:prefix)` is stable API ≥ 3.10 (01-PREFIX-MECHANISM §6.5) |

**Installation:** None — no packages added. No `Package Legitimacy Audit` section required (no external installs this phase).

## Architecture Patterns

### System Architecture Diagram

```
PARAPET_SCHEMA_PREFIX (env var, set by CI/operator)
        │
        ▼
config/config.exs  ──(normalize "" / "public" / nil ⇒ nil)──► config :parapet, schema_prefix: <value>
        │                                                                   │
        │  (compile time)                                                   │ (compile time, SAME key)
        ▼                                                                   ▼
Parapet.Spine.Schema.__prefix__/0 ◄── Application.compile_env(:parapet, :schema_prefix, "parapet")
        │  (normalize again — duplicated rule; agreement test pins equality)
        ▼
  @schema_prefix baked into each of:
  Incident · ActionItem · SystemEvent · ToolAudit · TimelineEntry · ActionClaim
        │
        ├──► Repo.all/get/insert/update/delete (schema module) ──► "parapet"."parapet_*"  [zero edits]
        ├──► insert_all(ActionClaim, …)                         ──► "parapet"."parapet_action_claims"
        ├──► Ecto.Multi steps (evidence.ex)                     ──► each step inherits its schema prefix
        └──► spine↔spine joins (mcp/server.ex, circuit_breaker) ──► both legs in "parapet"

TEST PATH (parallel, must agree by construction):
ConcurrencyBootstrap reads the SAME resolved prefix ──► qualifies CREATE TABLE / REFERENCES / ON / TRUNCATE
        └──► CREATE SCHEMA IF NOT EXISTS "<prefix>" (only when prefixed)

RUNTIME INTROSPECTION (not used by Phase 51 logic; for later phases):
Parapet.Evidence.schema_prefix/0 ◄── Application.get_env(:parapet, :schema_prefix, "parapet")
```

### Recommended Project Structure (delta only)
```
lib/parapet/
├── spine/
│   ├── schema.ex          # NEW — Parapet.Spine.Schema base macro (D-01)
│   ├── incident.ex        # EDIT — use Parapet.Spine.Schema (delete 4 dup lines)
│   ├── action_item.ex     # EDIT — same
│   ├── system_event.ex    # EDIT — same
│   ├── tool_audit.ex      # EDIT — same
│   ├── timeline_entry.ex  # EDIT — same
│   └── action_claim.ex    # EDIT — same
└── evidence.ex            # EDIT — add schema_prefix/0 next to repo/0 (D-08)
config/
└── config.exs             # NEW — env seam (D-06); NOT in package.files (D-07)
test/support/
└── concurrency_bootstrap.ex  # EDIT — hand-qualify all DDL (D-09)
```

### Pattern 1: The base-schema macro (reference implementation)
**What:** A `__using__/1` that wraps `use Ecto.Schema` and bakes the normalized compile-time prefix.
**When to use:** All six `lib/parapet/spine/*.ex`.
**Example:**
```elixir
# Source: 00-SYNTHESIS.md §2 (lines 38-56) + 01-PREFIX-MECHANISM.md §2.1 (verbatim reference)
defmodule Parapet.Spine.Schema do
  @moduledoc """
  Shared base for all Parapet spine schemas. Replaces `use Ecto.Schema`.
  Centralizes the Postgres schema prefix — the only place the prefix is named.
  Resolved at COMPILE TIME from `config :parapet, :schema_prefix` (default "parapet").
  `nil`/`""`/`"public"` mean "no prefix" (legacy/public behavior). Runtime `prefix:` is BANNED.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      @primary_key {:id, :binary_id, autogenerate: true}   # dedup: all 6 already declare this
      @foreign_key_type :binary_id
      @schema_prefix Parapet.Spine.Schema.__prefix__()
    end
  end

  @doc false
  def __prefix__ do
    case Application.compile_env(:parapet, :schema_prefix, "parapet") do
      p when p in [nil, "", "public"] -> nil
      other when is_binary(other) -> other
      other when is_atom(other) -> Atom.to_string(other)
    end
  end
end
```

### Pattern 2: Spine schema before/after (pure subtraction)
```elixir
# Source: live incident.ex:11-12,27-28 (before) + 01-PREFIX-MECHANISM §2.2 (after)
# BEFORE
use Ecto.Schema
import Ecto.Changeset
@primary_key {:id, :binary_id, autogenerate: true}
@foreign_key_type :binary_id
schema "parapet_incidents" do …

# AFTER
use Parapet.Spine.Schema        # replaces the 4 lines above
schema "parapet_incidents" do … # table name UNCHANGED — final identifier "parapet"."parapet_incidents"
```
Note: keep the `@type t :: %__MODULE__{…}` blocks and any `alias`/field declarations — only the four boilerplate lines move into the macro. `@triage_fields` and similar module attributes interleaved between `import` and `@primary_key` (e.g. incident.ex:14-25) must be preserved.

### Pattern 3: Runtime helper colocated with `repo/0`
```elixir
# Source: evidence.ex:22-26 (repo/0 shape) — mirror it
def schema_prefix do
  case Application.get_env(:parapet, :schema_prefix, "parapet") do
    p when p in [nil, "", "public"] -> nil
    other when is_binary(other) -> other
    other when is_atom(other) -> Atom.to_string(other)
  end
end
```

### Pattern 4: `config/config.exs` env seam (duplicated normalization)
```elixir
# Source: 04-TEST-STRATEGY §2.2 (lines 59-81)
import Config

schema_prefix =
  case System.get_env("PARAPET_SCHEMA_PREFIX") do
    nil -> "parapet"   # default-on
    "" -> nil          # explicit opt-out
    "public" -> nil    # alias for unprefixed
    other -> other
  end

config :parapet, schema_prefix: schema_prefix
```
> ⚠ This normalization is the *second copy* of the D-05 rule. It MUST agree with `__prefix__/0` on `["parapet","","public",nil,"custom"]`, enforced by a unit test. It cannot call `Parapet.Spine.Schema.__prefix__/0` because config.exs runs before the lib compiles.

### Pattern 5: Bootstrap qualification (read resolved prefix, not a literal)
```elixir
# Source: 04-TEST-STRATEGY §3.2 (lines 182-243) adapted to live concurrency_bootstrap.ex
@prefix (case Application.compile_env(:parapet, :schema_prefix, "parapet") do
           p when p in [nil, "", "public"] -> nil
           p -> p
         end)

defp q(table), do: if(@prefix, do: ~s("#{@prefix}"."#{table}"), else: ~s("#{table}"))

def bootstrap! do
  if @prefix, do: SQL.query!(ConcurrencyRepo, ~s(CREATE SCHEMA IF NOT EXISTS "#{@prefix}"), [])
  Enum.each(ddl_statements(), &SQL.query!(ConcurrencyRepo, &1, []))
end
# Every CREATE TABLE name, every REFERENCES target, every CREATE INDEX `ON` target,
# and the TRUNCATE list use q(table). Index NAMES stay bare (see Landmine 1).
```

### Anti-Patterns to Avoid
- **Hardcoding `"parapet"` in the bootstrap** — breaks the `public`/unprefixed leg (Phase 52 needs the same code to produce unprefixed DDL). Read the resolved prefix.
- **Qualifying the index *name*** (`CREATE INDEX parapet.idx_name`) — invalid SQL; an index lives in its table's schema automatically. Qualify only the `ON <table>` target.
- **Sourcing `:schema_prefix` from `runtime.exs`** — `compile_env` reads compile-time config only; Elixir raises a mismatch if a `compile_env` key comes from runtime config. Must be `config/config.exs`.
- **Calling lib code from `config/config.exs`** — config evaluates pre-compile; the lib isn't compiled yet. Duplicate the literal.
- **Renaming tables** — the double `parapet`.`parapet_incidents` is intentional and harmless; renaming is a needless breaking change and out of scope.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-call-site prefix threading | Pass `prefix:` to every `Repo`/`insert_all`/`Multi` call | Compile-time `@schema_prefix` on the schema | Ecto's read/write precedence is asymmetric — a stray runtime `prefix:` wins on writes but can lose on reads (split-brain). 01-PREFIX-MECHANISM §3.4 |
| Connection-level schema routing | `SET search_path` on checkout | Query-prefix only (`@schema_prefix`) | Rails Apartment abandoned `search_path` over leak/pooling bugs; breaks public-resident extensions. 01-PREFIX-MECHANISM §1 |
| Reading the compiled prefix in a test | Build a struct and inspect | `Mod.__schema__(:prefix)` | Stable Ecto API ≥ 3.10; no struct-building needed |

**Key insight:** The uniform single prefix across all six schemas means no join ever spans `parapet` + `public`, so propagation is correct by construction with zero call-site edits — this is the entire reason the compile-time mechanism was chosen over runtime prefixing.

## Runtime State Inventory

> This phase is a code/config change (compile-time attribute + new file + test DDL). It does NOT migrate any stored data — existing adopters opt in only, and the library's own test DB is rebuilt from `bootstrap!/0` each run.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None for Phase 51.** The compiled `@schema_prefix` changes where *new* SQL points; no existing rows move. Actual data movement (`SET SCHEMA`) is Track B / Phase 54. | None this phase |
| Live service config | **None.** No external service holds the prefix; it's a compile-time constant baked into the BEAM. | None |
| OS-registered state | **None.** No OS-level registration references the schema prefix. | None |
| Secrets/env vars | `PARAPET_SCHEMA_PREFIX` is newly *read* by `config/config.exs` (D-06). It is an input seam, not a secret; default-on `"parapet"` when unset. | Document the env var; CI sets it in Phase 52 |
| Build artifacts | Changing `:schema_prefix` after a build requires `mix deps.compile parapet --force` (compile_env is baked). For Phase 51 the default `"parapet"` is the only value the lib build sees. | Note recompile requirement (CI matrix lands Phase 52) |

## Common Pitfalls

### Pitfall 1: Index-name qualification breaks DDL
**What goes wrong:** Qualifying the index *name* (`CREATE INDEX "parapet"."idx" ON …`) is invalid Postgres.
**Why it happens:** Mechanical "qualify everything `parapet_`" sweep hits the index name too.
**How to avoid:** Qualify only the `ON <table>` target; leave the 12 index names bare. An index is implicitly created in its table's schema.
**Warning signs:** `syntax error at or near "."` on `CREATE INDEX` during `bootstrap!/0`.

### Pitfall 2: Normalization drift between config.exs and `__prefix__/0`
**What goes wrong:** The two duplicated copies of the `nil|""|"public" ⇒ nil` rule diverge (e.g. one forgets `""`).
**Why it happens:** config.exs cannot call lib code, forcing physical duplication (D-05).
**How to avoid:** Mandatory agreement unit test over `["parapet","","public",nil,"custom"]` asserting both implementations map every input identically.
**Warning signs:** A future config value that compiles fine but the bootstrap qualifies differently than the schemas.

### Pitfall 3: D-09 index count is wrong (11 vs actual 12)
**What goes wrong:** Planner trusts "11 CREATE INDEX" and a verification step expects 11 qualified `ON` targets.
**Why it happens:** The locked text undercounts by one.
**How to avoid:** Qualify all **12** `ON parapet_*` targets (lines 46,51,56,84,88,105,109,122,146,150,154,159). The VALIDATION check should count 12, not 11.
**Warning signs:** One unqualified index `ON` clause silently creating an index against a `public` (nonexistent under the prefixed leg) table → `relation does not exist`.

### Pitfall 4: `schema_migrations` is not in the bootstrap at all
**What goes wrong:** Planner adds a step to "keep schema_migrations in public" inside `concurrency_bootstrap.ex`.
**Why it happens:** The synthesis/test-strategy docs discuss `schema_migrations` (F6/F13) for the *demo app* and *Track B*, not the concurrency bootstrap.
**How to avoid:** Verified `schema_migrations` has **0 occurrences** in `concurrency_bootstrap.ex` — no action needed here. It is a later-phase concern.
**Warning signs:** A spurious `schema_migrations` qualification task in the plan.

### Pitfall 5: Preserving interleaved module attributes during the macro swap
**What goes wrong:** Deleting the 4 boilerplate lines accidentally removes adjacent attributes (`@triage_fields`, `@type t`, `alias`).
**Why it happens:** In several files the 4 lines are not contiguous — e.g. incident.ex has `@triage_fields` (14-25) and `@type t` (29-39) *between* `import` (12) and `@primary_key` (27).
**How to avoid:** Surgically delete only `use Ecto.Schema`, `import Ecto.Changeset`, `@primary_key {...}`, `@foreign_key_type :binary_id`; leave everything else.
**Warning signs:** Compile error on a now-undefined `@triage_fields` or a missing `alias`.

## Code Examples

See Patterns 1–5 above — all five are the implementation-ready bodies, sourced from synthesis §2 / 01-PREFIX-MECHANISM §2 / 04-TEST-STRATEGY §2-3 and reconciled against live code.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Six schemas each declare `@primary_key`/`@foreign_key_type`/`import` | Single `use Parapet.Spine.Schema` macro | v1.7 Phase 51 | Net deletion of boilerplate; single seam for the prefix |
| No schema prefix (`schema "parapet_incidents"` → `public.parapet_incidents`) | `@schema_prefix "parapet"` → `parapet.parapet_incidents` | v1.7 Phase 51 (default-on for new installs) | Existing adopters opt in only; `nil`/`""`/`"public"` keep byte-identical legacy SQL |

**Deprecated/outdated:** Nothing removed. Runtime `prefix:` and `search_path` are *banned* (never were used here — grep confirms zero offenders).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `__schema__(:prefix)` returns the compiled `@schema_prefix` and is stable in the project's Ecto version | Validation Architecture | If the Ecto version predates this introspection, the agreement test must build a struct + `Ecto.get_meta/2` instead. [ASSUMED from 01-PREFIX-MECHANISM §6.5 — verify against `mix.lock` ecto version] |
| A2 | `config/config.exs` is auto-loaded by Mix for the `:parapet` app's own build (no explicit import needed) | TEST-01 | If a wrapper/`runtime.exs` indirection is needed, the seam wiring differs. [ASSUMED — standard Mix behavior; config/config.exs is the conventional default-loaded file] |

**Note:** Both assumptions are low-risk standard-Ecto/standard-Mix behavior; flagged for the planner to confirm against `mix.lock` if a verification step fails.

## Validation Architecture

> nyquist_validation key absent in `.planning/config.json` → treated as ENABLED. This section drives the Nyquist VALIDATION.md.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`test_helper.exs` → `ExUnit.start()`) |
| Config file | none (no `config/` today; D-06 adds `config/config.exs` as a compile seam, not test config) |
| Quick run command | `mix test test/parapet/spine/` (scoped to spine + new prefix tests) |
| Full suite command | `mix test` |
| Test DB bootstrap | `Parapet.TestSupport.ConcurrencyBootstrap.bootstrap!/0` (hand-written DDL, no migrations) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PREFIX-01 | All six schemas `use Parapet.Spine.Schema` and compile | unit | `mix test test/parapet/spine/schema_test.exs` | ❌ Wave 0 |
| PREFIX-01/02 | `__schema__(:prefix) == "parapet"` for all six under default config | unit | `mix test test/parapet/spine/schema_test.exs -x` (assert across `[Incident, ActionItem, SystemEvent, ToolAudit, TimelineEntry, ActionClaim]`) | ❌ Wave 0 |
| PREFIX-03 | Normalization agreement: `__prefix__/0` and config.exs copy map `["parapet","","public",nil,"custom"]` identically | unit | `mix test test/parapet/spine/schema_test.exs` (agreement test) | ❌ Wave 0 |
| PREFIX-03 | `nil`/`""`/`"public"` ⇒ byte-identical legacy SQL (no qualifier) | unit | assert `__prefix__/0` returns `nil` for each via direct call (compile-time const can't be flipped in-suite — assert the *function*, not the baked attr) | ❌ Wave 0 |
| PREFIX-04 | `Evidence.schema_prefix/0` returns `"parapet"` (default) and normalizes runtime config | unit | `mix test test/parapet/evidence_test.exs` (or new) | ❌ Wave 0 (extend existing if present) |
| TEST-01 | `config/config.exs` reads `PARAPET_SCHEMA_PREFIX`; absent ⇒ `"parapet"` | unit (indirect) | covered by the agreement test asserting config copy's mapping | ❌ Wave 0 |
| TEST-01 | `config` excluded from Hex package | unit | `mix test` assertion on `Mix.Project.config()[:package][:files]` not containing `"config"` (optional belt-and-suspenders) | ⚠ optional |
| TEST-02 | Full suite green under `schema_prefix: parapet` (bootstrap qualifies all DDL) | suite-green | `mix test` (entire suite; bootstrap creates `parapet` schema + qualified tables) | ✅ existing suite, runs under new prefix |

### Specific observable checks (verbatim, for VALIDATION.md)
1. **Agreement unit test** — `["parapet","","public",nil,"custom"]` mapped identically by `Parapet.Spine.Schema.__prefix__/0` (called per-input via a swappable resolver or a pure helper) and the config.exs normalization. Expected: `["parapet", nil, nil, nil, "custom"]` from both. **Directly testable now.**
2. **`__schema__(:prefix) == "parapet"`** for all six spine modules under default config. **Directly testable now.**
3. **Byte-identical legacy SQL** for `nil`/`""`/`"public"` — assert `__prefix__/0` (and `schema_prefix/0`) return `nil` for each input. (Cannot flip the baked `@schema_prefix` in-suite — assert the resolver function, not the compiled attribute. The *compiled* unprefixed leg is Phase 52's recompiling matrix.) **Resolver directly testable now; compiled-leg backstop deferred to Phase 52.**
4. **Full suite green under `schema_prefix: parapet`** — `mix test` passes end-to-end with the qualified bootstrap creating `"parapet"."parapet_*"` and `CREATE SCHEMA IF NOT EXISTS "parapet"`. **Directly testable now (this is D-10's done-criterion).**
5. **Bootstrap qualifies 6 tables / 4 references / 12 index `ON` targets / TRUNCATE list** — structurally verified by the suite running green (any missed qualification → `relation does not exist`). **Directly testable now.**

### Deferred to Phase 52 (backstops, NOT Phase 51 gates)
- Compiled **unprefixed** leg green (recompiling CI matrix axis `schema_prefix: ['parapet','public']` + prefix-namespaced `_build` cache + `mix compile --force`).
- `to_sql`/`Ecto.get_meta` per-leg propagation assertions on selects/joins/insert_all/Multi.
- Static runtime-`prefix:` ban guard over `lib/`.
- Negative "no bare `parapet_incidents`" assertion under the prefixed leg.

### Wave 0 Gaps
- [ ] `test/parapet/spine/schema_test.exs` — covers PREFIX-01/02/03 (`__schema__(:prefix)` across six + normalization agreement + `__prefix__/0` legacy-nil cases)
- [ ] Runtime `schema_prefix/0` assertion — extend `test/parapet/evidence_test.exs` if it exists, else add (PREFIX-04)
- [ ] No new conftest/fixtures needed — `ConcurrencyCase`/`ConcurrencyBootstrap` already provide the DB harness
- [ ] No framework install — ExUnit already present

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (test DB `parapet_concurrency_test`) | TEST-02 suite-green + `CREATE SCHEMA` | ✓ (assumed — existing suite uses it; CI uses `postgres:16-alpine`) | — | none (suite requires it) |
| Ecto `__schema__(:prefix)` introspection | Validation checks 1-2 | ✓ (existing ecto dep) | per `mix.lock` (verify ≥ 3.10) | build struct + `Ecto.get_meta/2` |

**Missing dependencies with no fallback:** none identified — all tooling (ExUnit, Postgres, Ecto) is already in use.

## Scope Guardrails

The planner MUST NOT pull these into Phase 51 (they belong to later phases per D-11 + Deferred Ideas):

- **Phase 52 (PROP-01..03, TEST-03):** propagation regression tests (`to_sql`/`get_meta`), runtime-`prefix:` static ban guard, dual-prefix recompiling CI matrix + `_build` cache namespacing + `mix compile --force`, negative bare-table assertion.
- **Phase 53 (GEN-06):** prefixing the five committed `priv/repo/migrations/*.exs`; the `*_create_parapet_schema.exs` migration; generator DDL changes (`gen.spine.ex`, `gen.archive_indexes.ex`); `--schema`/`--no-create-schema` flags; Igniter `configure_new`.
- **Phase 54 (DOCTOR-01):** `mix parapet.doctor` drift check comparing runtime `schema_prefix/0` vs compiled `__prefix__/0`; Track B `SET SCHEMA` move task + round-trip test (throwaway DB).
- **Phase 55:** demo app end-to-end into `parapet`; `docs/upgrade-1.x.md`; deployment/README deltas; demo-smoke `information_schema.tables` assertion.
- **Phase 56:** CHANGELOG `feat` "no action required" banner; `verify.public_api`/telemetry/compile-out release gates; semver/release notes.

Also explicitly OUT this phase: renaming any `parapet_*` table; touching `lib/parapet/operator/action_payload.ex` (D-03); moving `schema_migrations`; adding `config` to `package.files` (D-07).

## Sources

### Primary (HIGH confidence)
- `.planning/phases/51-prefix-core-test-seam/51-CONTEXT.md` — locked decisions D-01…D-11 (authoritative)
- `.planning/research/v1.7/00-SYNTHESIS.md` §1, §2, §6 — locked decisions + reference macro body + testing prerequisites
- `.planning/research/v1.7/01-PREFIX-MECHANISM.md` §2-4, §6 — macro design, propagation proof, `__schema__(:prefix)` contract
- `.planning/research/v1.7/04-TEST-STRATEGY.md` §0, §2-3 — config seam, bootstrap qualification, footguns F0-F6
- Live code (verified this session): `lib/parapet/spine/{incident,action_item,system_event,tool_audit,timeline_entry,action_claim}.ex`, `lib/parapet/evidence.ex:22-26`, `lib/parapet/runbook.ex:14`, `lib/parapet/probe.ex:17`, `mix.exs:42-44`, `test/support/concurrency_bootstrap.ex` (full), `test/test_helper.exs`

### Secondary (MEDIUM confidence)
- Ecto multi-tenancy guide (cited in dimension docs) — read/write precedence, `@schema_prefix` semantics

### Tertiary (LOW confidence)
- A1/A2 assumptions (see Assumptions Log) — standard Ecto/Mix behavior, verify against `mix.lock` if a check fails

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new deps; native Ecto mechanism verified against six live schemas
- Architecture: HIGH — reference macro from synthesis §2, all integration points confirmed in live code
- Pitfalls: HIGH — D-09 index miscount caught by direct grep (12 vs 11); schema_migrations absence verified; interleaved-attribute hazard verified per-file

**Research date:** 2026-06-29
**Valid until:** 2026-07-29 (stable — internal lib refactor, no fast-moving external deps)
