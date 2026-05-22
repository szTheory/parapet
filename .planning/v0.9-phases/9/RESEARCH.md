# Phase 9: Reconcile Milestone Closure Artifacts - Research

**Researched:** 2026-05-22 [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
**Domain:** Planning-artifact reconciliation and milestone closure readiness. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
**Confidence:** HIGH. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/4/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

### Milestone closure posture
- **D-01:** Phase 9 should synchronize the live v0.9 tracking surfaces to "verification gaps closed, milestone still open, re-audit-ready" rather than claiming the milestone is already closed.
- **D-02:** The distinction between "requirements/phase proofs verified" and "milestone audit passed" must remain explicit in the reconciled wording.
- **D-03:** Phase 9 should optimize for principle of least surprise: readers opening the active top-level planning files should see one coherent current-state story without implied re-audit claims.

### Canonical truth hierarchy
- **D-04:** The artifact hierarchy for reconciliation is: fresh rerun proof if needed, then `VERIFICATION.md`, then `VALIDATION.md`, then execution summaries.
- **D-05:** Each phase `VERIFICATION.md` is the canonical closure artifact for milestone-wide reconciliation unless it is missing, stale, or contradicted by fresher evidence.
- **D-06:** `VALIDATION.md` remains a planning/sampling contract and may be reconciled for truthfulness, but it is not the closure-grade source of truth.
- **D-07:** Historical summaries remain implementation narrative only and must not drive milestone completion state.

### Phase 5 validation reconciliation
- **D-08:** `.planning/v0.9-phases/5/05-VALIDATION.md` should be rewritten into a current-state validation map that reflects completed proof rather than leaving `PLANNED` language in place.
- **D-09:** The Phase 5 validation file should explicitly point to `.planning/v0.9-phases/5/VERIFICATION.md` as the canonical closure proof while preserving the validation-vs-verification distinction.
- **D-10:** Phase 9 should prefer a hybrid validation posture for Phase 5: truthful current coverage plus a short note that the file was reconciled post-verification.

### Audit and re-audit handling
- **D-11:** `.planning/v0.9-MILESTONE-AUDIT.md` should remain a historical audit artifact from 2026-05-21 rather than being rewritten into a retroactive pass.
- **D-12:** The stale milestone audit should be clearly marked as superseded by later reconciliation evidence, with an explicit pointer to the proof artifacts that closed the original gaps.
- **D-13:** Phase 9 should add or update a short re-audit-readiness note that explains which original audit gaps are now covered and ends with the explicit next step: re-run `$gsd-audit-milestone`.
- **D-14:** No artifact produced by Phase 9 should imply that a fresh milestone audit has already passed.

### File-scope boundary
- **D-15:** Phase 9 should update only the files that define current milestone truth plus the singled-out stale validation artifact.
- **D-16:** In scope by default: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/v0.9-phases/5/05-VALIDATION.md`, and the active v0.9 audit/re-audit-readiness surface.
- **D-17:** Out of scope by default: older execution summaries, archived milestone snapshots under `.planning/milestones/`, and prior historical artifacts unless they contain a materially false claim that would still mislead after the top-level sync.

### Maintainer workflow preference
- **D-18:** Parapet should continue to use recommendation-first, codebase-first planning posture by default, with low-impact decisions shifted left into the agent workflow.
- **D-19:** `workflow.discuss_mode = "assumptions"` should remain the default interactive posture for this repo.
- **D-20:** The repo should centralize this doctrine in a canonical repo-root instruction surface rather than relying on repeated phase-local context files alone.
- **D-21:** Agents should escalate only when a choice changes public CLI/API contract, default install contents, auth ownership, dependency/support surface, runtime behavior, safety guarantees, operator semantics, durable evidence truth model, or irreversible schema/maintenance burden.
- **D-22:** Agents should also escalate when two medium-impact concerns move at once; otherwise they should auto-decide and state assumptions in the artifact instead of asking routine questions.

### Claude's Discretion [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
- Exact wording used to distinguish "verified", "reconciled", and "re-audit-ready", as long as the milestone is not overstated as closed.
- Exact location and format of the re-audit-readiness note, provided it clearly bridges the stale audit to the newer proof artifacts.
- Exact amount of cross-linking between top-level files and proof artifacts, provided the active truth surfaces remain easy to navigate and consistent.

### Deferred Ideas (OUT OF SCOPE) [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
- A broader, project-wide milestone-status taxonomy such as `implemented` / `verified` / `reconciled` / `closed` if repeated future milestones prove the extra ceremony worthwhile
- A machine-readable escalation rubric for GSD in addition to the recommended human-readable repo-root doctrine file
- Retroactive cleanup of older archived milestone snapshots or historical summaries beyond what is needed to avoid a materially misleading claim
</user_constraints>

## Summary

Phase 9 is a docs-truth reconciliation phase, not a feature phase and not a fresh runtime verification phase. The missing work after Phases 6 through 8 is that the active milestone trackers still lag the proof artifacts that now exist for Phases 1, 3, 4, and 5. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] [VERIFIED: /Users/jon/projects/parapet/.planning/REQUIREMENTS.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/4/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md]

The planner should treat `VERIFICATION.md` files as the canonical closure proofs, `VALIDATION.md` files as sampling maps that may need truthfulness cleanup, and summaries as historical implementation narrative only. That hierarchy is already locked in Phase 9 context and matches the stronger closure pattern used by Phases 6 through 8. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/03-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/phases/04-unified-install-path-dx/04-VALIDATION.md]

The highest-value Phase 9 outcome is a single coherent current-state story across `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `.planning/v0.9-phases/5/05-VALIDATION.md`, and the milestone audit surface, while preserving the historical audit as a dated pre-reconciliation artifact and explicitly telling the next human or agent to rerun `$gsd-audit-milestone`. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md]

