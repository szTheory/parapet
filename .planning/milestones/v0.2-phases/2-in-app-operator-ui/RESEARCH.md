<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Phoenix LiveView SRE dashboard for incidents and timelines | Generate a host-owned incident workbench mounted in the adopter's Phoenix app, backed by library data/query helpers. |
| UI-02 | Secure UI surface for safe audited mutations | Route all mutating actions through a public operator boundary that records state change, timeline entry, and audit semantics together. |
| UI-03 | External visualization links instead of rebuilt charting | Keep Grafana/runbook links in the UI and avoid embedded time-series ownership. |
| UI-04 | Generators and docs that secure the UI behind host auth | Ship an Igniter-based `mix parapet.gen.ui` task plus `mix parapet.doctor` checks for authenticated router/live_session mounting. |
</phase_requirements>

# Phase 2: In-App Operator UI (LiveView) - Research

**Researched:** 2026-05-11
**Domain:** Phoenix LiveView library integration, host-owned scaffolding, operator-grade incident workflows
**Confidence:** HIGH

## Summary

Phase 2 should ship as a hybrid library-plus-generator surface, not as a packaged admin app. The library owns reusable domain/query/action code and generated function components where useful, while the host app owns router mount, `pipe_through`, `live_session`, authorization, and the final LiveView modules. That matches Parapet's existing generator-first posture and avoids taking on tenancy or authentication responsibility inside the library.

The existing codebase already has the durable evidence spine (`Parapet.Evidence`, incident/timeline/tool-audit schemas) but does not yet have Phoenix or Phoenix LiveView dependencies. The safest path is to keep Phoenix-facing code optional and generated into the host application, while adding only the minimum library seams needed to list incidents, fetch incident detail, and execute audited operator actions. The UI must stay evidence-first: one-screen summary, append-only timeline for facts, and explicit approval-gated mutations.

**Primary recommendation:** split the phase into four executable chunks: operator domain/API boundary, UI generator/templates, doctor/docs/auth verification, and end-to-end host-facing tests/docs polish.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Incident listing/detail queries | Library API | Generated LiveView | Data access and audit semantics should stay versioned in Parapet rather than copied into each host. |
| Incident workbench UI | Generated host code | Library components/helpers | Host owns auth/router/session seams and can customize the resulting LiveViews. |
| Mutating operator actions | Library API | Generated host forms | Audit and transaction semantics must stay centralized. |
| Grafana/runbook/deep links | Generated host code | Library helpers | The host knows its final URLs and environment-specific destinations. |
| UI auth verification | Doctor task | Generator output | Security must be statically checkable in CI and visible in generated guidance. |

## Recommended Implementation Shape

### 1. Library boundary first

Introduce a new public boundary module, likely `Parapet.Operator`, analogous to `Parapet.Evidence`.

Responsibilities:
- list incidents for queue/index views
- fetch an incident with recent timeline and related tool audits
- expose small audited commands such as `mark_investigating/2`, `resolve_incident/2`, `record_note/2`, `request_approval/2`, `approve_recommendation/2`, `reject_recommendation/2`
- centralize actor/reason/correlation/idempotency validation

Why first:
- LiveView code should not talk directly to schemas or raw `Repo` writes
- UI-02 depends on durable audited mutation semantics more than on visual structure
- this boundary can be tested without Phoenix

### 2. Generated host-owned LiveView surface

Ship `mix parapet.gen.ui` as an Igniter task that generates:
- `lib/<host>_web/live/parapet/operator_live.ex`
- `lib/<host>_web/live/parapet/operator_components.ex`
- optional `lib/<host>_web/live/parapet/operator_detail_live.ex` or route split for mobile/index-detail
- router patch or route snippet for authenticated mounting

Generator rules:
- prefer idempotent AST/router edits
- never create or own auth plugs
- either insert into an already-authenticated scope or emit an explicit manual step if a safe mount point cannot be inferred
- keep templates readable and host-editable

### 3. Optional Phoenix / LiveView posture

Do not force core Parapet adoption to pull Phoenix UI dependencies unless the host opts into the operator UI path.

Practical posture:
- keep pure domain modules Phoenix-free
- isolate any Phoenix component helpers into clearly separate modules
- if library modules must compile against Phoenix, gate them behind optional dependencies and keep the generator the main delivery mechanism
- avoid making the package unusable in non-Phoenix or telemetry-only contexts

The repo already uses `Code.ensure_loaded?` for optional integrations. The same mindset should apply here even if the exact compile strategy differs from sibling-library adapters.

### 4. Keep Grafana external

The UI should render concise evidence and external links only:
- severity/state/impact/change marker
- top facts and recent timeline
- next safe action
- runbook/Grafana links

Do not rebuild dashboards, charts, or long operational procedures inside LiveView. That would dilute UI-03 and create a second observability surface Parapet cannot maintain well.

## Data And Action Model Recommendations

