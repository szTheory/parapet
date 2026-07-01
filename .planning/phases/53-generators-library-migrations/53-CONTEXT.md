# Phase 53: Generators & Library Migrations - Context

**Gathered:** 2026-07-01 (assumptions mode + per-fork deep research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Generators and Parapet's committed library migrations create the spine under the
configured Postgres schema: stamping `prefix:` on every `create table` / `references/2` /
index, writing `config :parapet, :schema_prefix` without clobbering adopters, behind a
least-privilege `--no-create-schema` hatch, with one shared prefix resolver
(`flag > existing config > default`) consumed by `gen.spine`, `gen.archive_indexes`, and
`install`. Requirements GEN-01..GEN-07.

**Out of scope (belongs to Phase 54):** the adopter-facing `mix parapet.gen.schema.move`
`ALTER TABLE … SET SCHEMA` upgrade task and the doctor drift check. Phase 53 owns
"new installs are *born* in the schema"; Phase 54 owns "existing installs *move* into it."
Do not build a `SET SCHEMA` move migration in this phase.
</domain>

<decisions>
## Implementation Decisions

### Cross-cutting invariant (the spine of all decisions below)
- **D-00:** There is exactly **one** prefix source in the codebase: `Parapet.Spine.Schema`.
  It owns a single `@default_prefix "parapet"` literal, `normalize/1`, `safe_ident!/1`, the
  compile-time `__prefix__/0` (built by Phases 51–52), and the new generate-time
  `resolve_prefix/2` (D-05). Every decision below reads *through* this module; nothing
  re-implements normalization, the default literal, or the allowlist. This is what GEN-05
  buys, made enforceable by construction rather than by review.

### A. Prefix-stamping in GENERATED (adopter-facing) migrations — GEN-02
- **D-01:** `gen.spine` and `gen.archive_indexes` stamp a **generate-time literal**
  `prefix: "<resolved>"` — resolved once at generation and interpolated into the emitted
  heredoc as a plain string — onto **every** `create table`, **each** `references/2`, and
  **every** `create index`/`create unique_index`. Chosen over (a) schema-qualified table
  atoms `:"parapet.foo"` — **disqualified on correctness**: Postgres treats the dotted string
  as a single quoted identifier, so the FK targets a nonexistent `public."parapet.foo"` and
  index/constraint names are contaminated (breaks GEN-02); and (b) a runtime
  `@prefix = …__prefix__()` call baked into the *adopter's* migration source — reintroduces
  the banned compile-vs-runtime split-brain (a migration is a historical snapshot; a runtime
  read can drift from the tables it already created).
- **D-02:** `references/2` is stamped with its **own explicit** `prefix:` equal to the
  referenced table's prefix — do **not** rely on Ecto's implicit inheritance from the
  enclosing `create table` block (GEN-02 "its own prefix"; keeps the FK target's schema
  legible to a reviewer). `create index` **never** inherits the table prefix, so it must
  carry an explicit `prefix:` too.
- **D-03:** FK constraint names and index names stay **byte-identical** to the unprefixed
  baseline. Verified in Ecto source: the Postgres adapter stores `:prefix` and `:name` in
  separate `%Table{}` fields and builds `"<table>_<col>_fkey"` / `"<table>_<cols>_index"`
  from `:name` only (`ecto_sql .../postgres/connection.ex:1264,1858,1884-1885`,
  `ecto/migration.ex:836,1041-1045`). `prefix:` is the mechanism that preserves them.
- **D-04:** **Nil/legacy leg is byte-identical.** When the resolved prefix is `nil`
  (i.e. config is `nil`/`""`/`"public"`), the generator emits **no** `prefix:` opt at all
  (not `prefix: nil`, not `prefix: ""`) so the generated migration is byte-for-byte the
  current pre-v1.7 output. `safe_ident!/1` is applied to the value **before** interpolation
  so an unsafe prefix can never reach the migration string.

### B. Shared prefix resolver — GEN-03, GEN-05
- **D-05:** Add `Parapet.Spine.Schema.resolve_prefix/2` — a **pure** core
  `(flag, config) -> {:ok, normalized} | {:conflict, normalized_flag, normalized_config}`
  (table-testable with zero Igniter scaffolding) — plus a thin Igniter-aware arity that
  extracts `igniter.args.options[:schema]` and `Application.get_env(:parapet, :schema_prefix)`
  and delegates to the core. Both paths run through `normalize/1` → `safe_ident!/1`, so the
  allowlist guard is unconditional. Lives on `Parapet.Spine.Schema` (**not** a new
  `PrefixResolver` module, **not** inlined per-task) so the single-source invariant (D-00)
  holds by construction.
- **D-06:** Precedence **`flag > existing config > default`**. Conflict (normalized flag ≠
  normalized config) → **flag wins for this run** + `Igniter.add_warning/2` instructing the
  operator to reconcile `config/config.exs` and run `mix deps.compile parapet --force`.
  **Never clobber config, never crash.** (Only `safe_ident!/1` raises, and only on a
  malformed identifier — a distinct failure mode from a conflict.)
- **D-07:** `install` and standalone `gen.spine` **persist** the resolved value via
  `Igniter.Project.Config.configure_new/6` (no-clobber). This makes precedence
  self-consistent: once written, config is the standing source and the next compile's
  `compile_env` (→ `__prefix__/0`) reads exactly what the last generate resolved. `configure_new`
  never overwrites an operator's hand-set value (GEN-03), so a subsequent conflicting `--schema`
  warns (D-06) rather than silently rewriting.
- **D-08:** All three tasks (`install`, `gen.spine`, `gen.archive_indexes`) set
  `%Igniter.Mix.Task.Info{group: :parapet}` so an operator types `--schema foo` once and
  Igniter routes it to every composed task (no `--parapet.gen.spine.schema` verbosity).
- **D-09:** **Compile-vs-runtime firewall.** `resolve_prefix/2` = **generate-time** reader
  (adopter's live config, via `Application.get_env`). `__prefix__/0` = **compile-time** reader
  (frozen library value, via `compile_env`). They share a module and are documented as a
  matched pair with an explicit "do not cross the streams" note; `resolve_prefix` must never
  call `__prefix__/0` or touch `@prefix`, and vice versa.

### C. Parapet's OWN committed migrations (5 lib + 3 demo) — GEN-06
- **D-10:** **Edit in place** — stamp `prefix:` directly into the already-committed files:
  `priv/repo/migrations/*.exs` (5, module ns `Parapet.Repo.Migrations.*`) and
  `examples/demo_app/priv/repo/migrations/*.exs` (3). **No** additive `SET SCHEMA` move
  migration (that is Phase 54's chartered job — duplicating it here would create two
  `SET SCHEMA` code paths and make the greenfield demo exercise a move it never needed).
  Safe because adopters never execute these (no `Parapet.Repo`; inert in the tarball) and
  they only ever run from-scratch (test bootstrap / ephemeral CI DB) — zero persistent-DB
  hazard. "Never edit a migration" is scoped to migrations that ran against a durable,
  non-reproducible DB; neither file set qualifies. Peer precedent: ash_postgres regenerates
  its dev migrations; Phoenix example apps favor pristine-runnable-from-scratch.
- **D-11:** In these committed files, bind the prefix via the **compile-time**
  `Parapet.Spine.Schema.__prefix__()` (leg-aware) — **not** a hard-coded `"parapet"` literal
  and **not** the generate-time `resolve_prefix/2`. Rationale: unlike adopter output, these
  files *are* recompiled under the Phase-52 dual-prefix CI matrix, so referencing the compiled
  source keeps the `public` leg byte-identical automatically. This is the deliberate
  counterpart to D-01: generated adopter migrations bake a **literal** (frozen snapshot, not
  recompiled); Parapet's own migrations reference **`__prefix__()`** (recompiled, from-scratch
  only) — same single source, different binding time, no split-brain in either.
- **D-12:** Keep migration **timestamps unchanged** (renaming to force re-run breaks the
  `add_lease_until_backfill_test` version pin and pointlessly rewrites history). Defuse the
  stale-dev-DB trap (an already-migrated local DB won't pick up the edits; bootstrap's
  `CREATE … IF NOT EXISTS` would leave stale public tables) with a documented **one-time**
  contributor step: `mix demo.reset` (demo) + drop `parapet_concurrency_test` (lib). Record
  this in the CHANGELOG/PR body and the Phase-55 upgrade doc.

### D. First-ordered schema migration + `--no-create-schema` hatch — GEN-01, GEN-04
- **D-13:** Emit a dedicated `00000000000000_create_parapet_schema.exs` via Igniter's
  `gen_migration` **`:timestamp: "00000000000000"`** option. Ecto's migrator sorts by
  `Integer.parse(Path.rootname(base))` → version `0`, strictly less than every real
  `20260521…` spine timestamp, so it sorts **first** deterministically and `mix ecto.migrate`
  accepts it. Chosen over `earliest_spine_ts - 1` (fragile: re-reads siblings at generate
  time, breaks on re-timestamping, opaque filename). The fixed sentinel is self-documenting
  ("intentionally first"); the deterministic path is also what enables the golden test (D-16).
  Note the Parapet-vs-Parapet collision caveat in the migration `@moduledoc`; installer no-ops
  if the file exists.
- **D-14:** Body = `execute("CREATE SCHEMA IF NOT EXISTS parapet")` up /
  **non-cascading** `execute("DROP SCHEMA IF EXISTS parapet")` down. Reverses correctly by
  construction: first-on-up ⟹ last-on-down, so `mix ecto.rollback` drops spine tables (higher
  versions) *before* the empty schema. Non-cascading is a **deliberate fail-closed safety
  feature** — `DROP SCHEMA` raises `2BP01` if any object remains, protecting the evidence
  spine from accidental data loss. **Do not add `CASCADE`.** Document "roll back the spine
  table migrations before this one can drop the schema." Sentinel is emitted **only** when the
  resolved prefix is non-nil.
- **D-15:** Flag surface (Oban-verbatim *semantics/naming*): `Info` schema
  `[schema: :string, create_schema: :boolean]`, defaults `[schema: "parapet", create_schema: true]`,
  alias `s: :schema`. `--no-create-schema` is OptionParser's negation of the `create_schema`
  boolean → **omits the sentinel migration file entirely** (cleaner than Oban's in-line
  boolean), keeps every table `prefix:`-stamped, and prints the DBA remediation. The
  remediation surfaces via **`Igniter.add_notice`** (consistent with the existing
  `install.ex` summary panel; beats `Mix.shell().info` which scrolls off, and a generated
  README which is undiscoverable). Remediation copy leads with the least-surprising happy path
  and shows the split-role fallback:
  ```
  -- Run once as a privileged role (DBA / schema owner):
  CREATE SCHEMA IF NOT EXISTS parapet AUTHORIZATION your_app_role;

  -- Split-role fallback (schema owned by a separate role):
  GRANT USAGE  ON SCHEMA parapet TO your_app_role;   -- resolve the schema
  GRANT CREATE ON SCHEMA parapet TO your_app_role;   -- create tables/indexes during migrate
  -- then: mix ecto.migrate  (no CREATE SCHEMA migration was generated)
  ```
  Key least-privilege insight: with `create_schema: false` the app role needs `USAGE` +
  `CREATE ON SCHEMA` (not `CREATE ON DATABASE`); the `AUTHORIZATION` form makes the app role
  owner so no explicit `GRANT` is needed.

### E. Generator-output tests — GEN-07
- **D-16:** Extend the existing AST substring asserts (`contains_snippet?` /
  `Igniter.Test.assert_creates`) with: a **`prefix:` count-guard** (`Regex.scan`) proving every
  table/reference/index carries it under the `parapet` leg; **one** golden `assert_creates/3`
  exact-bytes test on the **schema migration only** (deterministic path from D-13); a
  `refute`-omission test that `--no-create-schema` produces no `create_parapet_schema` file;
  the **FK-constraint-name-unchanged** assertion (e.g. `parapet_tool_audits_timeline_entry_id_fkey`)
  under **both** legs; and a **nil-leg byte-identical golden** proving the `public` leg emits
  today's unprefixed output. Retain the PROP-02 guard's `lib/mix/tasks/` carve-out and add a
  positive companion: generated migration source *contains* literal `prefix:` when the compiled
  prefix is non-nil, and contains none when nil.

### Claude's Discretion
- Exact `resolve_prefix/2` return-tuple shape and warning/notice wording (D-05, D-06, D-15).
- Whether the DBA remediation notice lands on `gen.spine` alone or is folded into the
  `install` summary's "Host follow-up" section (both surface it; D-15).
- Golden-file exact byte layout (formatter-driven) for the schema migration (D-16).
- Whether `resolve_prefix`'s Igniter arity returns the value or a `{igniter, value}` tuple
  (planner's call based on the task pipeline shape).

### Folded Todos
None — STATE.md "Pending Todos" was empty at gather time. (The four Phase-51 WR warnings
were already folded into and closed by Phase 52; WR-04's `safe_ident!` allowlist is the
guard D-05 reuses.)
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — GEN-01..GEN-07 (lines 26–32), the authoritative acceptance criteria.
- `.planning/ROADMAP.md` — Phase 53 goal + 4 success criteria (lines 97–110); Phase 54 boundary (lines 112+).
- `.planning/phases/51-prefix-core-test-seam/51-CONTEXT.md` — the prefix seam this phase builds on
  (`Parapet.Spine.Schema.__prefix__/0`, normalization; D-11 defers library-migration prefixing here).
- `.planning/phases/52-propagation-proof-guards-ci-dual-prefix-matrix/52-CONTEXT.md` — `normalize/1` +
  `safe_ident!/1` allowlist (D-15/D-18), the PROP-02 static guard + its `lib/mix/tasks/` carve-out
  (D-02), and the dual-prefix CI matrix (D-11..D-14) the `public` leg rides.
- `lib/parapet/spine/schema.ex` — the single prefix source; add `resolve_prefix/2` here (D-05).
- `lib/mix/tasks/parapet.gen.spine.ex`, `lib/mix/tasks/parapet.gen.archive_indexes.ex`,
  `lib/mix/tasks/parapet.install.ex` — the three tasks to thread `--schema` + resolver + `group: :parapet`.
- `test/support/concurrency_bootstrap.ex` — the already-prefixed raw-DDL template + `q/1` two-leg rule.
- `priv/repo/migrations/*.exs` (5) and `examples/demo_app/priv/repo/migrations/*.exs` (3) — edited in place (D-10).
- `test/mix/tasks/parapet.gen.spine_test.exs`, `.../parapet.gen.archive_indexes_test.exs` — the
  `assert_creates/3` + FK-name assertion patterns GEN-07 extends.

**External docs (verify at plan time, not user decisions):**
- Oban `Oban.Migration` `prefix` / `create_schema` option names + defaults (GEN-04 "Oban-verbatim"
  refers to these, not an installer flag — Oban's installer has no `--prefix`).
- Igniter `configure_new/6`, `add_warning/2`, `add_notice/2`, `%Info{group:}`, `gen_migration :timestamp`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Spine.Schema.__prefix__/0` / `normalize/1` / `safe_ident!/1` — the compile-time seam;
  `resolve_prefix/2` becomes the fourth member (generate-time counterpart).
- The generators already build migration bodies as interpolated heredocs passed to
  `Igniter.Libs.Ecto.gen_migration/4` — injecting `prefix: #{resolved}` is a natural seam.
- `parapet.install.ex` already reads `igniter.args.options[...]` and funnels guidance through
  `Igniter.add_notice` (the summary panel) — the pattern D-15's remediation reuses.
- `concurrency_bootstrap.ex` already proves the "qualify CREATE/REFERENCES/index-ON target,
  leave index *names* bare" rule and the two-leg (`parapet`/`public`) behavior.
- `Igniter.Test.assert_creates/3` (used in existing gen tests) — the byte-level golden tool for D-16.

### Established Patterns
- Ecto keeps `%Table{prefix:, name:}` separate → `prefix:` never touches constraint/index names (D-03).
- Ecto migrator sorts by integer timestamp prefix → sentinel `00000000000000` sorts first (D-13).
- Dual-prefix CI matrix recompiles the lib per leg → committed migrations must reference `__prefix__()`
  (D-11), generated adopter migrations bake a literal (D-01).

### Integration Points
- New `resolve_prefix/2` on `Parapet.Spine.Schema`, consumed by all three mix tasks.
- New sentinel schema migration generated by `gen.spine` (skipped under `--no-create-schema`).
- Config write via `configure_new` into the host's `config/config.exs`.
- Edits to 8 committed migration files (5 lib + 3 demo).
</code_context>

<specifics>
## Specific Ideas

- The A↔C split (generated = literal; committed = `__prefix__()`) is the load-bearing nuance —
  the planner must not "simplify" the committed migrations to a hard literal (breaks the `public`
  CI leg) nor bake a runtime call into generated adopter output (split-brain).
- The non-cascading `DROP SCHEMA` (D-14) is intentional; a reviewer may flag it as "won't drop a
  non-empty schema" — that is the desired fail-closed behavior for an evidence spine.
- "Oban-verbatim" (GEN-04) = option names/defaults from `Oban.Migration`, NOT an Oban installer flag.
</specifics>

<deferred>
## Deferred Ideas

- `mix parapet.gen.schema.move` (`ALTER TABLE … SET SCHEMA` adopter upgrade) + doctor drift check —
  **Phase 54** (UPG-*/DOCTOR-01), explicitly out of Phase 53.
- Optional `ALTER DEFAULT PRIVILEGES … IN SCHEMA parapet GRANT …` for a narrower runtime role than
  the migrator — mention as an optional note in remediation, do not make it the default block (D-15).

### Reviewed Todos (not folded)
None — no pending todos at gather time.
</deferred>
