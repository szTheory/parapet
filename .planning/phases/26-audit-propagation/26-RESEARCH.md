# Phase 26: Audit Propagation - Research

**Researched:** 2026-05-28
**Domain:** Elixir/Ecto — in-process audit-trail enrichment inside an existing `Ecto.Multi` transaction seam
**Confidence:** HIGH (all findings verified against live codebase; no external library research required)

## Summary

Phase 26 is a purely additive, in-codebase enrichment. The discuss-phase analyzer confirmed there are no external research gaps — every fact below is verified against live source files. The work enriches two existing write sites inside `Parapet.Operator.confirm_runbook_step/4` and adds one new failure write site, then adds two `format_payload/1` clauses to the retrospective renderer.

The transaction seam (`Evidence.run_operator_command/1` at `lib/parapet/evidence.ex:126`) already writes a `TimelineEntry` + `ToolAudit` atomically for the success arm. Phase 26 enriches the `timeline_attrs` map and `audit_attrs` map passed into that seam (for the success arm) and adds an analogous call in the `{:error, reason}` arm. The retrospective (`lib/parapet/evidence/retrospective.ex`) already surfaces all entries without a type whitelist — only `format_payload/1` display clauses need to be added.

No migration, no new dependency, no `mix.exs` churn, and no `Ecto.Enum` conversion touch the codebase. The `type` field stays `:string`; the new `"recovery_failed"` type is written as a plain string in exactly one new code path.

**Primary recommendation:** Three surgical edits — (1) enrich `build_audit/2` call-site in the `{:ok}` arm + the `timeline_attrs` map it builds, (2) add a new `Evidence.run_operator_command/1` call in the `{:error, reason}` arm before `mark_failed`, (3) add two `format_payload/1` clauses in `retrospective.ex` — then extend the two existing test files and the retrospective test.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Keep `TimelineEntry.type` as plain `:string`. Add `"recovery_failed"` by writing the string literal — NO migration, NO `Ecto.Enum` conversion, NO inclusion-list edit. (`timeline_entry.ex:33` is `field(:type, :string)`; `validate_typed_payload/1` only special-cases `"triage_snapshot"`.)
- **D-02:** Satisfy AUD-01's `:recovery_confirmed` atom spelling via the existing string write `"recovery_confirmed"` plus a documented atom-to-string mapping in requirement/CHANGELOG note. Do NOT convert the field to atom. Converting would break string-asserting tests (`operator_test.exs:594`, `preview_lifecycle_test.exs:262/286/410`) and the live step-done matcher at `workbench_contract.ex:130`.
- **D-03:** No new dedup mechanism. The claim gate IS the dedup boundary. A unique DB constraint would make a legitimate post-`mark_failed` retry collide.
- **D-04:** All five AUD-01/02 fields are reachable in current scope: `payload.actor` (operator identity), `to_string(capability_id)` (action name), `preview_entry.target_refs` (args — NOT the hash), structured outcome map + `inspect(exec_result)` (outcome), schema auto `timestamps/0` (timestamps).
- **D-05:** Populate `ToolAudit`'s currently-unset `output` field with the outcome map. `build_audit/2` today sets only `tool_name`, `success: true`, `input`.
- **D-06:** AUD-03 failure write lives at the single site `operator.ex:763` (the `{:error, reason}` arm after a won claim). The `{:capability_raised, msg}` rescued path flows into this same arm. The arm MUST still call `ClaimService.mark_failed(claim, reason)` AND still return `{:error, reason}` — the write is purely additive. Normalize error reason via `inspect(reason)`.
- **D-07:** Criterion #4 is structurally satisfied already — once entries are written they appear inline automatically. ONLY add `format_payload/1` clauses; do NOT add filtering/whitelist logic to retrospective.
- **D-08:** Telemetry emit-sites are OUT of scope. AUD-01/02/03 reference only `TimelineEntry`, `ToolAudit`, operator identity, and the retrospective.
- **D-09:** No change to `Parapet.Telemetry.RecoveryAction` event family / vocab.
- **D-10:** No change to `Parapet.Recovery` behaviour callbacks.
- **D-11:** No change to `confirm_runbook_step/4` return contract or claim/preview/short-circuit logic.
- **D-12:** No prebuilt playbooks (Ph 27), no demo seed/CI (Ph 28), no Stable-tier graduation (Ph 29).

### Claude's Discretion

- Exact key names and shape of the structured outcome map (`%{"status" => "succeeded"}` vs richer) — as long as AUD-01/02 fields are present and JSON-safe.
- Whether the enriched TimelineEntry payload and ToolAudit `output` reuse one shared builder helper or stay inline.
- Exact human-readable copy in the new `format_payload/1` retrospective clauses.
- Whether `recovery_failed` ToolAudit also sets `duration_ms` (nice-to-have; not required by AUD-03).

