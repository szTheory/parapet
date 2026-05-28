---
phase: 25-wire-confirm-through-claimservice-preview-confirm-ux
verified: 2026-05-28T02:42:47Z
status: human_needed
score: 4/4 must-haves verified (criterion-level); 4/4 requirement IDs satisfied
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. A 25-REVIEW.md (3 BLOCKER / 6 WARNING / 3 INFO) was completed by the code-reviewer immediately prior; this verification independently re-checked the 3 BLOCKERs against the code and the 4 ROADMAP success criteria."
human_verification:
  - test: "Open-incident happy path in the demo app: open an OPEN incident, click Preview on a capability-backed runbook step, then click Confirm Recovery WITHOUT acknowledging first."
    expected: "Preview panel shows Action name + Target Kind + Affected Count; Confirm flashes \"Mitigation confirmed and executed\" and the capability executes. (Code + unit/concurrency tests prove this returns {:ok, recovery_confirmed} on an open incident; visual render needs human eyes.)"
    why_human: "LiveView visual rendering (preview panel layout, flash appearance, blast-radius/diff fields) cannot be verified programmatically; demo app is not in the library mix test path (RESEARCH Pitfall 3)."
  - test: "Acknowledge-then-Confirm path: on an incident, click Acknowledge Incident (moves state to investigating), then Preview, then Confirm."
    expected: "DECISION POINT. With the current code, ClaimService.incident_state_gate/1 only passes state==\"open\"; after Acknowledge the incident is \"investigating\", so Confirm returns {:short_circuited, :incident_resolved} and the flash reads \"Incident already resolved — no action needed\" (mislabeled). Confirm directly whether your intended operator workflow permits Acknowledge-before-Confirm. If yes, this is a happy-path break (see WARNING WR-CR01) and the gate/mapping must be fixed before shipping. If operators Confirm directly on open incidents, this is a latent UX wart, not a blocker."
    why_human: "The 'intended operator workflow' (whether Acknowledge precedes Confirm) is a product/design decision not encoded anywhere in the codebase or planning docs. The code does NOT force Acknowledge before Confirm (buttons gate on step.state + active_preview, not incident state), so the criterion is not mechanically broken — but the answer determines whether WR-CR01 is a blocker."
  - test: "Conflict-flash copy on single-node self-conflict: trigger a {:conflicted, _} (e.g., double-click Confirm after a successful confirm, since WR-04 means the button never clears) on a single node."
    expected: "Flash currently reads \"Another node is executing this recovery — refresh to see the outcome\" (verbatim ROADMAP criterion #2). On a single-node self-conflict this copy is misleading (WR-WR05). Verify the copy is acceptable or schedule the WR-WR05 rewording."
    why_human: "Whether the multi-node-worded copy is acceptable for single-node self-conflict is a UX judgment call; the verbatim string is contractually pinned by ROADMAP criterion #2."
  - test: "Preview-expired + re-Preview affordance: generate a Preview, wait past 5 minutes (or expire the stored expires_at), click Confirm."
    expected: "Flash reads \"Preview expired — please re-Preview before confirming\" and the Preview button on the runbook card reappears (the active preview clears via the load_detail re-derive). Confirm there is a usable re-Preview path. NOTE: CONTEXT D-11 mentioned a dedicated 'Re-Preview button'; the implementation instead reuses the existing Preview button (RESEARCH A7) — verify this affordance is discoverable."
    why_human: "Time-based expiry behavior and the reappearing-button affordance are real-time/visual; not exercisable by static checks."
---

# Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX — Verification Report

