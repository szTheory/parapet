<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SLO-01 | `Parapet.SLO.define/2` produces valid PromQL rules | Generate multi-window burn-rate templates as Prometheus-compatible YAML. |
| SLO-02 | PromQL uses correct rate logic | Use `sum(rate(good[w])) / sum(rate(total[w]))` instead of `rate(sum(...))`. |
| AUTH-01 | Emits `parapet.journey.login` telemetry | Attach to `[:sigra, :auth, :login, :stop]` and exceptions, then emit custom telemetry with `:outcome`. |
| AUTH-02 | Optional `:sigra` compilation | Wrap `Parapet.Integrations.Sigra` in `if Code.ensure_loaded?(Sigra)`. |
| DOC-01 | `mix parapet.doctor` checks runbooks | CLI task that iterates SLOs and exits code 2 if `runbook:` is missing. |
| DEP-01 | `Parapet.Deploy.mark/1` correlates events | Emit deploy markers for Grafana vertical annotations. |
</phase_requirements>

# Phase 3: SLO DSL, Login Journey, and Deploy Markers - Research

**Researched:** 2026-05-09
**Domain:** Elixir Telemetry, Prometheus Alerting Rules, Sigra Integration
**Confidence:** HIGH

## Summary

This phase introduces the core Service-Level Objective (SLO) definitions and integrates the first business-critical journey: user login via Sigra. The SLO DSL will generate Prometheus recording and alerting rules based on multi-window burn-rate logic. To avoid common pitfalls with Prometheus PromQL, the generated queries must calculate ratios after the rate computation (`sum(rate(good[w])) / sum(rate(total[w]))`).

The login journey telemetry will conditionally integrate with Sigra by listening to the `[:sigra, :auth, :login, :stop]` and `[:sigra, :auth, :login, :exception]` events natively emitted by the library. When Sigra is not loaded, the module will compile out cleanly. Deploy markers will be implemented via an API that emits annotations with a monotonic sequence, which Grafana can pick up to overlay on SLO charts.

**Primary recommendation:** Build `Parapet.SLO` to generate exact PromQL YAML via EEx templates, implement `Parapet.Integrations.Sigra` with `Code.ensure_loaded?(Sigra)`, and write a `mix parapet.doctor` task to validate runbook presence.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SLO PromQL Generation | Build / CLI | — | Generated as static YAML files to be ingested by Prometheus (`promtool check rules`). |
| Sigra Login Telemetry | API / Backend | — | `Parapet.Integrations.Sigra` subscribes to Sigra auth events natively at runtime. |
| Deploy Markers | API / Backend | Metrics/DB | Emits timestamped events/metrics that Grafana ingests as annotations. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `sigra` | ~> 1.20 | Auth | Target integration library; emits native `[:sigra, :auth, :login, :stop]` events. |
| `telemetry` | ~> 1.2 | Event tracking | Unified pipeline for transforming Sigra events to Parapet SLO events. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/
├── parapet/
│   ├── slo.ex               # DSL for defining SLOs (`Parapet.SLO.define/2`)
│   ├── slo/
│   │   └── generator.ex     # Generates PromQL YAML
│   ├── deploy.ex            # Deploy markers API (`Parapet.Deploy.mark/1`)
│   └── integrations/
│       └── sigra.ex         # Optional Sigra integration for login journey
```

### Pattern 1: Optional Integration (Sigra)
**What:** Listen to `[:sigra, :auth, :login, :stop]` (and exceptions) without crashing if Sigra is missing.
**When to use:** Integrating external ecosystem sibling libraries (PKG-02).
**Example:**
```elixir
if Code.ensure_loaded?(Sigra) do
  defmodule Parapet.Integrations.Sigra do
    def attach do
      :telemetry.attach_many(
        "parapet-sigra-login",
        [
          [:sigra, :auth, :login, :stop],
          [:sigra, :auth, :login, :exception]
        ],
        &__MODULE__.handle_event/4,
        nil
      )
    end
    
    def handle_event([:sigra, :auth, :login, state], measurements, metadata, _config) do
      outcome = if state == :stop, do: :success, else: :failure
      :telemetry.execute([:parapet, :journey, :login], %{duration_ms: measurements.duration}, %{outcome: outcome})
    end
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Burn-rate logic | Custom math | Prometheus standard multi-window | Proven math to catch fast/slow burns correctly. |
| PromQL yaml generation | Dynamic string concatenation | EEx templates | YAML indentation is extremely error-prone. |

## Common Pitfalls

### Pitfall 1: PromQL Rate Ratio Order
**What goes wrong:** Using `rate(sum(good) / sum(total))` or `rate(sum(good))` which fails across counter resets or instance restarts.
**Why it happens:** Rate must be applied to the raw monotonic counter before aggregation.
**How to avoid:** Always generate `sum(rate(good[w])) / sum(rate(total[w]))`.

### Pitfall 2: Missing Runbooks
**What goes wrong:** Alerts fire but engineers do not know how to remediate them.
**How to avoid:** `mix parapet.doctor` statically validates that every SLO definition includes a `runbook:` URL and exits with code 2.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` and `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SLO-01 | SLO YAML matches Prometheus specs | unit | `mix test test/parapet/slo_test.exs` | ❌ Wave 0 |
| SLO-02 | PromQL uses correct rate formula | unit | `mix test test/parapet/slo_test.exs` | ❌ Wave 0 |
| AUTH-01 | Sigra handler converts events | unit | `mix test test/parapet/integrations/sigra_test.exs` | ❌ Wave 0 |
| DOC-01 | Doctor task exits 2 on missing runbook | integration | `mix test test/mix/tasks/parapet.doctor_test.exs` | ❌ Wave 0 |
| DEP-01 | Deploy marker increments monotonically | unit | `mix test test/parapet/deploy_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/parapet/slo_test.exs` - Validating PromQL strings via snapshot test
- [ ] `test/parapet/integrations/sigra_test.exs` - Simulating Sigra events
- [ ] `test/mix/tasks/parapet.doctor_test.exs` - Testing CLI exit codes
- [ ] `test/parapet/deploy_test.exs`
