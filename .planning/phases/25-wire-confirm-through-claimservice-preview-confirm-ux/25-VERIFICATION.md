---
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
verified: 2026-05-28T07:25:00Z
status: passed
score: 4/4 must-haves verified (code/contract level); 4/4 requirement IDs satisfied; 3/3 code-review BLOCKERs FIXED
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: "4/4 (criterion-level); 4/4 requirement IDs; 3 BLOCKERs open as WARNINGs pending a product decision"
  gaps_closed:
    - "CR-01: incident_state_gate now accepts allowed_states (default [\"open\"]; operator passes [\"open\",\"investigating\"]) — Acknowledge-then-Confirm no longer short-circuits. Product decision (ack-then-confirm is valid) resolved YES; fix verified in claim_service.ex + operator.ex; covered by 2 new passing tests."
    - "CR-02: ClaimService.mark_failed/2 added (status \"failed_retryable\" + last_error_*); steal_expired_claim re-grants failed_retryable rows; operator error arm releases the claim. No more 5-minute retry lockout. Verified in code + unboxed Postgres test (mark_failed-then-retry re-grants the same row)."
    - "CR-03: capability.execute wrapped in try/rescue → {:error, {:capability_raised, msg}}; claim released via mark_failed. Verified in code + new passing structured-error test."
  gaps_remaining: []
  regressions: []
  note: "Re-verification after commits 65e5ee5 + 790541b. Independently re-checked the 3 former BLOCKERs against the code and ran the new regression tests in-process. Full library suite re-run: 483 tests, 0 failures. mix compile --warnings-as-errors clean."
milestone_closeout:
  status: "accepted_with_deferred_visual_uat"
  accepted_on: "2026-06-03"
  note: "The remaining human_verification items are visual/real-time demo confirmations only. No code, contract, or requirement gaps remain; visual UAT remains documented in 25-HUMAN-UAT.md for post-close follow-up."
human_verification:
  - test: "Open-incident happy path in the demo app: open an OPEN incident, click Preview on a capability-backed runbook step, then click Confirm Recovery."
    expected: "Preview panel shows Action name + Target Kind + Affected Count; Confirm flashes \"Mitigation confirmed and executed\" and the capability executes. (Code + unit/concurrency tests prove this returns {:ok, recovery_confirmed} on an open incident; visual render needs human eyes.)"
    why_human: "LiveView visual rendering (preview panel layout, flash appearance, blast-radius/diff fields) cannot be verified programmatically; demo app is not in the library mix test path (RESEARCH Pitfall 3)."
  - test: "Acknowledge-then-Confirm path: click Acknowledge Incident (moves state to investigating), then Preview, then Confirm."
    expected: "Confirm now SUCCEEDS — flashes \"Mitigation confirmed and executed\" and the capability executes (NOT the prior mislabeled \"Incident already resolved\"). CR-01 is FIXED: confirm_runbook_step/4 passes allowed_states: [\"open\",\"investigating\"] so the ClaimService state gate no longer short-circuits after Acknowledge. The CR-01 product DECISION is resolved (ack-then-confirm IS a valid workflow). This item is now a pure VISUAL render confirmation of the success flash, not a decision point."
    why_human: "The fix is code-proven (preview_lifecycle_test.exs investigating-succeeds test passes), but confirming the operator sees the SUCCESS flash (not a stale short-circuit message) in the actual demo LiveView still needs human eyes; demo app is a separate Mix project outside the library test path."
  - test: "Conflict-flash copy on single-node self-conflict: trigger a {:conflicted, _} (e.g., double-click Confirm after a successful confirm — WR-04 means the Confirm button never clears) on a single node."
    expected: "Flash reads \"Another node is executing this recovery — refresh to see the outcome\" (verbatim ROADMAP criterion #2). On a single-node self-conflict this copy is misleading (WR-WR05). Verify the copy is acceptable or schedule the WR-WR05 rewording. NOTE: WR-04 (Confirm button not clearing after a successful confirm) was NOT in scope for this fix batch and remains open — the double-confirm path that produces a self-conflict still exists."
    why_human: "Whether the multi-node-worded copy is acceptable for single-node self-conflict is a UX judgment call; the verbatim string is contractually pinned by ROADMAP criterion #2."
  - test: "Preview-expired + re-Preview affordance: generate a Preview, wait past 5 minutes (or expire the stored expires_at), click Confirm."
    expected: "Flash reads \"Preview expired — please re-Preview before confirming\" and the Preview button on the runbook card reappears (the active preview clears via the load_detail re-derive). Confirm there is a usable re-Preview path. NOTE: CONTEXT D-11 mentioned a dedicated 'Re-Preview button'; the implementation instead reuses the existing Preview button (RESEARCH A7) — verify this affordance is discoverable."
    why_human: "Time-based expiry behavior and the reappearing-button affordance are real-time/visual; not exercisable by static checks."
