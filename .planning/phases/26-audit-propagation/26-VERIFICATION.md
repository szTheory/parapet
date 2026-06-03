---
phase: 26-audit-propagation
verified: 2026-05-28T10:51:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 26: Audit Propagation Verification Report

**Phase Goal:** Every successful recovery action writes a TimelineEntry (type: :recovery_confirmed) AND a ToolAudit row capturing operator identity, action name, args, outcome, and timestamps. Add the :recovery_failed TimelineEntry type emitted on capability execution error — distinct from short-circuit/conflict states which write no entry because nothing executed.
**Verified:** 2026-05-28T10:51:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth                                                                                                                                                                         | Status     | Evidence                                                                                                                                                          |
|----|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1  | Querying TimelineEntry after a successful Confirm returns a row with type "recovery_confirmed" carrying actor, capability, target_refs, and an outcome map                     | ✓ VERIFIED | `operator.ex:746-755` — `timeline_attrs` payload contains `"actor"`, `"capability"`, `"target_refs"`, `"outcome"` map; `operator_test.exs:594-600` asserts all fields |
| 2  | Querying ToolAudit after the same Confirm returns a row with output set, action_name + target_refs in input, success: true, and the operator actor                             | ✓ VERIFIED | `operator.ex:757-765` — `audit_attrs` pipeline adds `output`, `action_name`, `target_refs`; `operator_test.exs:602-608` asserts all six AUD-02 fields              |
| 3  | A capability returning {:error, reason} (or raising) produces a TimelineEntry type "recovery_failed" + ToolAudit success:false; short-circuit/conflict arms write nothing      | ✓ VERIFIED | `operator.ex:773-817` — failure arm writes `recovery_failed` inside `try/rescue` before `mark_failed`; `preview_lifecycle_test.exs:368-380, 437-453` assert write; `preview_lifecycle_test.exs:225-231` negative assert for short-circuit |
| 4  | Short-circuit (preview_expired, target_refs_drift, incident_resolved) and conflict outcomes write NO TimelineEntry and NO ToolAudit                                            | ✓ VERIFIED | `operator.ex:708-718` — `cond` short-circuit arms return before `case exec_outcome`; `preview_lifecycle_test.exs:225-231` asserts captured_writes has no recovery entry after short-circuit |
| 5  | The retrospective generator renders recovery_confirmed and recovery_failed entries with human-readable copy inline in the chronology, not as raw inspect(payload) output       | ✓ VERIFIED | `retrospective.ex:146-156` — two `format_payload/1` clauses before `inspect/1` fallback; `retrospective_test.exs:94-110` asserts human-readable copy, `refute markdown =~ "%{"`, chronological order |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact                                              | Expected                                                                   | Status     | Details                                                                                                                                            |
|-------------------------------------------------------|----------------------------------------------------------------------------|------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `lib/parapet/operator.ex`                             | Enriched recovery_confirmed + new recovery_failed write in confirm_runbook_step/4 | ✓ VERIFIED | Lines 742-818: success arm enriches `timeline_attrs`/`audit_attrs`; failure arm builds `failure_timeline_attrs`/`failure_audit_attrs`, calls `Evidence.run_operator_command` inside `try/rescue` before `ClaimService.mark_failed` |
| `lib/parapet/evidence/retrospective.ex`               | Two format_payload/1 clauses for recovery_confirmed and recovery_failed    | ✓ VERIFIED | Lines 146-156: success clause uses `Enum.join` for target_refs; failure clause uses `Map.get(outcome, "reason", "unknown reason")` fallback; both precede the `inspect/1` catch-all |
| `test/parapet/operator_test.exs`                      | AUD-01/AUD-02 enriched-write assertions on the success Confirm test        | ✓ VERIFIED | Lines 596-608: asserts `payload["actor"]`, `payload["capability"]`, `is_list(payload["target_refs"])`, `payload["outcome"]["status"]`, `tool_audit.success`, `tool_audit.input["action_name"]`, etc. |
| `test/parapet/operator/preview_lifecycle_test.exs`    | AUD-03 failure writes + short-circuit negative assertions                  | ✓ VERIFIED | Lines 368-379 (CR-02), 437-453 (CR-03 raised), 225-231 (preview_expired negative), 382-412 (CR-01 regression — raise guarded) |
| `test/parapet/evidence/retrospective_test.exs`        | recovery_confirmed + recovery_failed rendering assertions                  | ✓ VERIFIED | Lines 54-111: asserts `"confirmed by"`, `"Recovery failed:"`, `refute "%{"`, list syntax guard, chronological ordering; lines 113-142: WR-02 tolerance test for missing reason key |

---

### Key Link Verification

| From                                                             | To                                  | Via                                             | Status     | Details                                                                                                      |
|------------------------------------------------------------------|-------------------------------------|-------------------------------------------------|------------|--------------------------------------------------------------------------------------------------------------|
| `operator.ex confirm_runbook_step/4 {:ok}` arm                   | `Parapet.Evidence.run_operator_command/1` | enriched `timeline_attrs` + `audit_attrs` maps  | ✓ WIRED    | `operator.ex:767-771` — direct call, return is the function's success return                                 |
| `operator.ex confirm_runbook_step/4 {:error, reason}` arm        | `Parapet.Evidence.run_operator_command/1` | `failure_timeline_attrs` + `failure_audit_attrs`, `try/rescue` wrapped | ✓ WIRED    | `operator.ex:803-812` — `_ = try do Evidence.run_operator_command(...) rescue _ -> :ok end`                  |
| `retrospective.ex format_payload/1`                              | recovery_confirmed / recovery_failed timeline payloads | pattern-matched clauses before inspect/1 fallback | ✓ WIRED | `retrospective.ex:146-156` — two clauses present; confirmed via grep: `grep -c 'Recovery failed:' retrospective.ex` = 1 |

