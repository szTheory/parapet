# Phase 8: Close Day-1 Install and Doctor Verification - Pattern Map

**Mapped:** 2026-05-21
**Files analyzed:** 6 planned artifacts
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
| --- | --- | --- | --- | --- |
| `.planning/v0.9-phases/8/08-01-PLAN.md` | config | batch | `.planning/v0.9-phases/7/07-01-PLAN.md` | exact |
| `.planning/v0.9-phases/8/08-02-PLAN.md` | config | batch | `.planning/v0.9-phases/7/07-02-PLAN.md` | exact |
| `.planning/v0.9-phases/4/VERIFICATION.md` | test | transform | `.planning/v0.9-phases/5/VERIFICATION.md` | exact |
| `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md` | test | transform | `.planning/v0.9-phases/8/08-VALIDATION.md` | role-match |
| `.planning/REQUIREMENTS.md` | config | transform | `.planning/REQUIREMENTS.md` | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |

## Pattern Assignments

### `.planning/v0.9-phases/8/08-01-PLAN.md` (config, batch)

**Primary analog:** `.planning/v0.9-phases/7/07-01-PLAN.md`

**Frontmatter + must-haves shell** (`.planning/v0.9-phases/7/07-01-PLAN.md:1-34`):
```md
---
phase: 07-close-operator-ui-performance-proof
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/v0.9-phases/3/VERIFICATION.md
autonomous: true
requirements:
  - SCALE-01.c
  - AC-03
must_haves:
  truths:
    - "Phase 3 has a dedicated closure-grade `VERIFICATION.md` ..."
```

**Objective/context/tasks framing** (`.planning/v0.9-phases/7/07-01-PLAN.md:36-99`):
```md
<objective>
Create the missing closure-grade Phase 3 verification artifact first.

Purpose: prove the existing ... work with fresh executable evidence, then capture that proof in one canonical report without changing product behavior.
Output: `.planning/v0.9-phases/3/VERIFICATION.md`.
</objective>

<context>
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
...
</context>
```

**Task split to copy** (`.planning/v0.9-phases/7/07-01-PLAN.md:75-97`):
```md
<task type="auto">
  <name>Task 1: Re-run the deterministic ... proof lanes and capture exact outcomes</name>
  ...
</task>

<task type="auto">
  <name>Task 2: Write the canonical ... verification report in the repo’s closure-grade format</name>
  ...
</task>
```

**Threat/verification tail** (`.planning/v0.9-phases/7/07-01-PLAN.md:101-129`):
```md
<threat_model>
## Trust Boundaries
...
## STRIDE Threat Register
...
</threat_model>

<verification>
- Run `mix test ...`
</verification>
```

**Mapping guidance**
- Keep Phase 8 split the same way: Task 1 reruns `mix test test/mix/tasks/parapet.install_test.exs`, `mix test test/mix/tasks/parapet.doctor_test.exs`, doc-contract grep, and one fresh-host smoke lane; Task 2 writes `.planning/v0.9-phases/4/VERIFICATION.md`.
- Replace the benchmark-specific `must_haves` with Day-1 proof truths: installer contract, doctor contract, docs handoff, and explicit honesty boundary for optional UI and `doctor cluster`.
- Keep this plan single-output. `08-01` should only modify `.planning/v0.9-phases/4/VERIFICATION.md`.

---

### `.planning/v0.9-phases/8/08-02-PLAN.md` (config, batch)

**Primary analog:** `.planning/v0.9-phases/7/07-02-PLAN.md`

**Dependent reconciliation shell** (`.planning/v0.9-phases/7/07-02-PLAN.md:1-40`):
```md
---
phase: 07-close-operator-ui-performance-proof
plan: 02
type: execute
wave: 2
depends_on:
  - 07-01
files_modified:
  - .planning/v0.9-phases/3/03-VALIDATION.md
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
...
```

