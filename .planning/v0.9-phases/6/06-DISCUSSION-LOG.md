# Phase 6: Verify Cardinality Protection - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `06-CONTEXT.md`; this log preserves the analysis and recommendation path.

**Date:** 2026-05-21
**Phase:** 06-verify-cardinality-protection
**Mode:** assumptions
**Areas analyzed:** verification artifact shape, proof command set, reconciliation scope, maintainer workflow preference

## Assumptions Presented

### Verification artifact shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 6 should use a hybrid proof bundle with executable reruns as the main proof surface and short narrative only as explanation. | Confident | `.planning/v0.9-phases/2/VERIFICATION.md`, `.planning/v0.9-phases/5/VERIFICATION.md`, `.planning/ROADMAP.md`, `prompts/parapet-engineering-dna-from-sibling-libs.md` |

### Proof command set
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Closure-grade proof should center on `mix compile --force --warnings-as-errors`, `mix test test/parapet/metrics/validator_test.exs`, and `mix test test/mix/tasks/parapet.doctor_test.exs`. | Confident | `lib/parapet/metrics/validator.ex`, `lib/mix/tasks/parapet.doctor.ex`, `test/parapet/metrics/validator_test.exs`, `test/mix/tasks/parapet.doctor_test.exs`, local rerun results on 2026-05-21 |
| `mix parapet.doctor cardinality` is an advisory spot-check here and can legitimately `skip` in the current workspace. | Confident | `lib/mix/tasks/parapet.doctor.ex`, local workspace behavior, `.planning/phases/01-cardinality-protection/01-01-SUMMARY.md` mismatch |

### Reconciliation scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 6 should add a dedicated Phase 1 `VERIFICATION.md`, reconcile directly covered requirements, and fix local proof-surface drift, but leave broad milestone synchronization to Phase 9. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/v0.9-MILESTONE-AUDIT.md` |

### Maintainer workflow preference
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| This repo should prefer recommendation-first agent behavior and escalate only very impactful proof/documentation decisions. | Confident | `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md`, `.planning/phases/05-multi-node-safety-verification/05-CONTEXT.md`, `prompts/parapet-brand-identity-deep-research.md`, `prompts/parapet-engineering-dna-from-sibling-libs.md` |

## Corrections Made

No corrections requested. The maintainer explicitly asked for all areas to be discussed with deeper research, recommendation-first synthesis, and fewer low-impact escalation questions.

## External Research

- Verification-proof posture for Elixir/Phoenix OSS: executable reruns are the idiomatic trust surface, but closure-grade docs work best as hybrid proof reports that interpret the reruns instead of replacing them. Sources reviewed by subagent: ExUnit, Phoenix testing, Ecto, Oban, Plug.Telemetry, OpenTelemetry, Prometheus/Google SRE materials.
- Maintainer workflow encoding: a checked-in `AGENTS.md` is the least-surprise place to encode recommendation-first agent behavior, optionally mirrored in contributor docs. Sources reviewed by subagent: Phoenix docs, GitHub Copilot repo instructions, Claude Code memory docs, GitHub contributor-doc guidance.

## Notable Footguns Found

- `.planning/phases/01-cardinality-protection/01-UAT.md` expects doctor findings to exit with code `2`, but `lib/mix/tasks/parapet.doctor.ex` defines `1` for findings and `2` for execution failure.
- `.planning/phases/01-cardinality-protection/01-01-SUMMARY.md` implies `mix parapet.doctor cardinality` validates the current workspace successfully, but the current workspace can legitimately return `skip` when no SLOs are configured.
- `test/mix/tasks/parapet.doctor_test.exs` still proves the cardinality path through deprecated `Parapet.SLO.define/2`, even though provider-first SLOs are now preferred.
