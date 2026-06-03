# Phase 33: Documentation & Polish - Research

**Researched:** 2026-06-03
**Status:** Ready for planning

## Research Question

What do we need to know to plan Phase 33 well?

Phase 33 should complete the remaining v1.2 maturity artifacts without changing runtime behavior: v0.x -> v1.0 migration guidance, deployment guidance, maintainer release procedure docs, conventional commit contribution guidance, HexDocs branding assets, and demo app Docker Compose validation.

## Source Evidence

- `.planning/phases/33-documentation-polish/33-CONTEXT.md` defines this as an additive docs/polish phase.
- `.planning/REQUIREMENTS.md` maps the phase to DX-03, DX-04, MAT-05, MAT-06, MAT-07, and MAT-08.
- `mix.exs` owns Hex package files, ExDoc extras, and ExDoc grouping.
- `mix.lock` resolves `ex_doc` to `0.40.2`.
- `deps/ex_doc/lib/ex_doc.ex` documents first-class `:logo` and `:favicon` options.
- `examples/demo_app/docker-compose.yml`, `Dockerfile.dev`, `entrypoint.sh`, and `Makefile` already provide the demo Compose surface.
- `.github/workflows/ci.yml` runs docs with warnings as errors and runs demo smoke tests against Postgres.

## Implementation Findings

### Documentation Structure

The docs system is centralized in `mix.exs`:

- `docs()` has an `extras` list for all published extra pages.
- `groups_for_extras` currently groups adopter docs under `Guides`, integration docs under `Integration Guides`, and API-contract docs under `Reference`.
- The Hex package whitelist already includes `docs`, so new files under `docs/` are included without widening package files.

Planning implication: new adopter-facing docs should be added under `docs/` and registered in both `docs.extras` and the `Guides` group. The planner should prefer `docs/migration-v1.md` or `docs/v1-migration.md` for DX-03 and `docs/deployment.md` for DX-04, with final naming chosen from existing guide conventions.

### Migration Guide Scope

The migration guide should be practical upgrade guidance, not release history. Existing source docs to anchor it:

- `docs/HISTORY.md` for older release history.
- `docs/stability.md` for stability tiers, public API tiers, deprecation rules, and telemetry contract.
- `docs/getting-started.md` for current install and validation commands.
- `docs/recovery-actions.md` for recovery/operator surfaces introduced before the v1.0 line.

Planning implication: the guide should cover v0.x -> v1.0 adoption checks, stability tier meaning, `Parapet.SLO.define/2` deprecation and provider migration, telemetry contract stability, install/config validation, and `mix parapet.doctor --ci`.

### Deployment Guide Scope

Deployment guidance should stay host-owned and Phoenix-focused. The phase context specifically calls out:

- metrics endpoint exposure,
- Prometheus rule loading,
- deploy markers,
- database migrations for durable evidence,
- Oban/optional dependency compile-out notes,
- `mix parapet.doctor --ci`.

Planning implication: no new deployment runtime should be introduced. The guide should explain what Parapet expects a host app to expose or run, and how to validate those surfaces before release.

### Maintainer and Contribution Docs

`docs/release-policy.md` is adopter-facing release policy. Root `MAINTAINING.md` should be maintainer-only procedure truth and should not duplicate the docs guide.

`CONTRIBUTING.md` already has a basic Conventional Commits section with these prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, and `chore:`. `.github/PULL_REQUEST_TEMPLATE.md` distinguishes stable-line maintenance from feature work.

Planning implication:

- Add root `MAINTAINING.md` with concrete release/operator checklist steps around Release Please, `release_gate`, staged cuts, blocked release trains, Hex publish verification, and branch protection references.
- Update `CONTRIBUTING.md` in place with Release Please-oriented taxonomy and stable-line work examples.
- Avoid adding a second contribution document.

### HexDocs Branding

ExDoc 0.40.2 supports `:logo` and `:favicon` directly in `docs()`:

- `:logo` takes a PNG, JPEG, or SVG path and copies it to generated docs as `assets/logo.<ext>`.
- `:favicon` takes a PNG, JPEG, or SVG path and copies it to generated docs as `assets/favicon.<ext>`.
- SVG files should include `width`, `height`, and `viewBox` attributes for predictable sizing.

