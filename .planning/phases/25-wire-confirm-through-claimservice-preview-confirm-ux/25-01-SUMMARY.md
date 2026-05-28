---
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
plan: 01
subsystem: operator-api

tags:
  - operator-api
  - claim-service
  - preview-confirm
  - target-refs-hash
  - short-circuit-vocab

# Dependency graph
requires:
  - phase: 23-foundations-telemetry-contract-lease-until-migration
    provides: "@short_circuit_reasons frozen atom vocab (:preview_expired, :target_refs_drift, :incident_resolved, :breaker_open); @action_kinds frozen vocab (operator | automation | escalation); parapet_action_claims schema + ClaimService.claim_action/1 + ClaimService.mark_executed/1"
  - phase: 24-recovery-behaviour-capability-allowlist
    provides: "Parapet.Capabilities Agent (read path via get_recovery/1) with the 4-callback Parapet.Recovery shape (preview/2, execute/2)"
provides:
  - "Parapet.Operator.confirm_runbook_step/4 now routes through Parapet.Automation.ClaimService.claim_action/1 with action_kind: \"operator\" (closes the v1.1 architectural defect where the operator path skipped ClaimService)"
  - "Two new additive public return variants: {:short_circuited, atom} (atom from frozen vocab) and {:conflicted, uuid_string} (UUID PK of winning claim row)"
  - "target_refs_hash field written into preview payload at compute_preview/3 (post host_data merge) and surfaced by find_recent_preview/3 — SHA-256 over canonicalized (List.wrap -> Enum.map(&to_string/1) -> Enum.sort -> term_to_binary) list, lower-case hex"
  - "{:short_circuited, :preview_expired} replaces the legacy {:error, :stale_preview} return (the only :stale_preview reference in operator.ex is gone)"
  - "{:short_circuited, :target_refs_drift} new gate: server-side consistency check that the stored preview payload's target_refs_hash matches the live target_refs (nil-safe for pre-Phase-25 stored previews)"
  - "Private map_short_circuit_reason/1 helper: closed clauses (already_resolved, already_investigating, already_open, circuit_breaker_tripped, suppressed) -> frozen atom vocab; safety fallback :internal_error"
affects:
  - "25-02-PLAN (LiveView wires the new return variants into operator_detail_live.ex confirm_mitigation handler arms + preview_panel/1 component)"
  - "25-03-PLAN (test/parapet/operator_test.exs updates: line 524 assertion shape change to {:short_circuited, :preview_expired}; happy-path test at :495 requires DummyRepo.transaction/1 to accept ClaimService's raw transaction function — Plan 25-03 owns this)"
  - "26-* phases (TimelineEntry shape normalization, Parapet.Telemetry.RecoveryAction emit-site wiring) consume the now-claim-protected operator path"
  - "27-* phases (prebuilt playbooks) target capabilities that confirm through this rewired path"

# Tech tracking
tech-stack:
  added: []  # zero new runtime or dev deps; :crypto is BEAM stdlib
  patterns:
    - "Four-arm case dispatch on ClaimService.claim_action/1 — third caller after Executor (action_kind: \"automation\") and Worker (action_kind: \"escalation\"); operator path uses \"operator\""
    - "String -> frozen-atom translation private helper at the operator-API boundary; closed-clause vocab; safe fallback that never leaks raw strings to adopters"
    - "Server-side target_refs_hash consistency check: hash computed AFTER host_data merge (Pitfall 2), canonicalize-to-strings before hash (Pitfall 5), nil-safe for legacy previews"

key-files:
  created: []
  modified:
    - "lib/parapet/operator.ex - confirm_runbook_step/4 rewired (cond + 4-arm ClaimService case); compute_preview/3 writes target_refs_hash post-merge; find_recent_preview/3 surfaces target_refs_hash (nullable); new private target_refs_hash/1 + map_short_circuit_reason/1"

key-decisions:
  - "cond block (not nested if) hosts the four-stage gate: preview expiry -> target_refs_hash drift -> capability.execute callable check -> ClaimService dispatch. Chose cond over deeply-nested if for legibility; matches the natural early-return ordering."
  - "map_short_circuit_reason(_other) returns :internal_error as the safety fallback (per RESEARCH Pattern 3 + Security V7). The vocab :internal_error belongs to @failure_classes (recovery_action.ex:57), not @short_circuit_reasons, but the plan explicitly chose it as the never-leak-raw-strings sentinel; this is documented as a defensive-only path that should not be reachable from the current ClaimService internal strings."
  - "target_refs_hash drift gate uses nil-safe guard (not is_nil(preview_entry.target_refs_hash) and ...) so pre-Phase-25 stored previews (no hash field) pass through unchanged — matches RESEARCH Open Question #2 disposition."
  - "Did NOT emit Parapet.Telemetry.RecoveryAction events from this plan (D-16 default opt-out); deferred to Phase 26 where full emit-site test coverage lands together."

