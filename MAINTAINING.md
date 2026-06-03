# Maintaining Parapet

This file is maintainer-only release procedure truth. For adopter-facing release behavior, use [Release Policy](docs/release-policy.md). For repository protection settings, use [Branch Protection](docs/branch-protection.md).

## Routine release train

1. Confirm `main` is releasable and that the aggregate `release_gate` check is green.
2. Review the open Release Please PR, if one exists. Confirm the changelog, version bump, and `.release-please-manifest.json` match the intended release effect.
3. Do not manually merge a routine Release Please PR. The workflow enables auto-merge; GitHub merges it when branch protection and `release_gate` pass.
4. After merge, watch the publish workflow and confirm the Hex package, Git tag, GitHub release, and HexDocs page all reflect the same version.
5. If a publish fails after the Release Please PR merged, treat that as release incident work: fix forward with a small PR, keep the failed run linked, and avoid hand-editing release state unless Release Please is stuck.

## Staged version override

Use a `Release-As:` footer only for deliberate staged cuts where Release Please's computed version is not the release you intend.

Example commit footer:

```text
Release-As: 1.2.0
```

Before merging a staged cut:

1. Confirm the staged version is named in the PR description or linked milestone context.
2. Confirm the manifest diff matches the staged version.
3. Confirm `release_gate` is green.
4. Remove the staged override from future work once the cut has landed.

## Holding or blocking a cut

Use the `do-not-merge` label when a release PR exists but should not publish yet.

```bash
gh pr edit <number> --add-label "do-not-merge"
```

Remove the label only after the blocker is resolved and `release_gate` is expected to pass. Closing the Release Please PR is reserved for cases where the generated release state is wrong enough that a fresh PR is clearer than repair.

## When release truth blocks

If `.release-please-manifest.json` looks wrong, first inspect the commits that Release Please is reading:

```bash
git log --oneline --decorate --no-merges
```

Then check the Release Please workflow logs. Manual manifest edits are a last resort for a stuck train, not a normal operator control.

If CI blocks the cut:

1. Open the failed `release_gate` run.
2. Fix the failing lane in a normal PR.
3. Let Release Please refresh or re-run after `main` is green again.
4. Keep release-policy changes in [docs/release-policy.md](docs/release-policy.md), not in this checklist, unless the maintainer procedure itself changed.

## Post-publish verification

After a release publishes, verify:

- The GitHub release tag matches `mix.exs`.
- Hex shows the expected package version.
- HexDocs renders the new version.
- The changelog entry describes the release effect.
- `release_gate` stayed green on the release PR merge commit.

If any check fails, file a follow-up PR or issue with the failed URL, expected version, actual version, and the workflow run link.