---

### Data-Flow Trace (Level 4)

| Artifact             | Data Variable           | Source                          | Produces Real Data | Status     |
|----------------------|-------------------------|---------------------------------|--------------------|------------|
| `operator.ex`        | `exec_result` / `reason` | `capability.execute.(incident, preview_entry.target_refs)` at line 737 | Yes — adopter-supplied capability closure; normalized via `inspect/1` | ✓ FLOWING |
| `retrospective.ex`   | `entries` (TimelineEntry list) | Caller supplies list to `generate_markdown/2` | Yes — rendered from actual entries passed in | ✓ FLOWING |

---

### Behavioral Spot-Checks

| Behavior                                     | Command                                                                                 | Result               | Status  |
|----------------------------------------------|-----------------------------------------------------------------------------------------|----------------------|---------|
| Targeted test suite (AUD-01/02/03 + retro)   | `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs test/parapet/evidence/retrospective_test.exs` | 26 tests, 0 failures | ✓ PASS  |
| Full suite                                    | `mix test`                                                                              | 487 tests, 0 failures | ✓ PASS  |
| Compile with warnings-as-errors              | `mix compile --warnings-as-errors`                                                      | No output (clean)     | ✓ PASS  |

---

### Probe Execution

No probes declared for this phase. Step 7c: SKIPPED (no probe-*.sh files found for phase 26).

---

### Requirements Coverage

| Requirement | Source Plan | Description                                                                                                      | Status      | Evidence                                                                                                          |
|-------------|-------------|------------------------------------------------------------------------------------------------------------------|-------------|-------------------------------------------------------------------------------------------------------------------|
| AUD-01      | Plan 01     | Successful recovery emits `TimelineEntry` (`type: recovery_confirmed`) with operator identity, action name, args, outcome, timestamps | ✓ SATISFIED | `operator.ex:746-755`; assertions in `operator_test.exs:596-600`                                                  |
| AUD-02      | Plan 01     | Same Confirm emits `ToolAudit` row with operator identity, action name, args, outcome, timestamps                | ✓ SATISFIED | `operator.ex:757-765`; assertions in `operator_test.exs:602-608`                                                  |
| AUD-03      | Plan 01     | `:recovery_failed` TimelineEntry type emitted on capability execution error; short-circuit/conflict emit nothing | ✓ SATISFIED | `operator.ex:773-817`; `preview_lifecycle_test.exs:368-380` (CR-02), `437-453` (CR-03), `225-231` (negative)     |

All three requirements (AUD-01, AUD-02, AUD-03) are covered. The fourth roadmap success criterion (retrospective inline rendering) is also satisfied via `retrospective.ex:146-156` and `retrospective_test.exs:54-111`.

---

### Code Review Findings — Fix Verification

The code review (26-REVIEW.md, status: resolved) identified CR-01 (blocker) and WR-01/WR-02/WR-03 (warnings). All were fixed in commits 874fc76 and 9b0cee1.

| Finding | Description | Fix Present | Location |
|---------|-------------|-------------|----------|
| CR-01 (blocker) | Failure-path audit write could raise and strand the claim in "won" state | ✓ FIXED | `operator.ex:803-812` — `try do ... rescue _ -> :ok end` wraps `Evidence.run_operator_command`; `ClaimService.mark_failed` is always reached |
| WR-01 | target_refs rendered as raw Elixir list syntax via `inspect/1` | ✓ FIXED | `retrospective.ex:147-150` — `Enum.join(refs, ", ")` with empty-list guard (`"no targets"`) |
| WR-02 | recovery_failed clause fell through to `inspect/1` when `"reason"` key absent | ✓ FIXED | `retrospective.ex:153-155` — matches `%{"status" => "failed"} = outcome` and uses `Map.get(outcome, "reason", "unknown reason")`; `retrospective_test.exs:113-142` asserts this path |
| WR-03 | failure_audit_attrs built as hand-rolled map literal, divergence risk | ✓ FIXED (differently) | `operator.ex:788-797` — uses `build_audit("operator_confirm_recovery", payload)` as base, then `Map.put(:success, false)`, `Map.put(:output, ...)`, and `Map.update!(:input, ...)` pipeline — same base derivation, acceptable deviation from suggested 3-arity helper |
| IN-01 | DummyRepo capture guard only fires when `:timeline_entry` present | advisory, left as-is | WR-03 fix closed the practical risk; IN-01 is an informational note about test fragility, not a correctness bug |

CR-01 regression test is present at `preview_lifecycle_test.exs:382-412` — sets `Process.put(:raise_on_transaction_multi, true)` and asserts `{:error, :provider_unavailable}` is still returned.

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| None | — | — | No TBD/FIXME/XXX markers found in modified files; no unreachable clauses; no stub implementations |

`grep -v '^#' lib/parapet/operator.ex | grep -c 'recovery_failed'` = 1 (the type literal, not a comment).

No `mix.exs`/`mix.lock` changes. No new migration files. No new test files created (5 existing files modified, 0 new).

---

### Human Verification Required

None. All observable truths are verifiable from code + test execution. No visual UI behavior, real-time events, or external service integrations are in scope for this phase.

---

### Gaps Summary

No gaps. All 5 must-have truths verified, all 3 requirement IDs satisfied, all code review fixes confirmed present, and the full test suite (487 tests) is green.

---

_Verified: 2026-05-28T10:51:00Z_
_Verifier: Claude (gsd-verifier)_
