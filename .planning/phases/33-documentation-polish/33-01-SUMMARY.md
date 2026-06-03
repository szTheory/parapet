---
phase: 33-documentation-polish
plan: "01"
subsystem: docs
tags: [hexdocs, migration, deployment, exdoc, branding]
requires:
  - phase: 29-stability-adopter-onboarding
    provides: Stable 1.x API and adopter onboarding context
provides:
  - v0.x to v1.0 migration guide
  - production deployment guide
  - HexDocs guide wiring and docs-local branding assets
affects: [documentation, hexdocs, release-packaging]
tech-stack:
  added: []
  patterns: [docs-local ExDoc branding assets, adopter-facing guide grouping]
key-files:
  created:
    - docs/migration-v1.md
    - docs/deployment.md
    - docs/assets/parapet-logo.svg
    - docs/assets/favicon.svg
  modified:
    - mix.exs
key-decisions:
  - "Placed branding assets under docs/assets so the existing Hex package docs whitelist covers them."
  - "Kept migration guidance practical and linked older history to docs/HISTORY.md instead of duplicating changelog content."
patterns-established:
  - "New adopter guides are registered in both docs().extras and the Guides group."
  - "ExDoc logo and favicon use static SVG files with width, height, and viewBox."
requirements-completed: [DX-03, DX-04, MAT-07]
duration: 11min
completed: 2026-06-03
---

# Phase 33 Plan 01 Summary

**Adopter migration and deployment guides published through HexDocs with docs-local Parapet branding assets**

## Performance

- **Duration:** 11 min
- **Started:** 2026-06-03T17:59:00Z
- **Completed:** 2026-06-03T18:10:35Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `docs/migration-v1.md` with concrete v0.x to 1.x upgrade checks, including `Parapet.SLO.define/2` deprecation guidance and `Parapet.SLO.Provider` migration.
- Added `docs/deployment.md` covering host-owned metrics exposure, Prometheus rule loading, deploy markers, durable-evidence migrations, optional dependency compile-out, and strict doctor validation.
- Added package-safe SVG logo/favicon assets and wired both new guides plus branding into `mix.exs` ExDoc configuration.

## Task Commits

1. **Tasks 1-3: Migration guide, deployment guide, and ExDoc branding wiring** - `cd26cce` (docs)

## Files Created/Modified

- `docs/migration-v1.md` - Practical adopter guide for moving from pre-1.0 releases to the stable 1.x line.
- `docs/deployment.md` - Phoenix host-owned production deployment guide for Parapet surfaces.
- `docs/assets/parapet-logo.svg` - ExDoc logo asset.
- `docs/assets/favicon.svg` - ExDoc favicon asset.
- `mix.exs` - Added guide extras, guide grouping, and ExDoc `logo`/`favicon` options.

## Decisions Made

- Kept all branding under `docs/assets/` so `package.files` did not need to change.
- Used the current guide naming chosen by the plan: `docs/migration-v1.md` and `docs/deployment.md`.
- Linked historical upgrade context to `docs/HISTORY.md` and `CHANGELOG.md` rather than duplicating release history in the migration guide.

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `test -f docs/migration-v1.md && rg -q 'docs/HISTORY.md|HISTORY.md' docs/migration-v1.md && rg -q 'Parapet\.SLO\.define/2' docs/migration-v1.md && rg -q 'Parapet\.SLO\.Provider' docs/migration-v1.md && rg -q 'mix compile --warnings-as-errors' docs/migration-v1.md && rg -q 'mix parapet\.doctor --ci' docs/migration-v1.md`
- `test -f docs/deployment.md && rg -q 'metrics endpoint|/metrics' docs/deployment.md && rg -q 'Prometheus' docs/deployment.md && rg -q 'Parapet\.Plug\.DeployMarker' docs/deployment.md && rg -q 'durable-evidence|durable evidence' docs/deployment.md && rg -q 'optional dependency|optional dependencies' docs/deployment.md && rg -q 'mix parapet\.gen\.prometheus' docs/deployment.md && rg -q 'mix ecto\.migrate' docs/deployment.md && rg -q 'mix parapet\.doctor --ci' docs/deployment.md && rg -q 'auth|authentication' docs/deployment.md`
- `test -f docs/assets/parapet-logo.svg && test -f docs/assets/favicon.svg && rg -q 'width=' docs/assets/parapet-logo.svg && rg -q 'height=' docs/assets/parapet-logo.svg && rg -q 'viewBox=' docs/assets/parapet-logo.svg && rg -q 'width=' docs/assets/favicon.svg && rg -q 'height=' docs/assets/favicon.svg && rg -q 'viewBox=' docs/assets/favicon.svg && rg -q '"docs/migration-v1.md"' mix.exs && rg -q '"docs/deployment.md"' mix.exs && rg -q 'logo: "docs/assets/parapet-logo.svg"' mix.exs && rg -q 'favicon: "docs/assets/favicon.svg"' mix.exs`
- `mix format --check-formatted mix.exs`
- `MIX_ENV=dev mix docs --warnings-as-errors`

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 33-02 can add maintainer/contributor maturity docs and demo Compose documentation without depending on further HexDocs changes.

---
*Phase: 33-documentation-polish*
*Completed: 2026-06-03*
