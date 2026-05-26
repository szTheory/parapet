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
- ✅ **v1.0 Stable Release** — Phases 19-22 (shipped 2026-05-26)
- 💤 **No Active Milestone** — stable `main`, quiet by default
- 📌 **v1.1 Authoring DX & Maturity** — candidate; open only when a concrete PR-shaped slice is ready

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

### ✅ v1.0 Stable Release (Shipped 2026-05-26)

**Milestone Goal:** Freeze Parapet's public API and telemetry contract under a written stability + deprecation policy, ship the release-readiness scaffolding that lets a stranger trust `~> 1.0`, and cut 1.0.0.

- [x] **Phase 19: API & Telemetry Freeze** — Three stability tiers, deprecation policy, telemetry contract test, `mix verify.public_api` gate, hard-deprecate `Parapet.SLO.define/2` (completed 2026-05-25)
- [x] **Phase 20: Governance & Docs Completeness** — OSS governance docs (`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`), README semver commitment, four remaining integration guides (Chimeway, Mailglass, Rindle, Scoria), Provider-as-bundle pattern doc, hexdocs grouping (completed 2026-05-25)
- [x] **Phase 21: Runnable Demo App** — `examples/demo_app/` child Phoenix app with seeded evidence, smoke test, required `demo` CI gate, Hex-excluded (completed 2026-05-26 after 21-05/21-06 gap closure)
- [x] **Phase 22: Release Readiness & 1.0 Cut** — CI warnings-as-errors, Hex publish step, proportionate verification gate, Release-Please graduation, live `v1.0.0` tag/release, Hex + HexDocs verification, and post-cut cleanup removing the one-time `release-as` pin plus pre-1.0 bump flags (completed 2026-05-26)

**Release Evidence:** `v1.0.0` was published on 2026-05-26, `https://hex.pm/packages/parapet` resolves, `https://hexdocs.pm/parapet/1.0.0/` resolves, and `main` returns to steady-state Release Please config with no one-off version pin.

### 💤 Released Maintenance (Default)

**Default Goal:** Keep `main` stable and releasable. If `release_gate` is green and release truth is coherent, the default answer is that there is nothing to do.

- [ ] **Routine maintenance only** — fixes, docs, CI hygiene, and release-train-safe upkeep
- [ ] **Feature work requires activation** — serious feature work opens first as a PR-shaped slice, then becomes milestone work if needed

### 📌 v1.1 Authoring DX & Maturity (Candidate)

**Candidate Goal:** Land additive DX and maturity work without reopening the 1.0 freeze.

- [ ] **SLO-W1** — Flag-based `mix parapet.gen.slo` Igniter task
- [ ] **CI-M1** — Multi-version Elixir / OTP CI matrix
- [ ] **Post-1.0 maturity** — SHA-pinned actions, HexDocs logo/favicon, `MAINTAINING.md`, demo Docker Compose

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

**Plans**: 5 plans in 2 waves

  - [x] 20-01-PLAN.md — Governance triad: CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md (GOV-01/02/03) (Wave 1)
  - [x] 20-02-PLAN.md — README 1.0 semver commitment + Elixir/OTP/Postgres matrix (GOV-04) (Wave 1)
  - [x] 20-03-PLAN.md — Four integration guides: Chimeway, Mailglass, Rindle, Scoria (DOCS-01/02/03/04) (Wave 1)
  - [x] 20-04-PLAN.md — Provider-as-bundle pattern in SLO authoring guide + slo-reference cross-link (DOCS-05) (Wave 1)
  - [x] 20-05-PLAN.md — mix.exs wiring: files: whitelist (GOV-05) + extras/main/groups_for_extras (DOCS-06) (Wave 2, depends on 20-01/03/04)

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
**Plans**: 6 plans in 6 waves (4 original + 2 gap-closure from 21-VERIFICATION.md)

  - [x] 21-01-PLAN.md — Phoenix app skeleton: mix.exs/config/application/repo/endpoint/instrumenter + spine migration with runbook_data+trace_id (DEMO-01) (Wave 1)
  - [x] 21-02-PLAN.md — Operator UI wiring: committed generated LiveViews + open /parapet router + Tailwind assets + README (DEMO-01) (Wave 2, depends on 21-01)
  - [x] 21-03-PLAN.md — Seeds via Evidence Stable API (open/investigating/resolved + runbook warning) + ConnTest smoke test (DEMO-02/03) (Wave 3, depends on 21-02)
  - [x] 21-04-PLAN.md — CI demo + release_gate jobs + Hex-exclusion verify + getting-started link + branch-protection checkpoint (DEMO-03/04) (Wave 4, depends on 21-03)
  - [x] 21-05-PLAN.md — Gap closure: fix History-tab KeyError (CR-01) + add LiveView JS bundle/esbuild/script tag (CR-02) (DEMO-01/02) (Wave 5, depends on 21-04)
  - [x] 21-06-PLAN.md — Gap closure: configure release_gate as a required branch-protection check on main (DEMO-03) (Wave 6, depends on 21-05)

