# Local mix ci Alias & DX (v1.8)

**Researched:** 2026-07-02
**Source basis:** Derived entirely from actual project files — `mix.exs`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`, `MAINTAINING.md`, `lib/mix/tasks/verify.public_api.ex`, `.planning/PROJECT.md`.

---

## Gated steps CI actually runs (from ci.yml + verify.* tasks)

The `release_gate` job requires `lint`, `test`, and `demo`. The `demo` job is a separate-app smoke test that is not reproducible locally without the `examples/demo_app` Postgres fixture. `mix ci` should mirror the gating lane (lint + test on default prefix), not demo.

### Lint job — exact sequence (ci.yml lines 38–61, MIX_ENV=test)

| # | Command | Notes |
|---|---------|-------|
| 1 | `mix deps.get` | Fetch deps (CI runs clean; local skips if already fetched) |
| 2 | `mix format --check-formatted` | Fails if any file needs reformatting |
| 3 | `mix compile --warnings-as-errors` | Full compile, all optional deps present |
| 4 | `mix compile --no-optional-deps --warnings-as-errors` | Proves clean compile when optional deps absent |
| 5 | `mix docs --warnings-as-errors` | MIX_ENV=dev; catches broken ExDoc references |
| 6 | `mix credo --strict` | Static analysis, strict mode |
| 7 | `mix hex.audit` | Retired/vulnerable package check |
| 8 | `mix dialyzer` | Type analysis via dialyxir 1.4 |
| 9 | `mix verify.public_api` | Checks stability-tier docs + manifest drift |
| 10 | Operator UI manifest diff | Bash diff of screenshot capture script vs baseline; **not a mix task** |

### Test job — exact sequence (ci.yml lines 113–116, MIX_ENV=test)

| # | Command | Notes |
|---|---------|-------|
| 1 | `mix deps.get` | |
| 2 | `mix compile --force` | Forces recompile under the current schema_prefix leg |
| 3 | `mix test` | Runs full suite |

**Matrix:** `schema_prefix` in `['parapet', 'public']` — the `public` leg is an `include:` extra (OTP 28 only).

### verify.* tasks — complete enumeration

Only one `verify.*` task exists in `lib/mix/tasks/`:

- `mix verify.public_api` — checks that all public modules have `@moduledoc` + stability-tier admonition (`> #### Stable {: .info}` or `> #### Experimental {: .warning}`), and that `priv/parapet/public_api_stable.json` has not drifted.

There are no other `verify.*` tasks. The operator UI manifest diff (step 10 above) is a raw bash diff, not a mix task.

### Operator UI manifest diff — local reproducibility

The lint job runs:
```bash
diff \
  <(bash examples/demo_app/scripts/capture_operator_ui_screenshots.sh --manifest) \
  <(sed -n '/^| name /,/^Total: /p' examples/demo_app/scripts/operator-ui-baseline.md)
```

This requires a running demo app + Chromium. It is **not reproducible locally without significant setup** and is already gated through the `demo` CI job separately. Recommendation: **exclude it from `mix ci`**. Contributors who touch the Operator UI templates should run it manually. Document the exception in CONTRIBUTING.md.

---

## Recommended mix ci alias

### Exact alias definition for mix.exs `aliases/0`

```elixir
defp aliases do
  [
    ci: [
      "format --check-formatted",
      "compile --warnings-as-errors",
      "compile --no-optional-deps --warnings-as-errors",
      "credo --strict",
      "hex.audit",
      "dialyzer",
      "test",
      "verify.public_api"
    ]
  ]
end
```

### Step ordering rationale

1. **`format --check-formatted`** — fastest feedback, zero compilation required; kills bad diffs immediately.
2. **`compile --warnings-as-errors`** — gating step before any analysis tool runs; dialyzer and credo need compiled beam files.
3. **`compile --no-optional-deps --warnings-as-errors`** — optional-dep cleanliness check. Runs after full compile so the beam cache is warm; the `--no-optional-deps` flag forces a module-graph re-evaluation without restarting from scratch.
4. **`credo --strict`** — static analysis; fast on a warm build.
5. **`hex.audit`** — network call but lightweight; better before the expensive dialyzer.
6. **`dialyzer`** — slowest step; runs last in the lint-type group so fast failures abort before it.
7. **`test`** — runs the full suite (with quarantine tag, see below). After dialyzer because test failures are cheaper to see first, but dialyzer failures mean the beam types aren't trustworthy.
8. **`verify.public_api`** — last because it calls `Mix.Task.run("compile")` internally and checks the already-built beam output; fast after a warm build.

### Steps deliberately omitted from mix ci