### Deferred Ideas (OUT OF SCOPE)

- Telemetry emit-site coverage for `Parapet.Telemetry.RecoveryAction`.
- Structured failure-class taxonomy for `recovery_failed` payloads.
- Converting `TimelineEntry.type` to `Ecto.Enum`.
- Prebuilt Playbooks (Phase 27), Demo Seed + CI Lane (Phase 28), Stability + Adopter Onboarding (Phase 29).
- Per-capability cooldown / breaker scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUD-01 | Every successful recovery action emits a `TimelineEntry` (`type: :recovery_confirmed`) capturing operator identity, action name, args, outcome, and timestamps | Verified: `operator.ex:746-753` already writes the entry; Phase 26 enriches the payload map with all 5 AUD-01 fields. String `"recovery_confirmed"` satisfies the atom requirement via documented mapping (D-02). |
| AUD-02 | Every successful recovery action emits a `ToolAudit` row with operator identity, action name, args, outcome, timestamps — regardless of which surface triggered it | Verified: `operator.ex:755` calls `build_audit/2` which today sets only `tool_name`/`success`/`input`; Phase 26 adds `output` (D-05) and enriches `input` to carry action name + args. `payload.actor` is the consistent cross-surface identity (automation uses `"system:automation:executor"`). |
| AUD-03 | `:recovery_failed` `TimelineEntry` type emitted on capability execution error; short-circuit/conflict states emit nothing | Verified: `operator.ex:763` is the single error-arm site (post-won `{:error, reason}`). `{:capability_raised, msg}` rescue at `:738-740` flows into this arm. Short-circuit arms (`:710-715`) and conflict arm (`:773`) continue writing nothing. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `TimelineEntry` write (success) | API / Backend (`operator.ex` + `evidence.ex`) | Database / Storage | Business logic decides payload shape; Ecto.Multi handles persistence atomically |
| `ToolAudit` write (success) | API / Backend (`operator.ex` + `evidence.ex`) | Database / Storage | Same transaction seam as TimelineEntry; ToolAudit is linked via `timeline_entry_id` FK |
| `TimelineEntry` + `ToolAudit` write (failure) | API / Backend (`operator.ex` + `evidence.ex`) | Database / Storage | Failure arm at `operator.ex:763`; reuses same `run_operator_command/1` seam |
| Retrospective rendering | API / Backend (`retrospective.ex`) | — | Pure in-process rendering; no new storage tier needed; entries flow in from existing query |
| Operator identity propagation | API / Backend (`ActionPayload`) | — | `payload.actor` is already in scope at all write sites; no new plumbing |

## Standard Stack

No new dependencies. This phase uses only what is already present in the project.

### Core (already installed)
| Library | Version | Purpose | Relevance to Phase 26 |
|---------|---------|---------|----------------------|
| Ecto | ~> 3.10 | ORM + changeset + Ecto.Multi transactions | `run_operator_command/1` uses `Ecto.Multi`; `ToolAudit.changeset/2` casts `output` field |
| Ecto SQL | ~> 3.10 | Repo adapter | `repo().transaction/1` drives the Multi |
| ExUnit | built-in | Test framework | All new assertions use ExUnit patterns already established in the test suite |

**Installation:** None required. [VERIFIED: live mix.exs]

## Package Legitimacy Audit

Not applicable — Phase 26 installs no new packages.

## Architecture Patterns

### System Architecture Diagram

```
Operator Click (Confirm)
        |
        v
confirm_runbook_step/4  [operator.ex:691]
        |
   [validation + preview lookup]
        |
  ClaimService.claim_action/1
        |
   {:won, claim}
        |
  capability.execute.(incident, target_refs)  [operator.ex:737]
        |
   +---+---+
   |       |
{:ok,   {:error,
exec}    reason}
   |       |
   |    [NEW] build failure attrs
   |    Evidence.run_operator_command/1
   |      - type: "recovery_failed"
   |      - ToolAudit success: false
   |    ClaimService.mark_failed(claim, reason)
   |    return {:error, reason}  [unchanged]
   |
[ENRICHED] build_audit/2 extended
Evidence.run_operator_command/1  [evidence.ex:126]
  Ecto.Multi:
    update(:incident, changeset)
    insert(:timeline_entry)  ← enriched payload
    insert(:tool_audit)      ← output + success fields set
    run(:broadcast_audit)
return {:ok, %{timeline_entry:, tool_audit:, ...}}  [unchanged]

                [Short-circuit arms: operator.ex:710-715]
                {:short_circuited, :preview_expired}     ← writes NOTHING
                {:short_circuited, :target_refs_drift}   ← writes NOTHING
                {:conflicted, claim_id}                  ← writes NOTHING
                [These are structurally unchanged]

Retrospective query (Evidence.Retrospective.generate_markdown/1)
  SELECT * FROM parapet_timeline_entries
  WHERE incident_id = ? ORDER BY inserted_at ASC   [no whitelist]
        |
  format_entry/1 → format_payload/1
  [NEW clauses]
    "recovery_confirmed" payload → human-readable success line
    "recovery_failed"    payload → "Recovery failed: <reason>"
```