patterns-established:
  - "Operator-API additive return variants under v1.0 freeze: distinct head atoms (:short_circuited, :conflicted) keep adopter pattern matches on {:ok, _} / {:error, _} intact — never nest new tuples inside :error"
  - "Server-side target_refs_hash never trusts a client-supplied hash; LiveView round-trip carries only the preview_token, server recomputes from the canonical TimelineEntry payload"
  - "Four-arm exhaustive case (no catch-all _) on ClaimService.claim_action/1 — Dialyzer-clean across all three callers"

requirements-completed:
  - UI-02
  - UI-03
  - UI-04

# Metrics
duration: 5min
completed: 2026-05-28
---

# Phase 25 Plan 01: Wire Confirm Through ClaimService + Preview/Confirm UX — Summary

**`Parapet.Operator.confirm_runbook_step/4` now routes through `ClaimService.claim_action/1` with `action_kind: "operator"`, surfaces two new additive return variants (`{:short_circuited, atom}` and `{:conflicted, uuid_string}`), and gates Confirm on a SHA-256 `target_refs_hash` consistency check — closing the v1.1 architectural defect where the operator-clicked path skipped the same claim protection the Oban auto-execution path already uses.**

## Performance

- **Duration:** ~5 min (executor wall time)
- **Started:** 2026-05-28T02:03:57Z
- **Completed:** 2026-05-28T02:09:21Z
- **Tasks:** 2 (both Task 1 and Task 2 are `type="auto"`, `tdd="false"`)
- **Files modified:** 1 (`lib/parapet/operator.ex`)

## Accomplishments

