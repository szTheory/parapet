---
phase: 04
reviewed: 2026-05-19T08:54:32Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/parapet/operator.ex
  - lib/parapet/escalation/worker.ex
  - lib/parapet/operator/workbench_contract.ex
  - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
  - priv/templates/parapet.gen.ui/operator_components.ex.eex
  - docs/operator-ui.md
  - test/parapet/operator_test.exs
  - test/parapet/escalation/worker_test.exs
  - test/parapet/operator/workbench_contract_test.exs
  - test/parapet/operator_ui_integration_test.exs
  - test/parapet/operator_ui_compile_out_test.exs
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---
# Phase 4: Code Review Report

**Reviewed:** 2026-05-19T08:54:32Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Scoped tests currently pass (`mix test test/parapet/operator_test.exs test/parapet/escalation/worker_test.exs test/parapet/operator/workbench_contract_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs`), but the Phase 4 implementation still has four correctness issues. The largest one is in the durable escalation state: a manual trigger is recorded but never consumed, so later worker runs keep treating the incident as manually triggered.

## Warnings

### WR-01: Manual trigger state is never consumed, so later worker runs keep reporting manual mode

**File:** `lib/parapet/operator.ex:270-280`, `lib/parapet/escalation/worker.ex:70-99`, `lib/parapet/evidence.ex:73-77`

**Issue:** `trigger_next_escalation/2` persists `runbook_data["escalation"]["pending_trigger"] = true`, `triggered_by`, and `trigger_reason`, but the worker only appends timeline evidence. It never clears or marks that request as consumed. After the first manual execution, every later worker run for the same still-open incident will continue to emit `"mode" => "manual"` and reuse the stale actor/reason, because `escalation_mode/1` keys solely off `pending_trigger`. The current tests only assert the first manual run and miss the stale-state regression.

**Fix:**
```elixir
# Consume the pending manual trigger inside the same write path that records
# escalation execution / short-circuit evidence.
updated_escalation =
  escalation_state
  |> Map.delete("pending_trigger")
  |> Map.delete("triggered_by")
  |> Map.delete("trigger_reason")
  |> Map.delete("trigger_requested_at")

# persist the incident update transactionally before/with timeline append
```

Add a regression test that runs the worker twice for the same incident and asserts the second run is no longer tagged as manual.

### WR-02: Escalation commands are accepted and rendered for non-open incidents

**File:** `lib/parapet/operator.ex:268-354`, `priv/templates/parapet.gen.ui/operator_components.ex.eex:359-367`

**Issue:** `trigger_next_escalation/2` and `suppress_pending_escalation/3` have no incident-state guard, and the generated action rail renders both controls for every incident state. That allows operators to write `escalation_trigger_requested` / `escalation_suppressed` evidence against `investigating` or `resolved` incidents, even though the worker will later short-circuit those incidents. This leaves contradictory chronology on already-closed incidents and widens the control surface beyond the plan’s “bounded controls” posture.

**Fix:**
```elixir
def trigger_next_escalation(%Incident{state: state}, _payload)
    when state in ["investigating", "resolved"],
    do: {:error, :invalid_incident_state}

def suppress_pending_escalation(%Incident{state: state}, _until, _payload)
    when state in ["investigating", "resolved"],
    do: {:error, :invalid_incident_state}
```

Also hide or disable the escalation controls in the template unless the incident is still `open`, and add tests covering rejected commands plus the UI gating.

### WR-03: The new suppression handler crashes on malformed `minutes` input

**File:** `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex:71-76`

**Issue:** the LiveView handler parses `minutes` with `String.to_integer/1` directly. A tampered event payload like `%{"minutes" => "abc"}` raises `ArgumentError` and crashes the LiveView process instead of returning a validation error. The compile-out test only checks for string presence and does not exercise this path.

**Fix:**
```elixir
with {minutes, ""} <- Integer.parse(minutes),
     true <- minutes > 0 do
  ...
else
  _ -> {:noreply, put_flash(socket, :error, "Invalid suppression window")}
end
```

Add a LiveView-level test for invalid and out-of-range `minutes` values.

### WR-04: The generated Resolve action still records a note instead of resolving the incident

**File:** `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex:33-44`

**Issue:** the `handle_event("resolve", ...)` path builds a resolve payload but calls `Parapet.Operator.record_note/3` instead of `Parapet.Operator.resolve_incident/2`. Clicking “Resolve Incident” therefore leaves the incident unresolved and only appends a note. The current Phase 4 tests do not compile or execute this handler, so the regression is not caught.

**Fix:**
```elixir
case Parapet.Operator.resolve_incident(incident, payload) do
  {:ok, _result} ->
    {:noreply, push_navigate(socket, to: "/parapet/#{id}")}
  {:error, _reason} ->
    {:noreply, put_flash(socket, :error, "Failed to resolve")}
end
```

Add a behavioral test for the generated resolve event, not just compile/string checks.

---

_Reviewed: 2026-05-19T08:54:32Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
