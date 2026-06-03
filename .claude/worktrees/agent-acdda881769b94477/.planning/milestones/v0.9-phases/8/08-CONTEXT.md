# Phase 8: Close Day-1 Install and Doctor Verification - Context

**Gathered:** 2026-05-21 (assumptions mode, research-backed)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the Phase 4 verification gap for the public Day-1 install path by producing closure-grade proof that `mix parapet.install`, `mix parapet.doctor`, and the related docs handoff behave as claimed. This phase proves and reconciles the existing Phase 4 implementation; it does not broaden Parapet's runtime feature set, turn optional operator UI into a default install surface, or absorb milestone-wide artifact synchronization beyond the files directly needed to close the proof gap.

</domain>

<decisions>
## Implementation Decisions

### Verification artifact shape
- **D-01:** Phase 8 should produce a dedicated `.planning/v0.9-phases/4/VERIFICATION.md` as the canonical closure artifact for the underlying Phase 4 implementation.
- **D-02:** The verification artifact should stay thin and executable-first, following the repo's stronger proof pattern: Goal Achievement, Observable Truths, Behavioral Spot-Checks, Plan Output Check, Requirements Coverage, Human Verification Required, and Gaps Summary.
- **D-03:** Summaries and validation files remain supporting inputs and historical execution records; they should not be promoted into the primary closure artifact.

### Proof standard
- **D-04:** The default proof stack for Phase 8 should be layered: targeted installer and doctor tests, doc-contract checks, and one fresh Phoenix host smoke lane that exercises the public Day-1 path.
- **D-05:** Repo-internal task tests alone are not sufficient to claim public Day-1 closure, because they prove task contracts but not the adopter-facing install invocation and handoff.
- **D-06:** The fresh-host smoke lane should prove `mix parapet.install` -> generated host-owned artifacts/config -> `mix parapet.doctor` -> docs handoff consistency, while explicitly stopping short of third-party observability runtime claims.
- **D-07:** `mix parapet.doctor cluster` may be included only as an honesty/reporting check for runtime-mode behavior in a non-cluster host; it is not the primary proof of multi-node safety.

### End-to-end boundary
- **D-08:** For Phase 8, “end-to-end” means a fresh Phoenix host can adopt Parapet through the paved-road install command, reach the documented doctor follow-up, and find docs that describe that shipped contract accurately.
- **D-09:** End-to-end for this phase explicitly excludes Prometheus/Grafana runtime setup, external provider integrations, and actual cluster correctness proof, because those are outside the install-surface boundary Parapet owns here.
- **D-10:** Phase 5 remains the real proof surface for multi-node contention and effectively-once automation semantics; Phase 8 only needs to verify that Day-1 doctor surfaces that posture honestly.

### AC-01 interpretation and public DX posture
- **D-11:** `AC-01` should be treated as stale wording and corrected during closure rather than forcing the installer to include operator UI by default.
- **D-12:** The cohesive public contract is: `mix parapet.install` installs the core Day-1 path by default, and the optional operator UI remains an explicit opt-in when LiveView is present.
- **D-13:** The recommended corrected wording for `AC-01` is: “A developer can run `mix parapet.install` and get the spine and default Prometheus artifacts in one guided flow, with the optional operator UI offered explicitly when LiveView is present.”
- **D-14:** Phase 8 must preserve the host-owned auth boundary for operator UI; it should not reinterpret “guided flow” as permission to auto-own router auth or silently widen the default support surface.

### Reconciliation scope
- **D-15:** After proof lands, Phase 8 should reconcile only the directly covered traceability surfaces: the new Phase 4 `VERIFICATION.md`, any stale Phase 4 validation wording, the `DX-01.a`, `DX-01.b`, and `AC-01` rows in `.planning/REQUIREMENTS.md`, and the Phase 8 closure line in `.planning/ROADMAP.md`.
- **D-16:** Broader milestone-wide synchronization across `STATE.md`, milestone audit artifacts, and remaining cross-phase tracker drift stays Phase 9 work unless Phase 8 proof directly changes one of those files' facts.

### Maintainer workflow preference
- **D-17:** Downstream planning and execution agents should shift low-impact DX decisions left when product posture is already locked by prior context, code, and docs.
- **D-18:** Low-impact decisions that should be auto-resolved by default include flag naming, prompt wording, summary copy, doc phrasing, and “core vs explicit extra” wording once those surfaces are already constrained by product posture.
- **D-19:** Agents should escalate only when a choice materially changes default install contents, auth ownership, dependency policy, public CLI/API contract, support surface, or operator semantics.

### the agent's Discretion
- Exact wording inside the Phase 4 `VERIFICATION.md`, as long as executable proof remains primary and the report stays concise.
- Exact shape of the doc-contract checks and smoke-host assertions, as long as they prove the shipped install, doctor, and docs handoff contract honestly.
- Exact wording changes in `REQUIREMENTS.md` and `ROADMAP.md`, provided they reconcile stale wording to the locked Day-1 product posture without widening scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and audit gap
- `.planning/ROADMAP.md` — active Phase 8 scope, direct requirement targets, and the explicit boundary between proof closure and milestone-wide reconciliation
- `.planning/REQUIREMENTS.md` — `DX-01.a`, `DX-01.b`, and `AC-01` current wording and unchecked state that Phase 8 must reconcile
- `.planning/v0.9-MILESTONE-AUDIT.md` — audit diagnosis showing the missing closure-grade proof for the Day-1 install flow
- `.planning/PROJECT.md` — evidence-first product posture, host-owned library stance, and least-surprise DX constraints

