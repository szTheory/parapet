# Phase 59: CI Caching, Lint-Once & release_gate Hardening - Context

**Gathered:** 2026-07-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Structurally reshape the `.github/workflows/ci.yml` pipeline so that: the Dialyzer PLT is cached,
lint/quality steps run exactly once on OTP 28, PR runs cancel superseded in-flight runs (main
never cancelled), `release_gate` can never silently pass on an upstream failure/skip, the v1.7
dual-prefix false-green invariant is demonstrably intact, and SHA-pinned actions are refreshed.

**In scope:** `ci.yml` job/step edits, a top-level `concurrency:` block, PLT cache wiring, the
`release_gate` result-aggregation guard, and SHA-pin bumps.

**Out of scope:** OTP matrix reshape / nightly schedule (Phase 60), any change to `mix.exs`
(the `mix ci` alias and `plt_file` config already shipped in Phase 58), `release-please.yml`.
</domain>

<decisions>
## Implementation Decisions

### PLT Caching (CI-01)
- **D-01:** Add exactly one `actions/cache` step, in the **`lint-once` job only** — it is the sole
  job that runs `mix dialyzer` (via `mix ci`). No PLT cache is added to the `test` or `demo` jobs.
- **D-02:** Cache `path: priv/plts` (whole dir — covers both dialyxir's core and project PLTs).
  Key: `plt-${{ runner.os }}-28.x-1.19.0-${{ hashFiles('**/mix.lock') }}`.
  `restore-keys: plt-${{ runner.os }}-28.x-1.19.0-`.
- **D-03:** Key is **prefix-agnostic** — no `schema_prefix` component. Dialyzer output is
  independent of the runtime schema prefix, and `lint-once` is not matrixed by prefix. (CI-01
  explicitly mandates a prefix-agnostic PLT key.)
- **D-04:** Place the PLT cache step **before** the `mix ci` step (alongside the existing deps /
  `_build` cache steps). Cache save is automatic on job success, persisting the PLT dialyzer built.

### lint-once — caching-only touch (CI-02)
- **D-05:** CI-02 is already structurally satisfied by Phase 58 (quality steps collapsed into a
  single no-matrix OTP-28 `lint-once` job running `mix ci`). Phase 59 does **NOT** re-architect
  `lint-once` — the only additive change to it is the D-01 PLT cache step.
- **D-06:** The two CI-only steps in `lint-once` — `mix docs --warnings-as-errors` (MIX_ENV=dev)
  and the operator-UI manifest `diff` block — stay exactly as-is. They are the documented
  local-vs-CI deltas (see Phase 58 D-05).

### PR Concurrency Cancellation (CI-03)
- **D-07:** Add a **top-level** (workflow-scoped) `concurrency:` block, not per-job:
  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
    cancel-in-progress: ${{ github.event_name == 'pull_request' }}
  ```
- **D-08:** Rationale for the exact expressions: grouping by `pull_request.number` for PR events
  means a new push to the same PR supersedes the prior run; falling back to `github.ref` for
  non-PR events isolates each branch. `cancel-in-progress` is a **dynamic boolean** — `true` only
  for `pull_request` events, so pushes to `main` (and future nightly/scheduled runs) are **never
  cancelled**. This is the canonical "cancel PRs, protect main" GitHub Actions pattern.

### release_gate Hardening (CI-04)
- **D-09:** Keep `needs: [lint-once, test, demo]`. Add `if: always()` to the `release_gate` job so
  it runs even when an upstream job fails or is skipped (default `if: success()` behaviour is what
  currently lets a failed upstream *skip* the gate rather than *fail* it).
- **D-10:** Replace the bare `echo` step with a `run:` step doing **explicit per-job result
  aggregation**: check `needs.lint-once.result`, `needs.test.result`, `needs.demo.result`; if ANY
  is not exactly `success` → `exit 1`. Treat `failure`, `cancelled`, **and `skipped`** all as
  gate failures (strict — a skipped upstream must fail the gate, per the footgun in CI-04).
- **D-11:** Explicit per-job `if [ "..." != "success" ]` checks are preferred over a
  `contains(needs.*.result, 'failure')` one-liner, because the one-liner does not catch `skipped`
  and the roadmap language is "explicit per-job result aggregation".

### Dual-Prefix Invariant — DO NOT TOUCH (CI-05)
- **D-12:** **INVARIANT (hard block):** The `test` job's `_build` cache key MUST retain
  `${{ matrix.schema_prefix }}` (ci.yml:93) and EVERY test matrix cell MUST retain
  `mix compile --force` (ci.yml:98). No change in this phase may alter those two lines. The only
  permitted edit to the `test` job is the CI-06 SHA bumps on its `uses:` lines. Violation causes a
  false-green on the `public`-prefix schema leg (the v1.7 footgun).

### SHA-Pin Updates (CI-06) — "proven-recent" tier [user-confirmed]
- **D-13:** Update all SHA-pinned actions across **every** job to the following commit pins
  (proven-recent majors chosen over <2-week-old newest majors to avoid node24/ESM churn on the
  release-critical CI backbone; Dependabot remains in place to bump further later):
  - `actions/checkout`  → **v6.0.3** `df4cb1c069e1874edd31b4311f1884172cec0e10`
    (from current v4-era `34e114876b0b11c390a56381ad16ebd13914f8d5`)
  - `erlef/setup-beam`   → **v1.24.1** `54075bcc5e249e4758d363f27d099f55d843f124`
    (from current v1.24.0 `fc68ffb90438ef2936bbb3251622353b3dcb2f93`)
  - `actions/cache`      → **v5.1.0** `caa296126883cff596d87d8935842f9db880ef25`
    (from current v4-era `0057852bfaa89a56745cba8c7296529d2fc39830`)
- **D-14:** Keep the `# vX.Y.Z` version comment convention next to each SHA pin if present, and
  update those comments to match the new versions so Dependabot and humans can read the pin.
  Rejected: newest-major tier (checkout v7.0.0 / cache v6.1.0) — deferred to Dependabot's cadence.

### Claude's Discretion
- Exact shell syntax of the D-10 result-check script (multi-line `if` chain vs a small loop over
  a job-result list) — any form that fails on non-`success` for all three jobs satisfies D-10.
- Ordering of the new PLT cache step relative to the existing deps/`_build` cache steps within
  `lint-once` (any pre-`mix ci` position is fine).
- Whether to add a short comment above the `concurrency:` block explaining the main-never-cancelled
  intent (encouraged for maintainability, not required).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.github/workflows/ci.yml` — the single file this phase edits (jobs: `lint-once`, `test`,
  `demo`, `release_gate`). Current SHA pins, cache keys, and the dual-prefix invariant lines live here.
- `mix.exs` — the `ci:` alias (`mix.exs:137`) and `dialyzer: [... plt_file: {:no_warn,
  "priv/plts/project.plt"}]` (`mix.exs:25-27`), both shipped in Phase 58. Read-only reference —
  this phase does not modify `mix.exs`.
- `.gitignore` — the `/priv/plts/*.plt*` entry (line 37) that makes the PLT cacheable-not-committed.
- `.planning/phases/58-local-dx-mix-ci-contributing/58-CONTEXT.md` — D-04/D-05/D-07/D-08 there
  established the `lint-once` job, `mix ci` step list, and PLT `plt_file` prereq this phase builds on.
- `.planning/REQUIREMENTS.md` — CI-01 … CI-06 acceptance criteria (lines 25-30).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`lint-once` job already exists** (ci.yml:10-45) running `mix ci` on OTP 28 — CI-02 is
  structurally done; this phase only bolts a PLT cache onto it.
- **deps + `_build` cache-step pattern** already used in every job (`actions/cache` with a
  `hashFiles('**/mix.lock')` key + `restore-keys` fallback) — the new PLT cache step should mirror
  this exact shape for consistency.
- **`mix ci` alias** (mix.exs:137) already runs `dialyzer` as step 6, so no CI step wiring is
  needed to *invoke* dialyzer — only to *cache its PLT*.

### Established Patterns
- All actions are SHA-pinned (not tag-pinned) with Dependabot managing bumps — CI-06 keeps this
  intact; only the SHA values change.
- Cache keys follow `${{ runner.os }}-<kind>-${{ matrix.elixir }}-${{ matrix.otp }}-[...]-${{ hashFiles('**/mix.lock') }}`.
- `release_gate` is the single required status check (solo-OSS: required reviews are disabled by
  design; `release_gate` IS the safety net) — which is exactly why D-09/D-10 hardening matters.

### Integration Points
- `release_gate.needs` fans in from `lint-once`, `test`, `demo` — the D-10 aggregation must name
  all three job results.
- The `test` job is shared with the v1.7 dual-prefix protection (CI-05 invariant) — the SHA bumps
  are the ONLY permitted edit there.
- Future Phase 60 (OTP matrix reshape + nightly schedule) will re-touch the `test`/`demo` matrices
  and the `concurrency` main-vs-nightly semantics — keep D-07's expression nightly-friendly
  (`github.event_name == 'pull_request'` already excludes future `schedule` events from cancellation).
</code_context>

<specifics>
## Specific Ideas

- PLT cache key format locked: `plt-${{ runner.os }}-28.x-1.19.0-${{ hashFiles('**/mix.lock') }}`.
- Concurrency block locked verbatim (see D-07).
- Exact SHA pins locked (see D-13).
- release_gate strictness: `skipped` counts as failure (see D-10).
</specifics>

<deferred>
## Deferred Ideas

- **Newest-major action bump** (checkout v7.0.0, cache v6.1.0) — deferred to Dependabot's normal
  cadence rather than adopting <2-week-old majors with node24/ESM runtime changes now.
- **OTP matrix reshape + nightly schedule** — Phase 60 (already roadmapped).

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
</content>
</invoke>
