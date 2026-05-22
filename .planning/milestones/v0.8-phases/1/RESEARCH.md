# Phase 1: Durable Escalation Engine - Research

**Researched:** 2024-05-24
**Domain:** Elixir Background Jobs & Escalation Logic
**Confidence:** HIGH

## Summary

This phase introduces a durable escalation engine to Parapet using Oban to guarantee that incidents are routed to human operators unless resolved or acknowledged first. By defining a generic `Parapet.Escalation.Policy` behaviour, host applications can implement custom logic (PagerDuty, SMS, Email). The `Parapet.Escalation.Worker` manages the lifecycle, utilizing Oban's retry mechanisms and specifically checking the `Parapet.Spine.Incident` state before firing. If the incident has already transitioned out of `"open"` to `"investigating"` (acknowledged) or `"resolved"`, it gracefully short-circuits. All actions emit `TimelineEntry` records for auditability.

**Primary recommendation:** Integrate Oban job enqueueing transactionally inside `Parapet.Evidence.create_incident` using `Ecto.Multi`, mapping the Multi result back to the standard API signature. Ensure the worker explicitly checks `Code.ensure_loaded?(Oban)` and `incident.state` prior to executing the policy.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Escalation Policy Contract | API / Backend | — | Provides a behavior (`@callback`) for custom escalation adapters. |
| Escalation Worker | API / Backend (Jobs)| Database | Oban worker ensures durable retries and transactional enqueueing tightly coupled with Ecto. |
| Incident Lifecycle | API / Backend | Database | Scheduling happens transactionally on creation in `Parapet.Evidence`; worker reads state. |
| Timeline Emission | API / Backend | Database | Parapet's existing audit log (`TimelineEntry`) records when escalations fire or short-circuit. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Oban | >= 0.0.0 | Background Jobs | Existing optional dependency in Parapet; provides Ecto-transactional queueing. |
| Ecto.Multi | ~> 3.10 | Transactional Boundaries | Standard Elixir approach for DB ops + Job Enqueue. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/parapet/escalation/
├── policy.ex    # Defines the @callback behaviour
└── worker.ex    # The Oban.Worker implementation
```

### Pattern 1: Behaviour for Escalation Policies
**What:** `Parapet.Escalation.Policy` defines a callback for executing an escalation step.
**When to use:** To provide a generic interface for host applications implementing custom logic (e.g., PagerDuty, SMS).
**Example:**
```elixir
defmodule Parapet.Escalation.Policy do
  @moduledoc "Behaviour for incident escalation adapters."
  
  @callback escalate(incident :: Parapet.Spine.Incident.t(), opts :: keyword()) ::
              {:ok, term()} | {:error, term()}
end
```

### Pattern 2: Short-circuiting Worker
**What:** The `Parapet.Escalation.Worker` checks the `Incident` state. If it is `"investigating"` (acknowledged) or `"resolved"`, it returns `{:discard, reason}` instead of escalating.
**When to use:** To prevent stale notifications for already handled incidents.
**Example:**
```elixir
defmodule Parapet.Escalation.Worker do
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"incident_id" => incident_id}}) do
    incident = Parapet.Evidence.repo().get(Parapet.Spine.Incident, incident_id)

    case incident do
      nil ->
        {:discard, "Incident not found"}

      %{state: state} when state in ["investigating", "resolved"] ->
        Parapet.Evidence.append_timeline(incident_id, %{
          type: "escalation_short_circuited",
          payload: %{"reason" => "already_#{state}"}
        })
        {:discard, "Short-circuited (already #{state})"}

      %{state: "open"} ->
        # Fetch configured policy, execute, and append timeline
        # Handle {:error, _} by returning it to trigger Oban retries
        :ok
    end
  end
end
```

### Pattern 3: Transactional Enqueueing
**What:** In `Parapet.Evidence.create_incident`, if escalation is configured, enqueue the worker in the same `Ecto.Multi`.
**Example:**
```elixir
def create_incident(attrs \\ %{}) do
  multi =
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:incident, Incident.changeset(%Incident{}, attrs))
    |> maybe_enqueue_escalation()

  case repo().transaction(multi) do
    {:ok, %{incident: incident}} -> {:ok, incident}
    {:error, :incident, changeset, _} -> {:error, changeset}
    {:error, _step, reason, _} -> {:error, reason}
  end
end

defp maybe_enqueue_escalation(multi) do
  if Code.ensure_loaded?(Oban) and Application.get_env(:parapet, :escalation_policy) do
    Ecto.Multi.insert(multi, :escalation_job, fn %{incident: incident} ->
      Parapet.Escalation.Worker.new(%{"incident_id" => incident.id})
    end)
  else
    multi
  end
