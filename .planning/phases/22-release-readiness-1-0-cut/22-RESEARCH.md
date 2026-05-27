# Phase 22: Release Readiness & 1.0 Cut - Research

**Researched:** 2026-05-26
**Domain:** CI hardening, Release Please/Hex publish flow, release verification, 1.0 graduation sequencing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Completion boundary**
- D-01: Phase 22 can land prep work before the final cut, but it cannot claim completion until Phase 21's remaining proof is closed and the real `v0.10.0` tag exists.
- D-02: Treat the phase as two sub-stages: prep work first, then the graduation cut after blockers clear.

**CI hardening (REL-01)**
- D-03: A dedicated release-quality lint lane must own `mix compile --warnings-as-errors`, `mix compile --no-optional-deps --warnings-as-errors`, `mix docs --warnings-as-errors`, `mix credo --strict`, `mix dialyzer`, and `mix verify.public_api`.
- D-04: Keep `mix test` in its own job and keep `release_gate` as the branch-protection fan-in target.
- D-05: Demo asset-pipeline issues stay Phase 21 scope unless they directly break release proof.

**Hex publish automation (REL-02)**
- D-06: Extend `.github/workflows/release-please.yml`; do not replace Release Please.
- D-07: Publish sequence is fixed: `mix hex.publish --dry-run` -> `mix hex.publish --yes` -> post-publish verify.
- D-08: Use `HEX_API_KEY` as the repo secret name.
- D-09: Post-publish verification must prove both Hex package visibility and HexDocs visibility.

**Proportionate verification gate (REL-03)**
- D-10: Required proof surface is `mix verify.public_api`, `mix test`, `mix credo --strict`, `mix dialyzer`, `mix compile --no-optional-deps --warnings-as-errors`, and one manual cold-start walkthrough.
- D-11: The manual walkthrough is the already-scoped adopter trust proof, not a new broad UAT program.
- D-12: Do not widen the phase into security audit, perf reruns, multi-version CI matrix, SHA pinning, or demo Compose.

**Release Please graduation sequence (REL-04)**
- D-13: Do not remove `release-as: "0.10.0"` until `v0.10.0` actually exists.
- D-14: After `v0.10.0` exists, remove that pin; only after all prep work is merged should `release-as: "1.0.0"` be added.
- D-15: Immediately after the 1.0.0 tag exists, remove `release-as: "1.0.0"` and both pre-major bump flags.
- D-16: Do not hand-edit `.release-please-manifest.json`.

### Verified Current State

- `.github/workflows/ci.yml` currently has `test`, `demo`, and `release_gate`, but no dedicated `lint` job and no warnings-as-errors/doc gate.
- `release_gate` is already configured as a required GitHub branch-protection check on `main` (verified 2026-05-26 via `gh api .../required_status_checks` returning `release_gate` instead of 404).
- `mix compile --warnings-as-errors` succeeds in the root app as of 2026-05-26.
- `mix docs --warnings-as-errors` succeeds in the root app as of 2026-05-26.
- `.github/workflows/release-please.yml` currently runs Release Please only; it has no publish job.
- `release-please-config.json` still pins `release-as: "0.10.0"` and still carries `bump-minor-pre-major` plus `bump-patch-for-minor-pre-major`.
- `.release-please-manifest.json` still reads `"0.9.0"`.
- Local git tags include `v0.10` but not `v0.10.0`, so the graduation blocker remains live.

### Claude's Discretion

- Exact job name for the new release-quality lane (`lint` is the clearest choice).
- Exact split between automated verification doc, release checklist, and helper alias/script, as long as the truth surface stays explicit and proportionate.
- Exact post-publish verification commands, as long as they prove Hex package resolution and `https://hexdocs.pm/parapet/1.0.0/`.

### Deferred Ideas (OUT OF SCOPE)

