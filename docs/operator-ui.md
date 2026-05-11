# Parapet Operator UI Guide

The Parapet Operator UI is an optional, generated LiveView workbench that sits inside your host application. Rather than offering another dashboard with raw telemetry, it provides a strictly controlled surface for initiating actionable mitigations when an SLO is burning, with an immutable audit trail for every action.

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