**Primary recommendation:** Split Phase 9 into four narrow plans: Phase 5 validation reconciliation, live tracker synchronization, historical audit preservation, and a bounded repo-root doctrine surface that implements D-20 through D-22. Do not add new runtime proof unless an existing `VERIFICATION.md` is contradicted. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Current milestone completion truth | Active tracker files | Canonical proof artifacts | `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` are the reader-facing status surfaces, but they must defer to the phase verification reports for proof. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/parapet/.planning/REQUIREMENTS.md] [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Requirement closure truth | `VERIFICATION.md` artifacts | `VALIDATION.md` maps | The verified phase reports now exist for Phases 1, 3, 4, and 5, while `05-VALIDATION.md` is the only explicitly stale validation surface called out by the audit. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/4/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] |
| Historical audit integrity | `.planning/v0.9-MILESTONE-AUDIT.md` core findings | Supersession/addendum note | The audit must remain a dated `gaps_found` artifact from 2026-05-21, but it also must stop misleading readers after Phases 6 through 8 closed the cited gaps. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Re-audit readiness guidance | Active audit surface | `STATE.md` | The explicit next action belongs in current-state docs, not in historical summaries. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] |
| Maintainer workflow doctrine | `AGENTS.md` at repo root | `.planning/config.json` | D-20 through D-22 require one canonical repo-root instruction surface so agents inherit the recommendation-first, low-escalation doctrine without depending on repeated phase-local context. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json] |

## Standard Stack

### Core

| Artifact | Purpose | Why Standard |
|---------|---------|--------------|
| `.planning/v0.9-phases/*/VERIFICATION.md` | Canonical closure proof for completed phase claims. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] | Phases 1, 3, 4, and 5 already use these as the closure-grade source of truth. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/4/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md] |
| `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md` | Active milestone truth surfaces. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] | These are the exact top-level files the audit says are disagreeing today. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] |
| `.planning/v0.9-phases/5/05-VALIDATION.md` | Sampling-map surface that must be reconciled to current proof. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] | It is the only validation artifact still using `PLANNED` wording after verification landed. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] |