### Recommended Project Structure

No new files required. All edits are additive to existing files:

```
lib/parapet/
├── operator.ex                       # EDIT: enrich timeline_attrs + build_audit/2 in {:ok} arm;
│                                     #       add Evidence.run_operator_command/1 call in {:error} arm
├── evidence/
│   └── retrospective.ex              # EDIT: add 2 format_payload/1 clauses
test/parapet/
├── operator_test.exs                 # EDIT: extend confirm assertions (AUD-01, AUD-02)
└── operator/
    ├── preview_lifecycle_test.exs    # EDIT: extend assertions for new fields; add failure arm test
    └── [no new test files required]
test/parapet/evidence/
└── retrospective_test.exs            # EDIT: add recovery_confirmed + recovery_failed render tests
```

### Pattern 1: Enriching `timeline_attrs` in the `{:ok}` arm

**What:** Add `actor`, `capability` (action name), `target_refs` (args), and `outcome` map to the TimelineEntry payload. All fields are already in scope.

**Current code at `operator.ex:746-753`:**
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

**Enriched form:**
```elixir
# Source: verified against operator.ex:746-753 + action_payload.ex:19 + D-04
timeline_attrs = %{
  type: "recovery_confirmed",
  payload: %{
    "step_id"    => to_string(step_id_atom),
    "actor"      => payload.actor,
    "capability" => to_string(capability_id),
    "target_refs" => preview_entry.target_refs,
    "outcome"    => %{"status" => "succeeded", "result" => inspect(exec_result)}
  }
}
```

**Notes:** `payload.actor` is in scope (the `%ActionPayload{}` arg). `preview_entry.target_refs` is in scope (the `TimelineEntry` fetched by `find_recent_preview/3`). The outer `payload` variable is the `%ActionPayload{}` — no shadowing concern because Elixir pattern-match binds the arg at the function head.

### Pattern 2: Enriching `build_audit/2` for the success arm

**What:** Extend the `audit_attrs` map to carry action name, args, and `output`. `build_audit/2` is a private helper at `operator.ex:990`.

**Current `build_audit/2`:**
```elixir
# Source: verified against operator.ex:990-1002
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

**Option A — inline at the call site (no helper change):**
```elixir
# Source: operator.ex:755 pattern — extend the map directly
audit_attrs =
  build_audit("operator_confirm_recovery", payload)
  |> Map.merge(%{
    output: %{"status" => "succeeded", "result" => inspect(exec_result)},
    input: Map.merge(
      build_audit("operator_confirm_recovery", payload).input,
      %{
        "action_name"  => to_string(capability_id),
        "target_refs"  => preview_entry.target_refs
      }
    )
  })
```

**Option B — pass extra args to `build_audit/2` / add a new arity (Claude's discretion):**
Either approach is valid per CONTEXT.md. The planner should choose one and be consistent between success + failure paths.

**Key constraint:** `ToolAudit.changeset/2` at `tool_audit.ex:32` already casts `output` — no schema change needed. [VERIFIED: tool_audit.ex:32]

### Pattern 3: New failure write in the `{:error, reason}` arm

**What:** Before `ClaimService.mark_failed/2` and the `{:error, reason}` return, call `Evidence.run_operator_command/1` with a `"recovery_failed"` timeline entry and a `ToolAudit` with `success: false`.

**Current `{:error, reason}` arm at `operator.ex:763-768`:**
```elixir
{:error, reason} ->
  ClaimService.mark_failed(claim, reason)
  {:error, reason}
