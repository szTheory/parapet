# Milestone Arc: Ecosystem Ubiquity & Operator Mastery

## Shipped

- **v0.9 Performance, Scale & DX** (2026-05-23) — confidence under load: TSDB cardinality protection, DB scale & pruning, responsive Operator UI at 50k+ incidents, unified `mix parapet.install`, multi-node safety.
- **v0.10 Adopter Success** (2026-05-24) — credibility gate: hex.pm metadata + Release-Please CHANGELOG, one-line SLO starter packs, end-to-end `warning:` runbook depth, seven adoption guides + a uniform `Parapet.Integration` activation behaviour.

## Active Milestone

### v1.0 Stable Release

- status: active (planning) — Phases 19-22
- theme: API freeze and release readiness
- why_now: Lock the public surface only after ecosystem coverage and operational sharp edges are proven in adoption. Posture is the Oban-1.0 model — cleanup + a written stability promise, not a feature vehicle.
- goals:
  - Freeze the public API + telemetry contract under stability tiers (Stable/Experimental/Internal) + a written deprecation policy, enforced by `mix verify.public_api` and a telemetry contract test
  - OSS governance docs (CONTRIBUTING/SECURITY/CODE_OF_CONDUCT) + complete the four missing integration guides + hexdocs polish
  - A runnable demo app (`examples/demo_app/`) that doubles as a live CI contract test for the frozen surface
  - A proportionate verification gate + the Release-Please `0.10.0 → 1.0.0` graduation
- research: `.planning/research/V1-*.md`

## Candidate Milestones

### v1.1 Authoring DX & Maturity

- status: candidate
- theme: post-freeze additive ergonomics
- why_next: After the freeze, add purely-additive DX that adoption evidence actually justifies (no frozen-surface risk).
- goals:
  - SLO-W1: `mix parapet.gen.slo` as a flag-based Igniter task (not an interactive wizard)
  - Multi-version Elixir/OTP CI matrix
  - Supply-chain hardening (SHA-pinned actions), hexdocs logo/favicon, `MAINTAINING.md` maintainer runbook
