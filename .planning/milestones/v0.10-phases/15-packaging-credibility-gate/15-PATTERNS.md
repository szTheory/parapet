# Phase 15: Packaging Credibility Gate - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 6 (2 modified, 4 created)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mix.exs` | config | build-time transform | `deps/ecto/mix.exs` + `deps/req/mix.exs` | exact |
| `CHANGELOG.md` | doc-stub | event-driven (Release Please bot writes body) | `/Users/jon/projects/oarlock/CHANGELOG.md` | exact |
| `docs/HISTORY.md` | doc | static | `.planning/MILESTONES.md` (source material) | content-transform |
| `release-please-config.json` | config | CI trigger | `/Users/jon/projects/oarlock/release-please-config.json` | exact |
| `.release-please-manifest.json` | config | CI trigger | `/Users/jon/projects/oarlock/.release-please-manifest.json` | exact |
| `.github/workflows/release-please.yml` | CI workflow | event-driven | `/Users/jon/projects/oarlock/.github/workflows/release-please.yml` | exact |

---

## Pattern Assignments

### `mix.exs` (config, build-time transform)

**Analogs:** `deps/ecto/mix.exs` (primary) and `deps/req/mix.exs` (secondary)

**Current state** (`/Users/jon/projects/parapet/mix.exs` lines 1–57 — the full file):

```elixir
defmodule Parapet.MixProject do
  use Mix.Project

  def project do
    [
      app: :parapet,
      version: "0.1.0",           # line 7 — change to @version
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: [                  # lines 11-15 — inline; extract to package()
        files: ~w(lib priv .formatter.exs mix.exs README* docs),
        licenses: ["MIT"],
        links: %{}
      ],
      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix, :ex_unit]]
    ]
  end
  # ...
  defp aliases do
    [
      "verify.public_api": ["docs --warnings-as-errors"]  # line 54
    ]
  end
end
```

**Module-attribute pattern** (from `deps/ecto/mix.exs` lines 4–5; `deps/req/mix.exs` lines 4–5):

```elixir
# ecto: top of module
@source_url "https://github.com/elixir-ecto/ecto"
@version "3.13.6"

# req: top of module
@version "0.5.17"
@source_url "https://github.com/wojtekmach/req"
```

Copy this idiom verbatim for Parapet — attributes go at the top of `Parapet.MixProject`, before `def project`:

```elixir
@source_url "https://github.com/szTheory/parapet"
@version "0.10.0"
```

**`project/0` top-level keys pattern** (from `deps/ecto/mix.exs` lines 7–24):

```elixir
def project do
  [
    app: :ecto,
    version: @version,
    elixir: "~> 1.14",
    deps: deps(),
    consolidate_protocols: Mix.env() != :test,
    elixirc_paths: elixirc_paths(Mix.env()),

    # Hex
    description: "A toolkit for data mapping and language integrated query for Elixir",
    package: package(),

    # Docs
    name: "Ecto",
    docs: docs()
  ]
end
```

Note: `description:` and `source_url:` are **top-level keys in `project/0`**, not inside `package:`. `package:` and `docs:` are function calls, not inline keyword lists.

For Parapet, the patched `project/0` list adds (relative to current state):
- `version: @version` (was `version: "0.1.0"`)
- `description: "..."` (new top-level key)
- `source_url: @source_url` (new top-level key)
- `package: package()` (was inline keyword list)
- `docs: docs()` (new)

**`package/0` function pattern** (from `deps/ecto/mix.exs` lines 42–54):

```elixir
defp package do
  [
    maintainers: ["Eric Meadows-Jönsson", "José Valim", "Felipe Stival", "Greg Rychlewski"],
    licenses: ["Apache-2.0"],
    links: %{
      "GitHub" => @source_url,
      "Changelog" => "https://hexdocs.pm/ecto/changelog.html"
    },
    files:
      ~w(.formatter.exs mix.exs README.md CHANGELOG.md lib) ++
        ~w(integration_test/cases integration_test/support)
  ]
end
```

