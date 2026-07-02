# Phase 58: Local DX — mix ci & CONTRIBUTING - Context

**Gathered:** 2026-07-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Give contributors a single `mix ci` command that mirrors the CI gate locally, and a `CONTRIBUTING.md` that tells them exactly what to run and which known local-vs-CI deltas to expect. Also lands the `mix.exs` dialyzer `plt_file` config + `/priv/plts/` gitignore entry as Phase 59 PLT-cache prerequisites. Requirements: DX-01, DX-02, DX-03. This phase is **wiring, not building** — every step/tool it composes already exists (verified by codebase analysis). Actual CI caching, the standalone `lint-once` job structure beyond calling `mix ci`, and matrix reshaping are Phase 59/60.

</domain>

<decisions>
## Implementation Decisions

### `mix ci` alias definition (DX-01)
- **D-01:** `mix ci` is a single `aliases/0` entry (`ci: [...]`) in `mix.exs` (populating the currently-empty `defp aliases do [] end` at `mix.exs:133-135`), listing the 8 steps as a fail-fast list of `mix` command strings in the exact roadmap order. Mix aliases run sequentially and halt on first non-zero exit, so fail-fast is inherent — **no wrapper script**.
- **D-02:** The 8 steps carry their **exact CI flags verbatim** (these flags are load-bearing gates, not cosmetic):
  1. `format --check-formatted` (NOT bare `mix format` — bare form silently reformats instead of failing)
  2. `compile --warnings-as-errors`
  3. `compile --no-optional-deps --warnings-as-errors` (optional deps: `opentelemetry_api`, `oban`, `req`, `sigra` — `mix.exs:121-126`)
  4. `credo --strict` (`.credo.exs` sets `strict: false`, so the `--strict` flag is required or the local gate is weaker than CI)
  5. `hex.audit`
  6. `dialyzer`
  7. `test`
  8. `verify.public_api`
- **D-03:** Steps mirror the existing per-step invocations in the CI `lint` job (`.github/workflows/ci.yml:39-56`) — that job is the source-of-truth reference for exact invocation strings.

### CI anti-drift — `lint-once` reuse (DX-02)
- **D-04:** Add a `lint-once` CI job (single-run, **not** OTP-matrixed) whose one gate step is `mix ci`, replacing the 8 individual portable steps in the current 3×OTP-matrixed `lint` job. `mix.exs` becomes the single source of truth so the local alias and CI cannot drift.
- **D-05:** The two `lint`-job steps that are NOT portable stay CI-only and never enter the alias: "Build Docs" (`mix docs --warnings-as-errors`, ci.yml:45-48) and "Operator UI manifest drift" (the `diff` shell block, ci.yml:57-61). These are exactly the documented local-vs-CI deltas.
- **D-06:** `release_gate.needs` (`.github/workflows/ci.yml:172`, currently `[lint, test, demo]`) MUST be updated to reference the renamed/added job (`lint-once`) or the gate breaks. Keeping the OTP matrix on the lint gate is rejected (would run `mix dialyzer` 3× building 3 PLTs for no benefit).

