# Phase 35: Design-System Consolidation - Research

## RESEARCH COMPLETE

## Scope

Phase 35 is a repo-local generated UI consolidation phase. No external research is needed because the governing design contract is already approved in `.planning/phases/35-design-system-consolidation/35-UI-SPEC.md`, and the relevant implementation surface is generated Phoenix LiveView template code under `priv/templates/parapet.gen.ui/`.

## Findings

### Generated Component Surface Is the Right Unit of Change

- `priv/templates/parapet.gen.ui/operator_components.ex.eex` contains the repeated UI surfaces: navigation, overview cards, incident queue rows, incident summary, timeline rows, runbook cards, preview panel, action rail, action-item cards, and critical journeys.
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` and `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` mostly consume these helpers and should only need call-site tweaks if helper signatures change.
- Demo files under `examples/demo_app/lib/demo_app_web/live/parapet/` mirror the generated surface and should be updated in the same plan to avoid drift.

### Current Drift Targets

- Card surfaces repeat `bg-white shadow-sm ring-1 ring-stone-900/5 rounded-xl p-4`, including duplicate `bg-white` in several places.
- Button/link classes repeat `min-h-[40px]`, rounded shape, font treatment, transform transition, active scale, and semantic color variants.
- Chip/status classes are split across `journey_color/1`, `state_color/1`, `severity_color/1`, `timeline_entry_actor_class/1`, escalation helpers, and inline `span` classes.
- Mutating controls already have some audit/risk copy, but preview/confirm and escalation copy should be pinned against the UI spec text.
- Existing tests already refute `transition-all`; Phase 35 should expand that into allowed motion/source-contract assertions.

### Verification Fit

- Existing tests read generated templates directly: `test/parapet/operator_ui_integration_test.exs` and `test/mix/tasks/parapet.gen.ui_test.exs`.
- `test/parapet/operator_ui_compile_out_test.exs` protects dependency and public-surface posture.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` proves demo routes render, but Phase 35 does not require browser screenshots. Phase 36 owns browser automation.

## Needs External Research

None.

## Validation Architecture

Use source-contract tests to pin the generated artifact contract:

- Helper presence and usage: assert helper names or generated function components exist in `operator_components.ex.eex`.
- Design-system copy: assert required action/risk/audit strings are adjacent to mutating controls.
- Motion constraints: refute `transition-all`; assert allowed transition strings remain scoped to explicit buttons/action links.
- Dependency posture: keep compile-out test assertions that `mix.exs` does not add Phoenix or LiveView as direct Parapet deps.
- Demo alignment: assert generated and demo component surfaces both contain key helper/copy changes.

Recommended verification commands:

- `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs`
- `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs`
- `mix format --check-formatted`
