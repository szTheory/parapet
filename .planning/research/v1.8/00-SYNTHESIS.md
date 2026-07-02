# Project Research Summary

**Project:** Parapet — v1.8 CI/CD Performance & DX
**Domain:** Released 1.x Elixir/Phoenix Hex library — GitHub Actions CI reshape + local DX
**Researched:** 2026-07-02
**Confidence:** MEDIUM (pipeline YAML patterns verified against official docs; Elixir/OTP lifecycle facts verified against hexdocs + endoflife.date; codebase findings are HIGH — direct inspection)

---

## Executive Summary

v1.8 is a pure pipeline and developer-experience milestone for a released, stable Elixir library. The public API, telemetry contract, and Hex package surface are all frozen — no source behavior changes, only CI workflow restructuring and local tooling. The goal is to make `main` a trustworthy green backstop, give contributors a single local gate command (`mix ci`), and cut redundant runner spend without introducing any false-green regressions on the v1.7 dual-prefix schema isolation that was just shipped.

The research is unanimous on the recommended approach: collapse the three-cell `lint` matrix to a single OTP-28 cell (lint-once) with Dialyzer PLT caching; reshape the `test` matrix to a single PR cell (OTP 28 + parapet) with the full four-cell set reserved for main pushes and a new nightly schedule; skip the `demo` smoke on PRs; add `concurrency: cancel-in-progress` scoped to PR events; introduce a `mix ci` alias that mirrors the portable lint+test gate; directly fix the two known-red tests (both are one-line changes); and annotate the five intentional concurrency-simulation sleeps while removing the three spurious telemetry sleeps and replacing one startup-race sleep with a proper barrier.

The primary risk in this milestone is the v1.7 dual-prefix false-green footgun: the `test` job's `_build` cache key MUST keep `${{ matrix.schema_prefix }}` and `mix compile --force` MUST stay in every prefix leg. Every CI change in v1.8 must be evaluated against this constraint. The secondary risk is a `release_gate` stability gap — adding `if: always()` with an explicit result-check script is required to guarantee the gate always reports a result to branch protection, even when upstream jobs fail or are skipped. Both risks have known, concrete mitigations documented in the research.

---

## Key Findings

### Workstream A: Caching & PLT (from 01-CI-PERFORMANCE.md)

The current pipeline has three compounding waste sources: Dialyzer rebuilds its PLT from scratch on every run (5–10 minutes per cell, running 3× across the OTP matrix); OTP-insensitive lint steps run 3× for zero additional coverage; and no `concurrency: cancel-in-progress` means force-pushed PRs queue redundant runs.

**Concrete findings:**
- PLT cache must live in `priv/plts/` (not `_build`), use the split `actions/cache/restore` + `actions/cache/save` pattern so the PLT is saved even if the `mix dialyzer` analysis step fails, and be keyed on `plt-${{ runner.os }}-${{ steps.beam.outputs.otp-version }}-${{ steps.beam.outputs.elixir-version }}-${{ hashFiles('**/mix.lock') }}`. The `steps.beam.outputs.*` values (resolved from `erlef/setup-beam`) are more precise than the `matrix.otp`/`matrix.elixir` range strings.
- `mix.exs` must add `plt_file: {:no_warn, "priv/plts/project.plt"}` to the `dialyzer:` config, and `/priv/plts/` must be gitignored.
- PLTs contain no schema-prefix information — a single PLT in the `lint-once` job is correct for all prefix legs. Do NOT add `schema_prefix` to the PLT cache key.
- Lint-once split: rename `lint` to `lint-once`, remove the 3-cell OTP matrix, pin to OTP 28. All OTP-insensitive steps (format, credo, hex.audit, docs, verify.public_api, operator UI diff, dialyzer) run exactly once. The `lint-once` `_build` key has no `schema_prefix` segment — correct, because lint never exercises the prefix-sensitive test paths.
- `release_gate` must add `if: always()` with an explicit inline script checking `needs.*.result` for `'success'`; without `if: always()`, a failed upstream job causes `release_gate` to be skipped rather than failing — a branch protection gap.
- Action SHA updates needed: `actions/checkout` (~v4.2.0 → v4.2.2, SHA `11bd71901bbe5b1630ceea73d27597364c9af683`) and `erlef/setup-beam` (~v1.15-1.17 → v1.24.1, SHA `54075bcc5e249e4758d363f27d099f55d843f124`). `actions/cache` is already at v4.3.0 (SHA `0057852bfaa89a56745cba8c7296529d2fc39830`).
- `concurrency: cancel-in-progress: ${{ github.event_name == 'pull_request' }}` at the workflow top level. Cancels all in-flight jobs for a PR push (both prefix legs simultaneously). Does NOT cancel main pushes. Safe for `release_gate` — the cancelled run's gate never completes; the new push starts fresh.

