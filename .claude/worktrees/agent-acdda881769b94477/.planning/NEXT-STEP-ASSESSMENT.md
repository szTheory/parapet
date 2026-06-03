---
assessment_version: 1
assessed: "2026-05-27"
post_milestone: v1.0.0
target_milestone: v1.1 Actionable Recovery
status: active
expires_on: "v1.1 ship"
---

# Post-1.0 Strategic Assessment

Snapshot of where parapet stands after the v1.0.0 cut on 2026-05-26, what the highest-leverage next milestone is, and what should NOT be built next. Re-derive by parallel Explore agents (shipped surface · research+learnings+threads · adopter reality check) when v1.1 ships.

## Framing

- **One job:** A Phoenix SaaS team installs parapet and immediately knows whether critical user journeys are healthy via SLO-driven alerts + runbooks + a LiveView operator workbench — replacing vague dashboards with evidence-first reliability.
- **What "done" means here:** Adopter trust + workflow closure for the single-tenant Phoenix SaaS team. Not platform parity with DataDog, not multi-cloud, not autonomous remediation.
- **Confidence:** High. Code matches planning docs (rare). No drift between aspiration and reality to flag.

## Current state (rough done-%: 82–87% — band: strong, meaningful wedges remain)

- 75 lib modules / 91 test files; v0.1 → v1.0 shipped clean with 24/24 v1.0 requirements complete.
- Real (verified in code, not just docs): durable spine, SLO engine + WebSaaS/DeliverySaaS packs, generated operator LiveView, 8 integration adapters (Sigra/Accrue/Rulestead/Chimeway/Mailglass/Rindle/Threadline/Scoria), runbook DSL, escalation policies + circuit breakers + Oban-backed claims for multi-node safety, evidence archiver, deploy markers, MCP read-only server, `mix parapet.doctor`.
- Runnable demo app (Phoenix child app under `examples/demo_app/`) wired into release_gate CI as a contract.

## Adopter coverage map

**Well-served:**
- Day-1 activation (`mix parapet.install` → orchestrates 5 generators idempotently)
- Detection of HTTP / login / Oban / async-delivery problems via SLO packs
- Incident timeline + immutable evidence + ToolAudit
- Stability commitments (3-tier, deprecation cycle, telemetry frozen)

**Partially served:**
- SLO authoring (engine + packs are great; custom journeys still require hand-written PromQL — contradicts "zero PromQL" marketing)
- Operator UI (real LiveView surface, but adopter owns auth + tenant isolation; no turnkey scope mount)
- CI hygiene (lint/test/demo/release_gate all green; `release_gate` currently *bypassable* by admin — every direct push to main on 2026-05-27 reported "Bypassed rule violations")
- Integration docs (8 guides exist, all uniform; Sigra prereq for login journey is silent — metric stays zero, no surfaced error)

