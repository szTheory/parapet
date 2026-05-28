# Phase 27: Prebuilt Playbooks - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 27-prebuilt-playbooks
**Mode:** assumptions
**Areas analyzed:** Scope (reuse vs author), Guidance-only hardening, Generator interface, Capability reference model, Preview→Confirm proof boundary, Tests + packaging

## Assumptions Presented

### Scope — Reuse Existing, Author Only Two
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Author only 2 net-new templates (Deploy-Tied Incident `:revert_feature_flag`, Cardinality Blowout `:disable_metric_label`); reuse the other 4 unchanged | Confident | `priv/templates/parapet.gen.runbooks/` already has retry_storm, suppression_drift, stalled_executor (`:retry_async_item`), dead_letter (`:requeue_dead_letter`) |

### Guidance-Only Hardening (PB-01, PB-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No `capability:` key on guidance templates (structural guarantee); strengthen `warning:` to state why automated mitigation worsens the failure (suppression_drift needs reframing) | Likely | `retry_storm.ex.eex:14`, `suppression_drift.ex.eex:14,24` |

### Generator Interface
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add 2 templates to existing all-at-once `mix parapet.gen.runbooks`; do NOT build a per-template CLI (that's Phase 29 ADOP-01) | Likely | `lib/mix/tasks/parapet.gen.runbooks.ex:3` fixed-catalog; `24-CONTEXT.md` D-20, `25-CONTEXT.md` D-22 |

### Capability Reference Model
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Templates reference capability by atom id only + point at Rulestead / cardinality analyzer via guidance text; NO shipped reference Recovery impl | Unclear | templates are Runbook DSL modules naming atoms; no `use Parapet.Recovery` in `examples/` source; `runbook.ex` has no allowlist validation |

### Preview→Confirm Proof Boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Prove Preview→Confirm structurally (template declares `requires_preview: true` + capability step); runnable demo scenario is Phase 28 | Likely | ROADMAP Phase 28 = "Demo Seed + CI Lane"; Phase 27 success criteria omit seeding; existing test is `Igniter.Test` content-only |

### Tests + Packaging
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `parapet.gen.runbooks_test.exs` with the same assertion shape for the 2 new templates; no `mix.exs`/DSL/operator changes; snake_case file → CamelCase module | Confident | `parapet.gen.runbooks_test.exs:44-99`; existing naming convention |

## Corrections Made

No corrections — user selected "Yes, proceed"; all six assumptions confirmed.

## External Research

None — codebase provided sufficient evidence; no `needs_research` gaps flagged.
</content>
