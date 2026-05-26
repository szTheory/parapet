# Phase 22: Release Readiness & 1.0 Cut - Context

**Gathered:** 2026-05-25 (assumptions mode)
**Status:** Ready for planning

## Execution Update (2026-05-26)

- Phase 22 prep-stage repo work is in progress.
- The release workflow now has a gated `publish-hex` job that only runs when Release Please reports `release_created == true`.
- The canonical release gate now lives in `22-VERIFICATION.md`.
- The graduation blocker is still live and unchanged:
  - `release-please-config.json` still pins `release-as: "0.10.0"`
  - `.release-please-manifest.json` still reads `"0.9.0"`
  - local tags still include `v0.10` but not the exact `v0.10.0`
- Because that blocker is still live, the config must remain as-is today. The `0.10.0 -> 1.0.0` choreography is documented here and in `22-VERIFICATION.md`, but the actual pin transition is deferred until the real external tag truth exists.

<domain>
## Phase Boundary

Land the final release-mechanics work that makes Parapet's `1.0.0` cut credible:
warnings-as-errors CI hardening, Hex publish automation from Release Please, a
proportionate pre-release verification gate, and the exact `0.10.0 -> 1.0.0`
graduation sequence.

Scope is **release scaffolding and verification only**. This phase does **not**
add runtime features, new integrations, new safety guarantees, or a full security /
performance hardening pass. It may be planned before all prerequisites are cleared,
but it cannot be marked complete until the external/tagging prerequisites below are
actually satisfied.

Covers requirements: REL-01, REL-02, REL-03, REL-04.
</domain>

<decisions>
## Implementation Decisions

### Release Blockers & Completion Boundary
- **D-01:** Phase 22 can land code and docs before the final cut, but it cannot claim
  completion until two blockers are cleared:
  1. Phase 21's open demo gaps are closed, especially the seeded Operator UI
     verification failures recorded in `21-VERIFICATION.md`.
  2. The pending Release Please `0.10.0` release has merged and created the exact
     `v0.10.0` tag. Current evidence: `.release-please-manifest.json` still reads
     `"0.9.0"`, `release-please-config.json` still pins `release-as: "0.10.0"`, and
     `git tag` shows `v0.10` but not `v0.10.0`.
- **D-02:** Treat Phase 22 as two sub-stages, not two different phases:
  - **Prep stage:** CI hardening, publish workflow, verification docs/scripts.
  - **Graduation stage:** execute the tagged release sequence once blockers are cleared.

### CI Hardening (REL-01)
- **D-03:** "Lint lane" means a dedicated CI job for release-quality static/build
  gates, not further overloading the current `test` job. The lane must run:
  `mix compile --warnings-as-errors`,
  `mix compile --no-optional-deps --warnings-as-errors`,
  `mix docs --warnings-as-errors`,
  plus the already-required strict static gates that matter to release quality
  (`mix credo --strict`, `mix dialyzer`, `mix verify.public_api`).
- **D-04:** The existing `test` job remains focused on `mix test`, and `demo` remains
  the smoke-contract job for `examples/demo_app`. `release_gate` should fan in all
  required jobs (`lint`, `test`, `demo`) so branch protection continues to point at a
  single stable check name.
- **D-05:** The warnings-as-errors work is specifically about the library repo, not the
  demo app's asset pipeline. Demo build/test issues belong to Phase 21 unless they
  directly block the release proof surface.

### Hex Publish Automation (REL-02)
- **D-06:** Extend the existing `.github/workflows/release-please.yml`; do not replace
  Release Please. The publish flow should be a second job gated on Release Please
  reporting `release_created == 'true'`.
- **D-07:** Publish sequence is locked by the roadmap:
  `mix hex.publish --dry-run` -> `mix hex.publish --yes` -> post-publish verify.
  Keep the dry-run immediately before the real publish in the same job so the exact
  tagged tree is what gets validated and published.
