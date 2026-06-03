# Phase 34: operator-ia-navigation-foundation - Context

**Gathered:** 2026-06-03 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 34 reframes the generated Operator UI around active response, actions, history, and incident detail navigation without changing stable `Parapet.Operator` API semantics, auth ownership, or generated install contents beyond the locked v1.3 roadmap scope.

In scope:
- Make `/parapet` the active response landing route.
- Expose generated route guidance and demo-compatible routes for response, actions, history, preferred incident detail, and legacy incident detail.
- Keep `/parapet/:id` available for compatibility while generated links prefer `/parapet/incidents/:id`.
- Preserve the evidence/action hierarchy when detail is opened from the active workbench or directly by URL.

Out of scope:
- Phase 35 design-system consolidation beyond the route/navigation IA needed here.
- Phase 36 demo state expansion and browser screenshot automation.
- Stable `Parapet.Operator` public API changes.
- Auth ownership changes or Parapet-owned router/auth modules.
</domain>

<decisions>
## Implementation Decisions

### Scope Boundary
- **D-01:** Keep Phase 34 limited to IA/navigation work: `/parapet` active response landing, explicit `Respond`, `Actions`, and `History` lanes, preferred detail route guidance, and legacy detail-route compatibility.
- **D-02:** Do not absorb Phase 35 Tailwind/design-system consolidation or Phase 36 demo/browser verification work into this phase.

### Route Strategy
- **D-03:** Generated router guidance must expose these routes: `/parapet`, `/parapet/actions`, `/parapet/history`, `/parapet/incidents/:id`, and `/parapet/:id`.
- **D-04:** `/parapet/incidents/:id` is the preferred detail route for generated links and navigation copy.
- **D-05:** `/parapet/:id` remains mounted as a compatibility route, and both detail routes must preserve the same incident evidence/action hierarchy.

### Implementation Surface
- **D-06:** Implement this phase generator/template-first, using existing generated LiveView templates and route guidance rather than adding a new Parapet-owned router or application UI runtime.
- **D-07:** Use existing `Parapet.Operator.*` read/mutation seams and `Parapet.Operator.WorkbenchContract` derived fields; do not introduce new stable public API unless planning proves a narrow internal helper is unavoidable.
- **D-08:** Generated detail and workbench navigation should use the active-response copy locked in the UI spec, including `Back to active response`, `Active response workbench`, `Pending action items`, and `Load latest changes`.

### Auth And Install Ownership
- **D-09:** Keep auth host-owned. `mix parapet.gen.ui` should continue to emit authenticated-scope guidance and must not provide Parapet-owned auth.
- **D-10:** Do not change default install ownership semantics. Generated LiveViews remain host-owned, inspectable files under the host app's web tree.

### Verification
- **D-11:** Phase 34 proof should focus on generator/source contract tests and route-guidance assertions, especially `test/mix/tasks/parapet.gen.ui_test.exs` and `test/parapet/operator_ui_integration_test.exs`.
- **D-12:** Browser automation and screenshot proof are deferred to Phase 36 per `UI-VERIFY-02`.

### The Agent's Discretion
- Planners may choose whether to split this into one or two implementation plans based on test blast radius.
- Planners may tighten existing generated template copy/classes only where necessary to satisfy the Phase 34 UI spec; broad visual polish belongs to Phase 35.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` - Phase 34 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` - `UI-IA-01` through `UI-IA-04`, plus v1.3 out-of-scope constraints.
- `.planning/PROJECT.md` - stable-line constraints, install model, generated host-owned UI posture, auth/API boundaries.
- `.planning/STATE.md` - active milestone/session position.
- `.planning/phases/34-operator-ia-navigation-foundation/34-UI-SPEC.md` - approved visual and interaction contract for this phase.
- `lib/mix/tasks/parapet.gen.ui.ex` - generator and router guidance notice surface.
- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` - canonical route guidance snippet.
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` - generated active response, actions, history, queue, refresh, and selected-detail workbench.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` - generated direct incident detail route.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` - generated navigation, overview, queue, action, timeline, and detail components.
- `lib/parapet/operator.ex` - existing stable operator read/mutation seam.
- `lib/parapet/operator/workbench_contract.ex` - derived operator-facing IA fields and queue row projection.
- `test/mix/tasks/parapet.gen.ui_test.exs` - generator output and router guidance contract tests.
- `test/parapet/operator_ui_integration_test.exs` - generated UI source-contract coverage.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` already includes the desired response, actions, history, preferred detail, and compatibility detail routes.
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` already supports page modes for response/actions/history, active queue loading, explicit refresh, queue pagination, and selected incident detail.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` already provides the direct detail LiveView and existing action handlers.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` already provides `operator_nav/1`, `operator_overview/1`, `action_center/1`, queue rows, timeline rendering, and action rail components.
- `Parapet.Operator.WorkbenchContract` derives queue row and detail-facing fields from durable incident/timeline data without schema churn.

### Established Patterns
- Generated UI is host-owned Phoenix LiveView code copied by Igniter with `on_exists: :skip`.
- Parapet emits router guidance rather than editing or owning the host router directly.
- Auth is an adopter responsibility; generated guidance points to an authenticated scope/live session.
- Operator UI actions call `Parapet.Operator` seams instead of duplicating mutation semantics inside templates.
- Proof is currently source/generator-contract oriented for generated UI drift, with browser-backed verification explicitly reserved for later v1.3 work.

### Integration Points
- `Mix.Tasks.Parapet.Gen.Ui.igniter/1` copies the templates and emits route guidance.
- `Parapet.Operator.list_incident_queue/1` and `Parapet.Operator.incident_detail/1` back the workbench and detail reads.
- `Parapet.Operator.acknowledge_incident/2`, `resolve_incident/2`, `preview_runbook_step/3`, `confirm_runbook_step/4`, and escalation actions remain the mutation seams.
- `Parapet.Operator.WorkbenchContract.queue_row/1` and `derive/3` are the IA data projection seams planners should prefer before inventing new template-local derivations.
</code_context>

<specifics>
## Specific Ideas

- Use `Respond`, `Actions`, and `History` as explicit top-level navigation labels.
- Use `aria-current="page"` on the active top-level navigation item.
- Preferred generated detail links should move toward `/parapet/incidents/:id`; compatibility route `/parapet/:id` stays mounted.
- Mobile/back copy should use `Back to active response`, not older queue-oriented wording.
- Queue refresh should stay visible and operator-paced through `Load latest changes`, not silent reorder.
</specifics>

<deferred>
## Deferred Ideas

- Rich demo states and route smoke/screenshot proof belong to Phase 36.
- Broad Tailwind component consolidation, typography/color cleanup, and audit-safe action-card polish belong to Phase 35.
- Team responder ownership, handoff, and shift-aware coordination remain out of scope for this milestone.
- Cross-boundary journey correlation remains deferred to v1.4+.

### Reviewed Todos (not folded)
None - no phase-matched todos were found.
</deferred>
