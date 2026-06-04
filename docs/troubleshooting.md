# Parapet Troubleshooting

This guide answers common obstacles you may hit after following [Parapet Getting Started](getting-started.md). Each section names the exact surface involved so you can confirm the fix against your specific setup.

For UI-specific doctor checks, see [Parapet Operator UI Guide](operator-ui.md).

## When to run archive maintenance

Run archive maintenance with the existing Mix task:

```bash
mix parapet.archive
mix parapet.archive --days 30
mix parapet.archive --path priv/parapet/archive.jsonl
```

The default `--path` is `priv/parapet/archive.jsonl`. A successful run writes a
JSONL archive artifact plus a sidecar manifest and prints JSON with `status`,
`run_id`, `path`, `manifest_path`, `retention_days`, `cutoff`,
`selected_count`, `archived_count`, `deleted_count`, `skipped_count`,
`bytes_written`, and `checksum`.

Use it for routine resolved-incident retention, before widening retention or pruning old evidence, and after confirming host backups cover host-owned data.
Parapet archive maintenance is operational evidence export/prune for Parapet-owned records, not host backup/restore. Retention currently means resolved incidents created before the cutoff (`inserted_at < cutoff`), not incidents resolved before the cutoff.

## Archive failures before pruning

An archive can fail before any prune occurs during the `write`, `verify`,
`manifest`, or `publish` work. The CLI reports the failing `stage`, `run_id`,
`path`, `manifest_path`, selected/archived/deleted counts, and `reason` so you
can tell whether the JSONL file, manifest, destination path, or verification
step failed.

Fix the reported file, manifest, repo, retention, path, or delete issue first.
A safe rerun depends on fixing that underlying issue; rerunning without changing
anything should produce the same failure.

## Delete-stage archive failures

A delete-stage failure is different from a write, verify, manifest, or publish
failure. At the delete stage, the JSONL artifact and manifest can already be
published while the database prune did not complete.

Inspect `stage`, `run_id`, `path`, `manifest_path`, `selected_count`,
`archived_count`, `deleted_count`, and `reason`. If `stage` points at delete
work, confirm the archive artifact and manifest exist, fix the delete problem,
and then rerun. The selected records are pruned only after the export and
manifest stages succeed.

## Missing Parapet repo config

`mix parapet.archive` needs the host app to configure the Parapet repo:

```elixir
config :parapet, :repo, MyApp.Repo
```

If the task raises before printing success JSON, confirm that
`config :parapet, :repo` is present in the runtime config loaded by the Mix
environment you are using.

## Invalid retention or path usage

Use a positive integer for `--days` and a writable path for `--path`:

```bash
mix parapet.archive --days 30
mix parapet.archive --path priv/parapet/archive.jsonl
```

If `--days` is invalid, fix the retention value before rerunning. If `--path`
points at a missing or unwritable directory, create the directory or choose a
writable path before rerunning.

## Stale generated UI files still point at `/parapet`

If stale generated UI files still point at `/parapet`, the generated links
likely predate scoped route support. Generated Operator UI files are host-owned,
so older workbench files can still point directly at `/parapet` instead of
deriving paths through `operator_base_path`.

Regenerate the UI files, or regenerate or manually port `operator_base_path` helpers into host-owned generated files. After updating, confirm links from `/ops/parapet`, `/ops/parapet/actions`, `/ops/parapet/history`, and detail pages all stay under the same scoped mount.

## Scoped Operator UI mount is visible without auth

Host apps own authentication, authorization, pipelines, live sessions, and
router scopes. If `/ops/parapet` is visible without signing in, the route map is
outside the host app's authenticated pipeline or the `live_session` protection
is missing. A scoped Operator UI mount is visible without auth when those
host-owned guards are absent.

To recover, keep routes inside the host app's authenticated pipeline and `live_session`:

```elixir
scope "/ops", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :parapet_operator,
    on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do
    live "/parapet", MyAppWeb.Parapet.OperatorLive, :index
    live "/parapet/actions", MyAppWeb.Parapet.OperatorLive, :actions
    live "/parapet/history", MyAppWeb.Parapet.OperatorLive, :history
    live "/parapet/incidents/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
    live "/parapet/:id", MyAppWeb.Parapet.OperatorDetailLive, :show
  end
end
```

## Some `/ops/parapet` links return 404

If some `/ops/parapet` links return 404, only part of the generated route map
may be mounted under the nested scope. Partial nested route maps break local
navigation. If the index route is under `/ops/parapet` but actions, history,
preferred detail, or compatibility detail routes are not mounted in the same
scope, links will fail.

The fix is to mount the whole route map under the same `/ops` scope. The
complete map includes `live "/parapet"`, `live "/parapet/actions"`,
`live "/parapet/history"`, `live "/parapet/incidents/:id"`, and
`live "/parapet/:id"`.

## Demo app Docker port conflicts

If you are running several Phoenix demos at once and the Parapet demo cannot bind
to `4000`, `3000`, or `9090`, start it with automatic port selection from the
demo app directory:

```bash
cd examples/demo_app
make up-auto
```

The command prints the actual `/parapet`, `/parapet/actions`, `/parapet/history`,
Grafana, and Prometheus URLs. It writes generated settings to
`examples/demo_app/.docker/auto.env` so `make urls`, `make down`, and
`make reset` keep targeting the same generated Compose project.

If another process grabs a generated port between selection and container
startup, rerun:

