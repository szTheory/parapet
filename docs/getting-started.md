# Parapet Getting Started

Parapet is a reliability operating loop for Phoenix SaaS teams that turns your existing telemetry into SLO-backed burn-rate alerts — with zero raw PromQL.

This guide takes you from a fresh install to your first generated Prometheus alert. If you want the mental model before diving in, read [Parapet Adopter Flows](docs/adopter-flows.md) first.

## Prerequisites

- An existing Phoenix application with `mix` available
- Prometheus set up to scrape your app (or planned)
- Parapet `~> 0.10` available on [hex.pm](https://hex.pm/packages/parapet)

## Step 1: Add the dependency

Add `:parapet` to your `mix.exs` deps:

```elixir
def deps do
  [
    {:parapet, "~> 0.10"}
  ]
end
```

Then fetch it:

```bash
mix deps.get
```

## Step 2: Run the installer

Run the install task to scaffold the host-owned instrumenter, wire the metrics plug into your endpoint, and generate the deploy hook:

```bash
mix parapet.install
```

This writes the instrumenter module, configures `:instrumenter` in your app config, adds `Parapet.Plug.Metrics` to your endpoint, and creates `rel/hooks/post_start.sh` with a deploy marker. It does **not** activate any SLO providers — that is the next step.

## Step 3: Activate the WebSaaS starter pack

Add the built-in starter pack to your `config/config.exs`:

```elixir
config :parapet,
  providers: [Parapet.SLO.StarterPack.WebSaaS]
```

This one line is the entire SLO activation. You write **zero raw PromQL** — the WebSaaS pack passes metric names and label matchers to the Generator, which renders all PromQL expressions automatically (recording rules, alert thresholds, and the `min_total_rate` denominator guard).

The WebSaaS pack ships three slices:

- `web_saas_http_availability` — HTTP request success ratio (backed by `parapet_http_request_count`)
- `web_saas_login_journey` — Login success ratio (backed by `parapet_journey_login_count`)
- `web_saas_oban_job_success` — Oban job success ratio (backed by `parapet_oban_jobs_total`)

**Login slice prerequisite:** The `web_saas_login_journey` slice relies on `parapet_journey_login_count`, which is emitted by the Sigra integration. If you have not wired Sigra (or another emitter that fires `[:parapet, :journey, :login]`), the login slice has no data. The `min_total_rate` guard prevents false-positive alerts when data is absent, but no data is not the same as green. See [Parapet Sigra Integration](docs/integrations/sigra.md) to wire the login metric.

## Step 4: Generate Prometheus files

Run the Prometheus generator:

```bash
mix parapet.gen.prometheus
```

This reads your active providers and writes three files under `priv/parapet/prometheus/`:

- `recording_rules.yml` — pre-computation recording rules for all SLO ratio and rate series
- `alerts.yml` — multi-burn-rate alert rules; **this is your first generated alert**
- `rules.yml` — compatibility aggregate combining both recording rules and alerts

Load `recording_rules.yml` and `alerts.yml` into your Prometheus setup. The `rules.yml` file is a compatibility aggregate for setups that prefer a single rules file.

## Step 5: Validate your setup

Run the doctor task to check for obvious contradictions before deploying:

```bash
mix parapet.doctor
```

The doctor runs static checks: endpoint plug presence, `/metrics` router exposure, escalation worker uniqueness, and SLO runbook coverage. By default it exits `1` only when a finding is `:error`.

For CI pipelines, use the stricter gate:

```bash
mix parapet.doctor --ci
```

With `--ci`, the doctor exits `1` for any `:warn` or `:error` finding — a stricter threshold that catches configuration risks before they reach production. Local runs use the `:error` threshold so minor warnings do not block iterative development.

## Next steps

- [Parapet Adopter Flows](docs/adopter-flows.md) — understand the reliability operating loop and when each surface matters
- [SLO Authoring Guide](docs/slo-authoring-guide.md) — learn to author custom SLO slices for your specific journeys
- [Parapet Sigra Integration](docs/integrations/sigra.md) — wire the login journey slice with real authentication event data
