# Rulestead Release Engineering & CI

> **Purpose:** Workflow-by-workflow reference for rulestead's release pipeline and CI lanes. Every pattern here is already shipped in accrue, scrypath, lattice_stripe, or sigra — rulestead just combines the best parts.
>
> **Read this alongside:** `rulestead-engineering-dna-from-prior-libs.md` §2.2 (CI lane structure) + §2.3 (release & versioning).

---

## Bottom line (stack picks)

1. **CI/CD platform:** GitHub Actions.
2. **Elixir/OTP setup:** `erlef/setup-beam@v1` with `version-file: .tool-versions` + `version-type: strict`.
3. **Release automation:** `googleapis/release-please-action@v4`.
4. **Hex publishing:** `mix hex.publish --yes` with `--dry-run` first.
5. **Post-publish verification:** `mix verify.workspace_clean` + `mix verify.release_publish <v>` + `mix verify.release_parity <v>` (scrypath pattern — port verbatim).
6. **Conventional commits enforcement:** `amannn/action-semantic-pull-request@v5` on `pull_request_target`.
7. **Dependency hygiene:** Dependabot with `github-actions` + `mix` ecosystems; auto-merge patch-only.
8. **Drift monitors:** daily `verify-published-release.yml` cron; rolling single GitHub issue via `JasonEtco/create-an-issue@v2`.
9. **Supply chain:** SHA-pinned third-party actions with trailing `# vX.Y.Z` comments; Dependabot updates.
10. **Scripts-first surface:** every non-trivial step is `scripts/ci/*.sh` with `set -euo pipefail`; both `GITHUB_WORKSPACE` and local invocation work.

---

## 1. Workflow layout (files in `.github/workflows/`)

| Workflow file | Purpose | Blocks merge? | Triggers |
|---|---|---|---|
| `ci.yml` | Lint + test matrix + integration + installer-goldens | yes | `push: main`, `pull_request: main`, `workflow_dispatch`, `schedule: '0 6 * * *'` |
| `release-please.yml` | Cut release PRs + publish on merge | n/a | `push: main`, `workflow_dispatch` |
| `publish-hex.yml` | Manual recovery publish path | n/a | `workflow_dispatch` (inputs: `tag`, `release_version`, `package`) |
| `verify-published-release.yml` | Daily drift monitor | n/a | `schedule: '17 6 * * *'`, `workflow_dispatch` |
| `pr-title.yml` | Conventional-commit PR title lint | yes | `pull_request_target: [opened, edited, synchronize, reopened]` |
| `dependabot-automerge.yml` | Auto-merge patch-only Dependabot PRs | n/a | `pull_request` |
| `dependency-review.yml` | GitHub dep-review action | yes (PRs) | `pull_request` |
| `actionlint.yml` | `reviewdog` + `actionlint` on workflow changes | yes (workflow PRs) | `pull_request` with path filter on `.github/workflows/` |
| `playwright-github-pages.yml` | (deferred — after v0.5) Admin demo site | n/a | `schedule: '45 6 * * *'`, `push: main` (path-filtered), `workflow_dispatch` |

Every file opens with a **job-id contract comment**:

```yaml
# Job id contract — stable YAML `jobs:` keys relied on by docs, `act`, and branch protection:
#   lint, test, integration, installer_golden, release_gate
# `name:` strings evolve freely; `id:` strings are immutable without coordinated docs + branch-protection updates.
```

---

## 2. `ci.yml` — core gate

### 2.1 Triggers + concurrency + permissions

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
  schedule:
    - cron: '0 6 * * *'

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  actions: read
  checks: read
```

Path-ignore filter on the PR trigger (lattice_stripe pattern — keeps docs-only PRs from consuming CI minutes):

```yaml
on:
  pull_request:
    branches: [main]
    paths-ignore:
      - '.planning/**'
      - 'prompts/**'
      - '**.md'
      - 'docs/**'
```

CI still runs on `push: main` regardless of paths so the required-checks gate never goes green on a stale commit.

### 2.2 Job graph

```
lint ──┐
       ├── installer_path_gate ─── installer_golden ──┐
