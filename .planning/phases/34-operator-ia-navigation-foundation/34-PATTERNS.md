# Phase 34: Operator IA & Navigation Foundation - Pattern Map

**Mapped:** 2026-06-03
**Status:** Ready for planning

## Scope

Phase 34 modifies generated Phoenix LiveView UI templates, route guidance, demo copied LiveViews, docs route guidance, and source-contract tests. It should not modify stable `Parapet.Operator` API modules, database schema, auth ownership, install defaults, or broad Tailwind design-system rules.

## File Pattern Map

| Planned File | Role | Closest Existing Analog | Pattern to Reuse |
|--------------|------|-------------------------|------------------|
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | Generated active-response workbench | Existing same file | Keep `handle_params/3`, `page_mode/1`, `queue_path/2`, queue refresh, and stream setup; change only active-response IA copy/link semantics. |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | Generated direct incident detail route | Existing same file | Keep `Parapet.Operator.incident_detail/1`, mutation handlers, and shared component hierarchy; prefer `/parapet/incidents/:id` for generated post-action navigation. |
| `priv/templates/parapet.gen.ui/router_snippet.ex.eex` | Canonical adopter route guidance | Existing same file and fallback notice in `lib/mix/tasks/parapet.gen.ui.ex` | Keep authenticated scope guidance and both preferred/compatibility detail routes. |
| `lib/mix/tasks/parapet.gen.ui.ex` | Generator task and fallback guidance | Existing fallback notice block | If route guidance changes, keep fallback and template route sets identical. |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | Generated nav, overview, queue, detail, action components | Existing `operator_nav/1`, `nav_item/1`, `incident_list/1`, `action_center/1`, `incident_summary/1`, `incident_timeline/1`, `action_rail/1` | Reuse existing nav and hierarchy; avoid Phase 35 visual consolidation except exact copy required by UI spec. |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` | Demo copy of active workbench | Generated template counterpart | Keep narrowly synced with changed generated copy/link semantics. |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` | Demo copy of direct detail route | Generated template counterpart | Keep post-action navigation aligned with preferred detail route. |
| `examples/demo_app/lib/demo_app_web/router.ex` | Demo route mounting | Existing route set | Already mounts response/actions/history/preferred detail/compatibility detail; use smoke tests as verification. |
| `docs/operator-ui.md` | Adopter documentation | Existing mounting section and security posture sections | Update route snippet and route descriptions while preserving host-owned auth warning. |
| `test/mix/tasks/parapet.gen.ui_test.exs` | Generator output/notice contract | Existing generator tests | Add assertions for active-response copy, stale copy absence, preferred detail navigation, and compatibility route guidance. |
| `test/parapet/operator_ui_integration_test.exs` | Template/source contract | Existing IA and layout tests | Add exact assertions for selected-detail mobile copy, route guidance, preferred detail path, and compatibility preservation. |
| `test/parapet/operator_ui_compile_out_test.exs` | Optional Phoenix dependency posture and detail handler source contract | Existing detail LiveView assertions | Add preferred detail route assertion if post-action navigation changes there. |
| `examples/demo_app/test/demo_app/operator_smoke_test.exs` | Demo route smoke | Existing route smoke tests | Already covers all required routes; use unchanged or extend only if execution discovers a missing assertion. |

## Existing Code Excerpts

### Route Guidance

`priv/templates/parapet.gen.ui/router_snippet.ex.eex` already emits:

- `live "/parapet", ... OperatorLive, :index`
- `live "/parapet/actions", ... OperatorLive, :actions`
- `live "/parapet/history", ... OperatorLive, :history`
- `live "/parapet/incidents/:id", ... OperatorDetailLive, :show`
- `live "/parapet/:id", ... OperatorDetailLive, :show`

`lib/mix/tasks/parapet.gen.ui.ex` contains the same route lines in fallback guidance.

### Active Workbench

`priv/templates/parapet.gen.ui/operator_live.ex.eex`:

- loads action items in `mount/3`;
- resolves `page_mode` from `socket.assigns.live_action`;
- loads active queue via `Parapet.Operator.list_incident_queue/1`;
- loads resolved history through an internal `resolved_history_page/1`;
- selects detail from `params["id"]` through `Parapet.Operator.incident_detail/1`;
- uses `queue_refresh_available?` and `Load latest changes` rather than silently reordering.

### Shared Detail Hierarchy

`operator_detail_live.ex.eex` and selected-detail rendering in `operator_live.ex.eex` both use shared components from `operator_components.ex.eex`:

- `incident_summary/1`
- `incident_timeline/1`
- `runbook_card/1`
- `preview_panel/1`
- `action_rail/1`

This is the key reason direct detail URLs and selected workbench detail already preserve the evidence/action hierarchy.

### Tests

Existing tests already pin:

- generated files under `lib/<host>_web/live/parapet/`;
- `Parapet.Operator.list_incident_queue`;
- `Parapet.Operator.incident_detail(id)`;
- `Respond`, `Actions`, `History`;
- `Active response workbench`;
- `Back to active response`;
- `Load latest changes`;
- route smoke for preferred and compatibility detail routes in the demo app.

## Data Flow

1. `mix parapet.gen.ui` copies templates into the host app via Igniter with `on_exists: :skip`.
2. The generator emits route guidance notice instead of editing the host router.
3. Host router mounts the generated LiveViews inside a host-owned authenticated scope.
4. `/parapet` renders `OperatorLive` in active response mode.
5. `/parapet/actions` renders `OperatorLive` in action center mode.
6. `/parapet/history` renders `OperatorLive` in resolved history mode.
7. `/parapet/incidents/:id` and `/parapet/:id` both render `OperatorDetailLive`.
8. Both direct detail and selected workbench detail call `Parapet.Operator.incident_detail/1` and render the same evidence/action components.

## Landmines

- Do not remove `/parapet/:id`; Phase 34 explicitly preserves compatibility.
- Do not make Parapet edit or own the host router; guidance stays notice/template based.
- Do not add Phoenix or LiveView as a core dependency.
- Do not use this phase to normalize all Tailwind colors, cards, icons, or typography; Phase 35 owns that cleanup.
- Do not add browser screenshot automation or broad demo state expansion; Phase 36 owns that proof.
- Do not create new public `Parapet.Operator` functions for route IA; existing read/mutation seams are sufficient.
- Keep generated template changes and demo copied LiveView changes aligned where the demo source is expected to mirror generated output.

## PATTERN MAPPING COMPLETE
