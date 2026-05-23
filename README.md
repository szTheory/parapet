# Parapet

[![Hex.pm Version](https://img.shields.io/hexpm/v/parapet.svg)](https://hex.pm/packages/parapet)
[![HexDocs](https://img.shields.io/badge/hexdocs-online-blue)](https://hexdocs.pm/parapet/)
[![CI](https://github.com/szTheory/parapet/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/szTheory/parapet/actions/workflows/ci.yml)

**Parapet** is a zero-configuration Site Reliability Engineering (SRE) library for Elixir/Phoenix teams. 

It provides an immediate, evidence-based understanding of whether your critical user journeys are healthy, right out of the box. Instead of dashboards with arbitrary metrics, Parapet focuses on Service Level Objectives (SLOs) built on top of standard Prometheus metrics, generated via Telemetry.

Parapet's philosophy: A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## Features

- **Zero-Conf Instrumentation:** Automatically hooks into Phoenix, Ecto, and Oban telemetry.
- **Declarative SLOs:** Define your Service Level Objectives in Elixir.
- **GitOps Ready:** Generate Prometheus recording rules and alerts directly from your Elixir code.
- **Security by Default:** Includes a `mix parapet.doctor` to ensure metrics endpoints are properly secured.
- **Actionable Alerts:** Every SLO requires an actionable runbook URL.

## Installation

Add `parapet` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parapet, "~> 0.1.0"}
  ]
end
```

Then install and configure Parapet with the single Day-1 entrypoint:

```bash
mix deps.get
mix parapet.install
```

`mix parapet.install` composes the core paved road in order:

1. Generates the Parapet evidence spine
2. Scaffolds the host-owned instrumenter and wires `Parapet.Plug.Metrics`
3. Generates Prometheus recording and alert rules
4. Prints a concise summary and points you to `mix parapet.doctor`

Optional surfaces remain explicit opt-ins:

```bash
mix parapet.install --with-ui
mix parapet.install --skip-ui
mix parapet.install --with-mailglass --with-chimeway
```

The installer can generate host-owned activation code such as `Parapet.attach(adapters: [...])` and `config :parapet, providers: [...]`, but it does **not** add optional dependencies to `mix.exs`.

If you want the shortest explanation of what Parapet is trying to help an adopter do, read [Parapet Adopter Flows](docs/adopter-flows.md).

## The Operator Loop: Zero to First Alert

### 1. Define your SLOs

After installation, Parapet creates an SLO definitions file (usually in your application's `lib` directory, e.g., `lib/my_app/slos.ex`). 

You define SLOs using standard PromQL for `good_events` and `total_events`.

```elixir
defmodule MyApp.SLOs do
  require Parapet.SLO

  Parapet.SLO.define(:checkout_success_rate,
    objective: 99.9,
    good_events: ~s{sum(rate(phoenix_endpoint_http_requests_total{route="/checkout", status=~"2.."}[5m]))},
    total_events: ~s{sum(rate(phoenix_endpoint_http_requests_total{route="/checkout"}[5m]))},
    runbook: "https://notion.so/my-org/checkout-runbook"
  )
end
```

### 2. Validate your configuration

Run the Parapet Doctor immediately after install. It validates the install surface, SLO posture, and cluster-sensitive risks without pretending static analysis is enough on its own.

```bash
mix parapet.doctor
```

Doctor statuses are:

- `info`: healthy or informational
- `warn`: risk or ambiguity
- `error`: concrete contradiction or unsafe setup
- `skip`: not applicable or unavailable

Local runs fail only on `error`. CI can raise the threshold to fail on `warn` too:

```bash
mix parapet.doctor --ci
mix parapet.doctor --threshold warn
mix parapet.doctor --threshold error
```

For live cluster facts, run:

```bash
mix parapet.doctor cluster
```

### 3. Generate Prometheus Artifacts

Instead of manually keeping your Prometheus configuration in sync with your codebase, generate the recording rules and alerts directly from your SLO definitions:

```bash
mix parapet.gen.prometheus
```

This generates a `.yml` file that you can deploy to your Prometheus instance or import into your infrastructure-as-code repository.

### 4. Generate Grafana Dashboards

Parapet generates a complete set of Grafana dashboards and provisioning files based on your SLOs.

```bash
mix parapet.gen.grafana
```

This writes the dashboard JSON and provisioning YAML to `priv/parapet/grafana/`. You can configure your Grafana instance to read from these provisioning directories. Once Grafana is started and connected to your Prometheus datasource, your dashboards will appear automatically in the "Parapet" folder, displaying live SLO burn rates, error budgets, and system health metrics without any manual configuration.

### 5. Operator UI Workbench

Parapet can generate an optional, evidence-first LiveView operator workbench directly inside your host application. This UI is not part of the default install path unless you opt in with `mix parapet.install --with-ui`, and it remains host-owned.

For instructions on generating the UI and securing its routes, see the [Operator UI Guide](docs/operator-ui.md).

### 6. Synthetic Probes

Parapet provides active checks to maintain SLO signal quality using Synthetic Probes. You can define a probe by implementing the `Parapet.Probe` behavior:

```elixir
defmodule MyApp.Probes.Checkout do
  use Parapet.Probe

  @impl true
  def run do
    # Run active test logic here
    # Return :ok or {:error, reason}
    :ok
  end
end
```

To schedule probes, Parapet includes two pluggable schedulers:

- **NativeScheduler:** A standalone memory-based timer ideal for single-node setups. Configure it in your application tree:
  `{Parapet.Probe.NativeScheduler, probes: [{MyApp.Probes.Checkout, 60_000}]}`
- **ObanScheduler:** A distributed, cron-like scheduler for clustered setups without retries. Requires [Oban](https://getoban.pro/). Configure it in your Oban cron jobs:
  `{"* * * * *", Parapet.Probe.ObanScheduler, args: %{probe: to_string(MyApp.Probes.Checkout)}}`

### 7. Deploy Markers

Parapet can automatically track your deployments. Simply add the `Parapet.Plug.DeployMarker` to your authentication or administration pipeline:

```elixir
pipeline :admin do
  plug :require_authenticated_admin
  plug Parapet.Plug.DeployMarker
end
```

Then, trigger a deploy marker via a webhook or internal API to annotate your Grafana graphs with deployment events.

## Advanced Usage

### Optional Async And Delivery Integrations

Parapet's async and delivery contract is host-owned and explicit. To enable the built-in adapters, opt in through `Parapet.attach/1`:

```elixir
Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])
```

If you also want the built-in SLO providers, register them explicitly in config:

```elixir
config :parapet,
  providers: [
    Parapet.SLO.MailglassDelivery,
    Parapet.SLO.ChimewayDelivery,
    Parapet.SLO.RindleAsync
  ]
```

These adapters emit bounded public telemetry families such as `[:parapet, :delivery, :provider_feedback]` and `[:parapet, :async, :backlog]`. Exact identifiers are kept in `metadata.refs`, not top-level labels.

For the full contract, safe metadata rules, and event-family semantics, see [docs/telemetry.md](docs/telemetry.md).

## Learn The Flows

- [Parapet Adopter Flows](docs/adopter-flows.md)
- [Operator UI Guide](docs/operator-ui.md)
- [SLO Reference](docs/slo-reference.md)
- [Telemetry Contract](docs/telemetry.md)

For more detailed information, check the [Documentation](https://hexdocs.pm/parapet).

## License

MIT License. See `LICENSE` for details.