**Narrow reconciliation task pattern** (`.planning/v0.9-phases/7/07-02-PLAN.md:72-107`):
```md
<task type="auto">
  <name>Task 1: Reconcile ... validation and requirement traceability to the new proof artifact</name>
  <files>..., .planning/REQUIREMENTS.md</files>
  <action>
    Update ... so it no longer presents the ... proof surfaces as pending implementation work.
    ...
    Do not touch `DX-01`, `STATE.md`, or unrelated requirement rows.
  </action>
  <verify>
    <automated>...</automated>
  </verify>
</task>

<task type="auto">
  <name>Task 2: Reconcile the Phase 7 roadmap row without expanding into milestone-wide cleanup</name>
  ...
</task>
```

**Scope guardrail language** (`.planning/v0.9-phases/7/07-02-PLAN.md:112-139`):
```md
| Verification artifact -> tracking docs | Traceability state must change only after the new proof exists. |
| Narrow Phase 7 reconciliation -> milestone-wide state | This phase must not blur into broader cleanup owned by later work. |
```

**Mapping guidance**
- Copy the same dependency pattern: `08-02` depends on `08-01`.
- Limit `files_modified` to `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md`, `.planning/REQUIREMENTS.md`, and `.planning/ROADMAP.md`.
- Keep verification inline and exact: assert Phase 4 `VERIFICATION.md` is referenced, only `DX-01.a`, `DX-01.b`, and `AC-01` flip, and the Phase 8 roadmap row gains closure wording without touching Phase 9 or milestone-wide state.

---

### `.planning/v0.9-phases/4/VERIFICATION.md` (test, transform)

**Primary analog:** `.planning/v0.9-phases/5/VERIFICATION.md`

**Secondary analog:** `.planning/v0.9-phases/2/VERIFICATION.md`

**Frontmatter + report header** (`.planning/v0.9-phases/5/VERIFICATION.md:1-15`, `.planning/v0.9-phases/2/VERIFICATION.md:1-15`):
```md
---
phase: 05-multi-node-safety-verification
verified: 2026-05-21T10:48:32Z
status: verified
score: 4/4 requirements verified
human_verification: []
---

# Phase 5: Multi-Node Safety Verification Report

**Phase Goal:** ...
**Verified:** ...
**Status:** verified
**Re-verification:** Yes - this session executed the full ... proof suite and reconciled the plan artifacts.
```

**Section order to copy exactly** (`.planning/v0.9-phases/5/VERIFICATION.md:16-63`, `.planning/v0.9-phases/2/VERIFICATION.md:16-59`):
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

**Behavioral spot-check style** (`.planning/v0.9-phases/5/VERIFICATION.md:29-37`):
```md
| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Advisory doctor posture | `mix test test/mix/tasks/parapet.doctor_test.exs` | 10 tests, 0 failures | ✓ PASS |
```

**Human-verification/manual-proof pattern to embed** (`.planning/v0.9-phases/8/08-VALIDATION.md:38-43`):
```md
| Fresh Phoenix host can adopt Parapet through the public Day-1 command and reach the documented doctor follow-up honestly | `DX-01.a`, `AC-01` | ... | Create a fresh Phoenix host, add local `:parapet` as a path dependency, run `mix deps.get`, run `mix parapet.install`, inspect generated host-owned files and summary output, run `mix parapet.doctor`, optionally run `mix parapet.doctor cluster` ... |
```

**Mapping guidance**
- Use the v0.9 verification artifact shell unchanged.
- Observable truths should lead with: installer composes the shipped Day-1 path; doctor reports severity/threshold/cluster posture honestly; README and `docs/operator-ui.md` match the shipped default-vs-optional contract; a fresh Phoenix host can execute install -> doctor -> docs handoff without widening ownership claims.
- Behavioral Spot-Checks should include four rows: installer tests, doctor tests, doc-contract grep, and the fresh-host smoke lane transcript.
- `Human Verification Required` should not say `None`; this phase explicitly needs the fresh-host smoke lane recorded as manual closure evidence.
- In `Requirements Coverage`, split rows for `DX-01.a`, `DX-01.b`, and corrected `AC-01`.

---

### `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md` (test, transform)

**Primary analog:** `.planning/v0.9-phases/8/08-VALIDATION.md`