```

**Enriched form:**
```elixir
# Source: operator.ex:763; D-06 specifies additive-only write BEFORE mark_failed + return
{:error, reason} ->
  failure_timeline_attrs = %{
    type: "recovery_failed",
    payload: %{
      "step_id"    => to_string(step_id_atom),
      "actor"      => payload.actor,
      "capability" => to_string(capability_id),
      "target_refs" => preview_entry.target_refs,
      "outcome"    => %{"status" => "failed", "reason" => inspect(reason)}
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
      "target_refs"     => preview_entry.target_refs
    },
    output: %{"status" => "failed", "reason" => inspect(reason)}
  }

  Evidence.run_operator_command(
    incident_changeset: Ecto.Changeset.change(incident, %{}),
    timeline_attrs: failure_timeline_attrs,
    audit_attrs: failure_audit_attrs
  )

  ClaimService.mark_failed(claim, reason)
  {:error, reason}
```

**Key facts:**
- `inspect(reason)` is the established pattern for opaque reasons (escalation worker at `~:100`, D-06).
- `{:capability_raised, msg}` from the rescue at `operator.ex:738-740` flows into this same arm already — it is normalized by `inspect/1` which produces `"{:capability_raised, \"boom from host\"}"`.
- `mark_failed` and `{:error, reason}` return are UNCHANGED per D-06/D-11.
- If `run_operator_command/1` itself returns an error (e.g., DB down), do NOT propagate it — the function must still return `{:error, reason}` as the original capability error. The audit write is best-effort on the failure path. Log or ignore the inner error.

### Pattern 4: `format_payload/1` clauses in `retrospective.ex`

**What:** Add two clauses above the generic `inspect(payload)` fallback at `retrospective.ex:146`.

**Current fallback at `retrospective.ex:140-148`:**
```elixir
defp format_payload(nil), do: ""
defp format_payload(payload) when map_size(payload) == 0, do: ""
defp format_payload(%{"text" => text}), do: text
defp format_payload(%{"new_state" => state}), do: "State changed to #{state}"
defp format_payload(%{"change_ref" => ref}), do: "Change marker: #{ref}"

defp format_payload(payload) do
  inspect(payload)
end
```

**New clauses to insert before the catch-all:**
```elixir
# Source: retrospective.ex:140-148 pattern; D-07 specifies distinct wording for failures
defp format_payload(%{"capability" => cap, "actor" => actor, "outcome" => %{"status" => "succeeded"}} = p) do
  target_refs = Map.get(p, "target_refs", [])
  "#{cap} confirmed by #{actor} on #{inspect(target_refs)}"
end

defp format_payload(%{"capability" => cap, "actor" => actor, "outcome" => %{"status" => "failed", "reason" => reason}}) do
  "Recovery failed: #{cap} by #{actor} — #{reason}"
