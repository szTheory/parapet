# Phase 9: Reconcile Milestone Closure Artifacts - Patterns

**Mapped:** 2026-05-22
**Focus:** Closure-readiness and reconciliation, not new implementation proof

## Phase Posture

Phase 9 should copy the repo's recent closure pattern, but adapted for a phase where the proof already exists:

- Use the canonical truth hierarchy from [09-CONTEXT.md](/Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md:21): fresh rerun proof only if needed, then `VERIFICATION.md`, then `VALIDATION.md`, then summaries.
- Keep the milestone wording in the "verified, reconciled, re-audit-ready" posture from [09-CONTEXT.md](/Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md:16), not "milestone passed".
- Preserve historical artifacts as historical artifacts per [09-CONTEXT.md](/Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md:32), and add supersession/readiness notes instead of rewriting them into fiction.

## Reusable Patterns

### 1. Proof-First, Then Narrow Reconciliation

Copy the split used in Phase 7 and Phase 8:

- Phase 7 plan 1 creates or confirms canonical proof before any tracker edits: [07-01-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-01-PLAN.md:36), [07-01-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-01-PLAN.md:75)
- Phase 7 plan 2 flips only the directly dependent traceability surfaces: [07-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-02-PLAN.md:43), [07-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-02-PLAN.md:72)
- Phase 8 repeats the same pattern with broader but still bounded reconciliation: [08-01-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-01-PLAN.md:48), [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:45)

For Phase 9, "proof-first" means:

- first confirm that Phase 1, 3, 4, and 5 `VERIFICATION.md` files are the canonical truth surfaces
- first reconcile the stale proof-adjacent artifact `05-VALIDATION.md`
- only then update top-level tracker files

Do not start with `STATE.md` or milestone-audit wording.

### 2. Verification Artifacts Are Canonical Truth

Copy the closure-grade truth model from:

- [05-VERIFICATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md:16) for what a canonical proof artifact looks like
- [07-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-02-PLAN.md:117) for the "verification artifact -> tracking docs" trust boundary
- [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:164) for the "status changes must happen only after the new proof exists" rule

Apply that model directly:

- `REQUIREMENTS.md` should reflect the current verified rows already backed by proof, not summary-era status
- `ROADMAP.md` should describe closure with explicit references to existing proof artifacts, like Phase 7 and 8 already do in [ROADMAP.md](/Users/jon/projects/parapet/.planning/ROADMAP.md:51) and [ROADMAP.md](/Users/jon/projects/parapet/.planning/ROADMAP.md:61)
- `STATE.md` should summarize milestone reality after reconciliation, but should not outrun proof or imply that the audit has already been rerun

### 3. Validation Files Stay Truthful but Secondary

Use the exact stale-to-truthful repair pattern from Phase 7/8 reconciliation plans:

- [07-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-02-PLAN.md:76) updates validation wording so it no longer sounds like future implementation work
- [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:85) keeps the validation contract, but points it at the canonical `VERIFICATION.md`

Phase 5 needs the same treatment because [05-VALIDATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md:3) still says every proof lane is `PLANNED`, while [05-VERIFICATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md:47) already marks all requirements satisfied.

The Phase 9 pattern should be:

- preserve `05-VALIDATION.md` as a validation map
- replace stale `PLANNED` posture with truthful current coverage
- explicitly point readers to `.planning/v0.9-phases/5/VERIFICATION.md`
- add a short note that the validation file was reconciled post-verification

### 4. Keep Live Tracker Edits Narrow and Auditable

Reuse the exact row-flip and block-bounded style from:

- [07-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-02-PLAN.md:76)
- [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:85)
- [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:126)

Concretely, Phase 9 edits should:

- touch only `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `05-VALIDATION.md`, the active audit/readiness surface named in [09-CONTEXT.md](/Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md:38), plus one bounded root `AGENTS.md` surface for D-20
- preserve existing verified requirement rows unless a contradiction is found
- adjust only the Phase 9 block in `ROADMAP.md` plus any milestone header text that is materially inconsistent
- update `STATE.md` to the same completion story as `ROADMAP.md` and `REQUIREMENTS.md`

This phase should read like reconciliation, not a rewrite.

### 5. Historical Audit Preservation With Supersession

This is the new pattern unique to Phase 9 and it should follow the Phase 9 context literally:

- keep [v0.9-MILESTONE-AUDIT.md](/Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md:1) historical
- do not mutate it into a retroactive pass
- add a narrow supersession or re-audit-readiness note that points to the proof that closed the original gaps
- end with the explicit next step from [09-CONTEXT.md](/Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md:35): rerun `$gsd-audit-milestone`

The repo already distinguishes "what was true then" from "what is true now." Phase 9 should preserve that distinction instead of flattening the timeline.

### 6. Centralize Locked Workflow Doctrine in One Root Surface

Phase 9 also needs one bounded repo-root doctrine step because D-20 is locked:

- create `AGENTS.md` at repo root
- centralize D-18 through D-22 there
- reference `.planning/config.json` for the existing `workflow.discuss_mode = "assumptions"` default
- do not expand into broader contributor docs, taxonomy work, or config churn

## Recommended Plan Split

Phase 9 likely needs **4 plans**.

### Plan 9-01: Reconcile Proof-Adjacent Validation

Own:

- `.planning/v0.9-phases/5/05-VALIDATION.md`

Pattern to copy:

- stale-validation-to-proof-linked-validation from [07-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-02-PLAN.md:72)
- closure-accurate validation posture from [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:71)

What this plan should do:

- confirm `05-VERIFICATION.md` is the canonical proof surface
- rewrite `05-VALIDATION.md` from future-tense/`PLANNED` to current-state coverage
- preserve validation-vs-verification distinction

Why it should stand alone:

- it is the closest artifact to proof
- it avoids mixing proof-surface repair with milestone-wide tracker edits
- it creates a clean dependency for later traceability synchronization

### Plan 9-02: Synchronize Live Milestone Truth Surfaces

Own:

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`

