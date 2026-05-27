# Milestone Arc: Ecosystem Ubiquity & Operator Mastery

## Shipped

- **v0.9 Performance, Scale & DX** (2026-05-23) — confidence under load: TSDB cardinality protection, DB scale & pruning, responsive Operator UI at 50k+ incidents, unified `mix parapet.install`, multi-node safety.
- **v0.10 Adopter Success** (2026-05-24) — credibility gate: hex.pm metadata + Release-Please CHANGELOG, one-line SLO starter packs, end-to-end `warning:` runbook depth, seven adoption guides + a uniform `Parapet.Integration` activation behaviour.
- **v1.0 Stable Release** (2026-05-26) — frozen public API + telemetry contract, governance/docs completeness, runnable demo app as CI contract proof, release-quality CI lanes, Hex publish automation, and the live `v1.0.0` release with post-cut cleanup on `main`.

## Default Posture

- status: quiet stable line
- rule: if `main` is green and release truth is coherent, assume there is nothing to do
- activation: only open a milestone when a concrete PR-shaped feature slice is ready
- maintenance work: fixes, docs, CI hygiene, and release-train-safe upkeep may proceed without creating ambient milestone churn

## Candidate Milestones

### v1.1 Actionable Recovery

- status: candidate
- theme: close the action loop the operator UI already implies — make runbook steps executable from the UI, not handed off to other tools
- why_next: biggest "should-have-been-in-1.0" gap (Phase 7 Preview/Confirm flow shipped only as design, not code); JTBD-MAP Very-High-priority gap; unlocks the operator UI's full value prop for every existing adopter
- assessed_at: .planning/NEXT-STEP-ASSESSMENT.md (2026-05-27)
- goals:
  - Runbook capability-registration API so host apps declare named recovery actions
  - Operator UI Guidance → Preview → Confirm flow (no auto-execution; explicit Confirm required)
  - 4–6 prebuilt recovery playbooks: retry storm, suppression drift, stalled async, dead-letter drain, deploy-tied incident, cardinality blowout
  - Audit propagation: every action emits a `TimelineEntry` + `ToolAudit` inside `Parapet.Operator.ActionPayload` (circuit breaker + multi-node claim service apply for free)
  - Demo seed: fresh demo app shows at least one runbook with a Preview-able + Confirm-able action wired
- out_of_scope: autonomous remediation, cross-app journey correlation, multi-tenant action scoping
- research: `.planning/threads/actionable-recovery-design.md`, `docs/operator-ui.md` (Phase 7 design), `prompts/parapet-engineering-dna-from-sibling-libs.md`

### v1.2 Authoring DX & Maturity

- status: candidate (deferred from v1.1)
- theme: post-freeze additive ergonomics + maturity signals on a stable release line
- why_next: matures the adopter surface once the v1.1 action loop is closed; closes the documentation gaps a real adopter hits (deployment, upgrade) and the supply-chain gaps a real maintainer hits (Dependabot, SHA-pinned actions, branch-protection bypass)
- goals:
  - SLO-W1: `mix parapet.gen.slo` as a flag-based Igniter task (design resolved in `prompts/V1-SLO-WIZARD-BUNDLES.md`)
  - Multi-version Elixir/OTP CI matrix
  - Supply-chain hardening: SHA-pinned actions, Dependabot config (currently missing), `MAINTAINING.md` maintainer runbook, hexdocs logo/favicon
  - Branch-protection enforcement: make `release_gate` truly required (close the admin bypass — see `.planning/threads/release-gate-enforcement.md`)
  - Codify direct-to-main vs PR-required taxonomy (conventional commits) in `CONTRIBUTING.md` + PR template
  - v0.x → v1.0 migration guide
  - Deployment guide (end-to-end "deploy parapet + operator UI to production")
- research: `.planning/research/V1-*.md`, `.planning/threads/release-gate-enforcement.md`

### v1.3 Team Workflow & Coordination (JTBD #2)

- status: candidate (post-recovery, post-maturity)
- theme: responder coordination, handoff, on-call rotation — turn parapet into a tool larger orgs adopt, not just solo teams
- goals (provisional, refine when this opens):
  - Ownership / responder model (who's on the hook for this incident class)
  - Handoff & acknowledgement formalization
  - On-call rotation hooks (PagerDuty / Opsgenie / generic webhook adapter)

### v1.4+ Cross-boundary journey + vertical packs (JTBD #4)

- status: candidate (long-tail)
- theme: multi-app journey correlation; additional starter packs for non-Phoenix-default verticals
