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
- 🚧 **v0.10 Adopter Success** — Phases 15-18 (in progress)

## Overview

v0.10 closes the gap between "feature-complete" and "adoptable by a stranger" on top of a feature-complete v0.9 system — no new runtime deps, Ecto schemas, or Oban queues. The journey: land the cheap credibility gate first (populated hex.pm metadata + CHANGELOG), build the opinionated SLO starter packs and deepened recovery runbook templates that adopters will lean on, then author the docs that accurately name those packs and templates. Each phase touches exactly one side of the existing bifurcated architecture, and code deliverables always land before the docs that cite them.

## Phases

**Phase Numbering:**

- Integer phases (15, 16, 17): Planned milestone work (continues from v0.9 which ended at Phase 14)
- Decimal phases (16.1, 16.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 15: Packaging Credibility Gate** - Populated hex.pm metadata and a Release-Please-owned CHANGELOG so the package reads as alive (completed 2026-05-24)
- [ ] **Phase 16: SLO Starter Packs & Low-Traffic Guardrails** - One-line opinionated SLO packs (WebSaaS, DeliverySaaS) built on the existing Provider engine
- [ ] **Phase 17: Recovery Depth — Runbook Templates** - Deepen four runbook templates and add three new ones, all preview-first and bounded
- [ ] **Phase 18: Adoption & Authoring Docs** - Getting-started, troubleshooting, SLO authoring, and per-integration guides that name the packs and templates now built

## Phase Details

### Phase 15: Packaging Credibility Gate

**Goal**: A stranger evaluating Parapet on hex.pm sees a credible, maintained package with populated metadata and a changelog — the low-cost gate that unblocks all downstream adoption work.
**Depends on**: Nothing (first phase of v0.10)
**Requirements**: ADOPT-01, ADOPT-02
**Success Criteria** (what must be TRUE):

  1. A stranger viewing the package on hex.pm sees populated `links:` (GitHub, HexDocs, Issues), a `:description` sentence, and `source_url` — not an empty `links: %{}`.
  2. An adopter can read a root `CHANGELOG.md` covering v0.1–v0.9 retroactively and ongoing releases.
  3. The CHANGELOG body is owned by Release Please (humans commit at most a header-only stub); retroactive history lives outside the changelog body so it never conflicts with generation.
  4. `CHANGELOG*` is in the Hex `files:` whitelist so the changelog ships with the package.

**Plans**: 2 plans

  - [x] 15-01-PLAN.md — Create CHANGELOG.md stub, docs/HISTORY.md, and the Release Please config + manifest pair (Wave 1)
  - [x] 15-02-PLAN.md — Populate mix.exs metadata + docs: extras, bump to 0.10.0, switch workflow to manifest mode (Wave 2)

### Phase 16: SLO Starter Packs & Low-Traffic Guardrails

**Goal**: An adopter can register a coherent first set of SLOs in one line without hand-writing PromQL, with low-traffic safety baked in — the code surfaces that later docs will name.
**Depends on**: Phase 15
**Requirements**: SLO-01, SLO-02
**Success Criteria** (what must be TRUE):

  1. A WebSaaS adopter registers HTTP availability, LoginJourney, and Oban job-success SLOs in one line via `Parapet.SLO.StarterPack.WebSaaS` with documented default objectives.
  2. A delivery-sending adopter extends the set via `Parapet.SLO.StarterPack.DeliverySaaS` (adds Mailglass + Chimeway delivery slices), and those slices register only when the providers are configured — compiling out cleanly otherwise.
  3. Every pack slice uses only low-cardinality labels (no `id`/`trace`/`path`/`user` keys) and sets a non-zero low-traffic denominator guard so packs do not flap on low-traffic services.
  4. The new pack modules pass the existing public-API verification (`verify.public_api`) and participate in multi-burn-rate rule generation with zero Generator changes.

**Plans**: 2 plans

  - [x] 16-01-PLAN.md — Build `Parapet.SLO.StarterPack.WebSaaS` (3 SliceSpecs: HTTP availability, login journey, Oban job-success) pinned to real emitted metrics, with documented objectives + LabelPolicy/denominator-guard tests (Wave 1)
  - [ ] 16-02-PLAN.md — Build `Parapet.SLO.StarterPack.DeliverySaaS` composing WebSaaS + conditionally-loaded, delegated Mailglass/Chimeway delivery slices (Wave 2)

**Research flag**: RESOLVED — `AsyncDelivery.selector/2` renders any binary metric name + label matchers generically (D-04), so no HTTP selector helper is needed; HTTP matches on the `status_class` tag (not the `status_code` measurement, D-05). No `--research-phase` run required.

### Phase 17: Recovery Depth — Runbook Templates

**Goal**: An operator opening any prebuilt runbook template finds real, trustworthy depth — preconditions, a scoped preview, a warning, a bounded mitigation, and post-action verification — across seven templates.
**Depends on**: Phase 15
**Requirements**: RCV-01, RCV-02
**Success Criteria** (what must be TRUE):

  1. Each of the four existing templates (`dead_letter`, `callback_delay`, `stalled_executor`, `provider_outage`) has a precondition (`kind: :guidance`), a scoped preview step (`requires_preview: true`), at least one `warning:` annotation, a bounded mitigation, and a post-action verification step — not a 1–2 step stub.
  2. Three additional templates (`retry_storm`, `suppression_drift`, `partial_backlog_drain`) exist at the same depth, each with precondition, scope check, warning, bounded preview-first mitigation, and verification.
  3. The generator copies the new templates with `on_exists: :skip`, preserving the host-ownership contract.

**Plans**: TBD
**Research flag**: yes — verify the `Parapet.Runbook` DSL surface before writing templates. FEATURES.md states `warning:`/`requires_preview:`/`kind: :guidance` already exist, while SUMMARY.md notes the `warning:` key must land before any template uses it (Elixir silently swallows unknown macro keyword args). Plan-phase MUST confirm the `warning:` key is actually rendered by `Parapet.Runbook.step/2` and the Operator UI detail template before any template references it; if a surgical DSL/foundation addition is needed, it precedes template content within this phase.

### Phase 18: Adoption & Authoring Docs

**Goal**: A new adopter can go from cold start to a running SLO and a generated alert in under 30 minutes, recover from the first obstacle, and discover the SLO slices each built-in integration unlocks — all from docs that accurately name the packs and templates now built.
**Depends on**: Phase 16, Phase 17
**Requirements**: ADOPT-03, ADOPT-04, ADOPT-05, SLO-03, SLO-04
**Success Criteria** (what must be TRUE):

  1. A new adopter can follow `docs/getting-started.md` from install → first running SLO → first generated alert in under 30 minutes, with zero raw PromQL and referencing the WebSaaS starter pack from Phase 16.
  2. An adopter who hits a first obstacle finds an answer in `docs/troubleshooting.md`, seeded with the 5–7 most predictable questions (blank Prometheus target, doctor warn-vs-error, Oban compile-out, multi-node uniqueness, Fly.io config).
  3. An adopter can read `docs/slo-authoring-guide.md` with good-vs-bad journey-slicing examples, a decision tree, and a named "Low-Traffic and Low-Volume Services" section (denominator guard, synthetic-probe fallback, extended-window approach, and the explicitly-named lower-the-objective anti-pattern).
  4. An adopter finds a consistent per-integration guide under `docs/integrations/` for Sigra, Accrue, Rulestead, and Threadline — each leading with a Prerequisites/optional-dep section, surfacing the SLO slices that integration unlocks, the `Parapet.attach(adapters: [...])` line, config keys, and 2–3 troubleshooting answers — enabling activation without reading source.

**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 15 → 16 → 17 → 18

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 15. Packaging Credibility Gate | v0.10 | 2/2 | Complete    | 2026-05-24 |
| 16. SLO Starter Packs & Low-Traffic Guardrails | v0.10 | 1/2 | In Progress|  |
| 17. Recovery Depth — Runbook Templates | v0.10 | 0/TBD | Not started | - |
| 18. Adoption & Authoring Docs | v0.10 | 0/TBD | Not started | - |

---

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
