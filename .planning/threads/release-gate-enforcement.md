---
thread: release-gate-enforcement
opened: "2026-05-27"
target_milestone: v1.2 (Authoring DX & Maturity)
status: partially-shipped
shipped_in: v1.0.1 cut (2026-05-27)
links:
  - .planning/phases/22-release-readiness-1-0-cut/22-LEARNINGS.md
  - docs/release-policy.md
  - CONTRIBUTING.md
  - .github/PULL_REQUEST_TEMPLATE.md
  - .github/workflows/ci.yml
  - .github/workflows/release-please.yml
---

**Status update 2026-05-27 (v1.0.1 train):** Most of this thread shipped during the v1.0.1 cut. Remaining work scoped down to a single v1.2 item — see "Remaining for v1.2" at the bottom.

**Shipped (no longer open):**
- `enforce_admins: true` enabled on main branch protection — admin bypass closed.
- `allow_auto_merge: true` on the repo.
- `required_approving_review_count: 0` (solo OSS rationale locked into user memory as `project-solo-oss-required-reviews-disabled`).
- Auto-merge step in `release-please.yml` (PR #6 / commit c2349b4).
- `workflow_dispatch:` on `ci.yml` + dispatch step in `release-please.yml` so CI actually runs on Release Please PRs (PR #7 / commits 132e436 + ad39b77). Solves the GITHUB_TOKEN cycle-prevention gotcha.
- `docs/release-policy.md` recast from "manual merge" to "auto-merge by default" with a Manual Intervention section.

**Remaining for v1.2:**
- Codify conventional-commit taxonomy in `CONTRIBUTING.md` + `.github/PULL_REQUEST_TEMPLATE.md` (which `docs:`/`chore:`/`ci:`/`test:` paths can be direct on a multi-maintainer project — moot for parapet's solo posture but worth documenting for adopters who fork this CI shape).
- Path-based rulesets to allow direct-to-main for `docs:` / `.planning/` paths (reduces PR overhead on noise commits).
- **Flaky test:** `test/mix/tasks/parapet.gen.grafana_test.exs:22` ~~failed on the workflow_dispatch-triggered CI run during the v1.0.1 cut~~ → **fixed in PR #9 / commit fa26ac2** (`fix(test): isolate parapet.gen.grafana_test from global SLO state`). The fix is a bandage — `async: false` + setup-block snapshot/restore. The architectural root cause (Parapet.SLO uses global Application env as its registry) is split into its own dedicated thread: **[`slo-state-off-application-env`](slo-state-off-application-env.md)**. That thread is a v1.2 graduation candidate (high priority per maintainer signal).

# Thread: Make `release_gate` Truly Required

## What we're investigating

`release_gate` is named as a required status check in `main` branch protection, but admin role can bypass it. Today's pattern: admin pushes to main report `Bypassed rule violations for refs/heads/main: Required status check "release_gate" is expected.` This means the protection is an audit trail, not a gate. See `22-LEARNINGS.md` LEARN-22-A for the concrete cost (the `docs/release-policy.md` regression that snuck in via bypass and surfaced on PR #3).

## Specific open questions

### 1. Branch protection ruleset shape

GitHub's branch protection has two relevant knobs:
- "Restrict pushes that create files" + "Require status checks to pass before merging" — gates merges.
- "Do not allow bypassing the above settings" (administrators included) — closes the admin loophole.

Need to: enable "Do not allow bypassing" for the `main` branch protection rule. This is a user action in the GitHub UI (or `gh api`). **Out of scope for autonomous Claude action**; surface for user approval.

### 2. Conventional-commit taxonomy codified

Codify in `CONTRIBUTING.md` and `.github/PULL_REQUEST_TEMPLATE.md`:

**OK direct-to-main (quiet maintenance):**
- `docs:` (docs-only changes, including `.planning/` and CHANGELOG manual additions outside Release Please)
- `chore:` (build, deps, .gitignore, .DS_Store cleanup, etc. that don't change library behavior)
- `ci:` (workflow file changes that don't relax gates)
- `test:` (test hygiene that doesn't change tested behavior — e.g., flaky-test stabilization, `async: true → false`)

**PR-required (feature/maintenance with risk):**
- `feat:` (new public API, new behavior, new module)
- `fix:` (any `lib/` behavior change)
- `perf:` (any perf-affecting change in `lib/`)
- `refactor:` (any structural change in `lib/`, even if behavior-preserving — needs CI confirmation)
- Any change touching schema/migrations
- Any dep bump (mix.exs, mix.lock)

The taxonomy doubles as the Release Please trigger surface: `feat:` → minor bump, `fix:` → patch, breaking → major.

### 3. Impact on Release Please

Release Please reads conventional commit prefixes off the merge history of `main` to compute the next version. If the taxonomy is honored, version bumps stay predictable. If maintainers drift (e.g., a `feat:`-shaped change pushed as `chore:` to dodge PR), Release Please miscounts. Codifying the taxonomy + enforcing it via branch protection closes both loopholes.

### 4. Migration plan for the bypass-cleanup window

Today's audit-trail mode has been in place since v1.0 shipped. Concrete bypass-driven landings to retro-classify:
- 2026-05-26: `c2a1ee8 docs: codify quiet stable-line release posture` — docs-only, OK direct, but introduced LEARN-22-A regression.
- 2026-05-27: `3a66122 docs(planning): archive v1.0 cut phase artifacts` — docs-only, OK direct.
- 2026-05-27: `ba658a5 docs(planning): reconcile phase 20 and 21 records with shipped state` — docs-only, OK direct.
- 2026-05-27: `dbd4337 test(mcp): restore :repo env on exit and disable async to prevent leakage` — `test:`-typed, behavior change to test isolation; ambiguous under the new taxonomy. The `async: true → false` flip is technically a test-config change, not lib behavior. Borderline OK direct; in the new taxonomy, this should go through PR if there's any doubt.
- 2026-05-27: `1883664 docs(hex): include docs/release-policy.md in extras` — docs-config fix for a regression caused by an earlier bypass. OK direct, but the *underlying need* for it is the LEARN-22-A signal.

No retroactive enforcement needed; these all stand. Forward, the taxonomy applies.

## Recommended sequencing

1. **v1.1 (Actionable Recovery)** — don't touch this thread. v1.1 is a feature milestone and shouldn't be mixed with workflow-policy work.
2. **v1.2 (Authoring DX & Maturity)** — this thread becomes a planned slice:
   - Update `CONTRIBUTING.md` with the conventional-commit taxonomy.
   - Update `.github/PULL_REQUEST_TEMPLATE.md` with the corresponding checklist.
   - Update `docs/release-policy.md` to reference the taxonomy as the merge contract.
   - **Ask user to enable "Do not allow bypassing" on main branch protection** (this is a GitHub UI action — surface in conversation, do not auto-attempt).

## Out of scope

- Auto-detection / auto-enforcement of commit-type-vs-changed-files mismatch (e.g., a linter that flags `chore:` commits touching `lib/`). Possible v1.3+ tooling; not needed for the immediate policy fix.
- Forcing every maintenance commit through PR. The taxonomy explicitly preserves direct-to-main for docs/chore/ci/test.

## Next concrete step

When the user opens v1.2, this thread is the seed for one of the v1.2 phases. Don't auto-open; wait for the user's signal.