### Supporting

| Artifact | Purpose | When to Use |
|---------|---------|-------------|
| `.planning/v0.9-MILESTONE-AUDIT.md` | Historical audit baseline and supersession target. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] | Use when explaining what was true on 2026-05-21 and what later proof closed. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| `AGENTS.md` | Canonical repo-root maintainer doctrine surface. [ASSUMED] | Use to centralize D-18 through D-22 in one root instruction file aligned to `.planning/config.json` and current planning posture. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json] |
| `rg`, `sed`, and `git diff --name-only` | File-scope verification for reconciliation work. [ASSUMED] | Use to prove wording, links, and allowed-file boundaries without inventing runtime claims. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Editing summaries into current truth | Keep summaries historical and point active surfaces at verification files | This matches the locked truth hierarchy and avoids retroactive fiction. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Rewriting the audit into a pass | Add a dated supersession note to the historical audit surface | This preserves the original 2026-05-21 audit result while making re-audit next steps obvious. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Broad repo-governance expansion in this phase | Create one narrow repo-root instruction surface only | D-20 is locked, so Phase 9 should add a bounded `AGENTS.md` that centralizes D-18 through D-22 without expanding into broader process redesign. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json] |

**Installation:** No package or runtime dependencies should be added for this phase. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

## Recommended Plan Split

1. **Plan 09-01: Phase 5 validation reconciliation.** Rewrite `.planning/v0.9-phases/5/05-VALIDATION.md` into the same current-state posture already used by Phase 1, Phase 3, and Phase 4 validation artifacts while keeping `.planning/v0.9-phases/5/VERIFICATION.md` canonical. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md]
2. **Plan 09-02: Active milestone truth sync.** Update only `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md` so they all say the same thing: all phase proofs are now present, milestone closure artifacts are reconciled, and a fresh milestone audit is still pending. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/parapet/.planning/REQUIREMENTS.md] [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
3. **Plan 09-03: Audit supersession cleanup.** Add a dated supersession/re-audit-readiness note to `.planning/v0.9-MILESTONE-AUDIT.md` without changing its original scorecard or `gaps_found` history. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md]
4. **Plan 09-04: Repo-root doctrine centralization.** Create a narrow `AGENTS.md` that captures the recommendation-first, assumptions-mode, low-escalation doctrine from D-18 through D-22 without expanding into unrelated governance cleanup. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json]

## Truth-Source Hierarchy

1. Fresh rerun proof only if an existing proof artifact is missing, contradicted, or obviously stale. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
2. Phase `VERIFICATION.md` files are canonical for milestone closure claims. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
3. `VALIDATION.md` files may describe coverage and sampling, but they do not outrank verification reports. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
4. Execution summaries stay historical and must not be promoted into present-tense milestone truth. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

## File-Scope Boundaries

### Files that should change

| File | Required Change | Why |
|------|-----------------|-----|
| `.planning/ROADMAP.md` | Mark Phase 9 complete only when reconciliation work lands, and make the Phase 9 closure line explicitly say "re-audit-ready" rather than "audit passed". [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] | This is the active milestone phase ledger. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| `.planning/REQUIREMENTS.md` | Reconcile any remaining stale checklist truth, especially the unchecked `SCALE-02` bullet versus its already-verified traceability row. [VERIFIED: /Users/jon/projects/parapet/.planning/REQUIREMENTS.md] | Requirements should not disagree internally once proof exists. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] |
| `.planning/STATE.md` | Move current-position prose from "Phase 8 complete" to "Phase 9 reconciled / milestone awaiting re-audit", while keeping milestone-level status short of closure. [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| `.planning/v0.9-phases/5/05-VALIDATION.md` | Replace `PLANNED` wording with covered current-state validation language that points to `.planning/v0.9-phases/5/VERIFICATION.md`. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md] |
| `.planning/v0.9-MILESTONE-AUDIT.md` | Add a dated supersession/re-audit-readiness note that references the later proof artifacts and instructs the reader to rerun `$gsd-audit-milestone`, without altering the original audited date, `gaps_found` status, or scorecard tables. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| `AGENTS.md` | Add a concise repo-root instruction surface that centralizes D-18 through D-22 and points agents at `.planning/config.json` for the current assumptions-mode default. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json] |

