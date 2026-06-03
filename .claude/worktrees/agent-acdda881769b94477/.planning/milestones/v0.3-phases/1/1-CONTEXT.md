# Phase 1: Alert Routing & Reception - Context

This document captures the architectural decisions and alignment from the `discuss` phase for Phase 1. It serves as the foundation for the upcoming `plan` phase.

## Resolved Decisions

### 1. Webhook Routing Location & API Surface
**Decision**: Use a standalone `Plug` (`Parapet.Plug.Webhook`).
**Rationale**: Adheres to the "host-owned auth, no opaque magic" DNA. Instead of generating brittle controller code or using hidden macros, Parapet exposes a standard Plug. The host application operator mounts this plug explicitly in their `router.ex` (e.g., `forward "/parapet/webhooks", Parapet.Plug.Webhook`), retaining full control over the pipeline, scope, and authentication.

### 2. Incident Correlation Strategy (ROUTING-04)
**Decision**: Add a `correlation_key` (string) to `Parapet.Spine.Incident`.
**Rationale**: To prevent incident spam from subsequent firing alerts, Parapet will use a deterministic hash of the alert (the Prometheus `fingerprint` or `alertname` + `labels`) as a unique correlation key. Incoming alerts will attempt an upsert (`Repo.insert! on_conflict: :nothing`) or `Repo.get_by(correlation_key: key, state: "open")` rather than relying on complex JSON label matching.

### 3. Alertmanager Batch Processing
**Decision**: 1 Incident per individual Alert inside the webhook batch.
**Rationale**: Prometheus Alertmanager sends batches of alerts. Parapet will decouple the HTTP transport batch from the logical incident domain by iterating through the `.alerts` array and processing each alert independently based on its `correlation_key`. This guarantees high fidelity tracking and avoids the catastrophic "partially resolved" state-machine footgun when grouping alerts together.

### 4. Resolution Audit Trail (ROUTING-03)
**Decision**: Auto-resolution must mutate state AND insert a `TimelineEntry` via `Ecto.Multi`.
**Rationale**: Parapet's core brand is "durable evidence." When a "resolved" webhook automatically closes an incident, the system must use a database transaction to both update the Incident `state` and insert an undeniable `Parapet.Spine.TimelineEntry` (e.g., `action: "auto_resolved"`). This ensures operators can historically prove exactly when and how the system closed the incident.

## Ecosystem Alignment
These decisions explicitly prioritize the patterns proven in sibling libraries (`chimeway`, `mailglass`, `threadline`): explicit data boundaries, host-owned integration seams, and linear event auditability.
