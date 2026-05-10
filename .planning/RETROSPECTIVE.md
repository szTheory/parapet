# Project Retrospective

## Cross-Milestone Trends

| Milestone | Ph / Pl | Days | LOC | Velocity |
|-----------|---------|------|-----|----------|
| v0.1 | 4 / 15 | 2 | 1992 | 15 plans / 2 days |

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
