# Phase 33: Documentation & Polish - Context

**Gathered:** 2026-06-03 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 33 completes the remaining v1.2 maturity artifacts: v0.x -> v1.0 migration guidance, deployment guidance, maintainer/release procedure docs, conventional-commit contribution guidance, HexDocs branding assets, and demo Docker Compose validation. This is a docs/polish phase, not a runtime feature phase.
</domain>

<decisions>
## Implementation Decisions

### Documentation Structure
- **D-01:** Add new adopter-facing guides under `docs/` and wire them into `mix.exs` `docs.extras` and `groups_for_extras` so HexDocs publishes them with the existing guide set.
- **D-02:** Keep the current guide style: direct Phoenix adopter steps, explicit prerequisites, honest caveats, and concrete `mix` commands. Use `docs/getting-started.md`, `docs/recovery-actions.md`, and `docs/release-policy.md` as tone/style anchors.

### Migration and Deployment Guides
- **D-03:** The migration guide should be a practical v0.x -> v1.0 adopter guide, not a full historical changelog. It should point to `docs/HISTORY.md` for older release history and focus on stability tiers, public API/telemetry contract, install/config changes, and safe upgrade checks.
- **D-04:** The deployment guide should focus on host-owned Phoenix deployment surfaces Parapet actually touches: metrics endpoint exposure, Prometheus rule loading, deploy markers, database migrations for durable evidence, Oban/optional dependency compile-out notes, and `mix parapet.doctor --ci`.

### Maintenance and Contribution Docs
- **D-05:** Add `MAINTAINING.md` at the repo root for maintainer-only release procedure truth. It should complement, not duplicate, `docs/release-policy.md`; use the root file for checklist/operator actions and the docs guide for adopter-facing release policy.
- **D-06:** Update the existing `CONTRIBUTING.md` rather than creating a second contribution doc. Add the conventional-commit taxonomy needed by Release Please and align it with the stable-line work classes already present in `.github/PULL_REQUEST_TEMPLATE.md`.

### Demo Docker Compose
- **D-07:** Treat `examples/demo_app/docker-compose.yml` and existing `Dockerfile` files as the baseline. Planning should verify and repair them if needed, not create a competing root-level Compose setup unless the existing demo app setup cannot satisfy MAT-08.
- **D-08:** Demo Compose acceptance should include a reproducible command path and an explicit health/smoke check, ideally matching the existing demo app setup/reset conventions.

### HexDocs Branding
- **D-09:** Add logo/favicon assets only if they can be included without adding runtime dependencies or weakening the Hex package whitelist. Planning should research the exact ExDoc `logo`/`favicon` options for the installed ExDoc line before editing `mix.exs`.

### the agent's Discretion
- Keep the phase low-risk and additive: docs/assets/config only unless validation proves a demo Compose bug.
- Prefer updating existing docs over adding parallel docs with overlapping authority.
- No dependency upgrades or `mix.lock` churn unless an existing validation command cannot run without it.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `mix.exs`
- `README.md`
- `CONTRIBUTING.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `docs/getting-started.md`
- `docs/release-policy.md`
- `docs/HISTORY.md`
- `docs/stability.md`
- `docs/recovery-actions.md`
- `examples/demo_app/README.md`
- `examples/demo_app/docker-compose.yml`
- `examples/demo_app/Dockerfile`
- `examples/demo_app/Dockerfile.dev`
- `examples/demo_app/Makefile`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Root `mix.exs` owns HexDocs extras and grouping, and the package whitelist already includes `docs`.
- `docs/release-policy.md` already documents release train behavior, `release_gate`, Release Please, and manual intervention cases.
- Root `CONTRIBUTING.md` already exists and should be extended for conventional commits.
- `examples/demo_app/docker-compose.yml`, `Dockerfile`, `Dockerfile.dev`, and `Makefile` already exist and are the natural MAT-08 implementation surface.

### Established Patterns
- Documentation guides use practical, step-numbered Phoenix adopter workflows with commands and explicit caveats.
- Stable-line maintenance should stay additive and avoid dependency/support-surface expansion.
- Release truth centers on `release_gate`, Release Please, and Hex publish verification.

### Integration Points
- `mix.exs` `docs()` must include any new docs and branding configuration.
- `mix.exs` `package.files` must include any new root-level maintenance docs or branding assets intended for Hex publishing.
- Demo Compose validation should align with CI/demo smoke-test expectations from `.github/workflows/ci.yml`.
</code_context>

<specifics>
## Specific Ideas

- Use `docs/migration-v1.md` or `docs/v1-migration.md` for the migration guide; pick the name that best matches existing guide naming during planning.
- Use `docs/deployment.md` for deployment guidance unless planning finds a stronger existing naming convention.
- Keep branch protection details in `docs/branch-protection.md` from Phase 32 and link to it rather than duplicating commands in `MAINTAINING.md`.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.
</deferred>
