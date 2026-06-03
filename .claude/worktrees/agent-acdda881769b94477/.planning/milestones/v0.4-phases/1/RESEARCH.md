# Phase 1: SRE Telemetry Translation - Research

**Researched:** 2026-05-12
**Domain:** Elixir Telemetry, Prometheus Metrics, Code Scaffolding via Igniter
**Confidence:** HIGH

## Summary

This phase integrates Parapet with the Scoria AI library by safely parsing `Scoria.SRE.Telemetry` events. We will implement `Parapet.Integrations.Scoria` to serve as the telemetry consumption seam, translating low-cardinality metadata into Prometheus metrics and routing severe AI failures to durable Ecto Incidents via `Parapet.Evidence`. We will also implement a dedicated `mix parapet.gen.scoria` generator that scaffolds a standalone Grafana dashboard and conditionally composes into `mix parapet.install`.

**Primary recommendation:** Use `Parapet.Integrations.Scoria` to translate events, filter out high-cardinality refs (like `trace_id`), and implement an Igniter-based `mix parapet.gen.scoria` task that `parapet.install` can compose with `--with-scoria`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AI-TELEMETRY-01 | System consumes Scoria's `Scoria.SRE.Telemetry` events and translates them into Parapet Prometheus metrics and durable Ecto Incidents. | Handled via `Parapet.Integrations.Scoria` and `:telemetry.attach/4`, delegating to `Parapet.Evidence.create_incident/1`. |
| AI-TELEMETRY-02 | System provides `scoria_llm_token_count_total`, `scoria_llm_cost_usd`, and `scoria_llm_time_to_first_token_ms` in Grafana out-of-the-box. | Generator task `mix parapet.gen.scoria` will scaffold a standalone `scoria_dashboard.json` and Prometheus rules file. |
| AI-TELEMETRY-03 | System enforces a strict label policy that filters high-cardinality refs (like `trace_id`) from metrics labels, strictly splitting labels and refs. | Inside `Parapet.Integrations.Scoria`, the telemetry event payload will be parsed to explicitly extract low-cardinality labels before emitting `:telemetry.execute([:parapet, ...])` events. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SRE Telemetry Consumption | API / Backend | — | Elixir `:telemetry` handlers run in the backend application memory space. |
| Durable Incidents | API / Backend | Database | Extracted anomalies trigger Ecto Repo inserts via `Parapet.Evidence`. |
| Scaffolding / Code Gen | Build / Tooling | — | Mix tasks utilizing `Igniter` to modify AST and place standalone JSON files. |
| Dashboarding | Tooling | Grafana | Standalone JSON file provisioning follows the Parapet "host-owned" ethos. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `igniter` | Current | AST manipulation and scaffolding | Official Parapet code-gen foundation. Provides composable generator tasks. |
| `:telemetry` | Current | In-memory event routing | Native Erlang/Elixir standard for decoupled event publishing. |
| `ecto` | Current | Persistence | Used via `Parapet.Evidence` for tracking durable AI anomalies. |

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── parapet/
│   ├── integrations/
│   │   └── scoria.ex           # Telemetry translation adapter
├── mix/
│   ├── tasks/
│   │   └── parapet.gen.scoria.ex # Scoria generator task
priv/
├── templates/
│   └── parapet.gen.scoria/
│       ├── scoria_dashboard.json.eex
│       └── rules.yml.eex
```

### Pattern 1: Sibling Library Telemetry Adapter
**What:** Consuming sibling library telemetry safely and forwarding to internal metrics channels.
**When to use:** Integrating external libraries like Chimeway, Mailglass, or Scoria.
**Example:**
```elixir
defmodule Parapet.Integrations.Scoria do
  require Logger

  def setup do
    :telemetry.attach(
      "parapet-scoria-sre-telemetry",
      [:scoria, :sre, :telemetry],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(event, measurements, metadata, _config) do
    # Strip high cardinality refs here
    safe_labels = Map.take(metadata, [:model, :provider, :tool_name])
    
    :telemetry.execute(
      [:parapet, :scoria, :metrics],
      measurements,
      safe_labels
    )
    
    # Example: Create an incident on error
    if metadata[:error] do
      Parapet.Evidence.create_incident(%{
        title: "AI Tool Failure: #{metadata[:tool_name]}",
        description: inspect(metadata[:error])
      })
    end
  rescue
    e ->
      Logger.error("Parapet telemetry handler exception: #{Exception.message(e)}")
  end
end
```

### Pattern 2: Composable Generators in `mix parapet.install`
**What:** Invoking optional external generators if flags are passed.
**When to use:** Expanding the Parapet installer.
**Example:**
```elixir
with_scoria? = igniter.args.options[:with_scoria] || false

igniter = 
  if with_scoria? do
    Igniter.compose_task(igniter, "parapet.gen.scoria", [])
  else
    igniter
  end
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Editing `main_dashboard.json` dynamically via the generator. 
  *Fix:* Parapet DNA mandates standalone domain-specific dashboards (`scoria_dashboard.json`) so users can modify their `main_dashboard` freely without generator conflicts.
- **Anti-pattern:** Parsing raw OpenInference OTel spans. 
  *Fix:* Only consume the explicit `Scoria.SRE.Telemetry` event, which comes pre-sanitized for SRE use.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Creating durable anomalies | Direct Ecto `Repo.insert` | `Parapet.Evidence.create_incident/1` | Enforces structural constraints and schema validation boundaries. |
| AST injection | Regex / String replacement | `Igniter` / `Sourceror` | Parapet relies on Igniter's AST zipper for safe, deterministic `ParapetInstrumenter` modifications. |
| Custom Telemetry parsing | Raw OTel | `Scoria.SRE.Telemetry` | The Scoria project explicitly provides a pre-formatted SRE channel to avoid parser bloat. |

**Key insight:** Scoria is an AI-first sibling. Its primary abstractions operate with high cardinality contexts (traces, prompts). SRE needs strict bounded cardinality (models, tool names, outcomes). The translation layer (`Parapet.Integrations.Scoria`) must enforce this boundary rigorously.

## Common Pitfalls

### Pitfall 1: High Cardinality Label Leaks
**What goes wrong:** `trace_id` or `run_id` strings sneak into the Prometheus labels.
**Why it happens:** Passing the raw `metadata` map from `Scoria.SRE.Telemetry` directly into the Parapet metric execution.
**How to avoid:** Define an explicit safelist of labels (e.g., `model`, `tool_name`, `provider`) and `Map.take/2` before forwarding to the metrics pipeline.

### Pitfall 2: Missing Optional Dependency Safety
**What goes wrong:** `mix parapet.install` crashes if Scoria is not installed but `--with-scoria` is passed.
**Why it happens:** Code unconditionally calls `Parapet.Integrations.Scoria.setup()`.
**How to avoid:** The generated host `ParapetInstrumenter` must wrap the call in `if Code.ensure_loaded?(Parapet.Integrations.Scoria)`.

## Code Examples

### Modifying the Host Instrumenter
The AST generator should create a setup similar to:
```elixir
def setup do
  if Code.ensure_loaded?(Parapet.Integrations.Scoria) do
    Parapet.Integrations.Scoria.setup()
  end
  # other handlers...
  :ok
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unified dashboards | Standalone JSON dashboards | v0.4 (Scoria Integration) | Generators won't destroy user modifications. PromEx-like architecture. |

## Open Questions

1. **Dashboard Alert Linkage**
   - What we know: Scoria dashboard will be created.
   - What's unclear: Should it automatically link AI-HITL (Workflow Pauses) to Parapet's UI?
   - Recommendation: Follow up in Phase 4 when building HITL integrations. For Phase 1, strictly translate RED metrics.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AI-TELEMETRY-01 | Emits events & inserts incidents | unit | `mix test test/parapet/integrations/scoria_test.exs` | ❌ Phase 1 |
| AI-TELEMETRY-02 | Generates standalone dashboard | unit | `mix test test/mix/tasks/parapet.gen.scoria_test.exs` | ❌ Phase 1 |
| AI-TELEMETRY-03 | Enforces label policy (no traces) | unit | `mix test test/parapet/integrations/scoria_test.exs` | ❌ Phase 1 |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `Elixir` | App Runtime | ✓ | >= 1.15 | — |
| `Mix` | Build / CLI | ✓ | — | — |

**Missing dependencies with no fallback:**
- None.

## Sources

### Primary (HIGH confidence)
- `parapet/.planning/research/PHASE-1-SCORIA-DECISIONS.md` - Verified architecture decisions for Scoria telemetry integration and standalone dashboard strategy.
- `parapet/.planning/memory/scoria-v1.3-context.md` - Verified requirement to use `Scoria.SRE.Telemetry`.
- `lib/parapet/integrations/chimeway.ex` - Verified standard Parapet adapter pattern implementation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows existing Parapet `Igniter` & `:telemetry` implementation logic.
- Architecture: HIGH - Dictated explicitly by `PHASE-1-SCORIA-DECISIONS.md`.
- Pitfalls: HIGH - High-cardinality leakage is specifically called out in memory contexts.
