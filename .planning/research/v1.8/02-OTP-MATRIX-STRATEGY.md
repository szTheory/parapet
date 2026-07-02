# Elixir/OTP Matrix Strategy (v1.8)

**Dimension:** CI matrix reshape — OTP version set, schema-prefix composition, trigger design
**Milestone:** v1.8 CI/CD Performance & DX
**Researched:** 2026-07-02
**Overall confidence:** MEDIUM (version facts verified against hexdocs + endoflife.date; GitHub Actions patterns verified against official docs + community sources)

---

## Current matrix (as-is + D-11 unevenness)

From `.github/workflows/ci.yml` (read verbatim):

| Job | Elixir | OTP cells | schema_prefix cells | Total cells | Notes |
|-----|--------|-----------|---------------------|-------------|-------|
| `lint` | 1.19.0 | 26.x, 27.x, 28.x | n/a | **3** | OTP-independent steps run 3× (wasteful) |
| `test` | 1.19.0 | 26.x, 27.x, 28.x (base) + 28.x (include) | `parapet` (base) + `public` (include) | **4** | 3 parapet cells + 1 public cell |
| `demo` | 1.19.0 | 26.x, 27.x, 28.x | n/a | **3** | Full OTP sweep on demo smoke |
| `release_gate` | — | — | — | 1 | Aggregate; `needs: [lint, test, demo]` |

**D-11 unevenness (accepted v1.7 tech-debt):** The `public` prefix leg runs only on OTP 28.x via an `include:` entry. The `parapet` prefix leg runs on all three OTP versions. This means OTP 26 and OTP 27 coverage of the `public`/unprefixed schema leg is **absent** — a known false-confidence gap. Any bug exclusive to `public`-prefix behavior on OTP 26/27 goes undetected.

**Additional structural problems:**
- `lint` is OTP-independent (format, credo, dialyzer, verify.public_api are deterministic given one compiler). Running it 3× multiplies cost with zero information gain.
- The `demo` job runs a full 3-OTP sweep on every PR even though most PRs don't touch demo-app code.
- No `concurrency: cancel-in-progress` on PR runs — superseded runs continue burning minutes.
- Total PR cell count: 10 (3 lint + 4 test + 3 demo). For PRs this is entirely disproportionate.

---

## Recommended version set

### The OTP lifecycle (verified via endoflife.date + erlang.org, 2026-07-02)

| OTP Version | Released | Active Support Ends | Security Support Ends | Status (2026-07-02) |
|-------------|----------|--------------------|-----------------------|---------------------|
| OTP 26 | May 2023 | May 2024 | **May 26, 2026** | **EOL — just crossed** |
| OTP 27 | May 2024 | May 2025 | May 2027 | Security-only |
| OTP 28 | May 2025 | **May 2026** | May 2028 | Security-only |
| OTP 29 | May 2026 | May 2029 | May 2029 | Active (latest) |

### The Elixir compatibility matrix (verified via hexdocs.pm/elixir/compatibility-and-deprecations.html)

| Elixir | Supported OTP Range | Released | Support tier |
|--------|---------------------|----------|--------------|
| 1.20.x | 27 – 29 | June 2026 | Bug + security fixes |
| 1.19.x | 26 – 28 | October 2025 | Security patches only |
| 1.18.x | 25 – 27 | — | Security patches only |

**Current `mix.exs` floor:** `elixir: "~> 1.19"` — matches Elixir 1.19+.

**Current CI Elixir pin:** `1.19.0` — one minor release behind the stable 1.20.2.

### The recommended version triple for v1.8

| Role | OTP | Rationale |
|------|-----|-----------|
| **Oldest supported** | **OTP 27** | OTP 26 crossed EOL on May 26, 2026 — 37 days before this research. Retaining OTP 26 in CI signals support for an EOL runtime to adopters. Drop it. OTP 27 is the new floor: security support until May 2027, still widely deployed by Elixir 1.19 adopters. |
| **Mainstream** | **OTP 28** | Released May 2025, broadly deployed. Security support until 2028. The version most production Elixir 1.19/1.20 installations are on. |
| **Latest** | **OTP 29** | Released May 2026 (7 weeks ago as of research date). Active support until 2029. Forward-compatibility signal to adopters. |