Parapet equivalent — note `CHANGELOG*` glob (covers both `CHANGELOG.md` and future variants), and four links (D-04):

```elixir
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
```

**`docs/0` function pattern** (from `deps/ecto/mix.exs` lines 56–74; `deps/req/mix.exs` lines 103–129):

```elixir
# ecto: key keys
defp docs do
  [
    main: "Ecto",
    source_ref: "v#{@version}",
    source_url: @source_url,
    skip_undefined_reference_warnings_on: ["CHANGELOG.md"],  # line 74 — CRITICAL for CI
    extras: extras(),   # defined as separate public function
    groups_for_extras: groups_for_extras(),
    # ...
  ]
end

# req: simpler shape — closer to what Parapet needs
defp docs do
  [
    main: "readme",
    source_url: @source_url,
    source_ref: "v#{@version}",
    extras: [
      "README.md",
      "CHANGELOG.md"
    ],
    # ...
  ]
end
```

Parapet `docs/0` — inline extras (no separate function needed at this scale):

```elixir
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
```

**Anti-pattern to avoid** (from `deps/req/mix.exs` lines 49–58 — req puts `description:` inside `package:`):

```elixir
# req does this — DO NOT copy for Parapet:
defp package do
  [
    description: "Req is a batteries-included HTTP client for Elixir.",  # WRONG placement
    licenses: ["Apache-2.0"],
    links: %{...}
  ]
end
```

Hex reads `description:` from `project/0`, not `package/0`. Ecto (lines 17–18) is the correct reference — `description:` at the top level of `project/0`.

---

### `CHANGELOG.md` (doc-stub, event-driven)

**Analog:** `/Users/jon/projects/oarlock/CHANGELOG.md` lines 1–11 (the preserved stub prose above RP-generated entries)

The oarlock CHANGELOG shows exactly what a post-Release-Please file looks like: the human-authored prose header is preserved verbatim above the `## 0.1.0` section that Release Please inserted:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v1.1** in **`.planning/MILESTONES.md`** — those **v1.x** labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`MILESTONES.md`** as canonical for milestone dates and archive paths.

## 0.1.0 (2026-04-29)     ← Release Please inserted this and everything below
```

**Parapet stub to commit** — adapt the oarlock prose for Parapet's context (milestone labels differ: v0.1–v0.9, not v1.0–v1.1):

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

**Critical constraint:** Do NOT add any `## <version>` sections to this file. Release Please inserts those. Any human-authored `## 0.10.0` section will create a duplicate when RP runs.

**Ordering constraint (from RESEARCH.md validation architecture):** This file MUST be committed to the repo before `mix.exs` is modified to add `"CHANGELOG.md"` to `extras:`. If `mix verify.public_api` runs with `extras:` referencing a non-existent file, `mix docs` errors out.

---

### `docs/HISTORY.md` (doc, static / content-transform)

**Source material:** `.planning/MILESTONES.md` (full file read — 9 milestones, v0.1 through v0.9, each with Date, Stats, Accomplishments, Known Gaps)

**Pattern:** Transform each milestone block into a `## vX.Y — <Title> (<Date>)` H2 section. Reverse chronological order (newest first — v0.9 at top, v0.1 at bottom) so adopters see the most recent work first.

**Header pattern** (modeled on oarlock CHANGELOG stub prose style):

```markdown
# Parapet Milestone History

This document records the development milestones for Parapet v0.1–v0.9.
These are planning tranches, not Hex release versions — the package was not
published to hex.pm during this period.

For the changelog of published Hex releases (v0.10+), see [CHANGELOG.md](../CHANGELOG.md).

---
```

**Per-milestone section pattern** — source data from `.planning/MILESTONES.md`:

