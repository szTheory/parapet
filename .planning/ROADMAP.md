# Roadmap: Parapet

## Milestones

- ✅ **v0.1 Trustworthy Spine** — shipped 2026-05-10 ([archive](milestones/v0.1-ROADMAP.md))
- ✅ **v0.2 Durable Spine & Operator UI** — shipped 2026-05-11 ([archive](milestones/v0.2-ROADMAP.md))
- ✅ **v0.3 Runbooks & Alert Routing** — shipped 2026-05-12 ([archive](milestones/v0.3-ROADMAP.md))
- ✅ **v0.4 Scoria AI Integration** — shipped 2026-05-15 ([archive](milestones/v0.4-ROADMAP.md))
- ✅ **v0.5 Proactive Resilience & Copilot Triage** — shipped 2026-05-16
- ✅ **v0.6 Change Correlation & Audit Trailing** — shipped 2026-05-17 ([archive](milestones/v0.6-ROADMAP.md))
- ✅ **v0.7 Async & Delivery Reliability** — shipped 2026-05-18
- ✅ **v0.8 Deterministic Escalation & Bounded Mitigation** — shipped 2026-05-19 ([archive](milestones/v0.8-ROADMAP.md))
- ✅ **v0.9 Performance, Scale & DX** — Phases 1-14 (shipped 2026-05-23) ([archive](milestones/v0.9-ROADMAP.md))
- 📋 **Next milestone** — TBD via `/gsd:new-milestone`

## Phases

<details>
<summary>✅ v0.9 Performance, Scale &amp; DX (Phases 1-14) — SHIPPED 2026-05-23</summary>

Core deliverables (Phases 1-5) plus closure & reconciliation phases (6-14). Full
detail and per-phase closure evidence in [milestones/v0.9-ROADMAP.md](milestones/v0.9-ROADMAP.md).

- [x] Phase 1: TSDB Cardinality Protection — `mix parapet.doctor cardinality` + compile-time label ceiling
- [x] Phase 2: Database Scale & Pruning — composite indexes, `Parapet.Evidence.Archiver`, `mix parapet.archive`
- [x] Phase 3: Operator UI Performance — bounded queue paging, 50k+ benchmark
- [x] Phase 4: Unified Install Path (DX) — `mix parapet.install` orchestrator + multi-node doctor checks (3 plans)
- [x] Phase 5: Multi-Node Safety Verification — Ecto-backed claims/circuit breakers under concurrency
- [x] Phase 6: Verify Cardinality Protection — Phase 1 closure proof
- [x] Phase 7: Close Operator UI Performance Proof — Phase 3 closure proof
- [x] Phase 8: Close Day-1 Install and Doctor Verification — Phase 4 closure proof
- [x] Phase 9: Reconcile Milestone Closure Artifacts
- [x] Phase 10: Tighten Archive Retention Semantics — resolved-only contract (2 plans)
- [x] Phase 11: Harden Multi-Node Proof Rerunnability — environment-conditional canary (3 plans)
- [x] Phase 12: Backfill Closure-Phase Verification Surfaces (4 plans)
- [x] Phase 13: Repair Generated Operator Resolve Flow (2 plans)
- [x] Phase 14: Backstop Generated Operator UI Closure Proof (2 plans)

</details>

### 📋 Next Milestone (Planned)

To be defined via `/gsd:new-milestone` (questioning → research → requirements → roadmap).

## Progress

| Phase                                      | Milestone | Plans | Status   | Completed  |
| ------------------------------------------ | --------- | ----- | -------- | ---------- |
| 1. TSDB Cardinality Protection             | v0.9      | —     | Complete | 2026-05-23 |
| 2. Database Scale & Pruning                | v0.9      | 3/3   | Complete | 2026-05-23 |
| 3. Operator UI Performance                 | v0.9      | 3/3   | Complete | 2026-05-23 |
| 4. Unified Install Path (DX)               | v0.9      | 3/3   | Complete | 2026-05-23 |
| 5. Multi-Node Safety Verification          | v0.9      | 3/3   | Complete | 2026-05-23 |
| 6. Verify Cardinality Protection           | v0.9      | 2/2   | Complete | 2026-05-23 |
| 7. Close Operator UI Performance Proof     | v0.9      | 2/2   | Complete | 2026-05-23 |
| 8. Close Day-1 Install and Doctor Verify   | v0.9      | 2/2   | Complete | 2026-05-23 |
| 9. Reconcile Milestone Closure Artifacts   | v0.9      | 4/4   | Complete | 2026-05-23 |
| 10. Tighten Archive Retention Semantics    | v0.9      | 2/2   | Complete | 2026-05-23 |
| 11. Harden Multi-Node Proof Rerunnability  | v0.9      | 3/3   | Complete | 2026-05-23 |
| 12. Backfill Closure-Phase Verify Surfaces | v0.9      | 4/4   | Complete | 2026-05-23 |
| 13. Repair Generated Operator Resolve Flow | v0.9      | 2/2   | Complete | 2026-05-23 |
| 14. Backstop Generated Operator UI Proof   | v0.9      | 2/2   | Complete | 2026-05-23 |
