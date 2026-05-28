---
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
  - examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex
  - lib/parapet/operator.ex
  - test/parapet/operator/confirm_concurrency_test.exs
  - test/parapet/operator/preview_lifecycle_test.exs
  - test/parapet/operator_test.exs
findings:
  critical: 3
  warning: 6
  info: 3
  total: 12
status: issues_found
---

# Phase 25: Code Review Report

**Reviewed:** 2026-05-27T00:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Phase 25 wired `Parapet.Operator.confirm_runbook_step/4` through `ClaimService.claim_action/1`, added `{:short_circuited, reason}` / `{:conflicted, claim_id}` variants, and a `target_refs_hash` drift gate. The claim-protected race path is correct and well-proven by `confirm_concurrency_test.exs` — the unique-constraint-based winner/loser split is sound and the public 2-tuple translation at the boundary is verified.

However, the review surfaced three BLOCKER-level defects that the test suite does not catch because all unit tests pin the incident to `state: "open"` and mock the claim layer to always win:

1. The incident-state gate inside ClaimService requires `state == "open"`, but the documented operator UI flow (Acknowledge → Preview → Confirm) moves the incident to `"investigating"` before Confirm is reachable, so a normal confirm short-circuits — and is mislabeled `:incident_resolved`.
2. A won claim is never released or transitioned when `capability.execute` returns `{:error, _}`, leaking the claim for the full 5-minute lease and blocking operator retry.
3. `capability.execute` (adopter-supplied) is invoked with no `rescue`, so a host exception crashes the LiveView/operator boundary.

Secondary issues include a tautological/misleading `target_refs_hash` gate, lossy short-circuit reason mapping that violates the frozen telemetry vocab, a latent crash in `find_recent_preview`, and several UI/state coupling defects (Confirm button never clears after success; cross-node conflict copy shown for self-conflict).

## Critical Issues

### CR-01: Confirm path short-circuits (mislabeled `:incident_resolved`) after the normal Acknowledge step

**File:** `lib/parapet/operator.ex:721-727` (confirm) + `lib/parapet/automation/claim_service.ex:162-163` (gate) + `lib/parapet/operator.ex:780-784` (mapping)

**Issue:** `ClaimService.run_gates/4` calls `incident_state_gate/1`, which returns `:ok` **only** for `state == "open"`; any other state returns `{:short_circuit, "already_#{state}"}`. The standard operator UI flow is Acknowledge → Preview → Confirm. `acknowledge_incident/2` (`operator.ex:343-345`) transitions the incident to `"investigating"`. So by the time the operator clicks Confirm, the incident is `"investigating"`, the gate emits `"already_investigating"`, and `confirm_runbook_step/4` returns `{:short_circuited, :incident_resolved}` (via `map_short_circuit_reason("already_investigating") -> :incident_resolved`, `operator.ex:781`). The LiveView then flashes "Incident already resolved — no action needed" (`operator_detail_live.ex:162`) for an incident that is neither resolved nor un-actionable. Recovery becomes impossible through the documented happy path, and the reason shown to the operator is factually wrong.

This is invisible to the test suite because every unit test pins `state: "open"` (`operator_test.exs:549`, `preview_lifecycle_test.exs:167`, `confirm_concurrency_test.exs` inserts a fresh open incident) and `confirm_concurrency_test.exs` never acknowledges first.

**Fix:** Decide the intended state contract for operator recovery and align gate + UI. If recovery is meant to run while investigating, pass an explicit allowed-state set into ClaimService (or supply a `gate:`/`incident_state_gate` override) so `"investigating"` is permitted:
```elixir
# in confirm_runbook_step/4, when building claim_action opts
ClaimService.claim_action(
  incident_id: incident.id,
  action_kind: "operator",
  action_key: to_string(step_id_atom),
  breaker_step_id: step_id_atom,
  idempotency_key: payload.idempotency_key,
  # operator recovery is valid in open OR investigating
  gate: fn _repo, %{state: s}, _claim ->
    if s in ["open", "investigating"], do: :ok, else: {:short_circuit, "already_#{s}"}
  end
)
```
Alternatively, gate the Confirm button in the UI to `state == "open"` only and document that operators must Confirm before acknowledging — but that contradicts the Acknowledge-first action rail. Either way, also fix CR-02 below (mapping) so the surfaced reason is honest.