test ──┤                                              ├── release_gate
       └─── integration ──────────────────────────────┘
```

- `lint` — format / compile-warnings-as-errors / credo / docs / hex.audit / no-optional-deps-compile. ~3 min.
- `test` — matrix: `{elixir: [1.17, 1.19], otp: [26, 28]}`. Postgres 15 service container. `mix test --warnings-as-errors` with coverage. ~6 min per cell.
- `integration` — installer smoke + host-app HTTP smoke against `test/example/`. ~4 min.
- `installer_path_gate` — shell `git diff` sets output `run=true` only when installer surfaces change. On `main` push always runs.
- `installer_golden` — golden-diff fixture harness (5-min timeout). Needs path gate.
- `release_gate` — aggregates required statuses; single required check for branch protection.

### 2.3 The `lint` job (canonical shape)

```yaml
lint:
  runs-on: ubuntu-24.04
  steps:
    - uses: actions/checkout@de0fac2e0d0e70329c96e8b4d3e4dc33e27e6e83  # v6.0.2
      with:
        fetch-depth: 0   # needed for release-parity git tag lookups
    - uses: erlef/setup-beam@v1
      with:
        version-file: .tool-versions
        version-type: strict
    - name: Cache deps
      uses: actions/cache@v4
      with:
        path: |
          deps
          _build/test
        key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}-${{ hashFiles('.tool-versions') }}
        restore-keys: |
          ${{ runner.os }}-mix-
    - run: mix deps.get
    - run: mix format --check-formatted
    - run: mix compile --warnings-as-errors
    - run: mix compile --no-optional-deps --warnings-as-errors
    - run: mix credo --strict
    - run: mix docs --warnings-as-errors
    - run: mix hex.audit
```

### 2.4 The `test` matrix

```yaml
test:
  runs-on: ubuntu-24.04
  strategy:
    fail-fast: false
    matrix:
      include:
        - elixir: "1.17.3"
          otp: "26.2.5"
          support: required
        - elixir: "1.19.2"
          otp: "28.1.2"
          support: required
  services:
    postgres:
      image: postgres:15-alpine
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: rulestead_test
      ports: ['5432:5432']
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
  env:
    PGUSER: postgres
    PGPASSWORD: postgres
    PGHOST: localhost
    MIX_ENV: test
  steps:
    - uses: actions/checkout@de0fac2e0d0e70329c96e8b4d3e4dc33e27e6e83  # v6.0.2
    - uses: erlef/setup-beam@v1
      with:
        elixir-version: ${{ matrix.elixir }}
        otp-version: ${{ matrix.otp }}
    - name: Cache deps
      uses: actions/cache@v4
      with:
        path: |
          deps
          _build/test
        key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-mix-${{ hashFiles('**/mix.lock') }}
    - name: Restore dialyzer PLT
      uses: actions/cache/restore@v4
      with:
        path: priv/plts
        key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-plt-${{ hashFiles('**/mix.lock') }}
    - run: mix deps.get
    - run: mix ecto.create
    - run: mix ecto.migrate
    - run: mix test --warnings-as-errors
    - run: mix dialyzer --format github
    - name: Save dialyzer PLT
      if: always()
      uses: actions/cache/save@v4
      with:
        path: priv/plts
        key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-plt-${{ hashFiles('**/mix.lock') }}
```

The **restore → build-if-miss → save** PLT recipe (accrue pattern) means PLT cache survives unrelated job failures.

### 2.5 The `installer_golden` job

Path-gated by a preceding `installer_path_gate` job:

```yaml
installer_path_gate:
  runs-on: ubuntu-24.04
  outputs:
    run: ${{ steps.check.outputs.run }}
  steps:
    - uses: actions/checkout@...
      with: { fetch-depth: 0 }
    - id: check
      run: |
        set -euo pipefail
        if [[ "${{ github.event_name }}" != "pull_request" ]]; then
          echo "run=true" >> "$GITHUB_OUTPUT"; exit 0
        fi
        BASE="${{ github.event.pull_request.base.sha }}"
        HEAD="${{ github.event.pull_request.head.sha }}"
        if git diff --name-only "$BASE...$HEAD" \
            | grep -qE '^priv/templates/rulestead\.install/|^lib/rulestead/install/|^lib/mix/tasks/rulestead\.install\.ex$'; then
          echo "run=true" >> "$GITHUB_OUTPUT"
        else
          echo "run=false" >> "$GITHUB_OUTPUT"
        fi

