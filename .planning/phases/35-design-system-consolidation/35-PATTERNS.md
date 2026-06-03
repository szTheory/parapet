# Phase 35: Design-System Consolidation - Patterns

## PATTERN MAPPING COMPLETE

## Files To Modify

| File | Role | Closest Existing Analog | Notes |
|------|------|-------------------------|-------|
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | Generated component template and private helper surface | Same file, helper functions at bottom such as `queue_row_class/2`, `state_color/1`, `severity_color/1` | Primary change surface. Add local helper families here rather than new modules. |
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | Generated workbench consuming component helpers | Phase 34 plan changed this file for IA only | Touch only if helper signatures or call-site classes require it. |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | Generated direct detail route consuming component helpers | Phase 34 plan changed route/copy only | Touch only if detail-specific classes need helper usage. |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | Demo copy of generated component template | Generated `operator_components.ex.eex` after EEx expansion and formatting | Keep aligned with generated template changes. |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` | Demo copy of generated workbench | Generated `operator_live.ex.eex` | Update only for helper/copy alignment. |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` | Demo copy of generated detail route | Generated `operator_detail_live.ex.eex` | Update only for helper/copy alignment. |
| `test/mix/tasks/parapet.gen.ui_test.exs` | Generator output contract | Existing Phase 34 generator assertions | Add assertions for copied helper names/classes and required copy. |
| `test/parapet/operator_ui_integration_test.exs` | Source-contract assertions | Existing IA/source tests | Add design-system, copy, and motion assertions. |
| `test/parapet/operator_ui_compile_out_test.exs` | Dependency/API posture guardrail | Existing compile-out assertions | Extend only if needed to prove no new dependency/support surface. |

## Reusable Patterns

### Private Helpers Inside Generated Component Module

Existing helpers live in `operator_components.ex.eex` and return Tailwind class strings:

- `queue_row_class(selected, incident)`
- `state_color(state)`
- `severity_color(severity)`
- `journey_color(status)`
- `timeline_entry_actor_class(presentation)`

Phase 35 should keep that local-private pattern. Good helper candidates:

- `surface_class(:overview | :action | :detail | :quiet)`
- `chip_class(:state | :severity | :attention | :journey | :timeline_actor | :execution, value)`
- `control_class(:primary | :secondary | :warning | :success | :recovery | :quiet, opts \\ [])`
- `action_card(assigns)` as a small generated function component if markup reuse is clearer than string helpers.
- `empty_state(assigns)` if queue/action empty states can share copy surface without over-abstracting.

### Test Pattern

Existing tests use `File.read!` and string assertions against source templates. Continue this pattern because generated UI is the artifact:

- Positive assertions for exact helper names and required copy.
- Negative assertions for `transition-all`, stale one-off classes, and dependency additions.
- Generator tests should inspect rewritten generated source from `Igniter.Test`.

## Data Flow

`mix parapet.gen.ui` copies EEx templates into host-owned `lib/<app>_web/live/parapet/` files. The generated component module is imported by generated workbench/detail LiveViews. Demo files mirror those outputs manually and are used for route smoke coverage.

## Landmines

- Do not add shadcn, icons, Tailwind config files, Phoenix deps, or LiveView deps to Parapet core.
- Do not change stable `Parapet.Operator` public API or mutation semantics.
- Do not reopen route IA from Phase 34.
- Do not use browser screenshots in Phase 35 as the required proof; keep that for Phase 36.
- Do not hide mutating controls behind generic labels like `Submit`, `Go`, `Run`, `Open`, or `OK`.
