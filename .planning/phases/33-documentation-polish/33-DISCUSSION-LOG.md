# Phase 33: Documentation & Polish - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-03T17:33:00Z
**Phase:** 33-documentation-polish
**Mode:** assumptions
**Areas analyzed:** Documentation Structure, Migration and Deployment Guides, Maintenance and Contribution Docs, Demo Docker Compose, HexDocs Branding

## Assumptions Presented

### Documentation Structure
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add new adopter-facing guides under `docs/` and wire them into `mix.exs` docs extras/groups. | Confident | `mix.exs`, `docs/getting-started.md`, `docs/recovery-actions.md` |
| Keep guide style practical, command-oriented, and caveat-explicit. | Confident | `docs/getting-started.md`, `docs/release-policy.md`, `docs/troubleshooting.md` |

### Migration and Deployment Guides
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Migration guide should focus on v0.x -> v1.0 adopter steps and link to `docs/HISTORY.md` for older history. | Likely | `docs/HISTORY.md`, `docs/stability.md`, `.planning/REQUIREMENTS.md` |
| Deployment guide should cover metrics exposure, Prometheus rules, deploy markers, migrations, optional deps, and doctor CI. | Likely | `docs/getting-started.md`, `lib/parapet/deploy.ex`, `mix.exs` |

### Maintenance and Contribution Docs
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add root `MAINTAINING.md` for maintainer-only procedure truth and avoid duplicating adopter-facing release policy. | Confident | `docs/release-policy.md`, `.github/workflows/release-please.yml`, `.github/workflows/ci.yml` |
| Update existing `CONTRIBUTING.md` with conventional commits rather than creating a parallel doc. | Confident | `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `release-please-config.json` |

### Demo Docker Compose
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Validate and repair existing demo Compose files rather than creating a competing root setup. | Confident | `examples/demo_app/docker-compose.yml`, `examples/demo_app/Dockerfile`, `examples/demo_app/Dockerfile.dev`, `examples/demo_app/Makefile` |

### HexDocs Branding
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Research exact ExDoc branding options before editing `mix.exs`. | Likely | `mix.exs` uses ExDoc `~> 0.31`; logo/favicon config details should be checked against ExDoc docs during planning/research. |

## Corrections Made

No corrections — auto mode accepted all Confident/Likely assumptions.

## Auto-Resolved

- HexDocs Branding: auto-selected the conservative default to research ExDoc asset options before implementation.