**Phase Goal:** Close the operator-path-skips-claim defect by routing `Parapet.Operator.confirm_runbook_step/4` through `Parapet.Automation.ClaimService.claim_action/1` (same path the Oban auto-execution uses), add the `{:short_circuited, reason}` and `{:conflicted, claim_id}` additive return variants, and render both branches in the LiveView with operator-actionable next steps. Preview tokens get a 5-minute expiry with `target_refs` hash gating.
**Verified:** 2026-05-28T02:42:47Z
**Status:** human_needed
**Re-verification:** No — initial verification (post code-review)

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Preview renders action name + target args + blast-radius + diff before execution; Confirm without fresh Preview rejected with "re-Preview required" | ✓ VERIFIED (code) / ? render needs human | `preview_panel/1` (operator_components.ex:343-407) renders Action cell (line 357-358, sourced from `get_recovery(...).name`), Target Kind (363), Affected Count (367), warnings (371-380). Confirm-without-fresh-Preview is gated by `@detail.derived.active_preview` (operator_detail_live.ex:256) + `find_recent_preview/3` `{:error, :mismatched_preview}` (operator.ex:877). Happy-path Confirm on open incident → `{:ok, recovery_confirmed}` proven by operator_test.exs:593-594 + preview_lifecycle_test.exs:262. Visual layout/diff fields need human render check. |
| 2 | Second operator's Confirm during in-flight claim sees verbatim "Another node is executing this recovery — refresh to see the outcome" (`:conflicted` branch, operator-actionable) | ✓ VERIFIED | `{:conflicted, _claim_id}` arm (operator_detail_live.ex:146-150) emits the verbatim string (grep count = 1). At the API level the conflict path is PROVEN by confirm_concurrency_test.exs (ran 3x, deterministic): exactly one `{:ok,_}` + one `{:conflicted, claim_id}`, claim_id resolves to a real `parapet_action_claims` row. |
| 3 | Confirm on Preview older than 5 min, or against a resolved-since-Preview incident, returns `{:short_circuited, reason}`; LiveView renders reason ("Preview expired"/"Incident already resolved") with Re-Preview | ✓ VERIFIED | `cond` gate (operator.ex:709-710) → `{:short_circuited, :preview_expired}` proven by operator_test.exs:603-604 + preview_lifecycle_test.exs:201-202. Incident-state short-circuit via ClaimService gate → `map_short_circuit_reason("already_resolved") -> :incident_resolved` (operator.ex:780). `short_circuit_flash/1` (operator_detail_live.ex:161-164) renders all 4 reasons; verbatim strings present (grep each = 1). Re-Preview = reappearing Preview button (RESEARCH A7). 5-min expiry at compute_preview/3 (operator.ex:788). |
| 4 | Every successful Confirm flows through `ActionPayload` + `ClaimService.claim_action/1` with `action_kind: "operator"` — observable in a multi-node concurrency test | ✓ VERIFIED | `confirm_runbook_step/4` dispatches `ClaimService.claim_action(action_kind: "operator", ...)` (operator.ex:721-727; grep `action_kind: "operator"` = 1). `{:won, claim}` → `capability.execute` → `ClaimService.mark_executed` (operator.ex:728-731). Concurrency test asserts the winner's claim row has `action_kind == "operator"`, `action_key == "op_step"`, `status == "executed"` (confirm_concurrency_test.exs:174-178). |

**Score:** 4/4 success criteria met at the code/contract level. Criteria #1, #2, #3 require human render confirmation of the demo LiveView (see Human Verification).

### Requirements Coverage

All four requirement IDs from PLAN frontmatter cross-referenced against `.planning/REQUIREMENTS.md` (all map to Phase 25; none orphaned).

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| UI-01 | 25-02 | Preview shows action name, target args, blast-radius, expected diff in a dedicated panel | ✓ SATISFIED | `preview_panel/1` Action cell + Target Kind + Affected Count + Warnings (operator_components.ex:355-380); action name via `get_recovery/1` (operator_detail_live.ex:186-200). |
| UI-02 | 25-01, 25-03 | Confirm routes through `ActionPayload` + `ClaimService.claim_action/1` (closes operator-path-skips-claim defect) | ✓ SATISFIED | operator.ex:721-727 dispatch; concurrency test proves the claim-protected path with `action_kind: "operator"`. |
| UI-03 | 25-01, 25-03 | 5-min preview expiry; stale detected via `target_refs` hash; expired prompts re-Preview | ✓ SATISFIED | `compute_preview/3` 300s expiry + `target_refs_hash` (operator.ex:788, 822); drift gate (operator.ex:712-715); `preview_lifecycle_test.exs` covers `:preview_expired`, `:target_refs_drift`, nil-hash legacy compat, Pitfall-5 canonicalization. |
| UI-04 | 25-01, 25-02, 25-03 | Confirm returns `{:short_circuited, reason}` / `{:conflicted, claim_id}`; LiveView renders both branches with actionable next steps | ✓ SATISFIED | New return variants (operator.ex:710,715,755,758); 4-arm LiveView handler (operator_detail_live.ex:133-154); `short_circuit_flash/1` closed mapper; concurrency test proves the conflict path. |

