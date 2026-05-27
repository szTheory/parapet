---
thread: actionable-recovery-design
opened: "2026-05-27"
target_milestone: v1.1
status: open
links:
  - .planning/NEXT-STEP-ASSESSMENT.md
  - docs/operator-ui.md
  - prompts/parapet-engineering-dna-from-sibling-libs.md
  - lib/parapet/operator/action_payload.ex
  - lib/parapet/operator/workbench_contract.ex
  - lib/parapet/runbook
---

# Thread: Actionable Recovery Design (v1.1)

## What we're investigating

How to close the gap where parapet's operator UI sells "actionable mitigations" but actually hands action off to other tools. The Phase 7 Preview → Confirm flow is documented in `docs/operator-ui.md` as design but was never shipped in v1.0. JTBD-MAP names "common recovery depth" as the Very-High-priority gap. v1.1 should wire the action loop end-to-end without crossing into autonomous remediation.

## Specific open questions

### 1. Capability-registration API shape

How does a host application declare named recovery actions that parapet can dispatch from the operator UI?

- **Shape candidate A** — Behaviour module: `defmodule MyApp.Recovery do; use Parapet.Recovery; def retry_dlq(args), do: ...; end` with compile-time registration.
- **Shape candidate B** — Runtime registry: `Parapet.Recovery.register(:retry_dlq, &MyApp.RetryDLQ.run/1, schema: ...)` from `application/0` callback.
- **Tradeoff:** A is compile-time-safe and dialyzer-friendly; B is more flexible for multi-tenant scoping (if it ever happens — explicitly out of scope for v1.1).
- **Lean:** A. Matches `Parapet.Integration` behaviour pattern already used for adapters. Idiomatic for this lib.

### 2. Preview/Confirm UX (operator LiveView)

What does "Preview" actually render?

- Action name + human-readable description (from `@moduledoc` or behaviour `c:label/0`)
- Parameters the action will use (resolved from incident context — e.g., the queue name from a `stalled_async` incident)
- The expected diff or side-effect description (e.g., "Will re-enqueue 47 jobs from `default` queue. No data destruction.")
- "Confirm" button only enabled after Preview renders without error.

Must not auto-execute. Must require explicit Confirm. Audit log row created on both Preview-shown and Confirm-clicked.

### 3. Prebuilt recovery playbooks (target: 4–6)

Picked from JTBD-MAP's named failure modes:

- **Retry storm** — back off + clear in-flight retry intent.
- **Suppression drift** — clear suppression for confirmed-bouncing recipient class (with safety cap).
- **Stalled async** — re-enqueue stuck jobs past their lease.
- **Dead-letter drain** — promote DLQ batches back to active queue.
- **Deploy-tied incident** — revert feature flag changes correlated to the deploy marker.
- **Cardinality blowout** — toggle the offending label off and surface the analyzer report.

Each must be safe-by-default (idempotent or bounded), and each must be testable in the demo app's seeded incident set.

### 4. Audit propagation

Every recovery action must:
- Emit a `TimelineEntry` of type `:recovery_action` linked to the incident.
- Emit a `ToolAudit` row capturing the executing operator's identity, the action name, the resolved args, the outcome, and timestamps.
- Wrap inside `Parapet.Operator.ActionPayload` so the existing circuit breaker + claim service multi-node safety applies for free.

### 5. Demo-seed gap

Fresh `iex -S mix phx.server` in `examples/demo_app/` currently shows an empty incident queue. v1.1 must include at least one seeded incident where the runbook has a Preview-able + Confirm-able action wired. This is the smoke test for the wedge.

## Research already done — do not re-derive

- `prompts/parapet-engineering-dna-from-sibling-libs.md` — DNA: host-owned beats remote magic; operator workflows are real product scope.
- `prompts/sre-best-practices-solo-founder-deep-research.md` — operator-in-the-loop is the right safety posture for solo/small-team SaaS.
- `docs/operator-ui.md` — Phase 7 design draft for Preview/Confirm flow.
- `prompts/V1-SLO-WIZARD-BUNDLES.md` — flag-based Igniter task wins; same idiom guidance applies to any v1.1 generator (e.g., `mix parapet.gen.recovery`).

## Out of scope for v1.1

- Autonomous (no-human) execution.
- Cross-app or multi-tenant action scoping.
- Action approval workflows (multi-step approval chains).
- Custom action UIs beyond Guidance → Preview → Confirm.

## Next concrete step

When the user opens v1.1, this thread should be the seed for `gsd-discuss-phase` or `gsd-plan-phase`. Don't auto-open; wait for the user's signal.