```markdown
## v0.9 — Performance, Scale & DX (2026-05-23)

- Shipped proactive TSDB cardinality protection: a `mix parapet.doctor cardinality` static
  analyzer plus a compile-time `Parapet.Metrics.Validator` enforcing a 10-label ceiling.
- Delivered database scale & pruning: composite indexes for `Incident`/`TimelineEntry`/`ToolAudit`
  at >100k rows, a `Parapet.Evidence.Archiver` with resolved-only retention.
- Made the Operator UI responsive under load with bounded queue paging and a 50k+ incident benchmark.
- Unified the Day-1 experience under `mix parapet.install` (Igniter orchestrator).
- Proved multi-node safety with Ecto-backed action claims and circuit breakers.
- Hardened milestone closure: phases 6-14 backfilled verification surfaces and reconciled
  planning-artifact drift.

**Stats:** ~20,274 LOC (Elixir/EEx) · 36 plans · 88 commits · 2026-05-19 → 2026-05-23
```

Continue this pattern for v0.8 through v0.1. The accomplishment bullets come directly from the `### Accomplishments` lists in MILESTONES.md. Stats line from the `**Stats:**` block of each milestone.

**Ordering constraint:** This file MUST exist before `mix.exs` is modified to add `"docs/HISTORY.md"` to `extras:`.

---

### `release-please-config.json` (config, CI trigger)

**Analog:** `/Users/jon/projects/oarlock/release-please-config.json` (full file — 12 lines)

**Oarlock file (verbatim):**

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bump-minor-pre-major": false,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "include-v-in-tag": true
    }
  }
}
```

**Parapet adaptations** (3 differences from oarlock):

1. `"bump-minor-pre-major": false` → `true` — Parapet must prevent a BREAKING CHANGE from ever bumping to 1.0.0 pre-launch.
2. `"release-as": "0.10.0"` added inside `packages["."]` — one-time pin to force the first release to `0.10.0`. Remove after the 0.10.0 release PR is merged.
3. No other differences — `release-type: elixir`, `bump-patch-for-minor-pre-major: true`, `changelog-path`, `include-v-in-tag` all copy verbatim.

**Parapet file:**

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

**Post-0.10.0 follow-up:** Remove the `"release-as": "0.10.0"` line after the release PR merges. Document this as a TODO in the plan.

---

### `.release-please-manifest.json` (config, CI trigger)

**Analog:** `/Users/jon/projects/oarlock/.release-please-manifest.json` (full file — 3 lines)

**Oarlock file (verbatim):**

```json
{
  ".": "0.1.0"
}
```

**Parapet adaptations:** Seed value only. Oarlock seeded at `"0.1.0"` (its first release). Parapet seeds at `"0.9.0"` — the last planning milestone — so that with `release-as: "0.10.0"` the first computed release is pinned to exactly `0.10.0`.

**Parapet file:**

```json
{
  ".": "0.9.0"
}
```

**Why `"0.9.0"` and not `"0.0.0"`:** RESEARCH.md cites release-please issue #2087 — a `"0.0.0"` seed causes pre-major bump options to be ignored, potentially still proposing 1.0.0. `"0.9.0"` is a non-zero real version that avoids this boundary condition. The `release-as: "0.10.0"` pin in config overrides commit-based math entirely anyway.

---

### `.github/workflows/release-please.yml` (CI workflow, event-driven)

**Analog:** `/Users/jon/projects/oarlock/.github/workflows/release-please.yml` lines 1–49 (the `release-please` job; the `publish-hex` job is out of scope for Phase 15 per D-10)

**Current Parapet workflow** (`/Users/jon/projects/parapet/.github/workflows/release-please.yml` lines 1–20 — full file):

```yaml
on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

name: release-please

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/release-please-action@v4
        with:
          release-type: elixir
          target-branch: main
```

**Oarlock workflow** (lines 1–49 — `release-please` job only):

```yaml
name: Release Please

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: write
  issues: write
  pull-requests: write