- **D-08:** Use the standard Hex secret (`HEX_API_KEY`) in GitHub Actions. This is an
  operator-owned repo secret and an external prerequisite for the live cut; Phase 22
  should wire the workflow assuming that secret name rather than inventing a custom one.
- **D-09:** Post-publish verification must include both package visibility and docs
  visibility. At minimum: confirm the Hex package resolves and `hexdocs.pm/parapet/1.0.0/`
  resolves after the release.

### Proportionate Verification Gate (REL-03)
- **D-10:** The release gate is intentionally proportionate, matching the milestone's
  chosen freeze depth. Required proof surface:
  `mix verify.public_api`,
  `mix test`,
  `mix credo --strict`,
  `mix dialyzer`,
  `mix compile --no-optional-deps --warnings-as-errors`,
  and one manual cold-start walkthrough.
- **D-11:** The manual cold-start walkthrough is the already-tracked adopter proof, not
  a new broad UAT program. It should validate the getting-started path and the runnable
  demo path as release trust artifacts, not introduce new exploratory scope.
- **D-12:** No security audit, perf benchmark rerun, multi-version Elixir/OTP matrix,
  SHA-pinned actions pass, or demo Docker Compose belongs in this phase. Those are
  explicitly post-1.0 or v1.1 maturity items.

### Release-Please Graduation Sequence (REL-04)
- **D-13:** Do **not** remove `release-as: "0.10.0"` until the `v0.10.0` release PR
  is merged and the exact `v0.10.0` tag exists. Removing it early risks incorrect
  version computation because the manifest still seeds `0.9.0`.
- **D-14:** After `v0.10.0` exists, immediately remove the `0.10.0` `release-as` pin.
  Then, after all Phase 22 prep work is merged, add `release-as: "1.0.0"` so Release
  Please proposes the correct graduation PR instead of a natural pre-1.0 bump.
- **D-15:** Immediately after the `1.0.0` release PR merges and tags, remove:
  - `release-as: "1.0.0"`
  - `bump-minor-pre-major`
  - `bump-patch-for-minor-pre-major`
  from `release-please-config.json`. These flags are pre-1.0 scaffolding and become
  misleading once the package has graduated.
- **D-16:** Do not hand-edit `.release-please-manifest.json` to force the transition.
  The manifest is Release Please state and should advance through the normal merge/tag
  flow. Configuration changes belong in `release-please-config.json`; state changes
  belong to Release Please.
- **D-18:** Execution staging for the real cut is explicit:
  1. **Now:** keep `release-please-config.json` exactly as committed with
     `release-as: "0.10.0"` and both pre-major bump flags intact.
  2. **After the exact `v0.10.0` tag exists:** remove the `0.10.0` `release-as` pin.
  3. **After all prep work is merged and green:** add a one-time `release-as: "1.0.0"`
     pin for the graduation Release Please PR.
  4. **Immediately after the exact `v1.0.0` tag exists:** remove `release-as: "1.0.0"`
     plus `bump-minor-pre-major` and `bump-patch-for-minor-pre-major`.
  5. **Never:** hand-edit `.release-please-manifest.json`.

### External Operator Steps
- **D-17:** Two tasks are external but in-scope for release truth and must be captured
  in the context rather than silently assumed:
  - Configure `release_gate` as a required GitHub branch-protection check on `main`
    if not already active after Phase 21 closure.
  - Ensure the `HEX_API_KEY` secret exists before the live publish run.

### Claude's Discretion
- Exact CI job naming and whether `lint` is a new job or a renamed/restructured
  version of the current `test` job, as long as the release-quality commands are
  isolated and `release_gate` remains the branch-protection target.
- Exact post-publish verification commands, as long as they prove both Hex and
  HexDocs resolution for the tagged release.
- Exact artifact shape for documenting the manual cold-start walkthrough
  (`22-VERIFICATION.md`, checklist doc, or similar).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone / Phase Specs
