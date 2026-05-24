---
phase: 15-packaging-credibility-gate
reviewed: 2026-05-23T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - mix.exs
  - .github/workflows/release-please.yml
  - release-please-config.json
  - .release-please-manifest.json
  - CHANGELOG.md
  - docs/HISTORY.md
findings:
  critical: 1
  warning: 5
  info: 3
  total: 9
status: issues_found
---

# Phase 15: Code Review Report

**Reviewed:** 2026-05-23
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

This phase wires up Hex packaging metadata (`mix.exs`), release automation
(`release-please.yml` + config + manifest), and changelog/history scaffolding.
The D-10 scope fence is respected: there is **no** `mix hex.publish`, no
`publish-hex` job, and no `HEX_API_KEY` reference in the workflow — correct and
intentional. The `release-as: "0.10.0"` pin and `0.9.0` manifest seed are
deliberate and well-formed.

The most important defect is a credibility/packaging blocker: the package
declares `licenses: ["MIT"]` and the README's License section says "See
`LICENSE` for details," but **no `LICENSE` file exists in the repository** and it
is not listed in `package.files`. For a "packaging credibility gate" phase whose
purpose is a publishable, trustworthy first release, shipping a license
declaration with no license text is the single highest-risk gap.

A second concrete packaging defect: stray `.DS_Store` files exist on the
filesystem under `lib/` and `priv/`, both of which are in `package.files`. Hex
builds the tarball from filesystem globs (it does **not** honor `.gitignore`), so
these macOS artifacts would ship inside the published package.

The remaining findings concern release-automation robustness (concurrency
cancellation on the release job, unpinned action refs, changelog anchor shape)
and minor metadata polish.

## Critical Issues

### CR-01: `licenses: ["MIT"]` declared but no `LICENSE` file exists (and not in package files)

**File:** `mix.exs:42-43`
**Issue:** The package metadata asserts `licenses: ["MIT"]` and the README
License section (`README.md:206-208`) states "MIT License. See `LICENSE` for
details." There is no `LICENSE` (or `LICENSE.md` / `COPYING`) file anywhere in
the repo (`find . -iname 'license*'` returns nothing), and `LICENSE` is not
included in `package.files`:
`~w(lib priv .formatter.exs mix.exs README* CHANGELOG* docs)`.

Consequences for the first publish:
- The Hex package page advertises MIT but contains no license text — legally and
  reputationally weak for a "credibility gate" release.
- The README link to `LICENSE` is a dead reference inside the published tarball
  and on HexDocs.
- Adopters performing license-compliance review cannot vendor the license text.

**Fix:** Add a real `LICENSE` file at repo root and include it in the package
file globs:

```elixir
# mix.exs — package/0
files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* docs),
licenses: ["MIT"],
```

Then create `/LICENSE` with the standard MIT text (correct copyright holder /
year), e.g.:

```
MIT License

Copyright (c) 2026 szTheory

Permission is hereby granted, free of charge, to any person obtaining a copy
... (full MIT text) ...
```

## Warnings

### WR-01: `.DS_Store` artifacts under `lib/` and `priv/` will ship in the Hex tarball

**File:** `mix.exs:42` (file glob includes `lib`, `priv`)
**Issue:** `lib/.DS_Store` and `priv/.DS_Store` exist on disk. `mix hex.build`
expands `package.files` globs against the **filesystem**, not git, so
`.gitignore` (which does ignore `.DS_Store`) does **not** prevent these from
being packaged. The published tarball would contain macOS metadata cruft —
unprofessional for a credibility-gate release and a (small) information leak.
**Fix:** Delete the stray files and/or add an explicit exclusion. Simplest:
remove them before building (`find lib priv docs -name .DS_Store -delete`).
Optionally guard packaging by narrowing globs or adding a build-time check.
Verify with `mix hex.build` and inspect the file list before the first publish.

### WR-02: `cancel-in-progress: true` on the release job risks aborting an in-flight release

**File:** `.github/workflows/release-please.yml:13-15`
**Issue:** The concurrency group cancels in-progress runs on new pushes to the
same ref. release-please-action performs tag creation and GitHub Release
creation as part of a run; cancelling mid-run (e.g., a quick follow-up merge to
`main`) can leave the release in a partially-applied state (PR merged / version
bumped but tag or GitHub Release not created), which is awkward to recover from
and can desync the manifest from published tags.
**Fix:** For release workflows, prefer serializing without cancellation:

```yaml
concurrency:
  group: release-please-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: false
```

### WR-03: GitHub Actions pinned to mutable major-version tags, not commit SHAs

