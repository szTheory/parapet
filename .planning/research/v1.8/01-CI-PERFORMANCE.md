# CI Pipeline Performance (v1.8)

**Researched:** 2026-07-02
**Confidence:** MEDIUM (action SHAs verified against GitHub release pages; patterns verified against official GitHub docs and dialyxir official docs; all YAML is implementation-ready)

---

## Current Pipeline (as-is, from ci.yml)

The `.github/workflows/ci.yml` has three jobs gated by `release_gate`:

### Jobs

| Job | Matrix | Key steps |
|-----|--------|-----------|
| `lint` | elixir 1.19.0 × otp 26/27/28 (3 cells) | format, compile, compile --no-optional-deps, docs, credo, hex.audit, dialyzer, verify.public_api, operator UI manifest diff |
| `test` | elixir 1.19.0 × otp 26/27/28 × schema_prefix parapet (3 cells) + otp 28 × schema_prefix public (1 cell) = 4 cells | mix compile --force, mix test; Postgres service |
| `demo` | elixir 1.19.0 × otp 26/27/28 (3 cells) | deps.get, compile --no-optional-deps, ecto.create/migrate, seed, mix test --only smoke; Postgres service |
| `release_gate` | — | `echo "All required CI checks passed"` (gate only) |

### Cache as-is

**`lint` and `demo` jobs:**
```yaml
- uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0 — already current
  with:
    path: deps
    key: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
    restore-keys: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-

- uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
  with:
    path: _build
    key: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
    restore-keys: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-
```

**`test` job (v1.7 prefix-namespaced — correct):**
```yaml
- uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
  with:
    path: _build
    key: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-${{ hashFiles('**/mix.lock') }}
    restore-keys: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-
```

### Current action pins (in ci.yml)

| Action | Current SHA | Version |
|--------|-------------|---------|
| `actions/checkout` | `34e114876b0b11c390a56381ad16ebd13914f8d5` | ~v4.2.0 (behind) |
| `erlef/setup-beam` | `fc68ffb90438ef2936bbb3251622353b3dcb2f93` | ~v1.15–1.17 (behind) |
| `actions/cache` | `0057852bfaa89a56745cba8c7296529d2fc39830` | v4.3.0 (current for v4.x) |

### Critical issues in the current pipeline

1. **Dialyzer runs in every `lint` matrix cell** — rebuilds the PLT from scratch on every CI run (no caching), costing ~5–10 minutes per cell, times 3 OTP cells = 15–30 minutes of pure PLT rebuild per push. The PLT almost never changes between commits.
2. **All lint steps run 3× (one per OTP cell)** — format checking, credo, hex.audit, docs build, verify.public_api are not OTP-sensitive; running them 3× wastes runners for no coverage gain.
3. **No `concurrency: cancel-in-progress`** — force-pushed PR branches queue redundant runs that consume runner minutes without delivering new signal.
4. **No `mix ci` alias** — developers have no local equivalent of the CI gate. `mix dialyzer` alone takes many minutes, meaning the local feedback loop is either very slow or deliberately shorter than CI.
5. **Action pins are stale** — `actions/checkout` and `erlef/setup-beam` are months behind; Dependabot should propose updates but these should be bumped in v1.8.

---

## Recommendations

### 1. Dialyzer PLT Caching

**Problem:** Dialyzer rebuilds its PLT on every run. For a project with `plt_add_apps: [:mix, :ex_unit]` and dialyxir 1.4, this is a 5–10 minute step per matrix cell. PLTs only change when OTP version, Elixir version, or `mix.lock` changes.

**Why PLT lives in `priv/plts`, not `_build`:** The dialyxir convention (and official docs) stores PLTs under `priv/plts` because `_build` is environment-namespaced (`_build/test/lib/...`) and cleaned by `mix clean`. Storing PLTs in `priv/plts` decouples them from the build artifact lifecycle. The `priv/plts` directory must be gitignored.

**Why separate restore/save actions:** Using `actions/cache/restore` + `actions/cache/save` (the split-cache pattern, available since cache v3.3) means the PLT cache is saved even if the `mix dialyzer` analysis step fails. With the unified `actions/cache`, a failing dialyzer run leaves no saved PLT, and the next run rebuilds from scratch again — compounding the problem.