installer_golden:
  needs: installer_path_gate
  if: needs.installer_path_gate.outputs.run == 'true'
  runs-on: ubuntu-24.04
  timeout-minutes: 10
  services: { postgres: ... }
  steps:
    - uses: actions/checkout@...
    - uses: erlef/setup-beam@v1
      with: { version-file: .tool-versions, version-type: strict }
    - run: mix deps.get
    - run: mix test test/rulestead/install/golden_diff_test.exs --include golden
```

### 2.6 The `integration` job

Host-app smoke + installer smoke over `test/example/` (sigra pattern). See `rulestead-testing-and-e2e-strategy.md` §integration for the full spec.

### 2.7 The `release_gate` job

Aggregates required statuses into a single required check (accrue pattern):

```yaml
release_gate:
  needs: [lint, test, integration, installer_path_gate]
  if: always()
  runs-on: ubuntu-24.04
  steps:
    - run: |
        # Fail if any required job failed or was cancelled.
        if [[ "${{ needs.lint.result }}" != "success" ]]; then echo "lint failed"; exit 1; fi
        if [[ "${{ needs.test.result }}" != "success" ]]; then echo "test failed"; exit 1; fi
        if [[ "${{ needs.integration.result }}" != "success" ]]; then echo "integration failed"; exit 1; fi
        if [[ "${{ needs.installer_path_gate.result }}" != "success" ]]; then echo "installer path gate failed"; exit 1; fi
```

Branch protection requires only `release_gate`. Lane renames inside the workflow don't ripple to repo settings.

---

## 3. `release-please.yml`

Single-package v0.x shape (sigra-style):

```yaml
name: release-please
on:
  push:
    branches: [main]
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
    runs-on: ubuntu-24.04
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
      version: ${{ steps.release.outputs.version }}
    steps:
      - uses: googleapis/release-please-action@v4
        id: release
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}
          release-type: elixir
          package-name: rulestead
          bump-minor-pre-major: true
          bump-patch-for-minor-pre-major: true

  publish-hex:
    needs: release-please
    if: needs.release-please.outputs.release_created == 'true'
    runs-on: ubuntu-24.04
    services: { postgres: ... }
    env:
      HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
    steps:
      - uses: actions/checkout@...
        with: { ref: ${{ needs.release-please.outputs.tag_name }}, fetch-depth: 0 }
      - uses: erlef/setup-beam@v1
        with: { version-file: .tool-versions, version-type: strict }
      - run: |
          VERSION="${{ needs.release-please.outputs.version }}"
          set -euo pipefail
          grep -n "@version \"${VERSION}\"" mix.exs  # hard-fail if mismatched
      - run: mix deps.get
      - run: mix test
      - run: mix hex.publish --dry-run
      - run: mix hex.publish --yes
      - name: Post-publish verify
        run: |
          mix verify.release_publish "${{ needs.release-please.outputs.version }}"
          mix verify.release_parity "${{ needs.release-please.outputs.version }}"
        env:
          RULESTEAD_RELEASE_VERIFY_ATTEMPTS: "10"
          RULESTEAD_RELEASE_VERIFY_SLEEP_MS: "15000"
```

### 3.1 `release-please-config.json` (single-package v0.x)

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bump-minor-pre-major": true,
  "bump-patch-for-minor-pre-major": true,
  "include-v-in-tag": true,
  "packages": {
    ".": {
      "package-name": "rulestead",
      "changelog-path": "CHANGELOG.md"
    }
  }
}
```

### 3.2 Multi-package upgrade path (when `rulestead_admin` is split)

Switch to linked-versions (accrue pattern):

