# Project Retrospective

## Cross-Milestone Trends

| Milestone | Ph / Pl | Days | LOC | Velocity |
|-----------|---------|------|-----|----------|
| v0.1 | 4 / 15 | 2 | 1992 | 15 plans / 2 days |
| v0.2 | 3 / 11 | 1 | 3164 | 11 plans / 1 day |
| v0.3 | 4 / 12 | 1 | 6667 | 12 plans / 1 day |
| v0.4 | 4 / 9 | 3 | 7847 | 9 plans / 3 days |
| v0.7 | 4 / 12 | 1 | 13401 | 12 plans / 1 day |

## Milestone: v0.7 — Async & Delivery Reliability

**Shipped:** 2026-05-18
**Phases:** 4 | **Plans:** 12

### What Was Built
Implemented out-of-the-box SLIs for async pipeline health and provider delivery states (Chimeway, Mailglass, Rindle), added explicit fault-domain triage enrichment leveraging durable evidence, and introduced safe, host-wired recovery runbook templates for stalled async work.

### What Worked
- **Provider-First SLOs:** Extending the metrics layer to directly model provider states (like MailglassDelivery or RindleAsync) simplified creating actionable SLIs.
- **Evidence-Backed Triage:** Shifting triage classification from UI heuristics down to durable Ecto snapshot evidence ensures accuracy.

### What Was Inefficient
- Integrating across varying third-party service semantics required careful modeling of states to ensure low cardinality without losing fidelity.

### Patterns Established
- **Bounded SliceSpec Seam:** Providing a narrow surface to define provider-specific delivery slices.
- **Host-Owned Modules:** Utilizing generators to copy fixed template runbooks rather than inventing dynamic workflow DSLs.

### Key Lessons
- Providing exact recovery guidance requires distinguishing webhook/callback drift from internal queue backlogs or provider outages.

## Milestone: v0.4 — Scoria AI Integration

**Shipped:** 2026-05-15
**Phases:** 4 | **Plans:** 9

### What Was Built
Implemented AI telemetry translation, eval-driven SLOs, deploy correlation for AI configs, and workflow approval pauses as durable HITL states.

### What Worked
- **Strict Cardinality Control:** The `Parapet.Metrics.Scoria` translation layer successfully protected the TSDB from high-cardinality AI refs.
- **Data-First Providers:** Moving the SLO registry to a `Provider` behaviour enabled compile-time validation.

### What Was Inefficient
- Minimal friction encountered; test-driven approach ensured smooth implementation.

### Patterns Established
- **Dual-Track Telemetry:** Using Prometheus for systemic alerting and Ecto for 100% reliable deep links for workflow pauses.
- **Telemetry for UX, Adapter for Truth:** Using adapter polling as a cache-invalidation hint to prevent state drift.

### Key Lessons
- Alerting on low-volume AI endpoints requires multi-burn-rate PromQL to avoid false positives.
- Decoupling UI URLs from the routing layer via configurable MFA keeps the library pure.

## Milestone: v0.3 — Runbooks & Alert Routing

**Shipped:** 2026-05-12
**Phases:** 4 | **Plans:** 12

### What Was Built
Implemented webhook receiver for Prometheus Alertmanager, structured Runbook DSL, and modular Notifier system for Slack/Teams.

### What Worked
- Leveraging existing Ecto `Incident` schema for Alertmanager correlation simplified the state machine.

### What Was Inefficient
- Parsing external JSON payloads reliably required strict schema validation.

### Patterns Established
- One-click mitigations securely audited via the `ToolAudit` Ecto schema.

### Key Lessons
- Operator UI requires interactive state to display attached runbooks efficiently.

## Milestone: v0.2 — Durable Spine and Operator UI

**Shipped:** 2026-05-11
**Phases:** 3 | **Plans:** 11

### What Was Built
Established the durable Ecto spine (Incidents, Timeline, Tool Audits), generated an isolated Phoenix LiveView Operator SRE workbench, and integrated sibling libraries like Sigra, Rulestead, and Mailglass via optional capability adapters.

### What Worked
- **Decoupled Persistence:** Using `Application.get_env` for dynamic repo lookup enabled seamless host integration without coupling Parapet to a specific DB.
- **Static UI Verification:** Moving UI layout checks from manual human tasks to automated static Tailwind class assertions drastically improved cycle time.
- **Compile-time Adapters:** Utilizing `Code.ensure_loaded?` allowed us to add 6 sibling integrations without adding a single runtime dependency.

### What Was Inefficient
- **Test Context Leaks:** Had to manually intervene during telemetry testing because of leftover global state/crashes in `ThreadlineTest`.

### Patterns Established
- Generating LiveView templates into the host application rather than shipping them as pre-compiled modules to maintain host ownership.
- Validating visual contracts (like 3-pane layouts) via string matching in tests to avoid the weight of E2E browser automation.

### Key Lessons
- Ecto schemas can be successfully tested purely on their changesets without needing a Repo, which is crucial for library distribution.
- Automated structural testing of templates is a powerful "shift-left" technique that completely eliminated manual UI verification bottlenecks.

## Milestone: v0.1 — Trustworthy Spine

**Shipped:** 2026-05-10
**Phases:** 4 | **Plans:** 15

### What Was Built
Successfully implemented the core telemetry framework, metric collectors, SLO generators, and developer experience tools (doctor checks and dashboard generation) to enable the "Zero to First Alert" workflow.

### What Worked
- **Strict safety rails out of the box:** Forcing a hardcoded label policy regex and telemetry-first approach allowed us to guarantee safety.
- **Generator vs Runtime balance:** Distributing the integration scaffolding (`Parapet.Instrumenter`) vs runtime metrics plugins provided the flexibility expected by Phoenix teams.
- **Test Driven & Clear Phasing:** Breaking the work down vertically (Foundation → Metrics → SLO → DX) made progress verifiable and predictable at every step.

### What Was Inefficient
- **Verification Setup:** Setting up manual verification for Grafana/Prometheus was complex and required human intervention. 
- **Tooling Friction:** Encountered parsing limits with AST manipulation during DX phases (specifically handling function pipes in `mix parapet.doctor`), which required fallback static analysis.

### Patterns Established
- Telemetry-first contract definition before database persistence schemas.
- Using `Igniter` for deterministic codebase modifications inside Mix tasks.
- Abstracting complex configuration (like PromQL rules) into Elixir structs evaluated into EEx templates.

### Key Lessons
- Providing explicit configuration options early isn't always the best path; rigid safety boundaries (like hardcoded label regex) build more trust in a new SRE tool.
- Verifying artifacts that live outside the runtime (e.g. Grafana dashboards and YAML rules) requires robust programmatic checks (`promtool`) but ultimately still needs human eyes.
