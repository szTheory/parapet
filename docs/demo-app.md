# Running the Parapet demo

> **TL;DR — pick your job, copy one command.**
>
> | I want to… | Run this | Opens |
> |------------|----------|-------|
> | **See the components** (instant, no Docker, no database) | `cd examples/demo_app && make gallery` | prints `http://127.0.0.1:<free-port>/parapet/_gallery` |
> | **Run the full seeded demo** (Operator UI + Postgres) | `cd examples/demo_app && make up` | prints `http://127.0.0.1:<free-port>/parapet` |
> | **…with Grafana + Prometheus** | `make up-monitoring` | also prints the Grafana/Prometheus URLs |
> | **…at a stable hostname** (no ports to remember) | `make up-proxy` | `http://parapet.localhost/parapet` |
>
> `make up` is **conflict-free by default** — run it next to your other demo
> stacks and it picks free ports automatically. Stop with `make down`.

This guide is for looking at Parapet before installing it: a seeded Operator UI
with incidents, timelines, runbooks, action items, and (optionally) live
Prometheus + Grafana evidence links.

---

## Just the gallery (fastest, zero infra)

The component gallery renders every Operator-UI component with in-memory
fixtures — **no Docker, no Postgres**, on a free loopback port:

```bash
cd examples/demo_app
make gallery          # serve until Ctrl-C; prints the light + dark URLs
make gallery-shot     # capture light/dark desktop+mobile PNGs and exit
```

Use this when you're iterating on component styling or want a quick visual
check. It's the lightest path and never touches a database.

---

## The full demo (Docker)

```bash
cd examples/demo_app
make up               # web + Postgres, conflict-free ports, lean
```

When the stack is healthy, the command prints everything you need — Operator UI,
Actions, History, the compose project name, and stop/reset commands. Postgres
stays inside the Compose network (no host `5432` binding), so it won't fight a
local Postgres.

Add the observability stack when you want the Grafana evidence links live:

```bash
make up-monitoring    # web + Postgres + Prometheus + Grafana
```

Grafana ships with anonymous viewer access for the demo; the printed login
(default `admin` / `parapet`) comes from `.env`.

### Demo scenarios

```bash
make up-response      # active response (open / investigating)
make up-recovery      # capability-backed recovery preview/confirm
make up-escalation    # pending / suppressed / short-circuited escalation
make up-history       # resolved incidents + retrospective
```

Scenarios include the monitoring stack. Switching scenarios needs `make reset`
first (the seeder skips once incidents exist).

### Stop / reset

```bash
make down             # stop containers
make reset            # stop + drop volumes (clean database)
make urls             # reprint the URLs for the running stack
```

---

## Running several stacks at once

This is the common case when you maintain multiple OSS demos. Two options:

### Option A — auto-port (default, nothing to set up)

`make up` already routes through a per-project port allocator: it hashes your
repo path + user to a **stable, free** set of ports and a unique Compose project
name, so two stacks never collide. If a port gets grabbed between allocation and
launch, `make up` reselects and retries once. Nothing to configure.

```bash
# terminal 1
cd ~/projects/parapet/examples/demo_app && make up   # e.g. :4389

# terminal 2 (another lib, or a second checkout)
cd ~/projects/other-lib/examples/demo_app && make up # different free port
```

### Option B — `*.localhost` hostnames (no ports to remember)

Run one shared Caddy reverse proxy once, then reach every project at a stable
hostname like `parapet.localhost`. See
[`examples/demo_app/dev-proxy/README.md`](../examples/demo_app/dev-proxy/README.md).

```bash
# one-time, from examples/demo_app/dev-proxy/
docker network create dev-proxy-net
docker compose up -d

# then, per project:
cd examples/demo_app
make up-proxy             # → http://parapet.localhost/parapet
make up-proxy-monitoring  # also → http://grafana.parapet.localhost
```

