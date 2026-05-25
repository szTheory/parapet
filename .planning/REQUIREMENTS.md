# Requirements: Parapet — v1.0 Stable Release

**Defined:** 2026-05-25
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Milestone posture:** Credibility/commitment milestone — freeze the public surface and make `~> 1.0` trustworthy. No new runtime feature surface. Research backing: `.planning/research/V1-*.md`.

## v1.0 Requirements

Requirements for the 1.0 stable release. Each maps to exactly one roadmap phase (19–22).

### Stability Freeze (STAB)

- [x] **STAB-01**: Every public module (not `@moduledoc false`, not under `Parapet.Internal.*`) declares a stability tier — Stable or Experimental — via an ExDoc callout in its moduledoc, and every Stable public function carries `@doc since: "1.0.0"`.
- [x] **STAB-02**: A written stability & deprecation policy (`docs/stability.md`) enumerates the public API surface, states the semver promise, defines what counts as a breaking vs. additive change, and specifies the deprecation cycle (soft `@doc deprecated:` → hard `@deprecated` for ≥1 minor → removal only at a major).
- [x] **STAB-03**: The telemetry contract is documented as frozen — static `[:parapet, …]` event names, additive-only evolution of measurements/metadata, and an explicit "no configurable `:event_prefix`" rule — with a stability header on `docs/telemetry.md`.
- [x] **STAB-04**: `mix verify.public_api` fails (non-zero exit) when any public module is missing a stability-tier declaration, making tier annotation mandatory for every future public surface.
- [x] **STAB-05**: A telemetry contract test fails CI when the documented event families, measurement keys, metadata keys, or outcome-atom vocabularies drift from their fixtures.
- [x] **STAB-06**: `Parapet.SLO.define/2` is hard-deprecated with a compile-time warning that names `Parapet.SLO.Provider` as the replacement.

### OSS Governance (GOV)

- [ ] **GOV-01**: The repository ships a `CONTRIBUTING.md` covering local proof commands (`mix test`, `mix credo`, `mix dialyzer`), Conventional Commits + formatter expectations, and the PR flow.
- [ ] **GOV-02**: The repository ships a `SECURITY.md` documenting the vulnerability-disclosure process.
- [ ] **GOV-03**: The repository ships a `CODE_OF_CONDUCT.md` (Contributor Covenant or equivalent).
- [x] **GOV-04**: The README states the 1.0 semver commitment and a supported Elixir / OTP / Postgres version matrix.
- [x] **GOV-05**: The new governance docs are included in the Hex `files:` whitelist so they ship with the published package.

### Documentation Completeness (DOCS)

- [x] **DOCS-01**: An adopter can activate Chimeway monitoring from a dedicated integration guide (prerequisites, what it unlocks, uniform activation line, config keys, troubleshooting).
- [x] **DOCS-02**: An adopter can activate Mailglass monitoring from a dedicated integration guide (same shape).
- [x] **DOCS-03**: An adopter can activate Rindle monitoring from a dedicated integration guide (same shape).
- [x] **DOCS-04**: An adopter can activate Scoria monitoring from a dedicated integration guide (same shape).
- [ ] **DOCS-05**: The SLO authoring guide documents the Provider-as-bundle pattern (a `Parapet.SLO.Provider` returning multiple slices) so adopters compose multi-integration SLO sets without looking for a separate bundle abstraction.
- [x] **DOCS-06**: HexDocs are organized for adopters — grouped extras (Getting Started / Guides / Integration Guides / Reference) with the getting-started guide as the landing page.

### Runnable Demo App (DEMO)

- [ ] **DEMO-01**: A runnable demo Phoenix app under `examples/demo_app/` (path dep on parapet) starts with `mix setup && mix phx.server` and serves the Operator UI at `/parapet`.
- [ ] **DEMO-02**: The demo is seeded with realistic evidence — incidents in open/investigating/resolved states, timeline entries, a tool audit, a runbook with a `warning:` step, and registered WebSaaS SLO state — so the Operator UI is populated on first run.
- [ ] **DEMO-03**: A demo smoke test asserts the Operator UI responds `200` and at least one seeded incident exists, and runs as a required CI gate (in `release_gate`, never `continue-on-error`).
- [ ] **DEMO-04**: The demo app is excluded from the published Hex package (verified via `mix hex.build` dry run) and is linked from the getting-started guide.