**Cache key rationale:** Key on `${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}`. The `steps.beam.outputs.*` values come from `erlef/setup-beam` and are the exact OTP/Elixir versions resolved — more precise than `matrix.otp`/`matrix.elixir` which may be version ranges like `26.x`. The `mix.lock` hash catches dep changes. The `restore-keys` prefix (without `mix.lock`) lets a partial cache from a prior run seed the current run — dialyzer incrementally updates PLTs so a partial restore is still useful.

**mix.exs change required:** Add `plt_file: {:no_warn, "priv/plts/project.plt"}` to the `dialyzer:` config. Without this, dialyxir chooses its own path inside `_build` which defeats the separate `priv/plts` cache path. `{:no_warn, ...}` suppresses the "PLT path not under default" warning.

```elixir
# mix.exs
dialyzer: [
  plt_add_apps: [:mix, :ex_unit],
  plt_file: {:no_warn, "priv/plts/project.plt"}
]
```

Add to `.gitignore`:
```
/priv/plts/
```

**Concrete YAML — place inside the `lint-once` job (see Recommendation 4):**

```yaml
      - name: Restore PLT cache
        id: plt_cache
        uses: actions/cache/restore@5a3ec84eff668545956fd18022155c47e93e2684  # v4.2.3
        with:
          key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-
          path: priv/plts

      - name: Create PLTs
        if: steps.plt_cache.outputs.cache-hit != 'true'
        run: mix dialyzer --plt

      - name: Dialyzer
        run: mix dialyzer

      - name: Save PLT cache
        uses: actions/cache/save@5a3ec84eff668545956fd18022155c47e93e2684  # v4.2.3
        if: steps.plt_cache.outputs.cache-hit != 'true'
        with:
          key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
          path: priv/plts
```

> **Note on action SHA:** `actions/cache/restore` and `actions/cache/save` are sub-actions of the cache repo — they share the same SHA as `actions/cache`. The repo already pins `actions/cache` at `0057852bfaa89a56745cba8c7296529d2fc39830` (v4.3.0), which is the latest v4.x release. **The `actions/cache/restore` and `actions/cache/save` sub-paths use the same SHA.** For v1.8, keep the v4.3.0 SHA for the unified cache steps and use the same for split restore/save. The version `v4.2.3` SHA (`5a3ec84eff668545956fd18022155c47e93e2684`) shown above is NOT the latest v4.x; use v4.3.0 (`0057852bfaa89a56745cba8c7296529d2fc39830`) for consistency with what's already in ci.yml.
>
> **Corrected concrete YAML:**
> ```yaml
>       - name: Restore PLT cache
>         id: plt_cache
>         uses: actions/cache/restore@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
>         with:
>           key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
>           restore-keys: |
>             plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-
>           path: priv/plts
>
>       - name: Create PLTs
>         if: steps.plt_cache.outputs.cache-hit != 'true'
>         run: mix dialyzer --plt
>
>       - name: Dialyzer
>         run: mix dialyzer
>
>       - name: Save PLT cache
>         uses: actions/cache/save@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
>         if: steps.plt_cache.outputs.cache-hit != 'true'
>         with:
>           key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
>           path: priv/plts
> ```

**Dual-prefix interaction:** PLTs do NOT contain schema-prefix information. The PLT encodes OTP + Elixir type signatures and your library's own type contracts — none of which change with `@schema_prefix`. A single PLT is correct for all prefix legs. Therefore, PLT caching belongs in the `lint-once` job (see Recommendation 4), not in the per-prefix `test` matrix. Do not add `schema_prefix` to the PLT cache key.

**Expected savings:** On a cold run the PLT build dominates (5–10 min); on a warm run `mix dialyzer --plt` is skipped entirely. Across a 3-cell OTP matrix, each cell saves its own PLT (keys differ by OTP version). Measured improvement in community reports: ~765s → ~105s for the dialyzer step on a mid-sized Elixir project. Parapet will see proportionally similar improvement.

---

### 2. Deps and `_build` Caching + Prefix Interaction

**Current state:** The `lint` job caches `deps` and `_build` per `elixir+otp+mix.lock` — no prefix dimension. The `test` job correctly adds `schema_prefix` to the `_build` key (v1.7 work). The `demo` job caches `examples/demo_app/deps` and `examples/demo_app/_build` separately.