### Files that must stay historical

| File/Group | Keep Historical Because |
|------------|-------------------------|
| `.planning/v0.9-phases/1/VERIFICATION.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/4/VERIFICATION.md`, `.planning/v0.9-phases/5/VERIFICATION.md` | They are already the proof surfaces that active trackers should cite, not rewrite. [VERIFIED: respective verification files] |
| `03-01-SUMMARY.md`, `03-02-SUMMARY.md`, `03-03-SUMMARY.md`, `04-01-SUMMARY.md`, `04-02-SUMMARY.md`, `04-03-SUMMARY.md`, `05-01-SUMMARY.md`, `05-02-SUMMARY.md`, `05-03-SUMMARY.md` | Summaries are implementation narrative and are explicitly not the milestone truth source. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| `.planning/milestones/` snapshots and prior context/discussion logs | Phase 9 explicitly scopes them out unless they contain a still-material false claim. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |

## Audit Supersession Approach

Use an addendum model, not a rewrite model. The recommended shape is a short note near the top of `.planning/v0.9-MILESTONE-AUDIT.md` that says the file remains the 2026-05-21 audit result, lists which later proof artifacts closed the original proof gaps, states that `05-VALIDATION.md` has been reconciled, and ends with "Next step: rerun `$gsd-audit-milestone`." [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

Do not rewrite the audit frontmatter from `status: gaps_found` to a pass state, and do not mutate the original scorecard tables into post-hoc success tables. Those values describe what was true on 2026-05-21 before Phase 6 through 8 proof landed. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Phase verification artifacts
  -> active truth reconciliation pass
      -> ROADMAP.md phase ledger
      -> REQUIREMENTS.md checklist + traceability
      -> STATE.md milestone narrative
      -> 05-VALIDATION.md current-state validation map
  -> historical audit supersession note
      -> v0.9-MILESTONE-AUDIT.md remains dated gaps_found artifact
          -> reader sees "what was true then"
          -> reader sees "what proof exists now"
          -> reader sees "rerun $gsd-audit-milestone next"
```

This is the least-surprise flow already implied by the current phase context and the closure pattern used in earlier v0.9 proof phases. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/6/06-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/7/07-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/8/08-CONTEXT.md]

### Recommended Project Structure

```text
.planning/
├── AGENTS.md                     # Canonical repo-root maintainer doctrine surface
├── ROADMAP.md                    # Active phase ledger
├── REQUIREMENTS.md               # Requirement checklist + traceability ledger
├── STATE.md                      # Current milestone narrative
├── v0.9-MILESTONE-AUDIT.md       # Historical audit plus supersession note
└── v0.9-phases/
    ├── 1/VERIFICATION.md         # Canonical proof
    ├── 3/VERIFICATION.md         # Canonical proof
    ├── 4/VERIFICATION.md         # Canonical proof
    └── 5/
        ├── VERIFICATION.md       # Canonical proof
        └── 05-VALIDATION.md      # Reconciled validation map
```

### Pattern 1: Proof-First Status Reconciliation

**What:** Update status files only after tracing each current-state claim back to an existing verification artifact. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

**When to use:** Use for every present-tense milestone claim in `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md`. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/parapet/.planning/REQUIREMENTS.md] [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md]

**Example:**

```markdown
**Closure:** Proof gaps are closed by `.planning/v0.9-phases/1/VERIFICATION.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/4/VERIFICATION.md`, and `.planning/v0.9-phases/5/VERIFICATION.md`; milestone close still requires a fresh `$gsd-audit-milestone` rerun.
```

Source pattern: direct-proof closure wording from Phase 7 and Phase 8 roadmap entries, adapted to milestone-wide reconciliation. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md]

### Pattern 2: Historical Audit Addendum

**What:** Preserve the old audit as a snapshot and append a dated note that explains what later changed. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

**When to use:** Use only in the milestone audit file, not in summaries or verification reports. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

**Example:**

```markdown
## Supersession Note

This audit remains the 2026-05-21 `gaps_found` result. Later closure work added `.planning/v0.9-phases/1/VERIFICATION.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, and `.planning/v0.9-phases/4/VERIFICATION.md`, and reconciled `.planning/v0.9-phases/5/05-VALIDATION.md`. Re-run `$gsd-audit-milestone` for a fresh milestone result.
```

Source pattern: historical-preservation rule from Phase 9 context, not an existing literal file block. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

### Pattern 3: Narrow Repo-Root Doctrine Surface

**What:** Create one concise repo-root `AGENTS.md` that centralizes D-18 through D-22 and aligns agent posture with `.planning/config.json`. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json]

