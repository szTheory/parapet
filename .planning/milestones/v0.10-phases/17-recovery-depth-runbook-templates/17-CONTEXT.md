# Phase 17: Recovery Depth — Runbook Templates - Context

**Gathered:** 2026-05-24 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every prebuilt runbook template **deep enough that an operator trusts it** — a
precondition, a scoped preview, a warning, a bounded mitigation, and a post-action
verification — across **seven** templates total. This phase builds/deepens the runbook
*code surfaces*; it does **not** write the adoption docs that will later name them (Phase 18).

**In scope:**
- A surgical DSL/foundation addition so `warning:` actually renders (it is currently
  silently swallowed — see D-01), landing **before** any template references it.
- Deepen the four existing templates (`dead_letter`, `callback_delay`, `stalled_executor`,
  `provider_outage`) to the RCV-01 depth checklist (RCV-01).
- Add three new templates at the same depth: `retry_storm`, `suppression_drift`,
  `partial_backlog_drain` (RCV-02).
- Wire the three new templates into the generator with `on_exists: :skip` (already the
  established behaviour — D-08).
- Regression tests that prove `warning:` survives end-to-end, plus generator coverage.

**Out of scope (milestone + prior decisions):** No new runtime deps, Ecto schemas, or Oban
queues. **No new `capability:` ids** — the registry is a closed allowlist of three (D-05).
No Generator engine rewrite (glob refactor) — keep the explicit per-file copy model (D-08).
No adoption/authoring docs (Phase 18). Generated runbook files remain host-owned, inspectable,
and modifiable; the generator never overwrites adopter edits (`on_exists: :skip`).
</domain>

<decisions>
## Implementation Decisions

### `warning:` DSL Surface (RCV-01 prerequisite — research flag RESOLVED)
- **D-01:** `warning:` is currently **silently swallowed** by the DSL — the `step/2` macro
  (`runbook.ex:21-33`) builds the step map from exactly 11 keys (`id, label, description, type,
  kind, capability, target_kind, requires_preview, preview_only, auto_execute, guidance`) and
  `warning` is **not** among them. `requires_preview:` and `kind: :guidance` DO already work.
  This confirms the SUMMARY.md/STATE.md blocker and **overrides FEATURES.md's claim** that
  `warning:` already exists. The `warning:` addition MUST land before any template uses it.
- **D-02:** Adding `warning:` is a **three-surface change**, all required for an operator to
  actually see it:
  1. `step/2` macro + `__runbook_schema__/0` — add `warning: unquote(opts)[:warning]` to the
     step map (`runbook.ex:21-33`).
  2. `WorkbenchContract` step projection — `derive_runbook_steps/3` re-projects each step into a
     **new** explicit map (`workbench_contract.ex:144-156`) that lists fields individually;
     `warning` must be added there or it is dropped *after* the macro is fixed.
  3. Operator UI — the `runbook_card` (`operator_components.ex.eex:270-334`) renders only
     label/description/guidance/targeting_hints; add a distinct warning render block.
- **D-03:** Render the step-level `warning:` as a new **amber/red block inside the
  `runbook_card` step loop**, near the existing guidance block (`operator_components.ex.eex:293-297`).
  Do **NOT** route it through the runtime `preview_panel` warnings list
  (`operator_components.ex.eex:361-370`) — that list reads `preview.data["warnings"]`, a
  capability-preview runtime field, a different concern that would only show warnings for
  previewable steps and miss precondition/guidance warnings.
- **D-04 (good news):** End-to-end **persistence needs no work** — `__runbook_schema__/0`
  (`runbook.ex:55-63`) escapes the full step list, `alert_processor.ex:118` applies it whole into
  `runbook_data`, and `workbench_contract.ex:114-115` `stringify_keys` each step generically, so a
  new `warning` key survives JSON persistence automatically. The only gaps are the three surfaces
  in D-02.

### New Templates: Capabilities Are a Closed Allowlist (RCV-02)
- **D-05:** **No new `capability:` ids may be introduced.** The registry is a hard-coded
  allowlist of exactly three — `:retry_async_item`, `:requeue_dead_letter`,
  `:request_manual_provider_check` (`capabilities.ex:8-12`); `register_recovery/2` raises
  `ArgumentError` for anything else (`:35-37`, `capabilities_test.exs:32-36`). An unknown
  capability resolves to `{:error, :capability_unwired}` at runtime
  (`operator.ex:622-624`/`:669-671`/`:644`/`:705`).
- **D-06:** Each new template's mitigation is therefore **either** a guidance/manual step
  (`type: :mitigation, kind: :guidance` or `:manual`, dispatched via the host-overridable
  `execute_mitigation/2`, `runbook.ex:14-15`) **or** reuses one of the three existing
  capabilities **only where the target semantics are an exact fit** (e.g. `:retry_async_item`
  with `target_kind: :async_item` for `retry_storm`/`partial_backlog_drain`). Default to
  guidance-only mitigations; this honors the "host-owned runbook modules" prior decision and the
  "no new runtime code" constraint. `target_kind` is free-form (no registry, `operator.ex:723`
  passes through) — so a guidance step may name a descriptive `target_kind` without a backing
  capability, but a *wired* mitigation step must use one of the three real capabilities.
