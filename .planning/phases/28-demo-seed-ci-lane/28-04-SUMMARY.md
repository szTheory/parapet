---
phase: 28-demo-seed-ci-lane
plan: "04"
subsystem: demo-seed
tags: [seed, runbook, capability, demo]
dependency_graph:
  requires: ["28-01"]
  provides: ["capability-backed seeded incident with runbook_data[module]"]
  affects: ["examples/demo_app/priv/repo/seeds.exs"]
tech_stack:
  added: []
  patterns: ["runbook_data[\"module\"] => to_string(Module) for Preview/Confirm resolution"]
key_files:
  created: []
  modified:
    - examples/demo_app/priv/repo/seeds.exs
decisions:
  - "D-03: runbook_data[\"module\"] string key is the only load-bearing mechanism for Preview/Confirm; inline \"steps\" is display-only and breaks confirm_runbook_step/4 with {:error, :missing_runbook}"
  - "D-11: 4th incident added as new block alongside existing 3 (not replacing); always-insert; replayability via mix demo.reset (drop+recreate)"
metrics:
  duration: "34s"
  completed: "2026-05-28"
  tasks_completed: 1
  files_modified: 1
---

# Phase 28 Plan 04: Capability-Backed Incident Seed Block Summary

**One-liner:** Added 4th open incident to seeds.exs with `runbook_data["module"] => to_string(DemoApp.Runbooks.StalledExecutor)` enabling Preview/Confirm in the demo app.

## What Was Built

A single new incident seed block (Incident 4) in `examples/demo_app/priv/repo/seeds.exs`:

- `state: "open"`, `correlation_key: "stalled-async-executor"`, `title: "Stalled async executor"`
- `runbook_data: %{"module" => to_string(DemoApp.Runbooks.StalledExecutor)}` — the load-bearing `"module"` string key required by `extract_module/1` (`operator.ex:1097-1113`) for `preview_runbook_step/3` and `confirm_runbook_step/4` to resolve the runbook module
- One `append_timeline/2` note ("Job ID 8821 last heartbeat at 09:14 UTC — executor did not report completion") for narrative context
- Updated trailing `IO.puts` count line from "3 incidents (open/investigating/resolved), 6 timeline entries" to "4 incidents (open x2/investigating/resolved), 7 timeline entries, 1 tool audit"

## Tasks

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Add the capability-backed incident seed block | 00695cd | examples/demo_app/priv/repo/seeds.exs |

## Verification

`mix demo.reset` (drop → create → migrate → seed) ran successfully. The inserted row confirmed:

```
INSERT INTO "parapet_incidents" ... runbook_data => %{"module" => "Elixir.DemoApp.Runbooks.StalledExecutor"}
Seeds complete: 4 incidents (open x2/investigating/resolved), 7 timeline entries, 1 tool audit
```

Exit code 0. No unique-constraint crash. No `{:error, :missing_runbook}` risk.

## Acceptance Criteria

- [x] `examples/demo_app/priv/repo/seeds.exs` contains `"module" => to_string(DemoApp.Runbooks.StalledExecutor)` inside a `create_incident` call with `state: "open"`
- [x] The new incident block does NOT use an inline `"steps"` list (`"steps"` key appears 0 times in the new block; 1 occurrence total in file, in existing Incident 1)
- [x] The existing 3 incident blocks are unchanged
- [x] The trailing `IO.puts` count line reflects 4 incidents
- [x] `mix demo.reset` exits 0 (seed inserts without error)

## Deviations from Plan

None — plan executed exactly as written. The 4th incident block and updated count line match the spec in 28-PATTERNS.md lines 487-513 exactly.

## Known Stubs

None. The `"module"` key is wired to a compiled module (`DemoApp.Runbooks.StalledExecutor`, authored in Plan 28-01). No placeholder values.

## Threat Flags

None. This plan adds a static seed row to the local demo DB. No new trust boundary, no HTTP endpoint, no auth surface. T-28-04-01 (runbook_data["module"] resolution via `String.to_existing_atom/1`) is mitigated by the fact that only already-loaded module atoms resolve — the demo seed references a module compiled into the app.

## Self-Check: PASSED

- [x] `examples/demo_app/priv/repo/seeds.exs` exists and contains the new block
- [x] Commit 00695cd exists (`feat(28-04): add capability-backed incident seed block (Incident 4)`)
- [x] `mix demo.reset` exited 0 with 4 incidents seeded
