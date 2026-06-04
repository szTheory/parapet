# Parapet Demo App

A runnable Phoenix app for looking at Parapet before wiring it into your own app.
It starts a seeded Operator UI with incidents, timelines, runbook steps, action
items, history, Prometheus, and Grafana already populated.

## Fastest Path

From the repository root, use automatic port selection if you are running other
Docker UI demos or local admin tools:

```bash
cd examples/demo_app
make up-auto
```

For the fixed default ports, run:

```bash
cd examples/demo_app
make up
```

When the stack is ready, the command prints the URLs to open:

```bash
http://127.0.0.1:<web-port>/parapet
http://127.0.0.1:<web-port>/parapet/actions
http://127.0.0.1:<web-port>/parapet/history
http://127.0.0.1:<grafana-port>/d/parapet_demo/parapet-demo-operator-evidence
http://127.0.0.1:<prometheus-port>
curl -f http://127.0.0.1:<web-port>/parapet
```

Grafana anonymous viewer access is enabled for the local demo. The command also
prints the admin login from `.env`; the default is `admin` / `parapet`.

Stop it with:

```bash
make down
```

That is enough for a first look. Docker keeps Postgres inside the Compose
network by default, so this demo should not fight with another local Postgres on
`5432`. In auto mode, the web UI, Grafana, and Prometheus all get generated
localhost ports and the command prints the actual URLs.

## What To Look At

- `/parapet` opens with a calm active-response overview: are users being hurt,
  what evidence is newest, and what is the next safe operator action?
- `/parapet/actions` is the pending recovery-work lane. It points operators back
  to incident evidence before recovery work.
- `/parapet/history` is the resolved-incident review lane for evidence and
  retrospectives.
- Incident detail pages show the full timeline, runbook state, external links,
  tool audits, and warning copy that Parapet keeps together for operators.
- External Grafana evidence links open the local provisioned dashboard, and
  Prometheus scrapes the demo app's Parapet HTTP metrics on the Compose network.

## Demo Scenarios

The default seed scenario is `all`, which keeps the full UI state matrix for
testing. For a focused first look, use one of the scenario targets:

```bash
make up-response
make up-recovery
make up-escalation
make up-history
```

You can also choose explicitly:

```bash
make scenario SCENARIO=response
```

Available scenarios are:

- `response` - focused active response with open/investigating incidents.
- `recovery` - capability-backed recovery preview/confirm flow.
- `escalation` - pending, suppressed, and short-circuited escalation examples.
- `history` - resolved incident evidence and retrospective.
- `all` - complete state matrix used by CI and broad screenshot checks.

Changing scenarios requires `make reset` or a fresh `COMPOSE_PROJECT_NAME`,
because the entrypoint skips seeds once the database already contains incidents.

## Docker Compose

Use the default fixed web port when `4000` is free:

```bash
make up
```

The web port is bound to `127.0.0.1` and defaults to `4000`. Grafana defaults to
`3000`; Prometheus defaults to `9090`. Edit `.env` or pass `WEB_PORT=4001 make up`
if another project is already using a port in fixed-port mode.

Use automatic port selection when you are running multiple UI demos or another
project already owns `4000`, `3000`, or `9090`:

```bash
make up-auto
```

Then reprint the discovered URLs at any time:

```bash
make urls
```

In auto-port mode, Parapet writes generated settings to `.docker/auto.env` and
uses them for `make urls`, `make down`, and `make reset`. The Operator UI seed
data receives the generated Grafana URL, so external evidence links point at the
same local dashboard URL that `make up-auto` prints.

If another process grabs a generated port between selection and container
startup, rerun `make up-auto`; it will generate a fresh set of ports.

If you need host `psql` access, expose Postgres explicitly:

```bash
make up-db-port
```

Then stop the demo:

```bash
make down
```

Remove demo volumes when you want a clean database and clean container build
artifacts:

```bash
make reset
```

Compose resources are scoped by `COMPOSE_PROJECT_NAME`, which defaults to
`parapet_demo` in `.env.example`. Auto mode generates a stable project name from
your user and repo path unless you provide `COMPOSE_PROJECT_NAME` yourself.
Changing the project name also changes which named volumes Compose uses.

The printed Grafana credentials come from `GRAFANA_ADMIN_USER` and
`GRAFANA_ADMIN_PASSWORD` in `.env`. Anonymous viewer access is enabled because
the stack is local demo infrastructure, not a production recommendation.

For local reverse-proxy setups, keep Traefik optional: attach `web` to your
shared proxy network, add labels for a `.localhost` hostname, and avoid publishing
the app or database ports directly. The default demo does not require Traefik
because a proxy adds another fixed-port service and Docker socket/routing
configuration; `make up-auto` is the simpler conflict-free path.

## Run Without Docker

If you already have PostgreSQL running locally on `5432` with user `postgres` and
password `postgres`, you can run the Phoenix app directly:

```bash
mix setup
mix phx.server
```

Then open http://localhost:4000/parapet.

## Styling

The Operator UI uses Tailwind CSS. In development, styles are built automatically via the
`tailwind` Hex package. If the page appears unstyled, run:

```
mix assets.build
```

## Production Safety

Parapet does not provide its own auth. The `/parapet` route in this demo app is intentionally
open (unauthenticated) so that the smoke test can verify the Operator UI loads without a
redirect. **Production deployments must wrap these routes in an authenticated scope** using
the host application's auth plugs (e.g., `pipe_through [:browser, :require_authenticated_user]`).

See the [Parapet docs](https://hexdocs.pm/parapet) for the authenticated router pattern and
the `mix parapet.gen.ui` generator output.

## What This Demo Shows

- `DemoApp.Repo` registered as the `:parapet` repo
- `Parapet.SLO.StarterPack.WebSaaS` as the default SLO provider
- Demo-only Peep reporter exposing `/metrics` through the Phoenix endpoint for
  Prometheus
- Provisioned local Prometheus and Grafana, including a clickable seeded Grafana
  evidence link
- The full Parapet spine migration (incidents, timelines, tool audits, SLOs, runbooks)
- The generated Operator UI LiveView modules: `DemoAppWeb.Parapet.OperatorLive` and
  `DemoAppWeb.Parapet.OperatorDetailLive`
- Seeded scenarios, timeline entries, and runbook data (see `priv/repo/seeds.exs`
  and `priv/repo/demo_seed_scenarios.exs`)

## Hex Package Note

This demo app is excluded from the published Hex package (see `files:` in the root `mix.exs`).
It is included in the source repository for CI verification only.
