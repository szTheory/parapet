# Stack Research

**Domain:** Elixir/Phoenix SRE reliability layer — open-source library
**Researched:** 2026-05-09
**Confidence:** HIGH

Parapet is a library, not an application. This stack covers (a) the Elixir/OTP environment Parapet itself runs in, (b) the ecosystem libraries Parapet composes or adapts, and (c) the external systems Parapet generates artifacts for. The adopter's observability backend is intentionally pluggable; Parapet generates artifacts for it rather than owning it.

---

## Recommended Stack

### Core Language / Runtime

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir | 1.16 / 1.17 / 1.18 (matrix) | Implementation language | Hard constraint per PROJECT.md; all sibling libs target this matrix |
| OTP | 26 / 27 (matrix) | BEAM runtime, supervision, telemetry | Matches current Hex ecosystem compatibility window |
| Phoenix | Latest stable + previous stable | Host app integration target | Parapet's primary integration surface — must track two stable releases |
| Ecto | Latest stable + previous stable | DB metrics, pool saturation instrumentation | Pool queue/query time telemetry is a core v0.1 SLO slice |
| Oban | Current stable (optional dep) | Job SLO slice — queue depth, failure rate, latency | One of two v0.1 SLO slices; must compile out cleanly when absent |

### Core Telemetry Substrate (what Parapet attaches to)

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| `:telemetry` | (OTP stdlib, no separate pin) | Event emission substrate | Phoenix, Ecto, Oban all use it natively; Parapet's handler attachment layer |
| `telemetry_metrics` | Latest stable | Metric definition interface | Common interface for defining counters/distributions; Parapet generates these |
| `telemetry_poller` | Latest stable | VM-level metric polling | CPU, memory, run queues; needed for BEAM health metrics |

### Metrics Reporter (Parapet generates definitions; adopter chooses reporter)

Parapet's metric definitions must be reporter-agnostic. Ship a `PromEx` adapter first because it is the dominant choice in the ecosystem, but do not hard-couple the core.

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `prom_ex` | `~> 1.11` | Prometheus metrics + Grafana dashboard delivery | Default adapter; ships dashboards alongside metrics; most Phoenix teams already have it or will reach for it |
| `telemetry_metrics_prometheus_core` | Latest stable | Thin Prometheus reporter without PromEx | When adopter wants minimal reporter without PromEx's full plugin model |
| `peep` | `~> 5.0` (5.0.1 as of April 2026) | High-performance Telemetry.Metrics reporter for Prometheus/StatsD | When PromEx scrape cost becomes a bottleneck at very high request rates; Supavisor saw measurable latency improvement switching to Peep |

**Recommendation:** PromEx first. Peep is a known good alternative — document the swap path, don't block on it.

### Tracing Integration (optional dep, compile-out-clean)

Use OpenTelemetry for traces only. OTel Metrics and Logs are still marked "Development" in the Erlang/Elixir SDK — do not build on them for v0.1.

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `opentelemetry_api` | `~> 1.4` | OTel API surface (no-op without SDK) | Always — safe as a dep since it no-ops without SDK |
| `opentelemetry` | `~> 1.5` | OTel SDK | Optional; add when adopter wants distributed traces |
| `opentelemetry_exporter` | `~> 1.8` | OTLP export to collector/backend | Paired with the SDK |
| `opentelemetry_phoenix` | `~> 2.0` | Auto-instrument Phoenix requests as spans | Standard Phoenix OTel integration |
| `opentelemetry_cowboy` | `~> 1.0` | Cowboy HTTP layer instrumentation | Required when using OTel + Cowboy (Phoenix default) |
| `opentelemetry_ecto` | `~> 1.2` | Auto-instrument Ecto queries as spans | DB trace correlation |
| `opentelemetry_liveview` | `~> 1.0` | LiveView event instrumentation | For LiveView-heavy apps |
| `opentelemetry_logger_metadata` | `~> 0.3` | Inject trace/span IDs into Logger metadata | Enables log↔trace correlation |

**Important:** Mark `:opentelemetry` as `:temporary` in releases so OTel termination does not cascade to the host app.

### Logging (what adopters should use; Parapet generates wide event schemas)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `logger_json` | Latest stable | Structured JSON log formatter | Recommended for all adopters; supports standard ecosystems (GCloud, Datadog, Elastic) |

