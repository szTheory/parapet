# Phase 26: Audit Propagation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 26-audit-propagation
**Mode:** assumptions
**Areas analyzed:** Schema & Type Representation; Evidence Field Set & AUD-03 Failure Write; Retrospective Surfacing & Telemetry Scope

## Pre-flight: tooling blocker resolved

`/gsd-discuss-phase 26` initially failed because `init.phase-op 26` returned `phase_found: false` even though Phase 26 is fully specified in ROADMAP.md. Root cause: GSD's `extractCurrentMilestone()` treated the `### 📌 v1.2 (Candidate)` heading as the v1.1 milestone boundary, severing the shared `## Phase Details` section (where `### Phase 26:` lives) from the current-milestone slice. This blocked directory-less phases 26–29. Fix (user-approved): relocated the v1.2 candidate block to the bottom of ROADMAP.md (after Progress), committed as `docs(roadmap): move v1.2 candidate block below Phase Details`. After the fix, `init.phase-op 26` resolves with `expected_phase_dir: .planning/phases/26-audit-propagation`.

## Assumptions Presented

### Schema & Type Representation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep `TimelineEntry.type` as plain string; add `"recovery_failed"` with no migration/Enum/inclusion change | Confident | `timeline_entry.ex:33` `field(:type, :string)`; `validate_typed_payload/1` :49-59 only constrains `triage_snapshot` |
| Satisfy AUD-01 `:recovery_confirmed` via existing string write + documented atom↔string mapping (no atom conversion) | Confident | string asserted by `operator_test.exs:594`, `preview_lifecycle_test.exs:262/286/410`; live matcher `workbench_contract.ex:130` |
| No new dedup mechanism — the claim gate is the dedup boundary (one write per `{:won}+{:ok}`) | Confident | single execute `operator.ex:737`; repeat Confirms → `{:conflicted}` `:773` (writes nothing) |

### Evidence Field Set & AUD-03 Failure Write
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Enrich TimelineEntry payload + ToolAudit with actor / action name / target_refs / outcome / timestamps; set ToolAudit `output` | Confident | `build_audit/2` `operator.ex:990-1002` sets only tool_name/success/input; `tool_audit.ex:19-23` has `output`; `action_payload.ex:19` actor; `target_refs` `operator.ex:737` |
| Operator identity = `payload.actor` (mirrors `"system:automation:executor"`) | Confident | `executor.ex:56`; `action_payload.ex:37` required |
| AUD-03 `recovery_failed` write at single site `operator.ex:763`; `{:capability_raised,_}` counts; keep `mark_failed` + `{:error, reason}` return; `inspect(reason)` payload | Confident | `operator.ex:763-768` only post-won error arm; rescue `:738-740`; `inspect` convention `:751` |

### Retrospective Surfacing & Telemetry Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Criterion #4 already structurally satisfied; only add `format_payload/1` clauses (distinct failure wording); no whitelist exists | Confident | `retrospective.ex:24-25` selects all entries no filter; `:117-119` maps all; `:136` humanizes type; `:140-148` fallback |
| Telemetry emit-sites OUT of scope for Phase 26 | Likely | AUD-01/02/03 + criterion #4 cite no telemetry; `recovery_action.ex:14-15` frames emit-sites as future; `evidence.ex:156` already fires `[:parapet,:audit,:created]` |

## Corrections Made

No corrections — all assumptions confirmed via "Yes, proceed". User profile is `opinionated` (minimal_decisive calibration); assumptions presented decisively and accepted as-is.

## External Research

None — phase is entirely internal Ecto/audit wiring; analyzer reported no research gaps.