**Elixir version recommendation:** upgrade CI pin from `1.19.0` to `1.20.x` (latest patch, currently `1.20.2`). Rationale:
- Elixir 1.20 requires OTP 27+ — aligns exactly with the OTP floor drop.
- Elixir 1.19 no longer receives bug fixes (security patches only). Testing against it gives less signal per minute of CI spend.
- `mix.exs` already says `~> 1.19`, which allows 1.20 without a version bump.
- Adopters on Elixir 1.19 with OTP 26 are now running an EOL runtime stack; the library is not obliged to CI-prove that combination.

**If dropping OTP 26 feels premature**, the conservative alternative is to keep OTP 26 for one more milestone and drop it in v1.9. The cost is one extra cell that produces no new signal (all three prefix legs have already been exercised on OTP 26 throughout v1.7). This document recommends the drop, but the planner can hold for v1.9 if the team prefers a softer transition.

### Compatibility verification summary

With Elixir 1.20 + OTP {27, 28, 29}:
- All three OTP versions are in the official Elixir 1.20 support window (27-29). ✓
- All three OTP versions have active or security-level support from Erlang/OTP. ✓
- OTP 27 is the floor, capturing the adopter cohort on the previous-stable OTP. ✓
- OTP 29 is the ceiling, signaling forward readiness. ✓

---

## Matrix composition: OTP × schema-prefix

### The explosion problem

A naive full expansion of {27, 28, 29} × {parapet, public} = **6 test cells per trigger**, plus lint (1) + demo (3) = **10 cells total on every trigger**. That's the same count as today and defeats the v1.8 "trimmed PR breadth" goal.

### The composition principle

The `public`/`parapet` prefix split exists to prove a compile-time constant — it is OTP-independent by construction. If the test suite passes under `parapet` prefix on OTP 27/28/29, it proves the Ecto/Postgres behavior is correct. Whether `public` leg also exercises OTP 27 vs 28 vs 29 adds nothing: the prefix affects schema-qualification in SQL, not OTP runtime behavior.

**Therefore: the prefix axis and the OTP axis are independent and need not be fully crossed.**

### Recommended composition strategy

| Leg | OTP | schema_prefix | Trigger | Purpose |
|-----|-----|---------------|---------|---------|
| **PR representative cell** | 28 | parapet | PR | Single fast cell; proves the main path compiles and tests pass |
| **OTP floor** | 27 | parapet | main + nightly | Prove OTP 27 adopters not broken |
| **OTP ceiling** | 29 | parapet | main + nightly | Forward compatibility |
| **Public prefix** | 28 | public | main + nightly | Prove the D-11 OTP-uneven gap is closed |

