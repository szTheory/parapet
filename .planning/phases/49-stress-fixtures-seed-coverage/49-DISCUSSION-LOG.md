# Phase 49: Stress fixtures & seed coverage - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-28
**Phase:** 49-stress-fixtures-seed-coverage
**Mode:** assumptions
**Areas analyzed:** Scenario taxonomy & seed wiring; "Six status triplets" interpretation; Screenshot capture coverage; Demo contract test & fixture pins

## Assumptions Presented

### A. Scenario taxonomy & seed wiring (FIXTURE-01,02,03,05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `demo_seed_scenarios.exs` `@scenarios` with `long_string`/`empty`/`max_items`/`mixed_status`/`stress`, wired via existing `PARAPET_DEMO_SCENARIO`; `stress` = union guaranteeing ≥1 active incident | Confident | `demo_seed_scenarios.exs:4` `@scenarios`; `seeds.exs:7`; queue page size 30/100 `operator.ex:23-24` |

### B. "All six status triplets" interpretation (FIXTURE-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Read as "every distinct status visual the operator UI renders in one view" (incident states + journey statuses + escalation states + chip tones), NOT a literal injection of the six brand tokens | Likely → confirmed | `journey_color/1` only maps healthy/degraded/down (`operator_components.ex.eex:1565-1567`); `:watch/:burning/:exhausted` fall through to colorless `po-chip`; brand triplets in `tokens.css:25-30` |

### C. Screenshot capture coverage (FIXTURE-05, GALLERY-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `capture_operator_ui_screenshots.sh` (DB-backed) to add `/parapet/_gallery` captures + run against `PARAPET_DEMO_SCENARIO=stress`; keep `gallery_preview.sh --shot` (DB-less) untouched; no rasters committed (manifest is Phase 50) | Likely → confirmed | two scripts exist; Phase-48 deferred note "screenshot baseline manifest → Phase 50" |

### D. Demo contract test & fixture pins (GALLERY-02, FIXTURE-01..05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add gallery render test (`/parapet/_gallery` → 200, DB-independent) + fixture-existence pins per scenario to `operator_smoke_test.exs`; RED→green cadence | Confident | `gallery_live.ex:7` (no Repo); `router.ex:22` (`live_session :parapet_gallery`); `operator_smoke_test.exs` sandbox self-seed convention |

## Corrections Made

No corrections — both surfaced gray areas confirmed to the recommended reading:

### B. Six status triplets
- **Original assumption:** "all six status triplets" = every distinct status visual the operator UI
  actually renders (in-scope, values-only).
- **User decision:** Confirmed — "Every UI status visual." Literal six brand triplets would be
  out-of-scope markup creep.

### C. The screenshot capture script
- **Original assumption:** Extend the main DB-backed `capture_operator_ui_screenshots.sh` to carry
  both stress + gallery coverage; keep `gallery_preview.sh` as the DB-less dev preview.
- **User decision:** Confirmed — "Extend the main script."

## External Research

None — codebase evidence was sufficient.
</content>