**v1.7 interaction (critical):** The `test` job `_build` cache key MUST retain `${{ matrix.schema_prefix }}` (or the `sp-${{ matrix.schema_prefix }}` variant). `mix compile --force` MUST stay in every test matrix cell. These are non-negotiable and must survive the v1.8 CI rewrite unchanged.

### Workstream B: OTP Matrix & Triggers (from 02-OTP-MATRIX-STRATEGY.md)

**OTP lifecycle facts (as of 2026-07-02):**
- OTP 26: crossed EOL May 26, 2026 — 37 days before this research. Drop it.
- OTP 27: security support until May 2027. New floor.
- OTP 28: released May 2025, security support until 2028. Mainstream production version.
- OTP 29: released May 2026 (7 weeks ago). Active support until 2029. New ceiling.

**Recommended version set:** OTP {27, 28, 29} with Elixir 1.20.2 (or latest 1.20.x patch). Elixir 1.20 requires OTP 27+, which aligns exactly with the new OTP floor. Elixir 1.19 no longer receives bug fixes; `mix.exs` already allows 1.20 via `~> 1.19`.

**PR vs main/nightly matrix composition:**
- PRs: 1 test cell (OTP 28 + parapet). Rationale: single representative cell proves "not obviously broken"; OTP-specific regressions are extremely rare between patch versions of the same major.
- main push + nightly: 4 test cells — OTP {27, 28, 29} × parapet + OTP 28 × public. The OTP axis and prefix axis are independent — no need to cross them fully.
- Demo job: skip on PRs (`if: github.event_name != 'pull_request'`). Run on main + nightly on OTP 28 only (down from 3-cell sweep).
- Add nightly schedule: `cron: '0 3 * * *'` (03:00 UTC).

**Cell count reduction:**
| Trigger | Current | v1.8 | Reduction |
|---------|---------|------|-----------|
| PR | 10 cells | 3 cells (lint + test + matrix-config) | -70% |
| main push | 10 cells | 7 cells (lint + 4 test + demo + matrix-config) | -30% |
| nightly | none | 7 cells | new |

**D-11 retirement:** The v1.7 accepted-prune decision (public prefix leg OTP-28-only) is now retired by design, not as a gap. With the full matrix running only on main+nightly, the structural cost concern that drove D-11 is gone. Remaining asymmetry (parapet × 3 OTP vs public × 1 OTP) is intentional: prefix correctness is compile-time and OTP-independent. Remove the D-11 tech-debt flag.

**`release_gate` on PRs where `demo` is skipped:** The gate script must treat `needs.demo.result == 'skipped'` as non-failing on PRs. The inline result-check script handles this explicitly: only `'failure'` on demo causes exit 1.

**Matrix resolver pattern:** A `matrix-config` setup job emits the test matrix JSON via `$GITHUB_OUTPUT` based on `github.event_name`. The `test` job consumes it via `matrix: ${{ fromJson(needs.matrix-config.outputs.test-matrix) }}`. Single workflow file, no duplication.

### Workstream C: Test Deflaking & Red-Test Fixes (from 03-TEST-DEFLAKING.md)

