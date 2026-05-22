# Phase 6: Verify Cardinality Protection - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 3 planned artifacts + 2 stale reference surfaces
**Analogs found:** 3 / 3 planned artifacts

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
| --- | --- | --- | --- | --- |
| `.planning/v0.9-phases/1/VERIFICATION.md` | test | transform | `.planning/v0.9-phases/2/VERIFICATION.md` | exact |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` + `.planning/v0.9-MILESTONE-AUDIT.md` | role-match |
| `.planning/v0.9-phases/1/VALIDATION.md` | test | transform | `.planning/v0.9-phases/2/VALIDATION.md` | exact |

## Pattern Assignments

### `.planning/v0.9-phases/1/VERIFICATION.md` (test, transform)

**Primary analog:** `.planning/v0.9-phases/2/VERIFICATION.md`

**Secondary analog:** `.planning/v0.9-phases/5/VERIFICATION.md`

**Structural shell to copy** (`.planning/v0.9-phases/2/VERIFICATION.md:1-15`, `.planning/v0.9-phases/5/VERIFICATION.md:1-15`):
```md
---
phase: 02-database-scale
verified: 2026-05-20T17:58:29Z
status: verified
score: 5/5 must-haves verified
human_verification: []
---

# Phase 2: Database Scale & Pruning Verification Report

**Phase Goal:** ...
**Verified:** ...
**Status:** verified
**Re-verification:** Yes - implementation existed, this session re-ran the phase test gates and reconciled tracking docs.
```

**Core section order to copy** (`.planning/v0.9-phases/2/VERIFICATION.md:16-59`, `.planning/v0.9-phases/5/VERIFICATION.md:16-62`):
```md
## Goal Achievement

### Observable Truths
| # | Truth | Status | Evidence |

### Behavioral Spot-Checks
| Behavior | Command | Result | Status |

### Plan Output Check
| Plan | Summary | Status | Notes |

### Requirements Coverage
| Requirement | Status | Evidence |

### Human Verification Required

### Gaps Summary
```

**Behavioral proof posture to copy** (`.planning/v0.9-phases/5/VERIFICATION.md:29-37`):
```md
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Advisory doctor posture | `mix test test/mix/tasks/parapet.doctor_test.exs` | 10 tests, 0 failures | ✓ PASS |
```

**Mapping guidance**
- Keep the frontmatter and top summary terse. Use the v0.9 verification pattern, not the old one-line pass marker format.
- Put executable proof first. The first truths should map to: compile-time label-limit enforcement, built-in metrics staying under the limit, and doctor cardinality analysis existing with honest `skip`/advisory semantics.
- Use the Phase 6 proof set from `.planning/v0.9-phases/6/06-CONTEXT.md`: `mix compile --force --warnings-as-errors`, `mix test test/parapet/metrics/validator_test.exs`, and `mix test test/mix/tasks/parapet.doctor_test.exs`.
- Keep the requirements crosswalk compact. `PERF-01.a` should point to doctor-cardinality proof; `PERF-01.b` should point to compile-time validator proof.
- Keep the “Human Verification Required” section explicit even if it says `None`.
- End with the same footer used by Phases 2 and 5:
```md
---

_Verified: ..._
_Verifier: Codex_
```

**Anti-patterns / stale surfaces to avoid**
- Do not copy the obsolete minimal verification shape from `.planning/milestones/v0.8-phases/1/VERIFICATION.md:1-19`. It has no observable truths, no command matrix, and no requirement evidence.
- Do not reuse the overclaim from `.planning/phases/01-cardinality-protection/01-01-SUMMARY.md:31-34`:
```md
## Verification
- `mix compile --force --warnings-as-errors` passes.
- `mix test` passes.
- `mix parapet.doctor cardinality` validates the current system configuration successfully.
```
  That wording is too broad for the current workspace and ignores legitimate `skip` behavior.
- Do not reuse the older UAT expectation from `.planning/phases/01-cardinality-protection/01-UAT.md:20-23`:
```md
Running `mix parapet.doctor cardinality` analyzes all SLO PromQL definitions. It should report `fatal` ... and exit with code 2. It reports `ok` if all are safe.
```
  This is stale because Phase 6 must be honest that the current workspace can legitimately return `skip` when no SLOs are configured.

---

### `.planning/REQUIREMENTS.md` (config, transform)

**Primary analog:** `.planning/REQUIREMENTS.md`

**Supporting analog:** `.planning/v0.9-MILESTONE-AUDIT.md`

**Checklist pattern to preserve** (`.planning/REQUIREMENTS.md:20-41`):
```md
## System Requirements

### PERF-01: TSDB Cardinality Protection
- [ ] System provides a `mix parapet.doctor cardinality` sub-command ...
- [ ] System strictly limits the number of labels per metric at compile-time ...
```

**Traceability table pattern to preserve** (`.planning/REQUIREMENTS.md:43-57`):
```md
## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PERF-01.a | Phase 6 | Pending |
| PERF-01.b | Phase 6 | Pending |
```

**Reconciliation source of truth** (`.planning/v0.9-MILESTONE-AUDIT.md:148-162`):
```md
## Requirements Cross-Reference