- Multi-version Elixir / OTP matrix, SHA-pinned Actions, security audit, perf rerun, logo/favicon, `MAINTAINING.md`, and demo Docker Compose remain deferred beyond v1.0.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | CI enforces warnings-as-errors compile/docs in the lint lane | Current root commands are already green; work is CI topology plus command placement |
| REL-02 | Release Please publishes to Hex on created release with dry-run, publish, and post-publish verify | Existing workflow is the extension point; publish job is missing |
| REL-03 | A documented proportionate pre-release verification gate exists and is executable | Existing proof commands already exist; phase must codify them into one honest truth surface |
| REL-04 | The `0.10.0 -> 1.0.0` Release Please graduation sequence is documented and executable without manifest edits | Current config/manfiest mismatch proves the blocker and the required sequence |
</phase_requirements>

---

## Summary

Phase 22 should split into four plans:

1. **CI hardening**: introduce a dedicated `lint` job, move non-test release-quality gates there, and keep `release_gate` as the single branch-protection target.
2. **Release Please publish automation**: extend the existing release workflow with a gated Hex publish job that runs only when Release Please actually creates a release.
3. **Verification truth surface**: create the proportionate release verification artifact and any small helper wiring needed to make the gate executable and reviewable.
4. **Graduation sequence**: land the `0.10.0 -> 1.0.0` config choreography and operator checklist, but keep the final cut explicitly blocked on the real `v0.10.0` tag and final manual checks.

Two live facts narrow the work:

- The root library already passes `mix compile --warnings-as-errors` and `mix docs --warnings-as-errors`, so REL-01 is no longer a code cleanup task; it is CI enforcement and job topology.
- `release_gate` branch protection is already active, so the old Phase 21 verification report is partially stale. Phase 22 should consume the current truth, not re-plan that solved external step.

The one still-live external blocker is the Release Please state transition: config still pins `0.10.0`, the manifest still says `0.9.0`, and no `v0.10.0` tag is present locally. That makes REL-04 inherently staged: prep can land now, graduation cannot complete honestly until the tag exists.

---

## Architectural Responsibility Map

| Capability | Primary Surface | Secondary Surface | Rationale |
|------------|-----------------|------------------|-----------|
| Release-quality CI gates | `.github/workflows/ci.yml` | `mix.exs` aliases only if needed | CI already owns `test`, `demo`, and `release_gate`; Phase 22 should restructure that workflow rather than inventing a second gate |
| Release creation and publish | `.github/workflows/release-please.yml` | `release-please-config.json` | Release Please already owns version/tag state; publish must hang off its `release_created` output |
| Version graduation semantics | `release-please-config.json` | `.release-please-manifest.json` (read-only state) | Config changes are allowed; manifest hand-edits are forbidden |
| Release proof and checklist | `.planning/phases/22-release-readiness-1-0-cut/*` and possibly docs/README surfaces | GitHub/Hex/HexDocs manual checks | The phase needs an honest operator-visible truth artifact for the cut |

---

## Recommended Plan Split

### Plan 22-01: CI Hardening and Gate Topology

Scope:
- Add a dedicated `lint` job for release-quality static/build gates.
- Move `credo`, `dialyzer`, `verify.public_api`, and warnings-as-errors compile/docs checks out of `test`.
- Keep `test` focused on `mix test`.
- Keep `demo` intact and `release_gate` fan-in stable.

Why first:
- REL-01 is the cleanest prep task because the underlying commands are already green.
- It makes the release gate explicit before publish automation and release-cut docs depend on it.

### Plan 22-02: Release Please Hex Publish Flow

Scope:
- Extend `.github/workflows/release-please.yml` with a publish job gated on `release_created == 'true'`.
- Set up Beam, install deps, run `mix hex.publish --dry-run`, then `mix hex.publish --yes`, then post-publish verification commands.
- Use `HEX_API_KEY`; do not change release ownership semantics.

Why second:
- This is the core REL-02 automation and depends only on the existing workflow topology, not on the final graduation cut being ready.

### Plan 22-03: Proportionate Verification Truth Surface