end
```

**Notes:**
- Exact copy is Claude's discretion per CONTEXT.md.
- Clauses must be ordered before the generic `inspect(payload)` fallback.
- `format_type/1` at `retrospective.ex:136` already humanizes the type string — `"recovery_confirmed"` → `"Recovery confirmed"`, `"recovery_failed"` → `"Recovery failed"`. The `format_payload/1` clause provides supplementary details.

### Anti-Patterns to Avoid

- **Filtering the retrospective query:** `generate_markdown/1` selects ALL entries with no type whitelist (verified at `retrospective.ex:22-27`). Do NOT add a type-gating `where` clause.
- **Writing `"recovery_failed"` on short-circuit or conflict arms:** These arms never reach `capability.execute` — verified in `cond` block at `operator.ex:708-778`. Only the post-won `{:error, reason}` arm (`:763`) gets the write.
- **Propagating `run_operator_command/1` error from failure path:** The function contract returns `{:error, original_reason}` — do not let an audit DB failure change the return shape.
- **Adding a unique DB constraint on TimelineEntry for dedup:** D-03 explains this breaks the legitimate post-`mark_failed` retry cycle.
- **Using atoms as TimelineEntry type values:** `workbench_contract.ex:130` and three existing tests assert strings. The field is `:string`.
- **Calling `build_audit/2` twice in the failure path:** Build failure attrs directly (or add a `build_audit/3` variant) — don't call the existing arity-2 helper and override `success: true` afterward.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic TimelineEntry + ToolAudit write | Custom `Repo.transaction` | `Evidence.run_operator_command/1` at `evidence.ex:126` | Already handles both `dual_write` and `threadline_deferred` audit modes; fires `[:parapet, :audit, :created]` telemetry |
| Idempotency of the audit write | DB unique constraint | Claim gate in `ClaimService.claim_action/1` | Claim uniqueness is `(incident_id, action_kind, action_key)` — structurally guarantees single execution, single write |
| Operator identity | New identity field | `payload.actor` on the `%ActionPayload{}` already in scope | Consistent with automation path (`"system:automation:executor"`) — satisfies AUD-02 "regardless of surface" |
| Error reason normalization | Typed failure class | `inspect(reason)` | Matches established pattern in escalation worker; avoids coupling to frozen `@failure_classes` telemetry vocab |

## Runtime State Inventory

Step 2.6 SKIPPED — this is a greenfield additive phase. No rename, refactor, or migration involved. No existing stored data references `"recovery_failed"`. The only new string is introduced by new code, not a renaming of an existing string.

## Environment Availability

No external dependencies. This phase operates entirely within the existing project runtime.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | yes | ~> 1.19 (mix.exs) | — |
| Ecto / Ecto SQL | `Evidence.run_operator_command/1` | yes | ~> 3.10 (mix.exs) | — |
| ExUnit | Test assertions | yes | built-in | — |

**Missing dependencies with no fallback:** None.

## Common Pitfalls

### Pitfall 1: Overwriting `payload` variable name
**What goes wrong:** The function signature binds `%ActionPayload{} = payload` at `operator.ex:695`. Inside the `{:ok, exec_result}` arm, building a map named `timeline_attrs` with a key `"payload"` does not shadow the outer `payload` binding — but naming an intermediate variable `payload` (e.g. `payload = %{...}`) would. Elixir rebinds in the same scope.
**Why it happens:** Common in deeply nested `case`/`cond` arms.
**How to avoid:** Name the timeline payload map variable `timeline_attrs` (already the convention at `:746`) and the audit map `audit_attrs` (already the convention at `:755`). Do not rebind `payload`.
**Warning signs:** Compiler warning "variable 'payload' is unused" or unexpected `nil` actor in audit records.

### Pitfall 2: Failure audit write changing the return shape
**What goes wrong:** If `Evidence.run_operator_command/1` in the `{:error}` arm fails (e.g., DB unreachable) and its result is returned instead of `{:error, original_reason}`, the caller's pattern match breaks.
**Why it happens:** Forgetting to discard the return of `run_operator_command/1` in the failure path.
**How to avoid:** Pattern match with `_result = Evidence.run_operator_command(...)` or use `_ = ...` in the failure arm; always return `{:error, reason}` as the last expression.
**Warning signs:** Tests expecting `{:error, :provider_unavailable}` start returning `{:ok, %{...}}` or `{:error, :timeline_entry, ...}`.

### Pitfall 3: `target_refs` is nil for legacy previews
**What goes wrong:** Older `recovery_preview` entries may have `nil` target_refs (the hash was added in Phase 25 — legacy previews had no hash, and `target_refs` was only guaranteed populated after Phase 25). Writing a nil `target_refs` into the ToolAudit `input` map fails if `ToolAudit.changeset/2` casts it as-is; the audit DB row would store `null` for that key.
**Why it happens:** `find_recent_preview/3` returns whatever is in the stored payload; `preview_entry.target_refs` may be nil.
**How to avoid:** Use `Map.get(preview_entry, :target_refs) || []` (or `preview_entry.target_refs || []`) when building the audit `input` map. The existing nil-hash legacy compat test at `preview_lifecycle_test.exs:254-262` proves this case already passes in the success arm.
**Warning signs:** `{:error, :tool_audit, %Ecto.Changeset{...}, ...}` in tests using legacy preview fixtures.

### Pitfall 4: Calling `build_audit/2` in the failure path returns `success: true`
**What goes wrong:** Reusing `build_audit("operator_confirm_recovery", payload)` in the failure arm produces a map with `success: true`; overriding it afterward with `Map.put(..., :success, false)` works but is confusing.
**Why it happens:** Wanting to DRY the `input` map construction.
**How to avoid:** Either build the failure audit attrs map inline (explicit, easy to read), or add a private `build_failure_audit/4` variant that sets `success: false` and accepts `capability_id` + `target_refs` as extra args.
**Warning signs:** ToolAudit rows with `success: true` appear in the `"recovery_failed"` test assertions.

### Pitfall 5: Adding `format_payload/1` clauses after the catch-all
**What goes wrong:** Elixir matches function clauses in top-to-bottom order. If the two new clauses are added AFTER the `defp format_payload(payload) do ... end` catch-all, they are unreachable dead code — the retrospective still renders `inspect(payload)` for recovery entries.
**Why it happens:** Appending to the bottom of the file without reading clause order.
**How to avoid:** Insert the two new specific clauses immediately before the generic `inspect(payload)` fallback at `retrospective.ex:146`. The compiler warns about unreachable clauses.
**Warning signs:** Retrospective tests that assert a human-readable string fail; actual output contains `%{"capability" => ...}` inspect output.

### Pitfall 6: `run_operator_command/1` in failure arm executed AFTER `mark_failed`
**What goes wrong:** If `ClaimService.mark_failed/2` is called before the audit write, and a future retry wins the claim immediately, a race condition could have the second operator's `recovery_confirmed` entry precede the first operator's `recovery_failed` entry in the timeline (by insert time, not logical order). More critically, if `run_operator_command/1` raises after `mark_failed`, the entry is never written.
**Why it happens:** Ordering the failure arm as: mark_failed → write audit → return.
**How to avoid:** D-06 is explicit: write the audit BEFORE `mark_failed`. The canonical order is: write_audit → mark_failed → return `{:error, reason}`.
**Warning signs:** Tests that assert `recovery_failed` entry exists fail intermittently or not at all.

## Code Examples

### Verified: `run_operator_command/1` signature and multi steps

```elixir
# Source: lib/parapet/evidence.ex:126-162 (verified)
def run_operator_command(opts) do
  incident_changeset = Keyword.fetch!(opts, :incident_changeset)
  timeline_attrs = Keyword.fetch!(opts, :timeline_attrs)
  audit_attrs = Keyword.fetch!(opts, :audit_attrs)

  # Builds Ecto.Multi: update incident, insert timeline_entry,
  # insert tool_audit (in :dual_write mode), fire [:parapet, :audit, :created]
  # Returns {:ok, %{incident:, timeline_entry:, tool_audit:, broadcast_audit:}}
  # or {:error, step_name, changeset_or_reason, changes_so_far}
