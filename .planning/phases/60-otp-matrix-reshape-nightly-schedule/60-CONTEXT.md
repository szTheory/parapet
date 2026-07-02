# Phase 60: OTP Matrix Reshape & Nightly Schedule - Context

**Gathered:** 2026-07-02 (assumptions mode + deep decision-fork research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Reshape the CI test matrix so **pull requests get one fast representative cell** while
**push-to-`main` and a nightly cron get the full multi-OTP × dual-prefix matrix**; retire
EOL OTP 26 / Elixir 1.19 from CI (bump to OTP {27,28,29} × Elixir 1.20.2); trim the `demo`
smoke job to a single OTP-28 cell skipped on PRs; and formally close the v1.7 **D-11**
CI-coverage tech-debt flag.

Requirements: **MATRIX-01, MATRIX-02, MATRIX-03, MATRIX-04**.

**In scope:** `.github/workflows/ci.yml` (matrix reshape, `matrix-config` resolver, `schedule`
trigger, demo gating, `release_gate` truth-table hardening, concurrency-group fix, cache-key
bumps), the adjacent `release-please.yml` toolchain pin, D-11 retirement docs, and the
factually-stale README "CI validates…" sentence.

**Out of scope (deferred):** failure alerting / issue-on-nightly-failure; `paths-ignore`
docs-only PR skipping; the `mix.exs` `~> 1.19` floor bump (a separate v1.9+ decision, VER-01);
any change to the `test` job body's compile/isolation logic beyond what the reshape requires.
</domain>

<decisions>
## Implementation Decisions

Every decision below is backed by a dedicated research fork (6 subagents: 4 decision-forks +
1 sibling-lib/DNA pressure-test + 1 mechanical-trap sweep). Live-verified version facts as of
2026-07-02. Downstream planner should treat these as locked.

### D-01 · Elixir / OTP version set
- **D-01a:** Pin **Elixir `1.20.2` exact** (or the latest `1.20.x` patch that exists at
  implementation time — pin the exact resolved three-part string, **never** a floating `1.20`).
  *Live-verified:* Elixir 1.20.2 exists, requires OTP 27+, compatible with OTP 27/28/29.
- **D-01b:** OTP set **`{27.x, 28.x, 29.x}`** — drop OTP 26 (EOL 2026-05-26, verified), keep 28
  (mainstream, supported to 2028), add 29 (released 2026-05-13, verified; ecosystem deps are
  pure-Elixir/BEAM with no OTP-29-removed-API dependence).
- **D-01c:** **Do NOT change `mix.exs` `elixir: "~> 1.19"`.** CI pin ≠ advertised floor. The
  library still supports 1.19 adopters; CI proves the *upper* edge. Dropping the declared floor
  for a pure-DX release would be semver-hostile (forces every 1.19 adopter to upgrade for zero
  benefit). Floor-bump is a deliberate future decision, not a side effect of this phase.
- **D-01d:** Do **NOT** add `version-type: strict` to `setup-beam`. `strict` errors against
  `.x` OTP ranges (it demands an exact per-field version); default `loose` + the exact
  `1.20.2` string already resolves reproducibly and is what ecto/oban/req do. *(Resolves the
  Fork-A/pressure-test "add strict" recommendation against the mechanical incompatibility —
  loose wins.)*
- **D-01e:** Drop the standalone "OTP-29 `mix deps.get` compat check" idea — it is redundant on
  main/nightly (OTP 29 is already a full test cell there) and absent on PR, so it gates
  nothing. OTP-29 signal comes from the real matrix cell.

### D-02 · Event-conditional matrix mechanism
- **D-02a:** Add a **`matrix-config` setup job** that emits **single-line** JSON
  (`{"include":[...]}` shape, not a bare array) to `$GITHUB_OUTPUT`, branched on
  `github.event_name`. The `test` job gains **`needs: [matrix-config]`** and consumes
  `matrix: ${{ fromJson(needs.matrix-config.outputs.test-matrix) }}`; keeps `fail-fast: false`.
  - **PR →** 1 cell: `{otp: 28.x, schema_prefix: parapet}` (Elixir 1.20.2).
  - **push:main / schedule →** 4 cells: OTP {27,28,29}×`parapet` + OTP 28×`public`.
- **D-02b:** Inline `include`/`exclude` conditionals were **rejected** — a `strategy.matrix` is
  static at parse time and cannot *subtract* cells by `event_name`. The resolver job is the
  only single-file mechanism that yields PR=1 / main+nightly=4. Reusable-workflow and
  two-file approaches rejected (invariant-duplication + dual `release_gate` name risk).
- **D-02c (INVARIANT — carried from Phase 59, non-negotiable):** the `test` `_build` cache key
  **retains `${{ matrix.schema_prefix }}`** and every cell **retains `mix compile --force`**.
  The resolver only decides *which* `{otp, schema_prefix}` cells exist — never *how* they
  compile. Dropping either re-opens the v1.7 dual-prefix false-green footgun.
- **D-02d:** Each JSON `include` object **must carry all three keys** (`elixir`, `otp`,
  `schema_prefix`) or downstream `${{ matrix.* }}` interpolations silently resolve to empty
  string — e.g. a blank `PARAPET_SCHEMA_PREFIX` runs tests against the wrong schema (silent
  false-green). Emit `elixir: '1.20.2'` in every entry.
- **D-02e:** Give `matrix-config` a self-documenting `name:` (e.g.
  `matrix-config (PR=trimmed, main+nightly=full)`) so the Checks UI explains itself.

### D-03 · Triggers, demo gating & release_gate stability
- **D-03a:** Add `schedule: - cron: '17 3 * * *'` (03:17 UTC). Off-the-hour deliberately —
  GitHub delays top-of-hour crons under load; `:17` is already this repo's house convention
  (rulestead `verify-published-release.yml` uses `17 6 * * *`). *(Intentionally refines the
  roadmap SC-4 illustrative `'0 3 * * *'` — verifier should accept `17 3`.)*
- **D-03b:** Skip `demo` on PR via job-level **`if: github.event_name != 'pull_request'`**
  (this correctly *includes* `schedule` and `push`). Demo becomes a **plain job** (no
  `strategy`/`matrix`) with literal `elixir-version: '1.20.2'` / `otp-version: '28.x'`. Keep
  `demo` in `release_gate.needs` so the gate can inspect its result.
- **D-03c:** `release_gate` keeps **`if: always()`** (a *skipped* required check reads green in
  branch protection — catastrophic for a 0-review repo). Result truth table:

  | upstream `result` | `lint-once` | `test` | `demo` |
  |---|---|---|---|
  | `success` | PASS | PASS | PASS |
  | `skipped` | **BLOCK** | **BLOCK** | **PASS** (legit on PR only) |
  | `failure` | **BLOCK** | **BLOCK** | **BLOCK** |
  | `cancelled` | **BLOCK** | **BLOCK** | **BLOCK** |

  → strict `= success` allowlist for `lint-once`/`test`; `success|skipped` pass (else block)
  for `demo`. `cancelled` blocks everywhere (a naive `== failure` check on demo would leak a
  cancelled run — closed). Add `matrix-config` to `release_gate.needs` for a clear message if
  the resolver fails.
- **D-03d:** Add `github.event_name` to the **`concurrency.group`** key so a nightly and a
  same-time `main` push don't serialize into one lane:
  `group: ${{ github.workflow }}-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}`.
  `cancel-in-progress: ${{ github.event_name == 'pull_request' }}` stays PR-only (unchanged).
- **D-03e:** Keep job names **`lint-once`** and **`release_gate`** verbatim (branch-protection
  required-check names — renaming silently disables the backstop). `lint-once` keeps **no
  `if:`** so it runs on all three triggers (needed by the gate on nightly).

### D-04 · D-11 tech-debt retirement (dated, append-only, single-sourced)
- **D-04a:** Retire via **dated append-only** resolution notes — never rewrite the frozen v1.7
  audit body. Canonical note wording:
  > `RESOLVED 2026-07-02 (Phase 60 / MATRIX-02): retired by design, not by fix. The full
  > matrix now runs on main + nightly only, so the original solo-maintainer CI-budget reason
  > for the prune is gone. The remaining parapet ×3-OTP / public ×1-OTP asymmetry is
  > intentional — prefix resolution is compile-time and OTP-independent, so one OTP on the
  > public leg is complete signal. See PROJECT.md Key Decisions.`
- **D-04b:** **`.planning/PROJECT.md` Key Decisions = the single canonical explanation** (add
  one row; resolve/annotate the existing `⚠️ Revisit` v1.7-debt row). Every other location
  carries only a one-line dated **pointer**, never a re-derived rationale (anti-drift).
- **D-04c:** Minimal-complete edit set (4 spots): PROJECT.md (canonical) · v1.7-MILESTONE-
  AUDIT.md **register row only** (~line 165; leave frozen frontmatter ~line 22 and Seam-7 prose
  ~line 132 untouched) · MILESTONES.md (~line 31 pointer) · `ci.yml` comment.
- **D-04d:** The `ci.yml` asymmetry-explainer comment anchors on the **`matrix-config` resolver
  job** (where the cells are now defined), **not** the old static `include:` block (which D-02
  dissolves). Draft:
  ```
  # Matrix is intentionally asymmetric: parapet leg × {27,28,29} OTP, public leg × 28 only.
  # Do NOT "balance" it by adding OTP cells to the public leg — prefix resolution is
  # compile-time (@schema_prefix) and OTP-independent, so one OTP is complete signal.
  # (Retires the v1.7 D-11 coverage-prune; see PROJECT.md Key Decisions.)
  ```
- **D-04e:** **Do NOT touch `STATE.md` line 114** — its "D-11" is an *unrelated* decision (a
  `@concurrency_hold_ms` annotation), not the CI-coverage prune. A grep-and-replace would
  corrupt an unrelated record.

### D-05 · Support-surface honesty & contributor DX
- **D-05a (R1):** Add a one-line comment at the OTP-29 cell (and a compat-doc note) clarifying
  that OTP 29 requires Elixir ≥ 1.20 — *"the OTP-29 cell proves forward-compat under 1.20, not
  that a `~> 1.19` adopter can run OTP 29."* Elixir 1.19 tops out at OTP 28; without this a cold
  reader infers a combination that cannot exist (the DNA "support-surface honesty" footgun).
- **D-05b (R2):** Add a 4th bullet to CONTRIBUTING.md's existing "Local vs CI deltas" list:
  *PRs run a single trimmed cell (OTP 28 × `parapet`); the full matrix runs on merge to `main`
  + nightly; a green PR is not full-matrix proof — `release_gate` on `main` is the real
  multi-OTP gate.*

### D-06 · Adjacent stale-toolchain & doc fixes
- **D-06a:** Bump `release-please.yml` `publish-hex` job pins `1.19.0`/`27.2` → `1.20.2`/`28.x`
  (its setup-beam SHA stays) so the published Hex artifact is built on a toolchain CI actually
  tests.
- **D-06b:** Fix `README.md` line ~27 ("CI validates on Elixir 1.19 across OTP 26, 27, and 28")
  → the new set. **Leave** README's *support* matrix (~line 24, OTP 26–28) and CONTRIBUTING's
  `Elixir 1.19+` floor (~line 77) — those are adopter-facing support claims, not CI-pin facts.

### Claude's Discretion
- Exact bash phrasing of the `release_gate` result checks and the resolver's `if/else`
  heredoc, provided the D-03c truth table and D-02a/d shape hold.
- Whether the resolver emits Elixir in each include entry or sets it once as a job-level env —
  as long as `${{ matrix.* }}` interpolations never resolve empty (D-02d).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.github/workflows/ci.yml` — the file being reshaped (current: lint-once, test, demo,
  release_gate; concurrency at 9-12; PLT cache at 38-43; test `_build` key at 104-105).
- `.github/workflows/release-please.yml` — publish-hex toolchain pin (D-06a).
- `.planning/research/v1.8/02-OTP-MATRIX-STRATEGY.md` — recommended matrix/resolver YAML +
  release_gate stability analysis + DP-1. **Note:** its drafted resolver JSON is *multi-line* —
  that corrupts `$GITHUB_OUTPUT`; emit **single-line** (D-02a).
- `.planning/research/v1.8/00-SYNTHESIS.md` — Phase 4 delivery list + D-11 retirement plan.
- `.planning/research/v1.8/01-CI-PERFORMANCE.md` — caching/lint-once context.
- `.planning/PROJECT.md` — Key Decisions table (D-11 canonical home, D-04b).
- `.planning/milestones/v1.7-MILESTONE-AUDIT.md` — D-11 flag spots (D-04c).
- `prompts/parapet-engineering-dna-from-sibling-libs.md`,
  `prompts/prior-art/rulestead-release-engineering-and-ci.md`,
  `prompts/sre-best-practices-solo-founder-deep-research.md` — house CI conventions
  (`:17` cron, thin aggregate gate, stable job ids, support-surface honesty).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Existing `release_gate` aggregator** (`ci.yml:166-193`, `if: always()` + per-job result
  checks, Phase 59) — extend its truth table (D-03c), don't rebuild it.
- **Existing concurrency block** (`ci.yml:9-12`) — `cancel-in-progress` already PR-only;
  only the group key changes (D-03d).
- **Existing PLT split-cache** (`ci.yml:38-43`, Phase 59 "D-13") — reuse; only version tokens
  in the key change (`1.19.0` → `1.20.2`).
- **All action SHA pins** (checkout `df4cb1c…`, setup-beam `54075bcc…`, cache `caa29612…`,
  release-please pins) — Phase 59 "D-13" commits, **reuse unchanged**. `matrix-config` is a
  bare `run:` step (no external action → no new SHA to pin).

### Established Patterns
- Single-file CI workflow; stable required-check names; SHA-pinned actions; Postgres service
  container per test/demo job; `mix ci` alias called by lint-once (Phase 58).
- v1.7 dual-prefix isolation: `PARAPET_SCHEMA_PREFIX` env + `schema_prefix` in `_build` key +
  `mix compile --force` — **the load-bearing false-green guard** (D-02c).

### Integration Points / Mechanical checklist (from the trap sweep — planner guardrails)
- **Cache-key literal edits (lint-once only):** `ci.yml` lines 30, 31, 36, 37, 42, 43 —
  swap `1.19.0` → `1.20.2` (line 25 `otp-version: '28.x'` stays; PLT key at 42 has *reversed*
  otp-then-elixir order — change the `1.19.0` token, not `28.x`).
- **Interpolated cache keys (test 98/99/104/105, demo 147/148/153/154):** no literal edit;
  flow from the matrix — **but 104/105 MUST keep `${{ matrix.schema_prefix }}`** (D-02c).
- **setup-beam:** line 24 Elixir `1.19.0`→`1.20.2`; test 92-93 unchanged (from matrix);
  demo 141-142 → literals (D-03b). No `version-type: strict` (D-01d).
- **Static base+include matrix (lines 62-69)** → replaced by include-only `fromJson`; no
  residual `matrix.elixir/otp/schema_prefix` base axis left behind (R3/D-02).
- **Risk ranking (fix-or-break):** (1) demo `skipped`→blocks-all-PRs if release_gate not
  hardened; (2) include cells missing a key → blank-interp false-green; (3) `_build` key losing
  `schema_prefix`; (4) stale `1.19.0` in lint-once cache lines; (5) README:27 false sentence.
</code_context>

<specifics>
## Specific Ideas

- Nightly cron `17 3 * * *` (not `0 3`) — dodge GitHub top-of-hour delay, match house `:17`
  convention.
- `release_gate` demo branch uses a `case "$demo" in success|skipped) : ;; *) fail ;; esac`
  form (or equivalent) so `cancelled` blocks while PR-`skipped` passes.
- D-11 retirement note is dated `2026-07-02` and points to PROJECT.md Key Decisions.
</specifics>

<deferred>
## Deferred Ideas

- **Nightly failure alerting** (open/update a GitHub issue on nightly matrix failure) — the
  maintainer chose silent-for-now; a future CI-DX pass. Note the nightly is intentionally
  silent + default-branch-only + auto-disables after 60 days of repo inactivity.
- **`paths-ignore` for docs-only PRs** — deferred: skipping the *required* `release_gate` on
  docs-only PRs re-introduces the "skipped required check blocks/greens merge" footgun, and
  it's outside MATRIX-01…04. Revisit in a dedicated CI-DX phase with a stub-gate pattern.
- **`mix.exs` floor bump `~> 1.19` → `~> 1.20` (VER-01)** — a deliberate adopter-facing
  decision for v1.9+, not a side effect of the CI pin bump.

### Reviewed Todos (not folded)
None — `todo.match-phase 60` returned 0 matches.
</deferred>