```json
{
  "separate-pull-requests": false,
  "include-component-in-tag": true,
  "plugins": [
    {"type": "linked-versions", "groupName": "rulestead-monorepo",
     "components": ["rulestead", "rulestead_admin"]}
  ],
  "packages": {
    "rulestead":       {"component":"rulestead",       "release-type":"elixir", "package-name":"rulestead",       "changelog-path":"rulestead/CHANGELOG.md",       "include-component-in-tag":true},
    "rulestead_admin": {"component":"rulestead_admin", "release-type":"elixir", "package-name":"rulestead_admin", "changelog-path":"rulestead_admin/CHANGELOG.md", "include-component-in-tag":true}
  }
}
```

Tags become `rulestead-v0.3.1` and `rulestead_admin-v0.3.1`. The **lockstep-fallback bash block** (re-emits admin release_created when both manifest versions match) is load-bearing here — copy accrue's `release-please.yml` verbatim when making the switch.

### 3.3 Sibling admin `mix.exs` env-swap (when applicable)

```elixir
defp accrue_dep do
  if System.get_env("RULESTEAD_ADMIN_HEX_RELEASE") == "1" do
    {:rulestead, "~> #{@version}"}
  else
    {:rulestead, path: "../rulestead"}
  end
end
```

CI sets `RULESTEAD_ADMIN_HEX_RELEASE: "1"` only in the admin publish job. All dev/CI/test paths use the path dep.

---

## 4. `publish-hex.yml` — manual recovery

`workflow_dispatch` only. Same gate chain as release-please, keyed to an explicit tag input. For the day Release Please breaks.

```yaml
name: publish-hex
on:
  workflow_dispatch:
    inputs:
      tag:
        required: true
        description: "Git tag to publish from (e.g. v0.3.1)"
      release_version:
        required: true
        description: "Version number (e.g. 0.3.1) — must match @version in mix.exs"

permissions:
  contents: read

jobs:
  publish:
    runs-on: ubuntu-24.04
    services: { postgres: ... }
    env:
      HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
    steps:
      - uses: actions/checkout@...
        with: { ref: ${{ inputs.tag }}, fetch-depth: 0 }
      - uses: erlef/setup-beam@v1
        with: { version-file: .tool-versions, version-type: strict }
      - name: Verify version matches tag
        run: grep -n "@version \"${{ inputs.release_version }}\"" mix.exs
      - run: mix deps.get
      - run: mix verify.workspace_clean
      - run: mix test
      - run: mix hex.publish --dry-run
      - run: mix hex.publish --yes
      - name: Post-publish verify
        run: |
          mix verify.release_publish "${{ inputs.release_version }}"
          mix verify.release_parity "${{ inputs.release_version }}"
```

---

## 5. `verify-published-release.yml` — daily drift monitor

The scrypath signature move. A `200` from Hex is not enough — a fresh consumer app must actually compile against the tarball, and HexDocs must resolve for the exact version.

```yaml
name: verify-published-release
on:
  schedule:
    - cron: '17 6 * * *'
  workflow_dispatch:

permissions:
  contents: read
  issues: write

jobs:
  verify:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@...
        with: { fetch-depth: 0 }
      - name: Resolve latest published version
        id: resolve
        run: |
          set -euo pipefail
          RESPONSE=$(curl -sfSL "https://hex.pm/api/packages/rulestead" || echo "")
          if [[ -z "$RESPONSE" ]]; then
            echo "published=false" >> "$GITHUB_OUTPUT"
            echo "Rulestead is not yet published on Hex — skipping." >> "$GITHUB_STEP_SUMMARY"
            exit 0
          fi
          VERSION=$(echo "$RESPONSE" | jq -r '.latest_stable_version')
          echo "published=true" >> "$GITHUB_OUTPUT"
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
      - if: steps.resolve.outputs.published == 'true'
        uses: erlef/setup-beam@v1
        with: { version-file: .tool-versions, version-type: strict }
      - if: steps.resolve.outputs.published == 'true'
        run: mix deps.get
      - id: verify
        if: steps.resolve.outputs.published == 'true'
        continue-on-error: true
        run: |
          set -euo pipefail
          mix verify.release_publish "${{ steps.resolve.outputs.version }}"
          mix verify.release_parity "${{ steps.resolve.outputs.version }}"
        env:
          RULESTEAD_RELEASE_VERIFY_ATTEMPTS: "10"
          RULESTEAD_RELEASE_VERIFY_SLEEP_MS: "15000"
      - if: steps.verify.outcome == 'failure'
        uses: JasonEtco/create-an-issue@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          VERSION: ${{ steps.resolve.outputs.version }}
        with:
          filename: .github/ISSUE_TEMPLATE/release-parity-drift.md
          update_existing: true
          search_existing: open
```

