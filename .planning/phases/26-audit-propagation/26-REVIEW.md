---
phase: 26-audit-propagation
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - lib/parapet/evidence/retrospective.ex
  - lib/parapet/operator.ex
  - test/parapet/evidence/retrospective_test.exs
  - test/parapet/operator/preview_lifecycle_test.exs
  - test/parapet/operator_test.exs
findings:
  critical: 1
  warning: 3
  info: 1
  total: 5
status: issues_found
---

# Phase 26: Code Review Report

**Reviewed:** 2026-05-28T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 26 added a `recovery_failed` TimelineEntry + ToolAudit write in the `{:error, reason}` arm of `confirm_runbook_step/4`, enriched the `recovery_confirmed` write with `actor`/`capability`/`target_refs`/`outcome`, and added two `format_payload/1` clauses in `Parapet.Evidence.Retrospective`.

The pattern-match ordering of the new `format_payload/1` clauses is correct and neither clause can be shadowed by the existing clauses above it. The `{:error, reason}` return contract is preserved — the `_ =` assignment correctly discards the DB result so the original error propagates. However, one correctness bug exists in the exception-safety envelope around the best-effort audit write: an uncaught exception from `Evidence.run_operator_command/1` will bypass `ClaimService.mark_failed/2`, leaving the claim in a "won" state for its full 5-minute lease window. Two further issues affect the quality and correctness of the new `format_payload/1` clauses: one is a user-visible rendering defect (Elixir list syntax in markdown), and one is a missing guard in the `recovery_failed` pattern that allows payloads whose `outcome` map lacks the `"reason"` key to fall through to the `inspect/1` catch-all.

---

## Critical Issues

### CR-01: Best-effort audit write can raise and leave the claim permanently won

**File:** `lib/parapet/operator.ex:803-812`

**Issue:** The `_ =` assignment on line 803 discards the *return value* of `Evidence.run_operator_command/1` but does not protect against *exceptions* thrown by it. `Evidence.run_operator_command/1` delegates to `repo().transaction(multi)` (evidence.ex:161), and Ecto's PostgreSQL adapter raises `DBConnection.ConnectionError` (and other runtime errors) rather than returning `{:error, _}` when the database connection is broken or a connection checkout times out. If such an exception escapes line 804-808, execution never reaches `ClaimService.mark_failed(claim, reason)` on line 812. The claim remains in `"won"` state for the entire 5-minute lease window, preventing the operator from retrying the step.

The inline comment says "best-effort audit write **before** releasing the claim" — the intent is clearly to always call `mark_failed`, but the implementation does not guarantee it.

**Fix:** Wrap the best-effort write in `try/rescue` so `mark_failed` is always executed regardless of the audit outcome:

```elixir
{:error, reason} ->
  # Best-effort audit write — must not prevent claim release (CR-01).
  try do
    _ =
      Evidence.run_operator_command(
        incident_changeset: Ecto.Changeset.change(incident, %{}),
        timeline_attrs: failure_timeline_attrs,
        audit_attrs: failure_audit_attrs
      )
  rescue
    _ -> :ok
  end

  # Release the claim so the operator can retry immediately.
  ClaimService.mark_failed(claim, reason)
  {:error, reason}
```

---

## Warnings

### WR-01: `format_payload/1` recovery_confirmed clause renders target_refs as raw Elixir syntax

**File:** `lib/parapet/evidence/retrospective.ex:148`

**Issue:** The clause at line 148 produces:

```
retry_async_item confirmed by ops@example.com on ["job-1", "job-2"]
```

The `["job-1", "job-2"]` fragment is `inspect/1` output — Elixir list syntax embedded verbatim in a Markdown retrospective intended for human readers (and potentially external stakeholders). The test at retrospective_test.exs:101 asserts `refute markdown =~ "%{"` (guarding against map syntax) but does not catch list syntax, so this defect is not exercised by the test suite.

For empty `target_refs` the output is `on []`, which is similarly un-prose-like.

**Fix:** Join target_refs into a readable string:

```elixir
defp format_payload(%{"capability" => cap, "actor" => actor, "outcome" => %{"status" => "succeeded"}} = p) do
  target_refs = Map.get(p, "target_refs", [])
  refs_str = if target_refs == [], do: "no targets", else: Enum.join(target_refs, ", ")
  "#{cap} confirmed by #{actor} on #{refs_str}"
end
```

Update the corresponding test assertion to match the new format and add a list-syntax guard:

```elixir
refute markdown =~ ~r/\[.*\]/  # no raw Elixir list syntax
assert markdown =~ "retry_async_item confirmed by ops@example.com on job-1"
```

