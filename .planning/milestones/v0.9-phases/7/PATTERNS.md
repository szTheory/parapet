# Phase 7: Close Operator UI Performance Proof - Patterns

## Reusable Patterns

### Closure-Grade Verification Artifact

Reuse the Phase 2 and Phase 5 verification structure:
- frontmatter with `phase`, `verified`, `status`, `score`, and `human_verification`
- `Goal Achievement`
- `Observable Truths`
- `Behavioral Spot-Checks`
- `Plan Output Check`
- `Requirements Coverage`
- `Human Verification Required`
- `Gaps Summary`

Why it fits here:
- Phase 7 is closing an already-implemented phase.
- The repo already uses this structure for milestone-close proof work.
- It keeps proof rerunnable and audit-friendly.

### Proof First, Reconciliation Second

Reuse the Phase 6 split:
- Plan 1 creates the missing proof artifact by rerunning commands and capturing exact outcomes.
- Plan 2 reconciles only the files that should change after that proof exists.

Why it fits here:
- Prevents traceability edits from outrunning actual evidence.
- Matches the active repo style for narrow verification-gap closure.

### Narrow Reconciliation Scope

Reuse the Phase 6 discipline:
- update only the local validation file
- update only the exact requirement/acceptance rows that Phase 7 closes
- update only the roadmap row directly owned by this phase

Avoid:
- `.planning/STATE.md`
- milestone audit rewrites
- unrelated requirement rows
- broad milestone wording cleanup

### Honest Advisory Benchmark Language

Reuse the current Phase 3 docs posture and Phase 7 context:
- benchmark is reproducible
- benchmark is advisory
- benchmark is not a merge gate
- benchmark should record bounded visible-row outcomes and environment details
- benchmark should not claim a universal timing SLA

### Validation as an Explicit Nyquist Contract

Upgrade `03-VALIDATION.md` from “planned” to “closure-accurate” wording:
- each required proof surface should point at the new `VERIFICATION.md`
- statuses should stop implying future implementation work
- the file should become compatible with the already-landed implementation state

## Planner Recommendations

1. Split Phase 7 into exactly two plans.
2. Make `07-01` own `.planning/v0.9-phases/3/VERIFICATION.md` and the rerun commands only.
3. Make `07-02` own `.planning/v0.9-phases/3/03-VALIDATION.md`, `.planning/REQUIREMENTS.md`, and `.planning/ROADMAP.md` only.
4. Keep historical Phase 3 summary files read-only unless a concrete false claim is discovered during execution.
5. Use the benchmark’s existing printed signals directly in the verification artifact rather than inventing new acceptance numbers.

## Anti-Patterns

- Writing a new proof narrative without rerunning the commands.
- Treating summary files as canonical closure evidence.
- Updating roadmap/requirements first and proving later.
- Turning Phase 7 into milestone-wide artifact cleanup.
- Reframing the advisory benchmark as a hard performance SLA.
