---
phase: 28-demo-seed-ci-lane
plan: "03"
subsystem: demo-app-wiring
tags: [capabilities, recovery, boot-wiring, supervision]
dependency_graph:
  requires: ["28-01"]
  provides: ["28-04", "28-05"]
  affects: ["examples/demo_app/lib/demo_app/application.ex"]
tech_stack:
  added: []
  patterns:
    - "Boot-time capability registration via Parapet.Recovery.attach/1 after Supervisor.start_link/2"
    - "Named singleton agent started by :parapet OTP application — no double-start needed in host app"
key_files:
  modified:
    - examples/demo_app/lib/demo_app/application.ex
decisions:
  - "Do NOT add Parapet.Capabilities to demo app children list — Parapet.Internal.Application already starts it as part of the :parapet OTP application; adding it again causes {:already_started, PID} crash on Supervisor.start_link"
  - "Call Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem]) inline after Supervisor.start_link/2 returns; the named singleton is guaranteed running at that point"
  - "Capture Supervisor.start_link/2 result as {:ok, sup} and return {:ok, sup} from start/2 so the registered capability is active before any request or test runs"
metrics:
  duration: "4 min"
  completed: "2026-05-28T19:08:09Z"
  tasks_completed: 1
  files_modified: 1
---

# Phase 28 Plan 03: Boot-time Capabilities Wiring Summary

Boot-time `Parapet.Recovery.attach/1` call in `DemoApp.Application.start/2` registers `DemoApp.Recovery.RetryAsyncItem` under the `:retry_async_item` allowlisted atom, so `Parapet.Capabilities.get_recovery(:retry_async_item)` answers for both `mix phx.server` and the CI test process.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add boot-time attach to DemoApp.Application | (see below) | examples/demo_app/lib/demo_app/application.ex |

## What Was Built

Modified `examples/demo_app/lib/demo_app/application.ex`:

- Captured `Supervisor.start_link(children, opts)` result as `{:ok, sup}` (was bare one-liner)
- Called `{:ok, _} = Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` inline after `start_link/2` returns
- Returns `{:ok, sup}` so `Application.start/2` contract is satisfied

Boot smoke test confirmed: `Parapet.Capabilities.get_recovery(:retry_async_item)` returns the full capability map with `preview: &DemoApp.Recovery.RetryAsyncItem.preview/2` and `execute: &DemoApp.Recovery.RetryAsyncItem.execute/2` captures.

## Verification

- `MIX_ENV=test mix compile --warnings-as-errors` exits 0
- `grep -c "Parapet.Recovery.attach" lib/demo_app/application.ex` returns 1
- `MIX_ENV=test mix run -e "IO.inspect(Parapet.Capabilities.get_recovery(:retry_async_item))"` prints non-nil capability map
- `Parapet.Recovery.attach` is called AFTER `Supervisor.start_link/2` (ordering requirement D-09 satisfied)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Did not add Parapet.Capabilities to demo children list**

- **Found during:** Task 1 execution — boot smoke test returned `{:error, {:shutdown, {:failed_to_start_child, Parapet.Capabilities, {:already_started, PID}}}}`
- **Issue:** The plan's action instructed adding `Parapet.Capabilities` bare to the `children` list. However, `Parapet.Internal.Application` (the `:parapet` OTP application's application module at `lib/parapet/internal/application.ex:10-14`) already starts `{Parapet.Capabilities, []}` in its own supervision tree. When the demo app also adds it, `Supervisor.start_link/2` attempts to start the named singleton a second time, which fails with `{:already_started, PID}` — causing a boot crash.
- **Fix:** Removed `Parapet.Capabilities` from the demo `children` list. The named singleton is guaranteed running (started by `:parapet` application) before `DemoApp.Application.start/2` is called, so `attach/1` can safely call `Agent.update(Parapet.Capabilities, ...)` without a pre-check.
- **Files modified:** `examples/demo_app/lib/demo_app/application.ex`
- **D-09 compliance:** The ordering invariant (Capabilities running before attach/1) is preserved — the `:parapet` OTP application starts before the demo app because it is a dependency.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- [x] `examples/demo_app/lib/demo_app/application.ex` exists and contains `Parapet.Recovery.attach`
- [x] Compile exits 0 (MIX_ENV=test)
- [x] Boot smoke resolves `:retry_async_item` capability
