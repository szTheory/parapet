---
phase: 29-stability-adopter-onboarding
plan: "02"
subsystem: generator
tags: [igniter, mix-task, generator, scaffold, tdd]
dependency_graph:
  requires: []
  provides: [parapet.gen.recovery-task, recovery-eex-template, gen-recovery-test]
  affects: [adopter-dx, recovery-authoring-surface]
tech_stack:
  added: []
  patterns:
    - Igniter task with required positional arg (positional: [:name] bare atom)
    - Igniter.copy_template/5 with on_exists: :skip
    - Igniter.create_new_file/4 with on_exists: :skip
    - Igniter.Test configure_and_run/3 for positional-arg testing
key_files:
  created:
    - lib/mix/tasks/parapet.gen.recovery.ex
    - priv/templates/parapet.gen.recovery/recovery.ex.eex
    - test/mix/tasks/parapet.gen.recovery_test.exs
  modified: []
decisions:
  - "Used Igniter.Mix.Task.configure_and_run/3 in tests to thread positional argv through parse_argv/1 — the only correct way to test igniter/1 tasks that read igniter.args.positional"
  - "test stub content built inline in create_new_file/4 (not a second EEx template) — keeps the generator self-contained and matches D-10 plan choice"
  - "on_exists: :skip on both source module and test stub — idempotent scaffold, never overwrites adopter edits"
metrics:
  duration: "4 minutes"
  completed: "2026-05-29"
  tasks_completed: 3
  files_created: 3
  files_modified: 0
---

# Phase 29 Plan 02: gen.recovery Generator Summary

**One-liner:** Flag-based `mix parapet.gen.recovery <NAME>` Igniter task scaffolding a host-owned `use Parapet.Recovery` module (4 frozen callbacks + docstring template) and a companion test stub, with Wave-0 Igniter.Test coverage proving scaffold paths, content, required-arg enforcement, and on_exists:skip.

## What Was Built

**Task 1 — `lib/mix/tasks/parapet.gen.recovery.ex`** (commit 980c892)

The generator mirrors `parapet.gen.runbooks.ex` but adds `positional: [:name]` to `%Igniter.Mix.Task.Info{}`. Uses the bare-atom form (`[:name]`) so Igniter raises `ArgumentError` automatically if the arg is omitted. Reads the value via `igniter.args.positional.name` (map access). Derives `module_prefix` as `<BaseName>.Parapet.Recovery` and `lib_dir` as `lib/<app_name>/parapet/recovery`. Scaffolds the source module via `Igniter.copy_template/5` and the test stub via `Igniter.create_new_file/4`, both with `on_exists: :skip`. Finishes with `Igniter.add_notice/2` directing the adopter to the generated file and listing next steps.

**Task 2 — `priv/templates/parapet.gen.recovery/recovery.ex.eex`** (commit 983b8bb)

EEx template emitting a full host recovery capability module: `defmodule @module_prefix.@name_camelized do`, `use Parapet.Recovery`, `@moduledoc` with authoring instructions, and all 4 frozen callbacks (`id/0`, `label/0`, `preview/2`, `execute/2`) with inline `@doc` placeholders. The `id/0` doc comment lists all 5 allowlisted atoms and warns that non-allowlisted atoms raise `ArgumentError` at `Parapet.Capabilities.register_recovery/2`.

**Task 3 — `test/mix/tasks/parapet.gen.recovery_test.exs`** (commit e583331)

Wave-0 Igniter.Test coverage with 3 tests:
1. `"scaffolds the recovery module and test stub"` — asserts both output paths are present in `Rewrite.sources`, asserts source content contains `use Parapet.Recovery`, all 4 callback defs, and the fully-qualified module name `Test.Parapet.Recovery.RetryDLQ`.
2. `"missing NAME raises ArgumentError"` — asserts that invoking with no positional arg raises `ArgumentError` (Igniter enforces the required arg in `parse_argv/1`).
3. `"on_exists: :skip does not overwrite existing module on second run"` — runs the task twice on the same `test_project` and asserts the source content is unchanged after the second run.

## Verification Results

- `mix compile --warnings-as-errors` — exits 0
- `mix test test/mix/tasks/parapet.gen.recovery_test.exs` — 3 tests / 0 failures
- `git diff --stat mix.exs mix.lock` — no changes (zero new deps; Igniter 0.7.9 already a dep)
- Template contains all 4 frozen callbacks and 5-atom allowlist

## Deviations from Plan

### Auto-fixed Issues

None.

### Implementation Adjustments

**1. [Rule 1 - Clarification] Tests use `configure_and_run/3` instead of direct `igniter/1` calls**
- **Found during:** Task 3 RED phase
- **Issue:** The plan said to mirror `parapet.gen.runbooks_test.exs` which calls `Runbooks.igniter()` (no args). For `gen.recovery`, the positional arg must be threaded through `parse_argv/1` before `igniter/1` is called — otherwise `igniter.args.positional.name` is nil and the test is meaningless. Direct `Recovery.igniter/1` would bypass required-arg enforcement entirely.
- **Fix:** Tests use `Igniter.Mix.Task.configure_and_run(igniter, Recovery, argv)` which is the correct in-process equivalent of Mix task invocation: calls `parse_argv/1` (which raises `ArgumentError` for missing required positional) then `igniter/1`. The analog runbooks test doesn't need this because it has no positional args.
- **Files modified:** `test/mix/tasks/parapet.gen.recovery_test.exs`

## Known Stubs

None — the template ships with `def id, do: :<%= @name_underscored %>` as a placeholder, but this is explicitly documented as a starting point the adopter replaces. The scaffold is functionally correct as-is; the placeholder is intentional adopter-facing content (not a library stub).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The generator is a dev-time scaffold tool operating at operator-trust boundaries. Threat mitigations T-29-03 (path traversal via NAME) and T-29-04 (code injection via EEx interpolation) are addressed as planned: NAME passes through `Macro.camelize`/`Macro.underscore` producing alnum-only tokens before Path.join and EEx interpolation.

## Self-Check: PASSED

Files created:
- FOUND: lib/mix/tasks/parapet.gen.recovery.ex
- FOUND: priv/templates/parapet.gen.recovery/recovery.ex.eex
- FOUND: test/mix/tasks/parapet.gen.recovery_test.exs

Commits:
- FOUND: 980c892 (feat: gen.recovery task)
- FOUND: 983b8bb (feat: recovery.ex.eex template)
- FOUND: e583331 (test: Wave-0 Igniter.Test coverage)
