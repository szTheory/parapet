# Phase 3: Threadline Compliance Sync - Research

**Researched:** 2024-05-17
**Domain:** Audit Integrations, Telemetry, Optional Dependencies
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| THR-01 | System Parapet.Ecto.ToolAudit can be configured to broadcast audit events to Threadline (if available). System allows operators to defer the storage of audit logs entirely to Threadline in compliance-heavy environments to maintain a single source of truth for administrative actions. | Implementation of `config :parapet, audit_mode` config handling in `Parapet.Evidence`, and checking `Code.ensure_loaded?(Threadline)` in `Parapet.Integrations.Threadline` adapter. |
</phase_requirements>

## Summary

The goal of this phase is to sync Parapet operator actions to Threadline for compliance auditing, without forcing a hard dependency on Threadline for users who do not use it. To satisfy the "compile out cleanly" constraint, we rely on the standard Elixir `Code.ensure_loaded?/1` pattern for `Threadline`, avoiding compile-time failures if the module is missing. 

We also implement a configuration-driven mechanism in `Parapet.Evidence` to either dual-write audit logs to both Parapet's Ecto `ToolAudit` table and Threadline, or to defer them entirely to Threadline in compliance-heavy environments to prevent data duplication and maintain a single source of truth.

**Primary recommendation:** Add `config :parapet, audit_mode: :dual_write | :threadline_deferred`. In `Parapet.Evidence.run_operator_command/1`, branch the `Ecto.Multi` logic so that in `:threadline_deferred` mode, it skips inserting the `ToolAudit` into the database, and instead emits the audit event to `Parapet.Integrations.Threadline.broadcast/1`, which handles the actual Threadline API interaction using `Code.ensure_loaded?(Threadline)`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Ecto Multi Transactions | API / Backend | — | `Parapet.Evidence` acts as the primary seam for writing to the DB or conditionally deferring audit persistence. |
| Compliance Sync | API / Backend | — | `Parapet.Integrations.Threadline` acts as an Anti-Corruption Layer, isolating Threadline-specific calls and formats. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir `Code` module | built-in | `Code.ensure_loaded?/1` | Standard Elixir mechanism for checking if a module exists at runtime, ensuring clean compile-out of optional dependencies. |
| Ecto.Multi | ~> 3.10 | Database transactions | Used in `Parapet.Evidence.run_operator_command/1` to ensure timeline and audit insert as a clean transaction. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/
├── parapet/
│   ├── evidence.ex           # Updated to conditionally skip ToolAudit Ecto inserts
│   └── integrations/
│       └── threadline.ex     # Contains `broadcast/1` protected by `Code.ensure_loaded?`
```

### Pattern 1: Optional Dependency Wrapper
**What:** Wrapping external API calls in `if Code.ensure_loaded?(Dependency)`.
**When to use:** When integrating with optional packages (like `Threadline`, `Scoria`, or `Oban`) so the host app doesn't crash if they are omitted from `mix.exs`.
**Example:**
```elixir
# Source: Parapet's existing Scoria integration pattern
def broadcast(audit) do
  if Code.ensure_loaded?(Threadline) do
    # Proceed with Threadline call
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Optional module checks | Complex macro compilation checks | `Code.ensure_loaded?/1` | Native, fast, explicitly recommended for this codebase as seen in Oban and Scoria integrations. |

**Key insight:** Elixir provides built-in runtime loading checks. Macros overcomplicate optional dependencies and create brittle integration boundaries.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Parapet.Spine.ToolAudit records | No data migration required; new events will either route to `ToolAudit` or Threadline based on config. |
| Live service config | None — verified | None |
| OS-registered state | None — verified | None |
| Secrets/env vars | None — verified | None |
| Build artifacts | None — verified | None |

## Common Pitfalls

### Pitfall 1: Broken Ecto.Multi Chain
**What goes wrong:** If `run_operator_command/1` simply omits the `Ecto.Multi.insert(:tool_audit, ...)` step from the Multi chain when deferred, subsequent steps or return handlers might fail if they expect the `%{tool_audit: _}` map key in the transaction result.
**Why it happens:** Ecto Multi functions return a map of the completed operations. Any function relying on the `tool_audit` value will crash with `KeyError` if it is not present.
**How to avoid:** If `audit_mode == :threadline_deferred`, explicitly inject a placeholder or a no-op step: `Ecto.Multi.run(multi, :tool_audit, fn _repo, _changes -> {:ok, :deferred} end)` so the key exists and the transaction structure succeeds cleanly.

## Code Examples

### Conditional Ecto.Multi Execution
```elixir
# In Parapet.Evidence.run_operator_command/1
multi =
  Ecto.Multi.new()
  |> Ecto.Multi.update(:incident, incident_changeset)
  |> Ecto.Multi.insert(:timeline_entry, fn %{incident: incident} ->
    %TimelineEntry{}
    |> TimelineEntry.changeset(Map.put(timeline_attrs, :incident_id, incident.id))
  end)

multi =
  if Application.get_env(:parapet, :audit_mode, :dual_write) == :threadline_deferred do
    Ecto.Multi.run(multi, :tool_audit, fn _repo, _changes ->
      {:ok, :deferred}
    end)
  else
    Ecto.Multi.insert(multi, :tool_audit, fn %{timeline_entry: entry} ->
      %ToolAudit{}
      |> ToolAudit.changeset(Map.put(audit_attrs, :timeline_entry_id, entry.id))
    end)
  end
```

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified beyond Elixir standard lib and optional `Threadline` mock).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/parapet/integrations/threadline_test.exs test/parapet/evidence_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| THR-01 | Dual-write configuration inserts into `ToolAudit` and calls Threadline API | unit | `mix test test/parapet/evidence_test.exs` | ✅ Wave 0 |
| THR-01 | Threadline-deferred configuration skips `ToolAudit` insert | unit | `mix test test/parapet/evidence_test.exs` | ✅ Wave 0 |
| THR-01 | Optional dependency compiles out cleanly | unit | `mix test test/parapet/integrations/threadline_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/parapet/integrations/threadline_test.exs test/parapet/evidence_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements, but additional contexts for different `audit_mode` Application configs will need to be written in `evidence_test.exs`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Ecto Changesets for ToolAudit validation |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Parameter Tampering | Tampering | Ecto Changeset `cast/3` strict mapping |

## Sources

### Primary (HIGH confidence)
- `lib/parapet/integrations/scoria.ex` - Verified how optional dependencies are cleanly handled via `Code.ensure_loaded?/1`.
- `lib/parapet/evidence.ex` - Analyzed the `run_operator_command/1` `Ecto.Multi` logic.
- `lib/parapet/integrations/threadline.ex` - Analyzed existing mapper `to_threadline_shape/1`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - standard Elixir constructs verified in the repo.
- Architecture: HIGH - uses existing boundaries (`Parapet.Evidence`).
- Pitfalls: HIGH - `Ecto.Multi` missing keys is a well-known risk.

**Research date:** 2024-05-17
**Valid until:** 2024-06-17