Pattern to copy:

- narrow row/block reconciliation from [07-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-02-PLAN.md:98)
- broader but still scoped closure sync from [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:114)

What this plan should do:

- make all three live tracker files tell the same current-state story
- mark the milestone as verification gaps closed and reconciliation complete
- keep the milestone explicitly open pending a fresh audit rerun

Why it should stand alone:

- these are the reader-facing "truth now" files
- they should be updated together, with exact assertions that they agree
- this is the highest-risk place for accidental overstatement

### Plan 9-03: Preserve Historical Audit and Add Re-Audit Readiness Bridge

Own:

- `.planning/v0.9-MILESTONE-AUDIT.md` or a tightly scoped companion/addendum surface if planning chooses one

Pattern to copy:

- use the same evidence-first, non-overclaiming tone as Phase 7 and 8 closure language in [ROADMAP.md](/Users/jon/projects/parapet/.planning/ROADMAP.md:51) and [ROADMAP.md](/Users/jon/projects/parapet/.planning/ROADMAP.md:61)
- follow the historical-preservation rules from [09-CONTEXT.md](/Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md:33)

What this plan should do:

- preserve the 2026-05-21 audit as historical fact
- add a concise note explaining which gaps are now closed by later proof/reconciliation
- point directly to the relevant `VERIFICATION.md` files and to the next command: `$gsd-audit-milestone`

Why it should stand alone:

- historical-audit handling is a different trust boundary from live tracker reconciliation
- keeping it separate reduces the chance of mutating the audit into a fake pass

### Plan 9-04: Centralize Repo-Root Doctrine

Own:

- `AGENTS.md`

What this plan should do:

- implement D-20 through D-22 in one canonical repo-root instruction surface
- keep the guidance concise and operational
- preserve the current assumptions-mode default from `.planning/config.json`

Why it should stand alone:

- file ownership is disjoint from milestone-truth artifacts
- it satisfies the locked doctrine decision without widening the other reconciliation plans

## Suggested Ownership Boundaries

Use these file boundaries in the plans:

| Plan | Files | Boundary |
| --- | --- | --- |
| `09-01` | `.planning/v0.9-phases/5/05-VALIDATION.md` | Proof-adjacent repair only |
| `09-02` | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` | Current truth surfaces only |
| `09-03` | `.planning/v0.9-MILESTONE-AUDIT.md` or scoped addendum | Historical bridge only |
| `09-04` | `AGENTS.md` | Canonical repo-root doctrine only |

## Verification Style to Reuse

Phase 9 plans should still have concrete verification commands, but they should be reconciliation checks rather than runtime-heavy test reruns.

Copy the assertion style from:

- [07-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-02-PLAN.md:78)
- [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:93)
- [08-02-PLAN.md](/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-02-PLAN.md:134)

Best fit for Phase 9:

- Python or `rg` assertions that `05-VALIDATION.md` now references `05-VERIFICATION.md`
- assertions that `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` all describe the same milestone position
- assertions that the audit surface still says the old audit found gaps, but now includes a pointer to later reconciliation evidence and the next-step re-audit command
- assertions that `AGENTS.md` includes the recommendation-first, assumptions-mode, low-escalation doctrine

## Repo-Specific Anti-Patterns

- Treating summary files as current closure truth. Phase 9 context explicitly forbids this; use summaries only as narrative support.
- Marking v0.9 "complete" or "passed" before a fresh audit rerun. The allowed posture is "re-audit-ready", not "audit passed".
- Rewriting [v0.9-MILESTONE-AUDIT.md](/Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md:119) into a retroactive success report.
- Updating `STATE.md` alone. In this repo, `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` must move together or drift returns immediately.
- Leaving [05-VALIDATION.md](/Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md:3) in `PLANNED` posture after Phase 5 proof already exists.
- Expanding scope into archived milestone snapshots, old summaries, or broader doctrine cleanup beyond the single bounded `AGENTS.md`.
- Re-running heavy proof suites by default. Phase 9 is a reconciliation phase; reruns are only for contradictions or missing proof.

## Planner Guidance

If the planner wants the safest shape, use:

1. `09-01` for proof-adjacent validation repair.
2. `09-02` for live tracker synchronization.
3. `09-03` for historical audit supersession and re-audit readiness.
4. `09-04` for repo-root doctrine centralization.

That matches the repo's established closure sequencing while respecting the special rule of Phase 9: **proof already exists; the work is to reconcile current truth, preserve historical truth, and stop short of claiming audit success.**