### Prior Phase 4 decisions and artifacts
- `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md` — locked Phase 4 implementation decisions that remain authoritative for install, doctor, and operator UI posture
- `.planning/phases/04-unified-install-path-dx/RESEARCH.md` — prior research on Igniter orchestration, optional integrations, and doctor semantics
- `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md` — current validation plan and manual-vs-automated proof expectations
- `.planning/phases/04-unified-install-path-dx/04-01-SUMMARY.md` — summary of installer orchestration work
- `.planning/phases/04-unified-install-path-dx/04-02-SUMMARY.md` — summary of doctor severity and cluster-mode work
- `.planning/phases/04-unified-install-path-dx/04-03-SUMMARY.md` — summary of README and operator UI doc alignment work

### Verification analogs and closure precedents
- `.planning/v0.9-phases/2/VERIFICATION.md` — current repo example of a strong generator/backend verification artifact
- `.planning/v0.9-phases/5/VERIFICATION.md` — current repo example of a strong reliability-proof verification artifact
- `.planning/v0.9-phases/6/06-CONTEXT.md` — direct precedent for narrow proof-plus-traceability reconciliation
- `.planning/v0.9-phases/7/07-CONTEXT.md` — direct precedent for canonical verification artifact shape and bounded reconciliation

### Existing code and proof surfaces
- `lib/mix/tasks/parapet.install.ex` — public Day-1 installer contract and summary notice
- `lib/mix/tasks/parapet.doctor.ex` — doctor severity model, threshold behavior, and runtime `cluster` mode
- `test/mix/tasks/parapet.install_test.exs` — targeted proof surface for installer composition, flags, and summary output
- `test/mix/tasks/parapet.doctor_test.exs` — targeted proof surface for doctor semantics, cluster posture, and machine-readable output
- `README.md` — public Day-1 install, doctor, and optional extras narrative
- `docs/operator-ui.md` — optional operator UI install/auth/doctor guidance that must stay aligned with shipped behavior

### Product posture and ecosystem guidance
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned generation, diagnostics-first DX, and OSS discipline
- `prompts/parapet-brand-identity-deep-research.md` — calm, evidence-first, low-noise product direction
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — reliability-layer framing and generated paved-road lessons
- `prompts/elixir-telemetry-space-deep-research.md` — observability-stack boundary guidance and host-owned integration posture
- `prompts/parapet-integration-opportunities.md` — ecosystem seams that reinforce explicit extras and user-harm-first posture
- `prompts/prior-art/SOURCE-CANONICAL.md` — mirrored prior-art index for host-owned seams, telemetry-as-API, and durable evidence lessons

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Parapet.Install` already encodes the public Day-1 contract through composed generators, explicit extras, and an end-of-run summary; Phase 8 should verify this surface rather than redesign it.
- `Mix.Tasks.Parapet.Doctor` already provides the severity-aware install backstop, threshold semantics, and the explicit runtime `cluster` mode that Phase 8 needs to prove honestly.
- The existing task tests already cover the most important stable install/doctor contracts and should remain the targeted test foundation for closure.
- The README and operator UI guide already reflect the shipped default-vs-optional posture and are strong doc-contract surfaces.

### Established Patterns
- This repo’s best closure artifacts are executable-evidence indexes, not prose-heavy attestations.
- Generated code and auth-sensitive surfaces remain host-owned by default; optional operator/admin features stay explicit rather than silently widening the default path.
- Doctor commands are public product surfaces and must stay explicit about certainty boundaries instead of implying more than static or runtime checks can prove.
- Narrow verification phases should close direct proof gaps first and leave milestone-wide sync to dedicated cleanup phases.

### Integration Points
- Add `.planning/v0.9-phases/4/VERIFICATION.md` as the new canonical closure artifact for the underlying Phase 4 work.
- Reconcile `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md` only if its wording is stale relative to the new proof artifact.
- Update `.planning/REQUIREMENTS.md` and the Phase 8 line in `.planning/ROADMAP.md` once proof is captured and stale AC wording is corrected.
- Preserve broader milestone-state cleanup for Phase 9 unless proof directly changes those files’ truth.

</code_context>

<specifics>
## Specific Ideas

- The cohesive recommendation is: **one canonical verification artifact, layered proof with a fresh-host smoke lane, narrow direct reconciliation only, and requirement wording correction instead of widening the default install surface**.
- The most important product-honesty fix is to keep the optional operator UI explicit and correct the acceptance wording rather than reinterpret the shipped contract.
- Great maintainer DX here means a future reviewer can answer “what exactly was proven, by which commands, and what did we intentionally not claim?” by reading one verification report plus a small set of aligned tracking files.
- Great GSD ergonomics here means low-impact DX wording and contract details are auto-resolved from locked context unless they materially change public posture.

</specifics>

<deferred>
## Deferred Ideas

- Broader milestone-wide synchronization across `.planning/STATE.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, and other cross-phase trackers after Phases 6-8 land.
- Any expansion of public proof beyond the library-owned install/doctor/docs boundary into Prometheus/Grafana/provider runtime infrastructure.
- Reifying the left-shift preference into a repo-level agent instruction surface such as `AGENTS.md` as a separate focused follow-on task.

</deferred>

---

*Phase: 08-close-day-1-install-and-doctor-verification*
*Context gathered: 2026-05-21*
