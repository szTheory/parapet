# v0.9 Requirements: Performance, Scale & DX

## Overview
Milestone v0.9 shifts focus from feature breadth to operational depth. With the core SRE primitives, Operator UI, and integrations in place, the system must now prove it can handle high scale without degrading the host application. This means protecting the TSDB from cardinality explosions, protecting the Postgres DB from evidence bloat, and streamlining the developer experience for new adoptions.

## Architectural Deep Dive & Trade-offs

### 1. TSDB Safety & Cardinality Control
- **The Problem:** The most common failure mode for observability tools is exploding the TSDB (e.g. Prometheus) with unbound label cardinality, causing OOMs or massive bills.
- **Approach:** We already have strict label regexes. We will add a static analysis tool (`mix parapet.doctor cardinality`) that parses all Parapet configurations and flags any potential dynamic labels (e.g., user IDs) that might leak into the TSDB.

### 2. Evidence Pruning & Database Scale
- **The Problem:** Tool audits, timeline entries, and incidents accumulate. Over years, this will bloat the host application's primary Postgres instance.
- **Approach:** Introduce `Parapet.Evidence.Archiver`. We will not invent a custom cold-storage engine; instead, we will provide a built-in mix task (`mix parapet.archive`) and an Oban cron job template to automatically prune or compress resolved incidents older than a configurable threshold (e.g. 90 days). Indexes will also be optimized for large datasets.

### 3. Generator Ergonomics (DX)
- **The Problem:** Adopters currently have to run `spine`, `ui`, and `grafana` generators separately, remembering the correct order.
- **Approach:** Introduce `mix parapet.install`. It acts as an interactive wizard (using `Igniter`), orchestrating the sub-generators and verifying dependencies to ensure a flawless "Day 1" experience.

## System Requirements

### PERF-01: TSDB Cardinality Protection
- [x] System provides a `mix parapet.doctor cardinality` sub-command to statically analyze metrics configurations and flag unsafe label patterns.
- [x] System strictly limits the number of labels per metric at compile-time to prevent accidental TSDB explosion.

### SCALE-01: Database Pruning & Indexing
- [x] System provides optimized Ecto migrations to add composite indexes to `Incident`, `TimelineEntry`, and `ToolAudit` for fast querying at >100k rows.
- [x] System provides a `Parapet.Evidence.Archiver` module and `mix parapet.archive` task to safely soft-delete or export resolved incidents older than a configurable window.
- [x] Operator UI Incident list utilizes efficient pagination or cursor-based scrolling to prevent large payload rendering issues.

### DX-01: Unified Install Path
- [x] System provides `mix parapet.install` as a unified, interactive starting point that sequentially runs necessary sub-generators.
- [x] System's `mix parapet.doctor` checks for correct multi-node configuration (e.g., verifying Oban uniqueness settings for escalations).

### SCALE-02: Multi-Node Consistency
- [x] System test suite includes multi-node or concurrency simulation tests verifying that Ecto-backed circuit breakers prevent race conditions when multiple nodes attempt auto-mitigation simultaneously.

## Acceptance Criteria
- [x] A developer can run `mix parapet.install` and get the spine and default Prometheus artifacts in one guided flow, with the optional operator UI offered explicitly when LiveView is present.
- [x] Running `mix parapet.archive --days 90` successfully moves/clears old evidence without violating foreign key constraints.
- [x] The Operator UI loads instantly with 50,000 generated incident records, proving pagination and index effectiveness.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PERF-01.a | Phase 6 | Verified |
| PERF-01.b | Phase 6 | Verified |
| SCALE-01.a | Phase 2 | Verified |
| SCALE-01.b | Phase 2 | Verified |
| SCALE-01.c | Phase 7 | Verified |
| DX-01.a | Phase 8 | Verified |
| DX-01.b | Phase 8 | Verified |
| SCALE-02 | Phase 5 | Verified |
| AC-01 | Phase 8 | Verified |
| AC-02 | Phase 2 | Verified |
| AC-03 | Phase 7 | Verified |