**10 `Process.sleep` call sites found in `test/` (grepped):**
- 3 in `exemplar_telemetry_test.exs`: spurious. `:telemetry.execute/3` is synchronous — handlers run inline, before return. Remove all three entirely.
- 5 in concurrency test bodies (`worker_concurrency_test.exs`, `executor_concurrency_test.exs` × 2, `executor_cluster_smoke_test.exs`, `confirm_concurrency_test.exs`): intentional work-simulation sleeps that keep the winning DB transaction open while the loser races the unique-constraint. Correct by design. Annotate with a `@concurrency_hold_ms` module attribute and a comment explaining the purpose.
- 1 in `claim_service_test.exs`: intentional gate-fn hold for the same race. Keep with a comment, or replace with a message-barrier if the team wants zero sleeps.
- 1 in `executor_cluster_smoke_test.exs:80`: startup race — `Process.sleep(200)` after `spawn/1` waiting for remote `ConcurrencyRepo` to register. Replace with a startup barrier: use `:erpc.call(node, ConcurrencyRepo, :start_link, [...])` directly (synchronous) or poll via `Process.whereis` until non-nil.

**Two known-red tests — direct fixes (not quarantine):**
- `DocsPhase33Test` line 102: asserts `readme =~ "make up-auto"`. The README was rewritten in v1.6/v1.7 — `make up-auto` became `make up`. Fix: change the assertion to `readme =~ "make up"`. One-line fix.
- `Telemetry.RecoveryActionTest` lines 141–153: `atom_count` delta check is contaminated by concurrent async tests on loaded CI nodes. The load-bearing guard (line 130: `assert_raise ArgumentError, fn -> String.to_existing_atom(poison) end`) already proves the correctness property. Fix: delete lines 141–153 and update the comment. 13-line deletion.
- Both fixes are trivial. Quarantine infrastructure (nightly lane, `ExUnit.configure(exclude:)`) is documented as a fallback only — use it if fixes are deferred to a later subphase.
- `test_helper.exs` ordering note: if quarantine is ever used, `ExUnit.configure(exclude: [:quarantine])` must come BEFORE `ExUnit.start()`.

### Workstream D: mix ci & CONTRIBUTING (from 04-MIX-CI-DX.md)

**Recommended `mix ci` alias (8 portable steps, in order):**
1. `format --check-formatted` — fastest, zero compile
2. `compile --warnings-as-errors` — full compile; gates everything after
3. `compile --no-optional-deps --warnings-as-errors` — optional-dep cleanliness
4. `credo --strict` — static analysis on warm build
5. `hex.audit` — lightweight network check before expensive steps
6. `dialyzer` — slowest step; last in lint group
7. `test` — full suite (default prefix, quarantine excluded via `test_helper.exs`)
8. `verify.public_api` — fast on warm build; calls `Mix.Task.run("compile")` internally

**Anti-drift mechanism:** Restructure `ci.yml` so the lint job runs `mix ci` for the portable subset, then adds the two non-portable steps after (`MIX_ENV=dev mix docs --warnings-as-errors` and the operator UI manifest diff bash command). This makes `mix.exs` the single source of truth for the portable gate — adding a step to `mix ci` automatically gates it in CI.

**Known `mix ci` deltas from full CI (document in CONTRIBUTING.md):**
- Does not run `mix docs --warnings-as-errors` (requires `MIX_ENV=dev`; `mix ci` runs under `MIX_ENV=test`)
- Does not run the operator UI screenshot manifest diff (requires Chromium + running demo app)
- Runs only the default `parapet` schema prefix; the `public` prefix leg is CI-only

**CONTRIBUTING.md update:** Replace the "Local proof commands" section with `mix ci` instructions, first-run PLT warning (2–5 minutes), `mix deps.get` prerequisite, the delta callout, and the quarantine-test note.

**Deliberately omitted from `mix ci`:** `deps.get` (local env already has deps; running it silently could mask lock drift), `compile --force` (only meaningful across matrix prefix legs), `docs --warnings-as-errors` (MIX_ENV conflict).

---

## Recommended Workstreams & Build Order

The five workstreams have a clear dependency graph. The recommended build order within a milestone:

```
Phase 1: Test fixes + sleep triage
  ↓ (green suite is the premise for "CI is the backstop")
Phase 2: mix ci alias + CONTRIBUTING
  ↓ (mix ci must reflect the final gated step list, which depends on the CI shape)
  ↓ (but mix ci's portable steps are independent of CI structure, so can start here)
Phase 3: Caching & lint-once + release_gate hardening
  ↓ (lint-once restructure changes what steps exist; mix ci calls lint-once's portable subset)
Phase 4: Matrix & triggers (OTP set, PR vs main/nightly, demo skip, nightly schedule)
  ↓ (matrix reshape builds on the lint-once and release_gate work from Phase 3)
Phase 5: Action SHA updates + D-11 retirement docs
```

**Cross-dependencies:**
- `mix ci` (Phase 2) can be defined before the CI structure changes (Phase 3) because it mirrors the portable steps regardless of how ci.yml organizes them. However, `ci.yml` restructuring to call `mix ci` (anti-drift mechanism) happens in Phase 3.
- `release_gate` changes (Phase 3) must update the `needs:` list from `[lint, test, demo]` to reflect the renamed/restructured jobs before the matrix reshape (Phase 4) finalizes job names.
- The matrix-config setup job (Phase 4) introduces `needs: [matrix-config]` on the `test` job — this must be wired after the job exists.
- PLT caching (Phase 3) requires the `mix.exs` `plt_file:` change and the `.gitignore` entry before any CI run can populate the cache.
- The two red-test fixes (Phase 1) are prerequisites for the "bare `mix test` is green" claim that backs the `mix ci` and CI green-by-default goals.

**Scope that is explicitly out of bounds for every phase:**
- Changing `${{ matrix.schema_prefix }}` in the `test` job `_build` cache key
- Removing `mix compile --force` from any test matrix cell
- Modifying `release_gate` job name (only its `needs:` list and step logic change)
- Any change to public API, telemetry events, or Hex package surface

---

## Decision Points

### DP-1: Elixir 1.19 → 1.20.2 floor bump timing

**The question:** CI currently pins `elixir: '1.19.0'`. Research recommends bumping to `1.20.2` (or latest 1.20.x patch at implementation time).

**Why now (recommended):**
- Elixir 1.20 requires OTP 27+, which aligns exactly with the new OTP floor drop. Testing 1.19 + OTP 29 would be outside 1.19's official support window (1.19 supports OTP 26–28 only).
- Elixir 1.19 is security-patches-only; 1.20 receives bug fixes. Testing 1.19 gives less meaningful signal per runner-minute.
- `mix.exs` `elixir: "~> 1.19"` already allows 1.20 — no semver change to the library.
- Adopters on Elixir 1.19 + OTP 26 are running an EOL OTP stack; the library is not obliged to CI-prove that combination.

**Why hold at 1.19.x (alternative):**
- Adopters on Elixir 1.19 + OTP 27/28 (still supported) are a real cohort. Dropping CI coverage of 1.19 means regressions affecting that cohort go undetected.
- The cost is pinning to `1.19.5` (latest patch) and accepting that OTP 29 testing is outside 1.19's official support window.

**Researcher recommendation: upgrade to 1.20.2 in v1.8.** Rationale: the OTP 27 floor drop and Elixir 1.20's OTP 27+ requirement are a natural joint transition. Splitting them creates an awkward 1.19+OTP29 cell that is explicitly outside the compatibility matrix. If the team prefers a softer transition, hold at `1.19.5` and upgrade Elixir in v1.9.

---

### DP-2: Red tests — fix directly vs quarantine

**The question:** `DocsPhase33Test` and `Telemetry.RecoveryActionTest` are pre-existing reds documented in the v1.7 audit. The user pre-decided to make bare `mix test` green in v1.8. How?

**Fix directly (recommended):**
- `DocsPhase33Test`: change `readme =~ "make up-auto"` to `readme =~ "make up"`. One line.
- `RecoveryActionTest`: delete the `atom_count` delta check (lines 141–153). The `assert_raise ArgumentError, fn -> String.to_existing_atom(poison) end` on line 130 is the load-bearing guard and is unaffected. Thirteen lines deleted.
- Both fixes are clearly correct and have no edge cases. Total effort: ~15 minutes.
- Quarantine infrastructure is unnecessary overhead for problems with 5-minute fixes.

