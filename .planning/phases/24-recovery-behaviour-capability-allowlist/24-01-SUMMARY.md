---
phase: 24-recovery-behaviour-capability-allowlist
plan: "01"
subsystem: api
tags: [elixir, behaviour, recovery, capabilities, dialyzer]

# Dependency graph
requires:
  - phase: 23-foundations-telemetry-contract-lease-until-migration
    provides: Parapet.Capabilities Agent registry + Parapet.Telemetry.RecoveryAction event family
provides:
  - Parapet.Recovery behaviour module with 4 frozen callbacks (id/0, label/0, preview/2, execute/2)
  - __using__/1 macro injecting only @behaviour Parapet.Recovery
  - attach/1 activation function with silent Code.ensure_loaded? skip + {:ok, registered_ids} return
  - Verbatim Experimental admonition for mix verify.public_api auto-classification
affects:
  - 24-02 (allowlist widening — adds :revert_feature_flag, :disable_metric_label to Parapet.Capabilities)
  - 24-03 (tests — contract tests for the public surface defined here)
  - 25-operator-recovery-path-wiring (calls register_recovery data populated here)
  - 29-graduation-stable (STAB-07 freezes the 4 callbacks defined here)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Behaviour + minimal __using__/1 injection pattern (only @behaviour — no alias/import/helpers)"
    - "Flat-list attach/1 activation (Code.ensure_loaded? filter → id/label call → function-capture bridge → register)"
    - "Function-capture bridge: &module.preview/2 and &module.execute/2 for is_function/2 guard compatibility"

key-files:
  created:
    - lib/parapet/recovery.ex
  modified: []

key-decisions:
  - "4 callback signatures frozen: id() :: atom(), label() :: String.t(), preview(incident, step), execute(incident, target_refs) — locked by operator.ex consumer call sites"
  - "__using__/1 injects only @behaviour Parapet.Recovery — conservative surface freeze for Phase 29 STAB-07 graduation"
  - "attach/1 signature is flat list [module()] not keyword list — locked by ROADMAP.md success criterion #2"
  - "Function captures (&module.preview/2, &module.execute/2) mandatory — operator.ex is_function/2 guard would fail on module atoms"
  - "target_kind and preview_only NOT passed to register_recovery/2 — v1.1 callback set deliberately minimal"
  - "Return {:ok, registered_ids} 2-tuple — symmetric with Parapet.attach/1 return, ADOP-02 diagnostic surface"

patterns-established:
  - "Pattern: behaviour module with Experimental admonition + @doc since: 1.1.0 on each callback"
  - "Pattern: minimal __using__/1 with only @behaviour injection (first such macro in codebase)"
  - "Pattern: Enum.filter(&Code.ensure_loaded?/1) before any module callback invocation"

requirements-completed:
  - RCV-01
  - RCV-02

# Metrics
duration: 5min
completed: "2026-05-27"
---

# Phase 24 Plan 01: Recovery Behaviour + Capability Allowlist Summary

**`Parapet.Recovery` behaviour module with 4 frozen callbacks, minimal `__using__/1` macro, and crash-proof `attach/1` activation function that silently skips unloaded modules and registers loaded ones via function-capture bridge into `Parapet.Capabilities`**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-27T22:27:00Z
- **Completed:** 2026-05-27T22:32:25Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Created `lib/parapet/recovery.ex` with `Parapet.Recovery` behaviour defining the 4-callback host-app contract
- `__using__/1` macro injects only `@behaviour Parapet.Recovery` — the most conservative freeze surface for Phase 29 STAB-07
- `attach/1` accepts a flat list of module atoms, filters with `Code.ensure_loaded?`, captures `&module.preview/2` and `&module.execute/2` as anonymous functions (required for `is_function/2` guard in `operator.ex`), and delegates to `Parapet.Capabilities.register_recovery/2`
- Verbatim Experimental admonition in `@moduledoc` — `mix verify.public_api` auto-classifies the module as `experimental` with no manifest edits
- `mix compile --warnings-as-errors` exits 0; no edits to any other file

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Parapet.Recovery module with behaviour, __using__/1, and attach/1** - `e05f3fa` (feat)

