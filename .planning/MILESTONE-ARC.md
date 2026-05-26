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

### v1.1 Authoring DX & Maturity

- status: candidate
- theme: post-freeze additive ergonomics on a stable release line
- why_next: reopen only when a concrete feature slice is ready to be worked through a PR without diluting the stable-main posture
- goals:
  - SLO-W1: `mix parapet.gen.slo` as a flag-based Igniter task (not an interactive wizard)
  - Multi-version Elixir/OTP CI matrix
  - Supply-chain hardening (SHA-pinned actions), hexdocs logo/favicon, `MAINTAINING.md` maintainer runbook
  - Keep `main` green and releasable through the Release Please PR flow documented in `docs/release-policy.md`
- research: `.planning/research/V1-*.md`
