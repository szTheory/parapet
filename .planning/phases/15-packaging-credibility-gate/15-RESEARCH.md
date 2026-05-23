# Phase 15: Packaging Credibility Gate - Research

**Researched:** 2026-05-23
**Domain:** Elixir/Hex package metadata, ex_doc extras, Release Please version strategy, CHANGELOG ownership
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add `@source_url "https://github.com/szTheory/parapet"` module attribute to `mix.exs`, reference everywhere.
- **D-02:** Add top-level `:description`. Default: *"An opinionated SRE reliability layer for Phoenix/Elixir SaaS — turn existing telemetry into user-journey SLOs, deploy correlation, incident evidence, and operator-grade runbooks."*
- **D-03:** Add top-level `source_url: @source_url`.
- **D-04:** Populate `links:` with **GitHub**, **HexDocs** (`https://hexdocs.pm/parapet`), **Issues** (`#{@source_url}/issues`), and **Changelog** (HexDocs URL, since D-05 adds extras).
- **D-05:** Add a `docs:` block with `source_url: @source_url`, `source_ref: "v#{@version}"`, and `extras:` including `CHANGELOG.md`, `README.md`, and existing `docs/*.md` files.
- **D-06:** Release Please **owns** `CHANGELOG.md` body. Humans commit at most a header-only stub — `# Changelog` plus optional prose — never any hand-written `## <version>` sections.
- **D-07:** Retroactive v0.1–v0.9 history lives in `docs/HISTORY.md` (sourced from `.planning/MILESTONES.md`), framed as milestone history. The CHANGELOG.md stub links to it.
- **D-08:** Add `CHANGELOG*` to the Hex `files:` whitelist (currently `~w(lib priv .formatter.exs mix.exs README* docs)`).
- **D-09:** Add `release-please-config.json` with `bump-minor-pre-major: true` and `bump-patch-for-minor-pre-major: true`. Seed `.release-please-manifest.json` so the first release is `0.10.0`. Update `version:` in `mix.exs` to `0.10.0`.
- **D-10:** Phase 15 prepares repo state only — does **not** run `mix hex.publish`. Do not merge the Release Please release PR.

### Claude's Discretion

- Exact wording of the `:description` (D-02) — the proposed sentence is the default.
- Whether the Changelog link points at HexDocs (`changelog.html`) or GitHub blob — driven by D-05 being added (default to HexDocs).

### Deferred Ideas (OUT OF SCOPE)

- Actual `mix hex.publish` — manual, post-Phase-18.
- Reconciling/removing the GSD planning tags (`v0.1`–`v0.9`) vs future semver release tags.
- Hosted CHANGELOG / release subscription.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | A stranger evaluating the package on hex.pm sees populated metadata — `links:` (GitHub, HexDocs, Issues), a `:description` sentence, and `source_url` — instead of an empty `links: %{}`. | Verified pattern: `@source_url` module attribute + `package:` block + `docs:` block, modeled on `deps/ecto/mix.exs` and `deps/req/mix.exs`. |
| ADOPT-02 | An adopter can read a root `CHANGELOG.md` covering v0.1–v0.9 retroactively and ongoing releases. | Verified: Release Please + header-only stub + `docs/HISTORY.md` for retroactive milestone history. `CHANGELOG*` added to `files:` whitelist. |
</phase_requirements>

---

## Summary

Phase 15 is a pure configuration-and-documentation phase: no runtime Elixir code changes, no new dependencies, no database migrations. All deliverables are modifications to `mix.exs`, two new JSON files for Release Please, a new `CHANGELOG.md` stub, a new `docs/HISTORY.md`, and an update to the GitHub Actions workflow. The critical technical risk is not in difficulty but in ordering and correctness: getting the Release Please manifest seed and config right so the next generated release PR proposes `0.10.0` (not `1.0.0` or `0.1.1`), and ensuring the `docs:` block with extras doesn't break `mix verify.public_api` (which runs `docs --warnings-as-errors`).

The project has a proven reference implementation: `deps/oarlock` (locally at `/Users/jon/projects/oarlock`) shows the exact Release Please config + manifest + workflow + CHANGELOG stub pattern for an szTheory Elixir library. Key differences for Parapet: (1) we seed the manifest at a value that makes the next release `0.10.0` rather than `0.1.0`, (2) we need `bump-minor-pre-major: true` (oarlock uses `false`), and (3) the CHANGELOG stub links to `docs/HISTORY.md` for retroactive history.

