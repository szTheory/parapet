# Phase 30: Registry Decoupling - Research

**Researched:** 2024-05-28
**Domain:** Elixir GenServer, Test Isolation, Application Environment
**Confidence:** HIGH

## Summary

The current test suite struggles with test isolation because `Parapet.SLO` state and `:providers` configuration are mutated globally via `Application.put_env(:parapet, ...)`. Similarly, `Parapet.Capabilities` relies on a globally named `Agent`. This breaks any `async: true` tests that read or modify these subsystems concurrently.

There are currently uncommitted local changes in the repository that partially implement a `Parapet.SLO.Registry` using an ETS-backed test checkout pattern (similar to Ecto Sandbox). This phase must finalize this registry, ensure it tracks test processes correctly to prevent memory leaks, refactor all tests to stop using `Application.put_env`, and extend the isolation pattern to `Parapet.Capabilities` and `:providers`.

**Primary recommendation:** Use ETS with `read_concurrency: true` and a `$callers` test-checkout pattern to provide `async: true` test isolation while avoiding GenServer bottlenecks.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SLO definitions | API / Backend | — | Registry manages memory state for runtime SLOs |
| Recovery capabilities | API / Backend | — | Registry holds callbacks/modules for activated capabilities |
| Test Isolation | API / Backend | — | ETS `$callers` lookup ensures scoped reads/writes |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:ets` | native | In-memory key-value store | Provides `read_concurrency: true` avoiding GenServer message queues |
| `GenServer` | native | Registry lifecycle and monitoring | Allows `Process.monitor/1` to clean up ETS entries on test crash |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:ets` | `Process.put` | Process dictionary only works for `self()`, breaks for spawned `Task` / Oban jobs |
| `Parapet.SLO.Registry` | `Registry` module | Built-in Elixir `Registry` is for PID routing, not global config overriding |

## Package Legitimacy Audit

No external packages installed in this phase.

## Architecture Patterns

### System Architecture Diagram

```
[ExUnit Test] --> (checkout/0) --> [Parapet.SLO.Registry GenServer]
                                        | (Process.monitor)
                                        v
[ExUnit Test] --> (store/all) ---> [ETS Table]
                                        | (read_concurrency: true)
[Application.get_env] <-----------------+ (fallback for providers)
```

### Pattern 1: Ecto-Sandbox Style Test Checkout
**What:** Test processes explicitly register themselves, and the registry uses `$callers` to map spawned tasks back to the test.
**When to use:** When modifying globally-visible state in `async: true` tests.
**Example:**
```elixir
def checkout do
  GenServer.call(__MODULE__, {:checkout, self()})
end

defp find_checkout_pid do
  pids = [self() | Process.get(:"$callers", [])]
  Enum.find(pids, fn pid ->
    case :ets.lookup(__MODULE__, {:checkout, pid}) do
      [{_, true}] -> true
      _ -> false
    end
  end)
end
```

### Pattern 2: Read-Through Configuration
**What:** `Parapet.SLO.provider_catalog/0` checks the registry for a test override; if none, it falls back to `Application.get_env`.
**When to use:** For static configurations that only need mutation during testing.

### Anti-Patterns to Avoid
- **Agent for global state:** `Parapet.Capabilities` uses a globally named Agent, which causes the exact same test collisions as `Application.put_env`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Process family tracking | Custom tree walking | `Process.get(:"$callers")` | `Task` and `GenServer` automatically populate `$callers`. |

**Key insight:** Ecto has already solved the "find the test process from a spawned task" problem using `$callers`. We should emulate it directly.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `Parapet.SLO.Registry` ETS table | Finalize `$callers` checkout pattern, add `delete/1`, and `Process.monitor` |
| Stored data | `Parapet.Capabilities` Agent | Convert to ETS checkout pattern or merge into a unified Registry |
| Live service config | `Application.get_env(:parapet, :slos)` | Remove usage entirely. `SLO.all/0` uses Registry. |
| Live service config | `Application.get_env(:parapet, :providers)` | Keep for runtime, but override via Registry in tests. |
| OS-registered state | None — verified | none |
| Secrets/env vars | None — verified | none |
| Build artifacts | None — verified | none |

## Common Pitfalls

### Pitfall 1: ETS Memory Leaks in Tests
**What goes wrong:** A test crashes or exits naturally, but its `{:checkout, pid}` state stays in ETS forever.
**Why it happens:** The registry `checkout/0` only inserts into ETS without monitoring the test process.
**How to avoid:** `GenServer.call/3` for checkout must `Process.monitor(pid)`. Then handle `{:DOWN, ...}` to `ets.match_delete` all entries tied to that test PID.

### Pitfall 2: Forgetting to Migrate `Parapet.Capabilities`
**What goes wrong:** SLO test isolation is fixed, but the suite still flakes on capability tests.
**Why it happens:** `Parapet.Capabilities` uses a globally named `Agent` and wasn't included in the ETS migration.
**How to avoid:** Ensure `Parapet.Capabilities` adopts the exact same checkout pattern.

## Code Examples

### Monitoring Test Processes (Cleanup)
```elixir
def handle_call({:checkout, pid}, _from, state) do
  Process.monitor(pid)
  :ets.insert(__MODULE__, {{:checkout, pid}, true})
  {:reply, :ok, state}
end

def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
  :ets.match_delete(__MODULE__, {{:test, pid, :_}, :_})
  :ets.delete(__MODULE__, {:checkout, pid})
  {:noreply, state}
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Application.put_env` | Registry + ETS `$callers` | v1.2 | `async: true` tests can run without colliding. |

## Assumptions Log

If this table is empty: All claims in this research were verified or cited — no user confirmation needed.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)

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
| REQ-01 | All tests run async without flakes | integration | `mix test` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements, but many files need `async: false` removed.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | — |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom exhaustion | Denial of Service | Do not dynamically convert user input to atoms |

## Sources

### Primary (HIGH confidence)
- Codebase inspection of `test/mix/tasks/parapet.gen.grafana_test.exs` and `lib/parapet/slo/registry.ex`.
- Ecto Sandbox documentation (standard Elixir test isolation pattern).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ETS with `$callers` is the standard BEAM answer.
- Architecture: HIGH - Registry read-through allows static config + test overrides.
- Pitfalls: HIGH - Monitored ETS cleanup is a known strict requirement for this pattern.

**Research date:** 2024-05-28
**Valid until:** 30 days