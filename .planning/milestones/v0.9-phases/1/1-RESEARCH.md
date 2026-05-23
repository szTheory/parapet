# Phase 1: Performance, Scale & DX - Research

**Researched:** 2024-05-19
**Domain:** Observability, Telemetry, Mix Tasks, Elixir Meta-Programming
**Confidence:** HIGH

## Summary

This phase aims to proactively prevent TSDB cardinality explosions, a common failure mode in observability systems, by limiting the number of labels attached to metrics and blocking unsafe label keys (e.g., `user_id`, `token`). 

We will introduce a two-pronged approach:
1. **Dynamic / Config Validation:** Extend the existing `mix parapet.doctor` command to parse all `Parapet.SLO` and `Parapet.SLO.SliceSpec` definitions at static analysis time, detecting unbounded, high-cardinality labels inside PromQL expressions.
2. **Compile-Time Enforcement:** Create an `@after_compile` validation macro for internal metric definitions (`Parapet.Metrics.*`) to statically assert that metrics never exceed a threshold of 10 labels, preventing unbounded cardinality issues from shipping to production.

Currently, all built-in metrics and adapter SLIs strictly adhere to the proposed limit of 10 labels, with the largest having 7. Therefore, the focus is purely on introducing the enforcement boundaries rather than refactoring existing metrics.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Label Validation (Internal Metrics) | Compile-time | — | Metric structures are defined as pure functions, enabling static verification at compile time via `@after_compile` without runtime cost. |
| Configuration Cardinality Scanning | Tooling (Mix Tasks) | — | Application SLOs and slice configurations can be scanned locally or in CI via `mix parapet.doctor`, detecting user misconfigurations before deployment. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir Core | (Project Default) | `@after_compile` macros | Idiomatic approach for static validation of pure functions defined in modules. |
| Regex | (Project Default) | PromQL Parsing | Simplest mechanism to extract labels from PromQL `by (...)` and `{...}` syntax without requiring a full PromQL parser dependency. |

## Architecture Patterns

### Pattern 1: Compile-Time Metric Validation via `@after_compile`
**What:** Leveraging Elixir's compilation hooks to execute module functions immediately after compilation and assert their return values.
**When to use:** Validating module attributes or pure functions (like `metrics/0`) without imposing startup latency or runtime checks.
**Example:**
```elixir
defmodule Parapet.Metrics.Validator do
  defmacro __using__(opts) do
    quote do
      @max_labels Keyword.get(unquote(opts), :max_labels, 10)
      @after_compile __MODULE__

      def __after_compile__(env, _bytecode) do
        metrics = apply(env.module, :metrics, [])
        Enum.each(metrics, fn metric ->
          if length(metric.tags) > @max_labels do
             raise CompileError, description: "Metric #{inspect(metric.name)} exceeds max cardinality limit of #{@max_labels}"
          end
          Parapet.Internal.LabelPolicy.assert_safe!(metric.tags)
        end)
      end
    end
  end
end
```

### Pattern 2: Selective Mix Task Execution
**What:** Updating `Mix.Tasks.Parapet.Doctor` to allow specific check targeting (e.g. `mix parapet.doctor cardinality`).
**When to use:** When static analysis tooling grows and users need to run single checks (e.g. in CI pipelines or pre-commit hooks).
**Example:**
```elixir
def run(args) do
  {opts, checks, _} = OptionParser.parse(args, switches: [ci: :boolean])
  run_all? = checks == []

  results = %{}
  results = if run_all? or "cardinality" in checks, do: Map.put(results, :cardinality, check_cardinality()), else: results
  # ... continue for other checks
end
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Runtime cardinality checks on every event. *Why:* Introduces severe performance bottlenecks. Validation must happen at compile-time or static-analysis time.
- **Anti-pattern:** Depending on a heavy PromQL parsing library. *Why:* Overkill for extracting labels. Simple regexes for `by (...)` and `{...}` block keys are sufficient and keep the dependency tree light.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Label safety rules | A new duplicate validation function | `Parapet.Internal.LabelPolicy` | It already contains the logic (`high_cardinality_key?/1` and `assert_safe!/1`) defining unsafe labels like `id`, `raw_`, `token`. |

## Common Pitfalls

### Pitfall 1: Unhandled `Telemetry.Metrics` Name Types
**What goes wrong:** Attempting to `inspect` or concatenate metric names and crashing the validation hook.
**Why it happens:** Telemetry metric names are defined as lists of atoms (e.g. `[:parapet, :http, :request]`), which cannot be passed to `to_string/1` directly.
**How to avoid:** Always use `inspect(metric.name)` in error messages.

### Pitfall 2: PromQL Regex Misses Empty Tags
**What goes wrong:** Falsely passing PromQL queries with empty `by ()` aggregations.
**Why it happens:** The regex relies on matches inside parentheses.
**How to avoid:** Write regexes to account for standard Prometheus groupings: `~r/by\s*\(([^)]+)\)/` and `~r/\{([^}]+)\}/`. Missing an empty group is actually safe, as empty cardinality is 1.

## Code Examples

### Extracting labels from PromQL in Elixir
```elixir
def extract_labels(query) do
  by_labels =
    Regex.scan(~r/by\s*\(([^)]+)\)/, query)
    |> Enum.flat_map(fn [_, match] -> String.split(match, ",") |> Enum.map(&String.trim/1) end)

  brace_labels =
    Regex.scan(~r/\{([^}]+)\}/, query)
    |> Enum.flat_map(fn [_, match] ->
      String.split(match, ",")
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn kv ->
        case String.split(kv, ~r/(=|!=|=~|!~)/, parts: 2) do
          [k, _] -> String.trim(k)
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
    end)

  Enum.uniq(by_labels ++ brace_labels)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unchecked runtime tags | Compile-time validation | This phase | Guarantees internal metrics never exceed safe limits without paying any runtime penalty. |

## Open Questions
None. The architecture maps perfectly to the requirements.

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | `parapet.doctor` warns on bad labels in SLOs | unit | `mix test test/mix/tasks/parapet.doctor_test.exs` | ✅ Wave 0 |
| REQ-02 | `Parapet.Metrics.Validator` enforces tags limit | unit | `mix test test/parapet/metrics/validator_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/parapet/metrics/validator_test.exs` — covers the compile time limit bounds on a mock module.