**When to use:** Use in this phase because D-20 is locked and the repo currently lacks a canonical repo-root instruction surface. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

**Example:**

```markdown
# Agent Guidance

- Default to recommendation-first, codebase-first execution.
- Treat `.planning/config.json` `workflow.discuss_mode = "assumptions"` as the default interactive posture.
- Escalate only for public CLI/API, dependency/support, safety, operator-semantics, truth-model, or irreversible-maintenance changes.
```

Source pattern: locked workflow doctrine in Phase 9 context plus existing runtime config. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json]

### Anti-Patterns to Avoid

- **Retroactive pass language:** Do not say "v0.9 audit passed" anywhere until a new audit is actually rerun. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
- **Summary-driven reconciliation:** Do not use summary files as the reason a requirement is verified if a `VERIFICATION.md` exists. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
- **Validation-as-proof:** Do not let `05-VALIDATION.md` become the proof source; it should cite `VERIFICATION.md`. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
- **Broad repo-governance expansion inside closure cleanup:** Do not turn D-20 into a wide process rewrite. The allowed shape is one narrow repo-root instruction surface only. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Present-tense milestone truth | New status taxonomy or new proof document type | Existing `VERIFICATION.md` plus narrow tracker edits | The repo already established this proof contract in Phases 6 through 8. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/6/06-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/7/07-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/8/08-CONTEXT.md] |
| Audit supersession | Fresh "audit passed" fiction | Dated addendum/supersession note | It preserves historical accuracy and keeps the next action explicit. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Phase 5 validation cleanup | A bespoke format just for Phase 5 | The current-state validation posture already used by Phase 1, Phase 3, and Phase 4 | The repo already has working examples of post-proof validation language. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/03-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/phases/04-unified-install-path-dx/04-VALIDATION.md] |

**Key insight:** This phase should reuse the repo’s existing proof vocabulary and file roles, not invent a milestone-closure framework while trying to clean up milestone drift. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

## Wording Risks To Avoid

### Pitfall 1: Saying "closed" when you only mean "proof gaps reconciled"

**What goes wrong:** Readers infer that milestone audit closure already happened. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
**Why it happens:** `Verified`, `complete`, `reconciled`, and `closed` are easy to blur together in milestone prose. [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md]
**How to avoid:** Use "verified" for phase proof, "reconciled" for tracker alignment, and "re-audit-ready" for milestone posture. Reserve "passed" or "closed" for a fresh audit result only. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
**Warning signs:** Phrases like "v0.9 is done", "milestone passed", or "audit complete" appear in active trackers before rerunning `$gsd-audit-milestone`. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

### Pitfall 2: Treating the stale audit as current truth

**What goes wrong:** Top-level docs keep implying proof gaps still exist even though later verification files closed them. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/4/VERIFICATION.md]
**Why it happens:** The audit is a strong artifact and currently still reads as the latest whole-milestone story. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md]
**How to avoid:** Mark it as a historical 2026-05-21 result and add a supersession note that points to later proof. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
**Warning signs:** The audit remains unannotated while `STATE.md` or `ROADMAP.md` claim broader progress. [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md]