end
```

### Verified: `ToolAudit` schema field availability

```elixir
# Source: lib/parapet/spine/tool_audit.ex:18-28 (verified)
schema "parapet_tool_audits" do
  field(:tool_name, :string)   # required (validate_required)
  field(:input, :map)          # required (validate_required)
  field(:output, :map)         # optional — cast but NOT set today; Phase 26 sets it
  field(:success, :boolean)    # required (validate_required) — currently always true
  field(:duration_ms, :integer) # optional (nice-to-have per D-04 discretion)
  belongs_to(:timeline_entry, TimelineEntry, type: :binary_id)
  timestamps(type: :utc_datetime_usec)  # auto-set by Repo.insert
end
```

### Verified: `TimelineEntry` type field is `:string`, not validated beyond `"triage_snapshot"`

```elixir
# Source: lib/parapet/spine/timeline_entry.ex:33 + :49-59 (verified)
field(:type, :string)
# validate_typed_payload/1 has a single pattern-match case:
# {"triage_snapshot", payload} -> validates triage fields
# _ -> changeset (pass-through for all other types, including "recovery_failed")
```

### Verified: existing string assertions (regression guards)

```elixir
# Source: test/parapet/operator_test.exs:594 (verified)
assert %TimelineEntry{type: "recovery_confirmed"} = result.timeline_entry

# Source: test/parapet/operator/preview_lifecycle_test.exs:262, 286, 410 (verified)
assert {:ok, %{timeline_entry: %TimelineEntry{type: "recovery_confirmed"}}} = result

# Source: lib/parapet/operator/workbench_contract.ex:130 (verified)
e.type in ["mitigation_executed", "recovery_confirmed"]
```

### Verified: `build_audit/2` — current shape and what's missing

```elixir
# Source: lib/parapet/operator.ex:990-1002 (verified)
defp build_audit(tool_name, %ActionPayload{} = payload) do
  %{
    tool_name: tool_name,
    success: true,
    input: %{
      "actor"           => payload.actor,      # ← operator identity already here
      "reason"          => payload.reason,
      "correlation_id"  => payload.correlation_id,
      "idempotency_key" => payload.idempotency_key,
      "action_type"     => Atom.to_string(payload.action_type)
    }
    # MISSING: output field (AUD-02), action_name in input (AUD-02), target_refs in input (AUD-02)
  }