The Hex package whitelist currently includes `docs` but not a root `assets` directory. There is no root assets directory today.

Planning implication: place static branding assets under `docs/assets/` or another path already included by the Hex package whitelist. Then add `logo: "docs/assets/parapet-logo.svg"` and `favicon: "docs/assets/favicon.svg"` or equivalent to `docs()` in `mix.exs`. Keep assets hand-authored/static and avoid runtime dependencies or `mix.lock` churn.

### Demo Docker Compose

The demo app already has:

- `examples/demo_app/docker-compose.yml` with `db` and `web` services.
- `examples/demo_app/Dockerfile.dev`, which uses `entrypoint.sh`.
- `examples/demo_app/entrypoint.sh`, which fetches parent deps, fetches demo deps, runs `mix setup`, and starts Phoenix.
- `examples/demo_app/Makefile` with `up`, `down`, and `rebuild` targets.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` validating `/parapet` and seeded-incident behavior in test mode.

Risks to verify during execution:

- Compose uses `docker-compose` in the Makefile, while newer Docker installs may prefer `docker compose`.
- The Compose port defaults to host `5432` and `4000`, so docs should mention `DB_PORT` and `WEB_PORT` overrides from Compose.
- `docker-compose.yml` uses version `3.8`; that is acceptable but may be noisy on newer Docker Compose.
- The demo Compose smoke check should be explicit and reproducible, for example `cd examples/demo_app && docker compose up --build` followed by `curl -f http://localhost:${WEB_PORT:-4000}/parapet`.

Planning implication: validate and repair the existing demo Compose path rather than creating a root-level competing Compose file unless the existing demo setup cannot satisfy MAT-08.

## Validation Architecture

Phase 33 validation should prove docs are published, docs compile cleanly, contribution/release procedure truth is present, branding assets are wired into ExDoc, and demo Compose has a reproducible smoke path.

Required validation commands and checks:

- `mix format --check-formatted`
- `MIX_ENV=dev mix docs --warnings-as-errors`
- `mix compile --warnings-as-errors`
- Source assertions:
  - `mix.exs` `docs.extras` contains the new migration and deployment docs.
  - `mix.exs` `groups_for_extras` places the new guides in `Guides`.
  - `mix.exs` `docs()` contains `:logo` and `:favicon`.
  - Logo/favicon paths exist under a package-included path.
  - `MAINTAINING.md` exists at repo root.
  - `CONTRIBUTING.md` documents Release Please-compatible conventional commit taxonomy.
  - `examples/demo_app/README.md` documents the Compose command path and smoke check.
- Demo smoke validation when Docker is available:
  - `cd examples/demo_app && docker compose config`
  - `cd examples/demo_app && docker compose up --build`
  - `curl -f http://localhost:${WEB_PORT:-4000}/parapet`
  - `cd examples/demo_app && docker compose down -v`

If Docker is unavailable in the execution environment, the plan should still require source-level validation of Compose syntax and document Docker smoke verification as a manual or CI-capable acceptance step.

## Planning Constraints

- Keep edits additive and documentation-focused.
- Do not add dependencies.
- Do not change runtime behavior unless demo Compose validation proves a concrete bug.
- Do not create overlapping authority between `docs/release-policy.md`, root `MAINTAINING.md`, and `CONTRIBUTING.md`.
- Do not widen the Hex package whitelist unless selected asset placement cannot use an already-included path.
- Every requirement ID must appear in plan frontmatter: DX-03, DX-04, MAT-05, MAT-06, MAT-07, MAT-08.

## Suggested Plan Shape

One or two executable plans should be enough:

1. Docs and release procedure plan: migration guide, deployment guide, `MAINTAINING.md`, `CONTRIBUTING.md`, `mix.exs` docs wiring.
2. Branding and demo Compose polish plan: static docs assets, ExDoc logo/favicon config, demo Compose README/Makefile validation and any minimal Compose fixes.

The planner may keep this as one plan if dependencies are simple, but splitting docs/procedure from demo/branding would keep verification tighter.

## RESEARCH COMPLETE
