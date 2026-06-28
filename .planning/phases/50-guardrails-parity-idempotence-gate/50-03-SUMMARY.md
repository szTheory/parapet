---
phase: 50-guardrails-parity-idempotence-gate
plan: "03"
subsystem: milestone-audit
tags: [guard, audit, non-regression, idempotence, font-delta, evidence-binding]
dependency_graph:
  requires: [50-01, 50-02]
  provides: [GUARD-07]
  affects:
    - .planning/milestones/v1.6-MILESTONE-AUDIT.md
    - lib/parapet/evidence/archiver.ex
    - priv/parapet/public_api_stable.json
tech_stack:
  added: []
  patterns:
    - evidence-binding audit over existing gates (D-18/D-19)
    - per-requirement command/file:line coverage table (D-19)
    - three non-regression proofs (public-API, host-ownership, telemetry)
    - forward-only idempotence proof (on_exists: :skip + --dry-run + ledger semantics)
    - font package-size delta (absolute woff2 total + mix hex.build Package size)
key_files:
  created:
    - .planning/milestones/v1.6-MILESTONE-AUDIT.md
  modified:
    - lib/parapet/evidence/archiver.ex
    - priv/parapet/public_api_stable.json
decisions:
  - "D-18: Audit is a thin evidence-binding doc — every claim resolves to a command, manifest, or file:line; no new tooling"
  - "D-19: Per-requirement table with command/file:line Evidence cells; coherent-by-reference with operator-audit-matrix.md"
  - "D-20: Three non-regression proofs: public-API (mix verify.public_api), host-ownership (compile-out/integration tests + on_exists: :skip + matrix grep-proofs), telemetry (telemetry_contract_test.exs)"
  - "D-21: telemetry_stable.json NOT added — out of v1.6 UI-brand scope; deferred to future telemetry/contract-hardening phase"
  - "D-22: Idempotence proof: --dry-run at parapet.gen.ui.ex:74 + Igniter super/1 + three on_exists: :skip at :43/:54/:65 + audit-matrix todo->done->verified-only semantics"
  - "D-23: Font delta — 53,428 bytes / 52.2 KB (5 files, machine-checked under 150 KB ceiling) + mix hex.build 262 KB post-v1.6 tarball; no pre-font baseline to subtract"
  - "Rule 1 auto-fix: Parapet.Evidence.Archiver.Summary/Failure nested modules missing Experimental tier declarations — fixed + stable manifest refreshed (also picks up Parapet.Operator.fetch_incident_detail/1 from phase 48)"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-28"
  tasks: 2
  files: 3
status: complete
---

# Phase 50 Plan 03: v1.6 Milestone Audit (GUARD-07) Summary

**One-liner:** v1.6-MILESTONE-AUDIT.md: 68-row evidence table (every cell a command/file:line), three non-regression proofs (public-API/host-ownership/telemetry), idempotence proof (on_exists: :skip + --dry-run), font delta (52.2 KB / 262 KB tarball), all gates green.

## What Was Built

### Task 1: Gather real verification evidence

Ran all verification commands and captured real output:

- `mix verify.public_api` — initially exited 1 due to a pre-existing gap (two nested modules in `lib/parapet/evidence/archiver.ex` missing stability-tier declarations). Auto-fixed per Rule 1: added `> #### Experimental {: .warning}` to `Parapet.Evidence.Archiver.Summary` and `Parapet.Evidence.Archiver.Failure` `@moduledoc` blocks; refreshed `priv/parapet/public_api_stable.json` (also picks up `Parapet.Operator.fetch_incident_detail/1` added in phase 48). After fix: exit 0, all modules classified.
- `mix test test/telemetry_contract_test.exs` — 35 tests, 0 failures.
- `mix test test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_integration_test.exs` — 35 tests, 0 failures.
- `mix test test/parapet/operator_ui_parity_test.exs test/parapet/operator_ui_palette_gate_test.exs test/parapet/operator_ui_motion_test.exs test/parapet/operator_ui_fonts_test.exs` — 9 tests, 0 failures.
- Font absolute total: 53,428 bytes (52.2 KB) across 5 files — under 153,600-byte ceiling.
- `mix hex.build` — Package size 262 KB (post-v1.6 tarball).
- `--dry-run` idempotence: no clean host available in repo context; cited `parapet.gen.ui.ex:74` + `Igniter super/1` + three `on_exists: :skip` at :43/:54/:65 per plan guidance.