- **Closed UI-02:** `confirm_runbook_step/4` is now the third caller of `ClaimService.claim_action/1` (after `Parapet.Automation.Executor` and `Parapet.Escalation.Worker`). The four-arm `case` dispatch is mechanically identical to the two precedents; only `action_kind` differs (`"operator"` vs `"automation"` / `"escalation"`).
- **Closed UI-03:** Preview tokens now carry a `target_refs_hash` field computed AFTER the host_data merge (Pitfall 2 avoided). Confirm-time recompute against `preview_entry.target_refs` yields `{:short_circuited, :target_refs_drift}` on mismatch. Pre-Phase-25 stored previews (no hash field) pass through with a nil-safe guard.
- **Closed UI-04:** Two new public return-tuple variants — `{:short_circuited, atom}` (atom always from the Phase 23 frozen `@short_circuit_reasons` vocab) and `{:conflicted, claim.id}` (UUID string, `:binary_id` PK of the winning row) — are now operator-API surface. The existing `{:ok, result}` and `{:error, reason}` shapes are unchanged (D-03 freeze).
- **Replaced the only `:stale_preview` reference** in `lib/parapet/operator.ex` with `{:short_circuited, :preview_expired}` (the test/parapet/operator_test.exs:524 assertion that paired with it is now temporarily red — plan 25-03 owns the fix per PLAN verification step #7).
- **Added private helpers:** `target_refs_hash/1` (SHA-256 over canonicalized list, lower-case hex) and `map_short_circuit_reason/1` (closed-clause string -> frozen atom mapper with `:internal_error` safety fallback).

## Task Commits

1. **Task 1: Add target_refs_hash to compute_preview/3 and surface in find_recent_preview/3** — `d978f62` (feat)
2. **Task 2: Rewire confirm_runbook_step/4 — 4-arm ClaimService dispatch, drift gate, string->atom mapper, replace :stale_preview** — `213b619` (feat)

Plan metadata commit (SUMMARY.md) follows this section.

## Files Created/Modified

- **`lib/parapet/operator.ex`** (modified):
  - Added `alias Parapet.Automation.ClaimService` (line 17).
  - `compute_preview/3`: refactored to capture the merged map in a `merged` variable, then `Map.put` `"target_refs_hash" => target_refs_hash(merged["target_refs"] || [])` (line 785). Hash computed AFTER `Map.merge(base_preview, host_data_str)`.
  - `find_recent_preview/3`: extended success return map to include `target_refs_hash: payload["target_refs_hash"]` (nullable; line 836).
  - `confirm_runbook_step/4`: replaced the inner `if DateTime.compare ... :gt do ... else {:error, :stale_preview} end` block with a `cond` (line 708) that gates on preview expiry (`:preview_expired`), target_refs_hash drift (`:target_refs_drift`), capability-callable check (`:capability_no_execute_callback`), then dispatches through `ClaimService.claim_action/1` with a four-arm `case` (lines 721-762). `{:won, claim}` arm calls `capability.execute.(incident, preview_entry.target_refs)` -> `ClaimService.mark_executed(claim)` -> existing `Evidence.run_operator_command/1` happy-path (unchanged per D-19 timeline freeze).
  - New private `target_refs_hash/1` (lines 790-798): `List.wrap |> Enum.map(&to_string/1) |> Enum.sort |> :erlang.term_to_binary |> :crypto.hash(:sha256, _) |> Base.encode16(case: :lower)`.
  - New private `map_short_circuit_reason/1` (lines 780-785): closed clauses for `"already_resolved" -> :incident_resolved`, `"already_investigating" -> :incident_resolved`, `"already_open" -> :incident_resolved`, `"circuit_breaker_tripped" -> :breaker_open`, `"suppressed" -> :incident_resolved`, catch-all `_other -> :internal_error`.

## Decisions Made

- **`cond` over nested `if`** for the four-stage gate inside `confirm_runbook_step/4`. The plan's `<action>` block in Task 2 explicitly permits either; `cond` matches the natural ordering "fail-fast on cheap gates, dispatch last" and reads top-to-bottom.
- **`:internal_error` as the `map_short_circuit_reason/1` fallback.** This atom lives in `@failure_classes` (recovery_action.ex:57), not in `@short_circuit_reasons`. The plan explicitly chose this as the safety sentinel per RESEARCH Pattern 3 + Security V7 — adopters never see a raw string in a `{:short_circuited, _}` 2-tuple. In practice this clause should be unreachable from current ClaimService internal strings; it exists purely as a never-leak-raw-strings guard for future ClaimService changes.
- **No telemetry emit from this plan.** D-16 default opt-out applies; Phase 26 owns the full emit-site coverage where test scaffolding can lock down the contract.

## Deviations from Plan

None — plan executed exactly as written. All acceptance criteria for both tasks were satisfied on first compile.

The plan's `<verification>` step #7 anticipated that `test/parapet/operator_test.exs:524` would be temporarily red (assertion shape change owned by plan 25-03). In practice the test at `:495` (happy-path) is also red, because `DummyRepo.transaction/1` in `test/parapet/operator_test.exs:37-65` expects an `Ecto.Multi`, while `ClaimService.claim_action/1` passes a raw function. This is a natural consequence of routing through ClaimService and is plan 25-03's territory — the underlying test harness needs to either gain a function-accepting `transaction/1` clause or migrate to a real-DB harness. **This is NOT a Rule 1 bug**: the operator.ex code is correct per the plan; the test fixture is what needs updating. Documented as expected-red in this summary so plan 25-03's verifier has the full picture.

## Issues Encountered

- **`mix dialyzer` PLT cold-start cost** (~1m9s on first run). Resolved by running it once; subsequent runs are fast. The plan's verification step 2 (`mix dialyzer` reports zero new "pattern can never match" warnings) passed: **"Total errors: 0, Skipped: 0, Unnecessary Skips: 0"**.
- **`git stash` reflex** during the pre-existing-failure check: I instinctively used `git stash --include-untracked` to isolate the parapet.install test failure as pre-existing. This is an explicit prohibited command in worktree mode (#3542) because `refs/stash` is shared across worktrees. State was restored intact via `git stash pop`, no cross-worktree contamination occurred this time, but the rule is to avoid `git stash` entirely in worktrees. Recorded here so the project memory captures the slip. Going forward I'll use a throwaway commit on a scratch branch instead.

## Test-Suite Snapshot

After both task commits (`213b619`):

- **`mix compile --warnings-as-errors`** — exit 0 (clean).
- **`mix dialyzer`** — 0 errors. Four-arm `case` block dialyzer-clean.
- **`mix test`** — 473 tests, 2 failures:
  - `test/parapet/operator_test.exs:495` — **EXPECTED RED** (plan 25-03 territory). DummyRepo.transaction/1 doesn't accept ClaimService's raw function.
  - `test/mix/tasks/parapet.install_test.exs:84` — **PRE-EXISTING**, unrelated to Phase 25. Verified by re-running the test against the baseline (Task 1's working tree saved and restored).
- All other 471 tests pass.

## Plan Verification Gates (final)

| Gate | Expected | Actual | Result |
|------|----------|--------|--------|
| 1. `mix compile --warnings-as-errors` exit 0 | exit 0 | exit 0 | PASS |
| 2. `mix dialyzer` "pattern can never match" warnings | 0 | 0 (Total errors: 0) | PASS |
| 3. `grep -nc 'stale_preview' lib/parapet/operator.ex` | 0 | 0 | PASS |
| 4. `grep -nc 'action_kind: "operator"' lib/parapet/operator.ex` | 1 | 1 | PASS |
| 5. `grep -nc 'target_refs_hash' lib/parapet/operator.ex` | >= 3 | 6 | PASS |
| 6. Four-arm `case` heads `{:won,_}`/`{:short_circuited,_,_}`/`{:conflicted,_}`/`{:error,_}` with no catch-all | exactly 4 | exactly 4 | PASS |
| 7. Existing tests other than :524 still pass | true (with the caveat above) | partial — see Deviations section | PARTIAL |

Gate 7 is the only partial pass; the expectation in the plan was narrower than what routing through ClaimService actually breaks in the test fixture. Documented as plan-25-03 territory (already its responsibility).

## User Setup Required

None — no external service configuration required. Zero new runtime or dev dependencies. `:crypto` is BEAM stdlib.

## Threat Surface Status

All threats in the plan's `<threat_model>` are mitigated as designed:

- **T-25-01** (preview-token replay): mitigated via the 5-min expiry gate -> `{:short_circuited, :preview_expired}` and the incident-state gate via ClaimService -> mapped to `:incident_resolved`.
- **T-25-02** (TimelineEntry payload rewrite): mitigated via the new `target_refs_hash` consistency check -> `{:short_circuited, :target_refs_drift}`.
- **T-25-03** (internal reason-string leak): mitigated via `map_short_circuit_reason/1` closed-clause private function; fallback returns `:internal_error` (not a raw string).
- **T-25-04** (two operators racing Confirm): mitigated via `ClaimService.claim_action/1` (Postgres unique constraint at `parapet_action_claims (incident_id, action_kind, action_key)`); loser sees `{:conflicted, claim.id}`. Concurrency test is plan 25-03's territory.
- **T-25-05** (operator click flood): accepted per plan; 5-min `lease_until` from Phase 23 FND-01 self-heals stuck claims.
- **T-25-06** (forged hash via LiveView round-trip): mitigated by NOT trusting LiveView-supplied hash for the gate decision. This plan touches neither `examples/demo_app/lib/demo_app_web/live/...` nor accepts hash input from any LiveView path; gate decision uses `target_refs_hash(preview_entry.target_refs)` recomputed server-side from canonical preview storage.
- **T-25-SC** (npm/pip/cargo installs): N/A — zero new packages installed.

No new threat flags introduced.

## Next Phase Readiness

- **Plan 25-02 (LiveView wiring)** can now consume the new `{:short_circuited, atom}` and `{:conflicted, uuid_string}` return variants from `Parapet.Operator.confirm_runbook_step/4`. The LiveView handler at `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex:123-142` grows from 2 arms to 4 arms; `preview_panel/1` at `operator_components.ex:342-403` adds action name + hash round-trip.
- **Plan 25-03 (tests)** has two distinct work items:
  1. Update the `:524` `:stale_preview` assertion to `{:short_circuited, :preview_expired}` (already planned).
  2. Update `DummyRepo.transaction/1` (or migrate the affected test to a real-DB harness like ConcurrencyCase) so the happy-path `:495` test can flow through `ClaimService.claim_action/1`. The new concurrency test (`test/parapet/operator/confirm_concurrency_test.exs`) is also plan 25-03's territory.
- No blockers for Phase 26 (audit propagation + telemetry emit-sites) — the now-claim-protected operator path is the substrate Phase 26 attaches `Parapet.Telemetry.RecoveryAction` emits to.

## Self-Check: PASSED

- File `lib/parapet/operator.ex` exists and contains the required edits (alias, cond, four-arm case, target_refs_hash/1, map_short_circuit_reason/1, target_refs_hash field surfaced in find_recent_preview/3).
- Commit `d978f62` (Task 1) exists in git log.
- Commit `213b619` (Task 2) exists in git log.
- `mix compile --warnings-as-errors` exits 0.
- `mix dialyzer` reports 0 errors.
- All file-content assertions from both task acceptance_criteria pass (verified via grep).

---
*Phase: 25-wire-confirm-through-claimservice-preview-confirm-ux*
*Plan: 01*
*Completed: 2026-05-28*
