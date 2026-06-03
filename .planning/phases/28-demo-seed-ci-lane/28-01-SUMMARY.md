---
phase: 28-demo-seed-ci-lane
plan: "01"
subsystem: demo
tags: [elixir, parapet, recovery, runbook, capability, demo-app]

requires:
  - phase: 27-prebuilt-playbooks
    provides: "stalled_executor.ex.eex template and :retry_async_item in the capability allowlist"
  - phase: 24-recovery-behaviour-capability-allowlist
    provides: "Parapet.Recovery behaviour + attach/1 + Parapet.Capabilities agent"

provides:
  - "DemoApp.Runbooks.StalledExecutor — compiled use Parapet.Runbook module with 3-step shape"
  - "DemoApp.Recovery.RetryAsyncItem — compiled use Parapet.Recovery module with all 4 callbacks"

affects:
  - 28-02 (boot wiring — application.ex adds Parapet.Capabilities + attach call)
  - 28-03 (seed — uses DemoApp.Runbooks.StalledExecutor module string)
  - 28-04 (CI scenarios — headless tests resolve runbook via extract_module/1 and execute RetryAsyncItem)
  - 28-05 (mix demo.reset — seeds reference compiled modules)

tech-stack:
  added: []
  patterns:
    - "use Parapet.Recovery with @impl annotations on all 4 callbacks"
    - "5-field preview map (count, target_refs, preconditions, warnings, summary) as required by compute_preview/3"
    - "execute/2 uses DemoApp.Repo.update_all directly (demo-only code; sandbox shared mode propagates)"
    - "Runbook module is a near-copy of priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex with module prefix resolved"

key-files:
  created:
    - examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex
    - examples/demo_app/lib/demo_app/recovery/retry_async_item.ex
  modified: []

key-decisions:
  - "Reuse frozen-allowlist atom :retry_async_item (D-02) — non-allowlisted id raises ArgumentError at attach/1"
  - "DemoApp.Repo used directly in execute/2 (not Application.get_env indirection) — simpler demo code; sandbox shared mode covers it"
  - "Step id is :retry_item (not renamed) — all four downstream CI scenarios pass 'retry_item' as step_id string"

patterns-established:
  - "Pattern: recovery capability module = use Parapet.Recovery + @impl on each of 4 callbacks + DemoApp.Repo for demo DB mutations"
  - "Pattern: runbook module = near-copy of .eex template with module prefix substituted"

requirements-completed: [DEMO-05]

duration: 8min
completed: 2026-05-28
---

# Phase 28 Plan 01: Demo Runbook + Recovery Capability Modules Summary

**Two compiled demo modules wiring :retry_async_item capability to a 3-step StalledExecutor runbook — the load-bearing prerequisites for boot registration (Plan 02) and CI scenarios (Plan 04)**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-28T19:00:00Z
- **Completed:** 2026-05-28T19:08:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `DemoApp.Runbooks.StalledExecutor` authored as a near-copy of `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` with the only EEx substitution (`@module_prefix`) resolved to `DemoApp.Runbooks`; mitigate step declares `capability: :retry_async_item, target_kind: :async_item, requires_preview: true`
- `DemoApp.Recovery.RetryAsyncItem` authored with all 4 `@impl Parapet.Recovery` callbacks; `id/0` returns the frozen-allowlist atom `:retry_async_item`; `preview/2` returns the required 5-field map; `execute/2` mutates a `Parapet.Spine.ActionItem` row via `DemoApp.Repo.update_all`
- Both modules compile cleanly under `MIX_ENV=test mix compile --warnings-as-errors` (exit 0)

## Task Commits

1. **Task 1: Author DemoApp.Runbooks.StalledExecutor** - `21c5f9f` (feat)
2. **Task 2: Author DemoApp.Recovery.RetryAsyncItem capability** - `471b0b6` (feat)

## Files Created/Modified

- `examples/demo_app/lib/demo_app/runbooks/stalled_executor.ex` — `use Parapet.Runbook`; 3-step runbook (investigate_logs guidance, retry_item capability mitigate, verify_recovery guidance)
- `examples/demo_app/lib/demo_app/recovery/retry_async_item.ex` — `use Parapet.Recovery`; 4 callbacks; execute/2 flips ActionItem state from "open" to "retrying"

## Decisions Made

- Used `DemoApp.Repo` directly in `execute/2` rather than `Application.get_env(:parapet, :repo)` indirection — simpler for demo-only code; ExUnit sandbox shared mode propagates to callers of `DemoApp.Repo` within the test process span (confirmed by RESEARCH.md)
- Pre-existing `Phoenix.LiveReloader` undefined-module warnings in the demo app's `dev`-mode endpoint are not new and do not appear under `MIX_ENV=test` (the CI environment). The plan's `mix compile --warnings-as-errors` acceptance criterion passes with `MIX_ENV=test`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Pre-existing `Phoenix.LiveReloader` and `Parapet.Escalation.Worker` undefined-module warnings exist in `MIX_ENV=dev` but are absent under `MIX_ENV=test` (the CI-matching environment). No new warnings introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `DemoApp.Runbooks.StalledExecutor` is compiled — `extract_module/1` can resolve `"Elixir.DemoApp.Runbooks.StalledExecutor"` via `String.to_existing_atom/1`
- `DemoApp.Recovery.RetryAsyncItem` is compiled — `Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` in Plan 02 (boot wiring) will register `:retry_async_item` into `Parapet.Capabilities`
- Both modules are the prerequisites for Plan 02 (application.ex boot wiring), Plan 03 (seeds), and Plan 04 (CI scenarios)

---
*Phase: 28-demo-seed-ci-lane*
*Completed: 2026-05-28*