**Quarantine (fallback):**
- Add `@tag :quarantine` + `@tag quarantine_reason:` to each failing test.
- Add `ExUnit.configure(exclude: [:quarantine])` BEFORE `ExUnit.start()` in `test_helper.exs`.
- Optionally add a nightly non-gating workflow for visibility.
- Use only if the direct fixes are deferred to a later subphase for sequencing reasons.

**Researcher recommendation: fix directly.** The v1.8 "green-suite premise" is the stated goal; fixes satisfy it with minimal overhead.

---

### DP-3: Trim the `demo` job to single OTP leg

**The question:** Currently the `demo` job runs a 3-cell OTP matrix on every PR. Research recommends skipping on PRs entirely and running on OTP 28 only (single cell) on main + nightly.

**Recommendation: yes, trim.** Demo smoke exercises `mix ecto.create`, `mix ecto.migrate`, `seeds.exs`, and `--only smoke` tests — all OTP-independent and prefix-independent. Running 3× per OTP on every PR is expensive for low signal. The smoke test is most valuable as a post-merge and nightly check. PR correctness is already validated by the `test` job.

**Risk:** A demo-app breakage that only manifests on OTP 27 or 29 won't be caught by a PR run. Mitigation: main push and nightly runs cover the full test matrix; demo runs on OTP 28 which is the mainstream version. Acceptable trade-off.

---

### DP-4: Retain or drop the cross-OTP `compile` matrix leg

**The question:** Research describes an optional `compile-matrix` job that runs `mix compile --warnings-as-errors` across OTP {27, 28, 29} to catch OTP-version-specific compiler warnings. Without it, the `lint-once` job only compiles on OTP 28.

**Recommendation: drop the compile-matrix for v1.8.** OTP-version-specific warnings are very rare in practice between patch versions of the same major. Running dialyzer on OTP 28 (the highest version) catches the most type issues. The PR cell (OTP 28 + parapet) in the test matrix also compiles. Adding a separate compile-matrix job adds complexity for marginal signal. Revisit in v1.9 if an OTP-specific warning is missed.

**If retained:** add `compile-matrix` to `release_gate`'s `needs:` list.

---

## Invariants & Risks

### Non-negotiable invariants (must not be violated by any v1.8 change)

| Invariant | Why it matters | What breaks if violated |
|-----------|---------------|------------------------|
| `${{ matrix.schema_prefix }}` in `test` job `_build` cache key | `@schema_prefix` is compile-time; without it the `public` leg silently reuses the `parapet` build artifact | False-green: `public` prefix contract test passes with wrong compiled prefix |
| `mix compile --force` in every `test` matrix cell | Belt-and-suspenders: guarantees compile_env is re-baked for each prefix leg even on cache hit | False-green: stale cache hit could produce a build where `@schema_prefix` does not match the current leg |
| `release_gate` job name unchanged | Branch protection references the job name `release_gate`; renaming it breaks the required check | PRs can merge without a CI gate |
| Public API + telemetry contract frozen | v1.8 is DX-only; no source behavior changes | Semver violation |

### Risks and mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| PLT `plt_file:` path mismatch with CI cache path | HIGH | Set `plt_file: {:no_warn, "priv/plts/project.plt"}` in `mix.exs` and cache `priv/plts` in CI exactly |
| `release_gate` skipped on upstream failure (current bug) | HIGH | Add `if: always()` + inline result-check script |
| OTP 29 + Elixir 1.19 is outside the official compatibility matrix | MEDIUM | Upgrade Elixir to 1.20.2 (recommended) or drop OTP 29 from CI |
| PR matrix trimmed to 1 cell misses OTP 27/29 bugs | LOW | Main push and nightly runs cover the full matrix; OTP regressions are caught within 24 hours |
| Concurrency-simulation sleeps misidentified as spurious | LOW | 5 intentional sleeps are inside runbook/callback bodies that are the subject of the race, not in test coordination logic. Keep with annotation. |
| mix ci / ci.yml drift | LOW | Structural anti-drift: CI lint job runs `mix ci` for the portable subset; the alias is the single source of truth |

