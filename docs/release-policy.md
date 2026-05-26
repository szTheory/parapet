# Release Policy

Parapet `main` is the stable release line after `v1.0.0`.

## Operating Model

- Every merge to `main` must keep the repo releasable.
- `release_gate` is the canonical merge-readiness signal for `main`.
- Version cuts happen through Release Please PRs generated from conventional commits on `main`.
- Patch and minor releases are published only by merging the generated Release Please PR after CI is green and release truth is coherent.
- If `main` is green and release truth is coherent, the default stance is silence on the wire: no milestone churn, no release drama, no invented work.

## Work Classes

- Stable-line work: small fixes, docs, CI hygiene, packaging truth, and maintenance that preserves the released line.
- Feature work: additive behavior or meaningful product-surface expansion. Serious feature work must begin in a dedicated PR branch and should be scoped before it becomes milestone work.
- Release work: merging a generated Release Please PR plus the normal publish and verification flow.

## Quiet Default

- No active milestone is required just because candidate work exists.
- Deferred maturity items stay parked until a concrete slice is worth opening.
- If there is no concrete release-affecting work, the correct answer is that there is nothing to do.

## Release Truth

Before merging a Release Please PR, confirm:

- `release_gate` is green on the release commit.
- `release-please-config.json` has no one-off `release-as` pin unless a deliberate staged cut is in progress.
- Hex packaging and HexDocs wiring still match the published package shape.
- The changelog and tag to be created match the actual changes on `main`.

## Non-Goals

- Parapet does not auto-publish on every merge to `main`.
- Active milestones do not downgrade `main` to an unstable branch.
- `.release-please-manifest.json` is Release Please state, not a hand-edited operator control.
- Serious feature work is not ambient background activity on `main`; it belongs in explicit PR-shaped trains.