**Still rough:**
- **Recovery action wiring** — operator UI cannot one-click execute runbook steps (Phase 7 design unshipped) ← biggest gap
- **Deployment guide** — no end-to-end "deploy parapet + operator UI to production" doc; secrets, cluster, archival left implicit
- **Multi-tenant** — assumes single-tenant; no per-customer SLO or per-org operator-view recipe
- **Upgrade path** — CHANGELOG jumps v0.10 → v1.0 with one line; no v0.x → v1.0 migration guide
- **Team workflow** (JTBD-MAP #2) — responder coordination, handoff, shift awareness thin
- **Test parallelism** — only 1 async test file; serial suite is slow as adoption grows

## Next-work recommendation (ordered)

### v1.1 — Actionable Recovery (the wedge)

**Why it's the pick:** Closes the loudest credibility gap from v1.0. Unlocks the operator UI's full value prop. Every existing adopter gets value, not just authoring-flow new users. JTBD-MAP's Very-High-priority recovery-depth gap is the same gap.

**Scope (done-enough):**
1. **Runbook capability-registration API** — host apps declare named recovery actions parapet can dispatch.
2. **Operator UI Preview → Confirm flow** — Guidance shown first; Preview renders the action with its parameters and the diff it'll cause; Confirm executes inside a `Parapet.Operator.ActionPayload` envelope so it's audited + circuit-broken.
3. **4–6 prebuilt recovery playbooks** for the failure modes JTBD-MAP names: retry storm, suppression drift, stalled async, dead-letter drain, deploy-tied incident, cardinality blowout.
4. **Audit propagation** — every recovery action emits a `TimelineEntry` + `ToolAudit` row so the spine remembers what was done by whom.
5. **Demo seed** — fresh `iex -S mix phx.server` in the demo app shows at least one runbook with a Preview-able action wired up; closes the "empty incident queue on fresh clone" gap.

**Not in scope:** Autonomous remediation (parapet stays operator-in-the-loop), cross-app journey correlation, multi-tenant action scoping.

### v1.2 — Authoring DX & Maturity

- SLO-W1 as flag-based Igniter task (design resolved in `prompts/V1-SLO-WIZARD-BUNDLES.md` — don't re-argue)
- Elixir/OTP CI matrix
- Supply-chain hardening: SHA-pinned actions, Dependabot config (currently missing), `MAINTAINING.md`, hexdocs logo/favicon
- v0.x → v1.0 migration guide
- Deployment guide

### v1.3 — Team Workflow & Coordination (JTBD #2)

- Ownership / responder model (who's on the hook for this incident class)
- Handoff & acknowledgement formalization
- On-call rotation hooks (PagerDuty / Opsgenie / generic webhook adapter)

### v1.4+ — Cross-boundary journey + vertical packs

- Multi-app journey correlation (JTBD #4)
- Additional starter packs for non-Phoenix-default verticals

## Diminishing-returns judgment

**Keep pushing:** v1.1 Actionable Recovery (clear net-new value for every adopter), v1.2 maturity items (CI matrix + Dependabot + missing guides are real adoption signals).

**Polish / probably-overbuild:**
- A wizard-style SLO authoring UX (flag-based Igniter task already settled this)
- Adding more integration adapters before solving recovery
- Multi-tenant scope work before single-tenant recovery is solid

**Don't build:**
- Hosted SaaS control plane
- Autonomous (no-human) remediation
- Replacing the operator's Grafana / log tool

## Blunt maintainer takeaway

Build **Actionable Recovery as v1.1**, treat v1.2 as the maturity dividend (SLO-W1 + CI matrix + dep hygiene + missing guides), and stop scope-creep on integrations until v1.3 team-workflow lands. Parapet is at the stage where **closing the loop on what's already sold beats adding new top-line features.** The lib is 82–87% done for its intended scope; the remaining 13–18% is the difference between "looks credible" and "I trust this in prod."

## Unified GSD workflow (maintenance + feature)

The quiet-stable-line policy already names two modes; today's session exposed that the bypass undermines the policy. Tighten:

1. **Make `release_gate` actually required.** Branch protection should block admin pushes that haven't passed `release_gate`. Today's pattern (admin power → bypass → docs/test-config regressions like the `docs/release-policy.md` not-in-extras one) is exactly what `release_gate` is supposed to prevent.
2. **Taxonomy for direct-to-main** (codify in `CONTRIBUTING.md` and PR template):
   - **OK direct (quiet maintenance):** docs-only, `.planning/` updates, formatting, test hygiene that doesn't change behavior, CI config that doesn't relax gates. Use conventional commits (`docs:`, `chore:`, `ci:`, `test:`).
   - **PR-required (feature/maintenance with risk):** any `lib/` behavior change, any new public API, any schema change, any dep bump, anything `feat:` or `fix:` typed.
3. **Release Please already enforces conventional commits** → the taxonomy aligns with what Release Please reads to generate the next version.
4. **GSD's quiet mode stays the default**; opening a milestone is the explicit signal that PR-shaped feature work has begun.

## Open threads

- `.planning/threads/actionable-recovery-design.md` — v1.1 design investigation
- `.planning/threads/release-gate-enforcement.md` — make `release_gate` truly required

## Bookkeeping written this pass

- `.planning/NEXT-STEP-ASSESSMENT.md` (this file)
- `.planning/phases/22-release-readiness-1-0-cut/22-LEARNINGS.md`
- `.planning/threads/actionable-recovery-design.md`
- `.planning/threads/release-gate-enforcement.md`
- `.planning/STATE.md` (2026-05-27 entry + candidate work refresh)
- `.planning/MILESTONE-ARC.md` (v1.1 swapped to Actionable Recovery; SLO-W1 → v1.2)
- `.planning/PROJECT.md` (current state + candidate work refresh)
- User auto-memory: 4 new entries (parallel-explore for strategy, adopter-first done lens, phase-close LEARNINGS discipline, v1.1 target)

## Graduation candidates (surfaced for v1.2 planning)

- The "release_gate bypass is currently soft" finding should become a v1.2 supply-chain hardening requirement.
- The "no LEARNINGS files exist" gap should graduate into a GSD process default: write LEARNINGS at phase close, not just SUMMARY.