end
```

## State of the Art

No state-of-the-art changes apply — this phase uses the existing Ecto.Multi seam, established `inspect/1` normalization convention, and the existing `format_payload/1` clause pattern. No libraries or patterns are being updated.

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Thin `recovery_confirmed` payload (only `step_id`, `capability`, `result`) | Enriched payload + `ToolAudit.output` set | Phase 26 | AUD-01/AUD-02 compliance; audit is now forensically complete |
| No write on capability execute error | `"recovery_failed"` TimelineEntry + ToolAudit with `success: false` | Phase 26 | AUD-03 compliance; operator can reconstruct failure sequence from retrospective |

**Deprecated/outdated:**
- The thin `build_audit/2` shape (only `tool_name`/`success: true`/`input` without action_name/target_refs/output) is superseded by the enriched form in Phase 26.

## Assumptions Log

No claims in this research are tagged `[ASSUMED]`. All findings were verified directly against live source files in the repository.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | No assumed claims | — | — |

**All claims in this research were verified against live codebase files — no user confirmation needed.**

## Open Questions

1. **`run_operator_command/1` on the failure path — should it be best-effort or hard-fail?**
   - What we know: The function returns `{:ok, %{...}}` or `{:error, step, reason, changes}`. In the failure path, we must always return `{:error, original_reason}` per D-06/D-11.
   - What's unclear: Whether a failed audit write should be logged (e.g., `Logger.warning`) or silently discarded.
   - Recommendation: Planner decides; either is acceptable under D-06. Ignoring it is simpler; logging is more observable. The existing `run_operator_command/1` call in the success arm propagates its error naturally (the function returns it as the `confirm_runbook_step/4` result), so the failure arm is the only special case.

2. **`duration_ms` on the failure ToolAudit row**
   - What we know: D-04 marks it as a nice-to-have. The field is cast (not required) in `ToolAudit.changeset/2`.
   - What's unclear: Whether to capture a `start_time` before `capability.execute/2` to compute elapsed ms.
   - Recommendation: Planner adds a `t0 = System.monotonic_time(:millisecond)` before the `try` block and sets `duration_ms: System.monotonic_time(:millisecond) - t0` on both success and failure paths. Small addition, adds value to both arms.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs test/parapet/evidence/retrospective_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUD-01 | Successful Confirm writes `TimelineEntry` with `type: "recovery_confirmed"`, enriched payload including `actor`, `capability`, `target_refs`, `outcome` | Unit | `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs` | Yes — extend existing tests |
| AUD-02 | Successful Confirm writes `ToolAudit` row with `output` set, `action_name` in input, `target_refs` in input, `success: true` | Unit | `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs` | Yes — extend existing tests |
| AUD-02 | Cross-surface: `payload.actor` appears in ToolAudit `input` for both operator and automation paths | Unit | `mix test test/parapet/operator_test.exs` | Yes — extend |
| AUD-03 | `execute/2` returning `{:error, reason}` writes `TimelineEntry` with `type: "recovery_failed"` + ToolAudit `success: false`; `{:error, reason}` still returned | Unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` | Yes — extend existing CR-02 test |
| AUD-03 | `execute/2` raising (rescued to `{:capability_raised, msg}`) writes `recovery_failed` entry | Unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` | Yes — extend existing CR-03 test |
| AUD-03 (negative) | Short-circuit arms (`preview_expired`, `target_refs_drift`, `incident_resolved`) write NO TimelineEntry, NO ToolAudit | Unit | `mix test test/parapet/operator/preview_lifecycle_test.exs` | Yes — existing short-circuit tests; add negative assertion |
| AUD-03 (negative) | Conflict arm (`{:conflicted, _}`) writes NO TimelineEntry | Unit | `mix test test/parapet/operator_test.exs` | Yes — extend |
| SC-4 | `Retrospective.generate_markdown/1` renders `recovery_confirmed` entry with human-readable payload (not raw inspect) | Unit | `mix test test/parapet/evidence/retrospective_test.exs` | Yes — extend |
| SC-4 | `Retrospective.generate_markdown/1` renders `recovery_failed` entry with "Recovery failed: …" wording | Unit | `mix test test/parapet/evidence/retrospective_test.exs` | Yes — extend |
| SC-4 | Recovery entries appear inline (not in sidebar/separate section) in chronological order | Unit | `mix test test/parapet/evidence/retrospective_test.exs` | Yes — existing structure validates this; add recovery entries to the entry list |

### Test Observable Signals

**Success arm (AUD-01, AUD-02):**
```elixir
# Extend test at operator_test.exs:593 and preview_lifecycle_test.exs
assert {:ok, result} = Operator.confirm_runbook_step(incident, :retry, token, payload)
# AUD-01: TimelineEntry payload enriched
assert result.timeline_entry.type == "recovery_confirmed"
assert result.timeline_entry.payload["actor"] == payload.actor
assert result.timeline_entry.payload["capability"] == "retry_async_item"
assert result.timeline_entry.payload["target_refs"] == ["item-a"]
assert result.timeline_entry.payload["outcome"]["status"] == "succeeded"

# AUD-02: ToolAudit fields
assert result.tool_audit.success == true
assert result.tool_audit.input["action_name"] == "retry_async_item"
assert result.tool_audit.input["target_refs"] == ["item-a"]
assert result.tool_audit.input["actor"] == payload.actor
assert is_map(result.tool_audit.output)
assert result.tool_audit.output["status"] == "succeeded"
```

**Failure arm (AUD-03 — extend CR-02 test at preview_lifecycle_test.exs:314):**
```elixir
# After confirming with execute: fn -> {:error, :provider_unavailable} end
# Return shape MUST be unchanged:
assert {:error, :provider_unavailable} =
         Operator.confirm_runbook_step(incident, :retry, token, payload)