---

### WR-02: `format_payload/1` recovery_failed clause silently falls through to `inspect/1` when `"reason"` key is absent from outcome

**File:** `lib/parapet/evidence/retrospective.ex:151`

**Issue:** The `recovery_failed` clause matches only when the nested outcome map contains exactly `"status" => "failed"` **and** `"reason" => reason`. If a `recovery_failed` entry is persisted whose `outcome` map has `"status" => "failed"` but lacks the `"reason"` key (e.g., written by a different code path, or due to a serialization gap), the clause does not match and the payload falls through to the `inspect/1` catch-all at line 155. The retrospective then contains raw `%{"capability" => ..., ...}` map output — the very thing WR-01's test guards against for the happy path.

This is a latent defect rather than a currently exercised one, but it creates a hidden coupling: the `format_payload` clause is fragile with respect to the exact `outcome` shape.

**Fix:** Either add a fallback clause for `"failed"` outcomes missing `"reason"`, or make the clause tolerant:

```elixir
defp format_payload(%{"capability" => cap, "actor" => actor, "outcome" => %{"status" => "failed"} = outcome}) do
  reason = Map.get(outcome, "reason", "unknown reason")
  "Recovery failed: #{cap} by #{actor} — #{reason}"
end
```

---

### WR-03: `failure_audit_attrs` built manually instead of extending `build_audit/2` — divergence risk

**File:** `lib/parapet/operator.ex:788-801`

**Issue:** The failure-path audit attrs (lines 788-801) are constructed as a hand-rolled map literal rather than calling `build_audit("operator_confirm_recovery", payload)` and then patching the fields that differ (`success: false`, `output:`, `action_name:`, `target_refs:`). This is necessary because `build_audit/2` hardcodes `success: true` (operator.ex:1039) and has no override path.

As a result the two audit maps (success arm at line 757-765 and failure arm at line 788-801) share a large set of input fields that must be kept in sync manually. If a future change adds a new field to `build_audit/2` (e.g., a `session_id` from `ActionPayload`), the failure arm will silently omit it, producing audit records with asymmetric schemas.

**Fix:** Extend `build_audit/2` to accept an `opts` keyword list (or add a `build_failure_audit/3` helper) so both arms derive from the same base:

```elixir
defp build_audit(tool_name, payload, overrides \\ []) do
  %{
    tool_name: tool_name,
    success: Keyword.get(overrides, :success, true),
    input: %{
      "actor" => payload.actor,
      "reason" => payload.reason,
      "correlation_id" => payload.correlation_id,
      "idempotency_key" => payload.idempotency_key,
      "action_type" => Atom.to_string(payload.action_type)
    }
  }
  |> then(fn base ->
    case Keyword.get(overrides, :output) do
      nil -> base
      output -> Map.put(base, :output, output)
    end
  end)
  |> Map.update!(:input, fn inp ->
    Keyword.get(overrides, :extra_input, %{})
    |> Map.merge(inp)
  end)
end
```

---

## Info

### IN-01: Test CR-02 in `preview_lifecycle_test.exs` asserts `tool_audit.success == false` but the DummyRepo `transaction/1` multi-path only captures writes where `:timeline_entry` is present in the result map

**File:** `test/parapet/operator/preview_lifecycle_test.exs:371-373`

**Issue:** The DummyRepo `transaction/1` capture logic at lines 131-137 of `preview_lifecycle_test.exs` appends to `:captured_writes` only when the result map contains `:timeline_entry` (line 131: `when is_map_key(acc, :timeline_entry)`). The assertion on line 372 accesses `failed_write.tool_audit.success`. If the multi result map key for the ToolAudit is `:tool_audit` and the capture fires only when `:timeline_entry` is present in the SAME acc, the assertion is valid — but the guard means that a write producing a `:tool_audit` key WITHOUT a corresponding `:timeline_entry` key would not be captured and the test would falsely pass. This is not currently a bug (the Ecto.Multi in `run_operator_command` always inserts both `:timeline_entry` and `:tool_audit` together) but it creates a fragile test-level invariant that could mask future regressions if the Multi shape changes.

**Fix:** Consider asserting directly on the `:tool_audit` key of the same acc rather than relying on the side-captured `:captured_writes` list for the `:tool_audit` field; or add a guard to the capture that validates both keys are present:

```elixir
case result do
  {:ok, acc} when is_map_key(acc, :timeline_entry) and is_map_key(acc, :tool_audit) ->
    existing = Process.get(:captured_writes, [])
    Process.put(:captured_writes, existing ++ [acc])
  _ ->
    :ok
end
```

---

_Reviewed: 2026-05-28T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
