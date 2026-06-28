# Phase 50: Guardrails, parity & idempotence gate - Discussion Log (Assumptions Mode + Advisor Research)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-28
**Phase:** 50-guardrails-parity-idempotence-gate
**Mode:** assumptions (+ user-requested advisor research via 5 parallel `gsd-advisor-researcher` agents)
**Areas analyzed:** GUARD-03 byte-parity · GUARD-04 hex gate · GUARD-05 motion · GUARD-06 manifest · GUARD-07 audit · test placement

## Assumptions Presented (initial codebase analysis)

### GUARD-03 — byte-parity
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Render `.eex` + `Code.format_string!`-normalize + compare; raw byte-compare is wrong | Confident | mirrors are `mix format`-ted post-gen; operator_live/detail byte-equal after normalize |
| Real generator bug: `<%#-` comments at operator_components.ex.eex:1428/1442 diverge from mirror; fix template | Confident | grep: 2 `<%#-` in .eex vs literal `<%#` in mirror at same lines |
| `@repo_module` also differs live (not just `@web_module`) | Confident | operator_live.ex.eex:12,77,104,552 + detail 6× |

### GUARD-04 — hex gate
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Allowlist = 31 token hexes + 5 operator exceptions; augment (not replace) denylist | Confident | comm of template hexes vs tokens.css → exactly 5 non-token hexes |
| 3 of 5 exceptions (#1A5066/#556B77/#8C2E27) currently undocumented | Confident | operator-audit-matrix.md:132-157 documents only #7FB4C6/#A8D0DE |

### GUARD-05 — motion
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Mostly consolidation; add literal easing assert + `--motion-base: 0ms` check | Likely | contrast test asserts --motion-fast:0ms only; easing value not asserted |

### GUARD-06 — manifest
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Markdown manifest of 15 captures (no PNGs) + re-run procedure | Confident | capture script enumerates 15; v1.5 precedent |

### GUARD-07 — audit
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| v1.5 house style; lean on verify.public_api / fonts test / on_exists:skip / telemetry contract | Likely | all gates exist in repo |

### Test placement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend contrast test for GUARD-04/05; new file for GUARD-03 | Likely | shared path attrs in contrast test |

## User Direction

User did not correct individual assumptions; instead requested **deep advisor research** on each
decision — pros/cons/tradeoffs, idiomatic Elixir/Phoenix/Ecto patterns, prior-art lessons, DX, and
consultation of `prompts/` research — to produce a single coherent one-shot recommendation set.
Five `gsd-advisor-researcher` agents were spawned in parallel.

## Research Findings → Decision Refinements

- **GUARD-03 (D-01):** Research upgraded the approach from `EEx.eval_file` to the repo's **own
  `Igniter.Test` idiom** (`test_project` → `igniter()` → read `igniter.rewrite`), matching
  `parapet.gen.spine_test.exs` — more faithful, same speed.
- **GUARD-03 (D-02):** Confirmed **AST-compare must be rejected** — it drops comments and would mark
  the D-03 bug as passing (the single most important finding). `Code.format_string!` *raises* on the
  malformed rendered operator_components — wrap in try/rescue.
- **GUARD-03 (D-03):** Research **corrected the comment-fix form**: `<%%#-` would emit a deprecated
  token; the principled fix emits exactly what the mirror has (`<%%#` → `<%#`) or modernizes both to
  `<%!-- … --%>`. Fix the template, never normalize comments away.
- **GUARD-04 (D-06):** Research strengthened to **source the allowlist live from `tokens.css`**
  (single source of truth) with `MapSet.size >= 31` fail-closed guard — better than a hard-coded
  inline list. Plain ExUnit regex scan chosen over Credo (repo credo is lib/test-only, strict:false)
  and over a mix task (duplicates CI surface).
- **GUARD-04 (D-07):** Exceptions must be read from one documented declaration in the audit matrix;
  the 3 undocumented derived hexes get rationale + contrast notes this phase.
- **GUARD-05 (D-10):** Research showed the **literal easing assert is provably brittle** — template
  uses `.2, 0, 0, 1`, tokens.css uses `0.2, 0, 0, 1`. Use a whitespace/zero-tolerant regex.
  Verified `--motion-base: 0ms` IS present (line 469), so D-11's assertion is safe.
- **GUARD-06 (D-14):** Research elevated the manifest from hand-maintained to **script-emitted
  (`--manifest` mode)** so it can't drift from the capture list, plus a **cheap CI diff-check**
  (no Chrome/DB). Committed-PNG and cloud-baseline options rejected (contrary to repo-lean/zero-infra).
- **GUARD-07 (D-21):** Research confirmed **NOT** adding a telemetry-stable manifest this phase
  (out of milestone boundary); existing contract test suffices; deferred to backlog.
- **GUARD-07 (D-23):** Font delta = absolute woff2 total (≈52.2 KB, machine-checked ≤150 KB) +
  `mix hex.build` package-size before/after (the publish-payload-honest number).
- **Test placement (D-12/D-13):** Research **overrode** the initial "extend contrast test" plan in
  favor of **file-per-concern** (matching the repo's `operator_ui_*` convention) +
  a shared `test/support/operator_ui_paths.ex` helper (path strings already duplicated 30+ times).

## Corrections Made

No assumptions were *rejected* by the user. Advisor research **refined** several (comment-fix form,
Igniter.Test idiom, live-sourced allowlist, tolerant motion regex, script-emitted manifest,
file-per-concern placement) — all folded into CONTEXT.md decisions D-01..D-23.

## Empirical Verifications (post-research, before lock)

- `--motion-base: 0ms` present at operator_components.ex.eex:469 → GUARD-05 assertion safe.
- Easing literal mismatch confirmed (`.2` vs `0.2`) → tolerant regex required.
- `--dry-run` honored (parapet.gen.ui.ex:74 + Igniter super/1) → idempotence proof valid.
- Comment lines 1428/1442 confirmed as build-time `<%#- … %>` → real drift.