**Supporting analog:** `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md`

**Proof-lane infrastructure to copy** (`.planning/v0.9-phases/8/08-VALIDATION.md:12-26`):
```md
## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + shell/doc proof lane |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/parapet.install_test.exs test/mix/tasks/parapet.doctor_test.exs` |
| **Doc contract command** | `rg -n 'mix parapet\.install|mix parapet\.doctor|--with-ui|--skip-ui|cluster' README.md docs/operator-ui.md` |
```

**Per-task/manual verification pattern** (`.planning/v0.9-phases/8/08-VALIDATION.md:28-52`):
```md
| 08-01-04 | 01 | 1 | `DX-01.a`, `AC-01` | manual smoke capture | `test -x scripts/setup_sandbox.sh || true` | planned |

| Fresh Phoenix host can adopt Parapet through the public Day-1 command and reach the documented doctor follow-up honestly | `DX-01.a`, `AC-01` | ... | Create a fresh Phoenix host ... and record the exact command/results transcript in `.planning/v0.9-phases/4/VERIFICATION.md` |
```

**Existing Phase 4 layout to preserve where possible** (`.planning/phases/04-unified-install-path-dx/04-VALIDATION.md:1-79`):
```md
---
phase: 04
slug: unified-install-path-dx
status: draft
nyquist_compliant: true
...
## Per-Task Verification Map
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
```

**Mapping guidance**
- Preserve the existing Phase 4 validation file’s frontmatter and table-oriented shell, but update it from “pending implementation validation contract” to “closure-accurate proof map”.
- Point the relevant rows at `.planning/v0.9-phases/4/VERIFICATION.md` and the executed proof lanes instead of leaving them as pending-only plan checks.
- Keep the fresh-host smoke lane explicit and manual. Do not convert it into a permanent ExUnit gate.
- Remove or soften wording that implies `test/parapet_test.exs` is part of the closure-grade proof unless the new verification artifact actually cites it.

---

### `.planning/REQUIREMENTS.md` (config, transform)

**Primary analog:** `.planning/REQUIREMENTS.md`

**Checklist rows to edit narrowly** (`.planning/REQUIREMENTS.md:31-40`):
```md
### DX-01: Unified Install Path
- [ ] System provides `mix parapet.install` as a unified, interactive starting point that sequentially runs necessary sub-generators.
- [ ] System's `mix parapet.doctor` checks for correct multi-node configuration (e.g., verifying Oban uniqueness settings for escalations).

## Acceptance Criteria
- [ ] A developer can run `mix parapet.install` and get the spine, UI, and default Prometheus artifacts in one guided flow.
```

**Traceability rows to edit narrowly** (`.planning/REQUIREMENTS.md:43-57`):
```md
| DX-01.a | Phase 8 | Pending |
| DX-01.b | Phase 8 | Pending |
| AC-01 | Phase 8 | Pending |
```

**Row-flip discipline to copy** (`.planning/v0.9-phases/7/07-02-PLAN.md:72-95`):
```md
Then update `.planning/REQUIREMENTS.md` narrowly: flip only ... and change only the ... traceability rows from `Pending` to `Verified`. Do not touch ... unrelated requirement rows.
```

**Mapping guidance**
- Change only the two `DX-01` checklist bullets, the `AC-01` acceptance bullet, and the three Phase 8 traceability rows.
- Correct `AC-01` wording before marking it verified: core install by default, optional UI explicit when LiveView is present.
- Keep the broader overview and architectural narrative unchanged. This phase is proof reconciliation, not requirements redesign.

---

### `.planning/ROADMAP.md` (config, transform)

**Primary analog:** `.planning/ROADMAP.md`

**Current Phase 8 block to update** (`.planning/ROADMAP.md:61-68`):
```md
### Phase 8: Close Day-1 Install and Doctor Verification
**Goal:** Close the Phase 4 verification gap for the install, doctor, and documentation handoff flow.
**Requirements:** `DX-01.a`, `DX-01.b`, `AC-01`
**Gap Closure:** Closes audit requirement and flow gaps for the public Day-1 install path.
- Produce a Phase 4 `VERIFICATION.md` that proves `mix parapet.install` works end-to-end through doctor and docs handoff.
- Verify the multi-node doctor contract against the implemented checks and reported outcomes.
- Reconcile requirement coverage so the install and doctor claims are backed by explicit closure evidence.
```

**Closure-line style to mirror** (`.planning/ROADMAP.md:51-58`):
```md
### ✓ Phase 7: Close Operator UI Performance Proof
...
**Closure:** Satisfied by `.planning/v0.9-phases/3/VERIFICATION.md` plus the reconciled `03-VALIDATION.md` and `REQUIREMENTS.md` rows for `SCALE-01.c` and `AC-03`.
```

**Narrow roadmap edit rule** (`.planning/v0.9-phases/7/07-02-PLAN.md:98-107`):
```md
Update the active Phase 7 roadmap entry so it no longer reads as an open proof gap once `.planning/v0.9-phases/3/VERIFICATION.md` exists ...
Do not edit other roadmap phases, broader milestone goal text, or the future Phase 8/9 closure work.
```

**Mapping guidance**
- Mirror the Phase 7 closure style: convert Phase 8 to `### ✓ Phase 8 ...` and add one `**Closure:**` line naming `.planning/v0.9-phases/4/VERIFICATION.md` plus reconciled `04-VALIDATION.md` and `REQUIREMENTS.md` rows.
- Leave Phase 9 untouched.
- Do not rewrite the original Phase 4 implementation bullets; only append or adjust closure status once proof exists.