concurrency:
  group: release-please-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  release-please:
    name: Release Please
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
      version: ${{ steps.release.outputs.version }}
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          fetch-depth: 0

      - name: Run Release Please
        id: release
        uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```

**Critical differences from current Parapet workflow:**

1. **Action namespace:** `google-github-actions/release-please-action@v4` → `googleapis/release-please-action@v4` (oarlock uses the current namespace).
2. **Action inputs:** Remove `release-type: elixir` and `target-branch: main`. Replace with `config-file:` + `manifest-file:` inputs. This switches from action-input mode to manifest mode — required for the config JSON to be read.
3. **Token:** Add `token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}`.
4. **Do NOT copy** the `publish-hex` job from oarlock — D-10 explicitly excludes publish automation from Phase 15.

**Minimum Parapet update** (keep existing structure, patch only the step):

```yaml
on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

name: release-please

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - name: Run Release Please
        id: release
        uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```

Optional enhancements from oarlock (can be added in same commit): `workflow_dispatch:` trigger, `concurrency:` block, `actions/checkout` step with `fetch-depth: 0`, `job outputs:` block. These are improvements, not blockers.

---

## Shared Patterns

### `@source_url` Module Attribute
**Source:** `deps/ecto/mix.exs` line 4; `deps/req/mix.exs` line 5
**Apply to:** `mix.exs` only (single file in scope)

```elixir
@source_url "https://github.com/szTheory/parapet"
@version "0.10.0"
```

Both attributes go at the top of `Parapet.MixProject`, before `def project`. They are referenced as `@source_url` and `@version` throughout the file.

### `skip_undefined_reference_warnings_on`
**Source:** `deps/ecto/mix.exs` line 74
**Apply to:** `docs/0` function in `mix.exs`

```elixir
skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
```

This prevents `mix verify.public_api` (`docs --warnings-as-errors`) from failing when Release Please writes commit-hash links like `([abc123](https://github.com/...))` in the changelog — those are external URLs, not resolvable Elixir module cross-references.

### Explicit `config-file` + `manifest-file` in Workflow
**Source:** `/Users/jon/projects/oarlock/.github/workflows/release-please.yml` lines 43–49
**Apply to:** `.github/workflows/release-please.yml`

```yaml
uses: googleapis/release-please-action@v4
with:
  token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}
  config-file: release-please-config.json
  manifest-file: .release-please-manifest.json
```

Without explicitly passing `config-file:` and `manifest-file:`, the action runs in action-input mode (reading `release-type: elixir` from the `with:` block) and ignores `release-please-config.json` entirely.

---

## Execution Ordering Constraint

The RESEARCH.md validation architecture identifies a hard dependency chain for execution order:

1. **Wave 0 — Create doc stubs first:** `CHANGELOG.md` and `docs/HISTORY.md` must exist on disk before `mix.exs` is modified to include them in `extras:`. If `mix verify.public_api` runs after the extras are added but before the files exist, `mix docs` errors.

2. **Wave 0 — Create Release Please config files:** `release-please-config.json` and `.release-please-manifest.json` must exist before the workflow is updated to reference them.

3. **Wave 1 — Modify `mix.exs`:** Add `@source_url`/`@version` attributes, `description:`, `source_url:`, extract `package()`, add `docs()`.

4. **Wave 2 — Modify workflow:** Update `.github/workflows/release-please.yml` to switch to manifest mode.

Suggested two-commit structure from RESEARCH.md: (1) all new files in one commit, (2) all `mix.exs` + workflow changes in a second commit.

---

## No Analog Found

None. All 6 files have exact or near-exact analogs in the codebase or the oarlock reference project.

---

## Metadata

**Analog search scope:** `/Users/jon/projects/parapet/deps/ecto/`, `/Users/jon/projects/parapet/deps/req/`, `/Users/jon/projects/oarlock/`, `/Users/jon/projects/parapet/.github/workflows/`, `/Users/jon/projects/parapet/.planning/`
**Files read:** 9 (parapet mix.exs, parapet release-please.yml, oarlock release-please-config.json, oarlock manifest, oarlock workflow, oarlock CHANGELOG.md, deps/ecto/mix.exs, deps/req/mix.exs, .planning/MILESTONES.md)
**Pattern extraction date:** 2026-05-23
