# Phase 1: Alert Routing & Reception - Research

**Researched:** 2024-05
**Domain:** Elixir Webhooks, Ecto Schema Modifications, Prometheus Alertmanager Payloads
**Confidence:** HIGH

## Summary

Phase 1 focuses on building the webhook receiver layer in Parapet. It establishes a `Plug` that host applications will mount in their routers. Incoming payloads from Prometheus Alertmanager are parsed, and the individual alerts within the batch are either upserted as new `Incident` records or correlated with existing open incidents based on a `correlation_key`. Additionally, "resolved" payloads automatically close the incident and document the resolution in the `TimelineEntry` audit trail.

**Primary recommendation:** Implement `Parapet.Plug.Webhook`, modify `Parapet.Spine.Incident` with a `correlation_key`, and introduce a `Parapet.Spine.AlertProcessor` context module to handle the batch-iteration, upserts, and resolution state-machine via `Ecto.Multi`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. **Webhook Routing Location & API Surface:** Use a standalone `Plug` (`Parapet.Plug.Webhook`). Host app mounts it explicitly in their router.
2. **Incident Correlation Strategy (ROUTING-04):** Add a `correlation_key` (string) to `Parapet.Spine.Incident`. Use hash of `alertname` + `labels` or `fingerprint`.
3. **Alertmanager Batch Processing:** 1 Incident per individual Alert inside the webhook batch.
4. **Resolution Audit Trail (ROUTING-03):** Auto-resolution must mutate state AND insert a `TimelineEntry` via `Ecto.Multi`.

### the agent's Discretion
- Database constraints on `correlation_key`.
- Internal function boundaries inside the alert processor.

### Deferred Ideas (OUT OF SCOPE)
- N/A
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Webhook Routing | Plug | Host App Router | Host controls auth/pipeline, Parapet provides Plug |
| Correlation | API / Backend | DB (Unique Index) | Backend maps alerts to key, DB enforces uniqueness |
| Alert Processing | API / Backend | — | Domain logic for batch iteration and state transitions |
| Audit Trail | API / Backend | Ecto.Multi | Atomic creation of resolution and timeline entry |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Plug | ~> 1.15 | Webhook Interface | Elixir standard for composable HTTP |
| Ecto | ~> 3.10 | Database / State | Project default |
| Jason | ~> 1.4 | JSON Parsing | Standard for Elixir/Phoenix |

## Architecture Patterns

### System Architecture Diagram
Prometheus Alertmanager → Host App Router (`forward "/webhooks", Parapet.Plug.Webhook`) → `Parapet.Plug.Webhook` → `Parapet.Spine.AlertProcessor` → iterates `.alerts` array → Upsert `Parapet.Spine.Incident` & insert `Parapet.Spine.TimelineEntry` (using `Ecto.Multi`).

### Recommended Project Structure
```
lib/
├── parapet/
│   ├── plug/
│   │   └── webhook.ex         # The Plug accepting payloads
│   ├── spine/
│   │   ├── incident.ex        # (Updated) Ecto schema with correlation_key
│   │   └── alert_processor.ex # Context module for batch handling and state machine
```

### Pattern 1: Plug-based Webhook
**What:** Exposing a `Plug` instead of a Phoenix Controller.
**When to use:** When building an integration library that shouldn't dictate Phoenix route macros or controller inheritance.
**Example:**
```elixir
defmodule Parapet.Plug.Webhook do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(%{method: "POST"} = conn, _opts) do
    # Assuming host app has parsed JSON body (e.g. via Plug.Parsers)
    payload = conn.body_params
    Parapet.Spine.AlertProcessor.process_batch(payload)
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(202, Jason.encode!(%{status: "accepted"}))
  end
  
  def call(conn, _opts) do
    send_resp(conn, 405, "Method Not Allowed")
  end
end
```

### Anti-Patterns to Avoid
- **Implicit JSON Parsing:** Parapet should not assume `Plug.Parsers` is missing, but should handle if `body_params` is a struct or map. Usually, host app's endpoint or router has already parsed it.
- **Handling Batches as Single Incidents:** Alertmanager groups multiple alerts based on group_by rules. A single payload might contain "CPUHigh" and "DiskFull". The domain requires splitting these into individual incidents.
- **Partial DB Updates:** Resolving an incident without wrapping the `TimelineEntry` insert in an `Ecto.Multi` transaction risks partial state.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic State + Audit | Separate Ecto.Repo calls | `Ecto.Multi` | Prevents split-brain where incident is resolved but audit entry fails. |
| Alert Identification | Complex JSON matching | SHA256 / Deterministic correlation_key | JSON equality is brittle; hashing labels or using Prometheus `fingerprint` is durable. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Parapet DB schema `parapet_incidents` | Needs migration for `correlation_key` (string, indexed) |
| Live service config | None — verified | |
| OS-registered state | None — verified | |
| Secrets/env vars | None — verified | |
| Build artifacts | None — verified | |

## Common Pitfalls

### Pitfall 1: Unparsed JSON Body
**What goes wrong:** The Plug receives `conn.body_params` as an `Unfetched` struct or raw binary if the host app placed the `forward` route before `Plug.Parsers`.
**Why it happens:** Router setup order.
**How to avoid:** Clearly document in the Setup Guide that the webhook route must be placed after `Plug.Parsers` in the endpoint or router pipeline.

### Pitfall 2: Prometheus Fingerprint Variability
**What goes wrong:** Identical alerts get different correlation keys.
**Why it happens:** Prometheus groups by annotations too, or adds dynamic labels.
**How to avoid:** Rely on `fingerprint` field provided in the Alertmanager payload (available since Alertmanager v0.19+). If missing, fallback to deterministic hash of `labels`.

### Pitfall 3: Upsert Race Conditions
**What goes wrong:** Two identical alerts hit the webhook simultaneously, creating two incidents.
**Why it happens:** Read-modify-write without unique database constraints.
**How to avoid:** Add a unique index on `correlation_key` where `state` is "open". (e.g., `CREATE UNIQUE INDEX ... ON parapet_incidents(correlation_key) WHERE state = 'open'`)

## Code Examples

### Ecto Multi for Auto-Resolution
```elixir
def auto_resolve(incident, payload) do
  Ecto.Multi.new()
  |> Ecto.Multi.update(:incident, Ecto.Changeset.change(incident, state: "resolved"))
  |> Ecto.Multi.insert(:audit, %Parapet.Spine.TimelineEntry{
    incident_id: incident.id,
    type: "auto_resolved",
    payload: payload
  })
  |> Repo.transaction()
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | test/test_helper.exs |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Webhook Plug receives and processes JSON | integration | `mix test test/parapet/plug/webhook_test.exs` | ❌ |
| REQ-02 | Firing alert creates a new Incident | unit | `mix test test/parapet/spine/alert_processor_test.exs` | ❌ |
| REQ-03 | Identical alerts correlate to Incident | unit | `mix test test/parapet/spine/alert_processor_test.exs` | ❌ |
| REQ-04 | Resolved alert closes Incident + Timeline | unit | `mix test test/parapet/spine/alert_processor_test.exs` | ❌ |

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host app responsibility (via pipeline before Plug) |
| V3 Session Management | no | — |
| V4 Access Control | yes | Host app responsibility |
| V5 Input Validation | yes | Ecto Changesets for alert payloads |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Plug

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom Exhaustion | Denial of Service | `Jason` uses string keys by default |
| Webhook Spam | Denial of Service | DB unique constraints on correlation keys |