No ORPHANED requirements: REQUIREMENTS.md maps exactly UI-01..UI-04 to Phase 25, and all four are claimed across the three plans.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/parapet/operator.ex` | 4-arm `claim_action/1` dispatch + `map_short_circuit_reason/1` + `target_refs_hash/1` + hash write/surface | ✓ VERIFIED | All present (operator.ex:708-785, 822, 873). `:stale_preview` fully removed (grep=0). `alias ClaimService` (line 17). Compiles clean. |
| `examples/demo_app/.../operator_detail_live.ex` | 4-arm `confirm_mitigation` handler + closed `short_circuit_flash/1` | ✓ VERIFIED | 4 arms (lines 133-154); verbatim conflict flash (grep=1); 4 closed flash clauses (grep=1 each); `load_detail/1` augmentation. Demo app compiles (only 3 pre-existing unrelated warnings). |
| `examples/demo_app/.../operator_components.ex` | `preview_panel/1` with Action cell | ✓ VERIFIED | Action cell at lines 356-359, value `Map.get(preview, :action_name) \|\| preview.data["capability"]`. |
| `test/parapet/operator/confirm_concurrency_test.exs` | Multi-node race proof | ✓ VERIFIED | 197 lines; substantive assertions; passes 3x deterministically. |
| `test/parapet/operator/preview_lifecycle_test.exs` | `:preview_expired` + `:target_refs_drift` + legacy + canonicalization | ✓ VERIFIED | 308 lines; 4 tests, 0 failures. |
| `test/parapet/operator_test.exs` | `:stale_preview` → `:preview_expired` + DummyRepo for raw-fun txn | ✓ VERIFIED | 14 tests, 0 failures; assertion updated (line 603). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `confirm_runbook_step/4` `{:won, claim}` arm | `ClaimService.mark_executed/1` | called after `capability.execute` returns `{:ok,_}` | ✓ WIRED | operator.ex:731 inside the `{:ok, exec_result}` branch. |
| `map_short_circuit_reason/1` | `recovery_action.ex @short_circuit_reasons` frozen vocab | string→frozen atom (closed clauses) | ✓ WIRED (lossy — see WR-WR02) | Maps to `:incident_resolved`/`:breaker_open` (frozen atoms confirmed at recovery_action.ex:46-51). Lossy collapse of investigating/open→incident_resolved is a WARNING, not a break. |
| `compute_preview/3` | `find_recent_preview/3` | `target_refs_hash` written at compute, read at confirm | ✓ WIRED | Hash written post-merge (operator.ex:822); surfaced nullable (operator.ex:873). |
| LiveView `confirm_mitigation` | `Parapet.Operator.confirm_runbook_step/4` | case on 4 return variants | ✓ WIRED | operator_detail_live.ex:133-154. |
| `preview_panel/1` Action cell | `Parapet.Capabilities.get_recovery(capability_id).name` | server-side resolution via `load_detail/1` | ✓ WIRED | operator_detail_live.ex:186-200; degraded fallback to capability_id string. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `confirm_concurrency_test` claim assertions | `claim.action_kind/status` | real `parapet_action_claims` row via `ConcurrencyRepo` | Yes (live Postgres) | ✓ FLOWING |
| `preview_panel/1` Action cell | `preview.action_name` | `get_recovery/1` from Capabilities Agent (real registry) | Yes (with capability_id fallback) | ✓ FLOWING |
| `confirm_runbook_step/4` execute | `preview_entry.target_refs` | stored TimelineEntry payload via `find_recent_preview/3` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Operator unit suite | `mix test test/parapet/operator_test.exs` | 14 tests, 0 failures | ✓ PASS |
| Preview lifecycle (`:preview_expired`/`:target_refs_drift`/legacy/canon) | `mix test test/parapet/operator/preview_lifecycle_test.exs` | 4 tests, 0 failures | ✓ PASS |
| Multi-node concurrency (criterion #4) | `mix test test/parapet/operator/confirm_concurrency_test.exs --include unboxed` | 1 test, 0 failures; query log shows `action_kind='operator'`, `action_key='op_step'` | ✓ PASS |
| Concurrency determinism | seeds 1,2,3 | 3/3 pass | ✓ PASS |
| Full library suite (regression) | `mix test` | 478 tests, 0 failures | ✓ PASS |
| Library compile | `mix compile` | clean | ✓ PASS |
| Demo app compile (UI-01/UI-04 surface) | `cd examples/demo_app && mix compile` | success; only 3 pre-existing warnings (Escalation.Worker, LiveReloader) — none in edited files | ✓ PASS |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | No TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER in any phase-modified file | ℹ️ Info | Clean — completion is auditable. |
| `lib/parapet/operator.ex` | 738 | `"result" => inspect(exec_result)` into durable jsonb (IN-01) | ℹ️ Info | Inspect output not a stable serialization contract; Phase 26 normalizes timeline shape. |
| `lib/parapet/operator.ex` | 850 | `payload["preview_token"] == token` non-constant-time compare (IN-02) | ℹ️ Info | Timing side-channel on a 128-bit random token — impractical to exploit; defensive nicety. |

### Code-Review BLOCKER Re-Assessment (independent verdict)

The orchestrator flagged 3 BLOCKERs from 25-REVIEW.md. I re-checked each against the code and the 4 success criteria:

- **CR-01 (incident_state_gate only passes "open"; Acknowledge→investigating mislabels Confirm as `:incident_resolved`)** — CONFIRMED at code level (claim_service.ex:162-163 + operator.ex:780-784). **VERDICT: NOT a success-criterion break.** The actual UI flow does NOT force Acknowledge before Confirm: the runbook-step Preview/Execute buttons gate on `step.state` (operator_components.ex:317-332) and the Confirm button gates on `active_preview` (operator_detail_live.ex:256) — neither gates on incident state. Acknowledge is an independent `action_rail` button shown only when `state=="open"` (operator_components.ex:413-421). The happy path (open incident → Preview → Confirm) is reachable and PROVEN to return `{:ok, recovery_confirmed}` (operator_test.exs:593, preview_lifecycle_test.exs:262, confirm_concurrency_test.exs winner). Criterion #4 ("multi-node concurrency test") passes. Per the orchestrator's own decision rule, "if Confirm is reachable directly on an open incident and Acknowledge is independent, this is a latent bug but not a success-criterion break" — that condition holds. Downgraded to **WARNING WR-CR01** with a human DECISION POINT (does the intended workflow allow Acknowledge-first?). If the product answer is "operators are expected to Acknowledge before Confirm," this escalates to a blocker for shipping and must be fixed (gate to allow `["open","investigating"]` + truthful reason mapping).
- **CR-02 (won claim never released on `capability.execute` {:error,_}; 5-min retry lockout)** — CONFIRMED. operator.ex:750-751 returns `{:error, reason}` with no claim release; `ClaimService` has only `mark_executed` (no `mark_failed`/release; grep confirmed). **VERDICT: NOT a success-criterion break** (all 4 criteria concern success/short-circuit/conflict paths, not execute-error recovery), but a real recoverability defect. Downgraded to **WARNING WR-CR02**. The audit/timeline side of execute-error is Phase 26 scope (AUD-03 `:recovery_failed`, ROADMAP Phase 26 criterion #3), but the claim-release fix is Phase 25's own concern.
- **CR-03 (adopter `capability.execute` invoked with no `rescue`; host exception crashes the operator/LiveView boundary)** — CONFIRMED. The `rescue` blocks at operator.ex:884/892/904 are in `extract_module`/`parse_step_id`, NOT around `capability.execute.(...)` at line 729. **VERDICT: NOT a success-criterion break** but a real robustness defect at the documented "Phoenix-free public boundary." Downgraded to **WARNING WR-CR03**.

### Warnings (do not block the phase goal; surfaced for closure decision)

| ID | File | Issue | Recommended Disposition |
|----|------|-------|-------------------------|
| WR-CR01 | claim_service.ex:162; operator.ex:780-784 | incident_state_gate passes only "open"; "already_investigating" mislabeled `:incident_resolved`. Latent UX bug; becomes a blocker ONLY if intended workflow forces Acknowledge-before-Confirm. | Human decision (see Human Verification #2). If Acknowledge-first is intended, fix gate to allow `["open","investigating"]` and add a truthful reason atom. |
| WR-CR02 | operator.ex:750-751 | Won claim not released on execute `{:error,_}` → 5-min retry lockout. | Add `ClaimService.mark_failed/2` + release on error branch. Coordinate with Phase 26 (recovery_failed). |
| WR-CR03 | operator.ex:729 | Bare `capability.execute` — host exception crashes boundary. | Wrap in `try/rescue`, convert to structured `{:error, {:capability_raised, msg}}` + claim release. |
| WR-WR01 | operator.ex:712-715; operator_detail_live.ex:164 | `target_refs_hash` drift gate is tautological in normal operation (both inputs derive from same stored payload); copy "Target state changed since Preview" overstates protection. | Either recompute live preview at confirm (real drift detection) or reword copy to "payload integrity." Does not break criterion #3. |
| WR-WR02 | operator.ex:780-784 | Lossy reason mapping: investigating/open/suppressed all → `:incident_resolved`. | Extend frozen vocab or map truthfully. Tied to WR-CR01. |
| WR-WR04 | operator.ex:734; workbench_contract.ex:125-134; operator_components.ex:287 | Confirm writes `recovery_confirmed` but `derive_runbook_steps/3` only detects `mitigation_executed` → step never shows Executed, Confirm button never clears → double-confirm risk (collides on claim → misleading `:conflicted`). CONFIRMED in code. | Add `recovery_confirmed` to executed-detection in WorkbenchContract, or hide Confirm after success. Does not break a success criterion (single successful Confirm works), but a real footgun. |
| WR-WR05 | operator_detail_live.ex:149 | `:conflicted` copy assumes multi-node; misleading for single-node self-conflict. | Reword to outcome-agnostic copy (but criterion #2 pins this exact string for the cross-node case). Human UX call. |
| WR-WR06 | operator_detail_live.ex:129-130; operator.ex:742 | Per-click random `idempotency_key` provides no real cross-retry idempotency; `action_type: :execute_mitigation` vs `tool_name: "operator_confirm_recovery"` taxonomy mismatch. | Derive idempotency_key from preview_token; reconcile action_type/tool_name. Audit taxonomy is Phase 26 scope. |
| WR-IN03 | operator_test.exs; preview_lifecycle_test.exs | All unit tests pin `state: "open"` and DummyRepo always-wins; no coverage for investigating-state confirm, execute-`{:error,_}`, or execute-raises. | Add the 3 unit cases (recommended before Phase 26 builds on this path). |

### Deferred Items (Step 9b — addressed in later milestone phases)

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Execute-error timeline/audit emission (`:recovery_failed`) | Phase 26 | ROADMAP Phase 26 goal + success criterion #3: "A capability whose `execute/2` returns `{:error, reason}` produces a `TimelineEntry` with `type: :recovery_failed`." (Note: the claim-RELEASE half of WR-CR02 is NOT deferred — it is a Phase-25 recoverability concern.) |
| 2 | Audit/timeline shape normalization + idempotency-key/action-type reconciliation (WR-WR06, IN-01) | Phase 26 | ROADMAP Phase 26 goal: "TimelineEntry/ToolAudit writes for every Confirm." |
| 3 | CI demo lane exercising the four scenarios (happy/expired/short-circuit/conflict) | Phase 28 | ROADMAP Phase 28 goal: "CI exercises four scenarios ... so the loop is contract-tested." |

### Human Verification Required

See the 4 items in the frontmatter `human_verification` block. The load-bearing one is item #2 (Acknowledge-then-Confirm) — a product DECISION POINT that determines whether WR-CR01 stays a warning or escalates to a blocker. The other three are visual/real-time LiveView checks not exercisable by the library `mix test` path (demo app is a separate Mix project, RESEARCH Pitfall 3).

### Gaps Summary

**No BLOCKER gaps.** All four ROADMAP success criteria are achieved in the codebase at the code/contract level, all four requirement IDs (UI-01..UI-04) are satisfied, the full library suite is green (478/0), and the multi-node concurrency proof for criterion #4 is deterministic across 3 seeds. The phase goal — routing Confirm through `ClaimService.claim_action/1` with `action_kind: "operator"`, adding the two additive return variants, rendering both branches in the LiveView, and 5-min preview expiry with `target_refs` hash gating — is delivered and wired.

The 3 code-review BLOCKERs are real defects but **none breaks a Phase 25 success criterion**: CR-01 does not break the happy path because the UI does not force Acknowledge before Confirm (open-incident Confirm is reachable and proven); CR-02/CR-03 concern the execute-ERROR path, which is not part of any of the four criteria (and whose audit half is Phase 26 scope). They are reclassified as WARNINGS requiring a closure decision. The single item that needs a human/product answer before final sign-off is whether the intended operator workflow permits Acknowledge-before-Confirm (WR-CR01 / Human Verification #2) — if it does, that warning escalates to a blocker and the incident-state gate must be widened. Status is `human_needed` (not `passed`) because the demo LiveView visual flows for criteria #1/#2/#3 require human render confirmation and the WR-CR01 workflow question requires a product decision.

---

_Verified: 2026-05-28T02:42:47Z_
_Verifier: Claude (gsd-verifier)_
