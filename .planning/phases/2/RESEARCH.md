# Phase 2 Research: Eval-Driven SLOs (`Parapet.SLO.ScoriaEval`)

## Executive Summary
This document provides a deep-dive architectural and implementation recommendation for Phase 2 of Parapet, focusing on Eval-Driven SLOs. The goal is to allow operators to define, monitor, and alert on system objectives derived from Scoria AI evaluation pass rates.

Drawing heavily from modern SRE ecosystems (Sloth, Pyrra, OpenSLO), Elixir idiomatic design (Ecto, Plug, PromEx), and Parapet's core design tenets ("Reliability layer, not backend," "Safe defaults," "Operator-grade DX"), this document outlines the best-in-class path forward.

---

## 1. API & DSL Design for `Parapet.SLO.ScoriaEval`

We need a way for host application developers to define Scoria-backed SLOs that seamlessly integrate with Parapet's existing `Parapet.SLO` system, without feeling like "observability soup." 

### Evaluated Approaches

#### Approach A: Macro-Based DSL (The "Router" approach)
```elixir
defmodule MyApp.SLOs do
  use Parapet.SLO.Catalog

  scoria_eval :hallucination_rate do
    objective 99.5
    guardrail :factuality
    runbook "https://runbooks/ai-01"
  end
end
```
**Pros:** 
- Highly declarative, easy to read for non-Elixir operators.
- Looks like `Ecto.Schema` or `Phoenix.Router`.
**Cons:** 
- Macros hide implementation details and make dynamic SLO generation (e.g., from a database or config file) very difficult. 
- Violates Parapet's "host-owned and composable" constraint by introducing hidden magic.

#### Approach B: Plug-Style Options List
```elixir
config :my_app, Parapet,
  slos: [
    {Parapet.SLO.ScoriaEval, name: :hallucination_rate, objective: 99.5, guardrail: :factuality}
  ]
```
**Pros:** 
- Very easy to configure statically. 
**Cons:** 
- Lacks compile-time validation of configuration properties.
- Not very extensible if we need to add complex grouping/filtering logic later.

#### Approach C: Struct/Data-First (The "PromEx / Telemetry" approach)
```elixir
defmodule MyApp.SLOs do
  @behaviour Parapet.SLO.Provider

  def slos do
    [
      Parapet.SLO.ScoriaEval.new(
        name: :factuality_pass_rate,
        objective: 99.5,
        guardrail: :factuality,
        runbook: "https://runbooks/ai-01"
      )
    ]
  end
end
```
**Pros:**
- **Idiomatic:** Closely aligns with how `PromEx` plugins, `Telemetry.Metrics`, and `Oban` queues are defined.
- **Composable:** Developers can map over a list of guardrails to generate SLOs dynamically.
- **Type-safe:** `new/1` can validate arguments and return a well-formed struct, catching errors early.
**Cons:**
- Slightly more boilerplate than a macro, but worth the tradeoff for explicitness.

### Recommended Approach: Data-First Structs
We strongly recommend **Approach C**. This directly aligns with the existing `Parapet.SLO.define/2` logic but extends it beautifully. Parapet should introduce a `Parapet.SLO.Provider` behaviour (similar to PromEx) where users return lists of SLO structs, moving away from relying solely on `Application.put_env/get_env` at runtime to a more deterministic, explicit registry.

#### Concrete Code Example
```elixir
# In lib/parapet/slo/scoria_eval.ex
defmodule Parapet.SLO.ScoriaEval do
  @enforce_keys [:name, :objective, :guardrail, :runbook]
  defstruct [:name, :objective, :guardrail, :runbook, :labels]

  @doc "Builds an SLO struct specifically for Scoria evaluation metrics, generating PromQL under the hood."
  def new(opts) do
    # Validates and constructs the struct...
    struct!(__MODULE__, opts)
  end
  
  def to_slo(%__MODULE__{} = eval) do
    # Translates the ScoriaEval struct into the canonical Parapet.SLO shape
    # that generates Prometheus recording/alerting rules.
    labels_str = format_labels(eval.labels)
    
    %Parapet.SLO{
      name: eval.name,
      objective: eval.objective,
      # Maps to Telemetry metrics emitted by Scoria
      good_events: "sum(rate(scoria_evaluation_total{guardrail=\"#{eval.guardrail}\", passed=\"true\"#{labels_str}}[window]))",
      total_events: "sum(rate(scoria_evaluation_total{guardrail=\"#{eval.guardrail}\"#{labels_str}}[window]))",
      runbook: eval.runbook
    }
  end
end
```

---

## 2. Mapping Events to Prometheus natively (Cardinality Footguns)

Scoria evaluates outputs and emits telemetry (e.g., `[:scoria, :eval, :completed]`). 

### Lessons from PromEx and OpenTelemetry
- **The Cardinality Footgun:** Do **not** put `user_id`, `trace_id`, `prompt_hash`, or `completion_id` in the Prometheus metric labels. Doing so will blow up the Prometheus TSDB, causing massive memory spikes and OOMing the observability cluster.
- **The Ratio Math Footgun:** If we just calculate `good / total` over a 5m window, we suffer from the "low volume alert" problem. If the AI is used 1 time at 2 AM and fails, the error rate is 100%, and the on-call engineer gets paged for a non-issue. 

### Implementation Strategy for Parapet
1. **Low-Cardinality Metrics:** Parapet's metrics bridge (likely wrapping `:telemetry.attach`) should convert Scoria events into Prometheus counters with strict, bounded dimensions:
   ```elixir
   counter("scoria.evaluation.total", tags: [:guardrail, :passed, :model_name])
   ```
