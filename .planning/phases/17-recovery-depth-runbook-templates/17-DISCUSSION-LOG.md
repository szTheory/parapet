# Phase 17: Recovery Depth — Runbook Templates - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-24
**Phase:** 17-recovery-depth-runbook-templates
**Mode:** assumptions
**Areas analyzed:** `warning:` DSL surface, four-template depth gaps, new-template capability strategy, generator skip-on-exists, test strategy

## Assumptions Presented

### The `warning:` DSL addition is a three-surface change
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `warning:` is currently silently swallowed (not in the `step/2` 11-key map); `requires_preview:`/`kind: :guidance` already work | Confident | `runbook.ex:21-33` |
| Adding `warning:` requires macro + WorkbenchContract projection + UI card (3 surfaces) | Confident | `runbook.ex:21-33`, `workbench_contract.ex:144-156`, `operator_components.ex.eex:270-334` |
| Render as an amber/red block in the `runbook_card` step loop, not the runtime `preview_panel` warnings list | Confident | `operator_components.ex.eex:293-297` vs `:361-370` |
| Persistence needs no change — a new key survives JSON automatically | Confident | `runbook.ex:55-63`, `alert_processor.ex:118`, `workbench_contract.ex:114-115` |

### Four existing templates have distinct depth gaps
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Gaps are non-uniform; none has a `warning:` or verification step | Confident | `dead_letter.ex.eex:7-24`, `callback_delay.ex.eex:7-14`, `stalled_executor.ex.eex:7-23`, `provider_outage.ex.eex:7-24` |
| Add precondition/verification as distinct `type: :manual, kind: :guidance` steps | Confident | pattern at `dead_letter.ex.eex:7-14` |

### New templates: closed capability allowlist
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No new `capability:` ids possible — closed allowlist of three, raises otherwise | Confident | `capabilities.ex:8-12`, `:35-37`, `capabilities_test.exs:32-36` |
| New mitigations are guidance-only or reuse one of the three where target fits | Confident | `runbook.ex:14-15`, `operator.ex:622-624`/`:644`/`:705`/`:723` |

### Generator already satisfies skip-on-exists
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `on_exists: :skip` already met; add 3 explicit `copy_template` calls + tests; keep per-file model | Confident | `parapet.gen.runbooks.ex:33-56` (`:29` assign), `parapet.gen.runbooks_test.exs:8-48` |

### Test strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Three-layer test (schema + projection + generator content) proves `warning:` not swallowed | Likely | `runbook_test.exs:57-112`, `workbench_contract_test.exs:308-369`, `parapet.gen.runbooks_test.exs:8-48` |
| New `warning:` option must be documented or `verify.public_api` breaks | Likely | `runbook.ex:2-6` (`@moduledoc`), `mix docs --warnings-as-errors` |

## Corrections Made

No corrections — all five assumptions confirmed by the user ("Yes, proceed").

## External Research

None — self-contained internal-DSL/template phase. The FEATURES.md-vs-SUMMARY.md tension
(research flag) was resolved decisively against the source: `warning:` is currently swallowed
and must be added before any template uses it.
