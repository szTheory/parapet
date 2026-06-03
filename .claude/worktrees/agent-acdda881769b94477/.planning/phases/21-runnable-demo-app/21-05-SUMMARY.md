---
phase: 21-runnable-demo-app
plan: 05
subsystem: demo
tags: [phoenix, liveview, esbuild, demo-app, parapet, gap-closure]

# Dependency graph
requires:
  - "21-04 (verification report identifying CR-01 and CR-02)"
provides:
  - "Resolved-history queue rows projected through Parapet.Operator.WorkbenchContract.queue_row/1"
  - "LiveView JavaScript entrypoint at examples/demo_app/assets/js/app.js"
  - "esbuild dependency and asset aliases in examples/demo_app/mix.exs"
  - "config :esbuild profile in examples/demo_app/config/config.exs"
  - "CSRF meta tag and deferred /assets/app.js script in DemoAppWeb.Layouts"
affects:
  - "21-06 (branch-protection gate remains the final external verification step)"

key-files:
  created:
    - "examples/demo_app/assets/js/app.js"
  modified:
    - "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
    - "examples/demo_app/mix.exs"
    - "examples/demo_app/config/config.exs"
    - "examples/demo_app/lib/demo_app_web/components/layouts.ex"

requirements-completed: [DEMO-01, DEMO-02]

# Metrics
completed: 2026-05-25
---

# Phase 21 Plan 05: Verification Gap Closure Summary

Closed the two code-level gaps from `21-VERIFICATION.md`.

## What Changed

- `operator_live.ex` now aliases `Parapet.Operator.WorkbenchContract` and maps resolved `%Parapet.Spine.Incident{}` structs through `queue_row/1` before `queue_stream_item/1`, which removes the `:incident_id` KeyError on the History tab.
- `examples/demo_app/assets/js/app.js` now boots a standard Phoenix LiveView `LiveSocket` using the CSRF token from a `<meta name="csrf-token">` tag.
- `mix.exs` now includes `:esbuild` and runs `esbuild demo_app` in both `assets.build` and `assets.deploy`.
- `config/config.exs` now defines the `config :esbuild, demo_app: [...]` profile that bundles `assets/js/app.js` into `priv/static/assets`.
- `layouts.ex` now emits the CSRF meta tag and loads `/assets/app.js` at the end of `<body>`.

## Verification

- Confirmed by inspection that `resolved_history_page/1` now uses `WorkbenchContract.queue_row/1` while cursor helpers still operate on raw incident structs.
- Confirmed by inspection that `app.js`, esbuild wiring, CSRF meta tag, and script tag all match the plan requirements.
- Local `mix compile` / `mix assets.build` verification could not be completed in this environment because `mix deps.get` stalled while fetching the `heroicons` git dependency from GitHub.

## Notes

- These plan edits were already present in the working tree when execution resumed; this summary records and validates them rather than re-applying the same changes.