### CR-02: Won claim is never released on `capability.execute` failure — 5-minute retry lockout

**File:** `lib/parapet/operator.ex:728-752`

**Issue:** On `{:won, claim}`, when `capability.execute.(incident, target_refs)` returns `{:error, reason}` (line 750), the function returns `{:error, reason}` and the claim row is left in status `"claimed"` with a `lease_until` 5 minutes out (`claim_service.ex:17,26`). `mark_executed/1` is only called on the success branch (line 731). There is no `mark_failed`/release on the error branch. Consequence: the operator cannot retry the recovery — any retry within the lease window re-enters `acquire_claim`, finds the existing live `"claimed"` row (not yet expired, so `steal_expired_claim` returns nil), and returns `{:conflicted, claim.id}`. The operator sees the cross-node "Another node is executing this recovery" warning (`operator_detail_live.ex:149`) for a recovery that has already failed and is not running anywhere. This is a recoverability/data-availability defect: a transient provider error locks the operator out for 5 minutes.

**Fix:** Transition the claim out of `"claimed"` on execute failure so a retry can re-claim immediately:
```elixir
{:error, reason} ->
  ClaimService.mark_failed(claim, reason)   # add a mark_failed/2 to ClaimService
  {:error, reason}
```
If ClaimService has no failure transition yet, add one that sets status to `"failed"` (and records `last_error_*`) so `acquire_claim` no longer treats the row as a live claim, or so a retry path can steal/replace it. Verify `acquire_claim`/`steal_expired_claim` will re-grant after a `"failed"` row exists (currently `steal_expired_claim` only matches `status == "claimed"` AND expired lease — a `"failed"` row would still collide on the unique constraint and produce `{:conflicted, _}`, so the steal/replace logic must also cover terminal-but-non-executed states).

### CR-03: Adopter-supplied `capability.execute` invoked with no exception isolation

**File:** `lib/parapet/operator.ex:729`

**Issue:** `capability.execute.(incident, preview_entry.target_refs)` is a host/adopter-provided closure (registered via `Parapet.Capabilities.register_recovery/2`). It is called bare. If it raises (network client throws, pattern-match failure, etc.), the exception propagates uncaught out of `confirm_runbook_step/4`, crashing the calling LiveView process and — worse — leaving the just-won claim stuck in `"claimed"` (same lockout as CR-02, now also unauditable). The operator boundary is documented as the "Phoenix-free public boundary" (`operator.ex:3`) and should not let adopter code crash it. Note `compute_preview/3` already defensively wraps `capability.preview` in a `case`/fallback (lines 805-817), but the far more dangerous `execute` is not protected.

**Fix:** Wrap the execute call and convert exceptions into a structured error plus claim cleanup:
```elixir
result =
  try do
    capability.execute.(incident, preview_entry.target_refs)
  rescue
    e -> {:error, {:capability_raised, Exception.message(e)}}
  end

case result do
  {:ok, exec_result} -> ...
  {:error, reason} ->
    ClaimService.mark_failed(claim, reason)   # see CR-02
    {:error, reason}
end
```

## Warnings

### WR-01: `target_refs_hash` drift gate is a tautology in production and the surfaced copy is misleading

**File:** `lib/parapet/operator.ex:712-715`, `787-835`; `operator_detail_live.ex:164`

**Issue:** The drift gate compares `preview_entry.target_refs_hash` against `target_refs_hash(preview_entry.target_refs)` — but **both** values originate from the *same* stored timeline payload. The hash was computed in `compute_preview/3` over exactly the `target_refs` that were persisted alongside it. On read-back they are deterministically derived from each other, so under normal (untampered, single-row) operation the comparison can never be unequal. The only conditions that trip it are (a) direct DB tampering of one jsonb key without the other (not a realistic external attack surface — it requires DB write access), or (b) a canonicalization mismatch, which the suite deliberately proves is a NO-OP (`preview_lifecycle_test.exs:265-306`). It does **not** detect drift in the real-world target state (e.g., the actual `["item-1"]` resources changing between Preview and Confirm), because that would require re-invoking `capability.preview` and diffing the live snapshot. Yet the user-facing copy claims "Target state changed since Preview — please re-Preview" (`operator_detail_live.ex:164`), which overstates the protection.

