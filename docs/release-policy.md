# Release Policy

Parapet `main` is the stable release line after `v1.0.0`.

## Operating Model

- Every merge to `main` must keep the repo releasable.
- `release_gate` is the canonical merge-readiness signal for `main`, enforced via branch protection with `enforce_admins: true` — no bypass.
- Version cuts happen through Release Please PRs generated from conventional commits on `main`.
- Patch and minor releases are published by **letting the auto-merged Release Please PR land**. The release workflow activates auto-merge as soon as the PR opens; GitHub merges it when `release_gate` is green. No human merge action is required for routine release trains.
- If `main` is green and release truth is coherent, the default stance is silence on the wire: no milestone churn, no release drama, no invented work.

## Work Classes

- Stable-line work: small fixes, docs, CI hygiene, packaging truth, and maintenance that preserves the released line.
- Feature work: additive behavior or meaningful product-surface expansion. Serious feature work must begin in a dedicated PR branch and should be scoped before it becomes milestone work.
- Release work: handled automatically — Release Please opens the PR, the action activates auto-merge, CI gates the cut, the `publish-hex` job tags and publishes after merge.

## Quiet Default

- No active milestone is required just because candidate work exists.
- Deferred maturity items stay parked until a concrete slice is worth opening.
- If there is no concrete release-affecting work, the correct answer is that there is nothing to do.

## Release Truth (contract enforced by CI)

The `release_gate` status check is what guarantees release truth — it must be green before the release PR can merge. The check requires:

- Lint passes (formatting, credo, dialyzer, public-API gate, docs-with-warnings-as-errors).
- Test passes against a real Postgres.
- Demo smoke test passes.
- No one-off `release-as` pin in `release-please-config.json` (unless a deliberate staged cut is in progress).

If any of those go red, the auto-merge sits unfilled and the cut blocks. No release publishes until the gate is green again.

## Manual Intervention

Auto-merge does the routine work. A human steps in only for these cases:

- **Deliberate staged cut** — push a commit with a `Release-As: x.y.z` footer to override the version Release Please would compute (used during the `v0.10.0` → `v1.0.0` arc and the `v1.0.0` → `v1.0.1` cap).
- **Hold a cut** — apply a `do-not-merge` label to the Release Please PR (or `gh pr edit <n> --add-label "do-not-merge"`), or close the PR. Auto-merge will pause until the label is removed and CI passes again.
- **`.release-please-manifest.json` repair** — the manifest is Release Please state, not a hand-edited operator control. Touching it manually is reserved for breaking out of a stuck train.
- **Co-maintainer joins** — the `required_approving_review_count: 0` setting on branch protection assumes a solo maintainer. The moment a second human maintainer joins, revisit the review requirement.

## Non-Goals

- Parapet does not auto-publish on every merge to `main` — only Release Please PR merges trigger publish.
- Active milestones do not downgrade `main` to an unstable branch.
- `.release-please-manifest.json` is Release Please state, not a hand-edited operator control.
- Serious feature work is not ambient background activity on `main`; it belongs in explicit PR-shaped trains.