### Pitfall 3: Letting the D-20 doctrine task sprawl beyond one bounded repo-root surface

**What goes wrong:** A milestone cleanup plan turns into repo-governance work. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
**Why it happens:** D-20 requires a repo-root doctrine surface, but D-15 through D-17 still demand a tightly bounded reconciliation phase. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
**How to avoid:** Limit the doctrine work to one concise `AGENTS.md` that centralizes D-18 through D-22 and references `.planning/config.json`, with no wider contributor-doc or config churn. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json]
**Warning signs:** Plans start editing multiple repo-process docs, changing config defaults, or inventing a new governance taxonomy beyond the locked doctrine. [ASSUMED]

## Verification Commands

These commands prove reconciliation at the file layer and avoid inventing new runtime claims. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

### Active truth surfaces

```bash
sed -n '60,95p' .planning/ROADMAP.md
sed -n '30,70p' .planning/REQUIREMENTS.md
sed -n '1,90p' .planning/STATE.md
```

These commands should show one consistent story: verified proof gaps are closed, Phase 9 performed reconciliation, and the milestone still awaits a fresh audit rerun. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/parapet/.planning/REQUIREMENTS.md] [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md]

### Proof cross-links

```bash
rg -n 'VERIFICATION\.md|re-audit|reconcile|SCALE-02|Phase 9' \
  .planning/ROADMAP.md \
  .planning/REQUIREMENTS.md \
  .planning/STATE.md \
  .planning/v0.9-phases/5/05-VALIDATION.md \
  .planning/v0.9-MILESTONE-AUDIT.md
```

This proves the reconciled files point to canonical proof surfaces instead of summaries. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

### Phase 5 validation cleanup

```bash
sed -n '1,220p' .planning/v0.9-phases/5/05-VALIDATION.md
rg -n 'PLANNED|VERIFICATION\.md|COVERED|verified' .planning/v0.9-phases/5/05-VALIDATION.md
```

The success condition is that `05-VALIDATION.md` now resembles the current-state posture of Phase 1, Phase 3, and Phase 4 validation files rather than the original planned-only grid. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/03-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/phases/04-unified-install-path-dx/04-VALIDATION.md]

### Historical audit supersession

```bash
sed -n '1,70p' .planning/v0.9-MILESTONE-AUDIT.md
rg -n 'Supersession|re-audit|2026-05-21|VERIFICATION\.md|05-VALIDATION' .planning/v0.9-MILESTONE-AUDIT.md
```

The success condition is that the historical audit remains visibly dated and `gaps_found`, but no longer misleads readers about current proof coverage. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

### Allowed file boundary

```bash
git diff --name-only -- .planning
```

The resulting file list should stay within the bounded active-truth set plus one narrow repo-root instruction surface for D-20, unless execution finds a materially misleading live artifact. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

## Code Examples

Verified patterns from repo sources:

### Phase 5 validation row posture

```markdown
| SCALE-02 multi-node or concurrency simulation | `.planning/v0.9-phases/5/VERIFICATION.md` reruns the targeted concurrency suite and remains the canonical closure artifact for this phase. | COVERED |
```

Source pattern: current-state validation rows in Phase 1 and Phase 3. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/03-VALIDATION.md]

### State wording posture

```markdown
**Current focus:** Phase 9 artifact reconciliation is complete. v0.9 proof gaps are closed and the milestone is ready for a fresh `$gsd-audit-milestone` rerun, but the audit itself has not yet been rerun.
```

