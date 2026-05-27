# Phase 24: Recovery Behaviour + Capability Allowlist - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 24-recovery-behaviour-capability-allowlist
**Mode:** assumptions
**Calibration tier:** minimal_decisive (opinionated user)
**Areas analyzed:** Behaviour Module Shape, Activation Function (`attach/1`), Allowlist Widening, State Isolation Across 100 Async Tests, Public-API & Stability Tier

## Assumptions Presented

### A. Behaviour Module Shape (RCV-01)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New module at `lib/parapet/recovery.ex` with 4 `@callback`s: `id/0`, `label/0`, `preview/2`, `execute/2` | Confident | `lib/parapet/operator.ex:711,767` (arity-2 locked); `lib/parapet/integration.ex:1-27` (template) |
| `__using__/1` injects only `@behaviour Parapet.Recovery` (no defaults, no helpers) | Confident | Same pattern as `Parapet.Integration`; conservative surface for Phase 29 Stable freeze |
| `@moduledoc` carries verbatim Experimental admonition shape | Confident | `capabilities.ex:6-10`, `sigra.ex:2-11`; `verify.public_api.ex:7-15` auto-classifies |

### B. Activation Function: `Parapet.Recovery.attach/1` (RCV-02)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Signature `attach([module()])` — flat list of module atoms | Confident | Locked by RCV-02 success criterion #2 verbatim |
| `Code.ensure_loaded?/1` skip-silently on `false`; on `true` capture `&Module.preview/2`, `&Module.execute/2` and delegate to `Parapet.Capabilities.register_recovery/2` | Confident | `lib/parapet.ex:41-44`, `scoria.ex:194`, `threadline.ex:81` |
| Function-capture bridge required (NOT module atoms) | Confident | `capabilities.ex:33-34` stores anonymous funs; `operator.ex:711,767` guards with `is_function(., 2)` |
| `target_kind` / `preview_only` keep existing defaults; not in v1.1 callback set | Confident | `capabilities.ex:32,35`; out-of-scope per ROADMAP |
| Return `{:ok, registered_ids}` (omits silently-skipped) | Confident | Symmetric with `Parapet.attach/1` at `lib/parapet.ex:46` |

### C. Allowlist Widening (RCV-03)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Append `:revert_feature_flag`, `:disable_metric_label` to `@valid_capabilities` (5 total) | Confident | `capabilities.ex:14-18`; 23-CONTEXT.md D-12 |
| No edit to the `ArgumentError` raise branch — `inspect(@valid_capabilities)` auto-flows widened list | Confident | `capabilities.ex:42-45`; existing test regex still matches |
| No edit to `Parapet.Telemetry.RecoveryAction` — capability_id atom-vocab is NOT enumerated there | Confident | `recovery_action.ex:85-92` lists key NAMES only |

### D. State Isolation Across 100 Async Tests (Success Criterion #4)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep the single supervised Agent — no per-test sandbox, no Application-env | Likely | `capabilities.ex:20-22`; `application.ex:11`; 23-CONTEXT.md prior decision |
| 100-async tests assert only via `get_recovery(id)` on the row just written — never on `capabilities(:recovery)` list cardinality | Likely | `capabilities.ex:27-40` per-id `put_in`; v0.10 Pitfall 13 distinguished (atomic flag mutation vs per-key map) |
| New test pattern lives alongside existing sync `capabilities_test.exs`; existing tests NOT migrated to async | Confident | Existing `:async: false` setup at `capabilities_test.exs:2,12` cannot scale |

### E. Public-API & Stability Tier

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add one row to `docs/stability.md` Experimental Modules table, alphabetically between `Parapet.MCP.PrometheusClient` and `Parapet.Telemetry.RecoveryAction` | Confident | `docs/stability.md:45-58` |
| No edit to `lib/mix/tasks/verify.public_api.ex` — admonition-regex classifier auto-picks-up | Confident | `verify.public_api.ex:7-15,64-79` |

## Corrections Made

No corrections — all five areas confirmed via "Yes, proceed".

## External Research

None performed. The pattern is "mirror `Parapet.Integration` with four callbacks + a list-of-modules `attach/1` that bridges to the existing `Parapet.Capabilities` Agent via function captures" — every assumption grounded in source files.

## Codebase Files Read by Analyzer Agent

- `lib/parapet/capabilities.ex` (full, 65 LOC)
- `lib/parapet/integration.ex` (full, 27 LOC)
- `lib/parapet.ex` (full, 78 LOC)
- `lib/parapet/telemetry/recovery_action.ex` (Phase 23 contract surface)
- `lib/parapet/operator.ex` (call-site evidence at `:711,767,657`)
- `lib/parapet/integrations/sigra.ex` (admonition + behaviour template)
- `lib/parapet/integrations/scoria.ex` (optional-dep `Code.ensure_loaded?` pattern at `:194`)
- `lib/parapet/integrations/threadline.ex` (optional-dep pattern at `:81`)
- `lib/parapet/internal/application.ex` (supervisor wiring at `:11`)
- `lib/mix/tasks/verify.public_api.ex` (admonition classifier at `:7-15,64-79`)
- `test/parapet/capabilities_test.exs` (existing sync test pattern)
- `docs/stability.md` (Experimental Modules table at `:45-58`)

## Prior Context Applied

- `.planning/phases/23-foundations-telemetry-contract-lease-until-migration/23-CONTEXT.md` — D-12 vocabulary anchor ("5 atoms after Phase 24") and the prior decision to use the existing supervised Agent (Pitfall 13 avoidance).
- `.planning/PROJECT.md` — v1.1 Actionable Recovery milestone scope; v1.0 freeze contract; "compile out cleanly" constraint.
- `.planning/REQUIREMENTS.md` — RCV-01/02/03 (`:22-24`); explicit out-of-scope items (`:89-100`) including capability dispatch via Oban and capability marketplaces.

No prior-phase decisions were revisited.
