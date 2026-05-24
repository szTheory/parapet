# Parapet Troubleshooting

This guide answers the five most common obstacles you will hit after following [Parapet Getting Started](docs/getting-started.md). Each section names the exact surface involved so you can confirm the fix against your specific setup.

For UI-specific doctor checks, see [Parapet Operator UI Guide](docs/operator-ui.md).

## Prometheus target is blank

If Prometheus shows no metrics from your app, the most common causes are a missing metrics plug and a missing `/metrics` route.

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