```bash
make up-auto
```

Refresh the URLs after any restart before copying links:

```bash
make urls
```

The demo intentionally does not publish Postgres on host port `5432` by default.
The Phoenix app reaches Postgres through the Compose network, which keeps the
demo from colliding with other local databases. If you need direct `psql` access
from your host, run:

```bash
cd examples/demo_app
make up-db-port
```

Compose resources are scoped by `COMPOSE_PROJECT_NAME`. Use a different project
name for parallel copies of the demo, but remember that changing it also changes
the volume namespace, so an existing demo database can appear to disappear until
you switch back to the original project name.

If you switch demo seed scenarios with `make up-response`, `make up-recovery`,
`make up-escalation`, `make up-history`, or `make scenario SCENARIO=...`, reset
the demo database first or use a fresh `COMPOSE_PROJECT_NAME`. The entrypoint
skips seeds once incidents already exist.

Grafana and Prometheus are part of the default demo stack. `make up` binds them
to `127.0.0.1:${GRAFANA_PORT:-3000}` and
`127.0.0.1:${PROMETHEUS_PORT:-9090}`. `make up-auto` generates free localhost
ports for Grafana and Prometheus too, updates the seeded Grafana evidence URL,
and prints the local demo credentials. Anonymous viewer access is enabled for
convenience.

## Prometheus target is blank

If Prometheus shows no metrics from your app, the most common causes are a missing metrics plug and a missing `/metrics` route or reporter.

Run the doctor to check both:

```bash
mix parapet.doctor
```

The doctor's `endpoint` check reads your `endpoint.ex` and emits a `:warn` finding if `Parapet.Plug.Metrics` is not present. The `router` check looks for an exposed `/metrics` route.

If either check reports a finding, add `Parapet.Plug.Metrics` to your endpoint before the request pipeline and ensure `/metrics` is reachable by your Prometheus scrape job. Also confirm that `mix parapet.gen.prometheus` has run and written the three files under `priv/parapet/prometheus/` — `recording_rules.yml`, `alerts.yml`, and `rules.yml` — and that your Prometheus instance is configured to load them.

## The doctor reports a warning but I am not sure if CI will fail

The doctor uses a severity model with three levels: `info` (0), `warn` (1), `error` (2). Which severity causes an exit code of `1` depends on the threshold in effect.

```bash
mix parapet.doctor        # threshold :error — exits 1 only on :error findings
mix parapet.doctor --ci   # threshold :warn  — exits 1 on :warn OR :error findings (stricter)
```

By default, `mix parapet.doctor` uses the `:error` threshold, so `:warn`-level findings are reported but do not fail the run. With `--ci`, the threshold drops to `:warn`, making it a stricter gate: any warning or error causes a non-zero exit. This means a finding that passes a local run can still fail CI when you add `--ci`.

To match CI behavior locally, run `mix parapet.doctor --ci` before pushing. You can also pass `--threshold warn` or `--threshold error` explicitly to override the threshold without the `--ci` flag.

## Oban metrics are missing after install

If `parapet_oban_jobs_total` does not appear in your Prometheus metrics, Oban is likely not in your dependencies.

`Parapet.Metrics.Oban` is wrapped in a compile-time conditional:

```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Metrics.Oban do
    # ...
  end
end
```

Oban is declared as `optional: true` in Parapet's `mix.exs`, so the module is silently omitted when Oban is absent. Add Oban to your application's dependencies:

```elixir
def deps do
  [
    {:oban, ">= 0.0.0"}
  ]
end
```

After adding the dep and running `mix deps.get`, restart your application. The Oban metrics module will compile and `parapet_oban_jobs_total` will appear once your workers start processing jobs.

## Concurrent nodes could execute the same escalation twice

If you are running a multi-node deployment and see duplicate escalation actions, the escalation worker is likely missing Oban's `unique:` option.

Run the doctor to surface this statically:

```bash
mix parapet.doctor
```

The `cluster_static` check reads `lib/parapet/escalation/worker.ex` and emits an `:error` finding when the worker is missing Oban uniqueness:

> "Escalation worker is missing Oban uniqueness; concurrent nodes could execute the same escalation twice."

To fix it, add a `unique:` configuration to the escalation worker's `use Oban.Worker` call. The `period` and `fields` you choose depend on your escalation semantics, but uniqueness keyed on the incident ID and escalation step prevents the same escalation from running twice across nodes within the uniqueness window.

After adding `unique:`, re-run `mix parapet.doctor` to confirm the `cluster_static` check passes.

## Fly.io: my deploy hook is not firing

When deploying on Fly.io, `mix parapet.install` writes `rel/hooks/post_start.sh` with a deploy marker call. If your deploy marker is not being recorded, confirm that the hook contains the correct content:

```sh
bin/<app_name> rpc "Parapet.Deploy.mark(version: \"$RELEASE_VERSION\")"
```

The hook calls `Parapet.Deploy.mark/1` via Elixir's remote procedure call mechanism and passes `$RELEASE_VERSION` as the version string. Verify that:

- `rel/hooks/post_start.sh` exists and is executable
- The `$RELEASE_VERSION` environment variable is set in your Fly.io release environment
- Your release build includes the `rel/hooks/` directory

For Fly.io-specific scrape configuration and firewall rules needed to expose `/metrics` to your Prometheus instance, refer to the [Fly.io documentation](https://fly.io/docs/) — the network and scrape setup is outside Parapet's scope.
