# Phase 35: design-system-consolidation - Context

**Gathered:** 2026-06-03 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 35 tightens the generated Tailwind component system for the Operator UI so repeated UI elements share clear visual rules and interaction affordances. Scope is limited to `UI-DS-01` through `UI-DS-05`: shared surface/status/action helpers, selected/focus states, audit/risk communication before mutating controls, restrained motion, and active-response copy.

This phase does not reopen Phase 34 IA/navigation decisions, does not add Phase 36 demo/browser verification work, and must not change stable `Parapet.Operator` API semantics, auth ownership, default install ownership, or the dependency/support surface.
</domain>

<decisions>
## Implementation Decisions

### Implementation Surface
- **D-01:** Keep the work generator/template-first inside `priv/templates/parapet.gen.ui/operator_components.ex.eex`, with only companion updates to copied demo LiveViews/components where needed.
- **D-02:** Do not add a runtime design-system package, Phoenix UI dependency, icon dependency, Tailwind config contract, or Parapet-owned router.
- **D-03:** Keep helpers private/local to the generated component module so adopters receive deterministic host-owned generated code.

### Consolidation Shape
- **D-04:** Introduce local helper families in the generated component template for repeated surfaces: overview cards, action cards, status chips, control buttons/links, queue rows, empty states, and compact timeline badges.
- **D-05:** Reduce drift-prone repeated raw Tailwind strings such as shared card surfaces, chip classes, button classes, duplicate `bg-white`, and scattered semantic color classes.
- **D-06:** Treat this as a consolidation pass, not a broad redesign. Preserve the active-response IA and route map established in Phase 34.

### Visual And Interaction Rules
- **D-07:** Treat the approved Phase 35 UI spec as the locked design-token source: stone/white/teal dominant palette, semantic amber/emerald/blue/indigo/violet/red only for named meanings, 4px spacing scale, `min-h-[40px]` controls, visible focus rings, no `transition-all`, and press scaling only on explicit buttons/action links.
- **D-08:** Preserve restrained, non-essential motion. Hover states may adjust background/text color only and must not resize rows, cards, chips, or layout containers.
- **D-09:** Keep queue row selection visible through both `aria-current` and a teal selected state; keep navigation selection as `aria-current="page"`.

### Action Safety Copy
- **D-10:** Mutating action cards must keep or add adjacent pre-click audit/risk copy before controls, using the specific copy from the Phase 35 UI spec where applicable.
- **D-11:** Copy must stay active-response oriented: impact, evidence, next safe action, audit, and recovery.
- **D-12:** Preview/confirm recovery surfaces should communicate that Preview is non-mutating and Confirm executes bounded recovery with durable audit records.

### Verification
- **D-13:** Verify with source-contract and generator tests in this phase, not browser screenshots.
- **D-14:** Extend `test/parapet/operator_ui_integration_test.exs`, `test/mix/tasks/parapet.gen.ui_test.exs`, and, if useful, demo smoke/source checks to pin helper names/classes, required copy, focus/hover/selection states, and absence of `transition-all`.
- **D-15:** Leave browser automation and screenshot proof to Phase 36 per `UI-VERIFY-02`.

### The Agent's Discretion
- Planners may choose the exact helper names, provided the names are legible and source tests pin the generated contract.
- Planners may decide whether demo copied files are updated manually in the same plan or regenerated from templates, as long as generated and demo surfaces stay aligned.
- Planners may keep existing indigo/violet/blue treatments only where the UI spec assigns them specific meaning.

### Folded Todos
None - `todo.match-phase 35` returned no matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` - Phase 35 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` - `UI-DS-01` through `UI-DS-05`, plus v1.3 out-of-scope constraints.
- `.planning/PROJECT.md` - stable-line constraints, install model, generated host-owned UI posture, auth/API boundaries.
- `.planning/STATE.md` - active milestone/session position.
- `.planning/phases/34-operator-ia-navigation-foundation/34-CONTEXT.md` - locked IA, route, auth, install, and verification boundaries from the previous phase.
- `.planning/phases/35-design-system-consolidation/35-UI-SPEC.md` - approved visual, copy, motion, spacing, typography, color, and verification contract for this phase.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` - generated navigation, overview, queue, status, action, timeline, preview, and detail components.
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` - generated response/actions/history workbench consuming component helpers.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` - generated direct incident detail route and mutation handlers.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` - demo copy of generated component surface.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` - demo copy of generated workbench.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` - demo copy of generated detail route.
- `test/mix/tasks/parapet.gen.ui_test.exs` - generator output contract tests.
- `test/parapet/operator_ui_integration_test.exs` - generated UI source-contract and IA tests.
- `test/parapet/operator_ui_compile_out_test.exs` - dependency/auth/API posture guardrails.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` - demo route smoke coverage.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `operator_nav/1` and `nav_item/1` already provide the top-level `Respond`, `Actions`, and `History` navigation with `aria-current="page"` and focus-ring treatment.
- `operator_overview/1`, `incident_list/1`, `incident_summary/1`, `incident_timeline/1`, `runbook_card/1`, `preview_panel/1`, `action_rail/1`, and `action_item_card/1` already cover the repeated UI surfaces that Phase 35 needs to consolidate.
- Existing helper functions include `journey_color/1`, `queue_row_class/2`, `state_color/1`, `severity_color/1`, `timeline_entry_actor_class/1`, and escalation status helpers. These are the natural place to evolve toward a consistent chip/status helper family.
- Existing tests already read generated templates as source artifacts, making them a good fit for Phase 35 contract assertions.

### Established Patterns
- Generated UI is host-owned Phoenix LiveView code copied by Igniter with `on_exists: :skip`.
- Parapet emits router guidance rather than editing or owning the host router directly.
- Auth is an adopter responsibility; generated guidance points to an authenticated scope/live session.
- Phase 34 already established the route map and active-response IA; Phase 35 should consume it unchanged.
- UI verification in this part of the milestone is source/generator-contract oriented; Phase 36 owns browser-backed responsive screenshot proof.

### Integration Points
- `Mix.Tasks.Parapet.Gen.Ui.igniter/1` copies the templates and emits route guidance.
- `operator_live.ex.eex` consumes `operator_nav/1`, `operator_overview/1`, `action_center/1`, `incident_list/1`, `incident_summary/1`, `incident_timeline/1`, `action_item_list/1`, and `action_rail/1`.
- `operator_detail_live.ex.eex` consumes `operator_nav/1`, `incident_summary/1`, `incident_timeline/1`, `suspect_changes_card/1`, `runbook_card/1`, `preview_panel/1`, and `action_rail/1`.
- Demo files under `examples/demo_app/lib/demo_app_web/live/parapet/` are generated-surface mirrors and should stay aligned with template changes.
</code_context>

<specifics>
## Specific Ideas

- Preserve `Load latest changes`, `No active incidents`, `No pending action items`, and `Back to active response` copy from the approved UI spec.
- Prefer private helper functions or small function components over introducing a new public module or runtime configuration.
- Pin the absence of `transition-all` and restrict press scaling to explicit buttons/action links.
- Pin audit/risk copy adjacent to acknowledge, resolve, preview mitigation, confirm mitigation, escalation trigger/suppress, and external action item controls.
- Preserve `min-h-[40px]` on generated links/buttons used as controls.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within phase scope.

### Reviewed Todos (not folded)
None.
</deferred>
