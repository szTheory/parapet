# v0.10 Requirements: Adopter Success

**Defined:** 2026-05-23
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## Overview

v0.10 is a **credibility-gate** release on a feature-complete v0.9 system. The job is closing the gap between "feature-complete" and "adoptable by a stranger" — without expanding feature surface. Work spans three pillars, each touching one side of the existing architecture and requiring **no new runtime deps, Ecto schemas, or Oban queues**:

1. **Adoption funnel** — make the library credible and learnable from a cold start.
2. **SLO authoring guidance** — answer "what SLO do I add first, and how do I slice it?"
3. **Recovery depth** — make the prebuilt runbooks deep enough that operators trust them.

The dominant risk per research is drift and package scope-leak, not technical difficulty.

## System Requirements

### ADOPT: Adoption Funnel

- [x] **ADOPT-01**: A stranger evaluating the package on hex.pm sees populated metadata — `links:` (GitHub, HexDocs, Issues), a `:description` sentence, and `source_url` — instead of an empty `links: %{}`. *(mix.exs change; credibility gate that unblocks the rest.)*
- [x] **ADOPT-02**: An adopter can read a root `CHANGELOG.md` covering v0.1–v0.9 retroactively and ongoing releases. *(Conventional Commits / Release Please already in use.)*
- [x] **ADOPT-03**: A new adopter can follow a single `docs/getting-started.md` from install → first running SLO → first generated alert in under 30 minutes. *(Ends when they see something work, not when all features are explained.)*
- [x] **ADOPT-04**: An adopter who hits a first obstacle can find an answer in `docs/troubleshooting.md` (seeded with the 5–7 most predictable questions: blank Prometheus target, doctor warn-vs-error, Oban compile-out, multi-node uniqueness, Fly.io config).
- [x] **ADOPT-05**: An adopter can find a consistent per-integration setup guide under `docs/integrations/` for **Sigra, Accrue, Rulestead, and Threadline** — each surfacing the SLO slices that integration produces out of the box, the `Parapet.attach(adapters: [...])` line, config keys, and 2–3 troubleshooting answers.

### SLO: SLO Authoring Guidance

- [x] **SLO-01**: A WebSaaS adopter can register a coherent first set of SLOs in one line via `Parapet.SLO.StarterPack.WebSaaS` (HTTP availability, LoginJourney, Oban job success) with documented default objectives and human-terms rationale.
- [x] **SLO-02**: A delivery-sending adopter can extend the WebSaaS set via `Parapet.SLO.StarterPack.DeliverySaaS` (adds MailglassDelivery + ChimewayDelivery slices), registering delivery slices **only when those providers are configured** (compiles out cleanly otherwise).
- [ ] **SLO-03**: An adopter unsure how to slice SLOs can read `docs/slo-authoring-guide.md` with concrete good-vs-bad journey-slicing examples and a decision tree ("does this failure directly prevent a user task? → journey SLO").
- [ ] **SLO-04**: An adopter running a low-traffic service finds a named "Low-Traffic and Low-Volume Services" section documenting the denominator guard (`and sum(rate(total[1h])) > N`), synthetic-probe fallback, and extended-window/lower-sensitivity approach — and the explicitly-named anti-pattern of lowering the objective to silence noise. *(Guidance + generated-rule commentary; no engine code.)*

### RCV: Recovery Depth

- [x] **RCV-01**: An operator opening any of the four existing runbook templates (`dead_letter`, `callback_delay`, `stalled_executor`, `provider_outage`) finds real depth — preconditions (`kind: :guidance`), a scoped preview step (`requires_preview: true`), at least one `warning:` annotation, a bounded mitigation, and a post-action verification step — not a 1–2 step stub. *(Uses existing `Parapet.Runbook` DSL.)*
- [x] **RCV-02**: An operator has three additional prebuilt templates at the same depth — `retry_storm`, `suppression_drift`, and `partial_backlog_drain` — each with precondition, scope check, warning, bounded preview-first mitigation, and verification.

## Acceptance Criteria

