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
- ✅ **v0.10 Adopter Success** — Phases 15-18 (shipped 2026-05-24) ([archive](milestones/v0.10-ROADMAP.md))
- 🚧 **v1.0 Stable Release** — Phases 19-22 (in progress)

## Phases

<details>
<summary>✅ v0.10 Adopter Success (Phases 15-18) — SHIPPED 2026-05-24</summary>

Closed the gap between "feature-complete" and "adoptable by a stranger" on top of a feature-complete
v0.9 system — no new runtime deps, Ecto schemas, or Oban queues. Code deliverables landed before the
docs that name them. Full per-phase detail, success criteria, and closure evidence in
[milestones/v0.10-ROADMAP.md](milestones/v0.10-ROADMAP.md).

- [x] Phase 15: Packaging Credibility Gate (2/2 plans) — populated hex.pm metadata + `links:` + Release-Please-owned CHANGELOG + retroactive `docs/HISTORY.md`
- [x] Phase 16: SLO Starter Packs & Low-Traffic Guardrails (2/2 plans) — one-line `Parapet.SLO.StarterPack.WebSaaS`/`DeliverySaaS`, low-cardinality, low-traffic-safe
- [x] Phase 17: Recovery Depth — Runbook Templates (3/3 plans) — end-to-end `warning:` surface + 4 deepened + 3 new preview-first templates
- [x] Phase 18: Adoption & Authoring Docs (5/5 plans) — 7 adoption guides + `Parapet.Integration` behaviour (uniform, crash-proof `attach/1`)

</details>

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

### 🚧 v1.0 Stable Release (In Progress)

**Milestone Goal:** Freeze Parapet's public API and telemetry contract under a written stability + deprecation policy, ship the release-readiness scaffolding that lets a stranger trust `~> 1.0`, and cut 1.0.0.

- [x] **Phase 19: API & Telemetry Freeze** — Three stability tiers, deprecation policy, telemetry contract test, `mix verify.public_api` gate, hard-deprecate `Parapet.SLO.define/2` (completed 2026-05-25)
- [ ] **Phase 20: Governance & Docs Completeness** — OSS governance docs (`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`), README semver commitment, four remaining integration guides (Chimeway, Mailglass, Rindle, Scoria), Provider-as-bundle pattern doc, hexdocs grouping
- [ ] **Phase 21: Runnable Demo App** — `examples/demo_app/` child Phoenix app with seeded evidence, smoke test, required `demo` CI gate, Hex-excluded
- [ ] **Phase 22: Release Readiness & 1.0 Cut** — CI warnings-as-errors, Hex publish step, proportionate verification gate, Release-Please 1.0.0 graduation

## Phase Details

### Phase 19: API & Telemetry Freeze

**Goal**: The public API and telemetry contract are frozen under three named tiers and a written deprecation policy — every downstream artifact (docs, demo, guides) can reference a stable surface.
**Depends on**: Nothing (first v1.0 phase; continues from Phase 18)
**Requirements**: STAB-01, STAB-02, STAB-03, STAB-04, STAB-05, STAB-06
**Success Criteria** (what must be TRUE):

  1. Every public Parapet module (excluding `@moduledoc false` and `Parapet.Internal.*`) displays a Stable or Experimental ExDoc callout, and every Stable function carries `@doc since: "1.0.0"`.
  2. `docs/stability.md` exists and enumerates the frozen surface with tier assignments, the semver promise, what counts as breaking vs. additive, and the full deprecation cycle.
  3. `mix verify.public_api` exits non-zero when any public module is missing a stability-tier declaration, making the gate mandatory for all future surface additions.
  4. `test/telemetry_contract_test.exs` fails CI when documented `[:parapet, …]` event families, measurement keys, metadata keys, or outcome-atom vocabularies drift from their committed fixtures.
  5. Calling `Parapet.SLO.define/2` emits a compile-time warning naming `Parapet.SLO.Provider` as the replacement.

**Plans**: 4 plans in 2 waves

  - [x] 19-01-PLAN.md — Live STAB-04 gate (tier detection + alias fix) + docs/stability.md policy + telemetry.md stability header (Wave 1)
  - [x] 19-02-PLAN.md — Telemetry contract test for all 27 frozen families (STAB-05) + SLO.define/2 deprecation-warning test (STAB-06) (Wave 1)
  - [x] 19-03-PLAN.md — Stable-tier callouts + `@doc since: "1.0.0"` on the 13 Stable modules (STAB-01) (Wave 2, depends on 19-01)
  - [x] 19-04-PLAN.md — Experimental-tier callouts on the ~50 Experimental modules (STAB-01) (Wave 2, depends on 19-01)

