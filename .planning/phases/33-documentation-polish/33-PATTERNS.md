# Phase 33: Documentation & Polish - Pattern Map

**Mapped:** 2026-06-03
**Status:** Ready for planning

## Scope

Phase 33 modifies documentation, docs configuration, static HexDocs branding assets, and demo app Compose documentation/validation. No runtime feature code is expected unless Compose validation proves an existing demo bug.

## File Pattern Map

| Planned File | Role | Closest Existing Analog | Pattern to Reuse |
|--------------|------|-------------------------|------------------|
| `docs/migration-v1.md` or `docs/v1-migration.md` | Adopter guide | `docs/getting-started.md`, `docs/stability.md`, `docs/HISTORY.md` | Direct Phoenix adopter steps, practical commands, explicit caveats, links to deeper references |
| `docs/deployment.md` | Adopter deployment guide | `docs/getting-started.md`, `docs/troubleshooting.md`, `docs/operator-ui.md` | Host-owned setup language, concrete `mix` commands, security caveats for exposed routes/endpoints |
| `MAINTAINING.md` | Maintainer procedure | `docs/release-policy.md`, `docs/branch-protection.md` | Release truth around `release_gate`, Release Please, branch protection, manual intervention only when necessary |
| `CONTRIBUTING.md` | Contributor guide | Existing `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md` | Preserve current PR flow and stable-line taxonomy; expand commit taxonomy in place |
| `docs/assets/parapet-logo.svg` | HexDocs branding asset | No existing root docs asset; use ExDoc asset requirements | Static SVG with `width`, `height`, and `viewBox`; no dependency or build step |
| `docs/assets/favicon.svg` | HexDocs branding asset | No existing root docs asset; use ExDoc asset requirements | Static SVG with `width`, `height`, and `viewBox`; path included by existing Hex `docs` package whitelist |
| `mix.exs` | Docs/package configuration | Existing `docs()` and `package()` functions | Add extras and guide grouping; add `logo:` and `favicon:` in `docs()`; avoid package whitelist widening if assets stay under `docs/` |
| `examples/demo_app/README.md` | Demo run guide | Existing quick start and warning sections | Add Docker Compose path and smoke check without replacing local `mix setup` flow |
| `examples/demo_app/docker-compose.yml` | Demo compose baseline | Existing compose file | Repair only if validation proves a bug; keep two-service `db` + `web` shape |
| `examples/demo_app/Makefile` | Convenience commands | Existing `up`, `down`, `rebuild` targets | Prefer modern `docker compose` compatibility if touched; avoid requiring Make for core docs |

## Existing Code Excerpts

### `mix.exs` Docs Configuration

`mix.exs` currently centralizes published docs:

- `docs()` sets `main: "getting-started"`.
- `extras` includes README, CHANGELOG, history, stability, adopter guides, release policy, and integrations.
- `groups_for_extras` contains `Getting Started`, `Guides`, `Integration Guides`, and `Reference`.

Planner instructions should require any new published guide to be added to both `extras` and the relevant group.

### Hex Package Whitelist

`package.files` currently includes `docs`, so docs-local assets are package-safe:

- New files under `docs/` are already included.
- A root `assets/` directory would require package whitelist expansion and should be avoided unless necessary.

### Existing Guide Style

`docs/getting-started.md` uses:

- short prerequisites,
- numbered setup steps,
- fenced command blocks,
- explicit notes about what Parapet does and does not activate,
- next-step links.

`docs/release-policy.md` uses:

- concise operating model,
- stable-line work class definitions,
- explicit release truth and manual intervention sections.

Planning should preserve this concise, operational style.

### Demo Compose Flow

`examples/demo_app/docker-compose.yml` already defines:

- `db` service using Postgres 14 Alpine,
- `web` service built from project root with `examples/demo_app/Dockerfile.dev`,
- `WEB_PORT` and `DB_PORT` host port overrides,
- health-gated `depends_on`,
- named volumes for parent and demo deps/build artifacts.

`entrypoint.sh` runs parent deps, demo deps, `mix setup`, then `mix phx.server`.

Planner instructions should validate this existing flow before proposing any Compose changes.

## Data Flow

1. Contributor edits docs/assets/config.
2. `mix docs --warnings-as-errors` loads `mix.exs` `docs()` and renders all extras.
3. ExDoc copies configured `logo` and `favicon` into generated docs `assets/`.
4. Hex package includes docs files because `package.files` includes `docs`.
5. Demo Compose starts Postgres and Phoenix demo app; `/parapet` is the smoke endpoint.

## Landmines

- Do not create a second contribution doc; update `CONTRIBUTING.md`.
- Do not duplicate adopter release policy in `MAINTAINING.md`; maintainer docs should link to `docs/release-policy.md` and `docs/branch-protection.md`.
- Do not place branding assets in an unpackaged root path unless `package.files` is deliberately updated.
- Do not add dependencies, asset pipelines, or generated binary artifacts for branding.
- Do not create a root-level Compose setup unless the existing demo app Compose cannot satisfy MAT-08.
- Do not run `docker compose up` as a mandatory automated verification if Docker is unavailable; plan an explicit fallback and manual proof.

## PATTERN MAPPING COMPLETE