### Release Readiness & 1.0 Cut (REL)

- [ ] **REL-01**: CI enforces `compile --warnings-as-errors`, `compile --no-optional-deps --warnings-as-errors`, and `docs --warnings-as-errors` in the lint lane.
- [ ] **REL-02**: `release-please.yml` publishes to Hex.pm on a created release (`hex.publish --dry-run` → `hex.publish --yes` → post-publish verification).
- [ ] **REL-03**: A documented, proportionate pre-release verification gate (`verify.public_api`, `test`, `credo --strict`, `dialyzer`, no-optional-deps compile, one manual cold-start walkthrough) passes before the 1.0 cut — no security or performance audit.
- [ ] **REL-04**: Parapet is released as `1.0.0` via Release-Please (0.10.0 merged → `release-as` pin removed → `1.0.0` pinned and cut → pin plus the pre-1.0 `bump-*-pre-major` flags removed) and resolves at `hexdocs.pm/parapet/1.0.0/`.

## Future Requirements

Acknowledged but deferred beyond v1.0. Not in the current roadmap.

### SLO Authoring (SLO)

- **SLO-W1** (v1.1): `mix parapet.gen.slo` as a *flag-based Igniter task* (not an interactive wizard) that renders a host-owned `Parapet.SLO.Provider` module from flags, shows a diff, is dry-runnable/composable, and chains `parapet.gen.prometheus`.

### CI & Polish

- **CI-M1** (v1.1): multi-version Elixir/OTP CI test matrix.
- **CI-S1** (post-1.0): SHA-pin CI actions for supply-chain hardening.
- **DX-1** (post-1.0): HexDocs logo/favicon.
- **MAINT-1** (post-1.0): `MAINTAINING.md` maintainer runbook.
- **DEMO-X** (post-1.0): demo Docker Compose convenience + golden-installer diff test against `mix parapet.install` output.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| SLO-B1 formal `Parapet.SLO.Bundle` abstraction | Superseded — a `Parapet.SLO.Provider` returning multiple slices already is the bundle (`DeliverySaaS` proves it). A macro saving ~5 lines would freeze a premature abstraction whose right shape depends on future Grafana grouping. Documented as a pattern instead (DOCS-05). |
| Interactive (prompt-driven) generator wizard | Non-idiomatic — Igniter has no interactive-prompt API; a prompt-driven `Mix.Task` loses dry-run/composability and breaks DX consistency with `mix parapet.install`. The flag-based form is the v1.1 plan (SLO-W1). |
| Full security / performance re-audit | Maintainer chose freeze depth = stability tiers + deprecation policy, not a full hardening pass. A proportionate verify gate (REL-03) is used instead. |
| New runtime features / new integrations | v1.0 is a freeze and credibility milestone, not a feature vehicle (the Oban-1.0 model). |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| STAB-01 | Phase 19 | Complete |
| STAB-02 | Phase 19 | Complete |
| STAB-03 | Phase 19 | Complete |
| STAB-04 | Phase 19 | Complete |
| STAB-05 | Phase 19 | Complete |
| STAB-06 | Phase 19 | Complete |
| GOV-01 | Phase 20 | Pending |
| GOV-02 | Phase 20 | Pending |
| GOV-03 | Phase 20 | Pending |
| GOV-04 | Phase 20 | Complete |
| GOV-05 | Phase 20 | Complete |
| DOCS-01 | Phase 20 | Complete |
| DOCS-02 | Phase 20 | Complete |
| DOCS-03 | Phase 20 | Complete |
| DOCS-04 | Phase 20 | Complete |
| DOCS-05 | Phase 20 | Pending |
| DOCS-06 | Phase 20 | Complete |
| DEMO-01 | Phase 21 | Pending |
| DEMO-02 | Phase 21 | Pending |
| DEMO-03 | Phase 21 | Pending |
| DEMO-04 | Phase 21 | Pending |
| REL-01 | Phase 22 | Pending |
| REL-02 | Phase 22 | Pending |
| REL-03 | Phase 22 | Pending |
| REL-04 | Phase 22 | Pending |

**Coverage:**

- v1.0 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 — traceability confirmed by ROADMAP.md (Phases 19-22)*
