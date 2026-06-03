# Phase 34: Operator IA & Navigation Foundation - Research

**Researched:** 2026-06-03
**Status:** Ready for planning

## Research Question

What do we need to know to plan Phase 34 well?

Phase 34 is a generator/template-first IA phase. The work should reframe the generated Operator UI around active response, explicit lanes, and preferred incident detail routes while preserving the stable `Parapet.Operator` API, host-owned auth, and compatibility route behavior.

## Current State

### Already aligned

- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` already emits guidance for `/parapet`, `/parapet/actions`, `/parapet/history`, `/parapet/incidents/:id`, and `/parapet/:id`.
- `lib/mix/tasks/parapet.gen.ui.ex` fallback guidance mirrors those same route lines when the template file is unavailable.
- `examples/demo_app/lib/demo_app_web/router.ex` already mounts both preferred and compatibility detail routes.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` already exposes `Respond`, `Actions`, and `History` nav labels and sets `aria-current="page"` on the active top-level nav item.
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` already treats `/parapet` as the default active queue/workbench route, supports actions and history live actions, and uses `Load latest changes` for explicit refresh.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` already renders the same summary, timeline, runbook, preview, escalation, and action rail components used by the selected-detail workbench, preserving the evidence/action hierarchy for direct detail URLs.
- `test/mix/tasks/parapet.gen.ui_test.exs` and `test/parapet/operator_ui_integration_test.exs` already assert much of the active-response copy and generated UI structure.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` already smoke-tests `/parapet`, `/parapet/actions`, `/parapet/history`, `/parapet/incidents/:id`, and `/parapet/:id`.

### Remaining deltas

- `priv/templates/parapet.gen.ui/operator_live.ex.eex` still uses mobile back copy `Back to Queue`; the UI spec requires `Back to active response`.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` is a copied generated file and has the same stale mobile back copy. If the demo app is meant to express the current generated route shape, it should be kept in sync with the template for this narrow IA change.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` still navigates to `/parapet/#{id}` after acknowledge/resolve. Generated links should prefer `/parapet/incidents/:id` while preserving `/parapet/:id` as compatibility.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` mirrors the same post-action legacy detail navigation.
- `docs/operator-ui.md` still documents only `/parapet` and `/parapet/:id`; it should document the response, actions, history, preferred detail, and compatibility detail routes.
- Generator tests assert the preferred detail route exists, but they do not assert the compatibility route remains in generated guidance or that the generated detail LiveView prefers `/parapet/incidents/#{id}` internally.
- Source-contract tests assert `Back to active response` somewhere in combined content, but they do not fail if the selected-detail mobile path still says `Back to Queue`.

## Implementation Surfaces

| Surface | Role | Planning Notes |
|---------|------|----------------|
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | Generated active response workbench | Change only IA copy/link semantics required by Phase 34. Keep active queue, history, action center, and refresh mechanics intact. |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | Generated direct detail LiveView | Prefer `/parapet/incidents/:id` for post-mutation navigation. Preserve the same component hierarchy and public `Parapet.Operator` calls. |
| `priv/templates/parapet.gen.ui/router_snippet.ex.eex` | Canonical route guidance | Already has the required route set; tests should pin both preferred and compatibility lines. |
| `lib/mix/tasks/parapet.gen.ui.ex` | Generator fallback guidance | Already mirrors the route set; tests should keep it pinned so fallback drift is caught. |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | Generated nav and detail components | Already owns `Respond`, `Actions`, `History`, `aria-current`, `Pending action items`, and shared summary/timeline/action rail. Avoid broad Phase 35 visual cleanup. |
| `examples/demo_app/lib/demo_app_web/live/parapet/*.ex` | Demo copy of generated UI | Keep narrowly synced with template route/copy changes so demo smoke routes express the same IA. Rich seed expansion is Phase 36. |
| `docs/operator-ui.md` | Adopter route guidance | Update mounting snippet and prose to document response/actions/history/preferred detail/compatibility detail lanes. |
| `test/mix/tasks/parapet.gen.ui_test.exs` | Generator output/notice tests | Add exact assertions for `/parapet/:id`, preferred post-action detail path, active-response back copy, and absence of stale `Back to Queue`. |
| `test/parapet/operator_ui_integration_test.exs` | Source-contract tests | Add route/copy contract assertions across template, fallback generator, and direct detail templates. |
| `examples/demo_app/test/demo_app/operator_smoke_test.exs` | Demo route smoke | Already covers the required routes; keep as verification, avoid widening to browser screenshots in Phase 34. |

## Constraints

- Do not change `Parapet.Operator` public API semantics.
- Do not add Parapet-owned auth or router modules.
- Do not change default install contents beyond the existing host-owned UI generator templates and docs/guidance.
- Do not add runtime dependencies or Phoenix as a direct core dependency.
- Do not absorb Phase 35 design-system consolidation or Phase 36 demo-state/browser screenshot work.
- Preserve `/parapet/:id` as a mounted compatibility route and smoke-tested path.

## Planning Recommendations

Plan this as two executable plans:

1. **Generated IA contract plan:** update the generated templates and generator/source tests so `/parapet` is active response, top nav lanes are pinned, preferred detail links use `/parapet/incidents/:id`, and compatibility guidance remains present.
2. **Demo/docs route guidance plan:** sync the demo copied LiveViews for the same narrow IA changes and update `docs/operator-ui.md` to show the v1.3 route map. Use existing demo smoke tests rather than adding Phase 36 browser automation.

Keep verification source-contract heavy:

- `mix test test/mix/tasks/parapet.gen.ui_test.exs`
- `mix test test/parapet/operator_ui_integration_test.exs`
- `mix test test/parapet/operator_ui_compile_out_test.exs`
- `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs`
- `mix format --check-formatted`

## Validation Architecture

Phase 34 validation should be automated through source-contract and smoke-test sampling.

- Generator route guidance proof: assert both `live "/parapet/incidents/:id"` and `live "/parapet/:id"` in generator notices.
- Generated template IA proof: assert `Respond`, `Actions`, `History`, `aria-current="page"`, `Active response workbench`, `Pending action items`, `Back to active response`, and `Load latest changes`; refute `Back to Queue`.
- Preferred detail link proof: assert generated direct detail LiveView uses `/parapet/incidents/#{id}` after acknowledge and resolve.
- Compatibility proof: assert route guidance and demo smoke continue covering `/parapet/:id`.
- Demo route proof: keep existing demo smoke path tests for response, actions, history, preferred detail, and compatibility detail routes.

## Risks And Landmines

- A broad Tailwind cleanup would accidentally pull Phase 35 into this phase; keep copy/path changes small.
- Replacing `/parapet/:id` instead of preserving it would break deep links and fail UI-IA-04.
- Updating only templates while leaving demo copies stale would make the demo app disagree with generated IA.
- Updating docs only would not prove generated route notices or post-action navigation.
- Browser screenshots are intentionally deferred to Phase 36; do not make them a Phase 34 completion gate.

## RESEARCH COMPLETE