---

## Implications for Roadmap

### Suggested phase structure (4 phases)

**Phase 1: Test Suite Baseline**
**Rationale:** The "CI is the enforcement backstop" claim requires a green test suite. Everything else in v1.8 is undermined if `mix test` is red. This must come first so all subsequent phases build on a provably green baseline.
**Delivers:**
- Direct fix for `DocsPhase33Test` (1-line change)
- Direct fix for `Telemetry.RecoveryActionTest` (13-line deletion)
- Remove 3 spurious `Process.sleep` calls from `exemplar_telemetry_test.exs`
- Replace startup-race `Process.sleep(200)` in `executor_cluster_smoke_test.exs:80` with barrier pattern
- Annotate 5 intentional concurrency-simulation sleeps with `@concurrency_hold_ms` module attribute + explanatory comment
- Confirm `mix test` exits 0 with no spurious flakes
**Research flag:** No deeper research needed — all findings are grounded in direct codebase inspection (HIGH confidence).

---

**Phase 2: Local DX — mix ci & CONTRIBUTING**
**Rationale:** Define the local gate before restructuring CI. The alias's portable step list is independent of CI's internal job structure. Contributors need this in place as soon as the suite is green.
**Delivers:**
- `mix ci` alias in `mix.exs` (8 steps in defined order)
- `.gitignore` entry for `/priv/plts/` (prerequisite for PLT caching in Phase 3)
- `mix.exs` `dialyzer: [plt_file: {:no_warn, "priv/plts/project.plt"}]` config (prerequisite for Phase 3 PLT cache path)
- Updated CONTRIBUTING.md "Local proof commands" section
- Document the three known deltas from full CI (docs, operator UI diff, public prefix leg)
**Research flag:** No deeper research needed — derived entirely from first-party project files (HIGH confidence).

---

**Phase 3: CI Caching & Lint-Once + release_gate Hardening**
**Rationale:** This is the highest-impact structural change. PLT caching, lint-once split, and `release_gate` hardening are tightly coupled: lint-once determines the job names that `release_gate` depends on; PLT caching lives in the lint-once job; the anti-drift restructuring (CI calls `mix ci`) happens here.
**Delivers:**
- Rename `lint` → `lint-once` (or equivalent: strip the OTP matrix from the existing lint job)
- PLT split-cache pattern in `lint-once` (`actions/cache/restore` + `actions/cache/save`, keyed on OTP+Elixir+mix.lock, path `priv/plts`)
- `release_gate` updated: `needs: [lint-once, test, demo]`, `if: always()`, inline result-check script treating `demo` skipped as non-failing
- `ci.yml` lint job restructured to call `mix ci` for the portable subset, then append the two non-portable steps
- Action SHA updates for `actions/checkout` (→ v4.2.2) and `erlef/setup-beam` (→ v1.24.1) across all jobs
- `concurrency: cancel-in-progress: ${{ github.event_name == 'pull_request' }}` at workflow top level
**Avoids:** v1.7 false-green footgun — `test` job `_build` key and `mix compile --force` are untouched
**Research flag:** No deeper research needed — YAML is implementation-ready in 01-CI-PERFORMANCE.md. Verify action SHAs at implementation time (they may advance).

---

**Phase 4: OTP Matrix Reshape + Nightly Schedule + D-11 Retirement**
**Rationale:** The matrix reshape is last because it builds on the lint-once job name (Phase 3) and the `release_gate` logic that handles demo-skipped on PRs (Phase 3). The Elixir version bump (1.19 → 1.20.2) is the adopter-facing decision point in this phase.
**Delivers:**
- `matrix-config` setup job emitting PR vs main/nightly matrix JSON
- OTP set updated to {27, 28, 29} (drop OTP 26, add OTP 29)
- Elixir pin updated from `1.19.0` to `1.20.2` (or `1.19.5` if conservative path chosen — see DP-1)
- Test matrix: PR → 1 cell (OTP 28 + parapet); main+nightly → 4 cells (OTP {27,28,29} × parapet + OTP 28 × public)
- Demo job: `if: github.event_name != 'pull_request'`, single OTP 28 cell
- Nightly schedule added: `cron: '0 3 * * *'`
- D-11 tech-debt flag retired: update `.planning/milestones/v1.7-MILESTONE-AUDIT.md`, update `PROJECT.md` Key Decisions, update the `ci.yml` comment explaining the include structure
**Research flag:** Confirm OTP 29 + Elixir 1.20 compatibility with current `mix.exs` deps at implementation time (MEDIUM confidence — versions verified against hexdocs but ecosystem deps may have constraints).