### Phase 20: Governance & Docs Completeness

**Goal**: Trust artifacts and documentation gaps are closed — the repository ships the OSS governance triad, a clear version commitment, and all four previously missing integration guides plus hexdocs polish.
**Depends on**: Phase 19
**Requirements**: GOV-01, GOV-02, GOV-03, GOV-04, GOV-05, DOCS-01, DOCS-02, DOCS-03, DOCS-04, DOCS-05, DOCS-06
**Success Criteria** (what must be TRUE):

  1. `CONTRIBUTING.md`, `SECURITY.md`, and `CODE_OF_CONDUCT.md` exist in the repo root and are included in the Hex `files:` whitelist.
  2. The README states an explicit 1.0 semver commitment and an Elixir / OTP / Postgres version support matrix.
  3. An adopter can activate Chimeway, Mailglass, Rindle, or Scoria monitoring by following the corresponding integration guide (same shape: prerequisites, what it unlocks, activation line, config keys, troubleshooting).
  4. The SLO authoring guide documents the Provider-as-bundle pattern (a `Parapet.SLO.Provider` returning multiple slices) so adopters understand multi-integration composition without searching for a separate bundle abstraction.
  5. `hexdocs.pm/parapet` serves grouped extras (Getting Started / Guides / Integration Guides / Reference) with the getting-started guide as the landing page.

**Plans**: TBD

### Phase 21: Runnable Demo App

**Goal**: A runnable demo Phoenix app crystallizes the frozen surface as a live CI contract test and makes the getting-started guide walkable end-to-end.
**Depends on**: Phase 20
**Requirements**: DEMO-01, DEMO-02, DEMO-03, DEMO-04
**Success Criteria** (what must be TRUE):

  1. `cd examples/demo_app && mix setup && mix phx.server` succeeds and the Operator UI at `/parapet` loads, populated with seeded incidents (open, investigating, resolved), timeline entries, a tool audit, a runbook with a `warning:` step, and registered WebSaaS SLO state.
  2. The `demo` CI job (smoke test: `GET /parapet` returns 200, at least one seeded incident exists) is wired into `release_gate` as a required check and goes red if the Operator UI stops returning 200 — `continue-on-error` is never set.
  3. `mix hex.build --dry-run` confirms `examples/demo_app/` is absent from the published package.
  4. The getting-started guide links to the demo app as a "Next steps" reference.

**UI hint**: yes
**Plans**: TBD

### Phase 22: Release Readiness & 1.0 Cut

**Goal**: All CI hardening lands, the Hex publish pipeline is wired, the proportionate verification gate passes, and `1.0.0` is cut via Release-Please and resolves on hexdocs.
**Depends on**: Phase 21; external prerequisite: the pending v0.10.0 Release-Please PR must be merged and `v0.10.0` tagged before the `release-as` pin can be advanced (tracked risk — blocks the graduation sequence if delayed).
**Requirements**: REL-01, REL-02, REL-03, REL-04
**Success Criteria** (what must be TRUE):

  1. The CI lint lane runs `compile --warnings-as-errors`, `compile --no-optional-deps --warnings-as-errors`, and `docs --warnings-as-errors`; any warning fails the build.
  2. `release-please.yml` publishes to Hex.pm on a created release (`hex.publish --dry-run` → `hex.publish --yes` → post-publish verify) using the Rulestead pattern.
  3. The proportionate verification gate (`mix verify.public_api`, `mix test`, `mix credo --strict`, `mix dialyzer`, no-optional-deps compile, one manual cold-start walkthrough) passes in full.
  4. `hexdocs.pm/parapet/1.0.0/` resolves and the `bump-minor-pre-major` / `bump-patch-for-minor-pre-major` pre-release flags are removed from `release-please-config.json`.

**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 15. Packaging Credibility Gate | v0.10 | 2/2 | Complete | 2026-05-24 |
| 16. SLO Starter Packs & Low-Traffic Guardrails | v0.10 | 2/2 | Complete | 2026-05-24 |
| 17. Recovery Depth — Runbook Templates | v0.10 | 3/3 | Complete | 2026-05-24 |
| 18. Adoption & Authoring Docs | v0.10 | 5/5 | Complete | 2026-05-24 |
| 19. API & Telemetry Freeze | v1.0 | 4/4 | Complete   | 2026-05-25 |
| 20. Governance & Docs Completeness | v1.0 | 0/TBD | Not started | - |
| 21. Runnable Demo App | v1.0 | 0/TBD | Not started | - |
| 22. Release Readiness & 1.0 Cut | v1.0 | 0/TBD | Not started | - |

_Earlier milestone phases (1-14) are archived — see the milestone archives linked above._
