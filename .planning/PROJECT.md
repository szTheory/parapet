# Parapet

## What This Is

Parapet is an open-source Phoenix reliability layer for Elixir SaaS teams: an opinionated SRE substrate that turns existing telemetry into safe metrics, user-journey SLOs, deploy correlation, incident evidence, runbooks, doctor checks, and operator-grade diagnostics. It composes Phoenix, Ecto, Oban, OpenTelemetry, Prometheus, and Grafana into a coherent reliability story without replacing any of them. The target adopter is a Phoenix SaaS team that has good tools but no paved road connecting them.

## Core Value

A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. v0.1 "Trustworthy spine" -->

- [ ] Single `parapet` Hex package with a narrow, explicit public surface and `files:` whitelist
- [ ] Documented telemetry contract treated as public API — redaction-safe, low-cardinality by default
- [ ] HTTP/API request health SLI/SLO slice — error rate, latency, availability per route group
- [ ] Oban/job health SLI/SLO slice — failure rate, throughput, latency per queue and worker
- [ ] Login journey as the first business-critical SLO — auth success rate via `sigra` integration
- [ ] Deploy/change markers — correlated with SLO windows and error spikes
- [ ] Grafana dashboard and Prometheus alerting rule artifacts generated or documented as sane defaults
- [ ] Minimal `mix parapet.doctor` health check surface for adopter confidence
- [ ] Day-1 install guide and README that covers configuration through first alert

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Hosted observability SaaS — Parapet is host-owned infrastructure, not a vendor product
- APM backend, log database, or trace store — Parapet composes existing systems; it does not replace them
- Replacement for Phoenix Telemetry, OpenTelemetry, LiveDashboard, or vendor SDKs — composing these is the point
- Generic cross-language platform — Elixir/Phoenix ecosystem-native first; cross-language is a different product
- Unbounded autonomous incident-response agent — evidence-first tooling, not AI autopilot
- DB-backed durable evidence spine in v0.1 — telemetry-first establishes the contract before committing to a persistence model; defer to v0.2
- Operator/admin UI in v0.1 — Grafana artifacts provide the operator surface; in-app UI only when it materially beats the alternative
- `chimeway`, `mailglass`, `threadline`, `rulestead`, `accrue`, `rindle` integrations in v0.1 — login/sigra is sufficient to validate the integration pattern; others follow after the spine is proven

## Context

Phoenix SaaS teams have strong individual tools — telemetry, OTel, Prometheus, Grafana, Oban, Loki — but no opinionated layer that tells them what to measure, how to keep metrics safe, which journeys deserve SLOs, or how to correlate an incident with a deploy or flag change. The choice today is hand-assembly or a hosted platform with a different tradeoff profile. Parapet occupies the gap: open-source, host-owned, ecosystem-native.

The project is part of an established Elixir OSS family (Sigra, Chimeway, Mailglass, Threadline, Rulestead, Accrue, Rindle). Engineering DNA is documented in `prompts/parapet-engineering-dna-from-sibling-libs.md` and applies here: Conventional Commits, Release Please, scripts-first CI, `mix verify.*` surfaces, optional deps that compile out cleanly, and generated code that stays host-owned.

Key insight from product principles: **telemetry is lossy and ephemeral; evidence is durable**. v0.1 must establish this distinction in the model even if it only ships the telemetry side. Getting the contract right now prevents breaking changes when durable surfaces are added.

Prior research is in `prompts/` — sre-observability, brand identity, elixir telemetry space, SRE best practices for solo founders, integration opportunities, and prior art. Read before making architecture decisions.

## Constraints

- **Tech stack**: Elixir/Phoenix only — ecosystem-native is a hard constraint, not a preference
- **Package boundary**: Single `parapet` Hex package for v0.1 — splitting admin/UI into a separate package is deferred but expected; design the boundary now
- **Install model**: Generator for host-owned scaffolding, library config for runtime behavior — generated files must remain inspectable and modifiable by the adopter
- **Metrics safety**: Low-cardinality by default, explicit label contracts, redaction-safe metadata — violations of this are bugs, not configuration options
- **Telemetry as API**: Documented telemetry events are a public API surface with semver guarantees — treat breakage the same as a function signature change
- **Optional dependencies**: All integration deps (sigra, oban, etc.) must compile out cleanly when absent — no hard runtime coupling
- **OSS discipline**: Conventional Commits + Release Please, stable CI job ids, `mix verify.*` proof surfaces, `files:` whitelist on Hex publish

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Single `parapet` package for v0.1 | Avoids premature boundary splits before the public API is stable; admin/UI package boundary is designed in but deferred | — Pending |
| Telemetry-first in v0.1, no DB-backed evidence spine | Establishes the event contract before committing to a persistence model; avoids locking adopters into a schema prematurely | — Pending |
| HTTP + Oban as the two v0.1 SLO slices | These cover the most universal Phoenix SaaS reliability concerns and validate the full SLI→SLO→alert pipeline | — Pending |
| Login journey (via sigra) as first business SLO | Auth is the single most universal business-critical journey; validates the sibling-library integration pattern at minimal scope | — Pending |
| Grafana/Prometheus artifacts over in-app operator UI | Operators already have Grafana; an in-app UI in v0.1 would cost more than it buys until the evidence model is proven | — Pending |
| Generator for scaffolding, library for runtime | Host-owned principle requires adopters to be able to read and modify what Parapet puts in their repo | — Pending |

---
*Last updated: 2026-05-09 after initial project definition*