---

### Phase ordering rationale

- Phase 1 first because the green-suite premise is the foundation the entire milestone rests on.
- Phase 2 before Phase 3 because `mix.exs` changes (PLT path, alias definition) need to exist before the CI restructuring that calls `mix ci`.
- Phase 3 before Phase 4 because the lint-once job name and `release_gate` logic (demo-skipped handling) must be in place before the matrix-config job references them.
- All four phases keep the `test` job `_build` cache key and `mix compile --force` untouched throughout — this is a constant constraint, not a phased concern.

### Research flags

Needs deeper research during planning:
- **Phase 4:** Confirm OTP 29 support in all transitive deps at implementation time. OTP 29 was released 7 weeks before research date; some deps may not have explicit OTP 29 compatibility declarations yet.
- **Phase 4 (DP-1):** Elixir 1.20.2 bump decision must be made by the user/roadmapper before Phase 4 PLAN.md is written — it affects the Elixir pin in every job.

Standard patterns (no phase-level research needed):
- **Phase 1:** Direct codebase inspection — all findings are HIGH confidence.
- **Phase 2:** Derived from first-party project files — all findings are HIGH confidence.
- **Phase 3:** YAML is implementation-ready in 01-CI-PERFORMANCE.md. Verify action SHAs at implementation time only.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| PLT caching patterns | MEDIUM | Verified against dialyxir official docs and community reports; YAML is implementation-ready |
| `_build` / deps caching + v1.7 prefix interaction | HIGH | Grounded in v1.7 research artifacts and ci.yml direct inspection |
| `release_gate` `if: always()` requirement | MEDIUM | Verified against GitHub Actions docs and community discussions |
| OTP 26 EOL date | MEDIUM | Verified via endoflife.date + erlang.org; community tracker well-maintained |
| Elixir 1.20 OTP compatibility window | MEDIUM | Verified via hexdocs.pm/elixir/compatibility-and-deprecations.html |
| Two red-test root causes | HIGH | Direct codebase inspection — both confirmed by running the tests |
| `Process.sleep` call site triage | HIGH | Grepped `test/` exhaustively; implementation under test read directly |
| `mix ci` alias design | HIGH | Derived entirely from ci.yml and mix.exs direct inspection |
| Action SHA values | MEDIUM | Verified against GitHub release pages as of 2026-07-02; may advance before implementation |
| OTP 29 ecosystem dep compatibility | LOW | OTP 29 released 7 weeks before research; explicit compatibility declarations may lag |

**Overall confidence:** MEDIUM-HIGH. The codebase-grounded findings (red-test fixes, Process.sleep triage, mix ci steps) are HIGH. The pipeline patterns are MEDIUM — well-sourced but YAML is not yet run against the actual repo.

### Gaps to address

- **OTP 29 transitive dep compatibility:** Run `mix deps.unlock --all && mix deps.get` against OTP 29 at Phase 4 start to confirm no dep constraints block it.
- **Action SHA currency:** Re-verify `actions/checkout`, `erlef/setup-beam` SHAs at Phase 3 implementation time — they may have advanced since 2026-07-02.
- **Elixir 1.20.2 + existing CI helper scripts:** Confirm the operator UI screenshot capture script and demo seed scripts work under 1.20 (no 1.19-specific assumptions). Likely fine; note for Phase 4.
- **`test_helper.exs` ordering:** If quarantine path is taken instead of direct fixes, verify `ExUnit.configure` precedes `ExUnit.start()` — current file has `ExUnit.start()` on line 1 and would need reordering.