The root cause of the stale `1.0.0` release-please PR (from 2026-05-12) is **not** a `BREAKING CHANGE` commit footer — git log confirms no such footer exists in any commit. The `1.0.0` was produced by release-please's "first stable release" heuristic: when no manifest exists and `mix.exs` already declares a version, release-please with accumulated `feat:` commits and no pre-major config can propose a major version. The fix is explicit: add `release-please-config.json` + `.release-please-manifest.json` with `release-as: "0.10.0"` to pin the first computed release, then remove the pin after that PR merges.

**Primary recommendation:** Follow the oarlock reference pattern exactly, with the three adaptations above. Parallelizing all `mix.exs` changes into a single commit and the RP config/manifest/CHANGELOG stub into a single commit is the cleaner approach.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| hex.pm package metadata (`links:`, `:description`, `source_url`) | Build-time (`mix.exs`) | — | Hex reads `package:` block at publish time from `mix.exs`. No runtime involvement. |
| HexDocs documentation extras (`docs:` block) | Build-time (`mix.exs` + `ex_doc`) | — | `mix docs` / `mix verify.public_api` reads `docs:` at doc-generation time. |
| Release Please version strategy | CI (GitHub Actions) | Local config files | `release-please-config.json` + `.release-please-manifest.json` consumed by `googleapis/release-please-action@v4` on push to `main`. |
| `CHANGELOG.md` body | CI (Release Please bot) | — | Release Please writes the `## version` sections. Humans only commit the stub header. |
| Retroactive history (`docs/HISTORY.md`) | Repository docs | hex.pm package (`files:` includes `docs/`) | Human-authored, sourced from `.planning/MILESTONES.md`. Ships with the package because `docs/` is already in `files:` whitelist. |

---

## Standard Stack

### Core (all already in the project — no new deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ex_doc` | `~> 0.31` (locked: 0.40.2) | Hex documentation generation; consumes `docs:` block | Standard Elixir doc toolchain; already a dev dep |
| `googleapis/release-please-action` | `@v4` | GitHub Actions bot that generates Release PRs from Conventional Commits | Already wired in `.github/workflows/release-please.yml`; proven in oarlock |

[VERIFIED: codebase read — `mix.exs` line 47, `mix.lock`]

### New Files (no library installs required)