**File:** `.github/workflows/release-please.yml:21, 27`
**Issue:** `actions/checkout@v4` and `googleapis/release-please-action@v4` are
pinned to mutable tags. This workflow runs with `contents: write` and
`pull-requests: write` and consumes `secrets.RELEASE_PLEASE_TOKEN`. A compromised
or retagged third-party action could create malicious tags/releases or exfiltrate
the token. Pinning to a full commit SHA is the GitHub-recommended hardening for
privileged workflows. (Note: the existing `ci.yml` also uses `@v4`/`@v1` tags, so
this is a project-wide convention — calling it out here because the release
workflow is the privileged one.)
**Fix:** Pin to immutable SHAs with a version comment:

```yaml
- uses: actions/checkout@<full-sha>  # v4.x.x
  with:
    fetch-depth: 0
- uses: googleapis/release-please-action@<full-sha>  # v4.x.x
```

### WR-04: CHANGELOG has no release-please insertion anchor / `[Unreleased]` section

**File:** `CHANGELOG.md:8-12`
**Issue:** The only `##` heading is `## Planning milestones vs Hex releases`
(prose, not a version). The elixir release-type's changelog updater prepends new
version sections beneath the header block; with a non-standard prose `##` heading
immediately following the Keep-a-Changelog preamble, the inserted `## 0.10.0`
entry may land in an unexpected position (e.g., above or interleaved with the
"Planning milestones" note), producing a messy first changelog. This is a
correctness risk for the automated first release rather than a guaranteed break.
**Fix:** Validate insertion behavior before the first real run (release-please
PR preview), or restructure so version entries have a clean anchor — e.g., demote
the prose note to a single paragraph (no `##`) or move it below an explicit
`## [Unreleased]` placeholder that release-please replaces. Confirm the generated
PR diff places `## 0.10.0` at the top of the version list.

### WR-05: Heavy `igniter` toolchain is a non-optional runtime dependency of the published package

**File:** `mix.exs:80`
**Issue:** `{:igniter, "~> 0.7.9"}` is declared as a normal (non-optional,
runtime) dependency, yet it is only used by install/generator `mix` tasks
(`lib/mix/tasks/parapet.*`). Igniter transitively pulls in `sourceror`,
`rewrite`, `spitfire`, `owl`, `glob_ex`, and `req` into every consumer's
dependency tree at runtime, even though those are code-generation tools needed
only at install time. For a credibility-gate release this materially inflates the
dependency surface adopters inherit. (Pre-existing — not introduced by this
phase's diff — but it becomes live the moment this metadata ships, so it's in
scope for the publish gate.)
**Fix:** Reclassify install-time tooling so it does not become a runtime/prod
dependency of consumers — e.g.:

```elixir
{:igniter, "~> 0.7.9", optional: true}
```

and ensure the generator tasks degrade gracefully (or document that
`mix parapet.install` requires adding igniter to the host) when it's absent.
Confirm `lib` still compiles without igniter present.

## Info

### IN-01: `priv/` template/asset files ship under MIT without per-file headers

**File:** `mix.exs:42` (`priv` in package files)
**Issue:** Packaging `priv` (templates, `prometheus/rules.yml`, Grafana JSON,
EEx generators) is correct, but combined with CR-01 there is currently no license
text traveling with these generated-into-host artifacts. Once CR-01 is fixed this
is fully resolved; noting for completeness.
**Fix:** Resolve CR-01 (add `LICENSE` to the tarball); optionally note generator
output licensing in README/docs.

### IN-02: Em-dash (U+2014) in `description`

**File:** `mix.exs:16`
**Issue:** The Hex `description` contains a literal em-dash ("—"). This is valid
UTF-8 and renders fine on hex.pm, but some terminals/search/CI logs handle
non-ASCII inconsistently. Purely cosmetic.
**Fix:** Optional — replace with " - " (spaced hyphen) if strict ASCII is
preferred for metadata.

### IN-03: `release-as: "0.10.0"` removal is a future-maintenance footgun if left in

**File:** `release-please-config.json:10`
**Issue:** The one-time `release-as` pin is intentional and documented (per
15-01-SUMMARY.md, with a removal TODO) — not a defect. Flagged only as a reminder
that leaving it in after the 0.10.0 release would force every subsequent release
to 0.10.0 and suppress normal conventional-commit version bumping.
**Fix:** Remove the `"release-as": "0.10.0"` line from
`release-please-config.json` immediately after the 0.10.0 release lands, as
already planned.

---

_Reviewed: 2026-05-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