end
```

## Anti-Patterns to Avoid
- **Hardcoding delay without Oban features:** Don't build custom delay loops. Use `scheduled_in` or `scheduled_at` in Oban when future levels of escalation are added.
- **Ignoring idempotency:** Policy implementations might get called multiple times (if DB transaction fails after external API call). Policies should be written carefully, but the worker itself must correctly short-circuit on already escalated/resolved states.
- **Enqueueing outside the transaction:** `Oban.insert` must be in the `Ecto.Multi` with the incident creation, otherwise you risk incidents that never get escalated if the application crashes between insert and enqueue.
- **Changing public API return signatures:** `create_incident` must continue returning `{:ok, struct}` instead of exposing the Multi result map.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Retries & Backoff | GenServer / Process.send_after | Oban | Built-in durable retries, observability, and Ecto transaction support. |
| Short-circuiting | Custom state machines | Oban `{:discard, reason}` + DB Check | If the incident is ack'd, the worker can simply query the DB and discard itself. |

## Common Pitfalls

### Pitfall 1: Changing API Return Signatures
**What goes wrong:** Upgrading `repo().insert/1` to `repo().transaction/1` (Ecto.Multi) changes the return type.
**Why it happens:** Ecto Multi returns a map of operations on success `{:ok, %{op: result}}`.
**How to avoid:** Explicitly unwrap the Multi result in a `case` statement to return `{:ok, incident}` or `{:error, changeset}` as the callers expect.

### Pitfall 2: Silent Failures in Optional Dependencies
**What goes wrong:** Parapet has `:oban` as optional. If the user doesn't have it, `maybe_enqueue_escalation` could crash.
**Why it happens:** Calling `Oban.insert` when Oban is not in the host's supervision tree or loaded.
**How to avoid:** Use `Code.ensure_loaded?(Oban)` and check if an escalation policy is configured before attempting to build or insert the job.

### Pitfall 3: Missing Timeline Emissions
**What goes wrong:** An incident is escalated, but there is no trace of it on the incident timeline.
**Why it happens:** Missing integration between the escalation worker and the timeline audit system.
**How to avoid:** Explicitly emit a `TimelineEntry` via `Parapet.Evidence.append_timeline` upon successful policy execution or when short-circuiting. Note that `TimelineEntry` uses `type` and `payload` fields.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom GenServers | Oban `Worker` | Standardizing on Oban | Durable, inspectable queueing tightly bound to Postgres. |
| In-memory retries | Ecto Multi Enqueueing | Standardizing on Oban | Guaranteed at-least-once execution via DB transactions. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Parapet.Evidence.create_incident API must remain `{:ok, struct}` | Pitfalls | Upstream callers will break if they receive Ecto.Multi results. |
| A2 | "investigating" state is equivalent to "acknowledge" | Architecture Patterns | If "investigating" isn't the correct ack state, escalations might fire when operators are already looking at it. |

## Open Questions (RESOLVED)

1. **Escalation Policy Configuration**
   - What we know: The worker needs to know which policy module to call.
   - What's unclear: Should it be hardcoded in application config (e.g., `Application.get_env(:parapet, :escalation_policy)`) or passed explicitly per incident?
   - **Resolution:** Default to fetching from `Application.get_env(:parapet, :escalation_policy)` for V0.8, since Parapet is host-configured.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Postgres | Ecto/Oban | ✓ | (Host provided) | — |
| Oban | Escalation Worker | ✓ | (Host provided) | Opt-out of escalation |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Define Policy Behaviour | unit | `mix test test/parapet/escalation/policy_test.exs` | ❌ Wave 0 |
| REQ-02 | Implement Worker (Oban) | unit | `mix test test/parapet/escalation/worker_test.exs` | ❌ Wave 0 |
| REQ-03 | Integrate Incident Lifecycle | unit | `mix test test/parapet/evidence_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/parapet/escalation/worker_test.exs` — covers REQ-02
- [ ] `test/parapet/escalation/policy_test.exs` — covers REQ-01 (dummy implementation to test behavior if needed)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Ecto Changeset |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Injection | Tampering | Ecto queries (parameterized) / Ecto Changesets |

## Sources

### Primary (HIGH confidence)
- [VERIFIED: Codebase grep] - `lib/parapet/evidence.ex`
- [VERIFIED: Codebase grep] - `lib/parapet/spine/incident.ex`
- [VERIFIED: Codebase grep] - `lib/parapet/spine/timeline_entry.ex`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows existing Oban patterns in the repo.
- Architecture: HIGH - Applies standard Ecto/Oban transaction boundaries.
- Pitfalls: HIGH - Documented Elixir/Ecto common issues.

**Research date:** 2024-05-24
**Valid until:** 2024-06-24