# Parapet Demo App

A runnable Phoenix app demonstrating the Parapet Operator UI. This is a self-contained
example showing how Parapet integrates with a Phoenix application.

## Quick Start

Clone the repo, run `mix setup`, then `mix phx.server`.

The demo serves the Operator UI at http://localhost:4000/parapet.

If seeds fail, verify PostgreSQL is running on localhost:5432 with user `postgres` / password `postgres`.

## Styling

The Operator UI uses Tailwind CSS. In development, styles are built automatically via the
`tailwind` Hex package. If the page appears unstyled, run:

```
mix assets.build
```

## WARNING: demo only — do not copy router config to production.

Parapet does not provide its own auth. The `/parapet` route in this demo app is intentionally
open (unauthenticated) so that the smoke test can verify the Operator UI loads without a
redirect. **Production deployments must wrap these routes in an authenticated scope** using
the host application's auth plugs (e.g., `pipe_through [:browser, :require_authenticated_user]`).

See the [Parapet docs](https://hexdocs.pm/parapet) for the authenticated router pattern and
the `mix parapet.gen.ui` generator output.

## What This Demo Shows

- `DemoApp.Repo` registered as the `:parapet` repo
- `Parapet.SLO.StarterPack.WebSaaS` as the default SLO provider
- The full Parapet spine migration (incidents, timelines, tool audits, SLOs, runbooks)
- The generated Operator UI LiveView modules: `DemoAppWeb.Parapet.OperatorLive` and
  `DemoAppWeb.Parapet.OperatorDetailLive`
- Seeded incidents, timeline entries, and runbook data (see `priv/repo/seeds.exs`)

## Hex Package Note

This demo app is excluded from the published Hex package (see `files:` in the root `mix.exs`).
It is included in the source repository for CI verification only.
