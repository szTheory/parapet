# Parapet

## What This Is

Parapet is an open-source Phoenix reliability layer for Elixir SaaS teams: an opinionated SRE substrate that turns existing telemetry into safe metrics, user-journey SLOs, deploy correlation, incident evidence, runbooks, doctor checks, and operator-grade diagnostics. It composes Phoenix, Ecto, Oban, OpenTelemetry, Prometheus, and Grafana into a coherent reliability story without replacing any of them. The target adopter is a Phoenix SaaS team that has good tools but no paved road connecting them.

## Core Value

A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## Requirements

### Validated

- ✓ Single `parapet` Hex package with a narrow, explicit public surface and `files:` whitelist — v0.1
- ✓ Documented telemetry contract treated as public API — redaction-safe, low-cardinality by default — v0.1
- ✓ HTTP/API request health SLI/SLO slice — error rate, latency, availability per route group — v0.1
- ✓ Oban/job health SLI/SLO slice — failure rate, throughput, latency per queue and worker — v0.1
- ✓ Login journey as the first business-critical SLO — auth success rate via `sigra` integration — v0.1
- ✓ Deploy/change markers — correlated with SLO windows and error spikes — v0.1
- ✓ Grafana dashboard and Prometheus alerting rule artifacts generated or documented as sane defaults — v0.1
- ✓ Minimal `mix parapet.doctor` health check surface for adopter confidence — v0.1
- ✓ Day-1 install guide and README that covers configuration through first alert — v0.1
- ✓ System provides Ecto schemas for Incidents with a state machine (open, investigating, resolved) — v0.2
- ✓ System provides Ecto schemas for Timeline Entries linked to Incidents to durably track alerts, notes, and actions — v0.2
- ✓ System provides Ecto schemas for Tool Audits to securely log AI and human MCP tool calls — v0.2
- ✓ System enforces a clear boundary preventing raw high-volume telemetry from entering Ecto — v0.2
- ✓ System provides a Phoenix LiveView SRE dashboard to manage incidents and timelines — v0.2
- ✓ System provides a secure UI surface to execute and audit application mutations (e.g., toggling feature flags) — v0.2
- ✓ System UI integrates external visualization links (e.g., Grafana) rather than rebuilding charting in LiveView — v0.2
- ✓ System provides generators to secure the LiveView UI behind host application authentication — v0.2
- ✓ Optional Rulestead integration to track feature flag changes and enable flag-toggling mitigations — v0.2
- ✓ Optional Mailglass and Chimeway integrations for deliverability SLIs — v0.2
- ✓ Optional Accrue (billing) and Rindle (media processing) integrations for business-specific journey health — v0.2
- ✓ Strict adherence to the "compile out cleanly" constraint for all sibling libraries — v0.2
- ✓ Conceptual integration with Threadline for durable audit history interoperability — v0.2

### Active

<!-- Add requirements for v0.3 here when planning next milestone -->

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Hosted observability SaaS — Parapet is host-owned infrastructure, not a vendor product
- APM backend, log database, or trace store — Parapet composes existing systems; it does not replace them
- Replacement for Phoenix Telemetry, OpenTelemetry, LiveDashboard, or vendor SDKs — composing these is the point
- Generic cross-language platform — Elixir/Phoenix ecosystem-native first; cross-language is a different product
- Unbounded autonomous incident-response agent — evidence-first tooling, not AI autopilot

## Context

Shipped v0.2 with a focus on Durable Evidence, LiveView Operator UI, and ecosystem integrations.
The implementation separated ephemeral telemetry from durable low-volume Ecto schema data for incident timelines. A Phoenix LiveView SRE dashboard was generated to provide an operator workbench.

## Constraints

- **Tech stack**: Elixir/Phoenix only — ecosystem-native is a hard constraint, not a preference
- **Package boundary**: Single `parapet` Hex package for v0.1/v0.2
- **Install model**: Generator for host-owned scaffolding, library config for runtime behavior — generated files must remain inspectable and modifiable by the adopter
- **Metrics safety**: Low-cardinality by default, explicit label contracts, redaction-safe metadata — violations of this are bugs, not configuration options
- **Telemetry as API**: Documented telemetry events are a public API surface with semver guarantees — treat breakage the same as a function signature change
- **Optional dependencies**: All integration deps (sigra, oban, etc.) must compile out cleanly when absent — no hard runtime coupling
- **OSS discipline**: Conventional Commits + Release Please, stable CI job ids, `mix verify.*` proof surfaces, `files:` whitelist on Hex publish

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Dynamic Repo lookup via `Application.get_env` | Decouples library from specific host database | ✓ Good |
| Ecto schema changesets tested purely without DB | Ensures decoupling from specific host application databases | ✓ Good |
| Strict boundary between telemetry and Ecto | Prevents Ecto from being used for raw high-volume telemetry | ✓ Good |
| Sibling ecosystem integrations as optional adapters | Adheres to "compile out cleanly" constraint using `Code.ensure_loaded?` | ✓ Good |
| AI/MCP tool calls must be audited | Requires `Parapet.Ecto.ToolAudit` for app mutations | ✓ Good |
| Static analysis of doctor checks | Prevents global compilation side-effects by not dynamically injecting router modules in tests | ✓ Good |
| Automated structural UI layout verification | Verifies responsive tailwind layout logic via static file testing instead of full browser E2E to keep dependency footprint light and fast | ✓ Good |

---
*Last updated: 2026-05-11 after v0.2 milestone*