### Incident queue

Default queue behavior should follow the UI spec:
- open and investigating first, sorted by newest evidence timestamp
- resolved second, sorted by resolved timestamp
- explicit approval-needed indicator in the row

### Incident detail

Load a single summary payload that includes:
- incident metadata
- top facts
- latest hypotheses or recommendation summary
- recent timeline rows
- available actions and approval state
- external links

This avoids tab-driven hunting and keeps the workbench calm.

### Mutation semantics

Every mutating action should require a structured payload with:
- actor
- reason
- correlation_id
- optional idempotency_key

Each mutation should be implemented as one operator-level command that guarantees the related incident update, timeline append, and tool-audit write happen together where applicable. Even if the current `Parapet.Evidence` functions are simple inserts, the operator boundary should be designed for transactional semantics so the UI contract is trustworthy.

## Security And Generator Guidance

### Host-owned auth boundary

The host must own:
- route path
- `scope`
- `pipe_through`
- `live_session`
- authorization policy

Parapet should provide guidance and verification, not a hidden auth mechanism.

### Doctor extension

Extend `mix parapet.doctor` with an `operator_ui` check that:
- scans `lib/<app>_web/router.ex`
- finds Parapet LiveView mounts or generated route markers
- verifies they sit inside an authenticated pipeline or equivalent protected scope
- emits warnings in human mode and CI-readable output in `--ci` mode

This is the closest analog to the existing router/endpoint checks and directly satisfies UI-04.

## Risks And Tradeoffs

### Risk 1: Library-level Phoenix coupling

If Phase 2 adds hard Phoenix/Phoenix LiveView deps to the core package without careful isolation, Parapet becomes heavier for adopters who only want telemetry/evidence.

Mitigation:
- keep domain/query/action code Phoenix-free
- prefer generated host UI modules over packaged runtime UI ownership
- isolate any optional component helpers

### Risk 2: Over-generic action runner

A generic "run any mitigation" framework is tempting but conflicts with the locked decision to ship a small first-class set of safe actions.

Mitigation:
- start with explicit commands for note/state/approval/change-marker flows
- keep any shared envelope internal

### Risk 3: Security theater in generated routes

Auto-mounting a LiveView without verifying auth boundaries would undermine the whole operator-surface thesis.

Mitigation:
- require authenticated scope placement
- make doctor catch insecure mounts
- document manual review steps in the generator output

### Risk 4: UI work before operator API

Building LiveView templates first would push domain decisions into presentation code and create brittle tests.

Mitigation:
- sequence plans so operator boundary and audited commands land before the full generated UI surface

## Suggested Plan Split

### Plan 01: Operator Boundary And Audited Commands
- Add `Parapet.Operator` query and mutation surface
- Introduce validation for actor/reason/correlation payloads
- Add tests for queue/detail retrieval and audited command semantics

### Plan 02: UI Generator And Host-Owned LiveView Templates
- Add `mix parapet.gen.ui`
- Generate incident workbench LiveViews/components and router guidance
- Add generator tests for created files and idempotent behavior

### Plan 03: Doctor, Security Verification, And Docs
- Extend `mix parapet.doctor` for operator UI auth checks
- Add docs for secure mounting and generated customization points
- Update README and operator-specific docs

### Plan 04: Integration And Host-Facing Verification
- Add end-to-end style tests for generator + doctor expectations
- Ensure the generated surface matches UI-spec state/copy/security constraints
- Close any optional-dependency or compile-out gaps discovered in prior plans

## Validation Architecture

| Requirement | Behavior | Test Type | Suggested Command |
|-------------|----------|-----------|-------------------|
| UI-01 | Incident queue/detail data is exposed through a stable operator boundary | unit | `mix test test/parapet/operator_test.exs` |
| UI-02 | Mutating actions require actor/reason/correlation and produce durable evidence/audit writes | unit | `mix test test/parapet/operator_test.exs` |
| UI-03 | Generated UI emphasizes links and evidence rather than embedded charts | generator/docs | `mix test test/mix/tasks/parapet.gen.ui_test.exs` |
| UI-04 | Generator produces host-owned secure mount guidance and doctor flags insecure mounts | integration | `mix test test/mix/tasks/parapet.doctor_test.exs test/mix/tasks/parapet.gen.ui_test.exs` |

### Expected New Test Surfaces

- `test/parapet/operator_test.exs`
- `test/mix/tasks/parapet.gen.ui_test.exs`
- additions to `test/mix/tasks/parapet.doctor_test.exs`

## Anti-Patterns To Avoid

- Shipping a hidden admin shell mounted entirely from the library
- Requiring Parapet-specific auth instead of integrating with the host's auth
- Embedding Grafana charts or rebuilding LiveDashboard-like views
- Letting LiveView modules write directly to schemas or `Repo`
- Treating tool audit payloads as raw debug dumps in the main operator scan

## RESEARCH COMPLETE