| File | Purpose |
|------|---------|
| `release-please-config.json` | Release Please package config: release-type, bump flags, per-package settings |
| `.release-please-manifest.json` | Tracks last-released version so RP computes the next one |
| `CHANGELOG.md` | Root changelog, header-only stub; RP owns the body |
| `docs/HISTORY.md` | Retroactive v0.1–v0.9 milestone history for adopters |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `release-as: "0.10.0"` one-time pin in config | Seed manifest at `"0.9.9"` + accumulated feat: patches → 0.10.0 | Version math is unreliable without knowing exact commit types; `release-as` is explicit and proven (oarlock gotcha #5) |
| `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]` | Omitting CHANGELOG.md from `extras:` | Omitting breaks D-05/D-04 (HexDocs Changelog link); using the skip option is the ecto-proven pattern |

**Installation:** No new packages to install. All changes are file edits and new config/doc files.

---

## Package Legitimacy Audit

No external packages are installed in this phase. All tooling (`ex_doc`, `googleapis/release-please-action@v4`) is already present.

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Commits (Conventional Commits on main)
        |
        v
GitHub Actions: release-please.yml
        |
        +-- reads: release-please-config.json (bump flags, release-type: elixir)
        +-- reads: .release-please-manifest.json (current version = seed)
        |
        v
Release Please bot
        |
        +-- computes next version (seed + commit types → 0.10.0 via release-as pin)
        +-- generates/updates CHANGELOG.md (inserts ## 0.10.0 section below header)
        +-- updates mix.exs version: field
        +-- opens Release PR "chore(main): release 0.10.0"
        |
        v  (PR merged later, post-Phase-18 — D-10)
mix hex.publish (manual)
        |
        +-- reads mix.exs package: block → hex.pm metadata
        +-- reads mix.exs docs: block → HexDocs extras (CHANGELOG.md, README.md, docs/*.md)
        +-- ships files: whitelist (includes CHANGELOG*, docs/)
        |
        v
hex.pm / HexDocs
  Stranger sees: description, links: {GitHub, HexDocs, Issues, Changelog}
  Adopter reads: CHANGELOG.md (RP-generated entries), docs/HISTORY.md (retroactive)
```

### Recommended Project Structure (Phase 15 deliverables only)

```
parapet/
├── mix.exs                          # MODIFIED: @source_url, description, source_url,
│                                    #   links:, docs: block, files: whitelist, @version→0.10.0
├── CHANGELOG.md                     # NEW: header-only stub, RP owns the body
├── docs/
│   ├── HISTORY.md                   # NEW: retroactive v0.1–v0.9 milestone history
│   ├── adopter-flows.md             # existing (already ships via files: docs/)
│   ├── operator-ui.md               # existing
│   ├── slo-reference.md             # existing
│   └── telemetry.md                 # existing
├── release-please-config.json       # NEW: bump flags, release-type: elixir, release-as pin
├── .release-please-manifest.json    # NEW: seed value for version computation
└── .github/workflows/
    └── release-please.yml           # MODIFIED: add config-file + manifest-file inputs
```

### Pattern 1: mix.exs `@source_url` + `package:` + `docs:` Block

This is the canonical szTheory/Elixir OSS pattern, verified from two reference implementations.

```elixir
# Source: deps/ecto/mix.exs + deps/req/mix.exs (read 2026-05-23)

defmodule Parapet.MixProject do
  use Mix.Project

  @source_url "https://github.com/szTheory/parapet"
  @version "0.10.0"

  def project do
    [
      app: :parapet,
      version: @version,
      # ...existing keys...
      description: "An opinionated SRE reliability layer for Phoenix/Elixir SaaS — turn existing telemetry into user-journey SLOs, deploy correlation, incident evidence, and operator-grade runbooks.",
      source_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  defp package do
    [
      files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* docs),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/parapet",
        "Issues" => "#{@source_url}/issues",
        "Changelog" => "https://hexdocs.pm/parapet/changelog.html"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/HISTORY.md",
        "docs/adopter-flows.md",
        "docs/operator-ui.md",
        "docs/slo-reference.md",
        "docs/telemetry.md"
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_extras: [
        Guides: ~r/docs\//
      ]
    ]
  end
end
```

Key points:
- `package:` is now a function call `package()`, not an inline keyword list
- `docs:` is also a function call `docs()`
- `description:` and `source_url:` are **top-level** in `project/0`, not inside `package:`
- `files:` uses `CHANGELOG*` (glob) so it matches both `CHANGELOG.md` and any future variants
- `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]` prevents `--warnings-as-errors` from failing on release-please-generated commit links that may reference modules not resolvable in doc context [VERIFIED: `deps/ex_doc/lib/ex_doc.ex`]

### Pattern 2: `release-please-config.json`

```json
// Source: /Users/jon/projects/oarlock/release-please-config.json (read 2026-05-23)
// Adapted for Parapet: bump-minor-pre-major flipped to true, release-as pin added
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "include-v-in-tag": true,
      "release-as": "0.10.0"
    }
  }
}
```

**The `release-as` pin is one-time only.** Remove it after the `chore(main): release 0.10.0` PR merges (post-Phase-18). If the pin is left in, all future releases will also be pinned to `0.10.0` and republish attempts will fail.

**Bump flag semantics** [CITED: googleapis/release-please docs/manifest-releaser.md]:
- `bump-minor-pre-major: true` — when version < 1.0.0, a `BREAKING CHANGE` footer bumps the **minor** (e.g., 0.9.x → 0.10.0) instead of the major (0.x.x → 1.0.0)
- `bump-patch-for-minor-pre-major: true` — when version < 1.0.0, a `feat:` commit bumps the **patch** (e.g., 0.10.0 → 0.10.1) instead of the minor (0.10.0 → 0.11.0)
- Combined: pre-1.0, everything moves slowly — BREAKING → minor, feat → patch, fix → patch

### Pattern 3: `.release-please-manifest.json` Seed

```json
{
  ".": "0.9.0"
}
```

The manifest represents the **last released version**. Release Please reads it and computes the next version based on accumulated commits since the last release PR.

**Why `"0.9.0"` + `release-as: "0.10.0"`:**
The `release-as` pin overrides commit-based computation and directly sets the next version to `0.10.0`. This is necessary because:
1. No BREAKING CHANGE footers exist in the commit history (confirmed by `git log --all --format="%B"` search — zero hits)
2. With only `feat:` commits and `bump-patch-for-minor-pre-major: true`, the computed next version from seed `0.9.0` would be `0.9.1`, not `0.10.0`
3. `release-as: "0.10.0"` explicitly pins the first release, exactly as oarlock used `release-as: "0.1.0"` for its first release (bootstrap-elixir-hex-lib skill, gotcha #5)

**After the 0.10.0 release PR merges:** Release Please auto-updates the manifest to `"0.10.0"`. Remove `release-as` from the config. Future releases auto-bump based on commits.

**CRITICAL — Issue #2087 awareness** [CITED: github.com/googleapis/release-please/issues/2087]: If manifest is seeded at `"0.0.0"`, the pre-major bump options are NOT respected and RP may still propose 1.0.0. Seeding at `"0.9.0"` (a real non-zero version) avoids this boundary condition entirely.

### Pattern 4: Updated `.github/workflows/release-please.yml`

```yaml
# Source: /Users/jon/projects/oarlock/.github/workflows/release-please.yml (read 2026-05-23)
# Key change from current parapet workflow: add config-file + manifest-file inputs

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```

**Auto-discovery vs explicit:** `googleapis/release-please-action@v4` defaults `config-file` to `release-please-config.json` and `manifest-file` to `.release-please-manifest.json` at the repo root [CITED: github.com/googleapis/release-please-action README]. Explicit passing is not strictly required for default-named files, but oarlock passes them explicitly as a defensive practice. Follow oarlock — always pass explicitly.

**Current workflow gap:** `.github/workflows/release-please.yml` currently passes only `release-type: elixir` and `target-branch: main`, with no config-file or manifest-file inputs. Once those files are added to the repo, the workflow must be updated to reference them (or RP will fall back to action-level `release-type` input mode, ignoring config.json).

### Pattern 5: CHANGELOG.md Header-Only Stub

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog tracks **published Hex releases** using Semantic Versioning headings like `## 0.10.0`.
Separately, maintainers track development tranches as planning milestones in [`.planning/MILESTONES.md`](.planning/MILESTONES.md).
For v0.1–v0.9 milestone history, see [`docs/HISTORY.md`](docs/HISTORY.md).
```

**What Release Please does with this stub:** It inserts new `## version (date)` sections **below** the existing prose content (after the last `## ` heading it finds, or just below the `# Changelog` title if no `## ` headings exist). The header prose is preserved. No preamble comment (`<!-- Do not edit -->`) is required or automatically inserted by RP. [CITED: googleapis/release-please `src/updaters/changelog.ts` behavior — inserts above last `\n###? v?[0-9]` match, falls back to below H1]

**Do NOT include any `## version` sections** in the stub. The moment a human writes `## 0.10.0` before RP runs, RP will insert its generated section and create a duplicate.

### Pattern 6: `docs/HISTORY.md` Structure

```markdown
# Parapet Milestone History

This document records the development milestones for Parapet v0.1–v0.9.
These are planning tranches, not Hex release versions — the package was not
published to hex.pm during this period.

For the changelog of published Hex releases (v0.10+), see [CHANGELOG.md](../CHANGELOG.md).

---

## v0.9 Performance, Scale & DX (2026-05-23)
[content from .planning/MILESTONES.md]

## v0.8 Deterministic Escalation & Bounded Mitigation (2026-05-19)
[content from .planning/MILESTONES.md]

...continuing through v0.1...
```

Source material: `.planning/MILESTONES.md` has dated entries for all milestones v0.1–v0.9 with stats and accomplishments. Transform directly into HISTORY.md — no new content needed.

### Anti-Patterns to Avoid

- **Writing `## version` sections in the CHANGELOG.md stub.** Release Please will create duplicate entries. The stub must contain only `# Changelog` and optional prose.
- **Placing `description:` or `source_url:` inside the `package:` keyword list.** They are project-level keys in `project/0`, not package-level keys. Ecto and Req both put them at the top level.
- **Omitting `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]` from `docs:`.** Release-please generates commit hash links like `([abc123](https://github.com/...))` that resolve to external URLs, not Elixir modules. Without this option, `mix docs --warnings-as-errors` may emit warnings about unresolvable references, failing `mix verify.public_api` in CI.
- **Leaving `release-as: "0.10.0"` in config permanently.** It is a one-time pin. After the 0.10.0 release PR is merged, remove it.
- **Expecting release-please-action to read `release-please-config.json` without updating the workflow.** The current workflow passes `release-type: elixir` as an action input. When `release-please-config.json` is added, the workflow must be updated to pass `config-file:` and `manifest-file:` so action-input mode doesn't override config-file mode.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version bump logic from Conventional Commits | Custom git log parser + version calculator | Release Please (`release-please-config.json` + manifest) | RP handles all edge cases: pre-major semantics, BREAKING CHANGE detection, monorepo multi-package, PR creation, tag creation |
| CHANGELOG generation | Manual `## version` entries in stub | Let RP write them | Humans writing version sections will conflict with RP on the next run |
| Cross-ref safe doc extras | Custom markdown preprocessor | `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]` | Single config option vs a build step |

**Key insight:** The entire Release Please pipeline (version strategy + CHANGELOG generation) is already wired and proven. Phase 15 tunes it — it does not bootstrap it.

---

## Common Pitfalls

### Pitfall 1: First-Release Heuristic Produces 1.0.0

**What goes wrong:** Release Please without a manifest sees an existing `mix.exs` version, cannot find a prior release tag, and with many accumulated `feat:` commits proposes `1.0.0` — exactly what happened in the stale 2026-05-12 PR.
**Why it happens:** Without `release-please-config.json` + `.release-please-manifest.json`, RP runs in "simple" mode using the action-level `release-type` input. Its first-release heuristic can propose a major version.
**How to avoid:** Add both config and manifest files and pass them explicitly via `config-file:` / `manifest-file:` in the workflow. The `release-as: "0.10.0"` pin in config ensures the first computed release is exactly `0.10.0` regardless of commit history.
**Warning signs:** A release PR titled "chore(main): release 1.0.0" on the `origin/release-please--branches--main` branch — already visible and confirmed.

### Pitfall 2: `mix verify.public_api` Fails After Adding CHANGELOG.md to Extras

**What goes wrong:** Release Please generates commit hash links and external GitHub URLs in `CHANGELOG.md` that `ex_doc --warnings-as-errors` cannot resolve to Elixir module cross-references, causing `mix docs --warnings-as-errors` (= `mix verify.public_api`) to fail in CI.
**Why it happens:** `ex_doc` auto-links text that looks like `Module.function/arity` in extras. The RP-generated changelog contains commit descriptions that may inadvertently match this pattern.
**How to avoid:** Add `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]` to the `docs:` block. This is the same approach ecto uses (verified in `deps/ecto/mix.exs` line 74). [VERIFIED: codebase read]
**Warning signs:** CI fails on `mix verify.public_api` after the docs: extras block is added, but `mix docs` without `--warnings-as-errors` succeeds.

### Pitfall 3: `release-as` Pin Left in Config After First Release

**What goes wrong:** Every subsequent release PR will also be pinned to `0.10.0`. Re-publishing the same version will fail on Hex (version already exists). Release Please may open redundant PRs.
**Why it happens:** `release-as` is a global override, not a one-time flag. It must be manually removed.
**How to avoid:** Document the removal explicitly in the plan. After the `chore(main): release 0.10.0` PR merges, a follow-up commit removes `"release-as": "0.10.0"` from `release-please-config.json`.
**Warning signs:** Next release PR is titled "chore(main): release 0.10.0" again instead of "release 0.10.1" or similar.

### Pitfall 4: Workflow Not Updated — Config File Ignored

**What goes wrong:** `release-please-config.json` is added to the repo but the workflow still only passes `release-type: elixir` as an action-level input. Action-input mode takes precedence; the config file is ignored.
**Why it happens:** `googleapis/release-please-action@v4` has two operating modes: action-input mode (when `release-type` is passed as input) and manifest mode (when `config-file`/`manifest-file` are passed). They are not automatically combined.
**How to avoid:** Update `.github/workflows/release-please.yml` to replace `release-type: elixir` with `config-file: release-please-config.json` + `manifest-file: .release-please-manifest.json` (plus the optional token input). [VERIFIED: oarlock workflow, read 2026-05-23]
**Warning signs:** After pushing config files, release-please opens a PR with the wrong version (still 1.0.0), indicating it ran in action-input mode.

### Pitfall 5: `description:` Placed Inside `package:` Keyword List

**What goes wrong:** `description:` inside `package:` is not a valid Hex package key. Hex reads `description:` from the top-level `project/0` list. Placing it inside `package:` either silently no-ops or raises a compile/publish warning.
**Why it happens:** The Hex package API docs and the `project/0` Elixir docs overlap confusingly. Some libraries incorrectly put it in `package:`.
**How to avoid:** Place `description:` and `source_url:` at the top level of the `project/0` keyword list, not inside `package:`. Verified from both `deps/ecto/mix.exs` and `deps/req/mix.exs`. [VERIFIED: codebase read]
**Warning signs:** `mix hex.publish --dry-run` shows empty description on the package page preview.

---

## Code Examples

### Full `mix.exs` Diff Shape

```elixir
# Source: deps/ecto/mix.exs, deps/req/mix.exs (read 2026-05-23)

defmodule Parapet.MixProject do
  use Mix.Project

  # NEW: module attributes
  @source_url "https://github.com/szTheory/parapet"
  @version "0.10.0"  # was "0.1.0"

  def project do
    [
      app: :parapet,
      version: @version,  # was: version: "0.1.0"
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      # NEW top-level keys:
      description: "An opinionated SRE reliability layer for Phoenix/Elixir SaaS — turn existing telemetry into user-journey SLOs, deploy correlation, incident evidence, and operator-grade runbooks.",
      source_url: @source_url,
      package: package(),  # was: inline package: [...] keyword list
      docs: docs(),        # NEW
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix, :ex_unit]]
    ]
  end

  # ... application/0, elixirc_paths/1, deps/0, aliases/0 unchanged ...

  # NEW: extracted as function (was inline keyword list)
  defp package do
    [
      files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* docs),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/parapet",
        "Issues" => "#{@source_url}/issues",
        "Changelog" => "https://hexdocs.pm/parapet/changelog.html"
      }
    ]
  end

  # NEW: docs block
  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/HISTORY.md",
        "docs/adopter-flows.md",
        "docs/operator-ui.md",
        "docs/slo-reference.md",
        "docs/telemetry.md"
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_extras: [
        Guides: ~r/docs\//
      ]
    ]
  end
end
```

### `release-please-config.json` (complete)

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "include-v-in-tag": true,
      "release-as": "0.10.0"
    }
  }
}
```

### `.release-please-manifest.json` (complete)

```json
{
  ".": "0.9.0"
}
```

### `.github/workflows/release-please.yml` (updated section)

```yaml
# Replace the current step:
#   - uses: google-github-actions/release-please-action@v4
#     with:
#       release-type: elixir
#       target-branch: main

# With:
      - name: Run Release Please
        id: release
        uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```

Note: the action namespace changed from `google-github-actions/release-please-action` to `googleapis/release-please-action` in the oarlock reference. Update accordingly. [VERIFIED: oarlock workflow read 2026-05-23]

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Inline `package:` keyword list in `project/0` | Extracted `package()` function (matches ecto/req pattern) | Phase 15 | Cleaner separation; enables `docs()` function alongside it |
| No `docs:` block | `docs:` block with `source_url`, `source_ref`, `extras:` | Phase 15 | Enables HexDocs extras rendering (CHANGELOG, guides) |
| Empty `links: %{}` | Populated `links:` with 4 entries | Phase 15 | Satisfies ADOPT-01 |
| Release Please action-input mode (no config/manifest) | Manifest mode with config.json + manifest.json | Phase 15 | Enables pre-1.0 bump flags and explicit first-release pinning |
| No CHANGELOG.md | Header-only stub owned by Release Please | Phase 15 | Satisfies ADOPT-02; RP writes the version entries |
| No retroactive history | `docs/HISTORY.md` (milestone source) | Phase 15 | Covers v0.1–v0.9 for adopters without polluting RP's CHANGELOG |

**Deprecated/outdated:**
- `google-github-actions/release-please-action` (old namespace): Use `googleapis/release-please-action` instead. The oarlock workflow already uses the new namespace.
- Action-input `release-type:` as the primary configuration signal: With manifest mode, `release-type` and other settings live in `release-please-config.json`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The 1.0.0 release-please PR was caused by the "first stable release" heuristic (no manifest + no config), not by a BREAKING CHANGE commit footer. | Common Pitfalls #1, Code Examples | Risk is LOW: `git log --all --format="%B"` confirmed 0 BREAKING CHANGE occurrences; the manifest-seeding + release-as pin neutralizes either cause. |
| A2 | `googleapis/release-please-action@v4` ignores `release-please-config.json` when the workflow passes `release-type:` as an action input (action-input mode takes precedence over config-file mode). | Pitfall #4, Code Examples | Risk is MEDIUM: if RP actually merges both modes, the workflow update is still harmless (explicit is better than implicit). But if this assumption is wrong and RP already reads config.json in action-input mode, the manifest seed + release-as pin would still correctly compute 0.10.0. |
| A3 | `https://hexdocs.pm/parapet/changelog.html` will be the correct HexDocs URL for the generated changelog page once the package is published. | Code Examples (Changelog link) | Risk is LOW: this is the standard hex.pm URL pattern for extras pages (matches https://hexdocs.pm/ecto/changelog.html pattern from deps/ecto/mix.exs). |

**All other claims in this research were verified via direct codebase reads or official repository documentation.**

---

## Open Questions

1. **Should `.tool-versions` be added to align the publish workflow with CI?**
   - What we know: CI workflow hardcodes `elixir-version: '1.19.0'` / `otp-version: '27.2'`. The oarlock reference uses `version-file: .tool-versions` in its publish workflow.
   - What's unclear: Whether parapet needs a `.tool-versions` file at all for Phase 15 (no publish step in this phase per D-10).
   - Recommendation: Out of scope for Phase 15 (D-10 explicitly excludes publish). Defer to the phase that wires actual publishing.

2. **Should the stale `origin/release-please--branches--main` branch be deleted?**
   - What we know: The branch has a stale 1.0.0 Release PR commit. Once the new config/manifest land on main and RP re-runs, it will force-update this branch.
   - What's unclear: Whether the force-update is automatic or requires manual branch deletion.
   - Recommendation: Don't delete manually. Release Please force-pushes its PR branch on each run. The first push to main after the workflow update will regenerate the branch with the correct 0.10.0 PR.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix docs` / `ex_doc` | D-05 docs: block verification, `mix verify.public_api` | ✓ | 0.40.2 (locked) | — |
| `mix verify.public_api` | CI gate, docs: extras safety check | ✓ | alias defined in mix.exs:54 | — |
| `elixir` | Local verification runs | ✓ | 1.19.5 (OTP 28) | — |
| `googleapis/release-please-action@v4` | GitHub Actions | ✓ (already in workflow) | v4 | — |
| GitHub Actions runner | CI | ✓ (already running on push to main) | ubuntu-latest | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

---

## Validation Architecture

This phase installs no runtime code and changes no Elixir modules. The "tests" are:

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `mix docs --warnings-as-errors` (via `mix verify.public_api`) |
| Config file | `mix.exs` aliases (line 54) |
| Quick run command | `mix verify.public_api` |
| Full suite command | `mix test && mix verify.public_api` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-01 | `mix hex.build` produces tarball with populated `links:`, `description`, `source_url` | smoke | `mix hex.build && tar -tzf parapet-0.10.0.tar \| grep mix.exs` | ✅ (mix.exs modified) |
| ADOPT-01 | `mix verify.public_api` stays green after docs: block addition | unit | `mix verify.public_api` | ✅ existing alias |
| ADOPT-02 | `CHANGELOG.md` stub committed to repo root | manual | `test -f CHANGELOG.md` | ❌ Wave 0 |
| ADOPT-02 | `CHANGELOG*` glob matches in `files:` whitelist | smoke | `mix hex.build --dry-run` | ✅ (mix.exs modified) |
| ADOPT-02 | `docs/HISTORY.md` ships in the package (docs/ already whitelisted) | smoke | `mix hex.build && tar -tzf parapet-0.10.0.tar \| grep HISTORY` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix verify.public_api`
- **Per wave merge:** `mix test && mix verify.public_api && mix hex.build`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `CHANGELOG.md` — the header-only stub must exist before `mix docs` can include it in extras
- [ ] `docs/HISTORY.md` — must exist before `mix docs` can include it in extras (adding a non-existent file to `extras:` will cause `mix docs` to fail)
- [ ] `release-please-config.json` — needed before workflow update
- [ ] `.release-please-manifest.json` — needed before workflow update

**Ordering constraint:** Create `CHANGELOG.md` and `docs/HISTORY.md` BEFORE modifying `mix.exs` to add them to `extras:`. If `mix verify.public_api` runs between the extras addition and the files existing, it will fail because ex_doc will error on missing extra files.

---

## Security Domain

This phase makes no authentication, session, input validation, cryptographic, or access-control changes. All changes are static files (`.json`, `.md`) and build configuration (`mix.exs`). ASVS categories V2–V6 do not apply.

The only security-adjacent consideration: the `HEX_API_KEY` secret is referenced by the oarlock publish workflow but is NOT added in Phase 15 (D-10: no publish). If the workflow update adds a `publish-hex` job referencing the secret, it will fail silently (no secret = no publish). Phase 15 should NOT add the publish-hex job — only update the `release-please` job.

---

## Sources

### Primary (HIGH confidence)

- `deps/ecto/mix.exs` — canonical `@source_url`, `package()`, `docs()` pattern; `skip_undefined_reference_warnings_on`
- `deps/req/mix.exs` — `@source_url`, `package()`, `docs()` pattern; `source_ref: "v#{@version}"`
- `/Users/jon/projects/parapet/mix.exs` — current file to be modified (lines 11-15 package block, line 54 alias)
- `/Users/jon/projects/parapet/.github/workflows/release-please.yml` — current workflow (no config-file/manifest-file inputs)
- `/Users/jon/projects/oarlock/release-please-config.json` — canonical szTheory release-please-config.json template
- `/Users/jon/projects/oarlock/.release-please-manifest.json` — canonical manifest format
- `/Users/jon/projects/oarlock/.github/workflows/release-please.yml` — canonical workflow with explicit config-file/manifest-file inputs
- `/Users/jon/projects/oarlock/CHANGELOG.md` — real post-RP-generation CHANGELOG.md showing stub prose preserved above RP-generated `## version` sections
- `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md` — szTheory-specific gotcha catalog for Hex publishing
- `git show origin/release-please--branches--main:CHANGELOG.md` — confirmed stale 1.0.0 RP-generated CHANGELOG
- `git show origin/release-please--branches--main:mix.exs` — confirmed stale 1.0.0 version bump
- `git log --all --format="%B"` — confirmed zero BREAKING CHANGE footers in all commit history
- `deps/ex_doc/lib/ex_doc.ex` — confirmed `skip_undefined_reference_warnings_on` option exists in installed ex_doc 0.40.2
- `.planning/MILESTONES.md` — source material for docs/HISTORY.md (v0.1–v0.9 dated accomplishments)

### Secondary (MEDIUM confidence)

- [googleapis/release-please docs/manifest-releaser.md](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md) — `bump-minor-pre-major` / `bump-patch-for-minor-pre-major` semantics, manifest format
- [googleapis/release-please-action README](https://github.com/googleapis/release-please-action) — default config-file/manifest-file paths; `config-file` and `manifest-file` input names
- [googleapis/release-please issue #2087](https://github.com/googleapis/release-please/issues/2087) — manifest `0.0.0` seed causes pre-major options to be ignored; workaround: use `0.0.1` or higher

### Tertiary (LOW confidence — not used for critical decisions)

- WebSearch results on release-please pre-1.0 version strategy — corroborated by primary sources above; no LOW-confidence claims made

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all verified from direct codebase reads of reference implementations
- Architecture: HIGH — verified from oarlock live implementation + release-please branch state inspection
- Version math: HIGH — confirmed by git log search (no BREAKING CHANGE) + oarlock gotcha #5 pattern (release-as pin)
- Pitfalls: HIGH — verified from git state inspection + oarlock reference + ex_doc source read

**Research date:** 2026-05-23
**Valid until:** 2026-07-23 (60 days — stable tooling, config schema rarely changes)
