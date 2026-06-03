# Deploying Parapet

Parapet runs inside your Phoenix application. Deployment is therefore host-owned: your app controls routes, authentication, network policy, database migrations, Prometheus loading, and release orchestration. This guide names the Parapet surfaces you must wire and validate before production traffic depends on them.

## Prerequisites

- A Phoenix release or deployment path for your host app
- Prometheus scraping configured or planned
- The Parapet install and Prometheus generators available in the host app
- Database migration access for Parapet's durable evidence tables

## Step 1: Expose metrics deliberately

Parapet emits Prometheus text through `Parapet.Plug.Metrics`. The plug belongs in your endpoint or router where your Prometheus server can reach it.

Parapet does not own route authentication, admin scope, firewall rules, or network policy for `/metrics`. In production, expose metrics only to your scrape infrastructure. Do not make the endpoint public just because a local guide uses `localhost`.

Validate the static wiring with:

```bash
mix parapet.doctor --ci
```

## Step 2: Load generated Prometheus rules

Generate rule files from your active SLO providers:

```bash
mix parapet.gen.prometheus
```

The generator writes:

- `priv/parapet/prometheus/recording_rules.yml`
- `priv/parapet/prometheus/alerts.yml`
- `priv/parapet/prometheus/rules.yml`

Load the recording and alert files into your Prometheus deployment through your normal configuration management. The combined `rules.yml` file exists for setups that prefer a single include.

After Prometheus reloads, confirm that the rule files parse and that low-traffic SLOs use the generated denominator guard rather than firing on absent data.

## Step 3: Record deploy markers

Deploy markers let incidents and burn-rate windows line up with application releases.

If you use the generated install hook, confirm your release path still runs the post-start marker. For endpoint-based marking, wire `Parapet.Plug.DeployMarker` in the host app where your deployment system can call it safely. For explicit release hooks, call:

```elixir
Parapet.Deploy.mark(version: System.fetch_env!("RELEASE_VERSION"))
```

Whichever path you choose, protect it with the same ownership model as the rest of your deployment system. Parapet records the marker; your app decides who can trigger it.

## Step 4: Run durable-evidence migrations

Parapet's incident, timeline, tool audit, action claim, and system event data are durable Ecto tables in the host database. Run your application migrations before starting the release:

```bash
mix ecto.migrate
```

For releases, run the equivalent release task or remote migration command used by your Phoenix deployment platform. Do not start a release that can emit incidents before the evidence tables exist.

## Step 5: Check optional dependency compile-out

Parapet keeps several integrations optional. If a sibling library is absent, the related module compiles out instead of forcing the dependency into your app. Common examples include Oban-backed workers, integration adapters, and optional telemetry bridges.

This means a missing metric can be a dependency/configuration issue rather than a runtime failure. For example, Oban job metrics require Oban in your host application's dependencies. After changing optional dependencies, recompile and restart the application:

```bash
mix compile --warnings-as-errors
```

## Step 6: Secure operator routes

If you generated the Operator UI, mount it inside an authenticated Phoenix scope or `live_session`. Parapet does not provide its own authentication system and does not decide which users are allowed to view incidents or confirm runbook steps.

Use your app's existing auth plugs, scopes, and admin policies for any operator route. The demo app intentionally leaves `/parapet` open for local smoke tests; that is not production guidance.

## Step 7: Validate the deployed app

Run the strict doctor before cutting the release:

```bash
mix parapet.doctor --ci
```

Then validate the live deployment:

- Prometheus can scrape the metrics endpoint.
- Prometheus has loaded the generated rule files from `mix parapet.gen.prometheus`.
- A deploy marker is recorded through `Parapet.Plug.DeployMarker` or `Parapet.Deploy.mark/1`.
- `mix ecto.migrate` has applied the durable-evidence migrations.
- Operator routes, if mounted, require host-app authentication.
- Optional Oban and integration-dependent surfaces are present only when their dependencies are installed.

Parapet supplies the reliability surfaces. Your Phoenix application remains the authority for exposing, securing, migrating, and operating them.