**Do not** couple Parapet's output to LoggerJSON specifically — emit to `:telemetry` and let the adopter forward to their log sink. Parapet defines wide event schemas; LoggerJSON is the adopter's formatter choice.

### Sibling Library Integration (optional deps, all must compile-out-clean)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `sigra` | Current stable | Auth/session reliability — login journey SLO | v0.1 — first business-critical SLO slice; validates the sibling-lib integration pattern |

All other sibling integrations (chimeway, mailglass, threadline, rulestead, accrue, rindle) are deferred post-v0.1 per PROJECT.md.

### Development / CI Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `ex_doc` | Documentation generation | Standard for Elixir OSS; publish to HexDocs |
| `credo` | Static analysis / code style | Run with `--strict` in CI |
| `dialyxir` | Type analysis via Dialyzer | Run in CI; slow on first run, cache PLT |
| `mix format --check-formatted` | Formatting enforcement | Hard CI gate |
| `mix compile --warnings-as-errors` | Compilation warnings | Hard CI gate |
| Release Please | Changelog + version automation | Conventional Commits → automated releases; inherited from sibling libs |
| GitHub Actions | CI/CD | `erlef/setup-beam@v1` for Elixir matrix; SHA-pin all actions |
| `mix hex.audit` | Dependency vulnerability audit | Run in CI lint lane |
| `promtool` | Prometheus rule validation | Validate generated `.yml` alert/recording rules in CI |

---

## Installation (mix.exs)

