# Roadmap: Parapet

## Overview

Parapet ships in four phases. Phase 1 lays the safety rails — the telemetry contract, label policy, supervisor design, and install generator — that every downstream component inherits. Phase 2 instruments the three universal Phoenix surfaces (HTTP, Ecto, Oban) on that foundation. Phase 3 adds the SLO DSL and the first business signals (login journey, deploy markers) that make Parapet more than a metrics shim. Phase 4 generates the operator artifacts (Prometheus rules, Grafana dashboards) and closes with the doctor gate and day-1 guide that make the library shippable.

## Milestones

- ✅ **v0.1 Trustworthy Spine** — Phases 1-4 (shipped 2026-05-10)
- ✅ **v0.2 Durable Evidence** — Phases 5-7 (shipped 2026-05-11)

## Phases

<details>
<summary>✅ v0.1 Trustworthy Spine (Phases 1-4) — SHIPPED 2026-05-10</summary>

- [x] **Phase 1: Telemetry Foundation & Safety Rails** - Core supervisor, label policy, optional dep seams, install generator, CI setup (completed 2026-05-09)
- [x] **Phase 2: HTTP, Ecto, and Oban Metrics** - Instrumentation surfaces delivering the "is my app healthy?" signal (completed 2026-05-09)
- [x] **Phase 3: SLO DSL, Login Journey, and Deploy Markers** - SLO engine, Sigra integration, deploy correlation (completed 2026-05-10)
- [x] **Phase 4: Artifact Generation, Doctor, and Launch Readiness** - Prometheus/Grafana artifacts, CI gate, day-1 guide (completed 2026-05-10)

</details>

<details>
<summary>✅ v0.2 Durable Evidence (Phases 5-7) — SHIPPED 2026-05-11</summary>

- [x] **Phase 5 (v0.2 Phase 1): Durable Evidence Spine** - Data modeling for incidents, timelines, mitigations, and AI tool audits (completed 2026-05-11)
- [x] **Phase 6 (v0.2 Phase 2): In-App Operator UI** - Action-oriented SRE dashboards focusing on incident management and mitigation (completed 2026-05-11)
- [x] **Phase 7 (v0.2 Phase 3): Sibling Ecosystem Integrations** - Optional adapters for Rulestead, Mailglass, Chimeway, Accrue, Rindle, and Threadline (completed 2026-05-11)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Telemetry Foundation & Safety Rails | v0.1 | 5/5 | Complete | 2026-05-09 |
| 2. HTTP, Ecto, and Oban Metrics | v0.1 | 2/2 | Complete | 2026-05-09 |
| 3. SLO DSL, Login Journey, and Deploy Markers | v0.1 | 4/4 | Complete | 2026-05-10 |
| 4. Artifact Generation, Doctor, and Launch Readiness | v0.1 | 4/4 | Complete | 2026-05-10 |
| 5. Durable Evidence Spine | v0.2 | 3/3 | Complete | 2026-05-11 |
| 6. In-App Operator UI | v0.2 | 4/4 | Complete | 2026-05-11 |
| 7. Sibling Ecosystem Integrations | v0.2 | 4/4 | Complete | 2026-05-11 |