**Fix:** Either (a) make the gate meaningful by recomputing the live preview snapshot at confirm time and comparing its `target_refs_hash` to the stored one; or (b) keep the integrity check but rename it/scope its copy to what it actually verifies (payload integrity, not real-world drift). Do not market it as a state-drift guard if it only catches stored-row corruption.

### WR-02: Short-circuit reason mapping is lossy and leaks reasons outside the frozen telemetry vocab

**File:** `lib/parapet/operator.ex:780-785`

**Issue:** `map_short_circuit_reason/1` collapses `"already_resolved"`, `"already_investigating"`, `"already_open"`, and `"suppressed"` all to `:incident_resolved`. The frozen vocab in `recovery_action.ex:46-51` is `[:incident_resolved, :breaker_open, :preview_expired, :target_refs_drift]`. Mapping `"already_investigating"` and `"suppressed"` to `:incident_resolved` is semantically wrong (the incident is not resolved), and there is no atom for "suppressed" or "investigating" in the vocab, so the truth is lost. This directly causes the wrong flash text in CR-01. Mapping `"already_open"` to `:incident_resolved` is nonsensical (open is the *valid* state). The catch-all `_other -> :internal_error` will silently swallow any future ClaimService reason string.

**Fix:** Extend the frozen vocab (e.g. add `:incident_state_invalid` / `:suppressed`) and map each ClaimService reason to a truthful atom; do not alias unrelated states to `:incident_resolved`. At minimum, separate `"already_resolved"` (-> `:incident_resolved`) from `"already_investigating"`/`"already_open"` (-> a distinct state-invalid reason). Coordinate with `recovery_action.ex` since that vocab is described as frozen.

### WR-03: `find_recent_preview` raises on a malformed `expires_at` string (latent crash)

**File:** `lib/parapet/operator.ex:861-863`

**Issue:** In the `is_binary(str)` branch, `{:ok, dt, _} = DateTime.from_iso8601(str)` uses a strict match. If a stored preview has a non-ISO8601 `expires_at` string (corrupt row, or a future writer that stores a different format), `from_iso8601` returns `{:error, _}` and the match raises `MatchError`, crashing `confirm_runbook_step/4` and the LiveView. Compare with `WorkbenchContract.find_active_preview/1` (`workbench_contract.ex:184-192`), which handles the `{:error, _}` case gracefully. The two readers of the same field disagree on robustness.

**Fix:** Mirror the safe handling:
```elixir
str when is_binary(str) ->
  case DateTime.from_iso8601(str) do
    {:ok, dt, _} -> dt
    _ -> DateTime.utc_now()   # or treat as expired -> short-circuit
  end
```

### WR-04: Successful Confirm never marks the step executed in the UI — Confirm button stays live, enabling double-confirm

**File:** `lib/parapet/operator.ex:733-734`; `lib/parapet/operator/workbench_contract.ex:125-138`; `operator_components.ex:389-398`

**Issue:** On success the timeline entry written is `type: "recovery_confirmed"` (line 734). But `WorkbenchContract.derive_runbook_steps/3` only marks a step `:executed` when it finds a `"mitigation_executed"` entry for that `step_id` (`workbench_contract.ex:125-134`). It never looks for `"recovery_confirmed"`. So after a successful confirm the step stays `:executable`/`:previewable`, the preview row remains within its 5-minute window, `find_active_preview` keeps returning it, and the `preview_panel` keeps rendering a live "Confirm Recovery" button (`operator_components.ex:391`). A second click re-enters `confirm_runbook_step`, finds the same valid preview, and now collides with the existing executed claim → `{:conflicted, claim.id}` → the user sees the misleading "Another node is executing this recovery" warning (`operator_detail_live.ex:149`) for an action they themselves just completed.

**Fix:** Either (a) also emit/recognize a step-completed signal that `derive_runbook_steps/3` consumes (add `"recovery_confirmed"` to the executed-detection in WorkbenchContract, keyed on `step_id`), so the panel clears and the step shows "Executed"; and/or (b) in the LiveView, hide the Confirm button once the step is executed. Without this, the happy path leaves a footgun for double-submission.

### WR-05: `{:conflicted, _}` copy assumes multi-node; misleads single-node self-conflict