`.localhost` resolves to `127.0.0.1` automatically in Chrome/Edge and modern
Firefox — no `/etc/hosts` edits. The proxy is purely additive: when it isn't
running, `make up` still works via auto-port.

---

## Fast style / template iteration (no rebuilds)

You do **not** rebuild the Docker image to change styling. The dev compose
mounts your source as a volume and runs Phoenix LiveReload, so edits to
`.eex`/`.ex` templates, components, and assets **hot-reload in the browser with
no image rebuild at all**:

```bash
make up               # leave it running
# edit priv/templates/parapet.gen.ui/*.eex or examples/demo_app/lib/... and save
# → the browser reloads automatically
```

The Docker image only gets rebuilt for releases. Even then, dependencies are not
re-downloaded for a one-line code change: the Dockerfile copies `mix.exs` /
`mix.lock` before source and uses BuildKit cache mounts, so dep layers stay
cached. (Tailwind does re-scan templates on a prod `assets.deploy` — that's
inherent to class detection, and irrelevant to the dev hot-reload loop above.)

> **macOS tip:** bind-mounts are slower than native. The compose file already
> keeps `deps/` and `_build/` in named volumes (not the bind mount) to avoid
> cross-OS NIF issues and keep compiles fast. Enable **VirtioFS** in Docker
> Desktop (Settings → General) for the best file-watch performance.

---

## Ports & conflicts (how it stays clean)

- **Default is conflict-free.** `make up` allocates free ports per project; you
  don't manage numbers.
- **Lean by default.** Only web + Postgres start. Grafana/Prometheus are behind
  the `monitoring` profile (`make up-monitoring`).
- **Loopback only.** Every published port binds `127.0.0.1`, never the LAN.
- **Escape hatch.** `make up-fixed` uses the classic `4000`/`3000`/`9090` if you
  specifically want them (and accept the collision risk).
- Auto-port settings are written to `.docker/auto.env` and reused by `make
  urls` / `down` / `reset`.

---

## macOS gotchas

- **AirPlay Receiver** binds ports **5000** and **7000**. If a service won't
  bind there, turn it off in *System Settings → General → AirDrop & Handoff*, or
  just use `make up` (it avoids those ranges).
- **`.localhost` HTTPS:** `http://parapet.localhost` works immediately. Caddy can
  also serve local HTTPS via its internal CA; the browser warns until you trust
  it (`caddy trust`) — optional for local dev.
- **Bind-mount speed:** use VirtioFS (above); named volumes already cover the
  hot paths (`deps/`, `_build/`).

---

## Cleanup

```bash
make down                              # this project
docker compose down --remove-orphans -v  # belt-and-suspenders, in a project dir
docker system prune -f                 # reclaim space from stopped junk (careful)
```

Compose scopes containers, networks, and volumes by project name, so removing
one project never touches another.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `make up-proxy` says network not found | One-time: `docker network create dev-proxy-net` then start the proxy (see `dev-proxy/README.md`). |
| Page looks unstyled | `cd examples/demo_app && mix assets.build` (or just `make up` — assets build on boot). |
| Port still collides | You're probably on `make up-fixed`; switch to `make up`. Or another process grabbed it — `make up` retries once; rerun if needed. |
| Gallery won't start | Set a port explicitly: `PORT=4781 make gallery`. |
| Grafana links 404 | Grafana is opt-in — use `make up-monitoring` (or a scenario target). |

---

## Run without Docker

If you have local PostgreSQL on `5432` (`postgres`/`postgres`):

```bash
cd examples/demo_app
mix setup
mix phx.server          # http://localhost:4000/parapet
```

For components only, prefer `make gallery` — it needs no database at all.

---

## Production note

Parapet ships no auth. The demo's `/parapet` route is intentionally open so the
smoke test can verify the UI loads. **Production must wrap these routes in an
authenticated scope** (e.g. `pipe_through [:browser,
:require_authenticated_user]`). See the
[Operator UI guide](operator-ui.md) and the
[`mix parapet.gen.ui`](https://hexdocs.pm/parapet) generator output.