Source pattern: current-position prose in `STATE.md`, adapted to the locked non-overclaim posture. [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Summary-only or validation-only closure claims. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] | Dedicated `VERIFICATION.md` artifacts as milestone-close proof. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/4/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md] | By 2026-05-21 across Phases 6 through 8. [VERIFIED: verification file headers] | Phase 9 should reconcile trackers to that proof model instead of inventing new proof work. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Planned-only validation wording in Phase 5. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] | Current-state validation wording that cites canonical proof. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/03-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/phases/04-unified-install-path-dx/04-VALIDATION.md] | Phase 9 target. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] | Makes Nyquist surfaces truthful without recasting them as proof artifacts. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Unannotated historical audit. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] | Historical audit plus supersession/re-audit note. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] | Phase 9 target. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] | Readers can distinguish "what was true then" from "what is true now." [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |

**Deprecated/outdated:**
- `PLANNED` wording inside `.planning/v0.9-phases/5/05-VALIDATION.md` is outdated once `.planning/v0.9-phases/5/VERIFICATION.md` exists. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md]
- Treating `STATE.md` progress or summary files as stronger than canonical verification reports is outdated relative to the locked Phase 9 hierarchy. [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `rg`, `sed`, and `git diff --name-only` are available in the execution environment for future reconciliation verification. [ASSUMED] | Standard Stack; Verification Commands | The planner may need alternate shell probes if one of those tools is unavailable. |
| A2 | The recommended top-of-file supersession note can be added to `.planning/v0.9-MILESTONE-AUDIT.md` without conflicting with any external parser. [ASSUMED] | Audit Supersession Approach | The planner may need to move the note below frontmatter or use a separate addendum file if a parser is strict. |

## Open Questions (RESOLVED)

1. **Should the repo-root doctrine surface be created in Phase 9?**
   - Resolution: Yes. D-20 is a locked decision, so Phase 9 must include a narrow repo-root doctrine plan rather than deferring it.
   - Boundaries: Keep the implementation to a single `AGENTS.md` that centralizes D-18 through D-22 and references `.planning/config.json`; do not expand into broader governance cleanup or additional process docs. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Shell-level artifact assertions over tracked planning files. [ASSUMED] |
| Config file | none. [VERIFIED: /Users/jon/projects/parapet/.planning/config.json] |
| Quick run command | `rg -n 'VERIFICATION\\.md|re-audit|SCALE-02|Phase 9|recommendation-first|assumptions|AGENTS' .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md .planning/v0.9-phases/5/05-VALIDATION.md .planning/v0.9-MILESTONE-AUDIT.md AGENTS.md` [ASSUMED] |
| Full suite command | `sed -n '60,95p' .planning/ROADMAP.md && sed -n '30,70p' .planning/REQUIREMENTS.md && sed -n '1,90p' .planning/STATE.md && sed -n '1,220p' .planning/v0.9-phases/5/05-VALIDATION.md && sed -n '1,80p' .planning/v0.9-MILESTONE-AUDIT.md && sed -n '1,120p' AGENTS.md` [ASSUMED] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MCR-01 | Active truth surfaces agree that proof gaps are closed and a new audit is still pending. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] [VERIFIED: /Users/jon/projects/parapet/.planning/STATE.md] | doc assertion | `rg -n 're-audit|Phase 9|Verified|SCALE-02' .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md` [ASSUMED] | ✅ |
| MCR-02 | Phase 5 validation no longer presents proof as planned work. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md] | doc assertion | `rg -n 'VERIFICATION\\.md|COVERED|verified' .planning/v0.9-phases/5/05-VALIDATION.md` [ASSUMED] | ✅ |
| MCR-03 | Historical audit remains historical but points readers to later proof and rerun instructions. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] | doc assertion | `rg -n 'Supersession|re-audit|2026-05-21|VERIFICATION\\.md' .planning/v0.9-MILESTONE-AUDIT.md` [ASSUMED] | ✅ |
| MCR-04 | Repo-root doctrine exists and centralizes the default assumptions-mode, recommendation-first, low-escalation agent posture. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/config.json] | doc assertion | `rg -n 'recommendation-first|codebase-first|assumptions|discuss_mode|escalate only|public CLI/API|truth model|AGENTS' AGENTS.md` [ASSUMED] | ✅ |