### 5.1 Issue template: `.github/ISSUE_TEMPLATE/release-parity-drift.md`

```markdown
---
title: "Release parity drift: rulestead v{{ env.VERSION }}"
labels: ["area:release", "severity:drift"]
assignees: ["szTheory"]
---

The daily `verify-published-release` workflow detected drift between the git tag and the Hex tarball for version **{{ env.VERSION }}**.

See the workflow run: https://github.com/{{ env.GITHUB_REPOSITORY }}/actions/runs/{{ env.GITHUB_RUN_ID }}

- If this is drift: decide whether to re-publish, retire, or forward-ship.
- If this is a false alarm (empty unpack, HexDocs cold cache), close this issue and the next cron run will reopen only if the problem persists.
- Template reference: `.planning/milestones/v0.10-MILESTONE-AUDIT.md` "Trust spine"
```

---

## 6. `pr-title.yml` — conventional-commit enforcement

Fails PR if squash-merge title won't parse as Conventional Commits. Critical input to release-please.

```yaml
name: pr-title
on:
  pull_request_target:
    types: [opened, edited, synchronize, reopened]

permissions:
  pull-requests: read

jobs:
  lint:
    runs-on: ubuntu-24.04
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          types: |
            feat
            fix
            perf
            deps
            docs
            test
            refactor
            build
            ci
            chore
            style
          requireScope: false
          subjectPattern: '^(?![A-Z]).+$'
          wip: true
```

---

## 7. `dependabot-automerge.yml` — patch-only auto-merge

```yaml
name: dependabot-automerge
on: pull_request

permissions:
  pull-requests: write
  contents: write

jobs:
  auto-merge:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-24.04
    steps:
      - id: metadata
        uses: dependabot/fetch-metadata@v2
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
      - if: steps.metadata.outputs.update-type == 'version-update:semver-patch'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Minor + major still require human review.

---

## 8. `dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: "mix"
    directory: "/"
    schedule: { interval: "weekly" }
    open-pull-requests-limit: 5
    groups:
      patch-updates:
        update-types: ["patch"]
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly" }
  - package-ecosystem: "npm"
    directory: "/rulestead_admin/assets"
    schedule: { interval: "weekly" }
  - package-ecosystem: "npm"
    directory: "/test/example/priv/playwright"
    schedule: { interval: "weekly" }
```

---

## 9. Post-publish verify tasks (library code)

Port scrypath's three Mix tasks. Full API + internals documented in their source:

- `lib/mix/tasks/verify.workspace_clean.ex` — `git status --porcelain` scoped to `package.files ++ ["test"]`. No escape-hatch flag. Pure `classify/3`. `raise`s on dirty.
- `lib/mix/tasks/verify.release_publish.ex` — polls Hex for tarball visibility (retry 10×15s), creates fresh `mix new rulestead_consumer`, rewrites consumer `mix.exs` to depend on the just-published Hex version, compiles, checks `https://hexdocs.pm/rulestead/<version>` is reachable with `curl -IfsS`.
- `lib/mix/tasks/verify.release_parity.ex` — diffs `lib/` + `guides/` + `docs/` between git tag `v<version>` and Hex tarball. **Three exit codes**: `0 = parity`, `2 = drift (POSIX)`, `1 = runtime error`. Pure `compute/2` split for ExUnit testability. Retry reducer `retry_until!/4` public for test reuse.

Shared retry env vars:

- `RULESTEAD_RELEASE_VERIFY_ATTEMPTS` (default 10)
- `RULESTEAD_RELEASE_VERIFY_SLEEP_MS` (default 15000)

Security gate: version arg validated against `~r/^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$/` before hitting subprocesses (`git ls-tree`, `hex.package fetch`).

---

## 10. `mix.exs` release-relevant fragments

```elixir
defmodule Rulestead.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/<org>/rulestead"
  @hexdocs_url "https://hexdocs.pm/rulestead"
  @release_docs_url "#{@hexdocs_url}/#{@version}"

  def project do
    [
      app: :rulestead,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [
        warnings_as_errors: true,
        no_warn_undefined: no_warn_undefined()
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      cli: [preferred_envs: preferred_envs()],
      package: package(),
      docs: docs(),
      dialyzer: dialyzer(),
      description: "Elixir-native feature flags, experimentation, and remote config with a mountable Phoenix LiveView admin.",
      source_url: @source_url,
      homepage_url: @source_url,
      test_load_filters: test_load_filters(),
      test_ignore_filters: test_ignore_filters()
    ]
  end

  defp package do
    [
      maintainers: ["Jon"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => @hexdocs_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Guides" => "#{@release_docs_url}/readme.html"
      },
      # EXPLICIT whitelist — never auto-include.
      # Must never contain: test/example/, prompts/, .planning/, rulestead_admin/ (separate package), scripts/
      files: ~w(lib priv/templates priv/repo/migrations guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md CONVENTIONS.md SECURITY.md)
    ]
  end

  defp docs do
    [
      main: "getting-started",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: groups_for_modules(),
      skip_undefined_reference_warnings_on: &String.starts_with?(&1, "lib/")
    ]
  end

  defp aliases do
    [
      "ci.all": ["format --check-formatted", "compile --warnings-as-errors", "credo --strict",
                 "test --warnings-as-errors", "docs --warnings-as-errors", "hex.audit"],
      "verify.phase01": ["test test/rulestead/eval/core_test.exs"],
      "verify.phase02": ["test test/rulestead/eval/snapshot_test.exs"],
      # ... one per phase
      "test.all": ["test --include integration --include golden"]
    ]
  end

  defp preferred_envs do
    [
      "ci.all": :test,
      "verify.workspace_clean": :test,
      "verify.release_publish": :test,
      "verify.release_parity": :test,
      "verify.phase01": :test,
      # ... every verify.* task registered here
      credo: :test,
      dialyzer: :test
    ]
  end

  defp dialyzer do
    [
      plt_local_path: "priv/plts",
      plt_add_apps: [:ex_unit, :mix, :eex, :iex],
      flags: [:error_handling, :extra_return, :missing_return, :underspecs]
    ]
  end

  defp no_warn_undefined do
    # Optional deps — listed so `mix compile --warnings-as-errors` stays green downstream.
    [Oban, Oban.Worker, OpenTelemetry, Sigra.Admin.Policy, Mailglass, Accrue, Phoenix.LiveView]
  end
end
```

---

## 11. Caching strategy

| Cache | Key | Paths |
|---|---|---|
| Mix deps/build | `${runner.os}-${otp}-${elixir}-mix-${hashFiles('**/mix.lock')}` | `deps/`, `_build/test/` |
| Dialyzer PLT | `${runner.os}-${otp}-${elixir}-plt-${hashFiles('**/mix.lock')}` | `priv/plts/` (restore → build-if-miss → save) |
| Hex registry | default | `~/.hex` |
| Node npm (Playwright) | `${runner.os}-node-${hashFiles('test/example/priv/playwright/package-lock.json')}` | `~/.npm`, `test/example/priv/playwright/node_modules/` |

**Never include** `.planning/`, `prompts/`, or `guides/` in cache keys — they change for reasons unrelated to build reproducibility.

---

## 12. Secrets posture

| Secret | Used in | Never in |
|---|---|---|
| `HEX_API_KEY` | publish-hex, release-please (publish step only) | ci.yml, any lint/test step |
| `RELEASE_PLEASE_TOKEN` | release-please (release-please job only) | anywhere else |
| `GITHUB_TOKEN` (default) | default for most auth-free ops | n/a |