- `.planning/ROADMAP.md` — Phase 22 scope, success criteria, and explicit `0.10.0 -> 1.0.0` graduation wording.
- `.planning/REQUIREMENTS.md` — REL-01 through REL-04 acceptance criteria.
- `.planning/research/V1-RELEASE-READINESS.md` — canonical release sequencing, proportionate gate, and publish-workflow recommendation.
- `.planning/research/V1-SUMMARY.md` — v1.0 milestone framing and freeze-depth rationale.

### Current Release State
- `release-please-config.json` — current pre-1.0 bump flags and `release-as: "0.10.0"` pin.
- `.release-please-manifest.json` — current Release Please state (`"0.9.0"`), proving the graduation blocker remains live.
- `.github/workflows/release-please.yml` — existing Release Please workflow to extend with publish automation.
- `mix.exs` — current package version (`0.10.0`) and docs/package config relevant to release verification.

### Current CI / Demo State
- `.github/workflows/ci.yml` — existing `test`, `demo`, and `release_gate` jobs; the place to harden CI.
- `.planning/phases/21-runnable-demo-app/21-VERIFICATION.md` — open Phase 21 verification gaps that block release completion.
- `.planning/STATE.md` — tracked note that the `0.10.0` Release Please pin must stay until the tag exists.

### Prior Release Mechanics Context
- `.planning/phases/15-packaging-credibility-gate/15-CONTEXT.md` — why the `0.10.0` pin exists and what not to change prematurely.
- `.planning/milestones/v0.10-MILESTONE-AUDIT.md` — carried-forward clarification that the `release-as` pin is removed only after the real tag exists.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/ci.yml` already has a stable fan-in gate pattern via `release_gate`.
  Phase 22 should extend this rather than invent a different branch-protection target.
- `.github/workflows/release-please.yml` is already in manifest mode and exposes the
  Release Please step as `id: release`, which is the natural handoff point for a gated
  publish job.
- The repo already treats `mix verify.public_api`, `mix credo --strict`, and
  `mix dialyzer` as normal proof surfaces in CI and governance docs.

### Established Patterns
- Release Please owns version/tag progression; one-time `release-as` pins are retained
  only until the target tag exists, then removed immediately.
- `files:` allowlist in `mix.exs` means the demo app stays out of Hex automatically;
  no Phase 22 package-boundary change is needed there.
- v1.0 explicitly uses a proportionate release gate instead of a full hardening audit.

### Integration Points
- CI hardening work centers in `.github/workflows/ci.yml`.
- Publish automation centers in `.github/workflows/release-please.yml`.
- Version-transition mechanics center in `release-please-config.json` and the RP-managed
  `.release-please-manifest.json`.
- Manual release truth depends on GitHub branch protection and repository secrets, both
  outside the working tree but required for honest completion.
</code_context>

<specifics>
## Specific Ideas

- The exact blocker is **not** "Phase 21 generally unfinished"; it is the concrete set
  of demo verification gaps plus the missing branch-protection completion recorded in
  `21-VERIFICATION.md`.
- The exact version-state mismatch is load-bearing:
  `mix.exs` says `0.10.0`,
  `release-please-config.json` pins `0.10.0`,
  `.release-please-manifest.json` still says `0.9.0`,
  and git tags currently include `v0.10` but not `v0.10.0`.
- `release_gate` is already the intended public branch-protection check name. Preserve
  that operator-facing contract unless there is a compelling reason to change it.
</specifics>

<deferred>
## Deferred Ideas

- Multi-version Elixir / OTP CI matrix — v1.1 follow-up, not a 1.0 blocker.
- SHA-pinned GitHub Actions, logo/favicon, `MAINTAINING.md`, and demo Docker Compose —
  post-1.0 maturity work already tracked elsewhere.
- Any attempt to widen Phase 22 into new runtime behavior, new integrations, or a full
  hardening program is out of scope.
</deferred>

---

*Phase: 22-release-readiness-1-0-cut*
*Context gathered: 2026-05-25*
