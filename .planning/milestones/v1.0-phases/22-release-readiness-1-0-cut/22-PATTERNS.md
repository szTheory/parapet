# Phase 22: Release Readiness & 1.0 Cut - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 8 current release/CI/planning surfaces
**Analogs found:** 7 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` | CI config | workflow fan-in | self (existing `test`/`demo`/`release_gate`) | exact |
| `.github/workflows/release-please.yml` | release automation | release event -> publish | self (existing RP workflow) | exact |
| `release-please-config.json` | release config | config -> Release Please state | self | exact |
| `.planning/phases/22-release-readiness-1-0-cut/22-VERIFICATION.md` | verification truth surface | commands + manual checks | `.planning/phases/20-governance-docs-completeness/20-VERIFICATION.md` | role-match |
| `.planning/phases/22-release-readiness-1-0-cut/22-VALIDATION.md` | validation strategy | sampling/feedback | `.planning/phases/20-governance-docs-completeness/20-VALIDATION.md` | exact |
| `22-01-PLAN.md` | execution plan | CI topology | `21-04-PLAN.md` | role-match |
| `22-02-PLAN.md` | execution plan | release workflow | no close numbered analog; use current plan schema | exact-by-schema |
| `22-04-PLAN.md` | execution plan | external staged release cut | `21-06-PLAN.md` | role-match |

---

## Reusable Patterns

### 1. Stable Fan-In Gate Pattern

**Source:** `.github/workflows/ci.yml`

Current shape:
- `test`
- `demo`
- `release_gate` with `needs: [test, demo]`

Phase 22 pattern:
- introduce `lint`
- keep `test`
- keep `demo`
- expand `release_gate` to `needs: [lint, test, demo]`

Why this pattern:
- It preserves the single operator-facing check name already required by branch protection.
- It isolates failure classes without changing the merge-protection contract.

### 2. Self-Analog Workflow Extension Pattern

**Source:** `.github/workflows/release-please.yml`

Current shape:
- one `release-please` job
- Release Please step id `release`

Phase 22 pattern:
- keep the current job untouched as the release-creation step
- add a second job conditioned on `needs.release-please.outputs.release_created == 'true'`
- consume the created release context rather than inventing a second release mechanism

Why this pattern:
- D-06 explicitly forbids replacing Release Please.
- The existing workflow already exposes the right handoff point.

### 3. Config-Only Version Choreography Pattern

**Source:** `release-please-config.json` plus `.release-please-manifest.json`

Pattern:
- configuration changes happen in `release-please-config.json`
- state changes happen only when Release Please merges/tags
- the manifest is read for truth, never edited by hand

Why this pattern:
- It preserves the release system's state model and avoids "papering over" an out-of-date manifest with a manual edit.

### 4. Honest External Checkpoint Pattern

**Source:** `21-06-PLAN.md`

Pattern:
- keep repo-file changes in autonomous plans
- isolate external GitHub/Hex/manual release actions in a final plan or checkpoint
- make the resume signal explicit

Why this pattern:
- Phase 22 includes irreducibly external truth: Hex publish, HexDocs resolution, final release tag existence.
- The plan should not imply those steps are reproducible solely inside the working tree.

### 5. Proof-First Verification Artifact Pattern

**Source:** `20-VERIFICATION.md`, `21-VERIFICATION.md`

Pattern:
- enumerate exact truths
- separate automated commands from human-only verification
- keep gap language precise and bounded

Phase 22 application:
- one release verification artifact should state exactly which commands must be green before the cut
- it should also name the manual cold-start walkthrough and the post-publish URL checks explicitly

---

## Phase-Specific Recommendations

### `.github/workflows/ci.yml`

Recommended structure:
- `lint`: format, credo, dialyzer, verify.public_api, compile/docs warnings-as-errors
- `test`: `mix test`
- `demo`: smoke test
- `release_gate`: fan-in only

Avoid:
- putting `mix test` back in `lint`
- changing the `release_gate` job name
- duplicating expensive commands across jobs without need

### `.github/workflows/release-please.yml`

Recommended structure:
- preserve current `release-please` job
- add a `publish-hex` job with:
  - `needs: release-please`
  - `if: needs.release-please.outputs.release_created == 'true'`
  - Beam setup and deps install
  - `mix hex.publish --dry-run`
  - `mix hex.publish --yes`
  - post-publish verify commands

Avoid:
- unconditional publish on every push
- splitting dry-run and real publish into different workflows/jobs

### `release-please-config.json`

Recommended structure:
- keep current `0.10.0` pin until the real tag exists
- use a one-time `1.0.0` pin only after all prep work merges
- remove the one-time pin and both pre-major bump flags immediately after the 1.0.0 cut

Avoid:
- editing `.release-please-manifest.json`
- removing `release-as: "0.10.0"` early

---

## Suggested Ownership Boundaries

| Plan | Primary Files | Boundary |
|------|---------------|----------|
| 22-01 | `.github/workflows/ci.yml` | CI topology only; do not mix in release-config choreography |
| 22-02 | `.github/workflows/release-please.yml` | publish automation only; do not change version semantics here |
| 22-03 | `22-VERIFICATION.md`, maybe small helper wiring | truth surface only; do not rewrite CI topology again |
| 22-04 | `release-please-config.json`, release checklist docs | version choreography and external operator sequence only |

---

## Anti-Patterns to Avoid

### Renaming `release_gate`

Why it's bad:
- Branch protection already references `release_gate`.
- Renaming it widens operator semantics and needlessly creates external churn.

### Treating green local commands as sufficient release proof

Why it's bad:
- REL-03 explicitly includes manual cold-start walkthrough and post-publish URL resolution.
- A local command pass is necessary but not sufficient.

### Conflating stale historical verification with current truth

Why it's bad:
- `21-VERIFICATION.md` still records the old branch-protection gap.
- Current truth should be noted in Phase 22 research/plans without rewriting the historical report.

---

## Planner Guidance

- Keep the phase at **four plans**. Any finer split becomes bookkeeping; any coarser split hides the external gating and version choreography risks.
- Front-load CI and workflow mechanics because they are executable now.
- Put the final release transition last and mark it explicitly staged on the real `v0.10.0` tag.
- Preserve operator-facing contracts already in place: `release_gate`, `HEX_API_KEY`, Release Please ownership, and the no-manifest-edit rule.