Scope:
- Create the phase verification/checklist artifact that names the exact automated and manual release gate.
- Optionally add a helper alias or small script if that materially reduces operator error, but do not hide the real commands.
- Fold in the current external truth: `release_gate` required check already exists; final manual cold-start and post-publish URL checks remain.

Why third:
- REL-03 needs to reflect the final CI topology and publish flow, so it belongs after Plans 01 and 02 define those surfaces.

### Plan 22-04: Release Please Graduation Sequence

Scope:
- Update `release-please-config.json` and phase docs/checklists to codify the exact `0.10.0 -> 1.0.0` sequence.
- Preserve the explicit blocker: do not remove the `0.10.0` pin before `v0.10.0` exists.
- Capture the post-merge cleanup of `release-as: "1.0.0"` and the two pre-major bump flags.

Why last:
- It is the most externally gated plan and the only one that cannot be fully completed until the `v0.10.0` release/tag exists.

---

## File-Scope Recommendations

### Files that should change

| File | Why |
|------|-----|
| `.github/workflows/ci.yml` | Introduce dedicated `lint` job and preserve `release_gate` fan-in |
| `.github/workflows/release-please.yml` | Add publish job keyed off `release_created` |
| `release-please-config.json` | Finalize the 1.0 graduation semantics and remove pre-1.0 flags at the right time |
| `.planning/phases/22-release-readiness-1-0-cut/22-VERIFICATION.md` or equivalent | Honest release verification truth surface |
| `.planning/phases/22-release-readiness-1-0-cut/22-VALIDATION.md` | Sampling/verification contract for execution |

### Files that must stay read-only or state-owned

| File | Why |
|------|-----|
| `.release-please-manifest.json` | Release Please state; do not hand-edit |
| `.planning/phases/21-runnable-demo-app/21-VERIFICATION.md` | Historical verification report, even though one branch-protection claim is stale |

---

## Risks and Anti-Patterns

### 1. Overloading `test` again

Risk:
- Putting release-quality gates and `mix test` in one job makes failures less legible and violates D-03/D-04.

Avoidance:
- Make `lint` own the static/build/release-quality commands and let `test` own only the test suite.

### 2. Publishing outside the Release Please release event

Risk:
- A manually triggered or always-on publish job could publish the wrong tree or version.

Avoidance:
- Gate the publish job on Release Please's `release_created` output and run dry-run plus real publish in the same job.

### 3. Premature `0.10.0` pin removal

Risk:
- Removing `release-as: "0.10.0"` while the manifest is still `0.9.0` invites a wrong next version computation.

Avoidance:
- Treat the tag existence as a hard precondition, not a suggestion.

### 4. Hiding manual truth behind automation theater

Risk:
- REL-03 could become a vague "run some commands" doc that does not clearly call out the manual cold-start walkthrough and post-publish URL checks.

Avoidance:
- Keep the truth surface explicit, bounded, and operator-readable.

---

## Verification Commands to Reuse

### Already green locally

- `mix compile --warnings-as-errors`
- `mix docs --warnings-as-errors`

### Required release proof surface

- `mix verify.public_api`
- `mix test`
- `mix credo --strict`
- `mix dialyzer`
- `mix compile --no-optional-deps --warnings-as-errors`

### External truth checks

- `gh api repos/szTheory/parapet/branches/main/protection/required_status_checks --jq '.checks'`
- `gh release view v1.0.0` or equivalent release presence check after cut
- `curl -I https://hexdocs.pm/parapet/1.0.0/`

---

## Conclusion

Phase 22 is now mostly release mechanics, not code hardening. The library already satisfies the two highest-risk warnings/doc commands locally, and the `release_gate` branch-protection prerequisite is already live. The planning emphasis should therefore stay tight:

- enforce the release-quality commands in CI,
- wire publish into Release Please,
- make the verification gate explicit and honest,
- and sequence the `0.10.0 -> 1.0.0` config transition without touching manifest state early.

The final cut remains externally blocked on the real `v0.10.0` tag, so the last plan must preserve that truth rather than pretending the graduation can be completed immediately.
