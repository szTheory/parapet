# Phase 38: Scoped UI Routes - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make generated Operator UI links, forms, redirects, and LiveView patches respect host-owned route scopes. This phase hardens generated UI route behavior for both the default `/parapet` mount and a nested host scope such as `/ops/parapet`; it does not change auth ownership, router ownership, public API stability tier, dependency surface, or the archive/docs deliverables reserved for adjacent v1.4 phases.

</domain>

<decisions>
## Implementation Decisions

### Route Base Ownership
- **D-01:** Keep route ownership in generated, host-owned UI files. Add or preserve a generated base-path seam that defaults to `/parapet` and can represent nested mounts such as `/ops/parapet`.
- **D-02:** Prefer an inspectable generated-code approach over a Parapet-owned router framework. Acceptable implementation shapes include deriving the base path from the current LiveView URI or generating an explicit editable base-path helper/default in the scaffold, provided the host remains in control.

### Route Surface Coverage
- **D-03:** Cover all route-producing surfaces in the generated Operator UI, not just top-level navigation links: `push_patch`, `push_navigate`, `navigate`, `patch`, `href`, back links, queue pagination, history links, and incident detail links.
- **D-04:** Include form/submit surfaces in the audit, but do not invent form route handling unless planning finds an actual route-bearing form action. Current mutating controls appear to be LiveView events/buttons, not submitted forms.

### Demo And Generated-Copy Proof
- **D-05:** Test-pin both generated template behavior and checked-in demo copies for the default `/parapet` mount and one scoped mount such as `/ops/parapet`.
- **D-06:** Treat template/demo drift as a phase failure. The generator and runnable demo must prove the same route behavior, not just one or the other.

### Stability Boundaries
- **D-07:** Do not add new runtime dependencies, stable public APIs, auth behavior, or Parapet-owned router modules in Phase 38.
- **D-08:** Keep changes scoped to generated UI templates, demo copies, generator guidance, docs/guidance that directly support the route seam, and tests.
- **D-09:** Preserve the existing compile-out boundary: Parapet core must not gain a direct Phoenix or LiveView runtime dependency.

### the agent's Discretion
- Exact base-path helper name, storage location, and function signatures inside generated host-owned modules.
- Whether scoped behavior is proven through existing generated compile tests, a focused generated-vs-demo contract test, or both, provided both default and scoped mounts are pinned.
- Exact scoped example path, though `/ops/parapet` is preferred because it matches the phase prompt and host-owned admin-scope use case.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and trust diagnosis
- `.planning/ROADMAP.md` - Phase 38 goal and success criteria.
- `.planning/REQUIREMENTS.md` - `UIROUTE-01` through `UIROUTE-03` and out-of-scope boundaries.
- `.planning/QUALITY-EVALUATION.md` - host-app compatibility diagnosis: generated UI links use literal `/parapet`; scoped mounting must work without inventing a routing framework.
- `.planning/PROJECT.md` - v1.4 trust-hardening posture, host-owned install model, and stable-main constraints.
- `.planning/STATE.md` - current milestone and phase position.

### Generated UI implementation
- `lib/mix/tasks/parapet.gen.ui.ex` - generator entry point and generated host-owned file targets.
- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` - generated router guidance and route mount shape.
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` - generated list/workbench LiveView route-producing surfaces.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` - generated incident detail route-producing surfaces.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` - generated component links, nav, history, action, and detail link surfaces.

### Tests and proof surfaces
- `test/mix/tasks/parapet.gen.ui_test.exs` - generator output contract tests.
- `test/mix/tasks/parapet.gen.ui_shift_left_test.exs` - generated UI shift-left guards.
- `test/parapet/operator_ui_compile_out_test.exs` - compile-out and current hard-coded route guard.
- `test/parapet/operator_ui_integration_test.exs` - generated/demo UI integration checks and route ownership expectations.
- `test/parapet/operator_ui_demo_contract_test.exs` - checked-in demo route contract.
- `test/parapet/generated_operator_live_paging_test.exs` - generated LiveView compile/paging route behavior tests.

### Stability and docs
- `docs/operator-ui.md` - current generated UI mounting guidance and host-owned code explanation.
- `docs/stability.md` - public API stability tiers.
- `mix.exs` - dependency surface guard.
- `priv/parapet/public_api_stable.json` - stable public API inventory.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix parapet.gen.ui` already writes inspectable host-owned LiveViews/components under the host web namespace; this is the right place for the route base seam.
- Existing generated UI templates already centralize most Operator UI paths in a small set of EEx files, making a comprehensive route-surface pass feasible.
- Existing generated LiveView tests compile template output without requiring a full host app, which can be reused for default and scoped route assertions.
- Existing demo-contract tests can be extended to prevent checked-in demo copies from drifting away from generator output.

### Established Patterns
- Parapet is a respectful Phoenix library: host apps own auth, router scope, pipelines, and generated UI code after generation.
- Generated scaffolding should stay boring, editable, and Phoenix-native rather than hiding routing behind Parapet-owned runtime machinery.
- Optional UI support must not pull Phoenix/LiveView into Parapet core or weaken compile-out behavior.

### Integration Points
- Update `priv/templates/parapet.gen.ui/*` route-producing expressions to resolve through the chosen base-path seam.
- Update `lib/mix/tasks/parapet.gen.ui.ex` only if the generator needs to pass a base-path default, helper module, or template variable into generated files.
- Update demo generated-copy files if present in the repo so checked-in behavior matches generator output.
- Expand tests around generator output, demo contract, compile-out, and generated LiveView route behavior for `/parapet` and `/ops/parapet`.

</code_context>

<specifics>
## Specific Ideas

- Preferred scoped proof path: `/ops/parapet`.
- Preferred failure target: no generated Operator UI interaction should emit a literal `/parapet` path when the UI is mounted under `/ops/parapet`.
- A route-base helper in generated host code is acceptable if it is explicit, editable, and does not become a Parapet stable public API.
- The implementation should audit action controls but avoid broad form work unless a real generated route-bearing form is found.

</specifics>

<deferred>
## Deferred Ideas

- Broader adoption docs for default and scoped mounting belong to Phase 39, except for minimal generator guidance required to make Phase 38 understandable.
- Archive maintenance docs and quality-evaluation closeout belong to Phase 39.
- Multi-tenant/operator-per-org UI semantics remain out of scope for v1.4.
- Parapet-owned router modules, global route-helper replacement, auth policy changes, and new dependencies are explicitly out of scope.

### Reviewed Todos (not folded)

None.

</deferred>
