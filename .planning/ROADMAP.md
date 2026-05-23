# v0.9 Roadmap: Performance, Scale & DX

## Goal
Validate TSDB safety, generator ergonomics, and large-installation behavior. Shift the focus from feature breadth to operational depth, ensuring Parapet scales elegantly without bloating the host application's TSDB or Postgres instances.

## Phases

### ✓ Phase 1: TSDB Cardinality Protection
**Focus:** Proactively prevent observability's most common failure mode.
- Implement `mix parapet.doctor cardinality` to parse configuration and detect unsafe label patterns.
- Add compile-time enforcement limits on the number of labels permitted per metric.
- Ensure all built-in metrics and adapter SLIs strictly adhere to the limits.

### ✓ Phase 2: Database Scale & Pruning
**Focus:** Keep the Ecto evidence tables fast and lean over time.
- Generate and apply composite database indexes for `Incident`, `TimelineEntry`, and `ToolAudit` for >100k row scale.
- Implement `Parapet.Evidence.Archiver` for logic to soft-delete or export old evidence.
- Add `mix parapet.archive` task and an Oban cron template for automated pruning.

### ✓ Phase 3: Operator UI Performance
**Focus:** Ensure the SRE dashboard remains responsive under load.
- Refactor the LiveView Incident list to use efficient cursor-based pagination or streams instead of loading all active records.
- Optimize Ecto queries in the Operator context to leverage the new indexes.
- Benchmark UI performance with 50k+ mocked incident records.
**Closure:** Verified by `.planning/v0.9-phases/3/VERIFICATION.md`; milestone-close proof for `SCALE-01.c` and `AC-03` now exists and remains distinct from any fresh milestone audit result.

### ✓ Phase 4: Unified Install Path (DX)
**Focus:** Flawless Day-1 experience.
- Implement `mix parapet.install` as a unified Igniter task that chains `spine`, `prometheus`, and `ui` generation.
- Add interactive prompts to `mix parapet.install` to guide the user through optional integrations (e.g., Mailglass, Chimeway).
- Enhance `mix parapet.doctor` with multi-node safety checks (e.g., Oban uniqueness).
**Plans:** 3 plans
Plans:
- [x] 04-01-PLAN.md — Turn `mix parapet.install` into the deterministic Day-1 orchestrator with explicit extras and end-of-run summary.
- [x] 04-02-PLAN.md — Add severity-aware multi-node doctor checks, thresholded exits, and runtime-oriented probing.
- [x] 04-03-PLAN.md — Align README and operator UI docs to the final installer and doctor contracts.
**Closure:** Verified by `.planning/v0.9-phases/4/VERIFICATION.md`; the Day-1 install, doctor, and docs handoff proof is closed, while milestone close still awaits a fresh audit rerun.

### ✓ Phase 5: Multi-Node Safety Verification
**Focus:** Concurrency guarantees for bounded auto-mitigations.
- Create tests simulating concurrent mitigation triggers across multiple nodes.
- Validate Ecto-backed circuit breakers are robust against race conditions via database-level atomic checks or locks.
- Ensure escalation policies handle node crashes/restarts gracefully without duplicate alerts.
**Closure:** Verified by `.planning/v0.9-phases/5/VERIFICATION.md`, with `.planning/v0.9-phases/5/05-VALIDATION.md` reconciled as a truthful secondary validation surface.

### ✓ Phase 6: Verify Cardinality Protection
**Goal:** Close the Phase 1 verification gap so the TSDB safety work is milestone-close ready.
**Requirements:** `PERF-01.a`, `PERF-01.b`
**Gap Closure:** Closes audit requirement gaps for Phase 1 and adds the missing closure-grade verification evidence.
- Produce a Phase 1 `VERIFICATION.md` that proves `mix parapet.doctor cardinality` and compile-time label limits from implemented artifacts.
- Reconcile Phase 1 validation and requirement coverage against the verification artifact.
- Capture closure evidence in the planning artifacts so the milestone audit can mark Phase 1 complete.
**Closure:** Satisfied by `.planning/v0.9-phases/1/VERIFICATION.md`, which closes the Phase 1 proof gap without implying that the milestone audit has already been rerun.

