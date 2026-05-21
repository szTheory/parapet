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
