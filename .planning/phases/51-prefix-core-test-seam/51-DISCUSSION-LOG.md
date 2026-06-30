# Phase 51: Prefix Core & Test Seam - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-29
**Phase:** 51-prefix-core-test-seam
**Mode:** assumptions
**Areas analyzed:** spine-schema dedup, config seam, repo/0 colocation, test bootstrap qualification, propagation grounding, macro precedent, library-migration boundary

## Assumptions Presented

### Spine schema dedup
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| All six spine schemas already declare identical `use Ecto.Schema` + `@primary_key {:id, :binary_id}` + `@foreign_key_type :binary_id` + `import Ecto.Changeset`; switch to `use Parapet.Spine.Schema` is pure subtraction | Confident | `lib/parapet/spine/{incident,action_item,system_event,tool_audit,timeline_entry,action_claim}.ex` headers; synthesis line 43 comment confirmed |
| `lib/parapet/operator/action_payload.ex` is a 7th `use Ecto.Schema` but NOT a spine table — leave alone | Confident | under `operator/`, no `parapet_` table; the six `schema "parapet_*"` come only from `spine/` |

### Config seam
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `config/` does not exist; `config/config.exs` is net-new; `compile_env` resolves to `"parapet"` default today | Confident | `ls config/` → not found; zero `compile_env`/`config_env` hits in `lib/`+`test/` |
| `config` already excluded from `package.files`, so no action needed to keep it from shipping | Confident | `mix.exs:42-44` whitelist omits `config` |

### repo/0 colocation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `repo/0` is in `Parapet.Evidence` (`evidence.ex:22`, `Application.get_env`); runtime `schema_prefix/0` colocates there, distinct from compile-time `__prefix__/0` | Confident | `evidence.ex:3,22-26`; documented "Public API boundary for Spine schemas" |

### Test bootstrap qualification
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `concurrency_bootstrap.ex` hand-writes ~20 bare DDL stmts (6 CREATE TABLE, 4 REFERENCES, 11 CREATE INDEX, 1 `@tables` TRUNCATE), references no schema, leaves `schema_migrations` in `public` | Confident | full read of file; `@tables` lines 7-14; TRUNCATE line 23; `grep schema_migrations` → 0 hits in this file |

### Propagation grounding (Phase 52 scope, confirmed clean here)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| All reads/writes route through schema modules/structs (joins in `mcp/server.ex:37-38`, `circuit_breaker.ex:52-53`; `insert_all(ActionClaim)` `claim_service.ex:111`); no runtime string-literal table writes | Confident | `grep insert_all\|update_all\|delete_all` over `lib/` — all take module/query; only raw `parapet_*` are ETS `:parapet_exemplar_store` + generator DDL |

### Macro precedent
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No existing schema-base macro, but `defmacro __using__` is house style (`runbook.ex`, `recovery.ex`, `probe.ex`, `metrics/validator.ex`) | Confident | `grep "defmacro __using__"` → 4 behaviour/DSL macros, none wrap Ecto.Schema |

### Library-migration boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Prefixing the 5 committed `priv/repo/migrations/*.exs` — Phase 51 or Phase 53? | Likely (flagged) | Synthesis §7 phase-1 says "library migrations prefixed"; but REQUIREMENTS/ROADMAP map GEN-06 (library migrations under schema) to **Phase 53**; Phase 51 reqs (PREFIX-01..04, TEST-01/02) don't touch migrations |

## Corrections Made

No assumption corrections. One boundary question was put to the user:

### Library-migration boundary
- **Question:** Prefix the 5 `priv/repo/migrations/*.exs` in Phase 51, or defer to Phase 53?
- **User decision (2026-06-29):** "Yes, proceed" — **defer to Phase 53 (GEN-06)**, honoring the authoritative
  roadmap mapping over the synthesis phase-sketch.
- **Reason:** Phase 51's requirement set (PREFIX-01..04, TEST-01/02) does not include migration prefixing;
  GEN-06 explicitly owns "Parapet's five committed library migrations create their tables under the schema."

## External Research

None performed — the v1.7 synthesis already resolved all external dimensions (Ecto `@schema_prefix`
semantics, Oban prior art, `compile_env` immutability). All Phase 51 assumptions are grounded in current
repo files.