### ✓ Phase 7: Close Operator UI Performance Proof
**Goal:** Close the Phase 3 verification gap for paging, performance, and acceptance evidence.
**Requirements:** `SCALE-01.c`, `AC-03`
**Gap Closure:** Closes audit requirement and flow gaps for the Phase 3 operator queue performance proof.
- Produce a Phase 3 `VERIFICATION.md` covering bounded queue paging, query performance, and the 50k+ benchmark lane.
- Reconcile draft validation and roadmap completion state with the verified evidence.
- Record acceptance-proof outcomes so milestone closure no longer depends on summary-only claims.
**Closure:** Satisfied by `.planning/v0.9-phases/3/VERIFICATION.md` plus the reconciled `03-VALIDATION.md` and `REQUIREMENTS.md` rows for `SCALE-01.c` and `AC-03`.


### ✓ Phase 8: Close Day-1 Install and Doctor Verification
**Goal:** Close the Phase 4 verification gap for the install, doctor, and documentation handoff flow.
**Requirements:** `DX-01.a`, `DX-01.b`, `AC-01`
**Gap Closure:** Closes audit requirement and flow gaps for the public Day-1 install path.
- Produce a Phase 4 `VERIFICATION.md` that proves `mix parapet.install` works end-to-end through doctor and docs handoff.
- Verify the multi-node doctor contract against the implemented checks and reported outcomes.
- Reconcile requirement coverage so the install and doctor claims are backed by explicit closure evidence.
**Closure:** Satisfied by `.planning/v0.9-phases/4/VERIFICATION.md`, the reconciled `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md`, and the verified `DX-01.a`, `DX-01.b`, and corrected `AC-01` rows in `.planning/REQUIREMENTS.md`.

### ✓ Phase 9: Reconcile Milestone Closure Artifacts
**Goal:** Eliminate planning-artifact drift so milestone state matches verified reality.
**Requirements:** milestone closure readiness
**Gap Closure:** Closes the audit integration gap across `STATE.md`, `ROADMAP.md`, `REQUIREMENTS.md`, and Phase 5 validation.
- Synchronize milestone tracking artifacts to the same completion state after Phases 6-8 land.
- Update Phase 5 validation wording so it reflects already-completed verification evidence rather than planned checks.
- Leave v0.9 in a re-audit-ready state for `$gsd-audit-milestone`.
**Closure:** Reconciled to a verified, re-audit-ready posture. Existing proof now lives in `.planning/v0.9-phases/1/VERIFICATION.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/4/VERIFICATION.md`, and `.planning/v0.9-phases/5/VERIFICATION.md`; a fresh milestone audit is still pending via `$gsd-audit-milestone`.

### Phase 10: Tighten Archive Retention Semantics
**Goal:** Bring archival behavior back into line with the milestone contract so active work never gets pruned.
**Requirements:** `SCALE-01.b`, `AC-02`
**Plans:** 2/2 plans complete
Plans:
- [x] 10-01-PLAN.md — Repair the resolved-only archive predicate and regression-test every archive entry surface without changing the public CLI contract.
- [x] 10-02-PLAN.md — Reconcile Phase 2 and Phase 10 verification artifacts plus roadmap/requirements truth to the repaired archive contract.
**Gap Closure:** Closes the audit requirement, integration, and flow gaps around archive retention semantics.
- Restrict `mix parapet.archive` to archival states the milestone contract allows, leaving active `investigating` incidents in the operator queue.
- Update the archive tests and verification evidence so the accepted behavior is explicit and rerunnable.
- Re-verify Phase 2 closure evidence against the corrected archive contract.
**Closure:** Verified by `.planning/v0.9-phases/10/VERIFICATION.md`, the corrected `.planning/v0.9-phases/2/VERIFICATION.md`, and the verified `SCALE-01.b` / `AC-02` rows in `.planning/REQUIREMENTS.md`; a fresh `$gsd-audit-milestone` rerun is still separate and still pending.

### Phase 11: Harden Multi-Node Proof Rerunnability
**Goal:** Make the multi-node proof lane honest, bounded, and rerunnable in environments without distributed Erlang.
**Requirements:** `SCALE-02`
**Plans:** 3/3 plans complete
Plans:
- [x] 11-01-PLAN.md — Harden the peer-node smoke lane with an explicit supported-versus-skipped test harness contract.
- [x] 11-02-PLAN.md — Reconcile Phase 5 and Phase 11 proof artifacts to the conditional-canary verification hierarchy.
- [x] 11-03-PLAN.md — Promote the corrected `SCALE-02` proof chain into roadmap and requirements truth surfaces.
**Gap Closure:** Closes the audit requirement, integration, and flow gaps around the Phase 5 concurrency proof.
- Make the peer-node smoke lane skip cleanly when distributed Erlang is unavailable instead of failing hard with `:nodistribution`.
- Preserve a closure-grade proof path for multi-node safety that remains explicit about its environment contract.
- Reconcile Phase 5 verification so the milestone claim matches executable behavior in this environment class.
**Closure:** Verified by `.planning/v0.9-phases/11/VERIFICATION.md`, the corrected `.planning/v0.9-phases/5/VERIFICATION.md`, and the verified `SCALE-02` row in `.planning/REQUIREMENTS.md`; the peer-node canary is environment-conditional, and `.planning/v0.9-MILESTONE-AUDIT.md` remains a historical gap artifact until a fresh `$gsd-audit-milestone` rerun replaces it.

