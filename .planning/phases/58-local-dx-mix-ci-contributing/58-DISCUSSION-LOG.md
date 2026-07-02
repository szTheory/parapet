# Phase 58: Local DX — mix ci & CONTRIBUTING - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-02
**Phase:** 58-local-dx-mix-ci-contributing
**Mode:** assumptions (--auto)
**Areas analyzed:** mix ci alias, CI anti-drift (lint-once), dialyzer PLT config + gitignore, CONTRIBUTING.md

## Assumptions Presented

### Technical Approach — `mix ci` alias
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Single `ci: [...]` aliases/0 entry, 8 steps, fail-fast, exact CI flags (`--check-formatted`, `--strict`, `--warnings-as-errors`), no wrapper script | Confident | `mix.exs:133-135` empty aliases; all 8 steps run verbatim in ci.yml `lint` job :39-56; `.credo.exs:9` `strict:false` makes `--strict` load-bearing; test green since Phase 57 |

### CI Anti-Drift — `lint-once` reuse
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New non-matrixed `lint-once` job calls `mix ci`; `mix docs` + operator-UI diff stay CI-only deltas; `release_gate.needs` updated lint→lint-once | Likely | ci.yml:10-61 lint job (10 steps: 8 portable + 2 deltas); ci.yml:172 `release_gate: needs:[lint,test,demo]`; deltas canonical per 57-CONTEXT + roadmap SC#2 |

### Dialyzer PLT config + gitignore
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `mix.exs:25` add `plt_file: {:no_warn, "priv/plts/project.plt"}`; `.gitignore` gains `/priv/plts/*.plt*`; dir + rule net-new | Confident | `mix.exs:25` no plt_file today; `ls priv/plts` absent; `grep plt .gitignore` empty; dialyxir dep at mix.exs:129 |

### CONTRIBUTING.md shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Rewrite "Local proof commands" (:5-15) to single `mix ci`; add prose block for 3 local-vs-CI deltas | Likely | CONTRIBUTING.md exists (3602 bytes), :10-12 runs the 3 commands `mix ci` subsumes; dual-prefix at ci.yml:70-77; operator-UI diff at ci.yml:57-61 |

## Corrections Made

No corrections — all assumptions confirmed (--auto; all Confident/Likely, none Unclear).

## Auto-Resolved

None — no Unclear assumptions to resolve.

## External Research

None performed — analyzer reported the codebase is fully self-evidencing (all 8 steps already invoked verbatim in ci.yml; every dep/task exists; delta framing locked in 57-CONTEXT.md).

## Implementation Dependencies (all satisfied — no blockers)

- `mix verify.public_api` — `lib/mix/tasks/verify.public_api.ex` (`Mix.Tasks.Verify.PublicApi`)
- credo — dep `mix.exs:127`, config `.credo.exs`
- dialyxir — dep `mix.exs:129`
- `mix hex.audit` — built into Hex
- `compile --no-optional-deps` — already used at ci.yml:44 (optional deps: opentelemetry_api, oban, req, sigra)
