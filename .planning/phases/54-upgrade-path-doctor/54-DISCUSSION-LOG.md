# Phase 54: Upgrade Path & Doctor - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-01
**Phase:** 54-upgrade-path-doctor
**Mode:** assumptions + deep decision-fork research
**Areas analyzed:** Doctor check integration · Move task/migration shape · Pre-flight detection · Round-trip test · Track A / UPG-05

## Method

1. `gsd-assumptions-analyzer` produced 5 evidence-backed assumptions (3 research gaps flagged).
2. A general-purpose agent resolved the 3 gaps (PG `SET SCHEMA` behavior, Ecto tx/lock_timeout,
   Igniter generate-time DB reachability).
3. At the user's request, **5 parallel deep-research forks** (one per gray area) each applied the
   full lens checklist — idiomatic Elixir/Ecto/Igniter, peer-library lessons (Oban, ash_postgres,
   strong_migrations, Django, Rails), DBA/SRE, adopter-DX/least-surprise, API-consumer framing — and
   consulted `.planning/research/v1.7/` + `prompts/` prior-art. Returned one coherent recommendation
   set, synthesized into CONTEXT.md D-01…D-20.

## Assumptions Presented (post-research)

### Doctor check integration (DOCTOR-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| One `schema` static check folding drift+existence; drift→:error; existence→:skip when no repo | Confident | `parapet.doctor.ex:22,54,357,516`; Django check framework; Rails abort-if-pending |

### Move task / migration shape (UPG-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Igniter task mirroring gen.spine; real timestamp; `after_begin` lock_timeout; six explicit fully-qualified `execute` lines; `down` never DROP SCHEMA | Confident | `gen.spine.ex`; Ecto.Migration `after_begin`/`execute`; safe-ecto-migrations; Rails SET-SCHEMA playbook |

### Pre-flight detection (UPG-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Missing-table ABORT authoritative at migrate-time (DO-block guard); second-move REFUSE at generate-time via `on_exists: {:error,…}`; inbound-FK/view WARN; generate-time probe advisory-only | Confident | Igniter `ecto.ex:47,59` include_glob/module_exists; Oban migrate-time guard; ash_postgres snapshot |

### Round-trip test (UPG-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Clone backfill test; DEDICATED throwaway DB; own `public` fixture spine (leg-agnostic); catalog assertions re-create nothing; both legs | Confident | `add_lease_until_backfill_test.exs`; `04-TEST-STRATEGY.md` F11–F14; PG SET SCHEMA auto-move |

### Track A / UPG-05 (UPG-01, UPG-05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No runtime install-detection; Track A REQUIRES explicit `schema_prefix: nil`+recompile; do-nothing upgrader fails loud (UndefinedTable); doctor is the backstop; `to_sql`+round-trip pin; regex fitness-function UPG-05 pin | Confident | `schema.ex:81`; `Application.compile_env/3` boot-check semantics; Oban public-default contrast |

## Corrections Made (research vs pre-research assumptions)

### Pre-flight detection (UPG-03)
- **Pre-research lean:** generate-time catalog probe for the missing-table abort (Unclear).
- **Research resolution:** migrate-time authoritative guard (emitted into the migration), generate-time
  only for the rollback-invariant second-move refuse + an advisory probe.
- **Reason:** the DB that matters is the target (prod) at migrate time, not the dev laptop; peer
  generators (ecto.gen.migration, ash_postgres, Oban) avoid live-DB queries at generate time.

### Track A / UPG-05 (UPG-01, UPG-05) — the material finding
- **Pre-research assumption:** UPG-05 satisfied purely by test+doc; "default flips for new installs only"
  taken at face value.
- **Research resolution (uncomfortable truth surfaced on request):** there is no install-detection;
  "new installs only" describes who benefits, not a code gate. An existing adopter who does nothing gets
  a compiled `parapet` prefix over `public` data → **loud `UndefinedTable` first-query failure**. Track A
  genuinely REQUIRES `config :parapet, schema_prefix: nil` + recompile. Honest framing is "your data
  never moves, **but** one line is required to stay on public" — NOT "no action required." This makes the
  doctor drift check load-bearing, not optional.
- **Reason:** `Application.compile_env/3`'s boot-check only fires for explicitly-set config that drifts,
  never for an unset key whose library default changed — so the do-nothing upgrader gets no warning.

## External Research

- **PG `ALTER TABLE … SET SCHEMA`:** moves associated indexes/constraints/PKs/partial-indexes with
  byte-identical names; cross-schema FKs valid; multiple `SET SCHEMA` in one BEGIN/COMMIT supported.
  (postgresql.org/docs/current/sql-altertable.html)
- **Ecto migration tx + locking:** Postgres migrations run in a transaction by default; `SET LOCAL
  lock_timeout` correctly scoped; `SET SCHEMA` takes ACCESS EXCLUSIVE; do NOT set
  `@disable_ddl_transaction`/`@disable_migration_lock`. (ecto-sql hexdocs; safe-ecto-migrations)
- **Igniter generate-time DB:** tasks don't boot the repo; peers avoid live-DB at generate time →
  migrate-time guard is idiomatic. (igniter hexdocs; ash_postgres; ecto.gen.migration)
- **`compile_env` boot-check:** catches only explicitly-set drift, never unset-default change.
  (elixir Application docs; elixir-lang/elixir#11181)
- Peer DX: Django graded `check` + `--fail-level`; Rails `abort_if_pending_migrations`; Oban
  `create_schema: false` least-privilege hatch; strong_migrations inline remediation.