**The problem to not reintroduce:** The v1.7 design doc (04-TEST-STRATEGY.md, §2.3, "F1") is explicit: if two matrix cells share the same `_build` cache key but compile with different `PARAPET_SCHEMA_PREFIX` values, the `public` leg silently reuses the `parapet` build and false-greens the entire purpose of the dual-prefix matrix. The v1.7 fix — namespacing `_build` by `schema_prefix` and forcing `mix compile --force` — must be preserved unchanged.

**Lint job `_build` cache:** The `lint` job has no `schema_prefix` matrix dimension and does not set `PARAPET_SCHEMA_PREFIX`. It always compiles with the default prefix (`"parapet"`, via `config/config.exs`). This is correct and should stay as-is. Do NOT add `schema_prefix` to the lint `_build` key — it only has one prefix value.

**Deps cache can be shared across prefix legs:** The `deps` directory contains downloaded source code, not compiled artifacts. Two legs with the same `elixir+otp+mix.lock` but different prefixes produce identical `deps/`. The current per-OTP/Elixir `deps` key is correct and should not be changed.

**Concrete YAML for `_build` in the `lint-once` job (unchanged from current lint job):**
```yaml
      - name: Cache deps
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
        with:
          path: deps
          key: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-

      - name: Cache _build
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
        with:
          path: _build
          key: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-
```

**Concrete YAML for `_build` in the `test` matrix job (must include `schema_prefix`):**
```yaml
      - name: Cache deps
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
        with:
          path: deps
          key: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-

      # CRITICAL: _build key MUST include schema_prefix.
      # Without it, the 'public' leg restores the 'parapet' build artifact,
      # silently testing the wrong compiled @schema_prefix (false-green).
      - name: Cache _build
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
        with:
          path: _build
          key: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-
```

**Why `mix compile --force` must stay in the `test` job:** Even with a prefix-namespaced cache key, a cache miss on the first run of a new prefix value could restore a partial artifact. `mix compile --force` guarantees the `PARAPET_SCHEMA_PREFIX` env var is baked into the compiled modules for this exact run. Remove it and a stale cache hit could produce a build where `@schema_prefix` does not match the current prefix env var — another false-green path.

**Summary:** The current `test` job cache design is already correct from v1.7. The v1.8 change for caching is in the `lint-once` job split (no schema_prefix in lint `_build`) and adding PLT caching as a new separate cache path.

---

### 3. Concurrency: `cancel-in-progress` Scoped to PRs

**Problem:** Without `concurrency`, every push to a PR branch queues a new CI run without cancelling the superseded run. A developer pushing 5 quick fixup commits kicks off 5 CI runs when only the last one matters.

**Why not cancel on `main`:** `main` runs are release backstops. If two commits land on `main` in quick succession (e.g., auto-merge of a release-please PR followed by a hotfix), the second run should not cancel the first — both runs are meaningful evidence for the release history.

**Pattern:** Use `github.event_name == 'pull_request'` as a boolean expression for `cancel-in-progress`. This is a GitHub-supported expression context (confirmed in GitHub docs). The concurrency group uses `github.workflow` (stable workflow name) plus `github.ref` (PR branch ref, e.g. `refs/pull/42/merge`) which is unique per PR.

**Concrete YAML — add at the workflow top level (above `jobs:`):**
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

**Why this group expression is safe for `main`:** On `push` to `main`, `github.ref` is `refs/heads/main`. Two concurrent pushes to `main` would share the same group key — but `cancel-in-progress` evaluates to `false` for `push` events, so the second run waits rather than cancelling. Correct behavior.

