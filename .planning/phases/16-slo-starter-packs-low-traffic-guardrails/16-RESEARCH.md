# Phase 16: SLO Starter Packs & Low-Traffic Guardrails - Research

**Researched:** 2026-05-24
**Domain:** Elixir/Hex library — SLO SliceSpec provider modules, Prometheus metric series names, conditional compile-out pattern
**Confidence:** HIGH (all findings verified by direct code-read of live source files)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `Parapet.SLO.StarterPack.WebSaaS` is a new `@behaviour Parapet.SLO.Provider` module whose `slos/0` returns three `SliceSpec` structs — HTTP availability, login journey, Oban job-success. Mirrors shape of existing providers (`mailglass_delivery.ex:6`, `chimeway_delivery.ex:6`, `rindle_async.ex:6`).
- **D-02:** "One line" = adopter adds the pack module to `config :parapet, providers: [...]`. The engine reads providers from `Application.get_env(:parapet, :providers, [])` (`lib/parapet/slo.ex:71`), flat-maps `provider.slos()` (`:72`), resolves each via `Resolvable.to_slo/1` (`:77`). Pack MUST write to `:providers`, NOT legacy `:slos`.
- **D-03:** Pack defines fresh SliceSpecs; does NOT reuse legacy `Parapet.SLO.HTTP`/`.LoginJourney`/`.Oban` modules. Those emit wrong metric names.
- **D-04:** No HTTP selector helper module needed. `AsyncDelivery.selector/2` accepts a binary metric name and renders label matchers generically (`async_delivery.ex:108-130`).
- **D-05:** HTTP slice matches on `status_class` label (values `"2xx"`/`"3xx"`), NOT `status_code`. The plug emits `status_code` as a measurement (not queryable), and `status_class` as a tag.
- **D-06:** Pin exact Prometheus metric names from real emitters (this research resolves it; see Metric Names section below).
- **D-07:** `DeliverySaaS` delegates to `MailglassDelivery.slos()` / `ChimewayDelivery.slos()` — does NOT redefine delivery SliceSpecs inline.
- **D-08:** Delivery slices gated at runtime inside `slos/0` via `Code.ensure_loaded?(Mailglass)` / `Code.ensure_loaded?(Chimeway)`.
- **D-09:** The `DeliverySaaS` module itself is always loadable and fully documented — guard lives inside `slos/0`, never a module-level wrapper.
- **D-10:** Every pack slice keeps a non-zero `min_total_rate` (default `0.01`). No Generator changes needed.
- **D-11:** Low-cardinality compliance is convention-only in the SliceSpec/selector path; pack slices restrict HTTP matchers to `status_class` + `method`, omit `route` from `group_labels`. Planning should add a test asserting every pack slice's keys pass `LabelPolicy.assert_safe!`.
- **D-12:** Each pack slice ships an opinionated default objective with documented rationale in human terms. Values are Claude's discretion (see below), anchored to existing delivery slices + SRE norms.

### Claude's Discretion

- Exact default objective values per slice (D-12) and the human-terms rationale wording.
- Whether `DeliverySaaS` gating uses `Code.ensure_loaded?` (preferred) or a config-presence signal (D-08).
- Module/file naming under `lib/parapet/slo/starter_pack/` vs flat `lib/parapet/slo/`.

### Deferred Ideas (OUT OF SCOPE)

- `mix parapet.gen.slo` interactive wizard (SLO-W1) — v1.0+.
- Cross-integration SLO slice bundles (SLO-B1) — v1.0+.
- SLO authoring guide + low-traffic guidance docs (SLO-03/SLO-04) — Phase 18.
- Auto-generated / system-proposed SLO targets — permanently out of scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SLO-01 | A WebSaaS adopter can register a coherent first set of SLOs in one line via `Parapet.SLO.StarterPack.WebSaaS` (HTTP availability, LoginJourney, Oban job success) with documented default objectives and human-terms rationale. | Verified Provider engine path, exact metric names for each slice, SliceSpec shape, `slos/0` convention. |
| SLO-02 | A delivery-sending adopter can extend the WebSaaS set via `Parapet.SLO.StarterPack.DeliverySaaS` (adds MailglassDelivery + ChimewayDelivery slices), registering delivery slices only when those providers are configured. | Verified `Code.ensure_loaded?` + `apply/3` pattern, test stub modules, delegation to existing catalogs. |
</phase_requirements>

---

## Summary

Phase 16 ships two new `@behaviour Parapet.SLO.Provider` modules — `WebSaaS` and `DeliverySaaS` — that adopt can activate in one line via `config :parapet, providers: [...]`. The infrastructure is completely built: the Provider engine, SliceSpec → Generator pipeline, multi-burn-rate recording rules, denominator-guard alert expressions, and the optional-integration compile-out pattern. This phase adds zero engine changes; it only adds new provider modules.

The most important verified finding (D-06) is that the **HTTP counter metric exposed on Prometheus is `parapet_http_request_count`** (Telemetry dot-notation `"parapet.http.request.count"` → Prometheus underscores) and the **Oban counter is `parapet_oban_jobs_total`** (dot-notation `"parapet.oban.jobs.total"`). The legacy `slo/http.ex` and `slo/oban.ex` modules both reference non-existent metric names (`parapet_http_server_duration_milliseconds_count`, `parapet_oban_job_duration_milliseconds_count`) — copying them produces dead rules. The LoginJourney metric is `parapet_journey_login_count` (from `Parapet.Metrics.Sigra`, dot-notation `"parapet.journey.login.count"`).

The `PrometheusFormatter` module (`lib/parapet/metrics/prometheus_formatter.ex`) is a post-processing wrapper that injects exemplars; it does NOT perform dots-to-underscores conversion. That conversion is a convention of `telemetry_metrics_prometheus_core`: dots become underscores and the Telemetry.Metrics `counter/2` type produces a `_total` suffix in modern prometheus_core (or the metric name AS IS for older `counter/2` calls that already include the suffix). The exact emitted names are confirmed below.