2. **Burn Rate Alerting (The Sloth/Pyrra Lesson):**
   Instead of basic threshold alerting (e.g., `error_rate > 5%`), Parapet should generate **multi-window, multi-burn-rate** recording and alerting rules.
   - Parapet will take the `Parapet.SLO.ScoriaEval` definition and generate a Grafana/Prometheus `.yml` rule file containing Sloth-style Burn Rate equations.
   - This means generating short windows (5m, 30m) for critical paging alerts and long windows (6h, 3d) for ticketing.
3. **Event-to-Metric Bridge:**
   Parapet will provide a PromEx plugin specifically for Scoria: `Parapet.Metrics.Scoria`. When enabled, it listens to `[:scoria, :eval, :completed]` and emits the counters safe for SLO ratios.

---

## 3. DX and Ergonomics: Avoiding "Observability Soup"

"Observability Soup" happens when developers must maintain Telemetry definitions, PromEx plugins, SLO configurations, and Grafana dashboards in 4 different places.

### The Ideal Configuration Block
The host app developer should define their SLOs centrally, and Parapet handles the compilation down to the underlying layers.

```elixir
# lib/my_app/observability.ex
defmodule MyApp.Observability do
  use Parapet.Provider

  def slos do
    [
      # Standard HTTP SLO
      Parapet.SLO.HTTP.new(
        name: :api_availability,
        objective: 99.9,
        route: "/api/*",
        runbook: "https://wiki/api-down"
      ),
      
      # Phase 2: Eval-Driven SLOs
      Parapet.SLO.ScoriaEval.new(
        name: :ai_factuality_rate,
        objective: 99.0,
        guardrail: :factuality,
        labels: [model_name: "gpt-4-turbo"],
        runbook: "https://wiki/ai-hallucination"
      ),
      Parapet.SLO.ScoriaEval.new(
        name: :ai_toxicity_rate,
        objective: 99.99,
        guardrail: :toxicity,
        runbook: "https://wiki/ai-toxicity"
      )
    ]
  end
end
```

**Ergonomic Wins:**
- **Centralization:** All reliability definitions live in one module.
- **Mix Task Generators:** The developer runs `mix parapet.gen.prometheus` and Parapet compiles `MyApp.Observability.slos()` into the necessary PromQL recording/alerting `.yml` files to be ingested by Prometheus.
- **No Magic:** The user commits the generated `.yml` rules to their repo. It is "host-owned," entirely transparent, and compatible with standard GitOps/SRE workflows.

---

## 4. Ecosystem Lessons (Sloth, Pyrra, OpenSLO)

We must learn from successful tools in the Go/K8s ecosystem. 

- **Sloth / Pyrra (What they did right):** They abstract the incredibly complex PromQL required for Error Budget Burn Rate alerting. Writing burn rate PromQL by hand is error-prone. Parapet must serve this exact purpose for Elixir: abstracting the math while outputting standard Prometheus rules. 
- **Sloth (What to adapt):** Sloth uses K8s Custom Resource Definitions (CRDs). In Elixir, we don't need CRDs; we have Elixir code as our source of truth. We can generate Prometheus rules at compile-time or via a Mix task. 
- **Footguns to Avoid:** 
  - *Hardcoding Alert Receivers:* Do not hardcode PagerDuty or Slack webhooks inside the SLO definition. Emitting standard Prometheus alerts allows the host's existing Alertmanager to route alerts based on labels. 
  - *Assuming all traffic is equal:* Scoria evaluations might be asynchronous (background jobs) or synchronous. The SLO system must only care about the telemetry events, keeping Parapet decoupled from *how* Scoria was invoked.

---

## 5. Cohesive Final Recommendation / Blueprint

To implement Phase 2 optimally, follow this blueprint:

### Step 1: Core Domain Expansion
- Update `Parapet.SLO` to define a `__behaviour__` or standard protocol for SLOs so different types (HTTP, Oban, ScoriaEval) can implement `to_slo/1` to produce canonical `good_events / total_events` math.
- Create `Parapet.SLO.ScoriaEval` leveraging an Ecto-like `defstruct` and `new/1` constructor with strict validation.

### Step 2: Telemetry to Metrics Pipeline
- Implement a lightweight metrics wrapper in Parapet (or instructions for the PromEx plugin) that binds to `[:scoria, :eval, :completed]`.
- Define explicit, safe tag keys (`[:guardrail, :passed, :model]`). Prevent users from injecting raw prompt IDs into tags. 
- Store high-cardinality context (like trace IDs and exact prompts) in an evidence store (e.g., `Threadline` integration), linked by a request ID, **not** in Prometheus.

### Step 3: Mix Task Generation (The SRE Paved Road)
- Expand `mix parapet.gen.prometheus` to interpret `Parapet.SLO.ScoriaEval` structs.
- Use the Google SRE handbook multi-burn-rate methodology to output Prometheus alerting rules that trigger when the Error Budget drops too fast.
  - Generates recording rules: `slo:scoria_evaluation:ratio_rate5m`, `slo:scoria_evaluation:ratio_rate1h`, etc.
  - Generates alerting rules: `ScoriaFactualityBurnRateTooFast`.

### Step 4: The Developer Workflow
1. Developer defines the SLO in their Elixir provider.
2. Developer runs `mix parapet.gen.prometheus`.
3. The generated rules are loaded into the host's Prometheus instance.
4. Grafana reads the standard metric names to visualize AI stability automatically.

By relying on explicit data structures, safe telemetry cardinality, and code-generated Prometheus rules, Parapet guarantees a robust, scalable, and idiomatically pristine experience for Elixir teams operating AI in production.