**File:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex:146-150`

**Issue:** The `{:conflicted, _claim_id}` flash is hardcoded to "Another node is executing this recovery — refresh to see the outcome". But a conflict is also produced when the *same* operator double-submits (WR-04), or when a prior attempt failed and left a stuck claim (CR-02), or when an already-executed claim row still satisfies the unique constraint. In all of these single-node cases the copy is wrong and will confuse operators into waiting for a non-existent peer node.

**Fix:** Make the copy outcome-agnostic, e.g. "This recovery is already claimed (in progress or completed) — refresh to see the current state." Ideally inspect the conflicting claim's status to differentiate "in progress" from "already executed/failed".

### WR-06: Operator confirm action_type is `:execute_mitigation` but the audit/timeline label it as preview-confirm — inconsistent action taxonomy

**File:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex:123-133`; `lib/parapet/operator.ex:742`

**Issue:** The LiveView builds the confirm payload with `action_type: :execute_mitigation` (line 129) and a freshly generated `idempotency_key` per click (`Ecto.UUID.generate()`, line 130). Two problems: (1) `:execute_mitigation` is the action_type used by `execute_runbook_step/3` (`operator.ex:606,926`), yet `confirm_runbook_step` writes audit `tool_name: "operator_confirm_recovery"` (line 742) — the action_type and the audited tool disagree, muddying the audit trail. (2) Generating a new `idempotency_key` on every click means the idempotency key does **not** dedupe operator retries; only the `(incident_id, action_kind, action_key)` unique constraint does. The phase intent ("requires an idempotency_key", `operator.ex:689`) is satisfied syntactically but provides no real idempotency across retries — each retry presents a different key. This is acceptable given the claim row is the real dedupe, but the per-click UUID is misleading and should at least be derived deterministically (e.g. from preview_token) so retries of the *same* confirm carry the same key.

**Fix:** Use a deterministic idempotency key tied to the confirm intent (e.g. `"operator_confirm_#{incident_id}_#{step}_#{token}"`, mirroring `confirm_concurrency_test.exs:109`), and reconcile the `action_type`/`tool_name` pairing so the audit taxonomy is internally consistent.

## Info

### IN-01: `inspect/1` used to serialize execute result into durable timeline payload

**File:** `lib/parapet/operator.ex:738` (and `624` for mitigation)

**Issue:** `"result" => inspect(exec_result)` stores an Elixir-inspect string into the jsonb timeline payload. `inspect` output is not a stable serialization contract — it can change across OTP/Elixir versions and is not machine-parseable. For durable evidence this is fragile.

**Fix:** Store a structured/normalized representation (e.g. a bounded map or a `to_string`-able summary) rather than `inspect/1` output, if downstream consumers ever need to read `result`.

### IN-02: Non-constant-time comparison of the security-bearing preview token

**File:** `lib/parapet/operator.ex:850`

**Issue:** `entry.payload["preview_token"] == token` compares the confirm-gating token with `==`, which short-circuits on first differing byte (timing side channel). The token is 128 bits of `:crypto.strong_rand_bytes` so brute-forcing via timing is impractical, but for a value that authorizes execution of a recovery, constant-time comparison is the defensive default.

**Fix:** Use `Plug.Crypto.secure_compare/2` (or `:crypto`-based constant-time compare) when matching the token, after first filtering candidate entries by `step_id`.

### IN-03: Unit DummyRepo "always wins the claim" diverges from production gate behavior, masking CR-01/CR-02

**File:** `test/parapet/operator_test.exs:74-97`; `test/parapet/operator/preview_lifecycle_test.exs:72-93`

**Issue:** The DummyRepo `insert_all/3` stub unconditionally returns `{1, [claim]}` (first-caller-wins) and `aggregate/3` returns `0` (breaker never trips), and every incident is `state: "open"`. This is a faithful happy-path double, but it means no unit test exercises the `incident_state_gate` short-circuit for `"investigating"`/`"resolved"`, the execute-failure branch (CR-02), or an execute that raises (CR-03). The concurrency test proves the real claim collision but only with fresh open incidents. The blind spots directly correspond to the three BLOCKERs above.

**Fix:** Add unit coverage for: (a) confirm against an `"investigating"` incident (assert the surfaced reason is truthful, not `:incident_resolved`); (b) `capability.execute` returning `{:error, _}` (assert the claim is not left `"claimed"`); (c) `capability.execute` raising (assert no crash, structured error returned).

---

_Reviewed: 2026-05-27T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