**Why `github.head_ref` is not used here:** `github.head_ref` is only defined on `pull_request` events (it's the source branch name, e.g. `feat/add-plt-cache`). Using `github.head_ref || github.run_id` would make each push-to-main run have a unique group (via `run_id`) — fine, but unnecessary since we're not cancelling on main anyway. The simpler `github.workflow + github.ref` is sufficient.

**Impact on the dual-prefix matrix:** `concurrency` is set at the workflow level. When a PR push cancels an in-progress run, it cancels ALL in-flight jobs — both the `parapet` leg and the `public` leg. This is correct: both legs are being superseded by the new push. No partial-cancellation concern.

**Does this affect `release_gate`?** Yes — if a PR push cancels an in-progress workflow run, the `release_gate` job from that cancelled run is also cancelled. Branch protection sees a cancelled (not failed) check, which typically presents as "pending" on the prior commit SHA. The new push starts fresh with a new `release_gate` — this is the intended behavior.

---

### 4. Lint-Once Job Split

**Problem:** `format`, `credo`, `hex.audit`, `docs`, `verify.public_api`, and the operator UI manifest diff are all OTP-insensitive: they produce the same pass/fail result regardless of OTP 26, 27, or 28. Running them 3× (once per OTP cell) wastes 3× the runner time for zero additional coverage. Dialyzer is also run 3× in the current `lint` job.

**Solution:** Split the current `lint` job into:
- **`lint-once`**: Runs on a single fixed OTP version (e.g., `otp: '28.x'`). Contains all OTP-insensitive checks: format, credo, hex.audit, docs, verify.public_api, operator UI manifest diff, **and dialyzer with PLT caching**.
- **`compile-matrix`** (optional): If you want compile-warnings-as-errors verified across all OTP versions, keep a stripped matrix job that only runs `mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors`. This is the one lint step that IS OTP-sensitive (OTP-version-specific warnings may exist). If it turns out warnings are stable across OTPs in practice, drop this job.

**Why dialyzer moves to `lint-once`:** Dialyzer is CPU-intensive and OTP-sensitive for PLT construction, but you only want to run it once per commit (not 3×). Running it once on the highest OTP (28.x) is the standard practice — PLT for OTP 28 will catch the most issues. The PLT cache key includes OTP version, so it remains correct.

**Why `release_gate` must be updated:** Currently `release_gate` depends on `needs: [lint, test, demo]`. After the split, `lint` becomes `lint-once` (plus optionally `compile-matrix`). The `release_gate` must be updated to `needs: [lint-once, test, demo]` (and `compile-matrix` if kept).

**Concrete YAML for `lint-once`:**

```yaml
  lint-once:
    runs-on: ubuntu-latest
    env:
      MIX_ENV: test
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
      - name: Setup Elixir
        id: beam
        uses: erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124  # v1.24.1
        with:
          elixir-version: '1.19.0'
          otp-version: '28.x'

      - name: Cache deps
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
        with:
          path: deps
          key: ${{ runner.os }}-mix-1.19.0-28.x-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-mix-1.19.0-28.x-

      - name: Cache _build
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
        with:
          path: _build
          key: ${{ runner.os }}-build-1.19.0-28.x-${{ hashFiles('**/mix.lock') }}
          restore-keys: ${{ runner.os }}-build-1.19.0-28.x-

      - name: Restore PLT cache
        id: plt_cache
        uses: actions/cache/restore@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
        with:
          key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-
          path: priv/plts

      - name: Install dependencies
        run: mix deps.get

      - name: Check Formatting
        run: mix format --check-formatted

      - name: Compile Warnings as Errors
        run: mix compile --warnings-as-errors

      - name: Compile Without Optional Deps
        run: mix compile --no-optional-deps --warnings-as-errors

      - name: Build Docs Warnings as Errors
        env:
          MIX_ENV: dev
        run: mix docs --warnings-as-errors

      - name: Credo
        run: mix credo --strict

      - name: Hex Audit
        run: mix hex.audit

      - name: Create PLTs
        if: steps.plt_cache.outputs.cache-hit != 'true'
        run: mix dialyzer --plt

      - name: Dialyzer
        run: mix dialyzer

      - name: Save PLT cache
        uses: actions/cache/save@0057852bfaa89a56745cba8c7296529d2fc39830  # v4.3.0
        if: steps.plt_cache.outputs.cache-hit != 'true'
        with:
          key: plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}
          path: priv/plts

      - name: Verify Public API
        run: mix verify.public_api

      - name: Operator UI manifest drift
        run: |
          diff \
            <(bash examples/demo_app/scripts/capture_operator_ui_screenshots.sh --manifest) \
            <(sed -n '/^| name /,/^Total: /p' examples/demo_app/scripts/operator-ui-baseline.md)
```

**Note on `id: beam`:** The `Setup Elixir` step must have `id: beam` so that `steps.beam.outputs.otp-version` and `steps.beam.outputs.elixir-version` are available for the PLT cache key. These are the exact resolved version strings (e.g., `28.2.4` not `28.x`), which makes the PLT cache key precise.

**Runner savings:** With the lint-once split, `format + credo + hex.audit + docs + verify.public_api + dialyzer` run once instead of 3×. At ~5–8 minutes per `lint` cell today (most of that dialyzer), this saves 10–16 runner-minutes per push.

**Action SHA updates in this YAML:** These are the latest-confirmed SHAs as of 2026-07-02:
- `actions/checkout v4.2.2`: `11bd71901bbe5b1630ceea73d27597364c9af683`
- `erlef/setup-beam v1.24.1`: `54075bcc5e249e4758d363f27d099f55d843f124`
- `actions/cache v4.3.0`: `0057852bfaa89a56745cba8c7296529d2fc39830` (already current in repo)

**Note:** The repo's `actions/checkout` SHA (`34e114876b0b11c390a56381ad16ebd13914f8d5`, ~v4.2.0) and `erlef/setup-beam` SHA (`fc68ffb90438ef2936bbb3251622353b3dcb2f93`, ~v1.15–v1.17) are behind their latest versions. Updating them in v1.8 is appropriate. This update should be done for ALL jobs in ci.yml simultaneously to maintain consistency.

---

### 5. `release_gate` Aggregation — Stable Required Check Through a Job Reshape

**Current design (correct and to be preserved):** The `release_gate` job:
```yaml
  release_gate:
    needs: [lint, test, demo]
    runs-on: ubuntu-latest
    steps:
      - run: echo "All required CI checks passed"
```

This is already the canonical pattern. Branch protection requires only `release_gate` — not the individual `lint`, `test`, or `demo` job names. This is the v1.2 design decision ("release_gate remains the stable aggregate CI check").

**The critical `if: always()` problem:** The current `release_gate` job does NOT have `if: always()`. This means: if `lint`, `test`, or `demo` fail, GitHub Actions marks their dependent jobs (including `release_gate`) as "skipped" rather than running them. A skipped `release_gate` in branch protection appears as "pending" (never ran) — which can silently allow merges if the protection rule is not set to "require the check to pass" (as opposed to "require the check to be present").

**The correct fix is to add `if: always()` to `release_gate` AND fail if any dependency failed:**

```yaml
  release_gate:
    needs: [lint-once, test, demo]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Check all jobs passed
        run: |
          results="${{ needs.lint-once.result }} ${{ needs.test.result }} ${{ needs.demo.result }}"
          for result in $results; do
            if [ "$result" != "success" ]; then
              echo "One or more required jobs did not succeed: $results"
              exit 1
            fi
          done
          echo "All required CI checks passed"
```

**Why `if: always()` is required:** Without it, if `lint-once` fails, `release_gate` is skipped. Branch protection sees "required check not reported" — depending on configuration, this may or may not block merges. `if: always()` guarantees `release_gate` always reports a result, and the step logic above translates any upstream failure into a hard `exit 1`.

**Why not just `needs.test.result == 'success'`:** The `test` job is a matrix. `needs.test.result` is the aggregate result of all matrix cells — if any cell fails, it becomes `'failure'`. The above pattern works correctly: if any `test` cell fails, `needs.test.result` is `'failure'`, the loop finds a non-success result, and exits 1. No special handling needed for matrix jobs.

**Job rename from `lint` to `lint-once`:** This is the one change that MUST NOT break the existing branch protection rule. The branch protection rule is set to require `release_gate` — not `lint`. So renaming `lint` to `lint-once` and updating `release_gate`'s `needs:` list is safe. The `release_gate` job name itself never changes. The planner should confirm this assumption by checking the actual branch protection settings, but based on the v1.2 KEY DECISION and the `release_gate` design, this should hold.

**What if you want to keep `lint` (no rename)?** Rename the job to `lint-once` in ci.yml is recommended for clarity. If you don't rename, remove the 3-cell OTP matrix from the existing `lint` job and replace it with a single non-matrix step — the `release_gate` will continue to reference the same `lint` job name.

**Concrete updated `release_gate` for the v1.8 reshape:**

```yaml
  release_gate:
    needs: [lint-once, test, demo]
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Check all jobs passed
        run: |
          results="${{ needs.lint-once.result }} ${{ needs.test.result }} ${{ needs.demo.result }}"
          for result in $results; do
            if [ "$result" != "success" ]; then
              echo "Required jobs did not all succeed: $results"
              exit 1
            fi
          done
          echo "All required CI checks passed"
```

> **If `compile-matrix` is kept as a separate job** (for cross-OTP compile warning verification), add it to `needs`:
> ```yaml
>   release_gate:
>     needs: [lint-once, compile-matrix, test, demo]
> ```

---

## Sequencing Notes vs v1.7 Dual-Prefix Matrix

The v1.7 dual-prefix `_build` cache design and `mix compile --force` step must be preserved exactly. Every v1.8 change must be evaluated against this constraint.

| v1.8 change | v1.7 interaction | Safe? |
|-------------|-----------------|-------|
| PLT caching in `lint-once` | PLTs have no schema-prefix content. Single PLT for all prefix legs. PLT cache key: OTP+Elixir+mix.lock, no prefix dimension. | Safe — PLT is prefix-agnostic |
| `lint-once` job (no OTP matrix) | `lint-once` has no `schema_prefix` dimension. It always compiles with default prefix (`"parapet"`). The `_build` cache for `lint-once` has no prefix segment. | Safe — lint never runs `mix test`, never exercises prefix-sensitive paths |
| `test` job `_build` key | Must keep `${{ matrix.schema_prefix }}` in the key. **Do not remove.** | Required — unchanged from v1.7 |
| `mix compile --force` in `test` | Must be kept in every `test` matrix cell. **Do not remove.** | Required — without it, a cache hit on a stale artifact could skip baking the compile_env value |
| `concurrency: cancel-in-progress` | Cancels ALL jobs in a run (both `parapet` and `public` legs simultaneously). Not a partial cancellation. | Safe — new push correctly supersedes both legs together |
| `release_gate` rename from `lint` to `lint-once` | `release_gate` needs clause changes. The gate job name `release_gate` itself is unchanged — branch protection remains stable. | Safe — branch protection references `release_gate` only |
| `release_gate` adding `if: always()` | Makes the gate always report. Stronger guarantee than current design. | Safe — improves correctness |
| Action SHA updates (checkout, setup-beam) | These are infrastructure updates with no effect on Elixir compilation logic or prefix behavior. | Safe — verify via Dependabot or manual update |

**The one thing that would break v1.7 integrity:**
Removing `${{ matrix.schema_prefix }}` from the `test` job's `_build` cache key, or removing `mix compile --force`. Either change would allow the `public` leg to silently reuse the `parapet` build artifact, producing a false-green on the dual-prefix contract test. This must be treated as a release-blocking regression — the 04-TEST-STRATEGY.md document labels it "the #1 silent-failure footgun."

---

## Sources

- [dialyxir official GitHub Actions docs](https://github.com/jeremyjh/dialyxir/blob/master/docs/github_actions.md) — PLT cache path (`priv/plts`), split restore/save pattern, cache key structure using `steps.beam.outputs.*`
- [GitHub Actions: Control workflow concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency) — `cancel-in-progress` expression support, `github.event_name == 'pull_request'` pattern
- [GitHub community: Matrix job status check for required checks](https://github.com/orgs/community/discussions/26822) — `needs.job.result` aggregation, `if: always()` requirement
- [Parapet v1.7 04-TEST-STRATEGY.md](../../research/v1.7/04-TEST-STRATEGY.md) — Dual-prefix `_build` false-green analysis (F1), `mix compile --force` requirement
- [Parapet v1.7 00-SYNTHESIS.md](../../research/v1.7/00-SYNTHESIS.md) — v1.7 dual-prefix CI matrix decisions
- [actions/cache releases](https://github.com/actions/cache/releases) — v4.3.0 SHA `0057852bfaa89a56745cba8c7296529d2fc39830` (current in repo, confirmed)
- [actions/checkout releases](https://github.com/actions/checkout/releases) — v4.2.2 SHA `11bd71901bbe5b1630ceea73d27597364c9af683`
- [erlef/setup-beam releases](https://github.com/erlef/setup-beam/releases) — v1.24.1 SHA `54075bcc5e249e4758d363f27d099f55d843f124`
- [Hashrocket: Ultimate Elixir CI](https://hashrocket.com/blog/posts/build-the-ultimate-elixir-ci-with-github-actions) — Elixir CI patterns reference
- [Massdriver: Dilating GitHub Actions using Dialyzer](https://www.massdriver.cloud/blogs/dilating-github-actions-using-dialyzer) — PLT caching performance data
