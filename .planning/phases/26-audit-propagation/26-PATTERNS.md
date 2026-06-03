# Phase 26: Audit Propagation - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 5 modified files (no new files)
**Analogs found:** 5 / 5

## File Classification

| Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------|------|-----------|----------------|---------------|
| `lib/parapet/operator.ex` (`confirm_runbook_step/4` success arm + `build_audit/2`) | service | CRUD / request-response | `lib/parapet/automation/executor.ex` (actor convention) + `lib/parapet/escalation/worker.ex` (`inspect/1` normalization) | exact (cross-surface precedent for AUD-02) |
| `lib/parapet/operator.ex` (`confirm_runbook_step/4` `{:error}` arm) | service | request-response | `lib/parapet/escalation/worker.ex` `persist_failure_outcome/8` | role-match |
| `lib/parapet/evidence/retrospective.ex` (two new `format_payload/1` clauses) | utility / renderer | transform | `lib/parapet/evidence/retrospective.ex` existing `format_payload/1` clauses (lines 140–148) | exact (same file, same function) |
| `test/parapet/operator_test.exs` (extend AUD-01/02 assertions) | test | — | `test/parapet/operator_test.exs` existing confirm test at line 593 | exact |
| `test/parapet/operator/preview_lifecycle_test.exs` (extend CR-02/CR-03; add AUD-03 assertions) | test | — | `test/parapet/operator/preview_lifecycle_test.exs` CR-02 test at line 314, CR-03 at line 341 | exact |
| `test/parapet/evidence/retrospective_test.exs` (add recovery rendering tests) | test | — | `test/parapet/evidence/retrospective_test.exs` existing `generates markdown retrospective` test | exact |

---

## Pattern Assignments

### `lib/parapet/operator.ex` — success arm enrichment (`{:ok, exec_result}`)

**Analog:** `lib/parapet/automation/executor.ex` lines 54–61 (actor identity convention); `lib/parapet/escalation/worker.ex` lines 241–258 (`execution_payload/5` builder + `inspect(result)` normalization)

**Current `timeline_attrs` build (operator.ex lines 746–753) — the shape to REPLACE:**
```elixir
timeline_attrs = %{
  type: "recovery_confirmed",
  payload: %{
    "step_id" => to_string(step_id_atom),
    "capability" => to_string(capability_id),
    "result" => inspect(exec_result)
  }
}
```

**Enriched form (add `actor`, `target_refs`, replace `result` with nested `outcome` map):**
```elixir
# operator.ex ~line 746 — mirror the escalation_worker.ex execution_payload/5 pattern
timeline_attrs = %{
  type: "recovery_confirmed",
  payload: %{
    "step_id"      => to_string(step_id_atom),
    "actor"        => payload.actor,
    "capability"   => to_string(capability_id),
    "target_refs"  => preview_entry.target_refs || [],
    "outcome"      => %{"status" => "succeeded", "result" => inspect(exec_result)}
  }
}
```

**Current `build_audit/2` call and helper (operator.ex lines 755 + 990–1002) — the shape to EXTEND:**
```elixir
# call site (line 755):
audit_attrs = build_audit("operator_confirm_recovery", payload)

# helper (lines 990-1002):
defp build_audit(tool_name, %ActionPayload{} = payload) do
  %{
    tool_name: tool_name,
    success: true,
    input: %{
      "actor"           => payload.actor,
      "reason"          => payload.reason,
      "correlation_id"  => payload.correlation_id,
      "idempotency_key" => payload.idempotency_key,
      "action_type"     => Atom.to_string(payload.action_type)
    }
  }
end
```

**Enriched call site (add `action_name`, `target_refs` to `input`; set `output`):**
```elixir
# Two options — planner picks one and applies it consistently to both arms.

# Option A: extend build_audit/2 to a new build_audit/4 arity
# defp build_audit(tool_name, %ActionPayload{} = payload, extra_input, output) do
#   %{
#     tool_name: tool_name,
#     success: true,
#     input: Map.merge(base_input(payload), extra_input),
#     output: output
#   }
# end

# Option B (inline at call site — simpler, consistent with research recommendation):
audit_attrs =
  build_audit("operator_confirm_recovery", payload)
  |> Map.put(:output, %{"status" => "succeeded", "result" => inspect(exec_result)})
  |> Map.update!(:input, fn base ->
    Map.merge(base, %{
      "action_name"  => to_string(capability_id),
      "target_refs"  => preview_entry.target_refs || []
    })
  end)
```

