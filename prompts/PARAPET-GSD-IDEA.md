# Parapet — GSD new-project idea document

Use with: `/gsd-new-project` from the `parapet` repo root (`/Users/jon/projects/parapet`).

For the exact clean-window kickoff message and attachment set, use `prompts/INTERACTIVE-GSD-NEW-PROJECT.md`.

## One-line pitch

**Parapet** is an open-source **Phoenix reliability layer** for Elixir apps: an opinionated SRE substrate that turns existing telemetry into **safe metrics, user-journey SLOs, deploy correlation, incident evidence, runbooks, doctor checks, and operator-grade diagnostics**.

## Problem

Phoenix, Ecto, Plug, Oban, LiveView, OpenTelemetry, Prometheus, Grafana, Loki, and related tools already exist.

What does not exist is the **batteries-included reliability layer** that makes them cohere for a Phoenix SaaS team:

- what should be measured;
- which user journeys deserve SLOs;
- how to keep metrics low-cardinality and safe;
- how to correlate incidents with deploys, flags, providers, and jobs;
- how to give operators evidence instead of dashboards alone;
- how to make this feel host-owned instead of vendor-owned.

Today, teams either assemble this by hand or buy a hosted platform with a different set of tradeoffs.

## Product principles

- **Reliability layer, not backend.** Parapet composes existing telemetry, tracing, logging, and metrics systems. It does not try to replace Grafana, Prometheus, OpenTelemetry, or a log store.
- **Page on user harm.** Alerts should represent customer-facing hurt, not generic system noise.
- **Evidence-first.** Metrics, wide events, timelines, deploy markers, and incident bundles should make mitigation obvious.
- **Host-owned and composable.** The app owns its repo, auth boundary, provider choices, and runtime. Parapet supplies the paved road.
- **Safe defaults.** Low-cardinality metrics, redaction, bounded labels, and explicit contracts are table stakes.
- **Operator-grade DX.** Great developer ergonomics are necessary but not sufficient; the operator story has to be first-class.
- **Ecosystem-native.** Parapet should feel like it belongs beside Sigra, Chimeway, Mailglass, Threadline, Rulestead, Accrue, and Rindle.

## Non-goals

- Not a hosted observability SaaS.
- Not a Datadog clone, APM backend, or log database.
- Not a generic cross-language platform first.
- Not a replacement for Phoenix telemetry, OpenTelemetry, LiveDashboard, or vendor SDKs.
- Not an unbounded autonomous incident-response agent.

## Technical direction

- Treat Parapet as a **reliability substrate** with a few distinct pillars:
  - telemetry contract and redaction-safe event model;
  - user-journey SLIs and SLOs;
  - alerting and burn-rate policy generation;
  - deploy and change correlation;
  - runbooks, doctor checks, and diagnostics;
  - operator/admin surfaces for investigation;
  - AI-readable investigation bundles as a later extension.
- Start with **host-owned generated setup** or clearly inspectable configuration over hidden magic.
- Distinguish **telemetry** from **durable evidence**. Telemetry is lossy and ephemeral; evidence surfaces may need DB-backed timelines, snapshots, or incident bundles.
- Use the existing library ecosystem as deliberate integration surfaces:
  - `sigra` for auth and security-critical flows;
  - `chimeway` and `mailglass` for outbound delivery health;
  - `threadline` for durable incident context and audits;
  - `rulestead` for flag/deploy correlation;
  - `accrue` for revenue-critical journeys;
  - `rindle` for media/processing reliability.

## OSS / engineering constraints

Ship with the same discipline established in your recent Elixir OSS family:

- explicit Hex package boundaries and `files:` whitelist;
- Conventional Commits + Release Please;
- stable CI job ids and scripts-first workflows;
- `mix verify.*` surfaces for proof and release parity;
- optional dependencies that compile out cleanly;
- documented telemetry contracts treated as API;
- doctor/diagnostics surfaces for adopter confidence;
- admin/operator UI only when it materially improves the paved road;
- generated code should remain host-owned and inspectable.

The synthesized defaults live in `prompts/parapet-engineering-dna-from-sibling-libs.md`.

## Prior research and seed context

Read these first during GSD questioning and research:

1. `prompts/sre-observability-elixir-lib-deep-reseach.md`
2. `prompts/parapet-brand-identity-deep-research.md`
3. `prompts/elixir-telemetry-space-deep-research.md`
4. `prompts/sre-best-practices-solo-founder-deep-research.md`
5. `prompts/parapet-engineering-dna-from-sibling-libs.md`
6. `prompts/parapet-integration-opportunities.md`
7. `prompts/prior-art/SOURCE-CANONICAL.md`

## Suggested first milestone

**Milestone v0.1 — “Trustworthy spine”**

- establish Parapet as a single Hex package with a narrow, explicit public surface;
- lock the telemetry and evidence model for a few core Phoenix SaaS user journeys;
- ship one or two high-value reliability slices end-to-end, likely:
  - HTTP/API request health;
  - Oban/job health;
  - one business-critical journey such as login, billing, or transactional email;
- generate or document sane defaults for:
  - low-cardinality metrics;
  - redaction-safe metadata;
  - deploy/change markers;
  - a minimal health/doctor surface;
  - one or more Grafana/Prometheus-facing artifacts;
- produce a README and guide set that makes the Day-1 install path obvious.

## Open decisions for GSD questioning / planning

- **Package shape:** single `parapet` package first, or separate admin/UI package later.
- **Install surface:** how much should come from a generator vs pure library configuration in v0.1.
- **Durable evidence model:** should v0.1 include a DB-backed evidence spine, or stay telemetry-first with durable surfaces deferred.
- **Initial user journeys:** which first-class SLO slices make the v0.1 cut.
- **Tier-1 integrations:** which sibling-library integrations are baked into v0.1 vs documented as later milestones.
- **Operator UI timing:** when diagnostics and incident surfaces become worth their maintenance cost.

## Instruction to GSD

Treat this file as authoritative for the product thesis, constraints, non-goals, and first-milestone direction.

Use the attached Parapet docs to refine:

- the exact reliability wedge;
- the v0.1 public API and install story;
- the first user journeys to support;
- the DNA and integration assumptions inherited from sibling Elixir/Phoenix libraries.
