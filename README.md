# Parapet

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

Then install and configure Parapet with:

```bash
mix deps.get
mix parapet.install
```

This will automatically wire Parapet into your Phoenix Endpoint and create a default SLO configuration file.

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

Run the Parapet Doctor to ensure your configuration is secure and complete. The doctor ensures all your SLOs have runbooks and that your Prometheus metrics endpoint is authenticated.

```bash
mix parapet.doctor
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

Parapet can generate an optional, evidence-first LiveView operator workbench directly inside your host application. This UI is used for initiating mitigations and tracking immutable timeline events.

For instructions on generating the UI and securing its routes, see the [Operator UI Guide](docs/operator-ui.md).

### 6. Deploy Markers

Parapet can automatically track your deployments. Simply add the `Parapet.Plug.DeployMarker` to your authentication or administration pipeline:

```elixir
pipeline :admin do
  plug :require_authenticated_admin
  plug Parapet.Plug.DeployMarker
end
```

Then, trigger a deploy marker via a webhook or internal API to annotate your Grafana graphs with deployment events.

## Advanced Usage

For more detailed information, check the [Documentation](https://hexdocs.pm/parapet).

## License

MIT License. See `LICENSE` for details.
