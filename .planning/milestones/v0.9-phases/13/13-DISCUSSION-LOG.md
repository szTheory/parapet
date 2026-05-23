# Phase 13: repair-generated-operator-resolve-flow - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-23
**Phase:** 13-repair-generated-operator-resolve-flow
**Mode:** assumptions
**Areas analyzed:** runtime seam repair, operator semantics, proof strategy, verification hierarchy, maintainer workflow posture

## Assumptions Presented

### Runtime seam repair

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The generated queue LiveView should repair `"resolve"` by routing through `Parapet.Operator.resolve_incident/2`, and the generated UI should converge on the existing public operator seam rather than duplicate lifecycle behavior in templates. | Confident | `.planning/ROADMAP.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, `priv/templates/parapet.gen.ui/operator_live.ex.eex`, `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`, `lib/parapet/operator.ex`, `test/parapet/operator_ui_integration_test.exs` |

### Operator semantics

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `"Resolve"` in generated operator UI should mean a real transition to `resolved`, with durable lifecycle evidence and retrospective behavior, not a note-writing shortcut. | Confident | `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, `lib/parapet/operator.ex`, `priv/templates/parapet.gen.ui/operator_components.ex.eex` |

### Proof strategy

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The smallest honest regression backstop is a two-layer proof: one template/source-contract assertion for the queue resolve seam and one narrow generated-runtime lifecycle test. | Confident | `.planning/v0.9-MILESTONE-AUDIT.md`, `test/parapet/generated_operator_live_paging_test.exs`, `test/parapet/operator_ui_compile_out_test.exs`, `test/parapet/operator_ui_integration_test.exs`, `test/mix/tasks/parapet.gen.ui_test.exs` |

### Verification hierarchy

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The new resolve lane should live first in Phase 3 runtime proof and then be indexed by Phase 7 and Phase 12, rather than duplicated inside closure-phase verification reports. | Confident | `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-CONTEXT.md`, `.planning/v0.9-phases/3/03-VALIDATION.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/7/07-VALIDATION.md`, `.planning/v0.9-phases/7/VERIFICATION.md` |

### Maintainer workflow posture

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The repo should continue shifting routine decisions left into assumptions, artifacts, and recommendation-first defaults, escalating only on the already-locked impact boundaries. | Confident | `AGENTS.md`, `.planning/config.json`, `.planning/STATE.md`, `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md`, `prompts/parapet-engineering-dna-from-sibling-libs.md`, `prompts/parapet-brand-identity-deep-research.md` |

## Corrections Made

No corrections — the maintainer explicitly asked to discuss all areas with deeper research and to shift more decision-making left into cohesive recommendations rather than reopen routine questions.

## External Research

No web research was required. The analysis used repo-local canonical prompts and prior phase artifacts as the applicable research base:
- `prompts/parapet-engineering-dna-from-sibling-libs.md`
- `prompts/parapet-brand-identity-deep-research.md`
- `prompts/elixir-telemetry-space-deep-research.md`
- `prompts/sre-observability-elixir-lib-deep-reseach.md`
- `prompts/parapet-integration-opportunities.md`