**Actor identity pattern — from automation/executor.ex lines 55–57 (AUD-02 cross-surface precedent):**
```elixir
# Automation path sets a system actor string — operator path mirrors this shape.
# executor.ex:56 uses:
actor: "system:automation:executor"
# Operator path uses payload.actor (already in ActionPayload, required + non-blank).
# Both land in ToolAudit.input["actor"] — satisfying AUD-02 "regardless of surface."
```

---

### `lib/parapet/operator.ex` — failure arm (`{:error, reason}`)

**Analog:** `lib/parapet/escalation/worker.ex` `persist_failure_outcome/8` (lines 212–239) and `invoke_policy/3` `inspect(reason)` normalization (lines 166–178)

**Current `{:error, reason}` arm (operator.ex lines 763–767) — the base to EXTEND:**
```elixir
{:error, reason} ->
  ClaimService.mark_failed(claim, reason)
  {:error, reason}
```

**Enriched form — audit write BEFORE `mark_failed` (D-06 canonical order):**
```elixir
{:error, reason} ->
  failure_timeline_attrs = %{
    type: "recovery_failed",
    payload: %{
      "step_id"     => to_string(step_id_atom),
      "actor"       => payload.actor,
      "capability"  => to_string(capability_id),
      "target_refs" => preview_entry.target_refs || [],
      "outcome"     => %{"status" => "failed", "reason" => inspect(reason)}
    }
  }

  failure_audit_attrs = %{
    tool_name: "operator_confirm_recovery",
    success: false,
    input: %{
      "actor"           => payload.actor,
      "reason"          => payload.reason,
      "correlation_id"  => payload.correlation_id,
      "idempotency_key" => payload.idempotency_key,
      "action_type"     => Atom.to_string(payload.action_type),
      "action_name"     => to_string(capability_id),
      "target_refs"     => preview_entry.target_refs || []
    },
    output: %{"status" => "failed", "reason" => inspect(reason)}
  }

  # Best-effort: discard result to preserve {error, reason} return shape (Pitfall 2).
  _ = Evidence.run_operator_command(
    incident_changeset: Ecto.Changeset.change(incident, %{}),
    timeline_attrs: failure_timeline_attrs,
    audit_attrs: failure_audit_attrs
  )

  ClaimService.mark_failed(claim, reason)
  {:error, reason}
```

**`inspect/1` normalization precedent — escalation/worker.ex lines 100 + 170–171:**
```elixir
# escalation/worker.ex line 100 (success arm):
inspect(result)

# escalation/worker.ex lines 170-171 (error arm):
{:error, "policy_error", inspect(reason)}
# ...
{:error, "exception", Exception.message(error)}
```

**Note on `{:capability_raised, msg}` rescue (operator.ex lines 738–740):** This arm already uses `Exception.message(e)` to produce the msg string. When this flows into `{:error, reason}`, `reason` is `{:capability_raised, "boom from host"}`. `inspect(reason)` renders it as the string `"{:capability_raised, \"boom from host\"}"` — no structured failure class needed (D-06).

---

### `lib/parapet/evidence/retrospective.ex` — two new `format_payload/1` clauses

**Analog:** `lib/parapet/evidence/retrospective.ex` existing `format_payload/1` clauses (lines 140–148) — same function, same file.

**Existing clause chain to ADD BEFORE the catch-all (lines 140–148):**
```elixir
defp format_payload(nil), do: ""
defp format_payload(payload) when map_size(payload) == 0, do: ""
defp format_payload(%{"text" => text}), do: text
defp format_payload(%{"new_state" => state}), do: "State changed to #{state}"
defp format_payload(%{"change_ref" => ref}), do: "Change marker: #{ref}"

# ← INSERT new clauses HERE, before the catch-all below
defp format_payload(payload) do
  inspect(payload)
end
```

