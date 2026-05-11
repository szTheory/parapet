# Research Summary: Parapet v0.2

**Domain:** SRE / Observability / Incident Management (Elixir SaaS)
**Researched:** 2026-05-11 (Contextual Date)
**Overall confidence:** HIGH

## Executive Summary

Parapet v0.1 established the "ephemeral" telemetry layer: metrics, SLOs, and Grafana artifacts. Milestone v0.2 introduces the "durable" operator layer: a database-backed incident evidence spine, an in-app Operator UI, and integrations with the wider sibling Elixir ecosystem (Chimeway, Mailglass, Threadline, Rulestead, Accrue, Rindle). 

The core research insight is that **telemetry is lossy and ephemeral, but evidence must be durable and actionable.** Ecto and PostgreSQL are not suited for raw telemetry storage, but they are the ideal substrate for an *Incident Evidence Spine*—modeling incidents, mitigation timelines, postmortems, and AI tool-call audits. Concurrently, while Grafana remains the supreme tool for metrics visualization and exploration, it fundamentally lacks the capability for *application mutation* (e.g., toggling feature flags, approving AI mitigations, or correlating user-specific durable state). Therefore, an in-app LiveView Operator UI is required not to replace Grafana, but to complement it as the *action and resolution* surface. 

Finally, sibling integrations move Parapet from a generic tool to an opinionated platform. By inherently understanding `rulestead` (feature flags as incident causes), `mailglass`/`chimeway` (deliverability as critical reliability), and `threadline` (audit trails), Parapet provides a cohesive SRE narrative out of the box.

## Key Findings

**Stack:** Phoenix LiveView for the action-oriented Operator UI, Ecto for the relational incident state machine, and specific decoupled adapter modules for sibling integrations.
**Architecture:** Strict boundary between ephemeral high-volume telemetry (Prometheus/Grafana) and durable low-volume evidence (Ecto/PostgreSQL). 
**Critical pitfall:** Conflating telemetry with evidence by streaming high-volume metrics into Ecto, or attempting to rebuild Grafana's charting capabilities in Phoenix LiveView.

## Implications for Roadmap

Based on research, suggested phase structure for v0.2:

1. **Phase 1: The Durable Evidence Spine (Ecto)** - Data modeling for incidents, timelines, mitigations, and AI tool audits.
   - Addresses: The need for a durable incident state machine.
   - Avoids: Writing high-volume telemetry to PostgreSQL.

2. **Phase 2: In-App Operator UI (LiveView)** - Action-oriented SRE dashboards.
   - Addresses: The gap between seeing an alert in Grafana and safely mutating app state (e.g., rollbacks, runbooks, flag toggles).
   - Avoids: Replacing Grafana or building complex time-series charts in Elixir.

3. **Phase 3: Sibling Ecosystem Integrations** - Connect Chimeway, Mailglass, Rulestead, Accrue, Rindle, and Threadline.
   - Addresses: Turning generic SRE into business-aware observability (e.g., billing SLOs, deliverability SLIs, feature flag correlations).
   - Avoids: Hard runtime coupling; must remain optional compile-time integrations.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Phoenix, LiveView, and Ecto are the non-negotiable tech stack constraints for this ecosystem. |
| Features | HIGH | The feature landscape is explicitly defined by previous SRE research and sibling library product strategies. |
| Architecture | HIGH | The ephemeral vs. durable split is a proven industry standard (e.g., Prometheus vs. incident trackers). |
| Pitfalls | HIGH | Known footguns with Ecto pool saturation and LiveView charting overhead are well-documented. |

## Gaps to Address

- **Threadline Overlap:** Threadline is an audit/evidence library. We need to determine if Parapet's Timeline entries should natively wrap Threadline or remain independent but conceptually compatible.