### Dialyzer PLT config + gitignore (Phase 59 prereq)
- **D-07:** `mix.exs:25` dialyzer config changes from `[plt_add_apps: [:mix, :ex_unit]]` to add `plt_file: {:no_warn, "priv/plts/project.plt"}` (keep `plt_add_apps`). The `{:no_warn, ...}` tuple suppresses the first-run "PLT does not exist" warning. dialyxir is already a dep (`mix.exs:129`) — no dependency work.
- **D-08:** Add a `/priv/plts/*.plt*` entry to `.gitignore` (narrower `*.plt*` glob preferred over bare `/priv/plts/` so a future tracked dir/`.gitkeep` isn't blocked). The `priv/plts/` dir and any ignore rule are net-new (confirmed absent).

### CONTRIBUTING.md (DX-03)
- **D-09:** Rewrite the existing "Local proof commands" section (`CONTRIBUTING.md:5-15`): replace the three separate commands (`mix test`, `mix credo`, `mix dialyzer` at :10-12) with a single `mix ci` instruction ("run before pushing"). Point the "Development setup" trailing `mix test` (:74-77) at `mix ci` too. Keep the release-gate description line (:54) accurate.
- **D-10:** Add a prose block documenting the **three known local-vs-CI deltas**: (a) no `mix docs` locally, (b) no operator-UI manifest diff locally, (c) single `parapet` schema prefix locally (CI runs a dual-prefix `public`-leg matrix — see `PARAPET_SCHEMA_PREFIX` at ci.yml:70-77). Frame these so a contributor seeing green `mix ci` locally but red CI on `mix docs`/`public`-prefix knows it's an expected delta, not a regression.

### Claude's Discretion
- Exact prose wording in CONTRIBUTING.md and section ordering.
- Whether the CI-only `mix docs` + operator-UI-diff steps live as extra steps inside `lint-once` or as their own small job (either satisfies D-05; planner picks the cleaner diff).
- Whether to alias-name it purely `ci` or also add a convenience `mix ci` sub-grouping — default to the single flat `ci: [...]` list unless planning finds a reason otherwise.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### CI gate being mirrored
- `.github/workflows/ci.yml` §`lint` job (lines 10-61) — the 10 steps; 8 portable → `mix ci`, 2 CI-only deltas (`mix docs` :45-48, operator-UI diff :57-61).
- `.github/workflows/ci.yml:70-77` — `test` job dual-prefix (`PARAPET_SCHEMA_PREFIX`, `public` leg) proving delta (c).
- `.github/workflows/ci.yml:172` — `release_gate: needs:` dependency that must track the job rename.

### Build config & tasks
- `mix.exs:25` (dialyzer config), `mix.exs:121-126` (optional deps), `mix.exs:127`/`:129` (credo/dialyxir deps), `mix.exs:133-135` (empty aliases to populate).
- `.credo.exs` — `strict: false` (:9), why `--strict` is load-bearing.
- `lib/mix/tasks/verify.public_api.ex` — `Mix.Tasks.Verify.PublicApi` (internally runs `mix compile` at :26; self-sufficient).

### Prior decisions / delta framing
- `.planning/phases/57-test-suite-baseline/57-CONTEXT.md` — green-suite baseline + the canonical three local-vs-CI deltas.
- `CONTRIBUTING.md:5-15` (Local proof commands — rewrite site), `:54` (release-gate line), `:74-77` (dev setup).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- All 8 gate steps already run verbatim in the CI `lint` job — the alias composes existing invocations, no new tooling.
- `mix verify.public_api` task, credo (+`.credo.exs`), dialyxir all present; `hex.audit` and `compile --no-optional-deps` are built-in/already-used.

### Established Patterns
- `defp aliases do [] end` is empty and ready to populate (`mix.exs:133-135`).
- v1.7 dual-prefix CI matrix is compile-time (`@schema_prefix`); locally contributors run the default `parapet` prefix only — the source of delta (c).

### Integration Points
- `mix.exs` aliases ↔ CI `lint-once` job (`mix ci` is the shared entrypoint → single source of truth).
- `release_gate.needs` in ci.yml must track the lint job rename.
- dialyzer `plt_file` path (`priv/plts/project.plt`) is the seam Phase 59's cache wiring depends on.

</code_context>

<specifics>
## Specific Ideas

- The whole point is honest signal: `mix ci` green locally must mean the portable CI gate would pass — hence exact-flag fidelity (`--check-formatted`, `--strict`, `--warnings-as-errors`) is non-negotiable.
- Single source of truth: CI calls `mix ci`, so the alias and CI physically cannot diverge for the portable set.

</specifics>

<deferred>
## Deferred Ideas

- PLT cache wiring in CI, `concurrency: cancel-in-progress`, hardened `release_gate`, SHA updates — Phase 59.
- OTP matrix reshape (trim PR matrix to 1 cell, full matrix on main+nightly), nightly schedule, D-11 retirement — Phase 60.
- Promoting `check_intentional_hold.sh` to a Credo check (Phase 57 D-17 deferral) — Phase 58/59 candidate; not folded here.

</deferred>

---

*Phase: 58-local-dx-mix-ci-contributing*
*Context gathered: 2026-07-02*