### Phase 12: Backfill Closure-Phase Verification Surfaces
**Goal:** Satisfy the workflow's phase-proof model for reconciliation phases without widening product scope.
**Requirements:** milestone closure readiness
**Plans:** 4/4 plans complete
Plans:
- [x] 12-01-PLAN.md — Backfill the Phase 6 verification report as a proof index for the Phase 1 closure chain.
- [x] 12-02-PLAN.md — Backfill the Phase 7 verification report as a proof index for the Phase 3 closure chain.
- [x] 12-03-PLAN.md — Backfill the Phase 8 verification report as a proof index for the Phase 4 closure chain.
- [x] 12-04-PLAN.md — Backfill the Phase 9 verification report and close the four-report coherence check.
**Gap Closure:** Closes the audit integration gap between Phases 6-9 and the milestone proof model.
- Add phase-local `VERIFICATION.md` artifacts for Phases 6-9 that point to the proof surfaces those phases reconciled.
- Align the closure-phase evidence chain so roadmap, requirements, validation, and verification surfaces tell the same story.
- Leave v0.9 ready for a fresh `$gsd-audit-milestone` rerun once Phases 10-12 complete.

### Phase 13: Repair Generated Operator Resolve Flow
**Goal:** Restore the generated operator resolve path so the Phase 3 runtime lifecycle and acceptance story are true again.
**Requirements:** `SCALE-01.c`, `AC-03`
**Plans:** 2/2 plans complete
Plans:
- [x] 13-01-PLAN.md — Rewire generated queue resolve to `Parapet.Operator.resolve_incident/2` and prove the lifecycle change in the existing quick lane.
- [x] 13-02-PLAN.md — Reconcile Phase 3 and Phase 7 proof surfaces plus operator UI docs to the repaired resolve lane.
**Gap Closure:** Closes the audit requirement, integration, and flow gaps caused by the broken generated resolve action.
- Update the generated operator LiveView `"resolve"` event to call `Parapet.Operator.resolve_incident/2` instead of recording a note.
- Re-run the generated operator UI proof lanes that cover active-queue to resolved-history/archive transitions.
- Reconcile Phase 3 and Phase 7 truth surfaces so the repaired runtime path is reflected in closure artifacts.
**Closure:** Verified by `.planning/v0.9-phases/3/VERIFICATION.md`, the reconciled `.planning/v0.9-phases/7/VERIFICATION.md`, and the verified `SCALE-01.c` / `AC-03` rows in `.planning/REQUIREMENTS.md`; `.planning/v0.9-MILESTONE-AUDIT.md` remains historical until a fresh milestone audit rerun replaces it.

### Phase 14: Backstop Generated Operator UI Closure Proof
**Goal:** Extend the closure-proof chain so future milestone reruns catch generated operator UI runtime regressions.
**Requirements:** milestone closure readiness
**Plans:** 2/2 plans complete
Plans:
- [x] 14-01-PLAN.md — Promote the generated resolve-flow backstop into the active Phase 3, Phase 7, and Phase 12 proof hierarchy.
- [x] 14-02-PLAN.md — Reconcile roadmap, requirements, and state to the strengthened generated operator UI closure-proof chain.
**Gap Closure:** Closes the audit proof-coverage gap across the Phase 3, Phase 7, and Phase 12 closure surfaces.
- Add explicit proof coverage for the generated resolve action, including a failure if the UI bypasses `Parapet.Operator.resolve_incident/2`.
- Promote that proof into the Phase 3, Phase 7, and Phase 12 verification and validation hierarchy without widening runtime scope.
- Reconcile roadmap, requirements, and closure artifacts so milestone readiness depends on the new rerunnable resolve-flow lane.
**Closure:** Verified by `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/7/VERIFICATION.md`, and `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md`; the strengthened proof chain is current truth for milestone readiness, while `.planning/v0.9-MILESTONE-AUDIT.md` remains a historical audit artifact until a fresh milestone audit rerun replaces it as separate work.