**Plan metadata:** (committed with SUMMARY below)

## Files Created/Modified

- `lib/parapet/recovery.ex` — `Parapet.Recovery` behaviour module: 4 callbacks (id/0, label/0, preview/2, execute/2), minimal `__using__/1` macro, `attach/1` activation function

## Module Shape

The `Parapet.Recovery` module structure (top to bottom):

1. `@moduledoc` with adopter prose + verbatim Experimental admonition matching `lib/parapet/capabilities.ex:6-10`
2. Four `@callback` declarations each with `@doc since: "1.1.0"` + `@doc """..."""`:
   - `@callback id() :: atom()`
   - `@callback label() :: String.t()`
   - `@callback preview(incident :: any(), step :: any()) :: {:ok, map()} | {:error, term()}`
   - `@callback execute(incident :: any(), target_refs :: any()) :: {:ok, map()} | {:error, term()}`
3. `defmacro __using__(_opts) do quote do @behaviour Parapet.Recovery end end` — nothing else
4. `def attach(modules) when is_list(modules)` — filter → map → `{:ok, registered}`

## `attach/1` Flow

```
modules (flat list of module atoms)
  |> Enum.filter(&Code.ensure_loaded?/1)   # silent skip if false — no log, no warn
  |> Enum.map(fn module ->
       id    = module.id()                  # call once at attach time
       label = module.label()               # call once at attach time
       :ok   = Parapet.Capabilities.register_recovery(id,
                 name: label,
                 preview: &module.preview/2,   # anonymous-function capture (is_function/2 safe)
                 execute: &module.execute/2    # anonymous-function capture (is_function/2 safe)
               )
       id
     end)
{:ok, registered}                           # 2-tuple, not bare :ok
```

## Decisions Made

- 4 callback signatures frozen at arity-0 (`id`, `label`) and arity-2 (`preview`, `execute`) — locked by `lib/parapet/operator.ex:711,767` consumer call sites. Arity changes would be breaking.
- `__using__/1` injects only `@behaviour Parapet.Recovery`. No alias, no import, no helpers. Mirrors Phase 29 STAB-07 freeze posture.
- Flat-list `attach([module()])` signature — distinguished from `Parapet.attach/1`'s keyword-list `[adapters: [...]]` per ROADMAP.md success criterion #2.
- Function captures `&module.preview/2` / `&module.execute/2` mandatory — `lib/parapet/operator.ex:711,767` guards with `is_function(., 2)`; passing module atoms would silently fall back to `base_preview`.
- `target_kind` and `preview_only` deliberately excluded from v1.1 callback set — they keep struct defaults (`nil`, `false`) and are v1.2 additions if needed.
- Return value `{:ok, registered_ids}` — symmetric with `Parapet.attach/1`, enables Phase 29 ADOP-02 adoption-signal count.

## Deviations from Plan

None — plan executed exactly as written. The TDD flag in the task frontmatter is noted: the plan explicitly delegates test creation to Plan 03 ("Do NOT in this plan: Create or modify any test file"), so no test file was created.

## Issues Encountered

The worktree lacked a `deps/` directory, so compilation ran with `MIX_DEPS_PATH=/Users/jon/projects/parapet/deps` pointing to the main repo's deps. Compilation succeeded with 89 files (88 baseline + 1 new), confirming clean integration.

## Next Phase Readiness

- **Plan 02** (allowlist widening): Can widen `@valid_capabilities` in `lib/parapet/capabilities.ex` from 3 to 5 atoms (adds `:revert_feature_flag`, `:disable_metric_label`). This plan's `attach/1` will accept those new atoms after Plan 02 ships.
- **Plan 03** (tests): Contract tests can now exercise `use Parapet.Recovery`, `attach/1` with real fixture modules, and the silent-skip behavior.
- **Phase 25** (operator path wiring): `Parapet.Capabilities.get_recovery/1` at `operator.ex:657` will find capabilities registered via the `attach/1` flow defined here.
- **Phase 29** (STAB-07): The 4 callback signatures are frozen from this commit forward — graduation to Stable requires no modification.

---
*Phase: 24-recovery-behaviour-capability-allowlist*
*Completed: 2026-05-27*
