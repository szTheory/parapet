# Phase 3: Notifications & Escalation - Research

**Researched:** 2026-05-11
**Domain:** Elixir Integrations & Background Processing
**Confidence:** HIGH

## Summary

This phase introduces outbound integrations to broadcast incident state changes to external chat platforms (Slack and MS Teams) via a standardized behavior. Because Parapet is a resilient incident management system, notifications must not block the web server (e.g., when accepting an Alertmanager webhook) and should support durable retries.

**Primary recommendation:** Define a `Parapet.Notifier` behavior and implement Slack/Teams adapters using the `Req` HTTP client (added as an optional dependency). Use `Oban` (already an optional dependency) for durable, retriable notification delivery, falling back to simple `Task` execution if Oban is not present. Insert a `Parapet.Spine.TimelineEntry` after delivery attempts to guarantee auditability.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NOTIFY-01 | System provides a modular notification behavior (`Parapet.Notifier`) for broadcasting incident state changes. | Define an Elixir `@behaviour` pattern allowing custom adapters. |
| NOTIFY-02 | System includes an out-of-the-box Slack adapter that sends rich Block Kit messages. | Use Slack Incoming Webhooks with Block Kit JSON payload using `Req`. |
| NOTIFY-03 | System includes an out-of-the-box Microsoft Teams adapter that sends rich Adaptive Cards. | Use MS Teams Incoming Webhooks with Adaptive Card JSON format using `Req`. |
| NOTIFY-04 | System durably records all dispatched notifications as Timeline Entries on the incident. | Call `Parapet.Spine.TimelineEntry.changeset/2` to insert an entry representing the dispatch result. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Notification Behavior | API / Backend | — | Defines the contract for all outbound communication adapters. |
| HTTP Webhooks | API / Backend | — | Sends Block Kit or Adaptive Card payloads to remote servers via `Req`. |
| Async Dispatch | API / Backend | Database | Prevents blocking the caller; uses Oban (DB-backed) for reliable delivery. |
| Audit Trail | Database / Storage| API / Backend | `Parapet.Spine.TimelineEntry` records all successful/failed notifications. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Req` | `~> 0.5.17` | HTTP Client for adapters | [VERIFIED: npm registry/hex.pm] Standard, batteries-included HTTP client for modern Elixir. Add as `optional: true` dependency. |
| `Oban` | `~> 2.22` | Durable async jobs | [VERIFIED: hex.pm] Already an optional dependency in `mix.exs`. Perfect for retrying webhooks. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Elixir `Task` | Built-in | Fire-and-forget async | Use as a fallback for users who don't configure `Oban` but still need non-blocking notifications. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Req` | `:httpc` | `:httpc` avoids adding an optional dependency, but has poor ergonomics for JSON encoding/decoding and TLS handling compared to `Req`. |

**Installation:**
```bash
# Users will need to add req if they want to use built-in adapters
mix deps.add req --optional
```

## Architecture Patterns

### System Architecture Diagram
```
[Incident Update] --> (Parapet.Notifier.Dispatch)
                             |
                      [Is Oban enabled?]
                       /             \
                    (Yes)           (No)
                     |                |
             [Enqueue Job]     [Task.start/1]
                     |                |
            (Parapet.Notifier.Worker/Adapter)
                     |
              [HTTP Request via Req] --> [Slack/Teams API]
                     |
           (Record TimelineEntry)
```

### Recommended Project Structure
```
lib/parapet/
├── notifier.ex                  # The @behaviour and dispatch logic
├── notifier/
│   ├── slack.ex                 # Slack adapter (Block Kit)
│   ├── teams.ex                 # MS Teams adapter (Adaptive Cards)
│   └── oban_worker.ex           # Oban Worker for durable delivery
```

### Pattern 1: Notifier Behaviour
**What:** Define a standard callback for all notifiers.
**When to use:** To allow users to inject their own adapters (e.g., PagerDuty, Email).
**Example:**
```elixir
defmodule Parapet.Notifier do
  @callback deliver(Parapet.Spine.Incident.t(), keyword()) :: {:ok, term()} | {:error, term()}
end
```

### Anti-Patterns to Avoid
- **Synchronous Notification Dispatch:** NEVER block an incoming web request (like Alertmanager's webhook) to make a slow outgoing Slack API request. Always push to a background job or Task.
- **Missing Audit Records on Failure:** If a Slack webhook returns `429 Too Many Requests`, this must still be recorded in the `TimelineEntry` so operators know the alert wasn't successfully broadcasted.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP Requests | Custom `:httpc` wrappers | `Req` (optional dep) | `Req` handles JSON encoding, retry logic, and TLS securely out of the box. |
| Retries & Backoff | Custom `Process.send_after` | `Oban` | Oban gives persistent backoff, rate limiting, and visibility, preventing alert loss on restart. |

## Common Pitfalls

### Pitfall 1: Leaking Secrets in Timeline Entries
**What goes wrong:** Logging the full HTTP request/response to the `TimelineEntry` might accidentally log the Slack Webhook URL.
**Why it happens:** Blindly storing the `config` or `Req.Response` struct in the Ecto payload.
**How to avoid:** Specifically craft the payload for `TimelineEntry` to only include safe metadata (e.g., `adapter: "slack", status: "success", channel: "#alerts"`).

### Pitfall 2: Silent Failures in Tasks
**What goes wrong:** If a user doesn't use Oban, a `Task.start` that fails due to network issues will die silently.
**Why it happens:** Unlinked tasks do not report errors to the supervisor in a way that generates timeline entries.
**How to avoid:** The `Task` must internally `try/rescue` and record a failure `TimelineEntry` before exiting.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `:hackney` or `HTTPoison` | `Req` | ~2022 | Elixir HTTP clients have largely converged on `Req` for its ease of use and modern foundation on `Finch`/`Mint`. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | [ASSUMED] `Req` can be added as an optional dependency. | Standard Stack | If the project strictly forbids new dependencies, we'd have to use `:httpc`. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Oban | Durable retries | ✓ | ~> 2.22 | Elixir `Task` |
| Req | Outbound Webhooks | ✗ | — | Add as `optional: true` dependency |

**Missing dependencies with fallback:**
- `Req` is currently missing from `mix.exs`. It needs to be added as an optional dependency (or as a regular dependency if preferred by the maintainers) for the adapters to function.
