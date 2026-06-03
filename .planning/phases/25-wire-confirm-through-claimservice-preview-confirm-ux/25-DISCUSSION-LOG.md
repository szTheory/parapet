# Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 25-wire-confirm-through-claimservice-preview-confirm-ux
**Mode:** assumptions
**Calibration:** minimal_decisive
**Areas analyzed:** Operator-path ClaimService routing shape, Preview token lifecycle, LiveView surfacing of branches + multi-node concurrency test

## Assumptions Presented

### Operator-path ClaimService routing shape (UI-02, UI-04)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `confirm_runbook_step/4` calls `ClaimService.claim_action/1` with `action_kind: "operator"`, `action_key: to_string(step_id_atom)`, `breaker_step_id: step_id_atom`, `idempotency_key: payload.idempotency_key` after preview-token validation. Five-arm `case` mirrors `Executor.perform/1`/`Worker.perform/1` one-to-one. Internal `{:short_circuited, claim, reason}` 3-tuple wrapped to public 2-tuple `{:short_circuited, reason}`; conflict wrapped to `{:conflicted, claim.id}`. `{:ok, result}` and `{:error, reason}` arms unchanged (additive only). | Confident | `executor.ex:29-47`, `worker.ex:37-63`, `claim_service.ex:51-58`, `action_payload.ex:44-50`, `recovery_action.ex:65-69` (locked `"operator"` atom in `@action_kinds` vocab) |

### Preview token lifecycle: hash gating, expiry, "no fresh Preview" rejection (UI-01, UI-03)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep existing "newest `recovery_preview` TimelineEntry per (incident_id, step_id) is the active preview" storage. No new `parapet_preview_tokens` table, no ETS, no GenServer. 5-min expiry already at `compute_preview/3:751`; stale branch returns `{:short_circuited, :preview_expired}` (vocab locked at `recovery_action.ex:46-51`). Add `target_refs_hash` (SHA-256 of canonicalized target_refs) to preview payload; mismatch returns `{:short_circuited, :target_refs_drift}`. "Confirm without fresh Preview" rejection leans on `find_recent_preview/3`'s existing `{:error, :mismatched_preview}` at `operator.ex:817`, surfaced to LiveView. `WorkbenchContract.find_active_preview/1` unchanged. | Confident | `operator.ex:707, 736, 750-780, 782-819`; `workbench_contract.ex:167-206, 194-203`; `recovery_action.ex:46-51` locked vocab includes `:preview_expired`, `:target_refs_drift`; LiveView consumer at `operator_detail_live.ex:187-189` |

### LiveView surfacing of branches + multi-node concurrency test (UI-01, UI-04, success criteria #2 #4)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| LiveView edits land in `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` (`handle_event("confirm_mitigation", ...)` at `:123-142`) and `examples/demo_app/lib/demo_app_web/components/operator_components.ex` (`preview_panel/1` at `:342-403`). Confirm handler grows from 2 to 4 arms: adds `{:short_circuited, reason}` (reason-specific flash + Re-Preview button reusing existing `phx-click="preview_mitigation"`) and `{:conflicted, claim_id}` (verbatim flash "Another node is executing this recovery — refresh to see the outcome"). `preview_panel/1` adds action name (= capability label). Blast-radius (`:363`) and target_kind (`:359`) already render. Multi-node concurrency test at new `test/parapet/operator/confirm_concurrency_test.exs` uses `ConcurrencyCase`/`unboxed_run` + `Task.async` rendezvous pattern from `executor_concurrency_test.exs:1-78`, asserts exactly one task gets `{:ok, _}` and the other gets `{:conflicted, _claim_id}`. | Confident | Demo LiveView at `operator_detail_live.ex:103-121, 123-142, 187-189`; components at `operator_components.ex:342-403`; concurrency harness at `executor_concurrency_test.exs:1-78` + `claim_service_test.exs:1-50`; host-app LiveView is the only LiveView Parapet ships (no LiveView under `lib/parapet/`) |

## Corrections Made

No corrections — all three assumptions confirmed by user with "Yes, proceed".

## External Research

None — codebase had clear precedent for every Phase 25 wiring decision. `Executor.perform/1` and `Escalation.Worker.perform/1` give the five-arm `claim_action/1` pattern; `ActionPayload` already has `:execute_mitigation` action_type with required `:idempotency_key`; `@short_circuit_reasons` and `@action_kinds` vocabs locked by Phase 23; `WorkbenchContract.find_active_preview/1` already derives the LiveView preview surface; `ConcurrencyCase`/`unboxed_run` gives the multi-node test harness.

## Scope-Creep Flags (deferred to later phases)

- `:recovery_confirmed` / `:recovery_failed` `TimelineEntry` types, `ToolAudit` row writes from the operator Confirm path → **Phase 26 (AUD-01, AUD-02, AUD-03)**.
- Full `Parapet.Telemetry.RecoveryAction` emit-site wiring → **Phase 26**. Phase 25 may opportunistically emit `:short_circuited`/`:conflicted` if trivially cheap (D-16).
- 6 prebuilt playbooks consuming the new operator path → **Phase 27 (PB-01..PB-06)**.
- Stable-tier graduation for new return-tuple variants + CHANGELOG migration note → **Phase 29 (STAB-07)**.