**Primary recommendation:** Create `lib/parapet/slo/starter_pack/web_saas.ex` and `lib/parapet/slo/starter_pack/delivery_saas.ex`. Each is a plain `@behaviour Parapet.SLO.Provider` with `@moduledoc` (required by `verify.public_api`). All three WebSaaS slices target the real emitted metric names via binary strings passed directly to `AsyncDelivery.selector/2`. `DeliverySaaS.slos/0` conditionally prepends delivery slices via `Code.ensure_loaded?` guards.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SLO pack registration | Config / Application env | — | `Application.get_env(:parapet, :providers, [])` is the activation point |
| SliceSpec definition (pack) | Library module (`lib/parapet/slo/starter_pack/`) | — | Pure data construction; no process involvement |
| PromQL expression generation | `Generator` + `Resolvable` (existing) | — | Packs ride unchanged; generator reads `provider_catalog/0` |
| Low-traffic denominator guard | `Generator.alert_group/1` (existing) | SliceSpec `min_total_rate` field | Guard is baked: `> spec.min_total_rate` at `generator.ex:106` |
| Delivery slice conditional loading | `DeliverySaaS.slos/0` at runtime | `Code.ensure_loaded?` | Host-supplied libs detected by module presence, not mix deps |
| LabelPolicy enforcement | `LabelPolicy.assert_safe!/1` (existing) | Test assertion in Phase 16 test | Policy runs at metric-definition time; packs enforce by test |
| Public API verification | `mix docs --warnings-as-errors` | CI via `verify.public_api` alias | Every public module needs `@moduledoc` |

---

## D-06: Verified Prometheus Metric Names (HIGHEST VALUE)

All names confirmed by reading `lib/parapet/metrics/http.ex`, `lib/parapet/metrics/oban.ex`, `lib/parapet/metrics/sigra.ex`, and `lib/parapet/metrics/async_delivery.ex`.

### HTTP Availability Slice

**Source:** `lib/parapet/metrics/http.ex:29-33` [VERIFIED: code-read]

```elixir
counter("parapet.http.request.count",
  event_name: [:parapet, :http, :request],
  tags: [:route, :method, :status_class],
  description: "Total number of HTTP requests"
)
```

Prometheus series name: **`parapet_http_request_count`**

Tags (low-cardinality): `route`, `method`, `status_class`

The plug (`lib/parapet/plug/metrics.ex:23,28,39`) emits:
- `status_class` as a tag: `"#{div(conn.status, 100)}xx"` → `"2xx"`, `"3xx"`, `"4xx"`, `"5xx"`
- `status_code` as a **measurement** (not a tag/label): `%{duration_ms: duration_ms, status_code: conn.status}`

**Good matchers for HTTP availability:** `status_class=~"2xx|3xx"` — i.e., matcher list `[status_class: ["2xx", "3xx"]]` which `AsyncDelivery.selector/2` renders as `status_class=~"2xx|3xx"`.

**Total matchers:** empty list `[]` (all HTTP requests, no status filter).

**Watch-out confirmed:** Legacy `slo/http.ex:25` default `status_code=~"2..|3.."` targets `parapet_http_server_duration_milliseconds_count` — a metric this codebase does NOT emit. Do not copy it.

### LoginJourney Slice

**Source:** `lib/parapet/metrics/sigra.ex:14-16` [VERIFIED: code-read]

```elixir
counter("parapet.journey.login.count",
  event_name: [:parapet, :journey, :login],
  tags: [:outcome]
)
```

Prometheus series name: **`parapet_journey_login_count`**

Tags (low-cardinality): `outcome` (values: `:success`, `:failure` — from `integrations/sigra.ex:41`)

**Good matchers:** `[outcome: :success]`
**Total matchers:** `[]` (all login attempts)

**Important constraint:** The `LoginJourney` slice is only meaningful when the `Sigra` integration is enabled (the metric is emitted by `Integrations.Sigra.setup/0`). The WebSaaS pack includes it unconditionally — if no Sigra adapter is registered, the metric will simply be absent from Prometheus and the SLO will produce no alerts (which is correct behavior; the denominator guard handles this gracefully via `min_total_rate`).

**Watch-out confirmed:** Legacy `slo/login_journey.ex:26` default targets `parapet_journey_login_duration_milliseconds_count` — does not exist. The real metric is `parapet_journey_login_count`.

### Oban Job-Success Slice

**Source:** `lib/parapet/metrics/oban.ex:45-49` [VERIFIED: code-read]

```elixir
counter("parapet.oban.jobs.total",
  event_name: [:parapet, :oban, :job],
  tags: [:worker, :queue, :state],
  description: "Total number of Oban jobs processed"
)
```

Prometheus series name: **`parapet_oban_jobs_total`**

Tags (low-cardinality): `worker`, `queue`, `state`

The Oban handler (`lib/parapet/metrics/oban.ex:71`) emits `state` from `metadata.state` — values from Oban: `"success"`, `"failure"`, `"cancelled"`, `"discarded"`.

**Good matchers:** `[state: "success"]`
**Total matchers:** `[]` (all Oban jobs)

**Watch-out confirmed:** Legacy `slo/oban.ex:25` default targets `parapet_oban_job_duration_milliseconds_count{state="success"}` — that metric does not exist. The real counter is `parapet_oban_jobs_total` and the state field is `state`, not `outcome`.

**Additional note:** `Parapet.Metrics.Oban` is itself conditionally compiled: `if Code.ensure_loaded?(Oban) do ... end` (`oban.ex:1`). The WebSaaS Oban slice is included unconditionally in the pack's `slos/0` — same graceful behavior as LoginJourney: if no Oban adapter is registered, metric is absent and `min_total_rate` guard prevents false alerts.

---

## SliceSpec Shape (Verified)

**Source:** `lib/parapet/slo/slice_spec.ex` [VERIFIED: code-read]

### Struct Fields