```elixir
# Core deps (always required)
{:telemetry_metrics, "~> 1.0"},
{:telemetry_poller, "~> 1.1"},

# Optional: PromEx adapter
{:prom_ex, "~> 1.11", optional: true},

# Optional: OpenTelemetry (traces)
{:opentelemetry_api, "~> 1.4", optional: true},
{:opentelemetry, "~> 1.5", optional: true, runtime: false},
{:opentelemetry_exporter, "~> 1.8", optional: true},
{:opentelemetry_phoenix, "~> 2.0", optional: true},
{:opentelemetry_cowboy, "~> 1.0", optional: true},
{:opentelemetry_ecto, "~> 1.2", optional: true},
{:opentelemetry_liveview, "~> 1.0", optional: true},
{:opentelemetry_logger_metadata, "~> 0.3", optional: true},

# Optional: Sigra integration (v0.1 login SLO)
{:sigra, "~> x.x", optional: true},

# Dev-only
{:credo, "~> 1.7", only: [:dev, :test], runtime: false},
{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
{:ex_doc, "~> 0.34", only: :dev, runtime: false},
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| PromEx as default metrics adapter | `telemetry_metrics_prometheus_core` alone | When adopter explicitly wants no PromEx dependency; Parapet should support this via adapter pattern |
| Peep as high-performance alternative | (same as above) | At very high request volume where scrape latency matters; Parapet should document the swap |
| Grafana Alloy for log/trace collection | OTel Collector | Both work; Alloy is preferred in Grafana-stack shops; OTel Collector is preferred when backend-agnostic is required |
| Grafana + Prometheus for dashboards/alerting | OpenObserve, SigNoz | OpenObserve/SigNoz are valid for smaller self-hosted setups; Parapet should generate Prometheus/Grafana artifacts first as the dominant ecosystem choice |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Promtail | EOL March 2, 2026; official docs redirect to Grafana Alloy | Grafana Alloy |
| Grafana Agent (Static/Flow/Operator) | EOL November 1, 2025 | Grafana Alloy |
| OpenTelemetry for Elixir metrics/logs | Marked "Development" (not Stable) in the OTel Erlang/Elixir SDK; tracing only is Stable | `:telemetry` + Telemetry.Metrics + PromEx/Peep for metrics; LoggerJSON + structured output for logs |
| High-cardinality metric labels | Every unique label set creates a separate time series in Prometheus; `user_id`, `email`, `request_id`, `trace_id`, `order_id` will explode cardinality and cost | Low-cardinality labels only (`:route`, `:method`, `:status_class`, `:queue`, `:worker`, `:provider`, `:env`) |
| Raw Phoenix path params as metric labels | Unbounded path segments (e.g., `/users/:id`) create unbounded series | Use Phoenix route patterns (e.g., `/users/:id` as the pattern string, not the resolved value) |
| `telemetry_metrics_prometheus` (full, not core) | Ships its own HTTP server on port 9568 without HTTPS support; creates security footgun | Use PromEx.Plug or core reporter behind the Phoenix endpoint with auth |

---

## Stack Patterns by Variant

**If adopter already uses PromEx:**
- Wire Parapet's metric definitions into their existing PromEx module
- Parapet's Grafana dashboard artifacts complement PromEx's plugin dashboards rather than replacing them

**If adopter does not use PromEx:**
- Use `telemetry_metrics_prometheus_core` as the minimal reporter
- Document this as the "minimal" path; Parapet's SLO recording rules still work

**If adopter uses Oban:**
- Enable the Oban telemetry integration via optional dep
- Job SLO slice activates automatically on Oban telemetry events

**If adopter does not use Oban:**
- Oban dep compiles out cleanly; job SLO slice is simply unavailable
- `mix parapet.doctor` warns if Oban is detected in deps but integration is not configured

**If adopter wants distributed tracing:**
- Add OTel packages as hard deps in host app
- Parapet's OTel adapter activates; wide events gain trace/span correlation
- Mark `:opentelemetry` as `:temporary` in release config

**If adopter wants Grafana Cloud (simplest start):**
- Use Grafana Alloy on host (scrapes `/metrics`, tails logs, receives OTLP traces)
- Point Alloy at Grafana Cloud endpoints
- Parapet ships Grafana dashboard JSON importable directly into Grafana Cloud

**If adopter wants self-hosted Grafana stack:**
- Prometheus + Grafana + Loki + Tempo + Grafana Alloy + Alertmanager
- Parapet generates provisioning files for this layout:
  `priv/parapet/grafana/dashboards/*.json`
  `priv/parapet/grafana/provisioning/*.yml`
  `priv/parapet/prometheus/rules/*.yml`

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `prom_ex ~> 1.11` | Phoenix latest+previous, Ecto latest+previous | PromEx endpoint ordering matters: PromEx.Plug must come before Plug.Telemetry |
| `opentelemetry ~> 1.5` | Elixir 1.13+, Erlang 23+ | Mark as `:temporary` in releases |
| `opentelemetry_phoenix ~> 2.0` | Phoenix latest+previous; requires Cowboy adapter config | `OpentelemetryPhoenix.setup(adapter: :cowboy2)` |
| `peep ~> 5.0` | Elixir/OTP current stable | v5.0.1 published April 2026; API stable |
| Elixir 1.16–1.18 × OTP 26–27 | Full test matrix | Match sibling lib matrix; add OTP 28 when stable |

---

## Collector / Agent Layer (adopter infrastructure, not Parapet code)

Parapet itself does not ship a collector. Adopters need one between the Phoenix app and their observability backend. Recommend:

| Collector | When to Use |
|-----------|-------------|
| **Grafana Alloy** | Default recommendation; handles metrics scrape, log tailing, OTLP traces; modern replacement for Promtail + Grafana Agent |
| **OTel Collector** | When adopter wants backend-agnostic collection or vendor-neutral OTLP pipeline |

Generate a documented or templated Alloy config as a Parapet artifact so adopters do not hand-author it.

---

## Parapet's Own mix.exs Structure

```elixir
defp package do
  [
    name: "parapet",
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/szTheory/parapet"},
    files: ~w(
      lib
      priv/parapet
      mix.exs
      README.md
      CHANGELOG.md
      LICENSE
    )
  ]
end
```

Never ship `.planning/`, `prompts/`, example hosts, or development artifacts. The `files:` whitelist is a hard constraint from sibling lib DNA.

---

## Sources

- `prompts/elixir-telemetry-space-deep-research.md` — HIGH confidence; comprehensive 2026 Elixir observability ecosystem survey with live Hex version checks
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — HIGH confidence; prior art analysis and ecosystem gap analysis for Parapet's domain
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — HIGH confidence; authoritative constraints from established sibling lib patterns
- `prompts/prior-art/rulestead-telemetry-observability-and-audit.md` — HIGH confidence; production-grade telemetry/audit patterns from sibling lib
- Hex package page for `peep` — version 5.0.1, April 2026 (verified current)
- Hex package page for `sentry` — version 13.0.1, May 2026 (context only; not a Parapet dep)
- Grafana Alloy docs — Promtail EOL March 2, 2026; Grafana Agent EOL November 1, 2025 (verified)
- OpenTelemetry Erlang/Elixir official docs — Traces: Stable; Metrics: Development; Logs: Development (verified)

---

*Stack research for: Parapet — Phoenix reliability layer (Elixir OSS library)*
*Researched: 2026-05-09*
