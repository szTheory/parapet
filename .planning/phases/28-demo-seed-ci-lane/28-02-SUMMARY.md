---
phase: 28-demo-seed-ci-lane
plan: "02"
subsystem: demo-app-config
tags: [mix-alias, demo-app, seed, replayability]
dependency_graph:
  requires: []
  provides: ["demo.reset alias in examples/demo_app/mix.exs"]
  affects: ["examples/demo_app/mix.exs"]
tech_stack:
  added: []
  patterns: ["mix alias mirroring existing setup chain with ecto.drop prepended"]
key_files:
  created: []
  modified:
    - examples/demo_app/mix.exs
decisions:
  - "demo.reset leads with ecto.drop (not deps.get) so replayability comes from the drop; seeds stay always-insert"
  - "run priv/repo/seeds.exs string is byte-identical to the one in setup to ensure consistent behaviour"
metrics:
  duration: "2 min"
  completed: "2026-05-28"
  tasks: 1
  files_changed: 1
---

# Phase 28 Plan 02: Demo Reset Alias Summary

**One-liner:** Added `"demo.reset"` mix alias (`ecto.drop -> ecto.create -> ecto.migrate -> run priv/repo/seeds.exs`) so the recovery seed loop is replayable without manual DB cleanup.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add the demo.reset alias to mix.exs | fbcd31e | examples/demo_app/mix.exs |

## What Was Built

Added a single alias entry to `examples/demo_app/mix.exs` `aliases/0` function:

```elixir
"demo.reset": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
```

This implements D-10: adopters and CI can run `mix demo.reset` to drop, recreate, migrate, and re-seed the demo DB in one command, making the recovery smoke loop replayable. The `correlation_key` partial unique index would otherwise reject a naive re-seed against a non-empty DB — the drop makes that constraint moot.

## Verification Results

- `cd examples/demo_app && mix help demo.reset` resolves successfully (prints "Alias for..." — no "unknown task" error)
- `grep "demo.reset" examples/demo_app/mix.exs` shows `ecto.drop` first in the chain
- `grep -c "demo.reset" mix.exs` returns 1 (exactly one entry)
- `setup:` alias is unchanged (still leads with `deps.get`)
- No core module under `lib/parapet/**` was edited

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. This plan adds a local developer/CI convenience command with no network, external input, or new endpoints.

## Self-Check: PASSED

- [x] `examples/demo_app/mix.exs` modified and contains `"demo.reset":` entry
- [x] Commit `fbcd31e` exists
- [x] `mix help demo.reset` resolves the alias