**New clauses to insert (exact copy is Claude's discretion per CONTEXT.md D-07):**
```elixir
# Match on "outcome" status to distinguish success from failure.
# Must appear BEFORE the generic inspect/1 fallback (Elixir top-to-bottom clause order).
defp format_payload(%{
       "capability" => cap,
       "actor" => actor,
       "outcome" => %{"status" => "succeeded"}
     } = p) do
  target_refs = Map.get(p, "target_refs", [])
  "#{cap} confirmed by #{actor} on #{inspect(target_refs)}"
end

defp format_payload(%{
       "capability" => cap,
       "actor" => actor,
       "outcome" => %{"status" => "failed", "reason" => reason}
     }) do
  "Recovery failed: #{cap} by #{actor} — #{reason}"
end
```

**`format_type/1` context (line 136) — already handles type humanization:**
```elixir
defp format_type(type) do
  type |> to_string() |> String.replace("_", " ") |> String.capitalize()
end
# "recovery_confirmed" → "Recovery confirmed"
# "recovery_failed"    → "Recovery failed"
# format_payload/1 provides the supplementary details line.
```

---

### `test/parapet/operator_test.exs` — extend confirm test (AUD-01/AUD-02 assertions)

**Analog:** `test/parapet/operator_test.exs` line 593 (existing `recovery_confirmed` string regression guard)

**Existing assertion to EXTEND (lines 593–594):**
```elixir
assert {:ok, result} = Operator.confirm_runbook_step(incident, :retry, token, payload)
assert %TimelineEntry{type: "recovery_confirmed"} = result.timeline_entry
```

**New assertions to ADD after line 594:**
```elixir
# AUD-01: TimelineEntry payload enriched
assert result.timeline_entry.payload["actor"] == payload.actor
assert result.timeline_entry.payload["capability"] == "retry_async_item"
assert is_list(result.timeline_entry.payload["target_refs"])
assert result.timeline_entry.payload["outcome"]["status"] == "succeeded"

# AUD-02: ToolAudit fields — output set, action_name + target_refs in input
assert result.tool_audit.success == true
assert result.tool_audit.input["action_name"] == "retry_async_item"
assert is_list(result.tool_audit.input["target_refs"])
assert result.tool_audit.input["actor"] == payload.actor
assert is_map(result.tool_audit.output)
assert result.tool_audit.output["status"] == "succeeded"
```

---

### `test/parapet/operator/preview_lifecycle_test.exs` — extend CR-02/CR-03 + add AUD-03 assertions

**Analog:** `test/parapet/operator/preview_lifecycle_test.exs` CR-02 test (lines 314–338) and CR-03 test (lines 341–368) — same test file, same DummyRepo pattern.

**DummyRepo transaction/1 (lines 99–127) supports Ecto.Multi step inspection — all Multi steps are exercised in-process. The `{:run, fun}` clause at line 121 covers `run_operator_command/1`'s `:broadcast_audit` step.**

**Existing CR-02 test end to EXTEND (line 337–338):**
```elixir
assert {:error, :provider_unavailable} =
         Operator.confirm_runbook_step(incident, :retry, token, payload)
```

**Add AUD-03 assertions after the existing CR-02 return-shape assert:**
```elixir
# AUD-03: recovery_failed TimelineEntry written even on capability error.
# DummyRepo.transaction/1 drives the Multi synchronously; capture via sent message
# or inspect the multi result by adjusting DummyRepo to return the acc.
# The simplest approach: assert return is still {:error, ...} AND use a
# Process dict capture or send/assert_received pattern consistent with
# how operator_test.exs verifies timeline writes.
```

**Existing CR-03 test end to EXTEND (line 364–367):**
```elixir
assert {:error, {:capability_raised, message}} =
         Operator.confirm_runbook_step(incident, :retry, token, payload)
assert message =~ "boom from host"
```

**Add AUD-03 assertion: `{:capability_raised, msg}` also produces a `recovery_failed` entry (same arm, normalized by `inspect/1`).**

**Existing negative-case pattern (short-circuit test lines 184–202) — regression guard model:**
```elixir
# Uses assert {:short_circuited, :preview_expired} with no timeline_entry assertion.
# Extend with refute that no recovery_failed entry is inserted (assert no Multi
# transaction was dispatched to run_operator_command via :repo_all or similar).
```

**Setup context — test fixture already provides:**
```elixir
# setup (lines 136-182):
Application.put_env(:parapet, :repo, DummyRepo)
# payload.actor = "user_1"
# incident.runbook_data = %{"module" => to_string(LifecycleRunbook)}
# capability :retry_async_item preview -> {:ok, %{"target_refs" => ["item-a", "item-b"]}}
# capability :retry_async_item execute -> {:ok, :executed}  ← reset per CR-02/CR-03 test
```

---

### `test/parapet/evidence/retrospective_test.exs` — add recovery rendering tests

**Analog:** `test/parapet/evidence/retrospective_test.exs` existing `"generates markdown retrospective"` test (lines 8–52) — same module, same `generate_markdown(incident, entries)` call pattern.

**Existing test structure to MIRROR:**
```elixir
incident = %Incident{id: "inc-1", title: "...", ...}
entries = [%TimelineEntry{type: "alert", payload: %{"text" => "..."}, inserted_at: ...}, ...]
markdown = Retrospective.generate_markdown(incident, entries)
assert markdown =~ "..."
```

**New test entries for recovery rendering (SC-4):**
```elixir
%TimelineEntry{
  type: "recovery_confirmed",
  payload: %{
    "capability"  => "retry_async_item",
    "actor"       => "ops@example.com",
    "target_refs" => ["job-1"],
    "outcome"     => %{"status" => "succeeded", "result" => ":executed"}
  },
  inserted_at: ~U[2026-05-28 10:01:00Z]
},
%TimelineEntry{
  type: "recovery_failed",
  payload: %{
    "capability"  => "retry_async_item",
    "actor"       => "ops@example.com",
    "target_refs" => ["job-2"],
    "outcome"     => %{"status" => "failed", "reason" => ":provider_unavailable"}
  },
  inserted_at: ~U[2026-05-28 10:02:00Z]
}
```

**Assertions to use (SC-4):**
```elixir
assert markdown =~ "retry_async_item confirmed by ops@example.com"
assert markdown =~ "Recovery failed: retry_async_item"
refute markdown =~ "%{"   # no raw inspect(payload) fallback — new clauses matched
```

---

## Shared Patterns

### `Evidence.run_operator_command/1` — atomic Multi seam
**Source:** `lib/parapet/evidence.ex` lines 126–162
**Apply to:** Both the enriched success write and the new failure write in `operator.ex`

```elixir
# evidence.ex lines 126-162 (key signature):
def run_operator_command(opts) do
  incident_changeset = Keyword.fetch!(opts, :incident_changeset)
  timeline_attrs     = Keyword.fetch!(opts, :timeline_attrs)
  audit_attrs        = Keyword.fetch!(opts, :audit_attrs)
  # Builds Multi: update(:incident), insert(:timeline_entry), insert(:tool_audit),
  # run(:broadcast_audit) — fires [:parapet, :audit, :created] telemetry.
  # Returns {:ok, %{incident:, timeline_entry:, tool_audit:, broadcast_audit:}}
  # or {:error, step_name, reason, changes_so_far}
  repo().transaction(multi)
end
```

**Failure-path best-effort rule:** The result of `run_operator_command/1` in the `{:error, reason}` arm MUST be discarded (`_ = Evidence.run_operator_command(...)`). The function must always return `{:error, original_reason}` as its last expression regardless of audit DB outcome.

### `inspect/1` for opaque-result normalization
**Source:** `lib/parapet/operator.ex` line 751 (success arm); `lib/parapet/escalation/worker.ex` lines 100 + 170
**Apply to:** `exec_result` in the enriched success payload (`"result" => inspect(exec_result)`); `reason` in the failure payload (`"reason" => inspect(reason)`)

```elixir
# escalation/worker.ex line 100 — success:
inspect(result)

# escalation/worker.ex line 170 — error:
inspect(reason)
```

### `payload.actor` as cross-surface operator identity string
**Source:** `lib/parapet/automation/executor.ex` lines 55–57; `lib/parapet/operator/action_payload.ex` line 19
**Apply to:** `timeline_attrs` payload map and `audit_attrs.input` map in both arms

```elixir
# executor.ex lines 55-57 (system path):
payload = %ActionPayload{
  actor: "system:automation:executor",
  ...
}
# operator path uses the caller-supplied payload.actor — same field, same JSON key.
```

### `target_refs || []` nil-guard
**Source:** Research RESEARCH.md Pitfall 3; `preview_lifecycle_test.exs` legacy compat test at line 232
**Apply to:** Every reference to `preview_entry.target_refs` in the new audit attrs maps

```elixir
# Always guard against nil for legacy previews (pre-Phase-25 entries had no target_refs_hash
# and target_refs may be nil):
"target_refs" => preview_entry.target_refs || []
```

### `TimelineEntry.type` as snake-case plain string
**Source:** `lib/parapet/spine/timeline_entry.ex` line 33; `lib/parapet/operator/workbench_contract.ex` line 130
**Apply to:** Every new `type:` key in timeline attrs maps

```elixir
# Existing types in the codebase (string literals, NOT atoms):
"recovery_confirmed"           # operator.ex:747
"recovery_preview"             # operator.ex:803
"mitigation_executed"          # workbench_contract.ex:130
"automation_short_circuited"   # executor.ex:76
"escalation_executed"          # worker.ex:94

# New type for Phase 26:
"recovery_failed"              # string literal, no migration, no Ecto.Enum
```

---

## No Analog Found

All modified files have close analogs. No entry in this table.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | — |

---

## Metadata

**Analog search scope:** `lib/parapet/` (operator.ex, automation/executor.ex, escalation/worker.ex, evidence.ex, evidence/retrospective.ex, operator/action_payload.ex, spine/timeline_entry.ex, spine/tool_audit.ex); `test/parapet/` (operator_test.exs, operator/preview_lifecycle_test.exs, evidence/retrospective_test.exs)
**Files scanned:** 11 source files read directly
**Pattern extraction date:** 2026-05-28
