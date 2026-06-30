# Phase 52: Propagation Proof, Guards & CI Dual-Prefix Matrix - Discussion Log (Assumptions Mode + Deep Research)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 52-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-30
**Phase:** 52-propagation-proof-guards-ci-dual-prefix-matrix
**Mode:** assumptions (gsd-assumptions-analyzer) + 4 parallel gsd-advisor-researcher deep-dives
**Areas analyzed:** Static guard (PROP-02), Propagation tests (PROP-01/03), CI dual-prefix matrix (TEST-03), WR-01..04 remediation scope

## Assumptions Presented (from gsd-assumptions-analyzer)

### Static guard (PROP-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Single regex-scan ExUnit file, `lib/`-scoped, modeled on palette-gate | Confident | `operator_ui_compile_out_test.exs:57-64`, `operator_ui_palette_gate_test.exs:54-64` |
| Regex keys on `(insert_all\|update_all\|delete_all)\s*\(\s*["~]` to avoid `on_delete: :delete_all` FP | Confident | `parapet.gen.spine.ex:55,70` |

### Propagation tests (PROP-01/03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| One `prefix_propagation_test.exs` driving `to_sql`/`get_meta`/`__schema__(:prefix)` | Likely | `circuit_breaker.ex:44-61` already a pure builder; `to_sql`/`get_meta` net-new in test/ |
| `mcp/server.ex` join inlined → needs extraction or rebuild | Likely | `server.ex:36` inlined in `execute_tool/2` |
| Negative "no bare table" assertion leg-gated on `__prefix__() != nil` | Confident | `concurrency_bootstrap.ex:49-55` emits bare names on public leg |

### CI dual-prefix matrix (TEST-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `schema_prefix` axis to `test:`, env-inject, `--force`, namespace `_build` key | Confident | `ci.yml:66-68,100-103`; `config.exs:21`, `schema.ex:34` compile_env |
| `mix compile --force` not `deps.compile parapet --force` (repo IS the lib) | Confident | first-party `_build` modules |

### WR-01..04 remediation scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| WR-01 IN scope — extract shared `normalize/1`, drive agreement test from real code | Likely | matrix tests only 2 of 5 inputs |
| WR-03 IN scope now — `Evidence.schema_prefix/0` delegate to `__prefix__/0` | Likely | `evidence.ex:42-48` reads mutable env |
| WR-04 IN scope now — shared `safe_ident!/1` | Likely | `concurrency_bootstrap.ex:28,51` unquoted interpolation; Phase 53 copies template |
| WR-02 partial — matrix pins both legs; WR-01 rewrite adds unset-vs-nil assertion | Likely | byte-identical public/nil leg |

## Deep Research (4 parallel gsd-advisor-researcher agents)

Each fork was researched for pros/cons/tradeoffs, idiomatic Elixir/Ecto/Phoenix patterns, ecosystem
lessons (Oban/Triplex/Apartment/Ash/Ecto + cross-language Rails `apartment`/ArchUnit/ESLint), DX, and a
decisive one-shot recommendation. Key resolved facts:

- **PROP-02:** Regex fitness-function decisively beats Credo custom check / Sourceror-AST for a
  4-fingerprint guard (no dep, out of Hex tarball, multi-line teaching message). Scope to `lib/parapet/**`
  + comment-strip + shape-narrow regex eliminates all known false positives. Lesson (ArchUnit/ESLint): a
  precise teaching message + tight scope matters more than a clever matcher.
- **PROP-01/03:** `to_sql/3` supports `:all`/`:update_all`/`:delete_all` but **NOT `:insert_all`** —
  this dictates the split (to_sql for joins; `__schema__(:prefix)` + `get_meta` round-trip for
  insert_all/Multi). Extract `mcp/server.ex` join (the one justified prod edit); rebuild-in-test rejected.
  Match qualified-identifier tokens, never whole SQL (Ecto-patch-brittle). `get_meta` is Ecto's
  sanctioned prefix-verification path.
- **TEST-03:** Pruned 2nd axis (+1 cell), `mix compile --force` (whole project), namespace `_build`
  cache key by prefix (primary defense), shared `deps` cache, `fail-fast: false`, plus an in-suite leg
  guard (tertiary). Oban inverse-case lesson: Oban does NOT namespace `_build` (runtime prefix); Parapet
  MUST (compile_env prefix) or it false-greens.
- **WR-01..04:** ALL IN Phase 52 — one fix ("exactly one trustworthy prefix source") at four sites.
  `Code.require_file` into config.exs rejected (config is pre-compile); keep the config copy, make the
  agreement test real. `safe_ident!/1` allowlist beats escaping (Triplex/`apartment` CVE-class lesson).
  Ordering: WR-01 → WR-04 folds in → WR-03 (with WR-01 test rewrite) → WR-02 (tests+docs).

## Corrections Made

No assumptions were corrected. The user requested deep multi-lens research on all four areas (rather than
a yes/no confirm), then accepted the synthesized recommendation set in full.

### Scope decision (the consequential call)
- **Question:** Fold WR-01/03/04 production hardening into this "proof" phase, or keep Phase 52
  proof-only and defer the `schema.ex`/`evidence.ex` edits?
- **User decision (2026-06-30):** "Yes — proof + seal all 4 WRs." All four warnings remediated in
  Phase 52; production edits to `lib/parapet/spine/schema.ex` and `lib/parapet/evidence.ex` accepted.
- **Rationale:** Every researcher independently argued IN-phase — Phase 53's generators consume this
  seam and must not ship ahead of its safety net.

## External Research

Performed via the 4 advisor agents (sources captured inline above): Ecto multi-tenancy guide,
`Ecto.Adapters.SQL.to_sql/3`, `Ecto.get_meta/2`, `Application.compile_env` boot-check, Oban prefix
handling, Triplex tenant validation, Rails `apartment`, ArchUnit/ESLint guard patterns. No open research
gaps remain.
</content>