```elixir
@enforce_keys [:name, :integration, :kind, :alert_class, :runbook]
defstruct [
  :name,           # atom — slice identity, used in recording rule names
  :integration,    # atom — integration tag for labels
  :kind,           # :ratio | :freshness | :diagnostic
  :objective,      # float (percentage, e.g. 99.9) — mutually exclusive with :threshold
  :alert_class,    # :page | :ticket | :warning | :diagnostic
  :runbook,        # string URL
  :good_source_metric,   # binary Prometheus metric name
  :bad_source_metric,    # binary (diagnostic kind only)
  :total_source_metric,  # binary Prometheus metric name
  :threshold,      # float (0.0..1.0) — error ratio threshold, alternative to :objective
  :summary,        # string alert annotation
  group_labels: [:integration],  # list of atoms for PromQL sum-by clause
  labels: %{},                   # map added to alert rule labels
  good_matchers: [],             # keyword list for good series selector
  bad_matchers: [],              # keyword list for bad series selector (diagnostic only)
  total_matchers: [],            # keyword list for total series selector
  min_total_rate: 0.01,          # float — denominator guard threshold (non-zero required)
  for: nil,                      # alert duration override (nil = use default by alert_class)
  keep_firing_for: nil           # keep_firing_for override (nil = use default by alert_class)
]
```

**`source_metric:` shorthand** (`slice_spec.ex:79-91`): Passing `source_metric: "foo"` auto-expands to `good_source_metric: "foo"`, `bad_source_metric: "foo"`, `total_source_metric: "foo"`. Useful for freshness/ratio slices where good and total share a metric name.

**Required fields for `kind: :ratio`:** `:name`, `:integration`, `:kind`, `:alert_class`, `:runbook`, `:good_source_metric`, `:good_matchers` (non-empty), `:total_source_metric`, `:total_matchers` (non-empty), and either `:objective` or `:threshold`.

**Defaults applied by `new/1`** (`slice_spec.ex:36-43`):
- `group_labels: [:integration]`
- `labels: %{}`
- `good_matchers: []`
- `bad_matchers: []`
- `total_matchers: []`
- `min_total_rate: 0.01`