| Step | Reason for omission |
|------|---------------------|
| `mix deps.get` | CI runs in a clean env; locally deps are typically already fetched. Running it in the alias would silently upgrade on lock drift, masking a real issue. Contributor should run `mix deps.get` explicitly before `mix ci`. |
| `mix compile --force` | The CI test job uses `--force` to reset the beam cache for each schema_prefix leg. Locally, `mix ci` runs a single default-prefix pass; the force-recompile is only meaningful across matrix legs. |
| `mix docs --warnings-as-errors` | Requires `MIX_ENV=dev`, but `mix ci` runs under `MIX_ENV=test` (where `:ex_doc` is `only: :dev`). Running docs in a separate env switch inside an alias would be confusing. Contributors can run `MIX_ENV=dev mix docs --warnings-as-errors` manually. Omitting this is a known delta from CI. |
| Operator UI manifest diff | Requires Chromium + demo app; documented manual-only step. |

**Documented CI delta:** `mix ci` does not run `mix docs --warnings-as-errors` or the operator UI screenshot diff. These are noted in CONTRIBUTING.md so contributors are not surprised when CI catches something `mix ci` did not.

### Fail-fast behavior

Mix aliases in Elixir fail the whole chain on the first non-zero exit — this is the default behavior of `Mix.Task.run/1` called sequentially in an alias list. No special configuration is needed. Each step in the list must exit 0 or the alias halts. This matches CI's default `fail-fast: true` on the lint job.

---

## Anti-drift: keeping mix ci == CI

### The single-source-of-truth problem

The canonical gate is `ci.yml`. If `mix ci` is defined in `mix.exs` independently, the two can diverge silently when a step is added to one but not the other.

### Recommended mechanism: CI calls mix ci for the portable subset

Restructure `ci.yml` so the lint job delegates the portable steps to `mix ci`:

```yaml
# ci.yml lint job (portable steps)
- name: Run mix ci
  run: mix ci
  env:
    MIX_ENV: test
```

Then add the non-portable steps that `mix ci` cannot reproduce after:

```yaml
- name: Build Docs (dev env)
  run: mix docs --warnings-as-errors
  env:
    MIX_ENV: dev

- name: Operator UI manifest drift
  run: |
    diff \
      <(bash examples/demo_app/scripts/capture_operator_ui_screenshots.sh --manifest) \
      <(sed -n '/^| name /,/^Total: /p' examples/demo_app/scripts/operator-ui-baseline.md)
```

**Why this works as the anti-drift mechanism:** There is now only one definition of the portable gated steps — the `mix ci` alias. CI is a consumer of `mix ci`. Adding a new portable step to `mix ci` automatically makes it gate in CI. You cannot forget to update `ci.yml` for portable steps because `ci.yml` does not list them individually.

**What remains duplicated:** The two non-portable steps (docs in dev env, operator UI diff) stay explicitly in `ci.yml` only. Their absence from `mix ci` is documented, not accidental.

### Fallback: contract comment if CI cannot be refactored in this phase

If restructuring `ci.yml` to call `mix ci` is deferred, add a comment block at the top of the lint job:

```yaml
# SYNC-GATE: The following steps mirror the `mix ci` alias in mix.exs.
# If you add a step here, add the matching task to aliases/0 in mix.exs.
# Non-portable steps (MIX_ENV=dev docs, operator-ui diff) are exceptions.
```

This is weaker than the structural approach — it relies on discipline — but it makes drift intentional rather than accidental. Choose the structural approach (CI calls `mix ci`) for strongest guarantees.

---

## Local PLT ergonomics

### Where Dialyxir puts the PLT locally

Dialyxir 1.4 stores PLTs under `_build/<MIX_ENV>/dialyxir_<elixir_ver>_<otp_ver>/`. With `MIX_ENV=test`, that is `_build/test/dialyxir_*/`. The path is deterministic and env-scoped.

### First-run cost

Building the PLT from scratch takes 2–5 minutes on a typical developer machine (OTP + project modules). Subsequent runs are incremental — only changed beams are re-analyzed. The PLT is persistent across `mix ci` runs as long as `_build/test/` is not wiped.

### Keeping local PLT consistent with CI PLT cache

CI caches `_build` keyed on `${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}`. Locally:

- The PLT is in `_build/test/` which is in `.gitignore` — correct behavior.
- **When `mix.lock` changes** (a dep is added, upgraded, or removed), `mix dialyzer` will automatically detect the changed PLT inputs and rebuild the relevant slice. No manual intervention needed.
- **When the OTP version changes** locally (e.g., upgrading asdf OTP), dialyxir detects the version mismatch in the PLT path and rebuilds. The first run after an OTP upgrade is slow — expected.
- **CI uses `26.x`, `27.x`, `28.x` in its matrix.** Local contributors typically run one OTP version. This is acceptable — `mix ci` is checking local correctness, not cross-OTP portability. The matrix is CI's job.

### PLT config in mix.exs

The existing config is:
```elixir
dialyzer: [plt_add_apps: [:mix, :ex_unit]]
```

This is correct for a test-env alias (`mix` tasks and `ExUnit` are both reachable in `MIX_ENV=test`). No change needed. Do not add `plt_file:` — letting dialyxir manage the path automatically keeps it consistent with CI's `_build` cache key.

### .gitignore hygiene

Confirm `_build/` is in `.gitignore` (it should be for any Elixir project). PLT files are binary and large — never commit them.

---

## Quarantine + schema-prefix handling locally