- **D-07 (planning):** During planning, decide per new template whether its mitigation reuses a
  real capability or is guidance-only — and ensure `suppression_drift` (no async_item semantics)
  is guidance-only since none of the three capabilities fit it. Verification steps are always
  `kind: :guidance` and need no capability.

### Template Depth & Generator (RCV-01 / RCV-02 / criterion 3)
- **D-08:** The generator **already satisfies criterion 3** — `parapet.gen.runbooks.ex:33-56`
  is four explicit `Igniter.copy_template` calls, each already passing `on_exists: :skip`
  (lines 37/43/49/55), with assign `module_prefix` (`:29`). Each new template = **one new
  explicit `copy_template` call + one new generator-test assertion**. Keep the explicit per-file
  model; do **not** refactor to a priv-dir glob (diverges from the pattern the test asserts and
  is unjustified for a surgical milestone).
- **D-09:** The four existing templates have **distinct, non-uniform gaps** (none has any
  `warning:` or a dedicated verification step today):
  - `dead_letter` (2 steps, `dead_letter.ex.eex:7-24`) — add scoped preview + warning + verification.
  - `callback_delay` (1 guidance step, the thinnest, `callback_delay.ex.eex:7-14`) — add preview
    + warning + a mitigation + verification.
  - `stalled_executor` (2 steps, `stalled_executor.ex.eex:7-23`) — add warning + verification.
  - `provider_outage` (2 steps, `provider_outage.ex.eex:7-24`) — add warning + verification.
- **D-10:** Express precondition and verification as **distinct `type: :manual, kind: :guidance`
  steps** (clearest operator semantics; render via the guidance block) rather than folding them
  into a mitigation's `description`/`guidance`. The RCV-01 checklist demands an explicit
  "post-action verification" step.

