# Phase 14: backstop-generated-operator-ui-closure-proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `14-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-05-23
**Phase:** 14-backstop-generated-operator-ui-closure-proof
**Mode:** assumptions
**Areas analyzed:** canonical proof ownership, truth-surface reconciliation, generated UI seam posture, proof-lane design, maintainer DX

## Assumptions Presented

### Canonical proof ownership

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 3 should remain the canonical runtime proof owner for generated operator UI behavior, and Phases 7, 12, and 14 should act as closure/index layers rather than competing proof owners. | Confident | `.planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md`, `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-CONTEXT.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/7/VERIFICATION.md`, `.planning/v0.9-phases/9/VERIFICATION.md` |
| Phase 14 should strengthen the Phase 3 proof lane and promote that proof upward instead of inventing a new top-level runtime proof artifact. | Confident | `.planning/ROADMAP.md`, `.planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md`, `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-CONTEXT.md` |

### Generated UI seam posture

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `Parapet.Operator` should remain the sole canonical mutation seam for generated operator actions, and generated templates should stay thin, host-owned wiring over that seam. | Confident | `lib/parapet/operator.ex`, `priv/templates/parapet.gen.ui/operator_live.ex.eex`, `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`, `test/parapet/operator_ui_integration_test.exs`, `prompts/parapet-engineering-dna-from-sibling-libs.md`, `prompts/prior-art/chimeway-host-app-integration-seam.md` |
| Generator/source-contract tests should remain part of the proof contract because the bug class here is template drift as much as runtime drift. | Confident | `test/parapet/operator_ui_integration_test.exs`, `test/mix/tasks/parapet.gen.ui_test.exs`, `.planning/v0.9-MILESTONE-AUDIT.md` |

### Proof-lane design

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The canonical backstop should remain a two-layer lane: one cheap source-contract/generator assertion plus one narrow generated-runtime lifecycle test, not browser E2E. | Confident | `.planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md`, `test/parapet/generated_operator_live_paging_test.exs`, `test/parapet/operator_ui_integration_test.exs`, `test/mix/tasks/parapet.gen.ui_test.exs`, `docs/operator-ui.md` |
| The operator UX around this lane should preserve explicit refresh, bounded paging, chronology before controls, and least-surprise queue semantics rather than adding auto-refresh or operator-console complexity. | Confident | `docs/operator-ui.md`, `priv/templates/parapet.gen.ui/operator_live.ex.eex`, `test/parapet/operator_ui_integration_test.exs`, `prompts/parapet-brand-identity-deep-research.md` |

### Truth-surface reconciliation

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Active truth surfaces should be reconciled once fresh canonical runtime proof exists, even if a fresh milestone audit rerun has not happened yet. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/phases/13-repair-generated-operator-resolve-flow/13-02-SUMMARY.md` |
| Historical audit artifacts and execution summaries must remain historical; superseding truth should be additive and explicit rather than rewriting chronology. | Confident | `.planning/v0.9-MILESTONE-AUDIT.md`, `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-CONTEXT.md`, `AGENTS.md` |
| `SCALE-01.c` and `AC-03` should move out of pending in live tracker surfaces now, while `milestone closure readiness` should remain pending until Phase 14 lands. | Confident | `.planning/REQUIREMENTS.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/phases/13-repair-generated-operator-resolve-flow/13-02-SUMMARY.md` |
| The active Phase 12 closure-proof surfaces live under `.planning/phases/12-backfill-closure-phase-verification-surfaces/`, not `.planning/v0.9-phases/12/`. | Confident | repository inspection, `.planning/v0.9-MILESTONE-AUDIT.md`, `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md` |

### Scope boundary and deferred debt

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The duplicated resolved-history read path is real deferred runtime debt but should stay out of Phase 14 unless proof honesty makes it unavoidable. | Likely | `.planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md`, `priv/templates/parapet.gen.ui/operator_live.ex.eex`, `.planning/v0.9-MILESTONE-AUDIT.md` |
| `docs/operator-ui.md` is not a milestone truth surface and should change only if the named proof lane or operator-facing wording materially changes. | Likely | `docs/operator-ui.md`, `.planning/phases/13-repair-generated-operator-resolve-flow/13-02-SUMMARY.md` |

## Corrections Made

No corrections — all assumptions confirmed after deeper subagent research across proof hierarchy, artifact truth, ecosystem idioms, local `prompts/` research, and sibling-library priors.

## External Research

- Proof hierarchy and canonical artifact design: local subagent synthesis over `.planning` proof surfaces plus `prompts/parapet-engineering-dna-from-sibling-libs.md`, `prompts/parapet-brand-identity-deep-research.md`, and `prompts/sre-observability-elixir-lib-deep-reseach.md`.
- Artifact reconciliation and historical-boundary posture: local subagent synthesis over `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, and `AGENTS.md`.
- Ecosystem idioms and DX/UI lessons: local subagent synthesis over `docs/operator-ui.md`, generator/runtime tests, and the `prompts/prior-art/` research set.