### Quarantine tag for known-red tests

v1.8 introduces a `@moduletag :quarantine` (or `@tag :quarantine`) on `DocsPhase33Test` and `Parapet.Telemetry.RecoveryActionTest`. Once tagged, bare `mix test` can exclude them:

```elixir
# test/test_helper.exs
ExUnit.start(exclude: [:quarantine])
```

With this configured, `mix test` (and therefore `mix ci`) runs cleanly without the two known-red tests. Contributors see a green local run. CI's bare `mix test` call will also be green once `test_helper.exs` excludes `:quarantine` by default.

**The quarantine is not hiding failures** — the two tests are pre-existing reds documented in the v1.7 audit as internal hygiene. v1.8's goal is to restore the green-suite premise so CI is the trustworthy enforcement backstop.

To run quarantined tests explicitly:
```bash
mix test --include quarantine
```

This is what a contributor investigating `DocsPhase33Test` or `Telemetry.RecoveryActionTest` would do.

### Schema-prefix handling in mix ci

CI runs two prefix legs: `PARAPET_SCHEMA_PREFIX=parapet` (3 OTP versions) and `PARAPET_SCHEMA_PREFIX=public` (OTP 28 only, include leg). Locally, `mix ci` runs under the **default prefix only** — whatever the developer's local config resolves to (default is `parapet`).

**Do not attempt to run both prefix legs in `mix ci`.** The dual-prefix matrix exists in CI because the `@schema_prefix` is compile-time and requires a separate `_build` path. Doing this locally would require two full compiles with separate beam caches, doubling local run time without meaningful local benefit (the CI matrix is the authoritative cross-prefix gate).

**Document this delta in CONTRIBUTING.md:** "`mix ci` runs the default schema prefix (`parapet`). The CI matrix also validates the `public` prefix leg — that coverage is CI-only. If you are modifying prefix-sensitive code, see the dual-prefix test notes in `.planning/research/v1.8/`."

### Schema-prefix environment variable

If a contributor wants to test the `public` prefix locally:
```bash
PARAPET_SCHEMA_PREFIX=public mix compile --force && PARAPET_SCHEMA_PREFIX=public mix test
```

The `--force` recompile is required because `@schema_prefix` is compile-time. This is intentional — it is not part of `mix ci`.

---

## CONTRIBUTING note

Replace the current "Local proof commands" section in `CONTRIBUTING.md` with:

```markdown
## Local proof commands

Run `mix ci` before pushing. This reproduces the gated CI checks in a single command:

```bash
mix ci
```

`mix ci` runs format check, compile (with and without optional deps), static analysis (Credo), Hex audit, Dialyzer, tests, and the public-API manifest check — in that order. Any failure stops the chain immediately.

**First run:** Dialyzer builds a PLT on the first run, which takes 2–5 minutes. Subsequent runs are incremental and fast.

**Before the first run:** ensure your deps are up to date:

```bash
mix deps.get
mix ci
```

**Known deltas from CI:** `mix ci` does not run `mix docs --warnings-as-errors` (requires `MIX_ENV=dev`) or the Operator UI screenshot manifest diff (requires a running demo app). If you are touching ExDoc configuration or Operator UI templates, run those checks manually before pushing:

```bash
MIX_ENV=dev mix docs --warnings-as-errors
```

**Schema prefix:** `mix ci` uses the default schema prefix (`parapet`). The CI matrix also validates the `public` prefix — that coverage is CI-only.

**Quarantined tests:** Two pre-existing failing tests (`DocsPhase33Test`, `Telemetry.RecoveryActionTest`) are excluded from `mix test` by default via `ExUnit.start(exclude: [:quarantine])`. To run them explicitly:

```bash
mix test --include quarantine
```
```

The rest of CONTRIBUTING.md (commit conventions, PR flow, stable-main posture, development setup) stays unchanged.

---

## Sources

All findings derived from first-party project files — no external research required. Confidence: HIGH.

| File | What it established |
|------|---------------------|
| `.github/workflows/ci.yml` | Exact gated step sequence for lint, test, and release_gate jobs; schema_prefix matrix; operator UI manifest diff command |
| `mix.exs` | Existing empty `aliases/0`; dialyzer config `plt_add_apps: [:mix, :ex_unit]`; dep versions (`dialyxir ~> 1.4`, `credo ~> 1.7`) |
| `lib/mix/tasks/verify.public_api.ex` | Only `verify.*` task; calls `Mix.Task.run("compile")` internally; checks `priv/parapet/public_api_stable.json` |
| `lib/mix/tasks/` listing | Complete list of mix tasks — confirms no other `verify.*` tasks exist |
| `CONTRIBUTING.md` | Current guidance lists only `mix test`, `mix credo`, `mix dialyzer` — outdated; confirms no mention of `mix ci` or `verify.public_api` |
| `.planning/PROJECT.md` | v1.8 goals (quarantine `DocsPhase33Test` + `Telemetry.RecoveryActionTest`; `mix ci` alias; dual-prefix matrix context); OSS discipline constraint (`mix verify.*` proof surfaces) |
