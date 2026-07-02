# Requirements: Parapet — v1.8 CI/CD Performance & DX

**Defined:** 2026-07-02
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Milestone driver:** Make the CI pipeline fast, cheap, and green-by-default — so contributors get quick honest signal and `main` stays a trustworthy release backstop. Pipeline/DX only; public API + telemetry contracts stay frozen.

Grounding research: [`.planning/research/v1.8/00-SYNTHESIS.md`](research/v1.8/00-SYNTHESIS.md) (+ `01-CI-PERFORMANCE.md`, `02-OTP-MATRIX-STRATEGY.md`, `03-TEST-DEFLAKING.md`, `04-MIX-CI-DX.md`).

**Resolved decision points:** DP-1 → CI tests **Elixir 1.20.2 · OTP {27,28,29}** (drop EOL OTP 26 + Elixir 1.19; `mix.exs` stays `~> 1.19`, no library floor change). DP-2 → **fix the two red tests directly** (not quarantine). DP-3 → **trim `demo` to a single OTP-28 leg** (main+nightly). DP-4 → **drop the cross-OTP `compile-matrix`** for v1.8.

## v1.8 Requirements

### Test Suite Baseline (green `mix test`)

Closes v1.7 tech-debt #6 by fixing, not quarantining — a bare `mix test` must be green so "CI is the enforcement backstop" for the frozen contracts is an honest claim.

- [ ] **TEST-01**: A bare `mix test` (default env, default `parapet` prefix) passes green — `DocsPhase33Test`'s stale README assertion is fixed (`"make up-auto"` → `"make up"`)
- [ ] **TEST-02**: `Telemetry.RecoveryActionTest` no longer flakes under concurrent `async` tests — the `atom_count` before/after delta check is removed while the load-bearing `String.to_existing_atom/1`-raises guard is retained
- [ ] **TEST-03**: The three spurious `Process.sleep` calls in `exemplar_telemetry_test.exs` are removed (telemetry dispatch is synchronous, so the waits are dead time)
- [ ] **TEST-04**: The five intentional concurrency-simulation sleeps are annotated (named module attribute + explanatory comment) so they read as deliberate, and the cluster-smoke `Process.sleep(200)` startup race is replaced with a synchronous start barrier
- [ ] **TEST-05**: A reusable `assert_eventually`/until helper exists for genuinely-async assertions, so future tests have a deterministic alternative to `Process.sleep`

### CI Pipeline Performance

- [ ] **CI-01**: The Dialyzer PLT is cached across CI runs — `mix.exs` routes the PLT to `priv/plts` (`plt_file`), `priv/plts` is gitignored, and the cache key is `OTP + Elixir + mix.lock` (prefix-agnostic), so PRs no longer rebuild the PLT from scratch
- [ ] **CI-02**: Lint/quality steps run **once** in a single OTP-28 `lint-once` job (`format --check-formatted`, `compile --warnings-as-errors` incl. `--no-optional-deps`, `credo --strict`, `hex.audit`, `dialyzer`, `verify.public_api`) rather than repeating per matrix cell
- [ ] **CI-03**: PR workflows use `concurrency: { group, cancel-in-progress: true }` scoped to pull requests, so superseded PR runs are cancelled (main/nightly runs are never cancelled)
- [ ] **CI-04**: `release_gate` remains the single stable required check, hardened with `if: always()` + explicit per-job result aggregation so a skipped or failed upstream job can never let `release_gate` silently pass
- [ ] **CI-05**: deps/`_build` caching preserves the v1.7 dual-prefix invariant — the `test` job keeps its `${{ matrix.schema_prefix }}`-namespaced `_build` cache key and per-leg `mix compile --force`, so no schema-prefix leg can false-green
- [ ] **CI-06**: SHA-pinned actions are updated to current releases (`actions/checkout`, `erlef/setup-beam`, `actions/cache`), keeping the SHA-pin + Dependabot policy intact

### OTP Matrix & Triggers

