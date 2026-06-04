# Migrating to Parapet 1.x

Use this guide when you are moving an application from a pre-1.0 Parapet release to the stable 1.x line. It focuses on the checks and code changes that affect adopters. For older milestone history, see [Parapet Milestone History](HISTORY.md) instead of treating this page as a changelog.

## Step 1: Read the stability boundary

Parapet 1.x freezes the Stable public API and telemetry contract described in [Stability & Deprecation Policy](stability.md). Stable modules, callback contracts, telemetry event names, measurement keys, and metadata keys do not change without a major-version bump and a full deprecation cycle.

Experimental modules can still change in minor releases. Internal modules are not part of the adopter contract. Before upgrading, check whether your application calls only Stable modules or whether it has opted into Experimental surfaces such as the MCP server, generated Operator UI helpers, automation internals, or low-level metric modules.

## Step 2: Update the dependency

Move your dependency constraint from the pre-1.0 line to the 1.x line:

```elixir
def deps do
  [
    {:parapet, "~> 1.0"}
  ]
end
```

Then fetch and compile:

```bash
mix deps.get
mix compile --warnings-as-errors
```

If you are upgrading from an older source checkout rather than a Hex release, review [CHANGELOG.md](../CHANGELOG.md) and [Parapet Milestone History](HISTORY.md) for the historical path. Do not copy old setup snippets forward blindly; use [Parapet Getting Started](getting-started.md) as the current install reference.

## Step 3: Move custom SLOs to providers

`Parapet.SLO.define/2` is hard-deprecated in 1.x. Replace call-site definitions with a module that implements `Parapet.SLO.Provider`, then register that provider through `Parapet.attach/1`.

```elixir
defmodule MyApp.Parapet.SLOs do
  @behaviour Parapet.SLO.Provider

  @impl true
  def slos do
    [
      %Parapet.SLO.SliceSpec{
        name: :checkout_availability,
        objective: 99.9,
        numerator: "my_app_checkout_success_total",
        denominator: "my_app_checkout_total"
      }
    ]
  end
end
```

Then activate it through Parapet's provider configuration:

```elixir
config :parapet,
  providers: [MyApp.Parapet.SLOs]
```

`Parapet.attach/1` activates integration adapters through `:adapters`; it does not
register SLO providers. Put providers in config so Parapet can load them consistently
during boot and generator runs.

The old function remains available for the deprecation window, but it emits compile-time warnings. Treat those warnings as upgrade blockers now so a future major release is uneventful.

## Step 4: Re-check generated host surfaces

Run the installer or generators in a branch and review the diff. Parapet's generated files remain host-owned, so the upgrade is not an instruction to overwrite local endpoint, router, or LiveView customizations.

```bash
mix parapet.install
mix parapet.gen.prometheus
mix parapet.doctor
```

Confirm these surfaces still match your application:

- `Parapet.Plug.Metrics` is wired where Prometheus can scrape it.
- Generated Prometheus files under `priv/parapet/prometheus/` are loaded by your Prometheus deployment.
- Operator UI routes, if present, live inside your authenticated Phoenix scope.
- Deploy marker hooks still call `Parapet.Deploy.mark/1`.

## Step 5: Review recovery and operator surfaces

Recovery capabilities use the Stable `Parapet.Recovery` four-callback contract: `id/0`, `label/0`, `preview/2`, and `execute/2`. If you adopted recovery actions before 1.0, verify each capability still uses the allowlisted capability id atoms and still returns preview data that operators can understand before confirming a mutation.

Operator action return values are additive in the 1.x line. If your code pattern-matches `Parapet.Operator.confirm_runbook_step/4`, handle `{:ok, result}`, `{:error, reason}`, `{:short_circuited, reason}`, and `{:conflicted, claim_id}`.

## Step 6: Run the safe-upgrade checklist

Run these checks before merging the upgrade:

```bash
mix compile --warnings-as-errors
mix test
mix parapet.doctor --ci
```

Then verify the deployed environment:

- Prometheus is scraping the host application's metrics endpoint.
- The generated recording and alert rules are loaded.
- Deploy markers appear after a release.
- The Operator UI, if mounted, is protected by host-app authentication.
- Any recovery capabilities can preview safely before executing.

When those checks pass, the application is on the 1.x contract and can use normal patch and minor upgrades under the stability policy.