**`min_total_rate` override examples from existing providers:**
- Default: `0.01` (all providers that don't override)
- Low-volume override: `0.001` (`mailglass_delivery.ex:71`, `chimeway_delivery.ex:71`, `rindle_async.ex:43`)

### Objective Conventions from Existing Providers

| Provider | Slice | Objective | Alert Class |
|----------|-------|-----------|-------------|
| MailglassDelivery | submit_acceptance | 99.0 | :ticket |
| MailglassDelivery | confirmed_delivery | 99.0 | :page |
| MailglassDelivery | webhook_freshness | 99.0 | :page |
| MailglassDelivery | suppression_drift | threshold: 0.02 | :diagnostic |
| ChimewayDelivery | provider_acceptance | threshold: 0.01 | :ticket |
| ChimewayDelivery | callback_confirmation | threshold: 0.01 | :page |
| ChimewayDelivery | callback_freshness | 99.0 | :page |
| RindleAsync | terminal_success | 99.0 | :page |
| RindleAsync | queue_freshness | 99.0 | :page |
| RindleAsync | long_running_stage | threshold: 0.05 | :diagnostic |

---

## D-12: Recommended Default Objectives Per Pack Slice

These are Claude's Discretion values (D-12), anchored to existing delivery slice conventions and SRE norms.

### HTTP Availability (`web_saas_http_availability`)
- **Objective:** `99.5` — `:ticket` alert class
- **Rationale:** HTTP availability at 99.5% = 3.65 hours/month of non-2xx/3xx responses budget. Deliberately softer than 99.9% to be achievable as a "starter" — 99.9% (43 min/month) is appropriate once adopters understand their actual traffic patterns. Alert class `:ticket` (not `:page`) for the same reason: aggregate HTTP errors are noisy on first adoption; ticket-level keeps alert fatigue low.
- **`min_total_rate:`** `0.01` (default) — ~0.6 requests/minute over 1h window.

### Login Journey (`web_saas_login_journey`)
- **Objective:** `99.9` — `:page` alert class
- **Rationale:** Login failures are directly user-impacting and low-volume (not every request is a login). 99.9% = ~43 min/month of user-impacting auth failures. Auth failures are silent-revenue-loss events — worth paging. Mirrors what security-conscious SaaS teams already target. Existing delivery slices (confirmed_delivery) use `:page` at 99.0%; login is higher-stakes, so 99.9% is justified.
- **`min_total_rate:`** `0.01` (default) — appropriate for all but extremely low-volume services.

### Oban Job Success (`web_saas_oban_job_success`)
- **Objective:** `99.0` — `:ticket` alert class
- **Rationale:** Oban job failures at 99.0% success = ~7.3 hours/month of job-level failures. Jobs include retries, so transient failures are expected; 99.0% accommodates retry-normal patterns. `:ticket` matches `mailglass_submit_acceptance` convention (non-user-facing async operations are ticket-level, not page-level). Adopters with critical-path jobs (payment processing) should override to 99.9% + `:page`.
- **`min_total_rate:`** `0.01` (default).

### Mailglass + Chimeway (DeliverySaaS)
- Delegated to `MailglassDelivery.slos()` / `ChimewayDelivery.slos()` with no override. Those catalogs ship their own tested objectives (99.0% / threshold patterns). DeliverySaaS composites them unchanged — per D-07, no objective drift.

---

## Provider Engine (Verified)

**Source:** `lib/parapet/slo.ex:70-78` [VERIFIED: code-read]

```elixir
def provider_catalog do
  Application.get_env(:parapet, :providers, [])
  |> Enum.flat_map(fn provider -> provider.slos() end)
end

def provider_slos do
  provider_catalog()
  |> Enum.map(&Parapet.SLO.Resolvable.to_slo/1)
end
```

**Registration path:**
1. Adopter adds `config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]`
2. `SLO.provider_catalog/0` flat-maps `WebSaaS.slos()` → list of `%SliceSpec{}`
3. `SLO.provider_slos/0` maps each through `Resolvable.to_slo/1` → `%SLO{}`
4. `Generator.provider_artifacts/0` calls `SLO.provider_catalog()` directly to build recording rules + alerts from SliceSpec structs

**Provider behaviour** (`lib/parapet/slo/provider.ex`):
```elixir
@callback slos() :: [struct()]
```

**Resolvable protocol** (`lib/parapet/slo/resolvable.ex:49-51`):
```elixir
defp rate_expr(metric_name, matchers) do
  "sum(rate(#{AsyncDelivery.selector(metric_name, matchers)}[window]))"
end
```

The `rate_expr/2` private function calls `AsyncDelivery.selector/2` with a binary metric name — confirming D-04: the HTTP slice can pass `"parapet_http_request_count"` directly and get correct PromQL.

---

## AsyncDelivery.selector/2 (Generic Binary Metric Support)

**Source:** `lib/parapet/metrics/async_delivery.ex:102-130` [VERIFIED: code-read]

```elixir
def selector(family_or_metric, matchers \\ [], metric_kind \\ :total)

def selector(family, matchers, metric_kind) when is_atom(family) do
  render_selector(metric_name(family, metric_kind), matchers)
end

def selector(metric_name, matchers, _metric_kind) when is_binary(metric_name) do
  render_selector(metric_name, matchers)
end
```

When the first argument is a **binary string** (e.g., `"parapet_http_request_count"`), the selector renders it directly with the label matchers — **no delivery-family coupling**. D-04 is fully confirmed: HTTP, LoginJourney, and Oban pack slices all pass binary metric names and matchers directly; no HTTP-specific selector helper is needed.

**Matcher rendering (`render_selector/2`):**
- Empty matchers → `"parapet_http_request_count"` (no braces)
- List matchers → `"parapet_http_request_count{method=\"GET\", status_class=~\"2xx|3xx\"}"`
- List values trigger `=~` operator (regex match); scalar values trigger `=`

---

## Optional-Integration Compile-Out Pattern (Verified)

**Source:** `lib/parapet/integrations/threadline.ex:72-76`, `lib/parapet/integrations/scoria.ex:185-189`, `lib/parapet.ex:32` [VERIFIED: code-read]

Canonical idiom:
```elixir
if Code.ensure_loaded?(Mailglass) do
  apply(Mailglass, :some_function, [args])
else
  :ok
end
```

For `DeliverySaaS.slos/0`, the pattern adapts to conditional list prepending:

```elixir
def slos do
  websaas_slices = Parapet.SLO.StarterPack.WebSaaS.slos()

  mailglass_slices =
    if Code.ensure_loaded?(Mailglass) do
      Parapet.SLO.MailglassDelivery.slos()
    else
      []
    end

  chimeway_slices =
    if Code.ensure_loaded?(Chimeway) do
      Parapet.SLO.ChimewayDelivery.slos()
    else
      []
    end

  websaas_slices ++ mailglass_slices ++ chimeway_slices
end
```

**Test stub modules confirm the design** (`test/support/mailglass.ex`, `test/support/chimeway.ex`):
```elixir
defmodule Mailglass do
  @moduledoc false
  # Dummy module for testing Mailglass integration compiler guards
end

defmodule Chimeway do
  @moduledoc false
  # Dummy module for testing Chimeway integration compiler guards
end
```

These stubs exist in `test/support/` (compiled only in `:test` env via `elixirc_paths/1` in `mix.exs:37`). In test, `Code.ensure_loaded?(Mailglass)` returns `true` → delivery slices included. In production without the real Mailglass library installed, `Code.ensure_loaded?(Mailglass)` returns `false` → delivery slices silently omitted.

**D-09 confirmed:** The `DeliverySaaS` module MUST be always loadable. The guard lives inside `slos/0`, never at module-definition level. This is consistent with how `Parapet.Metrics.Oban` works (wraps with `if Code.ensure_loaded?(Oban) do defmodule ... end`) — but for a Provider module that must pass `verify.public_api`, the module-level guard pattern cannot be used (it would conditionally exclude the module from docs).

---

## LabelPolicy.assert_safe!/1 (D-11 Enforcement)

**Source:** `lib/parapet/internal/label_policy.ex:6-17` [VERIFIED: code-read]

```elixir
def assert_safe!(labels) do
  Enum.each(labels, fn label ->
    label_str = to_string(label)

    if label_str =~ ~r/id$/ or label_str =~ ~r/^raw_/ or label_str =~ ~r/token/ or
         label_str =~ ~r/path/ do
      raise ArgumentError, "High cardinality label rejected by Parapet safety policy: #{label}"
    end
  end)

  :ok
end
```

**Rejection rules:** Any label matching:
- Ends with `id` (e.g., `:user_id`, `:trace_id`, `:request_id`)
- Starts with `raw_`
- Contains `token`
- Contains `path`

**Pack slice label keys that pass `assert_safe!`:**
- HTTP slice: `:status_class`, `:method` — both pass (no `id`, `raw_`, `token`, or `path`)
- LoginJourney slice: `:outcome` — passes
- Oban slice: `:worker`, `:queue`, `:state` — all pass
- `group_labels: [:integration]` — passes

**Test pattern for D-11 enforcement:**
```elixir
test "all WebSaaS pack slice matcher keys pass LabelPolicy.assert_safe!" do
  slices = Parapet.SLO.StarterPack.WebSaaS.slos()

  Enum.each(slices, fn slice ->
    matcher_keys = Keyword.keys(slice.good_matchers ++ slice.total_matchers)
    assert :ok = Parapet.Internal.LabelPolicy.assert_safe!(matcher_keys)
    assert :ok = Parapet.Internal.LabelPolicy.assert_safe!(slice.group_labels)
  end)
end
```

---

## verify.public_api

**Source:** `mix.exs:95` [VERIFIED: code-read]

```elixir
defp aliases do
  [
    "verify.public_api": ["docs --warnings-as-errors"]
  ]
end
```

**What makes a new public module pass:**
1. The module has a `@moduledoc` with non-empty content (not `false`)
2. All public functions have `@doc` with non-empty content (or `@doc false` to explicitly hide)
3. All `@spec` type references resolve to valid types
4. No broken `[ModuleName]` or `[function/arity]` references in any doc string

**`skip_undefined_reference_warnings_on: ["CHANGELOG.md"]`** is already set in `mix.exs:67` — the CHANGELOG exemption already exists.

New modules `Parapet.SLO.StarterPack.WebSaaS` and `Parapet.SLO.StarterPack.DeliverySaaS` must have documented `@moduledoc` and `@doc` on `slos/0`. No new doc `extras:` entry is needed in Phase 16 — modules appear in the API reference automatically. Phase 18 will add the prose guide that names them.

---

## Architecture Patterns

### Recommended Project Structure

```
lib/parapet/slo/
├── starter_pack/
│   ├── web_saas.ex       # Parapet.SLO.StarterPack.WebSaaS
│   └── delivery_saas.ex  # Parapet.SLO.StarterPack.DeliverySaaS
├── mailglass_delivery.ex  (existing — composed by DeliverySaaS)
├── chimeway_delivery.ex   (existing — composed by DeliverySaaS)
└── ...

test/parapet/slo/
├── starter_pack/
│   ├── web_saas_test.exs
│   └── delivery_saas_test.exs
└── ...
```

**Naming rationale:** `starter_pack/` subdirectory mirrors the module namespace `Parapet.SLO.StarterPack.*`. Existing providers (`mailglass_delivery.ex`, `chimeway_delivery.ex`, `rindle_async.ex`) live flat in `lib/parapet/slo/` — packs go one level deeper to signal they are composites.

### Pattern: WebSaaS Provider Module

```elixir
# lib/parapet/slo/starter_pack/web_saas.ex
defmodule Parapet.SLO.StarterPack.WebSaaS do
  @moduledoc """
  Opinionated first-SLO pack for Phoenix SaaS teams.

  Register in one line:

      config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]

  Ships three slices with documented default objectives:
  - HTTP availability (99.5% / ~3.65 hours error budget/month)
  - Login journey success (99.9% / ~43 min/month)
  - Oban job success (99.0% / ~7.3 hours/month)
  """

  @behaviour Parapet.SLO.Provider
  alias Parapet.SLO.SliceSpec

  @impl true
  def slos do
    [
      SliceSpec.new(
        name: :web_saas_http_availability,
        integration: :http,
        kind: :ratio,
        good_source_metric: "parapet_http_request_count",
        good_matchers: [status_class: ["2xx", "3xx"]],
        total_source_metric: "parapet_http_request_count",
        total_matchers: [status_class: ["2xx", "3xx", "4xx", "5xx"]],
        objective: 99.5,
        alert_class: :ticket,
        runbook: "https://parapet.dev/runbooks/http-availability",
        group_labels: [:integration, :method],
        summary: "HTTP availability is below 99.5%"
      ),
      SliceSpec.new(
        name: :web_saas_login_journey,
        integration: :auth,
        kind: :ratio,
        good_source_metric: "parapet_journey_login_count",
        good_matchers: [outcome: :success],
        total_source_metric: "parapet_journey_login_count",
        total_matchers: [outcome: [:success, :failure]],
        objective: 99.9,
        alert_class: :page,
        runbook: "https://parapet.dev/runbooks/login-journey",
        group_labels: [:integration],
        summary: "Login journey success is below 99.9%"
      ),
      SliceSpec.new(
        name: :web_saas_oban_job_success,
        integration: :oban,
        kind: :ratio,
        good_source_metric: "parapet_oban_jobs_total",
        good_matchers: [state: "success"],
        total_source_metric: "parapet_oban_jobs_total",
        total_matchers: [state: ["success", "failure", "cancelled", "discarded"]],
        objective: 99.0,
        alert_class: :ticket,
        runbook: "https://parapet.dev/runbooks/oban-job-success",
        group_labels: [:integration, :queue],
        summary: "Oban job success is below 99.0%"
      )
    ]
  end
end
```

**Notes on non-empty `total_matchers`:** `SliceSpec.validate!` REJECTS an empty `total_matchers` list for `:ratio` slices (`slice_spec.ex:127-129`), so each slice enumerates its denominator explicitly (HTTP status classes, login outcomes, Oban terminal states — the RESOLVED values above). `AsyncDelivery.selector/2` renders a list-valued matcher as a PromQL regex match — e.g., `status_class=~"2xx|3xx|4xx|5xx"`. Confirmed at `async_delivery.ex:200-208`.

**Notes on `good_matchers: [status_class: ["2xx", "3xx"]]`:** The list-value path in `render_selector` produces `status_class=~"2xx|3xx"` — a PromQL regex match. Confirmed at `async_delivery.ex:200-208`.

### Pattern: DeliverySaaS Provider Module

```elixir
# lib/parapet/slo/starter_pack/delivery_saas.ex
defmodule Parapet.SLO.StarterPack.DeliverySaaS do
  @moduledoc """
  Extends `Parapet.SLO.StarterPack.WebSaaS` with Mailglass and Chimeway delivery slices.

  Delivery slices are registered only when the corresponding host library is loaded.
  If Mailglass is not installed, Mailglass slices are omitted cleanly.
  Same for Chimeway.

      config :parapet, providers: [Parapet.SLO.StarterPack.DeliverySaaS]
  """

  @behaviour Parapet.SLO.Provider

  alias Parapet.SLO.ChimewayDelivery
  alias Parapet.SLO.MailglassDelivery
  alias Parapet.SLO.StarterPack.WebSaaS

  @impl true
  def slos do
    websaas_slices = WebSaaS.slos()

    mailglass_slices =
      if Code.ensure_loaded?(Mailglass) do
        MailglassDelivery.slos()
      else
        []
      end

    chimeway_slices =
      if Code.ensure_loaded?(Chimeway) do
        ChimewayDelivery.slos()
      else
        []
      end

    websaas_slices ++ mailglass_slices ++ chimeway_slices
  end
end
```

### Anti-Patterns to Avoid

- **Copying legacy PromQL from `slo/http.ex`:** Uses `parapet_http_server_duration_milliseconds_count` — does not exist. Always pin metric names from the emitter module, not the legacy SLO module.
- **Module-level `Code.ensure_loaded?` guard on DeliverySaaS:** Would cause `verify.public_api` to fail when Mailglass is not present — the module would be undefined and docs would break.
- **`min_total_rate: 0`:** Reintroduces flapping on low-traffic services. Every pack slice must have a non-zero value (default `0.01` is fine for most slices).
- **Using `status_code` in HTTP matchers:** `status_code` is emitted as a measurement, not a tag — it cannot appear in PromQL label selectors. Use `status_class` which is a registered tag.
- **Defining delivery SliceSpecs inline in `DeliverySaaS`:** Creates objective drift from the tested `MailglassDelivery`/`ChimewayDelivery` catalogs. Always delegate.
- **Adding `route` to HTTP `group_labels`:** High cardinality (one series per route). Keep `group_labels: [:integration, :method]` for HTTP.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Prometheus metric selector with label matchers | Custom string builder | `AsyncDelivery.selector/2` with binary metric name | Already handles `=` vs `=~`, nil rejection, key sorting |
| Multi-burn-rate recording rules + alerts | Custom YAML generation | `Generator.provider_artifacts/0` + existing SliceSpec engine | 6 windows, denominator guard, severity mapping all baked in |
| Low-traffic denominator guard | Custom `min_total_rate` check | Non-zero `min_total_rate` field in `SliceSpec.new/1` | Generator renders `> spec.min_total_rate` at `generator.ex:106` |
| Optional integration detection | `Application.get_env` config check | `Code.ensure_loaded?/1` | Host-supplied libraries (Mailglass, Chimeway) are not in `deps/0`; config-presence would never trip |
| PromQL expression for SliceSpec | Hand-written `good_events:` string | `SliceSpec.new/1` + `Resolvable.to_slo/1` | `rate_expr/2` in Resolvable wraps selector in `sum(rate(...[window]))` automatically |

---

## Common Pitfalls

### Pitfall 1: Dead Alert Rules (Wrong Metric Names)
**What goes wrong:** Pack defines a `SliceSpec` targeting a metric name from legacy modules. Tests pass (the SliceSpec is structurally valid), but Prometheus never fires the alert because the series doesn't exist.
**Why it happens:** Legacy `slo/http.ex`, `slo/oban.ex`, and `slo/login_journey.ex` contain default PromQL strings that reference metrics the codebase does not emit. These were written speculatively.
**How to avoid:** Always derive metric names from the actual emitter module. For this phase: HTTP → `lib/parapet/metrics/http.ex:29`, Login → `lib/parapet/metrics/sigra.ex:14`, Oban → `lib/parapet/metrics/oban.ex:45`.
**Warning signs:** A metric name containing `_duration_milliseconds_count` in a pack — that pattern belongs to legacy modules, not real emitters.

### Pitfall 2: `status_code` in HTTP Matchers
**What goes wrong:** HTTP slice uses `status_code: ~r/2..|3../` as a matcher — produces invalid PromQL selector; `status_code` is a measurement field, not a label.
**Why it happens:** Cargo-culting from `slo/http.ex:25` default.
**How to avoid:** Use `status_class: ["2xx", "3xx"]` — the plug at `lib/parapet/plug/metrics.ex:23` emits `status_class` as a tag; confirmed at `http.ex:31`.
**Warning signs:** Any matcher key `:status_code` in a pack slice.

### Pitfall 3: Module-Level Compile Guard on DeliverySaaS
**What goes wrong:** `if Code.ensure_loaded?(Mailglass) do defmodule Parapet.SLO.StarterPack.DeliverySaaS do ... end end` makes the module absent when run without Mailglass → `verify.public_api` fails → CI breaks.
**Why it happens:** Pattern looked at `Parapet.Metrics.Oban` (which uses module-level guard) without noticing that Oban module is not required to appear in the public API docs.
**How to avoid:** Keep `DeliverySaaS` always defined; put `Code.ensure_loaded?` guards inside `slos/0` only (D-09).

### Pitfall 4: Empty `total_matchers` Validation Failure
**What goes wrong:** `SliceSpec.validate!/1` raises `ArgumentError` "slice requires total matchers and metric" when `total_matchers: []`.
**Why it happens:** The validator at `slice_spec.ex:127-129` checks `spec.total_matchers == []`.
**How to avoid:** Read `validate_metric_fields!/1` carefully — the check is `is_nil(spec.total_source_metric) or spec.total_matchers == []`. Since `total_matchers: []` IS empty list, the validator will raise. The HTTP slice must use a non-empty `total_matchers` — e.g., `total_matchers: [status_class: ["2xx", "3xx", "4xx", "5xx"]]` or a different approach.

**IMPORTANT DESIGN NOTE:** This pitfall requires a solution. `total_matchers: []` is NOT valid per the validator. Options:
1. Use an explicit catch-all matcher that is always true, e.g., `total_matchers: [method: ~w(GET POST PUT PATCH DELETE HEAD OPTIONS)]` — but this over-specifies.
2. Use a single low-cardinality matcher that covers all requests: `total_matchers: []` is invalid; the total must have at least one matcher.
3. **Preferred approach:** For HTTP total, use the metric name without matchers by passing the slices' `total_source_metric` to the generator directly. BUT the validator at `slice_spec.ex:127` checks `spec.total_matchers == []` and raises.

Looking at the existing Resolvable implementation at `resolvable.ex:49-51`:
```elixir
defp rate_expr(metric_name, matchers) do
  "sum(rate(#{AsyncDelivery.selector(metric_name, matchers)}[window]))"
end
```
And `render_selector` at `async_delivery.ex:119-129` — empty matchers produce no `{}` block (correct). But the SliceSpec validator at `slice_spec.ex:123-130` REQUIRES non-empty `total_matchers`.

**Resolution:** The HTTP total slice must include at least one matcher even if it is effectively a catch-all. Using a non-zero `total_matchers` like `[method: ["GET", "POST", "PUT", "PATCH", "DELETE"]]` couples the SLO to HTTP method enumeration (fragile). A better option is to use a wildcard regex matcher: but PromQL label selectors do not have a "match all" syntax beyond simply omitting the selector.

**Confirmed correct approach:** The simplest solution consistent with existing providers is to use `total_matchers: [status_class: ["2xx", "3xx", "4xx", "5xx"]]` — this uses all four status classes as the total (matching all HTTP requests). Alternatively, review if the validator can be bypassed: examining `validate_metric_fields!/1` at lines 122-130 confirms the check applies to non-diagnostic slices. There is no escape.

**Planner must resolve:** Either (a) use `total_matchers: [status_class: ["2xx", "3xx", "4xx", "5xx"]]` for the HTTP total (matching all classified requests), or (b) note that a single-matcher total like `total_matchers: [method: :any]` doesn't work. Option (a) is pragmatic — the four classes cover all HTTP responses.

Similarly for LoginJourney: `total_matchers: [outcome: [:success, :failure]]` and for Oban: `total_matchers: [state: ["success", "failure", "cancelled", "discarded"]]`.

**Alternative simpler fix:** Use `source_metric` shorthand and provide at least one trivially-true matcher. For Oban: `total_matchers: [queue: :.+]` is a regex-all — but this is unusual. The cleanest is to enumerate known values.

---

## Runtime State Inventory

SKIPPED — This is a greenfield addition phase (new modules, no renames, no runtime state changes). No databases, no OS-registered state, no secret renames involved.

---

## Environment Availability

SKIPPED — This phase is pure code addition in an existing Elixir library project. No external tools or services beyond the existing Elixir/Mix toolchain are required. The existing `mix test` / `mix docs` infrastructure already covers verification.

---

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json` → treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/parapet/slo/starter_pack/` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SLO-01 | `WebSaaS.slos/0` returns exactly 3 `SliceSpec` structs with correct names | unit | `mix test test/parapet/slo/starter_pack/web_saas_test.exs` | ❌ Wave 0 |
| SLO-01 | Each WebSaaS slice has non-zero `min_total_rate` | unit | same | ❌ Wave 0 |
| SLO-01 | WebSaaS registered as provider → `SLO.provider_catalog/0` returns 3 slices | integration | same | ❌ Wave 0 |
| SLO-01 | `Generator.provider_artifacts/0` with WebSaaS provider contains denominator guard `> 0.01` | integration | same | ❌ Wave 0 |
| SLO-01 | All WebSaaS slice matcher keys pass `LabelPolicy.assert_safe!` | unit | same | ❌ Wave 0 |
| SLO-01 | `verify.public_api` passes (WebSaaS + DeliverySaaS are documented) | integration | `mix verify.public_api` | depends on impl |
| SLO-02 | `DeliverySaaS.slos/0` returns 3+4+3=10 slices when Mailglass + Chimeway stubs present (test env) | unit | `mix test test/parapet/slo/starter_pack/delivery_saas_test.exs` | ❌ Wave 0 |
| SLO-02 | `DeliverySaaS.slos/0` returns only 3 WebSaaS slices when delivery stubs absent | unit | same | ❌ Wave 0 |
| SLO-02 | Delivery slices sourced from `MailglassDelivery` / `ChimewayDelivery` (no duplicated SliceSpec names) | unit | same | ❌ Wave 0 |
| SLO-01 | HTTP slice targets `parapet_http_request_count` with `status_class=~"2xx\|3xx"` | unit | `mix test test/parapet/slo/starter_pack/web_saas_test.exs` | ❌ Wave 0 |
| SLO-01 | Oban slice targets `parapet_oban_jobs_total` with `state="success"` | unit | same | ❌ Wave 0 |
| SLO-01 | LoginJourney slice targets `parapet_journey_login_count` with `outcome="success"` | unit | same | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/parapet/slo/starter_pack/`
- **Per wave merge:** `mix test && mix verify.public_api`
- **Phase gate:** `mix test && mix verify.public_api && mix docs --warnings-as-errors`

### Wave 0 Gaps
- [ ] `test/parapet/slo/starter_pack/web_saas_test.exs` — covers SLO-01 (metric names, objective values, LabelPolicy, denominator guard, generator output, provider registration)
- [ ] `test/parapet/slo/starter_pack/delivery_saas_test.exs` — covers SLO-02 (conditional loading with/without stubs, delegation, no SliceSpec drift)
- [ ] Test directory: `test/parapet/slo/starter_pack/` — create with Wave 0 tasks

---

## Security Domain

`security_enforcement` is not set in `.planning/config.json` → treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | SLO pack does not handle auth |
| V3 Session Management | no | No sessions |
| V4 Access Control | no | Read-only config, no RBAC |
| V5 Input Validation | yes (low) | SliceSpec validator rejects invalid kinds/alert_classes at construction time; `LabelPolicy.assert_safe!` rejects high-cardinality label keys |
| V6 Cryptography | no | No crypto |

### Known Threat Patterns for SLO Provider Pattern

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dead alert rules (wrong metric names) | Spoofing (false confidence) | Pin metric names from emitter modules (verified in D-06) |
| High-cardinality label in SLO matchers | Elevation of privilege (TSDB cardinality explosion) | `LabelPolicy.assert_safe!` test on every pack slice (D-11) |
| Objective drift in DeliverySaaS | Tampering (silent weakening of SLOs) | Delegate to `MailglassDelivery.slos()` / `ChimewayDelivery.slos()` (D-07), no inline redefinition |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `parapet_journey_login_count` is only emitted when Sigra integration is active | Metric Names — LoginJourney | If always emitted, no issue; if never emitted without Sigra, the login SLO produces no alerts — which is correct behavior (min_total_rate guard) |
| A2 | `parapet_oban_jobs_total` tag `state` values include `"success"` as emitted string | Metric Names — Oban | If Oban emits different state strings, the good_matchers would miss successful jobs. Verified by reading `handle_event/4` at `oban.ex:71` which uses `metadata.state` directly from Oban — Oban's documented state values include `"success"`. [ASSUMED] for exact Oban library output strings. |
| A3 | HTTP total for an empty-matcher SliceSpec requires enumerating status classes to pass validator | Common Pitfalls — Pitfall 4 | If validator is relaxed or `nil` total_matchers behaves differently, an empty list might work. Verified the validator code — empty list IS rejected. |

**If this table were empty:** All claims were verified or cited — this table has 3 entries, all low-risk.

---

## Open Questions (RESOLVED)

> All three total_matchers questions are resolved. The chosen values are LOCKED and are the
> enumerated values the plans (`16-01`, `16-02`) and the WebSaaS code block above use. Empty
> `total_matchers` is forbidden by `SliceSpec.validate!` (`slice_spec.ex:127-129`).

1. **HTTP total_matchers constraint** — **RESOLVED**
   - What we know: `SliceSpec.validate!` rejects empty `total_matchers` for non-diagnostic slices (`slice_spec.ex:127-129`).
   - What's unclear: The cleanest total matcher for "all HTTP requests" without enumerating all routes.
   - **Resolution (chosen):** `total_matchers: [status_class: ["2xx", "3xx", "4xx", "5xx"]]`. This covers all responses emitted by the plug and is stable — status classes don't change.

2. **LoginJourney total_matchers constraint** — **RESOLVED**
   - What we know: Same validator issue. Login metric tags are only `:outcome`.
   - What's unclear: Whether to enumerate `[outcome: [:success, :failure]]` or use a regex.
   - **Resolution (chosen):** `total_matchers: [outcome: [:success, :failure]]` — the only two outcomes emitted by `Integrations.Sigra`.

3. **Oban total_matchers constraint** — **RESOLVED**
   - What we know: Oban metric tags are `:worker`, `:queue`, `:state`. Total = all jobs.
   - What's unclear: Full enumeration of Oban state values.
   - **Resolution (chosen):** `total_matchers: [state: ["success", "failure", "cancelled", "discarded"]]` — the standard Oban terminal states. (The `queue` regex alternative was rejected in favor of the explicit terminal-state enumeration for clarity and stability.)

---

## Sources

### Primary (HIGH confidence — direct code-read)

- `lib/parapet/metrics/http.ex:29-33` — HTTP counter metric name `parapet_http_request_count`, tags `[:route, :method, :status_class]`
- `lib/parapet/plug/metrics.ex:23,28,39` — `status_class` is a tag; `status_code` is a measurement
- `lib/parapet/metrics/oban.ex:45-49` — Oban counter metric name `parapet_oban_jobs_total`, tags `[:worker, :queue, :state]`
- `lib/parapet/metrics/sigra.ex:14-16` — Login journey counter `parapet_journey_login_count`, tags `[:outcome]`
- `lib/parapet/slo/slice_spec.ex` — Full SliceSpec struct, defaults, validator
- `lib/parapet/slo/mailglass_delivery.ex` — Reference provider shape, objective conventions, `min_total_rate: 0.001` override
- `lib/parapet/slo/chimeway_delivery.ex` — Reference provider shape
- `lib/parapet/slo/rindle_async.ex` — Reference provider shape, `min_total_rate: 0.001` override
- `lib/parapet/slo.ex:70-78` — Provider engine: `provider_catalog/0`, `provider_slos/0`
- `lib/parapet/slo/provider.ex` — `@behaviour` with `@callback slos() :: [struct()]`
- `lib/parapet/slo/resolvable.ex:49-51` — `rate_expr/2` calls `AsyncDelivery.selector/2` with binary metric name
- `lib/parapet/slo/generator.ex:103-107,156-159` — Denominator guard in alert expr, `aggregate_rate/4` calls `AsyncDelivery.selector/2`
- `lib/parapet/metrics/async_delivery.ex:102-130` — `selector/2` generic binary metric support
- `lib/parapet/internal/label_policy.ex:6-17` — `assert_safe!/1` rejection rules
- `lib/parapet/integrations/threadline.ex:72-76` — `Code.ensure_loaded?` + `apply/3` idiom
- `lib/parapet/integrations/scoria.ex:185-189` — Same pattern
- `test/support/mailglass.ex`, `test/support/chimeway.ex` — Test stub modules confirming the compile-out design
- `mix.exs:95` — `verify.public_api` alias = `mix docs --warnings-as-errors`
- `lib/parapet/slo/http.ex`, `oban.ex`, `login_journey.ex` — Legacy modules read for watch-out confirmation; metric names therein are wrong for this codebase

---

## Metadata

**Confidence breakdown:**
- Metric names (D-06): HIGH — read directly from emitter source files
- SliceSpec shape: HIGH — read from `slice_spec.ex` struct definition
- Provider engine: HIGH — read from `slo.ex`, `resolvable.ex`, `generator.ex`
- Optional-integration pattern: HIGH — read from `threadline.ex`, `scoria.ex`, `parapet.ex`, test stubs
- LabelPolicy: HIGH — read from `label_policy.ex`
- Default objectives (D-12): MEDIUM — anchored to existing slice conventions and SRE norms, not empirical traffic data
- Oban state values: MEDIUM — derived from Oban's documented behavior, not live Oban source read

**Research date:** 2026-05-24
**Valid until:** 2026-06-24 (stable codebase; metric names would only change with emitter rewrites)