| Requirement | REQUIREMENTS.md | Summary evidence | Verification evidence | Final status |
| --- | --- | --- | --- | --- |
| PERF-01.a `mix parapet.doctor cardinality` | unchecked | Phase 1 summary claims complete | missing | orphaned |
| PERF-01.b compile-time label limits | unchecked | Phase 1 summary claims complete | missing | orphaned |
```

**Mapping guidance**
- Edit only the two `PERF-01` checklist bullets and the two `PERF-01` traceability rows.
- Preserve the existing requirement prose and file ordering. This should be a narrow reconciliation, not a requirements rewrite.
- Once Phase 1 `VERIFICATION.md` exists, flip the system requirement checkboxes for `PERF-01` to `[x]`.
- Update the traceability statuses for `PERF-01.a` and `PERF-01.b` from `Pending` to `Verified`, keeping them mapped to `Phase 6`.
- Match the milestone-audit vocabulary: the file should move `PERF-01.a` and `PERF-01.b` from “unchecked/orphaned” to explicitly verified, without touching unrelated pending items.

**Anti-patterns / stale surfaces to avoid**
- Do not broaden the edit into `DX-01`, `SCALE-01.c`, or `AC-03` reconciliation. `.planning/ROADMAP.md` and `.planning/v0.9-phases/6/06-CONTEXT.md` both constrain Phase 6 to direct `PERF-01` closure only.
- Do not change the narrative “Approach” text at `.planning/REQUIREMENTS.md:8-18`. Phase 6 is proof closure, not requirement redesign.

---

### `.planning/v0.9-phases/1/VALIDATION.md` (test, transform)

**Primary analog:** `.planning/v0.9-phases/2/VALIDATION.md`

**Negative analog:** `.planning/v0.9-phases/5/05-VALIDATION.md`

**Minimal covered validation shape to copy** (`.planning/v0.9-phases/2/VALIDATION.md:1-10`):
```md
# Phase 2: Database Scale & Pruning Validation

## Nyquist Validation Coverage

| Requirement | Verification Method | Status |
|-------------|---------------------|--------|
| [SCALE-01] Database Scale & Pruning | ... | COVERED |

## Gap Analysis
No gaps identified.
```

**Stale execution-planning shape to avoid** (`.planning/v0.9-phases/5/05-VALIDATION.md:3-16`):
```md
## Nyquist Validation Coverage

| Requirement | Verification Method | Status |
|-------------|---------------------|--------|
| ... | ... | PLANNED |

## Gap Analysis
- Execution has not started yet ...
```

**Mapping guidance**
- Keep this file short. Phase 1 validation already exists; it needs reconciliation, not a wholesale rewrite.
- Split the validation coverage to match the requirement granularity now used by Phase 6. Prefer separate rows for `PERF-01.a` and `PERF-01.b` rather than one umbrella `[PERF-01]` row.
- Point each row at the concrete proof surfaces named in the new verification report: targeted validator test, targeted doctor test, and forced compile pass.
- Update the gap analysis so it references the new verification artifact and explicitly states that no validation gap remains once the proof document exists.
- Keep wording aligned with the verification report’s honesty boundary: doctor-cardinality source inspection plus targeted tests prove the feature contract; a workspace `skip` result is not framed as a universal runtime-success proof.

**Anti-patterns / stale surfaces to avoid**
- Do not keep the current overly compressed row from `.planning/v0.9-phases/1/VALIDATION.md:5-10`:
```md
| [PERF-01] TSDB Cardinality Protection | Unit tests (`test/parapet/metrics/validator_test.exs`, `test/mix/tasks/parapet.doctor_test.exs`), Compile-time checks (`mix compile --warnings-as-errors`). | COVERED |

## Gap Analysis
No gaps identified. The implementation directly tests compile-time and static analysis behaviors described in the plan.
```
  It says “covered” but does not reconcile the missing Phase 1 verification artifact or the doctor-proof nuance.
- Do not copy the `PLANNED` posture from `.planning/v0.9-phases/5/05-VALIDATION.md:7-16`. Phase 6 is closing an already-implemented artifact gap, not planning future proof work.

## Shared Patterns

### Verification writing posture
**Sources:** `.planning/v0.9-phases/2/VERIFICATION.md:11-15`, `.planning/v0.9-phases/5/VERIFICATION.md:11-15`
```md
**Phase Goal:** ...
**Verified:** ...
**Status:** verified
**Re-verification:** Yes - implementation existed, this session re-ran the phase test gates and reconciled the plan artifacts.
```
Apply this tone to Phase 1: concise, evidence-first, explicit that this is re-verification of existing work.

### Observable-truth-first structure
**Sources:** `.planning/v0.9-phases/2/VERIFICATION.md:18-28`, `.planning/v0.9-phases/5/VERIFICATION.md:18-27`
```md
### Observable Truths
| # | Truth | Status | Evidence |
```
Lead with truths about what is proven, then use short crosswalk tables for auditability.

### Narrow reconciliation discipline
**Sources:** `.planning/ROADMAP.md:40-47`, `.planning/v0.9-phases/6/06-CONTEXT.md`
Copy the discipline, not the prose: update only the proof surfaces directly closed by Phase 6 and leave broader milestone synchronization for Phase 9.

## Stale Reference Surfaces

| File | Why it is stale | Safe use |
| --- | --- | --- |
| `.planning/phases/01-cardinality-protection/01-01-SUMMARY.md` | Summary-level verification language overstates current doctor proof by implying success on the current workspace. | Use only as implementation-history context for Plan Output Check. |
| `.planning/phases/01-cardinality-protection/01-UAT.md` | Assumes doctor-cardinality always resolves to `fatal` or `ok`; does not encode legitimate `skip` semantics. | Use only as a historical note to correct, not as proof wording to reuse. |
| `.planning/milestones/v0.8-phases/1/VERIFICATION.md` | Too thin for v0.9 audit posture; lacks observable truths, commands, and traceability. | Treat as a legacy anti-analog only. |

## No Analog Found

None. All planned Phase 6 documentation targets have usable in-repo analogs.

## Metadata

**Analog search scope:** `.planning/`, especially `v0.9-phases/`, legacy milestone verification docs, and original Phase 1 summary/UAT surfaces  
**Files scanned:** 13  
**Pattern extraction date:** 2026-05-21

## PATTERN MAPPING COMPLETE