---

# Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX — Verification Report

**Phase Goal:** Close the operator-path-skips-claim defect by routing `Parapet.Operator.confirm_runbook_step/4` through `Parapet.Automation.ClaimService.claim_action/1` (same path the Oban auto-execution uses), add the `{:short_circuited, reason}` and `{:conflicted, claim_id}` additive return variants, and render both branches in the LiveView with operator-actionable next steps. Preview tokens get a 5-minute expiry with `target_refs` hash gating.
**Verified:** 2026-05-28T07:25:00Z
**Status:** passed (accepted with deferred visual UAT at v1.2 closeout pre-flight)
**Re-verification:** Yes — after code-review gap closure (commits 65e5ee5 + 790541b). Previous status: human_needed.

## Re-Verification Summary

The prior verification (2026-05-28T02:42) was `human_needed` for two reasons: (1) the demo LiveView visual flows require human render confirmation, and (2) the CR-01 question — "does the intended operator workflow permit Acknowledge-before-Confirm?" — was an unresolved product DECISION POINT that, if answered "yes", escalated WR-CR01 to a blocker. The user decided **YES**, ack-then-confirm is a valid operator workflow, and the three code-review BLOCKERs were fixed.

**All three BLOCKERs are now FIXED and independently verified against the code + new passing regression tests:**

### CR-01 FIXED — incident_state_gate now allow-list driven; ack-then-confirm succeeds

- `lib/parapet/automation/claim_service.ex:189-206`: `run_gates/4` reads `allowed_states = Keyword.get(opts, :allowed_states, ["open"])` and calls `incident_state_gate(incident, allowed_states)` which returns `:ok` when `state in allowed_states`, else `{:short_circuit, "already_#{state}"}`. The **default `["open"]` preserves Executor/Escalation behavior unchanged** (neither passes `allowed_states`).
- `lib/parapet/operator.ex:721-731`: `confirm_runbook_step/4` passes `allowed_states: ["open", "investigating"]`. So after Acknowledge (state → "investigating"), Confirm no longer short-circuits.
- **Tests (both pass):** `preview_lifecycle_test.exs:265-288` ("succeeds while the incident is investigating") asserts `{:ok, %{timeline_entry: %TimelineEntry{type: "recovery_confirmed"}}}`. `preview_lifecycle_test.exs:290-312` ("short-circuits :incident_resolved when resolved") asserts `{:short_circuited, :incident_resolved}` — proving the gate still honestly blocks the genuinely-resolved case while the `:incident_resolved` reason mapping (operator.ex:796-800) is now reached only via the resolved/open/suppressed paths, not the investigating happy path.

### CR-02 FIXED — won claim released on execute failure; no 5-minute lockout

- `lib/parapet/automation/claim_service.ex:87-96`: new `mark_failed/2` transitions the claim to `"failed_retryable"` (default) and records `last_error_kind`/`last_error_message`.
- `lib/parapet/automation/claim_service.ex:146-167`: `steal_expired_claim` query now re-grants when `(status == "claimed" AND lease_until < now) OR status == "failed_retryable"`, resetting status to `"claimed"`, refreshing the lease, clearing the error fields, and incrementing `attempt_count`.
- `lib/parapet/operator.ex:763-767`: the execute `{:error, reason}` arm now calls `ClaimService.mark_failed(claim, reason)` before returning `{:error, reason}`.
- Schema support: `lib/parapet/spine/action_claim.ex:16-25,39-41,51-65` adds `"failed_retryable"`/`"failed_terminal"` to `@statuses` and `:last_error_kind`/`:last_error_message` fields + casts. Migration `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs:18-19` already has the columns.
- **Test (passes against real Postgres):** `claim_service_test.exs:181-224` (`@tag :unboxed`) wins a claim, calls `mark_failed`, asserts `status == "failed_retryable"` + `last_error_kind == "capability_raised"` + `last_error_message == "provider boom"`, then a retry **re-grants the SAME row** (`retried.id == claim.id`, `status == "claimed"`, `attempt_count == 2`, error fields nil, total claim count still 1). This is the direct CR-02 proof: a transient failure no longer locks the operator out for the lease window.

