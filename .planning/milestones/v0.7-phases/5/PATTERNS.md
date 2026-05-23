# Phase 5: Built-In Async & Delivery SLOs - Pattern Map

**Mapped:** 2026-05-17
**Files analyzed:** 10
**Analogs found:** 9 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/slo/mailglass_delivery.ex` | provider | transform | `lib/parapet/slo/scoria_eval.ex` + `lib/parapet/slo/provider.ex` | partial-match |
| `lib/parapet/slo/chimeway_delivery.ex` | provider | transform | `lib/parapet/slo/scoria_eval.ex` + `lib/parapet/slo/provider.ex` | partial-match |
| `lib/parapet/slo/rindle_async.ex` | provider | transform | `lib/parapet/slo/scoria_eval.ex` + `lib/parapet/slo/provider.ex` | partial-match |
| `lib/parapet/slo.ex` | service | request-response | `lib/parapet/slo.ex` | exact |
| `lib/parapet/slo/provider.ex` | behavior | interface | `lib/parapet/slo/provider.ex` | exact |
| `lib/mix/tasks/parapet.gen.prometheus.ex` | generator-task | file-I/O | `lib/mix/tasks/parapet.gen.prometheus.ex` | exact |
| `priv/templates/parapet.gen.prometheus/rules.yml.eex` | template | transform | `priv/templates/parapet.gen.prometheus/rules.yml.eex` | exact |
| `test/mix/tasks/parapet.gen.prometheus_test.exs` | test | file-I/O | `test/mix/tasks/parapet.gen.prometheus_test.exs` | exact |
| `test/parapet/slo/*_test.exs` | test | transform | `test/parapet/slo_test.exs` + `test/parapet/slo/scoria_eval_test.exs` | role-match |
| `lib/parapet/metrics/*async_delivery*.ex` | metrics | event-driven | no direct analog; consume `lib/parapet/telemetry/async_delivery.ex` contract | no-analog |

## Pattern Assignments

### `lib/parapet/slo/mailglass_delivery.ex`, `lib/parapet/slo/chimeway_delivery.ex`, `lib/parapet/slo/rindle_async.ex`

**Use this shape for all three new provider modules.**

**Behavior declaration** from `lib/parapet/slo/provider.ex` lines 1-7:
```elixir
defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for providing SLOs to the Parapet system.
  """

  @callback slos() :: [struct()]
end
```

**Provider aggregation seam** from `lib/parapet/slo.ex` lines 62-70:
```elixir
def all do
  legacy_slos = Application.get_env(:parapet, :slos, [])

  provider_slos =
    Application.get_env(:parapet, :providers, [])
    |> Enum.flat_map(fn provider -> provider.slos() end)
    |> Enum.map(&Parapet.SLO.Resolvable.to_slo/1)

  legacy_slos ++ provider_slos
end
```

**Data-first custom struct + validation** from `lib/parapet/slo/scoria_eval.ex` lines 6-45:
```elixir
@enforce_keys [:name, :objective, :guardrail, :runbook]
defstruct [:name, :objective, :guardrail, :runbook, labels: %{}]

def new(opts) do
  name = Keyword.get(opts, :name)
  objective = Keyword.get(opts, :objective)
  guardrail = Keyword.get(opts, :guardrail)
  runbook = Keyword.get(opts, :runbook)
  labels = Keyword.get(opts, :labels, %{})

  missing =
    []
    |> append_if_missing(objective, :objective)
    |> append_if_missing(guardrail, :guardrail)
    |> append_if_missing(runbook, :runbook)
    |> Enum.reverse()

  if missing != [] do
    raise ArgumentError, "missing required fields for ScoriaEval #{name}: #{inspect(missing)}"
  end

  %__MODULE__{name: name, objective: objective, guardrail: guardrail, runbook: runbook, labels: labels}
end
```

**Resolvable conversion** from `lib/parapet/slo/scoria_eval.ex` lines 51-68:
```elixir
defimpl Parapet.SLO.Resolvable, for: Parapet.SLO.ScoriaEval do
  def to_slo(eval) do
    labels_str = format_labels(eval.labels)

    good_events =
      "sum(rate(scoria_evaluation_total{guardrail=\"#{eval.guardrail}\", passed=\"true\"#{labels_str}}[window]))"

    total_events =
      "sum(rate(scoria_evaluation_total{guardrail=\"#{eval.guardrail}\"#{labels_str}}[window]))"

    %Parapet.SLO{
      name: eval.name,
      objective: eval.objective,
      good_events: good_events,
      total_events: total_events,
      runbook: eval.runbook
    }
  end
end
```

**Planner guidance:** prefer providers that return a small catalog of structs or `%Parapet.SLO{}` values via `slos/0`. Use custom structs only if the generator needs richer alert metadata than the current `%Parapet.SLO{}` fields can carry.

---

### `lib/parapet/slo.ex`

**Keep backward-compatible aggregation, but keep Phase 5 blessed path provider-first.**

**Legacy define/store compatibility** from `lib/parapet/slo.ex` lines 29-57:
```elixir
@deprecated "Use a Parapet.SLO.Provider module instead"
def define(name, opts) do
  ...
  slo = %__MODULE__{
    name: name,
    objective: objective,
    good_events: good_events,
    total_events: total_events,
    runbook: runbook
  }

  store(slo)
  slo
end
```

**Provider merge test** from `test/parapet/slo_test.exs` lines 47-83:
```elixir
defmodule DummyProvider do
  @behaviour Parapet.SLO.Provider

  def slos do
    [
      %Parapet.SLO{
        name: :provider_slo,
        objective: 99.0,
        good_events: "provider_good",
        total_events: "provider_total",
        runbook: "provider_runbook"
      }
    ]
  end
end

Application.put_env(:parapet, :providers, [DummyProvider])
all_slos = SLO.all()
```

**Planner guidance:** Phase 5 should preserve `legacy_slos ++ provider_slos` unless there is a compelling migration step. New built-ins should come through `:providers`, not through `register/1` mutation.

---

### `lib/mix/tasks/parapet.gen.prometheus.ex`

**Keep the generator task thin and host-owned.**

**Exact analog** from `lib/mix/tasks/parapet.gen.prometheus.ex` lines 15-33:
```elixir
alias Parapet.SLO

@impl Igniter.Mix.Task
def igniter(igniter) do
  slos = SLO.all()

  windows = ["5m", "30m", "1h", "2h", "6h", "3d"]

  template_path =
    Application.app_dir(:parapet, "priv/templates/parapet.gen.prometheus/rules.yml.eex")

  yaml_content = EEx.eval_file(template_path, slos: slos, windows: windows)

  Igniter.create_new_file(
    igniter,
    "priv/parapet/prometheus/rules.yml",
    yaml_content
  )
end
```

**Counterexample to avoid** from `lib/mix/tasks/parapet.gen.grafana.ex` lines 18-28:
```elixir
def igniter(igniter) do
  # Register built-in SLOs
  SLO.HTTP.register()

  if Code.ensure_loaded?(Oban) do
    SLO.Oban.register()
  end

  SLO.LoginJourney.register()

  slos = SLO.all()
```

**Planner guidance:** follow the Prometheus task, not the Grafana task. Phase 5 explicitly wants `mix parapet.gen.prometheus` to render from active providers only, with no hidden built-in activation.

---

### `priv/templates/parapet.gen.prometheus/rules.yml.eex`

**Reuse the current “iterate over SLO catalog in EEx” shape, but expect richer slice-aware output.**

**Template loop pattern** from `priv/templates/parapet.gen.prometheus/rules.yml.eex` lines 1-15:
```eex
groups:
<%= for slo <- slos do %>
  - name: parapet_slo_<%= slo.name %>
    rules:
<%= for window <- windows do %>
      - record: slo:error_ratio:rate<%= window %>
        expr: >
          1 - (
            sum(rate(<%= slo.good_events %>[<%= window %>]))
            /
            sum(rate(<%= slo.total_events %>[<%= window %>]))
          )
```

**Current alert shape** from lines 17-54:
```eex
      - alert: <%= Macro.camelize(to_string(slo.name)) %>SLOBurnRatePage
        expr: >
          slo:error_ratio:rate1h{slo="<%= slo.name %>"} > (<%= 1 - (slo.objective / 100) %> * 14.4)
          and
          slo:error_ratio:rate5m{slo="<%= slo.name %>"} > (<%= 1 - (slo.objective / 100) %> * 14.4)
        labels:
          severity: page
          slo: <%= slo.name %>
        annotations:
          summary: "High SLO burn rate for <%= slo.name %>"
          runbook: "<%= slo.runbook %>"
```

**Planner guidance:** keep the template data-driven, but Phase 5 likely needs more than `good_events`, `total_events`, `objective`, and `runbook`. If symptom-vs-diagnostic rules diverge, add provider/slice metadata to the input model rather than hardcoding per-integration branches directly in EEx.

---

### `lib/parapet/metrics/*async_delivery*.ex`

**No exact metrics-module analog exists. Build against the normalized telemetry contract, not raw upstream events.**

**Canonical family list** from `lib/parapet/telemetry/async_delivery.ex` lines 49-57:
```elixir
@event_families [
  [:parapet, :delivery, :outbound],
  [:parapet, :delivery, :provider_feedback],
  [:parapet, :delivery, :webhook_ingest],
  [:parapet, :async, :stage],
  [:parapet, :async, :backlog],
  [:parapet, :async, :callback]
]
```

**Allowed label shapes** from `lib/parapet/telemetry/async_delivery.ex` lines 6-25 and 27-47:
```elixir
@delivery_family_keys %{
  outbound: [:integration, :provider, :channel, :outcome, :failure_class, :fault_plane],
  provider_feedback: [:integration, :provider, :channel, :outcome, :failure_class, :fault_plane],
  webhook_ingest: [:integration, :provider, :channel, :outcome, :failure_class, :delay_bucket, :fault_plane]
}

@async_family_keys %{
  stage: [:integration, :provider, :queue, :pipeline_stage, :outcome, :retry_state, :fault_plane],
  backlog: [:integration, :provider, :queue, :outcome, :delay_bucket, :fault_plane],
  callback: [:integration, :provider, :queue, :pipeline_stage, :outcome, :delay_bucket, :fault_plane]
}
```

**Metadata shaping seam** from `lib/parapet/telemetry/async_delivery.ex` lines 189-206:
```elixir
def shape_metadata(family, metadata) when is_atom(family) and is_map(metadata) do
  public_keys = allowed_public_keys(family)

  public_metadata =
    metadata
    |> Map.take(public_keys)
    |> maybe_normalize_known_values()

  refs =
    metadata
    |> extract_known_refs()
    |> merge_explicit_refs(Map.get(metadata, :refs, %{}))

  if map_size(refs) == 0 do
    public_metadata
  else
    Map.put(public_metadata, :refs, refs)
  end
end
```

**Planner guidance:** any new metrics module should subscribe to the six normalized families and derive counters/gauges from bounded top-level keys only. Never promote `refs` values into labels.

---

### Delivery and async integration touch points

**Mailglass event mapping** from `lib/parapet/integrations/mailglass.ex` lines 47-77:
```elixir
defp process_event([:mailglass, :outbound, :send, :stop], measurements, metadata) do
  emit_delivery(:outbound, measurements, metadata, %{
    integration: :mailglass,
    provider: Map.get(metadata, :provider, :unknown),
    channel: :email,
    outcome: :attempted,
    fault_plane: :provider
  })
end

defp process_event([:mailglass, :reconcile, :stop], measurements, metadata) do
  emit_delivery(:provider_feedback, measurements, metadata, %{
    integration: :mailglass,
    provider: Map.get(metadata, :provider, :unknown),
    channel: :email,
    outcome: Map.get(metadata, :status, :failed),
    fault_plane: :provider
  })
end
```

**Chimeway fault-plane split** from `lib/parapet/integrations/chimeway.ex` lines 42-53 and 80-93:
```elixir
defp process_event([:chimeway, :event, :failed], measurements, metadata) do
  family = if callback_delay?(metadata), do: :webhook_ingest, else: :provider_feedback

  emit_delivery(family, measurements, metadata, %{
    integration: :chimeway,
    provider: Map.get(metadata, :provider, :unknown),
    channel: :notification,
    outcome: :failed,
    failure_class: Map.get(metadata, :error, :failed),
    fault_plane: fault_plane_for(metadata),
    delay_bucket: delay_bucket_for(metadata)
  })
end
```

**Rindle retry-vs-terminal split** from `lib/parapet/integrations/rindle.ex` lines 69-110:
```elixir
defp process_event([:rindle, :media, :failed], measurements, metadata) do
  emit_async(:stage, measurements, metadata, %{
    pipeline_stage: stage_from(metadata),
    outcome: :retryable_failed,
    retry_state: :retrying,
    fault_plane: :worker
  })
end

defp process_event([:rindle, :media, :discarded], measurements, metadata) do
  emit_async(:stage, measurements, metadata, %{
    pipeline_stage: stage_from(metadata),
    outcome: :discarded,
    retry_state: :exhausted,
    fault_plane: :worker
  })
end

defp process_event([:rindle, :media, :backlog], measurements, metadata) do
  emit_async(:backlog, measurements, metadata, %{
    outcome: :delayed,
    delay_bucket: delay_bucket_from(measurements, metadata),
    fault_plane: :backlog
  })
end
```

**Planner guidance:** provider slice definitions should be derived from these normalized distinctions. Keep `provider_accepted != delivered`, `retryable_failed != discarded`, and `callback != backlog`.

## Shared Patterns

### Explicit activation stays separate from provider registration
**Sources:** `lib/parapet.ex` lines 21-38, `.planning/v0.7-phases/5/5-CONTEXT.md` lines 84-97
```elixir
def attach(opts) when is_list(opts) do
  adapters = Keyword.get(opts, :adapters, [])

  Enum.each(adapters, fn adapter ->
    module_name =
      adapter
      |> to_string()
      |> Macro.camelize()

    module = Module.concat(Parapet.Integrations, module_name)

    if Code.ensure_loaded?(module) do
      apply(module, :setup, [])
    end
  end)

  {:ok, adapters}
end
```
Apply to: planning API boundaries. Adapter attachment remains `Parapet.attach(adapters: [...])`; SLO enablement remains `config :parapet, providers: [...]`.

### Generator tests should assert artifact content, then optionally `promtool`
**Source:** `test/mix/tasks/parapet.gen.prometheus_test.exs` lines 15-53
```elixir
igniter =
  test_project(app_name: :test)
  |> Prometheus.igniter()

assert_creates(igniter, "priv/parapet/prometheus/rules.yml")

yaml_content =
  Rewrite.source!(igniter.rewrite, "priv/parapet/prometheus/rules.yml")
  |> Rewrite.Source.get(:content)

assert yaml_content =~ "name: parapet_slo_http"
assert yaml_content =~ "record: slo:error_ratio:rate5m"
```
Apply to: new generator tests. Assert file paths and key rule fragments first; keep `promtool` as best-effort verification, not the only proof.

### Integration tests are characterization-first and assert bounded metadata exactly
**Sources:** `test/parapet/integrations/mailglass_test.exs` lines 46-139, `test/parapet/integrations/chimeway_test.exs` lines 40-99, `test/parapet/integrations/rindle_test.exs` lines 35-138
Apply to: any Phase 5 tests that need upstream semantics pinned before generator logic is layered on top. Exact assertions on `fault_plane`, `outcome`, `delay_bucket`, and `refs` are already the repo norm.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/parapet/metrics/*async_delivery*.ex` | metrics | event-driven | There is no existing metrics module over the Phase 4 contract yet; planners should treat `Parapet.Telemetry.AsyncDelivery` plus integration tests as the authoritative seam. |

## Likely Touch Points

- `lib/parapet/slo.ex`: keep provider aggregation stable while expanding provider catalog.
- `lib/parapet/slo/provider.ex`: only touch if Phase 5 needs richer callbacks than `slos/0`.
- `lib/mix/tasks/parapet.gen.prometheus.ex`: switch from generic SLO rendering to provider-backed slice rendering, still through explicit provider config.
- `priv/templates/parapet.gen.prometheus/rules.yml.eex`: likely needs the biggest redesign for symptom-vs-diagnostic rules, `for` durations, and minimum-volume guards.
- `test/mix/tasks/parapet.gen.prometheus_test.exs`: broaden beyond one generic HTTP SLO fixture to provider-backed async/delivery fixtures.
- `test/parapet/slo_test.exs`: add provider aggregation coverage for the new modules or richer resolvable structs.

## Metadata

**Analog search scope:** `lib/parapet/`, `lib/mix/tasks/`, `priv/templates/`, `test/parapet/`, `.planning/v0.7-phases/4/`
**Files scanned:** 20+
**Pattern extraction date:** 2026-05-17
