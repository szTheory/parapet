# Roadmap: Parapet

## Overview

Parapet ships in four phases. Phase 1 lays the safety rails — the telemetry contract, label policy, supervisor design, and install generator — that every downstream component inherits. Phase 2 instruments the three universal Phoenix surfaces (HTTP, Ecto, Oban) on that foundation. Phase 3 adds the SLO DSL and the first business signals (login journey, deploy markers) that make Parapet more than a metrics shim. Phase 4 generates the operator artifacts (Prometheus rules, Grafana dashboards) and closes with the doctor gate and day-1 guide that make the library shippable.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Telemetry Foundation & Safety Rails** - Core supervisor, label policy, optional dep seams, install generator, CI setup
- [ ] **Phase 2: HTTP, Ecto, and Oban Metrics** - Instrumentation surfaces delivering the "is my app healthy?" signal
- [ ] **Phase 3: SLO DSL, Login Journey, and Deploy Markers** - SLO engine, Sigra integration, deploy correlation
- [ ] **Phase 4: Artifact Generation, Doctor, and Launch Readiness** - Prometheus/Grafana artifacts, CI gate, day-1 guide

## Phase Details

### Phase 1: Telemetry Foundation & Safety Rails
**Goal**: The library's core safety guarantees are in place — adopters can install Parapet and trust that their metrics will be correct and secure from day one
**Depends on**: Nothing (first phase)
**Requirements**: PKG-01, PKG-02, PKG-03, PKG-04, TELE-01, TELE-02, TELE-03, TELE-04, INST-01, INST-02, INST-03, INST-04, INST-05, DOCS-02, DOCS-04, ERR-01, ERR-03, ERR-04, OSS-01, OSS-02, OSS-03, OSS-04
**Success Criteria** (what must be TRUE):
  1. `mix parapet.install` runs on a fresh Phoenix app and produces inspectable, host-owned scaffolding in `lib/` and `config/` with inline comments
  2. Running `mix parapet.install` twice on an already-configured app prints "already configured" for each step and makes no file changes
  3. A telemetry handler that raises an exception is re-attached by the supervisor and the exception is logged — the host process does not crash
  4. A metric label with a high-cardinality value (raw request path, UUID-format user ID) is rejected at compile time — not silently passed through to Prometheus
  5. `mix verify.public_api` exits non-zero when an undocumented public module exists in the library
**Plans**: TBD

### Phase 2: HTTP, Ecto, and Oban Metrics
**Goal**: An adopter can see HTTP request rate, error rate, latency, DB pool health, and Oban job queue health in Prometheus after adding Parapet to their Phoenix app
**Depends on**: Phase 1
**Requirements**: HTTP-01, HTTP-02, HTTP-03, HTTP-04, HTTP-05, HTTP-06, OBAN-01, OBAN-02, OBAN-03, OBAN-04, ECTO-01, ECTO-02, ECTO-03, ERR-02
**Success Criteria** (what must be TRUE):
  1. After adding `Parapet.Plug.Metrics` to the Phoenix Endpoint, `parapet_http_requests_total` and `parapet_http_request_duration_ms` appear in `/metrics` with route-pattern labels — never raw paths
  2. Requests to unknown routes (404s from unmatched paths) appear in metrics as `route: "_unknown"` — the raw path never leaks into a Prometheus label
  3. `parapet_ecto_queue_time_ms` and `parapet_ecto_query_time_ms` appear as separate histograms, allowing operators to distinguish pool saturation from slow queries
  4. When `:oban` is present, `parapet_oban_jobs_total` metrics appear per worker and queue; when `:oban` is absent, the application compiles and starts without errors or warnings
  5. A duplicate metric registration (two modules claiming the same metric name) is reported at application start with a clear error — the app does not silently start with a partial metric set
**Plans**: TBD

### Phase 3: SLO DSL, Login Journey, and Deploy Markers
**Goal**: An adopter can express a service-level objective in code, have it compile to correct Prometheus alerting rules, and correlate incidents with deploy events — making Parapet fundamentally different from "just use PromEx"
**Depends on**: Phase 2
**Requirements**: SLO-01, SLO-02, SLO-03, SLO-04, SLO-05, AUTH-01, AUTH-02, AUTH-03, AUTH-04, DEPL-01, DEPL-02, DEPL-03, DEPL-04, DOCS-03
**Success Criteria** (what must be TRUE):
  1. An SLO defined via `Parapet.SLO.define/2` produces multi-window burn-rate recording and alerting rules (fast-burn and slow-burn) that pass `promtool check rules` without errors
  2. Generated PromQL uses `sum(rate(good[w])) / sum(rate(total[w]))` — verifiable via snapshot test — and never uses `rate(sum(...))`
  3. When `:sigra` is present, `parapet.journey.login` telemetry events are emitted per auth attempt with `:outcome` of `:success` or `:failure`; when `:sigra` is absent, the app compiles and starts with no warnings
  4. `mix parapet.doctor` exits with code 2 when any SLO definition is missing a `runbook:` field
  5. `Parapet.Deploy.mark/1` records a deploy event with a monotonic sequence number that Grafana can render as a vertical annotation on SLO time-series panels
**Plans**: TBD

### Phase 4: Artifact Generation, Doctor, and Launch Readiness
**Goal**: An adopter can generate importable Grafana dashboards and valid Prometheus rule files, run a CI safety gate that catches footguns, and follow a day-1 guide from zero to their first alert firing
**Depends on**: Phase 3
**Requirements**: PROM-01, PROM-02, PROM-03, PROM-04, GRAF-01, GRAF-02, GRAF-03, GRAF-04, DOCT-01, DOCT-02, DOCT-03, DOCT-04, DOCT-05, DOCS-01
**Success Criteria** (what must be TRUE):
  1. `mix parapet.gen.prometheus` writes Prometheus YAML to `priv/parapet/prometheus/` and the output passes `promtool check rules` without errors
  2. `mix parapet.gen.grafana` writes importable Grafana dashboard JSON and provisioning YAML covering HTTP, Oban, login SLO, error budget, and deploy marker panels — no manual copy-paste required
  3. `mix parapet.doctor` exits with code 0 (all clear), 1 (warnings), or 2 (safety violation), runs in under 5 seconds, and is usable as a CI gate
  4. `mix parapet.doctor --ci` suppresses color and emits structured JSON to stdout that a CI system can parse programmatically
  5. The README covers the complete path from `mix.exs` dependency through first Grafana panel showing live data, with no gaps requiring source code reading
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Telemetry Foundation & Safety Rails | 3/5 | Executing | - |
| 2. HTTP, Ecto, and Oban Metrics | 0/TBD | Not started | - |
| 3. SLO DSL, Login Journey, and Deploy Markers | 0/TBD | Not started | - |
| 4. Artifact Generation, Doctor, and Launch Readiness | 0/TBD | Not started | - |