### CR-03 FIXED — adopter capability.execute isolated in try/rescue

- `lib/parapet/operator.ex:735-740`: `capability.execute.(incident, preview_entry.target_refs)` is wrapped in `try/rescue`; a raise becomes `{:error, {:capability_raised, Exception.message(e)}}`. The structured error then flows through the same `{:error, reason}` arm (operator.ex:763-767) that releases the claim via `mark_failed`, so a raised host closure both (a) cannot crash the operator/LiveView boundary and (b) does not strand the claim.
- **Test (passes):** `preview_lifecycle_test.exs:341-368` registers a capability whose `execute` does `raise "boom from host"`, asserts `{:error, {:capability_raised, message}}` and `message =~ "boom from host"`.

**Net:** the two former human-verification items that were *decision-dependent* (CR-01 ack-then-confirm decision, and conflict-flash-on-self-conflict insofar as it tied to CR-02's stranded-claim conflict) now resolve. CR-01 is fixed (not an open blocker); CR-02's stranded-claim path is fixed so a *failed* recovery no longer produces a spurious self-conflict. The remaining human items are pure LiveView visual/real-time render confirmations.

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Preview renders action name + target args + blast-radius + diff before execution; Confirm without fresh Preview rejected with "re-Preview required" | ✓ VERIFIED (code) / ? render needs human | `preview_panel/1` (operator_components.ex) renders Action cell + Target Kind + Affected Count + warnings. Confirm-without-fresh-Preview gated by `active_preview` + `find_recent_preview/3` `{:error, :mismatched_preview}` (operator.ex:893). Happy-path Confirm on open incident → `{:ok, recovery_confirmed}` (preview_lifecycle_test.exs:232-263, 8 tests pass). Visual layout/diff fields need human render check. |
| 2 | Second operator's Confirm during in-flight claim sees verbatim "Another node is executing this recovery — refresh to see the outcome" (`:conflicted` branch, operator-actionable) | ✓ VERIFIED | `{:conflicted, _claim_id}` arm (operator_detail_live.ex:146-149) emits the verbatim string (grep count = 1). Conflict path PROVEN by claim_service_test.exs:10-83 (unboxed): exactly one `{:won,_}` + one `{:conflicted, %ActionClaim{}}`, single durable row. |
| 3 | Confirm on Preview older than 5 min, or against a resolved-since-Preview incident, returns `{:short_circuited, reason}`; LiveView renders reason with Re-Preview | ✓ VERIFIED | `cond` gate (operator.ex:709-710) → `{:short_circuited, :preview_expired}` proven by preview_lifecycle_test.exs:184-203. Incident-state short-circuit via ClaimService gate → `{:short_circuited, :incident_resolved}` proven by preview_lifecycle_test.exs:290-312 (now honestly reached only for resolved, NOT investigating — CR-01 fix). `short_circuit_flash/1` (operator_detail_live.ex:161-164) renders all 4 reasons (verbatim strings present). Re-Preview = reappearing Preview button (RESEARCH A7). 5-min expiry at compute_preview/3 (operator.ex:804). |
| 4 | Every successful Confirm flows through `ActionPayload` + `ClaimService.claim_action/1` with `action_kind: "operator"` — observable in a multi-node concurrency test | ✓ VERIFIED | `confirm_runbook_step/4` dispatches `ClaimService.claim_action(action_kind: "operator", ...)` (operator.ex:721-731). `{:won, claim}` → isolated `capability.execute` → `ClaimService.mark_executed` (operator.ex:743-744). Multi-node race proven by claim_service_test.exs unboxed suite (4 tests, 0 failures). |

**Score:** 4/4 success criteria met at the code/contract level; 3/3 former BLOCKERs FIXED. Criteria #1, #2, #3 require human render confirmation of the demo LiveView (see Human Verification).

### Requirements Coverage

All four requirement IDs cross-referenced against `.planning/REQUIREMENTS.md` (lines 30-33, 117-120; all map to Phase 25; none orphaned).

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| UI-01 | 25-02 | Preview shows action name, target args, blast-radius, expected diff in a dedicated panel | ✓ SATISFIED | `preview_panel/1` Action cell + Target Kind + Affected Count + Warnings; action name via `get_recovery/1`. (Visual render → human.) |
| UI-02 | 25-01, 25-03 | Confirm routes through `ActionPayload` + `ClaimService.claim_action/1` (closes operator-path-skips-claim defect) | ✓ SATISFIED | operator.ex:721-731 dispatch with `action_kind: "operator"`; unboxed concurrency test proves the claim-protected path. |
| UI-03 | 25-01, 25-03 | 5-min preview expiry; stale detected via `target_refs` hash; expired prompts re-Preview | ✓ SATISFIED | `compute_preview/3` 300s expiry + `target_refs_hash` (operator.ex:804, 838); drift gate (operator.ex:712-715); preview_lifecycle_test covers `:preview_expired`, `:target_refs_drift`, nil-hash legacy compat, Pitfall-5 canonicalization. |
| UI-04 | 25-01, 25-02, 25-03 | Confirm returns `{:short_circuited, reason}` / `{:conflicted, claim_id}`; LiveView renders both branches with actionable next steps | ✓ SATISFIED | New return variants (operator.ex:710,715,771,774); 4-arm LiveView handler (operator_detail_live.ex:133-154); `short_circuit_flash/1` closed mapper; conflict path proven. |

No ORPHANED requirements: REQUIREMENTS.md maps exactly UI-01..UI-04 to Phase 25, and all four are claimed across the three plans.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/parapet/operator.ex` | 4-arm `claim_action/1` dispatch + `allowed_states` + try/rescue execute + `mark_failed` release + `map_short_circuit_reason/1` + `target_refs_hash` | ✓ VERIFIED | `allowed_states: ["open","investigating"]` (730); try/rescue (735-740); `mark_failed` on error arm (766); no debt markers; `mix compile --warnings-as-errors` clean. |
| `lib/parapet/automation/claim_service.ex` | `allowed_states` opt (default `["open"]`); `mark_failed/2`; `steal_expired_claim` re-grants `failed_retryable` | ✓ VERIFIED | `run_gates` reads opt (190); `incident_state_gate/2` (200-206); `mark_failed/2` (87-96); steal query OR-clause (152-153). Executor/Escalation untouched (use default). |
| `lib/parapet/spine/action_claim.ex` | `failed_retryable`/`failed_terminal` statuses + `last_error_*` fields | ✓ VERIFIED | `@statuses` (16-25); fields (39-41); cast list (51-65). Migration columns present (20260521010000:18-19). |
| `examples/demo_app/.../operator_detail_live.ex` | 4-arm `confirm_mitigation` handler + closed `short_circuit_flash/1` + verbatim conflict copy | ✓ VERIFIED | 4 arms (133-154); verbatim conflict flash (149, grep=1); 4 closed flash clauses (161-164). |
| `test/parapet/operator/preview_lifecycle_test.exs` | investigating-succeeds, resolved-short-circuits, execute-error-releases, execute-raise-structured-error (+ prior 4) | ✓ VERIFIED | 8 tests, 0 failures. New CR tests at lines 265-288, 290-312, 314-339, 341-368 — substantive (real Operator + ClaimService path, asserting concrete tuples), not stubs. |
| `test/parapet/automation/claim_service_test.exs` | `mark_failed`-then-retry re-grant (@tag :unboxed, real Postgres) | ✓ VERIFIED | 4 tests, 0 failures (unboxed). New test at 181-224 asserts status transition + same-row re-grant + attempt_count increment + single durable row. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `confirm_runbook_step/4` claim opts | `ClaimService.run_gates/4` `allowed_states` | `allowed_states: ["open","investigating"]` keyword | ✓ WIRED | operator.ex:730 → claim_service.ex:190. Default `["open"]` keeps Executor/Escalation behavior. |
| `confirm_runbook_step/4` execute-error arm | `ClaimService.mark_failed/2` | called on `{:error, reason}` after isolated execute | ✓ WIRED | operator.ex:766. Releases claim to `failed_retryable`. |
| `confirm_runbook_step/4` raised execute | `{:error, {:capability_raised, msg}}` | `try/rescue` around `capability.execute` | ✓ WIRED | operator.ex:735-740; flows into the same release arm. |
| `ClaimService.mark_failed/2` | `steal_expired_claim/2` re-grant | `status == "failed_retryable"` OR-clause | ✓ WIRED | claim_service.ex:152-153; reset to `claimed`, errors cleared. |
| `confirm_runbook_step/4` `{:won, claim}` success | `ClaimService.mark_executed/1` | called after `{:ok, exec_result}` | ✓ WIRED | operator.ex:744. |
| LiveView `confirm_mitigation` | `Parapet.Operator.confirm_runbook_step/4` | case on 4 return variants | ✓ WIRED | operator_detail_live.ex:133-154. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `claim_service_test` mark_failed retry | `released.status`/`last_error_*`, `retried.id` | real `parapet_action_claims` rows via `ConcurrencyRepo` (live Postgres) | Yes | ✓ FLOWING |
| `confirm_runbook_step/4` error arm | `reason` → `mark_failed` → claim row | structured error from isolated execute closure | Yes | ✓ FLOWING |
| `preview_panel/1` Action cell | `preview.action_name` | `get_recovery/1` from Capabilities registry | Yes (capability_id fallback) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Preview lifecycle + CR-01/02/03 unit regressions | `mix test test/parapet/operator/preview_lifecycle_test.exs` | 8 tests, 0 failures (investigating-succeeds, resolved-short-circuits, execute-error-releases, execute-raise-structured) | ✓ PASS |
| ClaimService incl. mark_failed re-grant (unboxed, real Postgres) | `mix test test/parapet/automation/claim_service_test.exs --include unboxed` | 4 tests, 0 failures | ✓ PASS |
| Full library suite (regression) | `mix test --include unboxed` | 483 tests, 0 failures | ✓ PASS |
| Library compile (warnings-as-errors) | `mix compile --warnings-as-errors` | clean (no output) | ✓ PASS |
| Debt-marker scan on all 5 modified files | grep TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER | none | ✓ PASS |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER in any of the 5 phase-modified files | ℹ️ Info | Clean — completion is auditable. |
| `lib/parapet/operator.ex` | 751 | `"result" => inspect(exec_result)` into durable jsonb (IN-01) | ℹ️ Info | Inspect output not a stable serialization contract; Phase 26 normalizes timeline shape. |
| `lib/parapet/operator.ex` | 866 | `payload["preview_token"] == token` non-constant-time compare (IN-02) | ℹ️ Info | Timing side-channel on a 128-bit random token — impractical to exploit; defensive nicety. |

### Code-Review BLOCKER Re-Assessment (verdict after fixes)

| ID | Prior verdict | Fix verified | Now |
|----|---------------|--------------|-----|
| CR-01 | WARNING + product DECISION POINT (ack-then-confirm?) | `allowed_states` opt added; operator passes `["open","investigating"]`; Executor/Escalation default `["open"]` unchanged (claim_service.ex:190-206, operator.ex:730). Decision resolved YES. | ✓ FIXED — 2 passing tests (investigating-succeeds, resolved-short-circuits). |
| CR-02 | WARNING (5-min retry lockout) | `mark_failed/2` + `failed_retryable` re-grant + error-arm release (claim_service.ex:87-96,146-167; operator.ex:766). | ✓ FIXED — unboxed Postgres test proves same-row re-grant, no lockout. |
| CR-03 | WARNING (bare execute crashes boundary) | `try/rescue` → `{:error, {:capability_raised, msg}}` + claim release (operator.ex:735-740,766). | ✓ FIXED — passing structured-error test. |

### Warnings (do not block the phase goal; surfaced for closure decision)

The three former BLOCKER-warnings (WR-CR01/CR02/CR03) are now closed. The following secondary warnings from 25-REVIEW.md remain OPEN (none breaks a success criterion):

| ID | File | Issue | Recommended Disposition |
|----|------|-------|-------------------------|
| WR-WR01 | operator.ex:712-715; operator_detail_live.ex:164 | `target_refs_hash` drift gate is tautological in normal operation; copy "Target state changed since Preview" overstates protection. | Either recompute live preview at confirm or reword copy to "payload integrity." Not a criterion break. |
| WR-WR02 | operator.ex:796-800 | Lossy reason mapping: already_resolved/already_investigating/already_open/suppressed all → `:incident_resolved`. Less impactful now (investigating no longer reaches this map on the happy path), but already_open/suppressed still collapse misleadingly. | Extend frozen vocab or map truthfully. |
| WR-WR04 | operator.ex:747; workbench_contract.ex:125-129; operator_components.ex | Confirm writes `recovery_confirmed` but `derive_runbook_steps/3` only detects `mitigation_executed` → step never shows Executed, Confirm button never clears → double-confirm produces `{:conflicted, _}` (self-conflict). **CONFIRMED still open** (workbench_contract.ex:127 unchanged). | Add `recovery_confirmed` to executed-detection or hide Confirm after success. Not in this fix batch; not a criterion break (single Confirm works). |
| WR-WR05 | operator_detail_live.ex:149 | `:conflicted` copy assumes multi-node; misleading for single-node self-conflict (reachable via WR-04 double-confirm). | Reword (but criterion #2 pins this exact string for the cross-node case). Human UX call (see Human Verification #3). |
| WR-WR06 | operator_detail_live.ex; operator.ex | Per-click random `idempotency_key`; `action_type: :execute_mitigation` vs `tool_name: "operator_confirm_recovery"` taxonomy mismatch. | Derive key from preview_token; reconcile taxonomy. Audit taxonomy is Phase 26 scope. |
| WR-IN03 | (resolved) | Was: no unit coverage for investigating/execute-error/execute-raise. | ✓ CLOSED — preview_lifecycle_test.exs now covers all three (+ resolved). |

### Deferred Items (Step 9b — addressed in later milestone phases)

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Execute-error timeline/audit emission (`:recovery_failed`) | Phase 26 | ROADMAP Phase 26 success criterion #3: a capability whose `execute/2` returns `{:error, reason}` produces a `TimelineEntry` with `type: :recovery_failed`. (The claim-RELEASE half — CR-02 — is fixed here in Phase 25; only the timeline/audit emission is deferred.) |
| 2 | Audit/timeline shape normalization + idempotency-key/action-type reconciliation (WR-WR06, IN-01) | Phase 26 | ROADMAP Phase 26 goal: TimelineEntry/ToolAudit writes for every Confirm. |
| 3 | CI demo lane exercising the four scenarios (happy/expired/short-circuit/conflict) | Phase 28 | ROADMAP Phase 28 goal: CI exercises four scenarios so the loop is contract-tested. |

### Human Verification Required

See the 4 items in the frontmatter `human_verification` block. All four are now pure **LiveView visual/real-time render confirmations** (preview panel layout, success-flash appearance, conflict-flash copy, expired-flash + re-Preview affordance). The previously load-bearing item — the CR-01 ack-then-confirm product DECISION — is **RESOLVED (YES)** and the code is fixed; item #2 is downgraded from a decision point to a visual confirmation that the operator now sees the SUCCESS flash after Acknowledge. None of the remaining items can be exercised by the library `mix test` path because the demo app is a separate Mix project (RESEARCH Pitfall 3).

### Gaps Summary

**No BLOCKER gaps.** All four ROADMAP success criteria are achieved at the code/contract level, all four requirement IDs (UI-01..UI-04) are satisfied, and the three code-review BLOCKERs (CR-01/CR-02/CR-03) are now FIXED with code citations and new passing regression tests:

- **CR-01** — `ClaimService.incident_state_gate/2` is now allow-list driven (default `["open"]`, unchanged for Executor/Escalation); `confirm_runbook_step/4` passes `["open","investigating"]` so Acknowledge-then-Confirm succeeds. Proven by `preview_lifecycle_test.exs` investigating-succeeds + resolved-short-circuits tests.
- **CR-02** — `ClaimService.mark_failed/2` (status `failed_retryable` + `last_error_*`) plus `steal_expired_claim` re-granting `failed_retryable` rows; the operator error arm releases the claim. Proven by the unboxed Postgres `mark_failed`-then-retry test (same-row re-grant, no lockout).
- **CR-03** — `capability.execute` is wrapped in `try/rescue` → `{:error, {:capability_raised, msg}}` with claim release. Proven by the structured-error test.

Full library suite re-run green at **483 tests, 0 failures**; `mix compile --warnings-as-errors` clean; no debt markers in any of the 5 modified files.

Status remains **`human_needed`** (not `passed`) solely because the demo LiveView visual flows for criteria #1/#2/#3 require human render confirmation. This is a clean human-UAT gate, **not** a code gap: the open secondary warnings (WR-WR01/02/04/05/06) are non-criterion UX/robustness polish items, and WR-04 (Confirm button not clearing → double-confirm self-conflict) was explicitly out of scope for this fix batch and remains an open follow-up, not a regression introduced here.

---

_Verified: 2026-05-28T07:25:00Z (re-verification after gap closure)_
_Verifier: Claude (gsd-verifier)_