Enforcement: all SHA-pinned third-party actions + Dependabot-updated; never echo secrets; workflow-level `permissions:` default to read-only; jobs opt in to elevated perms.

---

## 13. Branch protection (required checks)

Branch protection for `main` requires:

- `release_gate` (aggregated in `ci.yml`)
- `pr-title`
- `dependency-review` (PRs only, automatic pass on branches without runnable changes)
- Linear history enforced
- Require PR with ≥1 approving review (can be relaxed for solo-maintainer + Dependabot patch-only auto-merge works through `--auto`)
- Require signed commits (optional v1.0 upgrade — rulestead v0.x can skip)

Verbatim checklist appears in `MAINTAINING.md`.

---

## 14. `scripts/ci/*.sh` inventory (day-1 shape)

- `install-smoke.sh` — run `mix rulestead.install` against a fresh phx.new skeleton, grep stdout for success markers.
- `install-matrix-local.sh` — installer flag combinations (`--no-admin`, `--no-oban`, defaults) locally for maintainer pre-PR check.
- `installer-milestone-audit.sh` — diff current installer output against `.planning/milestones/v*-installer-evidence/`.
- `verify-release-publish.sh` — thin wrapper calling `mix verify.release_publish` with default env vars.
- `verify-release-parity.sh` — thin wrapper calling `mix verify.release_parity`.
- `admin-artifact-bundle-contract.sh` — asserts `rulestead_admin/priv/static/*.{css,js}` exist + minimum size before publish.
- `admin-acceptance-smoke.sh` — boots `test/example/`, visits /flags, asserts 200.
- `assemble-playwright-gh-pages-site.sh` — (deferred) assembles runs/ dir.
- `ensure-github-pages-legacy-branch.sh` — (deferred) flips Pages site via REST API.

All scripts:
- `set -euo pipefail`
- `RULESTEAD_REPO="${GITHUB_WORKSPACE:-$(pwd)}"` preamble
- Exit codes: `0` success, `1` error, `2` "known drift" (for verify-* scripts)

---

## 15. Pre-1.0 semver policy (sigra codified this)

- Any new **supported public `lib/` module** → minor bump.
- Any **new `@doc`-annotated function on an existing public module** → minor bump.
- Doc-only / internal `@moduledoc false` / test changes → patch bump.
- **Pre-1.0 breaking changes are allowed in minor bumps.** This rule ends at v1.0 — after which semver is strict.

Committed in `guides/api_stability.md` alongside the public-surface enumeration.

---

## 16. Anti-patterns — don't

- Don't run `mix hex.publish` locally on a whim. Always via release-please or `publish-hex.yml`.
- Don't auto-merge Dependabot minors/majors. Patch-only.
- Don't omit `fetch-depth: 0` on publish jobs — release-parity needs the tag history.
- Don't let `.tool-versions` drift from `mix.exs` supported range.
- Don't put domain-specific gates in `release_gate` — keep it thin; add dedicated jobs instead.
- Don't rely on workflow `name:` strings for branch-protection. Pin to `name:` field of the job, documented verbatim in `MAINTAINING.md`.
- Don't commit `release-please-manifest.json` edits by hand (except for bootstrap) — let the bot own it.
- Don't skip dry-run before publish. Dry-run cost is 30s; real-publish mistakes cost days.
- Don't `mix hex.revert` without first trying to ship forward. Reverts burn trust.
- Don't add a workflow without the job-id contract comment.

---

## 17. Mental model (one paragraph)

CI is for correctness and library hygiene. Release Please is the release brain. Hex is the package/docs publisher. ExDoc is both the user docs surface and the LLM-facing docs layer. The post-publish verify trio is the trust heartbeat — it runs on every publish and daily forever. GitHub security features (SHA-pinned actions, Dependabot, dependency-review) keep the automation safe. Conventional squash-merge titles keep contributor workflow friendly without burdening them with commit-message discipline. Every one of these pieces is already shipped in a prior lib; rulestead's job is to compose them correctly from day one.