This gives:
- **PR:** 1 test cell (+ 1 lint cell + 1 demo cell = 3 total, vs today's 10)
- **main push / nightly:** 4 test cells (OTP 27+parapet, OTP 28+parapet, OTP 29+parapet, OTP 28+public)

### Why OTP 28 for the `public` cell

- OTP 28 is the mainstream production version.
- The `public` prefix leg tests SQL without schema qualification; OTP version is irrelevant to whether `CREATE TABLE parapet_incidents` vs `"parapet"."parapet_incidents"` is emitted.
- Running public prefix on one OTP version is sufficient — D-11 accepted it on OTP 28 and it remains sound.

### Retiring D-11 unevenness

The D-11 decision was: "OTP 26/27 coverage only under the `parapet` leg; `public` leg OTP 28 only." With the OTP 26 drop and the move to main+nightly-only full matrix:

- The `parapet` leg now covers OTP 27/28/29 on main+nightly.
- The `public` leg covers OTP 28 on main+nightly.
- **D-11 is effectively retired by the new design**: the structural reason for D-11 was to keep PR cost down. Now that the full matrix only runs on main+nightly, the original cost concern is gone, and we can afford OTP 27+28+29 on the `parapet` leg without penalty.
- The remaining asymmetry (parapet × 3 OTP vs public × 1 OTP) is intentional and justified: prefix correctness is compile-time and OTP-independent; the extra coverage adds no signal.

**Explicit clean retirement:** remove the `D-11` tech-debt flag from the audit register and replace the accepted-prune note with: "Public prefix leg is pinned to OTP 28 by design; the OTP dimension and prefix dimension are independent — additional OTP cells for the public leg are non-additive."

---

## PR vs main vs nightly trigger design

### Design goals

1. PRs: fast feedback. One representative cell. Prove "not obviously broken."
2. main push: full 4-cell test matrix. Prove release readiness across OTP range + both prefix legs.
3. Nightly schedule: same as main push. Provide early warning of OTP regression before a contributor files a PR.
4. `release_gate` must be a stable, always-present required check. Branch protection cannot reference a job that sometimes doesn't exist.

### The `release_gate` stability problem

Branch protection rules in GitHub reference a job *name*. If that job is absent from a workflow run, branch protection treats it as "not yet passed" (pending) or "missing" — which is either a block or a bypass, depending on repo settings. This means:

- `release_gate` must appear in **every** workflow run.
- If the full matrix only runs on main+nightly, the PR run must still have a `release_gate` job.
- The PR `release_gate` must succeed based only on the PR-scoped cells.

### Recommended YAML design

**Pattern: single workflow file, event-conditional matrix via `fromJSON` in a setup job.**

This is the most maintainable pattern. One file, one place to edit, clear data flow.

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: '0 3 * * *'   # nightly at 03:00 UTC

concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

jobs:
  # ── Matrix resolver ─────────────────────────────────────────────────────────
  # Emits the test matrix JSON based on trigger.
  # PR: single representative cell. main/nightly: full 4-cell matrix.
  matrix-config:
    runs-on: ubuntu-latest
    outputs:
      test-matrix: ${{ steps.resolve.outputs.matrix }}
    steps:
      - id: resolve
        run: |
          if [[ "${{ github.event_name }}" == "pull_request" ]]; then
            # Single representative cell: mainstream OTP, default prefix
            echo 'matrix={"include":[{"otp":"28.x","schema_prefix":"parapet"}]}' >> "$GITHUB_OUTPUT"
          else
            # Full matrix: 3 OTP × parapet + 1 OTP × public
            echo 'matrix={"include":[
              {"otp":"27.x","schema_prefix":"parapet"},
              {"otp":"28.x","schema_prefix":"parapet"},
              {"otp":"29.x","schema_prefix":"parapet"},
              {"otp":"28.x","schema_prefix":"public"}
            ]}' >> "$GITHUB_OUTPUT"
          fi

  # ── Lint (once, OTP-independent) ────────────────────────────────────────────
  lint:
    runs-on: ubuntu-latest
    env:
      MIX_ENV: test
    steps:
      - uses: actions/checkout@<SHA>
      - uses: erlef/setup-beam@<SHA>
        with:
          elixir-version: '1.20.2'
          otp-version: '28.x'
      - name: Cache deps
        uses: actions/cache@<SHA>
        with:
          path: deps
          key: ${{ runner.os }}-mix-1.20.2-28.x-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-mix-1.20.2-28.x-
      - name: Cache _build (lint)
        uses: actions/cache@<SHA>
        with:
          path: _build
          key: ${{ runner.os }}-build-lint-1.20.2-28.x-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-build-lint-1.20.2-28.x-
      - run: mix deps.get
      - run: mix format --check-formatted
      - run: mix compile --warnings-as-errors
      - run: mix compile --no-optional-deps --warnings-as-errors
      - name: Build Docs
        env:
          MIX_ENV: dev
        run: mix docs --warnings-as-errors
      - run: mix credo --strict
      - run: mix hex.audit
      - run: mix dialyzer
      - run: mix verify.public_api
      - name: Operator UI manifest drift
        run: |
          diff \
            <(bash examples/demo_app/scripts/capture_operator_ui_screenshots.sh --manifest) \
            <(sed -n '/^| name /,/^Total: /p' examples/demo_app/scripts/operator-ui-baseline.md)

  # ── Test (matrix-driven) ────────────────────────────────────────────────────
  test:
    needs: [matrix-config]
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix: ${{ fromJson(needs.matrix-config.outputs.test-matrix) }}
    env:
      MIX_ENV: test
      PARAPET_SCHEMA_PREFIX: ${{ matrix.schema_prefix }}
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: parapet_concurrency_test
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready --health-interval 10s
          --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@<SHA>
      - uses: erlef/setup-beam@<SHA>
        with:
          elixir-version: '1.20.2'
          otp-version: ${{ matrix.otp }}
      - name: Cache deps
        uses: actions/cache@<SHA>
        with:
          path: deps
          key: ${{ runner.os }}-mix-1.20.2-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-mix-1.20.2-${{ matrix.otp }}-
      # CRITICAL: cache key must include schema_prefix or the two prefix legs
      # poison each other (compile_env is baked at compile time — reusing a
      # cached _build from the other prefix is a silent false-green).
      - name: Cache _build
        uses: actions/cache@<SHA>
        with:
          path: _build
          key: ${{ runner.os }}-build-1.20.2-${{ matrix.otp }}-sp-${{ matrix.schema_prefix }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-build-1.20.2-${{ matrix.otp }}-sp-${{ matrix.schema_prefix }}-
      - run: mix deps.get
      # Belt-and-suspenders: force recompile so compile_env is re-baked with
      # the correct schema_prefix for this leg. Prevents stale-cache false-greens.
      - name: Compile (force for this prefix leg)
        run: mix compile --force
      - run: mix test

  # ── Demo smoke (PR: skip; main/nightly: OTP 28 only) ───────────────────────
  demo:
    needs: [lint, test]
    if: github.event_name != 'pull_request'
    runs-on: ubuntu-latest
    env:
      MIX_ENV: test
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: demo_app_test
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready --health-interval 10s
          --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@<SHA>
      - uses: erlef/setup-beam@<SHA>
        with:
          elixir-version: '1.20.2'
          otp-version: '28.x'
      - name: Cache demo deps
        uses: actions/cache@<SHA>
        with:
          path: examples/demo_app/deps
          key: ${{ runner.os }}-demo-mix-1.20.2-28.x-${{ hashFiles('examples/demo_app/mix.lock') }}
          restore-keys: ${{ runner.os }}-demo-mix-1.20.2-28.x-
      - name: Cache demo _build
        uses: actions/cache@<SHA>
        with:
          path: examples/demo_app/_build
          key: ${{ runner.os }}-demo-build-1.20.2-28.x-${{ hashFiles('examples/demo_app/mix.lock') }}
          restore-keys: ${{ runner.os }}-demo-build-1.20.2-28.x-
      - run: cd examples/demo_app && mix deps.get
      - run: cd examples/demo_app && mix compile --no-optional-deps --warnings-as-errors
      - run: cd examples/demo_app && mix ecto.create && mix ecto.migrate
      - run: cd examples/demo_app && mix run priv/repo/seeds.exs
      - run: cd examples/demo_app && mix test --only smoke

  # ── Release gate ─────────────────────────────────────────────────────────────
  # Must always be present so branch protection has a stable check name.
  # On PR: gates on lint + test only (demo is skipped on PR).
  # On main/nightly: gates on lint + test + demo.
  release_gate:
    needs: [lint, test, demo]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Check all required jobs passed
        run: |
          lint_result="${{ needs.lint.result }}"
          test_result="${{ needs.test.result }}"
          demo_result="${{ needs.demo.result }}"
          # demo is skipped on PR — treat 'skipped' as passing for PRs
          if [[ "$lint_result" != "success" ]]; then
            echo "lint failed: $lint_result" && exit 1
          fi
          if [[ "$test_result" != "success" ]]; then
            echo "test failed: $test_result" && exit 1
          fi
          # demo is 'skipped' on PR runs (event_name == pull_request)
          # demo is 'success' or 'failure' on main/nightly
          if [[ "$demo_result" == "failure" ]]; then
            echo "demo failed" && exit 1
          fi
          echo "All required checks passed (demo=$demo_result)"
```

### Why `if: always()` on `release_gate`

Without `if: always()`, GitHub Actions skips downstream jobs when an upstream job is cancelled or skipped. `demo` is intentionally skipped on PRs via `if: github.event_name != 'pull_request'`. Without `always()`, `release_gate` would itself be skipped on PRs, making the required check appear as "not run" — which is treated as a blocking failure in branch protection.

The inline script pattern (check `needs.*.result` explicitly) is more reliable than chaining `needs:` transitively, because it lets you express "demo is optional on PR" without removing it from the `needs` list.

### The `demo` skip on PRs: rationale

Demo smoke exercises: `mix ecto.create`, `mix ecto.migrate`, `seeds.exs`, and `--only smoke` tests. These are all OTP-independent and prefix-independent (the demo app uses the default `parapet` prefix). Running them 3× per OTP on every PR is expensive for low signal. The smoke test is most valuable as a post-merge (main push) and nightly check — it proves the library still boots and seeds in a real host app context. Skipping on PRs is a conscious trade-off acceptable when `test` already validates correctness.

### Cell count comparison

| Trigger | Old total cells | New total cells | Reduction |
|---------|-----------------|-----------------|-----------|
| PR | 10 (3 lint + 4 test + 3 demo) | 3 (1 lint + 1 test + 1 matrix-config) | -70% |
| main push | 10 | 7 (1 lint + 4 test + 1 demo + 1 matrix-config) | -30% |
| nightly | N/A (no schedule trigger today) | 7 | new |

---

## Retiring D-11 unevenness

### The D-11 accepted decision (from v1.7 audit)

> "OTP 26/27 coverage only under the parapet prefix leg; public leg OTP 28 only — accepted as a cost-prune with known gap."

### What changes in v1.8

| Factor | v1.7 | v1.8 |
|--------|------|------|
| OTP 26 | In matrix (26, 27, 28) | **Dropped** (EOL May 2026) |
| PR matrix breadth | 4 test cells (3 parapet, 1 public) | 1 test cell (OTP 28 parapet) |
| Full matrix (main+nightly) | All test cells run every PR | OTP 27+28+29 parapet + OTP 28 public |
| The unevenness concern | public leg misses OTP 26/27 — gaps | moot: OTP 26 dropped; main+nightly runs full matrix, OTP choice for public leg is a design decision not a gap |

### Explicit retirement action items for the planner

1. Remove the D-11 tech-debt flag from `.planning/milestones/v1.7-MILESTONE-AUDIT.md` (or add a "retired in v1.8" annotation).
2. Update `PROJECT.md` Key Decisions: replace the D-11 accepted-prune row with "Public prefix leg pinned to OTP 28 (mainstream); OTP dimension and prefix dimension are independent — additional OTP cells for the public leg are non-additive by design."
3. Update the CI comment in `ci.yml` that explains the include structure — remove the note about D-11 accepted prune and replace with the new design rationale.
4. Verify the `PARAPET_SCHEMA_PREFIX` env var seam still works with Elixir 1.20 (no API changes in `Application.compile_env` between 1.19 and 1.20; confirmed safe).

### False-green risk from trimming — explicit treatment

**The false-green risk from reducing the PR matrix to 1 cell:** A bug that manifests only on OTP 27 or OTP 29 will not be caught by the PR cell (OTP 28 parapet). This is the trade-off. It is acceptable because:

1. The main-push and nightly runs cover the full matrix — any OTP-specific bug that lands on main will be caught within 24 hours maximum.
2. OTP compatibility bugs between patch versions of the same major are extremely rare in practice; they almost always appear at major version boundaries (25→26, 26→27, etc.).
3. The v1.7 dual-prefix compile-env footgun (false-green via cache poisoning) is more dangerous than the OTP-version gap. The cache-key discipline (`sp-${{ matrix.schema_prefix }}` in the `_build` key + `mix compile --force`) from v1.7 research remains in place and is the primary false-green guard.

**The false-green risk from the `public` prefix being OTP-28-only on full matrix:** Prefix behavior is compile-time and Postgres-layer — not OTP-dependent. There is no realistic scenario where `public` prefix passes on OTP 28 but fails on OTP 27 or 29 due to an OTP-specific difference. The risk is negligible and the design is correct.

**The remaining real false-green risk (unchanged from v1.7):** The cache-key discipline. Both prefix legs must have separate `_build` cache keys. The `mix compile --force` step is belt-and-suspenders. These must not be removed during any future CI refactor.

---

## Elixir version upgrade: 1.19.0 → 1.20.x

The current CI pin is `elixir: '1.19.0'`. Recommend bumping to `'1.20.2'` (or latest patch at implementation time).

**Why now:**
- Elixir 1.20 requires OTP 27+, which matches the new OTP floor exactly.
- Using 1.19 while testing OTP 27/28/29 is valid (1.19 supports 26-28), but OTP 29 is not in Elixir 1.19's official support window — testing 1.19 + OTP 29 would be untested territory.
- Elixir 1.20 is the current maintained release (bug + security fixes). Testing against 1.19 (security-only) gives less meaningful signal.
- `mix.exs` `elixir: "~> 1.19"` already allows 1.20 without a semver change.

**Impact on adopters:** Moving the CI pin to 1.20 does not change the `mix.exs` floor (`~> 1.19` remains). Adopters on 1.19 + OTP 26 are now running an EOL OTP stack; the library is not responsible for CI-proving EOL combinations, though it continues to accept them if they compile.

**If Elixir upgrade is out of scope for v1.8**, keep `1.19.x` (latest patch `1.19.5` as of research date) and accept that OTP 29 testing is outside 1.19's support window. The OTP-floor drop (26→27) is still a valid standalone action.

---

## Summary of recommendations

| Decision | Recommendation |
|----------|---------------|
| OTP floor | Drop OTP 26 (EOL May 2026). New floor: **OTP 27**. |
| OTP ceiling | Add **OTP 29** (released May 2026, active). |
| OTP set | {27, 28, 29} |
| Elixir pin | Upgrade from 1.19.0 to **1.20.2** (or latest 1.20.x patch). |
| PR matrix | 1 cell: OTP 28 + parapet prefix. |
| Full matrix (main+nightly) | 4 cells: OTP {27,28,29} × parapet + OTP 28 × public. |
| Demo on PR | Skip (`if: github.event_name != 'pull_request'`). |
| Lint | 1 cell (OTP 28, once). Remove the 3× OTP multiplication. |
| `release_gate` | `if: always()` + inline result-check script; gates PR on lint+test, main on lint+test+demo. |
| D-11 retirement | Retire the tech-debt flag; document the OTP/prefix independence principle. |
| Cache key discipline | Preserve `sp-${{ matrix.schema_prefix }}` in `_build` key + `mix compile --force` for all prefix-carrying legs. |
| `concurrency` | Add `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` at workflow level. |
| Schedule trigger | Add `schedule: cron: '0 3 * * *'` (nightly 03:00 UTC) to `on:`. |

---

## Sources

- [Compatibility and deprecations — Elixir v1.20.x](https://elixir.hexdocs.pm/compatibility-and-deprecations.html) — OTP compatibility table. (MEDIUM confidence, official docs)
- [Elixir v1.20.0 released — ElixirForum](https://elixirforum.com/t/elixir-v1-20-0-released/75566) — release date, OTP 27+ requirement. (MEDIUM confidence, cross-checked)
- [Erlang | endoflife.date](https://endoflife.date/erlang) — OTP lifecycle dates. (MEDIUM confidence, well-maintained community tracker)
- [Support, Compatibility, Deprecations — Erlang System Documentation v29.0.1](https://www.erlang.org/doc/system/misc.html) — official OTP support policy. (MEDIUM confidence)
- [GitHub Actions workflow syntax — GitHub Docs](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions) — `on:`, `strategy.matrix`, `if:`. (MEDIUM confidence, official docs)
- [Dynamic matrix in GitHub Actions — oneuptime blog](https://oneuptime.com/blog/post/2025-12-20-dynamic-matrix-github-actions/view) — fromJSON matrix pattern. (LOW confidence, community)
- [Parapet v1.7 Test Strategy research](../v1.7/04-TEST-STRATEGY.md) — D-11 context, compile_env footgun (F1), cache-key discipline. (HIGH confidence, project artifact)
- [Parapet v1.7 Synthesis](../v1.7/00-SYNTHESIS.md) — dual-prefix CI matrix design, compile_env mechanics. (HIGH confidence, project artifact)
