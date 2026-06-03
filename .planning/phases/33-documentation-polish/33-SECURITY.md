---
phase: 33
slug: documentation-polish
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-03
verified: 2026-06-03
---

# Phase 33 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| docs -> adopter deployment changes | Readers may treat guide steps as production-safe operational truth. | Operational guidance for metrics, auth, deploy markers, migrations, and operator routes. |
| mix.exs docs config -> HexDocs output | Misconfigured extras or assets can silently hide guides or break branding in published docs. | Documentation navigation and docs-local assets published through ExDoc. |
| maintainer docs -> release operations | Incorrect procedure text can cause unsafe or inconsistent release handling. | Release train procedures, Release Please guidance, and branch-protection references. |
| demo docs -> local Docker execution | Readers may treat the demo Compose path or open `/parapet` route as production guidance. | Local container startup instructions and demo-only route exposure guidance. |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-33-01 | Information Disclosure | `docs/deployment.md` | mitigate | `docs/deployment.md` states that route authentication, admin scope, firewall rules, and network policy for `/metrics` remain host-owned; it also requires authenticated operator routes and calls the open demo route non-production guidance. | closed |
| T-33-02 | Tampering | `mix.exs` docs() wiring | mitigate | `mix.exs` includes exact ExDoc `extras` entries for `docs/migration-v1.md` and `docs/deployment.md`, places both under the `Guides` group, and sets `logo`/`favicon` to docs-local SVG assets; Phase 33 summary records `MIX_ENV=dev mix docs --warnings-as-errors` passing. | closed |
| T-33-SC | Tampering | package/dependency surface | mitigate | Phase 33 summaries record no dependencies added, no `mix.lock` changes, no package whitelist change, and branding assets kept under `docs/assets/` so the existing docs package whitelist covers them. | closed |
| T-33-03 | Tampering | `MAINTAINING.md` vs `docs/release-policy.md` authority split | mitigate | `MAINTAINING.md` is checklist-oriented and links to `docs/release-policy.md` for adopter-facing release behavior and `docs/branch-protection.md` for repository settings; release-policy changes are explicitly kept out of the checklist unless procedure changes. | closed |
| T-33-04 | Elevation of Privilege | `examples/demo_app/README.md` demo routing guidance | mitigate | `examples/demo_app/README.md` preserves the demo-only warning, states `/parapet` is intentionally unauthenticated only for local smoke tests, and requires production deployments to wrap routes in an authenticated host-app scope. | closed |
| T-33-05 | Denial of Service | `examples/demo_app/Makefile` compose command compatibility | mitigate | `examples/demo_app/Makefile` prefers `docker compose` while falling back to `docker-compose`; Phase 33 summary records `docker compose config` passing against the existing `db` + `web` Compose shape. | closed |

Status: open or closed.
Disposition: mitigate (implementation required), accept (documented risk), or transfer (third-party).

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-03 | 6 | 6 | 0 | Codex |

## Evidence

- `docs/deployment.md`: host-owned authentication, `/metrics` network policy, authenticated operator route, and non-production demo warning verified.
- `mix.exs`: ExDoc guide extras, guide grouping, logo, and favicon wiring verified.
- `.planning/phases/33-documentation-polish/33-01-SUMMARY.md`: docs generation and docs-local branding verification recorded.
- `MAINTAINING.md`: release procedure is separated from policy/settings authority and references canonical docs.
- `CONTRIBUTING.md`: Release Please-aware commit taxonomy is documented for contributor behavior.
- `examples/demo_app/README.md`: demo Compose smoke path, port overrides, teardown, and production auth warning verified.
- `.planning/phases/33-documentation-polish/33-02-SUMMARY.md`: demo Compose config validation and Makefile compatibility fix recorded.

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

Approval: verified 2026-06-03
