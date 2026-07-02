# Phase 60: OTP Matrix Reshape & Nightly Schedule - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-02
**Phase:** 60-otp-matrix-reshape-nightly-schedule
**Mode:** assumptions + deep decision-fork research (user-requested)
**Areas analyzed:** version set · matrix mechanism · triggers/demo/release_gate · D-11 retirement · DX/support-honesty · adjacent stale toolchain

## Method

Six subagents were fanned out at the user's request (full lens checklist per fork; UI/graphic
lenses N/A — CI config). Four decision-fork researchers + one sibling-lib/engineering-DNA
pressure-test + one mechanical-trap completeness sweep. All version facts live-verified
against hexdocs / endoflife.date / erlang.org as of 2026-07-02.

## Assumptions Presented (initial)

| Area | Initial assumption | Confidence | Evidence |
|------|--------------------|-----------|----------|
| Versions | Elixir 1.20.2 exact + OTP {27,28,29}, keep `~> 1.19` floor | Confident | REQUIREMENTS MATRIX-01/02; research DP-1; `mix.exs:11` |
| Matrix mechanism | `matrix-config` setup job → `fromJson` | Confident | research 02-OTP-MATRIX-STRATEGY.md |
| Triggers/gate | nightly cron; demo `if` PR-skip; release_gate `always()` + skipped-tolerant | Confident | `ci.yml:166-193`; roadmap SC-3/4 |
| D-11 retirement | dated note, PROJECT.md canonical, 4 files | Confident | v1.7-MILESTONE-AUDIT.md; 00-SYNTHESIS |

## Corrections & Refinements Made (from research)

### From the version fork (A)
- Confirmed 1.20.2 / OTP 29 exist and are ecosystem-compatible; OTP 26 EOL confirmed.
- Reinforced: keep `mix.exs ~> 1.19` (CI pin ≠ advertised floor).

### From the matrix fork (B)
- Ruled out inline `include`/`exclude` (matrix is static at parse time — cannot subtract cells
  by event). Setup-job resolver is the only single-file mechanism.
- **Footgun caught:** the project's own drafted resolver JSON is multi-line → corrupts
  `$GITHUB_OUTPUT`. Emit single-line `{"include":[...]}`.

### From the triggers/gate fork (C)
- Exact truth table: strict `= success` for lint-once/test; `success|skipped` for demo;
  `cancelled` blocks everywhere (closes a hole a naive `== failure` demo check would leave).
- **Concurrency:** add `github.event_name` to the group so nightly ≠ main-push serialize.
- **Cron:** recommend `17 3` over `0 3` (top-of-hour delay). **User chose `17 3`.**

### From the D-11 fork (D)
- **Caught:** `STATE.md` line 114's "D-11" is a *different* decision (concurrency hold) — must
  NOT be edited. Dated append-only notes; PROJECT.md canonical; 4-spot minimal set.

### From the sibling-lib/DNA pressure-test (E) — verdict REFINE (R1–R6)
- **R1 (adopted, D-05a):** OTP-29 cell exceeds the `~> 1.19` floor's OTP-28 ceiling — add a
  support-honesty comment.
- **R2 (adopted, D-05b):** add CONTRIBUTING "trimmed PR matrix" bullet + descriptive
  `matrix-config` job name.
- **R3 (adopted, D-02):** resolver must emit pure include rows — no stale static base matrix.
- **R4 (adopted, D-04d):** re-anchor the D-11 ci.yml comment to the resolver job (D-02
  dissolved the static block it was going to annotate).
- **R5 vs mechanical sweep — CONFLICT RESOLVED (D-01d):** R5 said `version-type: strict` is
  harmless belt-and-suspenders; the mechanical sweep showed `strict` *errors* against `.x` OTP
  ranges. **Resolution: do NOT add `strict`** — loose + exact `1.20.2` is reproducible and
  sibling-idiomatic.
- **R6a (adopted, D-01e):** drop the standalone OTP-29 `deps.get` check — redundant theater.
- **R6b (deferred):** `paths-ignore` for docs-only PRs re-introduces the skipped-required-check
  footgun — deferred to a dedicated CI-DX phase.

### From the mechanical-trap sweep (F)
- Line-precise cache-key / setup-beam / trigger-scoping checklist (folded into CONTEXT
  `<code_context>`).
- **New adjacent edits (D-06):** `release-please.yml` publish-hex pins `1.19.0`/`27.2` are
  stale; README:27 "CI validates…" sentence is factually false.
- Confirmed `_build` key must retain `${{ matrix.schema_prefix }}`; no `.tool-versions` file
  exists; STATE.md D-11 left alone.

## User Decisions

- Nightly cron: **`17 3 * * *`** (accepted the off-hour refinement over the roadmap's `0 3`).
- Nightly failure alerting: **stay silent** for now (deferred).

## External Research

Live-verified (2026-07-02): Elixir 1.20.2 exists (requires OTP 27+; compatible 27/28/29);
OTP 29.0 released 2026-05-13 (29.0.x patches through July); OTP 26 EOL 2026-05-26; OTP 28
supported to 2028. setup-beam default `version-type` is `loose`; `strict` requires exact
per-field versions (incompatible with `.x` OTP). Sibling libs (ecto/oban/bandit/req/phoenix)
use `include`-only static matrices with loose+exact pins and thin aggregate gates.
