---
phase: 15-packaging-credibility-gate
plan: "02"
subsystem: packaging
tags: [hex-metadata, ex-doc, release-please, ci-workflow]
dependency_graph:
  requires: ["15-01"]
  provides: [hex-package-metadata, docs-extras, release-please-manifest-mode]
  affects: [mix.exs, .github/workflows/release-please.yml]
tech_stack:
  added: []
  patterns: [mix-hex-metadata, ex-doc-extras, release-please-manifest-mode]
key_files:
  created: []
  modified:
    - mix.exs
    - .github/workflows/release-please.yml
decisions:
  - "Place description: and source_url: as top-level keys in project/0, not inside package/0 (Hex reads them from project/0 per ecto analog)"
  - "Use skip_undefined_reference_warnings_on: [\"CHANGELOG.md\"] in docs/0 to prevent docs --warnings-as-errors failures on RP-generated commit-hash links"
  - "Add workflow_dispatch: trigger and concurrency block to release-please workflow (oarlock pattern, not required but improves CI robustness)"
metrics:
  duration_minutes: 8
  completed_date: "2026-05-23"
  tasks_completed: 2
  files_modified: 2
---

# Phase 15 Plan 02: Wire mix.exs Metadata and Release Please Manifest Mode Summary

Populated mix.exs with 4-key Hex links, description, source_url, version 0.10.0, a docs: extras block with CHANGELOG.md and docs/HISTORY.md, and switched the release-please workflow from action-input mode to manifest mode.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Populate mix.exs metadata, add docs: extras block, bump version to 0.10.0 | 70157d5 | mix.exs |
| 2 | Switch the release-please workflow to manifest mode | 2475a11 | .github/workflows/release-please.yml |

## What Was Built

### Task 1: mix.exs Metadata

Modified `mix.exs` to add:

- `@source_url "https://github.com/szTheory/parapet"` and `@version "0.10.0"` module attributes at the top of `Parapet.MixProject`
- `version: @version` (was `"0.1.0"`)
- `description:` as a top-level key in `project/0` with the D-02 sentence
- `source_url: @source_url` as a top-level key in `project/0`
- Extracted the inline `package: [...]` into `defp package/0` with:
  - `CHANGELOG*` glob added to the `files:` whitelist
  - 4-key `links:` map: GitHub, HexDocs, Issues, Changelog
- Added `defp docs/0` with 7 extras (README.md, CHANGELOG.md, docs/HISTORY.md, and the four existing docs/*.md), `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]`, and `groups_for_extras: [Guides: ~r/docs\//]`

### Task 2: release-please.yml Manifest Mode

Updated `.github/workflows/release-please.yml` to:

- Switch action namespace from `google-github-actions/release-please-action@v4` to `googleapis/release-please-action@v4`
- Remove `release-type: elixir` and `target-branch: main` inputs
- Add `token:`, `config-file: release-please-config.json`, and `manifest-file: .release-please-manifest.json` inputs
- Add `id: release` to the step
- Add `workflow_dispatch:` trigger and `concurrency:` block (from oarlock pattern)
- Add `actions/checkout@v4` step with `fetch-depth: 0`
- No `publish-hex` job, no `HEX_API_KEY` reference (D-10 scope fence maintained)

## Verification Results

- `mix verify.public_api` (= `mix docs --warnings-as-errors`): **PASSED** — green with all 7 extras including CHANGELOG.md and docs/HISTORY.md; `skip_undefined_reference_warnings_on` prevents RP link failures
- `mix test`: **PASSED** — 291 tests, 0 failures (one intermittent async flap observed in Notifier, pre-existing, not caused by this plan's changes)
- `mix hex.build`: **PASSED** — produces `parapet-0.10.0.tar`; inner `contents.tar.gz` contains both `CHANGELOG.md` and `docs/HISTORY.md`
- Negative gates: no `publish-hex` job, no `HEX_API_KEY`, no `google-github-actions` namespace — all clean
- YAML validation: workflow parses via `yaml.safe_load`

## Deviations from Plan

None — plan executed exactly as written. The description was initially split across two lines (Elixir string continuation) but was collapsed to one line so the plan's grep verification command (`grep -Eq 'description: "An opinionated SRE'`) passes. Functionally identical.

## Known Stubs

None — all data is wired. The CHANGELOG.md stub is intentionally empty of version sections (Release Please will write those when a release PR merges — this is the correct state).

## Threat Flags

No new security-relevant surface introduced. The workflow's `token:` input uses `secrets.RELEASE_PLEASE_TOKEN || github.token` with `permissions:` limited to `contents: write` + `pull-requests: write` (T-15-03 accepted, T-15-04 mitigated). No new network endpoints, auth paths, or schema changes.

## Self-Check: PASSED

- mix.exs exists and contains all required metadata: CONFIRMED
- .github/workflows/release-please.yml exists in manifest mode: CONFIRMED
- Commit 70157d5 (Task 1): CONFIRMED
- Commit 2475a11 (Task 2): CONFIRMED
- mix verify.public_api: PASSED
- mix hex.build tarball ships CHANGELOG.md and docs/HISTORY.md: CONFIRMED
