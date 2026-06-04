# Phase 38: Scoped UI Routes - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-04T18:58:38Z
**Phase:** 38-Scoped UI Routes
**Mode:** assumptions
**Areas analyzed:** Route Base Ownership, Route Surface Coverage, Demo And Generated-Copy Proof, Stability Boundaries

## Assumptions Presented

### Route Base Ownership

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Scoped UI support should keep route ownership in generated, host-owned UI files and make every internal Operator UI path resolve against a host-owned base path that defaults to `/parapet` and can represent nested mounts such as `/ops/parapet`. | Likely | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `lib/mix/tasks/parapet.gen.ui.ex`; `docs/operator-ui.md` |

### Route Surface Coverage

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The phase must cover all route-producing surfaces in the generated Operator UI, not just top-level nav links: `push_patch`, `push_navigate`, `navigate`, `patch`, `href`, back links, queue pagination, history links, and detail links. | Confident | `priv/templates/parapet.gen.ui/operator_live.ex.eex`; `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`; `priv/templates/parapet.gen.ui/operator_components.ex.eex`; `priv/templates/parapet.gen.ui/router_snippet.ex.eex` |

### Demo And Generated-Copy Proof

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Demo synchronization should be test-pinned by comparing generated template behavior with the checked-in demo copies for both default `/parapet` and scoped `/ops/parapet` behavior. | Confident | `test/parapet/operator_ui_integration_test.exs`; `test/parapet/operator_ui_demo_contract_test.exs`; `test/parapet/generated_operator_live_paging_test.exs` |

### Stability Boundaries

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 38 should not add dependencies, stable public APIs, auth behavior, or Parapet-owned router modules; changes should stay in templates, demo copies, docs/guidance, and tests. | Confident | `.planning/REQUIREMENTS.md`; `test/parapet/operator_ui_compile_out_test.exs`; `test/parapet/operator_ui_integration_test.exs`; `mix.exs`; `docs/stability.md`; `priv/parapet/public_api_stable.json` |

## Corrections Made

No corrections - all assumptions confirmed.
