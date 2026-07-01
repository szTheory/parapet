# Phase 53: Generators & Library Migrations - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 53-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-01
**Phase:** 53-generators-library-migrations
**Mode:** assumptions + per-fork deep research
**Areas analyzed:** Prefix-stamping mechanism · Shared resolver · Committed-migration edits · First-ordered schema migration / `--no-create-schema` · Generator tests

## Assumptions Presented (initial codebase pass)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| A: generated migrations stamp a literal `prefix:` opt (not qualified atoms, not a runtime call) | Likely | `parapet.gen.spine.ex:24-89` heredoc → `gen_migration`; Ecto `prefix:` preserves FK names |
| B: shared resolver on `Parapet.Spine.Schema`, precedence `flag > config > default` | Likely | `schema.ex:41,75-77` single seam; `install.ex:58-63` reads `igniter.args.options` |
| C: edit the 5 lib + 3 demo committed migrations in place | Unclear → **Confident (verified)** | ns `Parapet.Repo.Migrations.*`; `mix.exs:42-44` ships `priv` inert; adopters have no `Parapet.Repo`; D-11 `51-CONTEXT.md:80-83` |
| D: first-ordered golden schema migration + `--no-create-schema` notice via `add_notice` | Likely | GEN-01 "first-ordered"; `gen_migration` stamps `now()`; `install.ex:86` notice pattern |

## Corrections Made

User selected "Let me correct some" then requested — for **all four** areas — a per-fork
deep-research pass (pros/cons/tradeoffs, idiomatic Elixir/Ecto/Igniter, peer-lib lessons +
footguns, DX / API-as-UX, principle of least surprise, coherence with project vision) and a
single coherent one-shot recommendation set. Four `general-purpose` research subagents were
fanned out (one per fork), then synthesized.

Outcome: no assumption was *reversed*, but each was sharpened and the set was made mutually
coherent. Net changes from the initial pass:

- **A:** confirmed literal; qualified atoms **disqualified on correctness** (Postgres reads
  `:"parapet.foo"` as one quoted identifier → FK targets a nonexistent table), proved via Ecto
  source. Added: explicit per-`references` prefix, explicit index prefix, and the nil-leg
  "emit no `prefix:` opt at all" rule for byte-identical legacy output.
- **B:** confirmed location; added the **pure `resolve_prefix/2` core + Igniter arity**,
  the **conflict = flag-wins + warn + never-clobber** rule, **`configure_new` persistence** of
  the resolved value, the **`group: :parapet`** flag-routing companion, and the explicit
  **compile-vs-runtime firewall**. Clarified "Oban-verbatim" = option names/defaults, not a flag.
- **C:** Unclear → **Confident**. Verified adopters never run these files (shipped-but-inert).
  Added the key nuance that committed migrations bind via compile-time **`__prefix__()`**
  (leg-aware for the CI `public` leg), NOT a hard literal and NOT the generate-time resolver —
  the deliberate counterpart to A. Added the stale-dev-DB mitigation and the Phase-54 boundary.
- **D:** confirmed; nailed the mechanism — **sentinel `00000000000000`** via Igniter `:timestamp`
  (Ecto `Integer.parse` → version 0), **non-cascading `DROP SCHEMA`** fail-closed reversibility,
  `--no-create-schema` **omits the file**, and the verbatim **`CREATE SCHEMA … AUTHORIZATION` +
  `GRANT USAGE, CREATE ON SCHEMA`** DBA remediation. Golden test via `assert_creates/3` on the
  deterministic path + `refute`-omission test.

User confirmed "Yes, lock all of it" on the synthesized A–E set.

## External Research

Four parallel `general-purpose` subagents (Forks A/B/C/D). Key sourced facts:

- **Ecto** keeps `%Table{prefix:, name:}` separate; FK/index names derive from `:name` only
  (`ecto_sql .../postgres/connection.ex:1264,1858,1884-1885`, `ecto/migration.ex:836,1041-1045`)
  → `prefix:` preserves constraint names (GEN-02).
- **Ecto migrator** sorts by `Integer.parse(Path.rootname(base))` → `00000000000000` = version 0,
  sorts first, accepted by `mix ecto.migrate`.
- **Oban** (`Oban.Migration`): `prefix` + `create_schema` (default true) options; `create_schema:
  false` is the least-privilege hatch with a verbatim "user can't create schema" rationale. Oban's
  *installer* exposes no `--prefix` — its footgun is hand-synced prefix drift between migration and
  config; Parapet's shared resolver + persistence is the deliberate improvement.
- **ash_postgres** regenerates dev migrations from snapshots (endorses in-place rewrite of
  non-shipped fixtures) and threads explicit per-reference prefixes; issue #247 = generator that
  omitted `CREATE SCHEMA` broke fresh DBs (warning that motivated GEN-01).
- **Igniter**: `configure_new/6` (no-clobber), `add_warning/2`, `add_notice/2`, `%Info{group:}`
  flag routing, `gen_migration` `:timestamp` opt, `Igniter.Test.assert_creates/3` golden tool.

Sources: Oban.Migration / oban installation docs; Ecto.Migration + ecto_sql source; Igniter
Project.Config + writing-generators docs; ash_postgres migrations doc + issue #247; Safe Ecto
Migrations; Phoenix ecto.reset/setup guide.