### Task 2: Write v1.6-MILESTONE-AUDIT.md in v1.4/v1.5 house style

Created `.planning/milestones/v1.6-MILESTONE-AUDIT.md` with all required sections:

1. YAML frontmatter: `status: passed`, scores (61/68 requirements), gaps (Phase 48 FLOW/COPY/A11Y-06 human-verified + TOKEN-04 deferred), `tech_debt` noting telemetry_stable.json backlog (D-21), `nyquist: compliant_phases: [44..50]`.
2. Summary paragraph.
3. Requirements Coverage: 68-row table with `Requirement | Phase | Claim | Evidence | Status` — every Evidence cell is a runnable command or file:line. GUARD-03/04/05 cite plan 50-01 commits; GUARD-06 cites plan 50-02 commits; GUARD-07 cites this document.
4. Phase Verification: per-phase (44–50) brief line.
5. Non-Regression Proofs: three proofs per D-20 with pasted real output.
6. Idempotence Proof: --dry-run + on_exists: :skip + ledger semantics per D-22.
7. Font Package-Size Delta: per-file table + absolute total + mix hex.build tarball size per D-23.
8. Verification Commands: fenced bash block with pasted real outputs.
9. Result: passed.

Coherent-by-reference with `operator-audit-matrix.md` — does not duplicate the component×state ledger.

## Verification

```
mix verify.public_api                                       → exit 0 (0 unclassified)
mix test test/telemetry_contract_test.exs                  → 35 tests, 0 failures
mix test operator_ui_compile_out_test + integration_test   → 35 tests, 0 failures
mix test parity + palette_gate + motion + fonts            → 9 tests, 0 failures
diff --manifest vs operator-ui-baseline.md                 → no output (exit 0)
v1.6-MILESTONE-AUDIT.md all sections present              → OK
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing stability-tier declarations in Archiver nested modules**
- **Found during:** Task 1 (running `mix verify.public_api`)
- **Issue:** `Parapet.Evidence.Archiver.Summary` and `Parapet.Evidence.Archiver.Failure` nested modules had `@moduledoc` strings without `> #### Experimental {: .warning}` tier declarations. `mix verify.public_api` exited 1 with "unclassified" error. Pre-existing gap from the archiver feature addition, not introduced by this phase.
- **Fix:** Added Experimental tier declaration to both nested `@moduledoc` blocks in `lib/parapet/evidence/archiver.ex`; ran `mix verify.public_api --write` to refresh the stable manifest (also picks up `Parapet.Operator.fetch_incident_detail/1` added in phase 48 but never committed to the stable manifest).
- **Files modified:** `lib/parapet/evidence/archiver.ex`, `priv/parapet/public_api_stable.json`
- **Commit:** 6572e5d

## Known Stubs

None. The audit document binds every claim to a real runnable artifact.

## Threat Flags

None. No new runtime attack surface introduced. The audit document proves every regression claim resolves to a re-runnable artifact (T-50-06 mitigated). The three non-regression proofs bind to existing drift gates that fail closed (T-50-07 mitigated).

## Self-Check: PASSED

- `.planning/milestones/v1.6-MILESTONE-AUDIT.md` — FOUND
- `lib/parapet/evidence/archiver.ex` — FOUND (modified)
- `priv/parapet/public_api_stable.json` — FOUND (modified)
- 6572e5d (archiver tier fix + stable manifest refresh) — FOUND
- e93f951 (v1.6-MILESTONE-AUDIT.md) — FOUND
