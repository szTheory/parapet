# Parapet Operator UI Guide

The Parapet Operator UI is an optional, generated LiveView workbench that sits inside your host application. Rather than offering another dashboard with raw telemetry, it provides a strictly controlled surface for initiating actionable mitigations when an SLO is burning, with an immutable audit trail for every action.

Phase 6 extends that boundary with fault-domain triage for async and delivery incidents. The workbench now treats a compact evidence-backed triage block as the current-state index and the incident chronology as the authoritative source of sequence.

## Prerequisites

- Phoenix and LiveView installed in your host app
- Parapet installed and configured (`mix parapet.install`)
- A router with an existing authenticated pipeline or `live_session`

## Installation

Run the generator from the root of your project:

```bash
mix parapet.gen.ui
```

This will scaffold three files into your `lib/my_app_web/live/parapet/` directory:
- `operator_live.ex` (The main workbench view)
- `operator_detail_live.ex` (Detailed view of specific SLOs or incidents)
- `operator_components.ex` (Reusable UI components)

### Mounting the Operator UI

The generated files belong to your application. Parapet does **not** provide its own authentication system. You must mount the operator routes inside your application's authenticated scope to ensure the UI is secured according to your app's existing authorization policies.

Update your `router.ex` to include the Parapet routes within a protected area:

```elixir
# lib/my_app_web/router.ex

scope "/admin", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :parapet_operator,
    on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}] do

    live "/parapet", Parapet.OperatorLive.Index, :index
    live "/parapet/:id", Parapet.OperatorDetailLive.Show, :show
  end
end
```

## Security and Verification

The Parapet Doctor includes a dedicated check to verify that your operator UI is securely mounted. 

Run the doctor task to ensure the UI is not exposed publicly:

```bash
mix parapet.doctor
```

If the doctor detects that `OperatorLive` or `OperatorDetailLive` are mounted outside of an authenticated scope, it will report a warning (`Unsecured operator UI LiveView found`).

## Evidence-First Design

The Parapet operator workbench adheres to strict evidence-first design principles (D-05, D-07-D-12, D-17-D-19):

1. **Grafana/Runbooks are External:** (D-05) The Parapet UI does not attempt to replace Grafana for telemetry exploration or Notion/Confluence for runbooks. It provides focused, context-aware links to these external tools rather than duplicating their functionality.
2. **First-Class Actions:** (D-07 - D-09) The UI surface is explicitly limited to initiating predefined, safe mitigation actions. It is not an arbitrary admin console.
3. **Immutable Factual Timelines:** (D-10 - D-12) Any events or incidents viewed within the UI reflect immutable facts stored in the evidence spine. The UI reads these facts but cannot alter history.
4. **Required Audit Context:** (D-17 - D-19) Every mutating action triggered from the workbench automatically captures audit context, including the actor's identity and the rationale. This ensures every operational change leaves a durable, queryable trace.

## Phase 6 Triage Contract

For async and delivery incidents, the generated detail view should render:

1. A compact triage block derived from durable evidence only.
2. The normalized chronology immediately underneath it.
3. External links outward to provider consoles, Grafana, and runbooks.
4. Exact action items only when one concrete object needs manual follow-up.

The triage block is sourced from the incident summary in `runbook_data["triage"]` and the latest `triage_snapshot` timeline entry. It should answer:

- Observed symptom
- Likely fault plane
- Why we think that, using 2-4 bounded evidence facts
- Safe next step

The detail page should not infer fault planes by parsing titles, should not treat `runbook_data` as a hidden timeline, and should not attempt provider-console-style forensics.

## Exact Follow-Up Only

`ActionItem`s remain a narrow exact-object seam. They are appropriate when one concrete async or delivery object needs operator attention, such as a suppressed delivery, dead-lettered job, stale workflow, or orphaned callback. They are not generic investigation todos, ownership queues, or SLA-tracked incident tasks.

## Phase 7 Preview-First Recovery

Phase 7 introduces a formal recovery model built on top of the Phase 6 triage foundation. The workbench moves from evidence display to guided recovery, while maintaining strict safety boundaries.

### Safe Recovery Principles

The operator workbench adheres to these recovery principles (D-20, D-21):

1. **Chronology First:** Investigation always starts with the chronological evidence. Recovery actions are only considered after the operator has reviewed the triage facts and timeline.
2. **Preview Before Mutation:** Destructive or mutating recovery actions (e.g., retrying jobs, clearing suppressions) must be previewed. The UI renders the exact scope of the change, warnings, and idempotency caveats before asking for confirmation.
3. **Bounded Recovery:** Recovery is not a broad admin console. It is limited to the specific capabilities and runbook steps defined for the burning SLO.
4. **Exact-Item Preference:** Scoped recovery targeting specific `ActionItem`s (exact-item recovery) is preferred over bulk replays or opaque automation.

### Recovery Flow

The generated UI implements a three-state recovery flow for runbook steps:

- **Guidance:** For steps that are purely informational or not yet wired to a host capability. These render with guidance text and no action button.
- **Preview:** For executable steps, the operator first clicks "Preview". This triggers a call to the host capability to calculate the effect of the recovery (e.g., "This will retry 42 suppressed deliveries").
- **Confirm:** After reviewing the preview, warnings, and target scope, the operator confirms the action. This execution is recorded in the immutable timeline with a unique idempotency key.

### Named Capabilities

Recovery actions are backed by named host capabilities. These capabilities are responsible for:
- Validating preconditions.
- Generating a time-bounded preview.
- Executing the mutation idempotently.
- Reporting success or failure back to the evidence spine.

By naming and bounding these capabilities, the host application maintains control over what the operator can do, ensuring the workbench remains a safe environment for high-stakes incident response.

