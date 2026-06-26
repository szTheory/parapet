# Parapet Demo App

A runnable Phoenix app for looking at Parapet before wiring it into your own app.
It starts a seeded Operator UI with incidents, timelines, runbook steps, action
items, history, Prometheus, and Grafana already populated.

> **Full walkthrough:** [docs/demo-app.md](../../docs/demo-app.md) — gallery,
> full demo, running several stacks at once, hot-reload, macOS gotchas, and
> troubleshooting. This README is the quick version.

## Fastest Path

`make up` is **conflict-free by default** — it picks free ports automatically, so
it's safe to run alongside your other Docker UI demos:

```bash
cd examples/demo_app
make up               # full seeded demo (web + Postgres), lean
# …or just the components, no Docker/database, on a free port:
make gallery
```

When the stack is ready, `make up` prints the URLs to open (Operator UI,
Actions, History) plus the Compose project name and stop/reset commands.

- `make up-monitoring` — also start Grafana + Prometheus (evidence links).
- `make up-proxy` — reach the demo at `http://parapet.localhost` (no ports to
  remember); see [docs/demo-app.md](../../docs/demo-app.md).
- `make up-fixed` — classic fixed `4000` / `3000` / `9090` ports.
- `make down` — stop.

Postgres stays inside the Compose network (no host `5432`), so it won't fight a
local Postgres. Grafana anonymous viewer access is enabled for the demo; the
printed login defaults to `admin` / `parapet`.

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

| Command | What it does |
|---------|--------------|
| `make up` | **Default.** Web + Postgres on auto-selected free ports (conflict-free). Retries once if a port is grabbed mid-launch. |
| `make up-monitoring` | Adds Prometheus + Grafana (the `monitoring` profile). |
| `make up-proxy` | Routes through the shared `*.localhost` proxy — see [`dev-proxy/README.md`](dev-proxy/README.md). |
| `make up-fixed` | Classic fixed `4000` / `3000` / `9090` (full stack). |
| `make up-db-port` | Expose Postgres on the host for `psql`. |
| `make urls` | Reprint the running stack's URLs. |
| `make down` / `make reset` | Stop / stop + drop volumes. |

Auto-port mode writes generated settings to `.docker/auto.env` (reused by `urls`
/ `down` / `reset`), and the Operator UI seed gets the generated Grafana URL so
evidence links resolve. Compose resources are scoped by `COMPOSE_PROJECT_NAME`
— auto mode derives a stable one from your user + repo path, so multiple stacks
never share volumes or networks. Grafana credentials come from `.env`
(`GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD`); anonymous viewer access is on
for the demo only.

See [docs/demo-app.md](../../docs/demo-app.md) for running several stacks at
once, the `*.localhost` proxy, hot-reload, macOS gotchas, and troubleshooting.

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
