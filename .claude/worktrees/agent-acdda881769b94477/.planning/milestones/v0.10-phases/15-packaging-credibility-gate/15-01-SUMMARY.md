---
phase: 15-packaging-credibility-gate
plan: "01"
subsystem: packaging
tags: [release-please, changelog, hex, documentation, versioning]
dependency_graph:
  requires: []
  provides:
    - CHANGELOG.md header-only stub (Release Please owns the body)
    - docs/HISTORY.md retroactive milestone history v0.1-v0.9
    - release-please-config.json version strategy (elixir, pre-1.0 bump flags, release-as pin)
    - .release-please-manifest.json version seed at 0.9.0
  affects:
    - plan 15-02 (mix.exs extras wiring depends on these files existing)
    - GitHub Actions release-please workflow (config-file + manifest-file inputs in 15-02)
tech_stack:
  added: []
  patterns:
    - Release Please manifest mode (config.json + manifest.json pair)
    - Header-only CHANGELOG stub (RP inserts version sections below prose header)
    - Reverse-chronological milestone history in docs/
key_files:
  created:
    - release-please-config.json
    - .release-please-manifest.json
    - CHANGELOG.md
    - docs/HISTORY.md
  modified: []
decisions:
  - "Seeded .release-please-manifest.json at 0.9.0 (not 0.0.0) per issue #2087 — 0.0.0 seed causes pre-major bump options to be ignored"
  - "Used release-as: 0.10.0 one-time pin to override commit-based math (confirmed zero BREAKING CHANGE footers in git history)"
  - "bump-minor-pre-major: true to prevent any future BREAKING CHANGE from bumping to 1.0.0 pre-launch"
  - "CHANGELOG.md is header-only with zero hand-written version sections — Release Please owns all ## X.Y.Z entries"
metrics:
  duration_minutes: 2
  completed_date: "2026-05-23"
  tasks_completed: 2
  files_created: 4
  files_modified: 0
requirements_satisfied: [ADOPT-02]
---

# Phase 15 Plan 01: Release Please Config, Manifest, CHANGELOG Stub, and Milestone History Summary

Created four static repository files that plan 15-02 depends on: Release Please version-strategy config + manifest pair, a header-only CHANGELOG.md stub, and the retroactive docs/HISTORY.md milestone history.

## What Was Built

**Wave 0 prerequisite files for plan 15-02** — all four must exist on disk before mix.exs adds them to `extras:` and before the GitHub Actions workflow references config-file/manifest-file.

### release-please-config.json

Release Please version strategy for Parapet's first Hex release:
- `release-type: "elixir"` — Elixir-aware version handling
- `bump-minor-pre-major: true` — prevents any BREAKING CHANGE from bumping 0.x.x → 1.0.0
- `bump-patch-for-minor-pre-major: true` — feat: commits bump patch while pre-1.0 (0.9.x → 0.9.1)
- `release-as: "0.10.0"` — ONE-TIME pin overriding commit-based math; forces first release to exactly 0.10.0

### .release-please-manifest.json

Single key `{ ".": "0.9.0" }` — seeded at the last planning milestone version (not 0.0.0 per issue #2087).

### CHANGELOG.md

Header-only stub with `# Changelog` H1, Keep-a-Changelog + SemVer preamble, and a "Planning milestones vs Hex releases" prose section linking to `docs/HISTORY.md` (v0.1–v0.9 history) and `.planning/MILESTONES.md`. Contains **zero** `## X.Y.Z` version sections — Release Please owns those.

### docs/HISTORY.md

Nine `## v0.X — Title (Date)` sections in reverse-chronological order (v0.9 first, v0.1 last), sourced faithfully from `.planning/MILESTONES.md`. Each section includes accomplishment bullets and a `**Stats:**` line drawn from the corresponding MILESTONES.md block. Framed as planning tranches, not Hex release versions (the package was not published to hex.pm during v0.1–v0.9).

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Release Please config, manifest, CHANGELOG stub | 7e5e397 | release-please-config.json, .release-please-manifest.json, CHANGELOG.md |
| 2 | Retroactive milestone history | a677445 | docs/HISTORY.md |

## Deviations from Plan

None — plan executed exactly as written. The `release-please-config.json` matches Pattern 2 verbatim from PATTERNS.md with all three Parapet adaptations applied. The manifest uses 0.9.0 per the critical reconciliation. The CHANGELOG.md stub follows Pattern 5 exactly. HISTORY.md follows Pattern 6 with all nine milestones sourced from MILESTONES.md.

## TODO: One-Time `release-as` Removal (D-10)

**IMPORTANT — action required after 0.10.0 release PR merges (post-Phase-18):**

Remove `"release-as": "0.10.0"` from `release-please-config.json` after the `chore(main): release 0.10.0` PR is merged. This is a one-time pin. If left in, all future releases will also be pinned to 0.10.0, causing republish failures on Hex. Release Please auto-updates the manifest to `"0.10.0"` when the PR merges — only the config line needs removal.

The line to remove:
```json
      "release-as": "0.10.0"
```

Location: `release-please-config.json`, inside `packages["."]` object.

## Known Stubs

None — all four files are fully complete static content. No data sources need wiring.

## Threat Flags

No new security-relevant surface introduced. All files are static `.json` and `.md` documents with no runtime behavior, network endpoints, or auth paths.

## Self-Check

Files verified to exist:
- FOUND: release-please-config.json
- FOUND: .release-please-manifest.json
- FOUND: CHANGELOG.md
- FOUND: docs/HISTORY.md

Commits verified:
- FOUND: 7e5e397
- FOUND: a677445

## Self-Check: PASSED
