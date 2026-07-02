# Phase 59: CI Caching, Lint-Once & release_gate Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-02
**Phase:** 59-ci-caching-lint-once-release-gate-hardening
**Mode:** assumptions
**Areas analyzed:** PLT caching, lint-once scope, PR concurrency, release_gate hardening, dual-prefix invariant, SHA-pin updates

## Assumptions Presented

### PLT Caching (CI-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| One `actions/cache` step in `lint-once` only, `path: priv/plts`, prefix-agnostic key `plt-${os}-28.x-1.19.0-${mix.lock}`, before `mix ci` | Confident | ci.yml:10-45 (lint-once runs `mix ci`→dialyzer); mix.exs:25-27 (`plt_file` → priv/plts); .gitignore:37 |

### lint-once scope (CI-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| CI-02 already satisfied by Phase 58; only additive change is the PLT cache; `mix docs` + operator-UI diff stay | Confident | ci.yml:10-45; 58-CONTEXT D-04/D-05 |

### PR Concurrency (CI-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Top-level `concurrency` block, group by PR number ∥ ref, `cancel-in-progress` true only for pull_request events | Confident | No concurrency block currently in ci.yml; canonical GitHub pattern |

### release_gate Hardening (CI-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `if: always()` + explicit per-job result checks; non-`success` (incl. skipped) → exit 1; keep needs [lint-once,test,demo] | Confident | ci.yml:155-159 (bare echo, no `if`, no aggregation — the footgun) |

### Dual-Prefix Invariant (CI-05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `test` job untouched except SHA bumps; `_build` key keeps `schema_prefix`, cells keep `mix compile --force` | Confident | ci.yml:93 (prefix in key), ci.yml:98 (`mix compile --force`); roadmap INVARIANT |

### SHA-Pin Updates (CI-06)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Bump checkout/setup-beam/cache to newest SHA-pinned releases | Likely | Current pins v4-era checkout `34e11487`, v4-era cache `0057852b`, setup-beam v1.24.0 `fc68ffb` |

## Corrections Made

### SHA-Pin Update Tier (CI-06)
- **Original assumption:** Bump to newest SHA-pinned releases (aggressiveness left open, Likely).
- **User decision:** **Proven-recent tier** — checkout v6.0.3 (`df4cb1c0…`), cache v5.1.0
  (`caa29612…`), setup-beam v1.24.1 (`54075bcc…`). Rejected newest-major (checkout v7.0.0 /
  cache v6.1.0) to avoid <2-week-old node24/ESM churn on release-critical CI; Dependabot bumps later.

Assumptions ①–⑤ (PLT cache, lint-once caching-only, PR concurrency, release_gate hardening,
dual-prefix invariant) confirmed as-is with no corrections.

## External Research

Current action release SHAs resolved via GitHub tags + git-refs API (2026-07-02):
- `actions/checkout`: v7.0.0 `9c091bb2…` (Jun 17), v6.0.3 `df4cb1c0…` (Jun 2), v5.0.0 `08c6903c…`
- `erlef/setup-beam`: v1.24.1 `54075bcc…` (Jun 28), v1.24.0 `fc68ffb…` (Mar 30)
- `actions/cache`: v6.1.0 `55cc8345…` (Jun 23, ESM/node24 migration), v5.1.0 `caa29612…` (Jun 26)
</content>
