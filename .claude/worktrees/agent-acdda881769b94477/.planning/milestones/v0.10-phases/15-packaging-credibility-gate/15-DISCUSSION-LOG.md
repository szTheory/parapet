# Phase 15: Packaging Credibility Gate - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-23
**Phase:** 15-packaging-credibility-gate
**Mode:** assumptions
**Areas analyzed:** hex.pm metadata, CHANGELOG ownership & retroactive history, version strategy, publish scope

## Assumptions Presented

### hex.pm Metadata (ADOPT-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `@source_url`, top-level `:description` + `source_url:`, a `docs:` block (`source_ref`/`extras`), and `links:` with GitHub/HexDocs/Issues + Changelog | Confident | `mix.exs:11-15` (`links: %{}`, no description/source_url); README badges + git remote fix URLs; `deps/ecto/mix.exs`, `deps/req/mix.exs` idiom |

### CHANGELOG Ownership & Retroactive History (ADOPT-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Release Please owns the CHANGELOG body; commit a header-only stub to main | Confident | `origin/release-please--branches--main:CHANGELOG.md` is fully generated; success criterion 3 |
| Retroactive v0.1–v0.9 history lives in shipped `docs/HISTORY.md` (milestone-framed), linked from the stub | Confident | success criteria 2-3; `docs/` already in `files:` (`mix.exs:12`); `.planning/MILESTONES.md` is the source |
| Add `CHANGELOG*` to the `files:` whitelist | Confident | success criterion 4; absent at `mix.exs:12` |

### Version Strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Release Please targets an accidental `1.0.0`, contradicting the deferred v1.0 freeze | Unclear (decision surfaced to user) | `origin/release-please--branches--main:mix.exs` → `version: "1.0.0"`; commit `8268889` `BREAKING CHANGE:` footer; `MILESTONE-ARC.md` reserves v1.0 for the API freeze |

### Publish Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 15 prepares repo state only; no `mix hex.publish` this phase | Confident | no publish automation in `.github/`; no semver release tags exist |

## Corrections Made

No corrections — the user confirmed all non-version assumptions ("Yes, lock these").

## Decisions Resolved by User

### Version Strategy
- **Question:** With Release Please targeting `1.0.0` (accidental `BREAKING CHANGE` footer) but the
  milestone arc reserving v1.0 for the deferred API freeze, how should Phase 15 set the version
  strategy?
- **User chose:** **Pin pre-1.0 → 0.10.0** — add `release-please-config.json`
  (`bump-minor-pre-major`) + seed `.release-please-manifest.json` so the first release publishes
  as `0.10.0`, reserving v1.0 for the API freeze.
- **Rationale:** Aligns the first hex version with the milestone numbering and honors
  `MILESTONE-ARC.md`; neutralizes the stray breaking-change footer without rewriting history.

## External Research

None performed — codebase + git refs + reference deps provided sufficient evidence. (The analyzer
flagged release-please-action@v4 manifest-bootstrap behavior and ex_doc `extras:` requirements as
worth confirming during plan-phase; captured as planning notes in CONTEXT.md D-05/D-09.)