# AUD-03: TimelineEntry written even on failure
# (requires DummyRepo to capture the Multi result — verify via sent messages or
#  inspect Process dict if using mock pattern)
```

**Negative cases (no write on short-circuit/conflict):**
```elixir
# Short-circuit: no DB insert sent
assert {:short_circuited, :preview_expired} = Operator.confirm_runbook_step(...)
refute_received {:repo_all, _}  # or assert no Ecto.Multi transaction ran with a timeline insert
```

**Retrospective rendering (SC-4):**
```elixir
entries = [
  %TimelineEntry{type: "recovery_confirmed",
    payload: %{"capability" => "retry_async_item", "actor" => "ops@example.com",
               "target_refs" => ["job-1"], "outcome" => %{"status" => "succeeded"}},
    inserted_at: ~U[2026-05-28 10:01:00Z]},
  %TimelineEntry{type: "recovery_failed",
    payload: %{"capability" => "retry_async_item", "actor" => "ops@example.com",
               "target_refs" => ["job-2"], "outcome" => %{"status" => "failed", "reason" => ":provider_unavailable"}},
    inserted_at: ~U[2026-05-28 10:02:00Z]}
]
markdown = Retrospective.generate_markdown(incident, entries)
assert markdown =~ "retry_async_item confirmed by ops@example.com"
assert markdown =~ "Recovery failed: retry_async_item"
refute markdown =~ "%{"  # no raw inspect fallback
```

### Sampling Rate
- **Per task commit:** `mix test test/parapet/operator_test.exs test/parapet/operator/preview_lifecycle_test.exs test/parapet/evidence/retrospective_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
None — existing test infrastructure covers all phase requirements. No new test files need to be created; all new assertions extend existing test modules.

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `payload.actor` is already `validate_required` + `validate_not_blank` in `ActionPayload.changeset/2`; `inspect(reason)` for error payloads prevents injection into JSON map values |
| V6 Cryptography | no | — |

**Threat pattern relevant to this phase:**

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Injecting control characters via `exec_result` or `reason` in audit payload | Tampering | `inspect/1` serializes to Elixir term notation — not JSON; stored in `output: :map` JSONB field which escapes at the DB layer |
| Audit write revealing stack traces from host capability via `inspect(reason)` | Information disclosure | `{:capability_raised, msg}` uses `Exception.message/1` (already at `operator.ex:739`) — normalized string, not a full stacktrace |

## Sources

### Primary (HIGH confidence)
All findings verified by direct file inspection of the live codebase:

- `lib/parapet/operator.ex:691-787` — `confirm_runbook_step/4` full implementation including all four arms
- `lib/parapet/operator.ex:990-1002` — `build_audit/2` current shape
- `lib/parapet/evidence.ex:126-162` — `run_operator_command/1` multi steps and audit modes
- `lib/parapet/spine/tool_audit.ex` — `output`/`success` field availability; changeset casts
- `lib/parapet/spine/timeline_entry.ex` — `type: :string`; `validate_typed_payload/1` fallthrough
- `lib/parapet/evidence/retrospective.ex` — no type whitelist; `format_payload/1` fallback clause
- `lib/parapet/operator/action_payload.ex` — `actor` field required + non-blank
- `lib/parapet/operator/workbench_contract.ex:130` — string type dependency
- `test/parapet/operator_test.exs:594` — string `"recovery_confirmed"` regression guard
- `test/parapet/operator/preview_lifecycle_test.exs:262,286,410` — same regression guards
- `test/parapet/operator/preview_lifecycle_test.exs:314-367` — CR-02 (error return) and CR-03 (raised exception) test patterns
- `test/parapet/spine/tool_audit_test.exs` — `output` field in schema, cast but not required
- `test/parapet/evidence/retrospective_test.exs` — existing test pattern and structure

### Secondary (MEDIUM confidence)
- `.planning/phases/26-audit-propagation/26-CONTEXT.md` — all 12 locked decisions with cited line evidence

### Tertiary (LOW confidence)
None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; verified existing versions against mix.exs
- Architecture: HIGH — all edit targets read and verified line-by-line
- Pitfalls: HIGH — derived from reading actual code paths and DummyRepo transaction stubs
- Test patterns: HIGH — derived from reading existing test structure

**Research date:** 2026-05-28
**Valid until:** 2026-07-28 (stable codebase; no external dependency version staleness risk)