### Phase 22: Release Readiness & 1.0 Cut

**Goal**: All CI hardening lands, the Hex publish pipeline is wired, the proportionate verification gate passes, and `1.0.0` is cut via Release-Please and resolves on hexdocs.
**Depends on**: Phase 21
**Requirements**: REL-01, REL-02, REL-03, REL-04
**Success Criteria** (what must be TRUE):

  1. The CI lint lane runs `compile --warnings-as-errors`, `compile --no-optional-deps --warnings-as-errors`, and `docs --warnings-as-errors`; any warning fails the build.
  2. `release-please.yml` publishes to Hex.pm on a created release (`hex.publish --dry-run` → `hex.publish --yes` → post-publish verify) using the Rulestead pattern.
  3. The proportionate verification gate (`mix verify.public_api`, `mix test`, `mix credo --strict`, `mix dialyzer`, no-optional-deps compile, one manual cold-start walkthrough) passes in full.
  4. `hexdocs.pm/parapet/1.0.0/` resolves and the `bump-minor-pre-major` / `bump-patch-for-minor-pre-major` pre-release flags are removed from `release-please-config.json`.

**Plans**: 4 plans in 4 waves

  - [x] 22-01-PLAN.md — CI hardening: dedicated lint lane + `release_gate` fan-in on lint/test/demo (REL-01, REL-03) (Wave 1)
  - [x] 22-02-PLAN.md — Release Please publish automation: gated Hex dry-run/publish/post-publish verify job (REL-02) (Wave 2, depends on 22-01)
  - [x] 22-03-PLAN.md — Proportionate verification truth surface: canonical 1.0 release gate + bounded manual cold-start walkthrough (REL-03) (Wave 3, depends on 22-01/22-02)
  - [x] 22-04-PLAN.md — Release-Please graduation sequence: staged `0.10.0 -> 1.0.0` cut + post-cut config cleanup checkpoint (REL-04) (Wave 4, completed 2026-05-26)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 15. Packaging Credibility Gate | v0.10 | 2/2 | Complete | 2026-05-24 |
| 16. SLO Starter Packs & Low-Traffic Guardrails | v0.10 | 2/2 | Complete | 2026-05-24 |
| 17. Recovery Depth — Runbook Templates | v0.10 | 3/3 | Complete | 2026-05-24 |
| 18. Adoption & Authoring Docs | v0.10 | 5/5 | Complete | 2026-05-24 |
| 19. API & Telemetry Freeze | v1.0 | 4/4 | Complete   | 2026-05-25 |
| 20. Governance & Docs Completeness | v1.0 | 5/5 | Complete   | 2026-05-25 |
| 21. Runnable Demo App | v1.0 | 6/6 | Complete | 2026-05-26 |
| 22. Release Readiness & 1.0 Cut | v1.0 | 4/4 | Complete | 2026-05-26 |

_Earlier milestone phases (1-14) are archived — see the milestone archives linked above._