### Test Strategy
- **D-11:** Prove `warning:` is **not swallowed** with a three-layer test, because the failure
  mode is invisible at compile time:
  1. **DSL/schema** — assert `__runbook_schema__()` exposes `warning` (mirror
     `runbook_test.exs:57-112`, e.g. add `warning:` to a `DummyRunbook` step and assert it).
  2. **Projection** — assert the `WorkbenchContract`-projected step map includes `warning`
     (extend `workbench_contract_test.exs:308-369`) — this is the layer most likely to silently
     drop it (D-02 #2).
  3. **Generator content** — assert each new/deepened template file copies and contains its
     `warning:` line (extend `parapet.gen.runbooks_test.exs:8-48`).
- **D-12:** `Parapet.Runbook` is a **documented public module** (`runbook.ex:2-6` `@moduledoc`),
  so the new `warning:` option must be documented in the `step/2` `@doc` or `verify.public_api`
  (`mix docs --warnings-as-errors`) breaks CI.

### Claude's Discretion
- Exact wording/content of each step's `label`, `description`, `guidance`, and `warning:` text —
  pin during planning, anchored to the existing templates' voice and the RCV depth checklist.
- Per-new-template mitigation choice (reuse `:retry_async_item` vs. guidance-only) within the
  D-05/D-06 constraints (D-07).
- Whether the new warning UI block is amber vs. red and its exact Tailwind classes — follow the
  existing `operator_components.ex.eex` styling conventions.
- File/module naming of the three new templates under
  `priv/templates/parapet.gen.runbooks/` — mirror the existing four.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `lib/parapet/runbook.ex` — the DSL: `step/2` macro + `__runbook_schema__/0` (`:19-65`); the
  surface to add `warning:` (D-01/D-02 #1) and document (D-12); `execute_mitigation/2`
  overridable default (`:14-15`) for guidance mitigations.
- `lib/parapet/operator/workbench_contract.ex` — `derive_runbook_steps/3` step re-projection
  (`:113-158`, field list `:144-156`); the layer that drops `warning` unless added (D-02 #2).
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — `runbook_card` (`:270-334`),
  guidance block (`:293-297`), runtime `preview_panel` warnings list (`:361-370`); add the
  step-level warning block here (D-03).
- `priv/templates/parapet.gen.runbooks/dead_letter.ex.eex`,
  `callback_delay.ex.eex`, `stalled_executor.ex.eex`, `provider_outage.ex.eex` — the four
  templates to deepen (D-09); the depth/step pattern to mirror.
- `lib/parapet/capabilities.ex` — the closed allowlist of three capabilities (`:8-12`),
  `register_recovery/2` raise (`:35-37`); the constraint behind D-05/D-06.
- `lib/parapet/operator.ex` — capability resolution / preview-execute path (`:622-624`,
  `:669-671`, `:644`, `:705`); `target_kind` pass-through (`:723`); proves the `:capability_unwired`
  failure mode.
- `lib/mix/tasks/parapet.gen.runbooks.ex` — generator with explicit `copy_template` calls +
  `on_exists: :skip` (`:33-56`), `module_prefix` assign (`:29`); add three new calls (D-08).
- `lib/parapet/alert_processor.ex` — `runbook_data` persistence (`:118`); confirms `warning`
  survives JSON automatically (D-04).
- `test/parapet/runbook_test.exs` (`:57-112`) — canonical DSL/schema test pattern (D-11 #1).
- `test/parapet/operator/workbench_contract_test.exs` (`:308-369`) — projection test to extend
  (D-11 #2).
- `test/mix/tasks/parapet.gen.runbooks_test.exs` (`:8-48`) — generator content test to extend
  (D-11 #3); confirms hardcoded per-file model (D-08).
- `test/parapet/capabilities_test.exs` (`:32-36`) — proves the allowlist raises (D-05).
- `.planning/REQUIREMENTS.md` — RCV-01, RCV-02, AC-03 (operator sees precondition + scoped
  preview + bounded mitigation + warning on ≥1 deepened and ≥1 new template).

No external specs — requirements fully captured in decisions above.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **DSL is 90% there** — `requires_preview:`, `preview_only:`, `kind: :guidance`,
  `capability:`, `target_kind:`, `guidance:`, `auto_execute:` already work
  (`runbook.ex:21-33`). Only `warning:` is missing.
- **Persistence path is generic** — `__runbook_schema__` → `alert_processor.ex:118` →
  `stringify_keys` carries any new step key through to `runbook_data` with zero changes (D-04).
- **Generator already host-safe** — `on_exists: :skip` on every existing `copy_template` call
  satisfies criterion 3 (D-08).
- **Three working capabilities** — `:retry_async_item`, `:requeue_dead_letter`,
  `:request_manual_provider_check` are wired and previewable; reuse where the target fits (D-06).
- **`execute_mitigation/2` is host-overridable** — guidance-only mitigation steps are safe,
  inspectable, and need no capability (`runbook.ex:14-15`).

### Established Patterns
- Precondition / verification = `type: :manual, kind: :guidance` steps (pattern at
  `dead_letter.ex.eex:7-14`); scoped preview = `requires_preview: true` on the mitigation
  (`dead_letter.ex.eex:23`).
- Templates are EEx with `<%= inspect(@module_prefix) %>` headers; generator copies each
  explicitly with `on_exists: :skip`.
- Public modules must be documented or `verify.public_api` (`mix docs --warnings-as-errors`)
  fails (D-12).

### Integration Points
- DSL `step/2` map → `__runbook_schema__` → `alert_processor` `runbook_data` →
  `WorkbenchContract.derive_runbook_steps` → operator UI `runbook_card`. The `warning:` change
  touches the macro, the projection, and the card (D-02).
- `parapet.gen.runbooks` generator → `priv/templates/parapet.gen.runbooks/*.ex.eex` (D-08).

### Watch-outs
- **Silent-swallow trap:** Elixir ignores unknown keyword args to the `step/2` macro — a template
  using `warning:` before D-02 lands compiles cleanly and passes schema tests yet never shows the
  warning. Land the DSL change first; test at the schema layer (D-11 #1).
- **Projection-drop trap:** even after the macro is fixed, `warning` is dropped at
  `workbench_contract.ex:144-156` unless explicitly added — invisible to operators (D-02 #2,
  D-11 #2).
- **Unwired-capability trap:** a template naming a non-allowlisted `capability:` generates and
  compiles, but the runtime Preview/Execute button returns `{:error, :capability_unwired}` — a
  broken runbook (D-05).
</code_context>

<specifics>
## Specific Ideas

- Land the `warning:` DSL+projection+UI change as the **first task/wave**, gated by a schema-level
  test, before any template content references `warning:`.
- Author new-template mitigations as guidance-only by default; only reuse `:retry_async_item`
  where `target_kind: :async_item` is a genuine fit (`retry_storm`, `partial_backlog_drain`).
  `suppression_drift` is guidance-only (no fitting capability).
- Three-layer regression test (schema + projection + generator content) so the silent-swallow
  failure mode can never return undetected.
</specifics>

<deferred>
## Deferred Ideas

- **New `capability:` ids / new wired mitigations** (e.g. `:pause_queue`, `:set_concurrency`) —
  out of scope; the milestone forbids new runtime code and the registry is a closed allowlist.
  New templates use guidance-only mitigations or reuse the existing three.
- **Generator glob refactor** — replacing explicit `copy_template` calls with a priv-dir glob is
  deliberately not done; keep the explicit per-file model.
- **Adoption / authoring docs that name these templates** — Phase 18 (this phase builds the code
  surfaces those docs will reference).

### Reviewed Todos (not folded)
None — no pending todos matched Phase 17.
</deferred>