- [ ] **MATRIX-01**: Pull requests run a trimmed matrix — a single representative cell (OTP 28 · Elixir 1.20.2 · `parapet` prefix) — for fast feedback
- [ ] **MATRIX-02**: Push-to-`main` and a nightly schedule run the full matrix — OTP {27, 28, 29} on Elixir 1.20.2 across the v1.7 schema-prefix legs — replacing the EOL OTP 26 / Elixir 1.19 pins and retiring the D-11 uneven-coverage carve-out
- [ ] **MATRIX-03**: The `demo` smoke job is trimmed to a single OTP-28 leg, skipped on PRs and run on main + nightly (its checks are OTP- and prefix-independent)
- [ ] **MATRIX-04**: A nightly scheduled run (`on: schedule`) exercises the full matrix + demo, so full multi-version coverage is preserved off the PR hot path

### Local Developer Experience

- [ ] **DX-01**: A `mix ci` alias reproduces the CI gate locally in fail-fast order (the same gated steps as `lint-once` + `test` on the default prefix), so a contributor can prove a change before pushing
- [ ] **DX-02**: The CI `lint-once` job invokes `mix ci` as its single source of truth for the portable gate steps, so the local alias and CI cannot drift apart
- [ ] **DX-03**: `CONTRIBUTING.md` is updated to instruct `mix ci` before pushing (replacing the outdated `mix test` / `credo` / `dialyzer` note) and documents the intended local-vs-CI delta (single prefix + trimmed matrix locally; full matrix in CI)

## Future / Deferred Requirements

Tracked, not in the v1.8 roadmap.

### Quality Hardening (v1.9)

- **TELEM-01**: Stable telemetry manifest (`telemetry_stable.json`) + drift gate (the durable WR-01 fix, deferred per D-21)
- **REFACTOR-01**: Decompose the `operator.ex` god-module behind the frozen Stable surface
- **A11Y-01**: Playwright + axe-core a11y lane; ExUnit-pin the v1.6 `override_closeout` gaps (TOKEN-04, FLOW/COPY/A11Y-06)

### Later

- **VER-01**: Bump the `mix.exs` Elixir requirement from `~> 1.19` to `~> 1.20` once the 1.19 + OTP 27/28 adopter cohort has had time to migrate (revisit in/after v1.9)

## Out of Scope

Explicitly excluded from v1.8, with reasoning.

| Feature | Reason |
|---------|--------|
| Cross-OTP `compile-matrix` job (DP-4) | OTP-version-specific compile warnings between same-major patches are very rare; `dialyzer` on OTP 28 + the PR test cell already compile. Adds complexity for marginal signal — revisit in v1.9 if a warning slips |
| Bumping the `mix.exs` `elixir:` floor (`~> 1.19` → `~> 1.20`) | Changing the published library's declared floor is an adopter-facing decision deferred to VER-01; v1.8 only changes what CI tests, not what adopters may install |
| CI-provider migration (e.g. off GitHub Actions) | Pipeline is reshaped in place; GitHub Actions + Release Please + `release_gate` stay the substrate |
| Any public-API, telemetry, generator, or runtime behavior change | v1.8 is pipeline/DX only; the frozen v1.0 contracts and host-ownership model are invariants, not scope |
| Quarantine infrastructure (nightly non-gating red-test lane) | Superseded by DP-2 — both reds have trivial direct fixes; quarantine tooling would be dead weight |

## Traceability

Populated during roadmap creation (each requirement maps to exactly one phase).

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEST-01 | — | Pending |
| TEST-02 | — | Pending |
| TEST-03 | — | Pending |
| TEST-04 | — | Pending |
| TEST-05 | — | Pending |
| CI-01 | — | Pending |
| CI-02 | — | Pending |
| CI-03 | — | Pending |
| CI-04 | — | Pending |
| CI-05 | — | Pending |
| CI-06 | — | Pending |
| MATRIX-01 | — | Pending |
| MATRIX-02 | — | Pending |
| MATRIX-03 | — | Pending |
| MATRIX-04 | — | Pending |
| DX-01 | — | Pending |
| DX-02 | — | Pending |
| DX-03 | — | Pending |

**Coverage:**
- v1.8 requirements: 18 total
- Mapped to phases: 0 (roadmap pending)
- Unmapped: 18 ⚠️

---
*Requirements defined: 2026-07-02*
*Last updated: 2026-07-02 after initial definition*
