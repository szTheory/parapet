---
phase: 22-release-readiness-1-0-cut
plan: 02
subsystem: release-please-publish
tags: [github-actions, release-please, hex, rel-02]

requires:
  - "22-01 CI topology complete"
  - "Existing Release Please workflow and manifest mode"
provides:
  - "Release Please job outputs exposed for downstream publish automation"
  - "Hex publish job gated on release_created"
  - "Post-publish verification for both Hex package metadata and HexDocs"

requirements-completed: [REL-02]
completed: 2026-05-26
---

# Phase 22 Plan 02 Summary

Extended the existing Release Please workflow so Hex publishing happens only for a real release event and runs against the exact release SHA.

## What Changed

- Added job outputs on `release-please` for `release_created`, `version`, `tag_name`, and `sha`.
- Added a `publish-hex` job with `needs: [release-please]`.
- Gated `publish-hex` on `needs.release-please.outputs.release_created == 'true'`.
- Checked out `${{ needs.release-please.outputs.sha }}` before publishing.
- Wired `HEX_API_KEY` from repository secrets.
- Added the ordered publish flow: `mix hex.publish --dry-run`, `mix hex.publish --yes`, `mix hex.info parapet VERSION`, and `mix hex.docs fetch parapet VERSION` plus a HexDocs URL check.

## Verification Results

| Check | Result |
|-------|--------|
| `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-please.yml'))"` | PASS |
| `rg -n "release_created|needs: \\[release-please\\]" .github/workflows/release-please.yml` | PASS |
| `rg -n "hex.publish --dry-run|hex.publish --yes|HEX_API_KEY" .github/workflows/release-please.yml` | PASS |
| `rg -n "mix hex.info parapet|mix hex.docs fetch parapet" .github/workflows/release-please.yml` | PASS |

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
