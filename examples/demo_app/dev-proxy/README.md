# `dev-proxy` — one local proxy for all your demo stacks

Run several OSS demo apps at once and reach each at a stable hostname
(`parapet.localhost`, `rindle.localhost`, …) with **no host port to remember or
collide on**. One small Caddy container watches Docker and routes by label.

> This directory is a **reusable reference**, not parapet-specific. It is meant
> to live once on your machine — copy it to `~/dev-proxy/` (or anywhere outside a
> single repo) and share it across every project.

## TL;DR

```bash
# one-time, from this directory
docker network create dev-proxy-net
docker compose up -d

# then in any project that has a proxy overlay (parapet ships one):
cd /path/to/parapet/examples/demo_app
make up-proxy
open http://parapet.localhost
```

That's it. `.localhost` resolves to `127.0.0.1` automatically in Chrome/Edge and
modern Firefox — no `/etc/hosts`, no dnsmasq.

## How it works

- `compose.yaml` runs [`caddy-docker-proxy`](https://github.com/lucaslorentz/caddy-docker-proxy),
  which reads container **labels** and builds Caddy routes on the fly.
- Any container that (1) joins the external `dev-proxy-net` network and (2) has a
  `caddy: <host>.localhost` label is published at that hostname automatically.
- Add or remove a project and the route appears/disappears — nothing to edit here.

## Adding a new project (the label contract)

In the project's compose (see parapet's `docker-compose.proxy.yml` for a worked
example), attach the web service to `dev-proxy-net` and label it:

```yaml
services:
  web:
    networks: [default, dev-proxy-net]
    labels:
      caddy: myproject.localhost
      caddy.reverse_proxy: "{{upstreams 4000}}"   # 4000 = the container's port
networks:
  dev-proxy-net:
    external: true
```

## Notes & footguns

- **HTTP on :80** is the simplest path — open `http://parapet.localhost`. Caddy
  can also serve local HTTPS via its internal CA; the browser will warn until you
  trust the CA (`caddy trust`), which is optional for local dev.
- **Docker socket** is mounted read-only so Caddy can watch labels. This is a
  fine local-dev convenience; don't replicate it on a shared/remote host.
- **One hostname per identity.** Two copies of the *same* project both claiming
  `parapet.localhost` is ambiguous — give the second a different label
  (`parapet2.localhost`). Different projects never collide.
- The proxy is **independent** of your projects: stopping a project leaves the
  proxy up; `docker compose down` here stops only the proxy.
- When the proxy is **not** running, projects still work via their normal
  auto-port host bindings (`make up`) — the proxy is purely additive.