### Sampling Rate

- **Per task commit:** Re-run the `rg` proof-cross-link command. [ASSUMED]
- **Per wave merge:** Re-run all `sed` block inspections plus `git diff --name-only -- .planning`. [ASSUMED]
- **Phase gate:** Confirm the bounded six-file-plus-root-surface scope and the non-overclaim wording before marking Phase 9 complete. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]

### Wave 0 Gaps

None. Existing repository shell tooling is sufficient because this phase reconciles tracked markdown artifacts only. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] | This phase does not change runtime auth behavior. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| V3 Session Management | no. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] | This phase changes planning artifacts only. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| V4 Access Control | no. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] | The scope excludes changes to install defaults, auth ownership, or operator semantics. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| V5 Input Validation | yes. [ASSUMED] | Constrain edits to allowed files and validate wording with exact file-level assertions before completion. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| V6 Cryptography | no. [VERIFIED: /Users/jon/projects/parapet/.planning/ROADMAP.md] | No cryptographic behavior changes are in scope. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False milestone-closure wording | Repudiation | Keep "verified", "reconciled", and "re-audit-ready" distinct; reserve "passed" for a fresh audit. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Historical artifact rewrite that destroys audit provenance | Tampering | Use an addendum or supersession note instead of rewriting the audit result. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |
| Scope drift into unrelated planning or repo-governance work | Denial of service | Enforce the bounded file set plus one narrow `AGENTS.md`; do not expand into additional process-doc cleanup. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `/Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md` - locked Phase 9 scope, truth hierarchy, file boundaries, and wording constraints.
- `/Users/jon/projects/parapet/.planning/ROADMAP.md` - active Phase 9 goal, scope, and current roadmap posture.
- `/Users/jon/projects/parapet/.planning/REQUIREMENTS.md` - current requirement checklist and traceability state.
- `/Users/jon/projects/parapet/.planning/STATE.md` - current milestone narrative and progress posture.
- `/Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md` - historical audit result and drift diagnosis.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/1/VERIFICATION.md` - canonical proof for Phase 1.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md` - canonical proof for Phase 3.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/4/VERIFICATION.md` - canonical proof for Phase 4.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md` - canonical proof for Phase 5.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md` - stale validation artifact that Phase 9 must reconcile.
- `/Users/jon/projects/parapet/AGENTS.md` - new canonical repo-root instruction surface required by D-20.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/1/VALIDATION.md` - current-state validation analog.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/3/03-VALIDATION.md` - current-state validation analog.
- `/Users/jon/projects/parapet/.planning/phases/04-unified-install-path-dx/04-VALIDATION.md` - current-state validation analog.

### Secondary (MEDIUM confidence)

- `/Users/jon/projects/parapet/.planning/phases/05-multi-node-safety-verification/05-CONTEXT.md` - maintainer planning posture precedent.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/6/06-CONTEXT.md` - proof-first reconciliation precedent.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/7/07-CONTEXT.md` - narrow closure precedent.
- `/Users/jon/projects/parapet/.planning/v0.9-phases/8/08-CONTEXT.md` - direct precedent that milestone-wide synchronization remains Phase 9 work.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - this phase reuses existing planning artifact roles that are already present in the repo. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/1/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/4/VERIFICATION.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/VERIFICATION.md]
- Architecture: HIGH - file scope, truth hierarchy, and non-overclaim posture are explicitly locked in Phase 9 context. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
- Pitfalls: HIGH - the exact drift conditions and stale Phase 5 validation issue are already documented by the milestone audit and current file contents. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/5/05-VALIDATION.md]

**Research date:** 2026-05-22. [VERIFIED: /Users/jon/projects/parapet/.planning/v0.9-phases/9/09-CONTEXT.md]
**Valid until:** 2026-06-21 for this repo state, or until any of the cited proof or planning artifacts change. [ASSUMED]