---

## Sources

### Primary (HIGH confidence — direct project artifact inspection)

- `.github/workflows/ci.yml` — current job structure, cache keys, action SHAs, matrix dimensions, release_gate design
- `mix.exs` — existing dialyzer config, empty `aliases/0`, dep versions
- `test/parapet/docs_phase_33_test.exs` — DocsPhase33Test root cause confirmed
- `test/parapet/telemetry/recovery_action_test.exs` — RecoveryActionTest root cause confirmed
- `lib/parapet/metrics/exemplar_telemetry.ex` + `exemplar_store.ex` — confirmed synchronous telemetry dispatch
- `test/` (grep: `Process.sleep`) — 10 call sites enumerated and classified
- `.planning/milestones/v1.7-MILESTONE-AUDIT.md` — D-11 context, both pre-existing reds documented
- `.planning/research/v1.7/04-TEST-STRATEGY.md` — dual-prefix `_build` false-green analysis (F1), `mix compile --force` requirement
- `.planning/research/v1.7/00-SYNTHESIS.md` — dual-prefix CI matrix decisions
- `CONTRIBUTING.md` — current guidance (confirms no `mix ci` mention; confirms outdated local proof commands)
- `lib/mix/tasks/verify.public_api.ex` — only `verify.*` task; confirmed no other `verify.*` tasks exist

### Secondary (MEDIUM confidence — official docs and verified community sources)

- [dialyxir official GitHub Actions docs](https://github.com/jeremyjh/dialyxir/blob/master/docs/github_actions.md) — PLT cache path (`priv/plts`), split restore/save pattern
- [GitHub Actions: Control workflow concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency) — `cancel-in-progress` expression support
- [GitHub community: Matrix job status check for required checks](https://github.com/orgs/community/discussions/26822) — `needs.job.result` aggregation, `if: always()` requirement
- [Compatibility and deprecations — Elixir v1.20.x](https://elixir.hexdocs.pm/compatibility-and-deprecations.html) — OTP compatibility table
- [Erlang | endoflife.date](https://endoflife.date/erlang) — OTP lifecycle dates
- [Support, Compatibility, Deprecations — Erlang System Documentation v29.0.1](https://www.erlang.org/doc/system/misc.html) — official OTP support policy
- [GitHub Actions workflow syntax — GitHub Docs](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions) — `on:`, `strategy.matrix`, `if:`
- [actions/cache releases](https://github.com/actions/cache/releases) — v4.3.0 SHA `0057852bfaa89a56745cba8c7296529d2fc39830`
- [actions/checkout releases](https://github.com/actions/checkout/releases) — v4.2.2 SHA `11bd71901bbe5b1630ceea73d27597364c9af683`
- [erlef/setup-beam releases](https://github.com/erlef/setup-beam/releases) — v1.24.1 SHA `54075bcc5e249e4758d363f27d099f55d843f124`
- [ExUnit docs](https://ex-unit.hexdocs.pm/ExUnit.html) — `exclude` option, `@tag`, quarantine patterns
- [`:telemetry_test` module](https://telemetry.hexdocs.pm/telemetry_test.html) — `attach_event_handlers/2`, synchronous handler model

### Tertiary (LOW confidence — needs validation at implementation time)

- [Dynamic matrix in GitHub Actions — oneuptime blog](https://oneuptime.com/blog/post/2025-12-20-dynamic-matrix-github-actions/view) — `fromJSON` matrix pattern (community source; pattern is widely used but this specific source is LOW)
- [Elixir v1.20.0 released — ElixirForum](https://elixirforum.com/t/elixir-v1-20-0-released/75566) — release date, OTP 27+ requirement (cross-checked against hexdocs but forum source)
- OTP 29 ecosystem dep compatibility — not yet verifiable; research date is 7 weeks post-OTP-29 release

---

*Research completed: 2026-07-02*
*Ready for roadmap: yes*
*Synthesized from: 01-CI-PERFORMANCE.md, 02-OTP-MATRIX-STRATEGY.md, 03-TEST-DEFLAKING.md, 04-MIX-CI-DX.md*