## Shared Patterns

### Proof first, reconciliation second
**Sources:** `.planning/v0.9-phases/7/07-01-PLAN.md:36-99`, `.planning/v0.9-phases/7/07-02-PLAN.md:43-107`
```md
Plan 1 creates the missing proof artifact.
Plan 2 updates only the traceability surfaces that depend on that proof.
```
Apply this split directly to Phase 8.

### Closure-grade verification shell
**Sources:** `.planning/v0.9-phases/5/VERIFICATION.md:1-67`, `.planning/v0.9-phases/2/VERIFICATION.md:1-64`
```md
frontmatter
Goal Achievement
Observable Truths
Behavioral Spot-Checks
Plan Output Check
Requirements Coverage
Human Verification Required
Gaps Summary
```
Phase 8 should copy this structure verbatim.

### Manual smoke stays manual
**Source:** `.planning/v0.9-phases/8/08-VALIDATION.md:38-52`
```md
Fresh-host smoke remains a manual closure artifact, not a permanent test gate
```
Do not convert the Phoenix host adoption proof into a repo-default automated suite.

### Narrow row-flip discipline
**Source:** `.planning/v0.9-phases/7/07-02-PLAN.md:72-107`
```md
flip only the exact requirement and roadmap rows closed by the new proof
```
Phase 8 should update only `DX-01.a`, `DX-01.b`, `AC-01`, the local Phase 4 validation wording, and the Phase 8 roadmap row.

## No Analog Found

None. All planned Phase 8 artifacts have strong in-repo analogs.

## Metadata

**Analog search scope:** `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md`, `.planning/v0.9-phases/{2,5,7,8}/`
**Files scanned:** 12
**Pattern extraction date:** 2026-05-21

## PATTERN MAPPING COMPLETE

**Phase:** 8 - Close Day-1 Install and Doctor Verification
**Files classified:** 6
**Analogs found:** 6 / 6

### Coverage
- Files with exact analog: 5
- Files with role-match analog: 1
- Files with no analog: 0

### Key Patterns Identified
- Verification closure uses the Phase 2/5 `VERIFICATION.md` shell with observable truths first and exact rerun commands second.
- Proof-closing phases split into two plans: first create the proof artifact, then reconcile only the directly dependent planning rows.
- Fresh-host adoption proof stays a manual, transcript-backed lane recorded in `VERIFICATION.md`, not a permanent automated gate.

### File Created
`.planning/v0.9-phases/8/PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now mirror the Phase 7 proof-closing split for Phase 8 and point each artifact at a concrete in-repo analog.