- [ ] **AC-01**: Starting from the hex.pm / GitHub landing, a stranger follows getting-started and reaches a generated Prometheus alert rule for their first SLO in under 30 minutes. *(ADOPT-01/02/03 + SLO-01)*
- [ ] **AC-02**: A WebSaaS adopter activates a starter pack in one line and gets a coherent set of first SLOs whose objectives are documented in human terms (e.g., "99.9% login = 43 min/month of user-impacting auth failures"). *(SLO-01/02/03)*
- [ ] **AC-03**: An operator running a deepened or new runbook sees preconditions, a scoped preview of affected items before acting, and a bounded mitigation with a warning — verifiable on at least one deepened and one new template. *(RCV-01/02)*
- [ ] **AC-04**: An adopter using a built-in integration (e.g., Sigra for auth) can discover from its guide which SLO slices it unlocks and enable them without reading source. *(ADOPT-05)*

## Future Requirements

Acknowledged, deferred — not in the v0.10 roadmap.

### v0.10.x (after validation)

- **DEMO-01**: Runnable demo app under `examples/demo_app/` (minimal Phoenix app wired with Parapet + a few SLOs) plus a CI green check. *Deferred per scope decision: high maintenance; validate that docs alone reduce onboarding friction first.*

### v1.0+

- **SLO-W1**: Interactive `mix parapet.gen.slo` wizard (guided prompts → starter SLO definition). *Guide + starter packs ship faster with less maintenance risk.*
- **SLO-B1**: Cross-integration SLO slice bundles (e.g., Sigra+Accrue+Chimeway "e-commerce reliability suite"). *Defer until per-integration docs prove which bundles adopters want.*

## Out of Scope

Explicit exclusions (anti-features from research + milestone-arc decision) to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Auto-generated SLO targets (system proposes 99.9%) | Silent defaults become false safety guarantees; make adopters confirm objectives. Use opinionated packs with documented rationale instead. |
| Bundled Grafana provisioning in the demo | Diverges fast from real adopter setups (datasources, org IDs, auth); ongoing false-expectation noise. Link to `mix parapet.gen.grafana` instead. |
| Bundled SLO "score" / reliability rating | Aggregate score creates false executive confidence divorced from context. Surface per-slice error-budget burn instead. |
| Auto-discovery of "important journeys" from telemetry | Right SLOs require human intent; auto-discovery SLOs the wrong things and misses the right ones. Use packs + decision guide. |
| Hosted CHANGELOG / release subscription | Adds vendor dependency + privacy surface. `mix hex.outdated` + GitHub watch + `CHANGELOG.md` already cover it. |
| API / telemetry freeze | Deferred to v1.0 per `MILESTONE-ARC.md` — recovery and SLO surfaces land complete before they are locked. |

## Traceability

Each requirement maps to exactly one phase. v0.10 continues phase numbering from v0.9 (which ended at Phase 14), so v0.10 phases are 15–18.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADOPT-01 | Phase 15 | Complete |
| ADOPT-02 | Phase 15 | Complete |
| ADOPT-03 | Phase 18 | Complete |
| ADOPT-04 | Phase 18 | Complete |
| ADOPT-05 | Phase 18 | Complete |
| SLO-01 | Phase 16 | Complete |
| SLO-02 | Phase 16 | Complete |
| SLO-03 | Phase 18 | Pending |
| SLO-04 | Phase 18 | Pending |
| RCV-01 | Phase 17 | Complete |
| RCV-02 | Phase 17 | Complete |

**Coverage:**

- v0.10 requirements: 11 total (+ 4 acceptance criteria)
- Mapped to phases: 11 ✓ (Phases 15-18)
- Unmapped: 0 ✓

Acceptance criteria are cross-cutting verification, not separate phases:

- AC-01 spans Phases 15, 16, 18 (ADOPT-01/02/03 + SLO-01)
- AC-02 spans Phases 16, 18 (SLO-01/02/03)
- AC-03 verified within Phase 17 (RCV-01/02)
- AC-04 verified within Phase 18 (ADOPT-05)

---
*Requirements defined: 2026-05-23 — milestone v0.10 Adopter Success*
*Last updated: 2026-05-23 — traceability populated by roadmap (Phases 15-18, 11/11 mapped)*
