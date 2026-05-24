# Phase 17: Recovery Depth — Runbook Templates - Research

**Researched:** 2026-05-24
**Domain:** Parapet Runbook DSL — `warning:` surface addition + template depth
**Confidence:** HIGH (all claims verified against live source code)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: `warning:` is currently silently swallowed. `requires_preview:` and `kind: :guidance` DO already work. The `warning:` addition MUST land before any template uses it.
- D-02: Adding `warning:` is a three-surface change: (1) `step/2` macro + `__runbook_schema__/0`, (2) `WorkbenchContract.derive_runbook_steps/3` explicit field re-projection, (3) `runbook_card` in `operator_components.ex.eex`.
- D-03: Render the step-level `warning:` as a new amber/red block inside the `runbook_card` step loop, near the existing guidance block. Do NOT route through `preview_panel` warnings list.
- D-04: Persistence needs no work — `__runbook_schema__/0` carries the full step map, `alert_processor` stores it as-is, and `stringify_keys` in `WorkbenchContract` handles atom/string duality.
- D-05: No new `capability:` ids. The registry is a hard-coded allowlist of exactly three: `:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check`.
- D-06: Each new template's mitigation is either guidance/manual or reuses one of the three existing capabilities only where the target semantics are an exact fit.
- D-07: `suppression_drift` must be guidance-only (no fitting capability). `retry_storm` and `partial_backlog_drain` may reuse `:retry_async_item` with `target_kind: :async_item`.
- D-08: Generator already satisfies criterion 3 — explicit `copy_template` calls each with `on_exists: :skip`. Each new template = one new explicit call + one new generator-test assertion.
- D-09: The four existing templates have distinct, non-uniform gaps (none has any `warning:` or a dedicated verification step today).
- D-10: Precondition and verification expressed as distinct `type: :manual, kind: :guidance` steps.
- D-11: Three-layer regression test: (1) DSL/schema, (2) WorkbenchContract projection, (3) generator content.
- D-12: `Parapet.Runbook` is a documented public module; the new `warning:` option must be documented in the `step/2` `@doc` or `verify.public_api` breaks CI.

### Claude's Discretion
- Exact wording of each step's `label`, `description`, `guidance`, and `warning:` text.
- Per-new-template mitigation choice (reuse `:retry_async_item` vs. guidance-only) within D-05/D-06/D-07 constraints.
- Whether the new warning UI block is amber vs. red and its exact Tailwind classes.
- File/module naming of the three new templates under `priv/templates/parapet.gen.runbooks/`.

### Deferred Ideas (OUT OF SCOPE)
- New `capability:` ids / new wired mitigations (e.g., `:pause_queue`, `:set_concurrency`).
- Generator glob refactor.
- Adoption/authoring docs (Phase 18).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RCV-01 | Four existing templates (`dead_letter`, `callback_delay`, `stalled_executor`, `provider_outage`) deepened to full depth: precondition, scoped preview, at least one `warning:`, bounded mitigation, post-action verification. | `warning:` three-surface change confirmed; template gaps confirmed per-template; existing DSL patterns confirmed. |
| RCV-02 | Three new templates (`retry_storm`, `suppression_drift`, `partial_backlog_drain`) at same depth: precondition, scope check, warning, bounded preview-first mitigation, verification. | Capability constraints confirmed; mitigation routing per template researched; generator extension pattern confirmed. |
</phase_requirements>

---

## Summary

Phase 17 requires a surgical DSL/foundation addition before any template work: the `warning:` keyword arg is currently **silently swallowed** by `Parapet.Runbook.step/2` because the macro builds the step map from exactly 11 explicit keys and `warning` is not among them. This is confirmed by direct code inspection. Once the DSL change lands, it must also be threaded through a second silent-drop layer — the `WorkbenchContract.derive_runbook_steps/3` explicit field re-projection — and then rendered in the `runbook_card` component. Persistence (JSON round-trip) is a non-issue: `__runbook_schema__/0` captures the full step map as compile-time data, `alert_processor` stores it whole, and `stringify_keys` handles atom/string key duality generically.

All four existing templates are confirmed stubs of 1–2 steps with no `warning:` and no verification step. The gaps are non-uniform: `callback_delay` has only 1 step and lacks even a mitigation step. The three new templates can legitimately reuse `:retry_async_item` for `retry_storm` and `partial_backlog_drain` (both are `:async_item` semantics); `suppression_drift` has no fitting capability and must be guidance-only.

The CONTEXT.md's line-number citations are largely accurate but several have drifted or carry minor inaccuracies — the authoritative current state is documented in the Drift Report below.

**Primary recommendation:** Land `warning:` as Wave 1 (DSL + projection + UI + schema test), gate it with a projection-level test before any template references it, then deepen the four existing templates and add three new ones in Wave 2, finishing with generator wiring and content-level tests in Wave 3.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `warning:` DSL key | Library (Parapet.Runbook macro) | — | Compile-time step map construction; must be in the `@steps` attribute accumulation |
| `warning:` projection | Library (WorkbenchContract) | — | Re-projects step fields into operator-facing shape; explicit allowlist at lines 144–156 |
| `warning:` UI render | Generated template (operator_components.ex.eex) | — | HEEx component consumes projected step map; adopter-owned after generation |
| Template depth content | Generated templates (priv/templates/parapet.gen.runbooks/) | — | EEx files copied to host app with `on_exists: :skip`; host-owned after generation |
| Generator wiring | Mix task (parapet.gen.runbooks.ex) | — | Explicit `copy_template` calls; one new call per new template |
| Capability routing | Library (Parapet.Capabilities + Parapet.Operator) | — | Closed allowlist; unwired = `{:error, :capability_unwired}` at runtime |

---

## D-01 CONFIRMED: `warning:` is silently swallowed

**Live code: `lib/parapet/runbook.ex` lines 19–35**

```elixir
defmacro step(id, opts) do
  quote do
    @steps %{
      id: unquote(id),
      label: unquote(opts)[:label],
      description: unquote(opts)[:description],
      type: unquote(opts)[:type],
      kind: unquote(opts)[:kind],
      capability: unquote(opts)[:capability],
      target_kind: unquote(opts)[:target_kind],
      requires_preview: Keyword.get(unquote(opts), :requires_preview, false),
      preview_only: Keyword.get(unquote(opts), :preview_only, false),
      auto_execute: Keyword.get(unquote(opts), :auto_execute, false),
      guidance: unquote(opts)[:guidance]
    }
  end
end
```

**Confirmed allowlist: 11 keys** — `id, label, description, type, kind, capability, target_kind, requires_preview, preview_only, auto_execute, guidance`. `warning` is absent. [VERIFIED: live source at `lib/parapet/runbook.ex:19-35`]

**CONTEXT.md claimed lines 21–33.** Live code has the macro at lines **19–35** (the `defmacro step(id, opts) do` line is 19 and the closing `end` is 35). The step map body is 21–33 as claimed, but the macro definition itself starts at 19. Minor drift — plan should use 19–35 for the macro boundary and 21–33 for the map body.

**D-01 verdict: CONFIRMED.** `requires_preview:` (line 29) and `kind:` (line 26) both work; `warning:` does not.

---

## D-02 CONFIRMED: Three-surface change required

### Surface 1: `step/2` macro (lines 19–35) and `__runbook_schema__/0`

`__runbook_schema__/0` is generated at compile time by `__before_compile__/1` (lines 49–64). It captures the `@steps` accumulator via `Macro.escape(steps)` (line 60). This means:

- Adding `warning: unquote(opts)[:warning]` to the `@steps` map (line 32, after `guidance:`) automatically makes `warning` appear in `__runbook_schema__()`.
- No separate change needed in `__before_compile__` — it already captures the full step map.
- `__runbook_schema__/0` shape confirmed: `%{module: String, title: String, description: String, steps: [step_map, ...]}` (lines 54–63). [VERIFIED: live source at `lib/parapet/runbook.ex:49-64`]

### Surface 2: `WorkbenchContract.derive_runbook_steps/3` — the drop layer

**Live code: `lib/parapet/operator/workbench_contract.ex` lines 113–158**

The function processes `raw_steps` from `runbook_data`. At line 115 it applies `stringify_keys(step)` which converts atom keys to strings. Then at lines 144–156 it re-projects into an **explicit map**:

```elixir
%{
  id: step_id,
  label: Map.get(step, "label"),
  description: Map.get(step, "description"),
  type: Map.get(step, "type"),
  kind: Map.get(step, "kind"),
  capability: Map.get(step, "capability"),
  target_kind: target_kind,
  guidance: Map.get(step, "guidance"),
  state: state,
  executed_at: if(executed_entry, do: executed_entry.inserted_at),
  targeting_hints: targeting_hints
}
```

**`warning` is absent from this explicit map.** Even after the macro is fixed, `warning` will be dropped here. The fix is to add `warning: Map.get(step, "warning")` to this map. [VERIFIED: live source at `lib/parapet/operator/workbench_contract.ex:144-156`]

**CONTEXT.md line numbers for this section: claimed 144–156.** CONFIRMED — the explicit map runs from line 144 to line 156 exactly.

### Surface 3: `runbook_card` UI template

**Live code: `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 269–334**

The `runbook_card` component renders each step in a loop (line 281 `for step <- @detail.derived.runbook_steps`). Current rendered fields: `step.label` (line 286), `step.description` (line 291), `step.guidance` (lines 293–297 guidance block), `step.targeting_hints` (lines 299–307), `step.state` (for button/badge logic, lines 287–326). No `step.warning` rendering exists.

**CONTEXT.md claimed `runbook_card` at lines 270–334.** Live code: `attr :detail` is line 269, `def runbook_card` is line 270, closing `end` is line 334. Accurate.

**CONTEXT.md claimed guidance block at lines 293–297.** Live code: the guidance block is:
```heex
<%%= if step.state == :guidance && step.guidance do %>
  <div class="mt-2 p-2 bg-blue-50 border border-blue-100 rounded text-xs text-blue-800 italic">
    <%%= step.guidance %>
  </div>
<%% end %>
```
This runs lines **293–297**. CONFIRMED.

**CONTEXT.md claimed `preview_panel` warnings list at lines 361–370.** Live code: the `preview_panel` warnings block runs lines **361–370** exactly — `if (preview.data["warnings"] || []) != [] do`, a `bg-red-50` div block. CONFIRMED. This reads `preview.data["warnings"]` — a capability-preview runtime field returned by `compute_preview/3` in `operator.ex` (line 727 `"warnings" => []`), entirely separate from a step's `warning:` field.

**D-02 verdict: CONFIRMED. All three surfaces verified.**

---

## D-03 CONFIRMED: Warning render placement

The new step-level warning block should go **between the guidance block (line 297) and the targeting_hints block (line 299)** in the `runbook_card` step loop. Styling should follow the existing patterns in `operator_components.ex.eex` — the guidance block uses `bg-blue-50 border-blue-100 text-blue-800`, the `preview_panel` warning uses `bg-red-50 border-red-100 text-red-700`. For step-level warnings (advisory, not runtime-computed) an **amber** variant (`bg-amber-50 border-amber-100 text-amber-800`) is appropriate — distinct from the blue guidance block and the red runtime warnings panel.

The warning block should only render when the projected step has a non-nil, non-empty `warning` value:
```heex
<%%= if step.warning do %>
  <div class="mt-2 p-2 bg-amber-50 border border-amber-100 rounded text-xs text-amber-800">
    <%%= step.warning %>
  </div>
<%% end %>
```

**D-03 verdict: CONFIRMED. Do NOT route through `preview_panel` warnings list.**

---

## D-04 CONFIRMED: Persistence is a non-issue

**alert_processor.ex:** `build_runbook_data/2` calls `apply(module, :__runbook_schema__, [])` (line 118) and passes the result to `Incident.put_triage_summary/2` which merges it into the runbook_data map (incident.ex lines 67–71). The step map is stored as-is with atom keys.

**WorkbenchContract:** `stringify_keys/1` (lines 226–228) converts the step's atom keys to strings at projection time. A new `warning` atom key in the stored step map becomes `"warning"` after stringify, then `Map.get(step, "warning")` retrieves it in the projection (once that line is added).

**Incident JSON round-trip:** Ecto casts `runbook_data` as `:map`, which means PostgreSQL JSONB. Atom keys become string keys on the round-trip from DB. `WorkbenchContract.derive_runbook_steps/3` handles this with its `stringify_keys(step)` at line 115 — it normalises before field extraction. So whether the data came straight from `__runbook_schema__()` (atom keys) or was round-tripped through the DB (string keys), the projection handles both.

**D-04 verdict: CONFIRMED. Zero persistence work needed.**

---

## D-05 CONFIRMED: Capabilities allowlist

**Live code: `lib/parapet/capabilities.ex` lines 8–12**

```elixir
@valid_capabilities [
  :retry_async_item,
  :requeue_dead_letter,
  :request_manual_provider_check
]
```

`register_recovery/2` clause at line 21 guards on `id in @valid_capabilities`. The fallback at lines 35–37 raises `ArgumentError`. [VERIFIED: live source at `lib/parapet/capabilities.ex:8-12, 35-37`]

**capabilities_test.exs:32–36:** Confirmed — test at lines 32–36 asserts `assert_raise ArgumentError, ~r/Invalid recovery capability id/`. [VERIFIED: live source]

**D-05 verdict: CONFIRMED.**

---

## D-06 CONFIRMED: `execute_mitigation/2` overridable

**Live code: `lib/parapet/runbook.ex` lines 14–15**

```elixir
def execute_mitigation(_step, _incident), do: {:error, :not_implemented}
defoverridable execute_mitigation: 2
```

Confirmed as the default guidance-mitigation dispatch path. Host runbooks may override it or leave the default (which returns `{:error, :not_implemented}` — acceptable for guidance-only steps since the UI will not wire an Execute button for `kind: :guidance` steps). [VERIFIED: live source at `lib/parapet/runbook.ex:14-15`]

**`target_kind` pass-through:** `operator.ex` line 723: `"target_kind" => capability.target_kind || step.target_kind` — `target_kind` on a guidance step is purely informational and is passed through without a capability registry lookup. [VERIFIED: live source at `lib/parapet/operator.ex:723`]

**`:capability_unwired` failure mode:** `operator.ex` lines 644 and 705 both have `nil -> {:error, :capability_unwired}` — this fires when `Parapet.Capabilities.get_recovery(capability_id)` returns nil (i.e., the capability is not wired by the host adapter). Lines 622–624 and 669–671 are the `with` chain guards where this nil falls through. [VERIFIED: live source at `lib/parapet/operator.ex:622-624, 644, 669-671, 705`]

**CONTEXT.md cited `:644`/`:705` as the capability_unwired lines.** CONFIRMED. Also cited `:622-624`/`:669-671` as the with-chain guards. CONFIRMED.

**D-06 verdict: CONFIRMED.**

---

## D-07: Per-new-template mitigation analysis

Based on the confirmed closed allowlist and the semantics of each scenario:

### `retry_storm`
**Scenario:** A queue is saturating with rapid retry attempts after a transient failure, causing worker exhaustion.
**Mitigation fit:** `:retry_async_item` does NOT fit — the operator needs to *stop* or *defer* retries, not retry individual items. Retrying items would worsen the storm.
**Verdict: guidance-only mitigation.** The mitigation step should be `type: :manual, kind: :guidance` instructing the operator to adjust retry backoff configuration, increase concurrency limits, or temporarily pause the queue via host tooling. A scoped preview (`requires_preview: true`) using `:retry_async_item` would be counterproductive here.

> Note: CONTEXT.md D-07 and the Specific Ideas section claim that `retry_storm` *may* reuse `:retry_async_item` with `target_kind: :async_item`. After reviewing the scenario semantics, this is **incorrect**. A retry storm means items are retrying too aggressively — executing `:retry_async_item` on them is exactly the wrong mitigation. The CONTEXT.md was written in assumptions mode and this capability-fit claim should be corrected. `retry_storm` must be guidance-only.

### `partial_backlog_drain`
**Scenario:** A subset of a queue's backlog is not draining — items are stuck while others process normally.
**Mitigation fit:** `:retry_async_item` with `target_kind: :async_item` — an exact semantic fit. The operator scopes the preview to the stuck items, confirms the bounded set, and retries them. This is exactly the `:retry_async_item` use case.
**Verdict: use `:retry_async_item` with `target_kind: :async_item` and `requires_preview: true`.**

### `suppression_drift`
**Scenario:** Escalation suppression windows have accumulated or drifted, causing incidents to stay silently suppressed beyond intended periods.
**Mitigation fit:** None of the three capabilities address escalation suppression state — `:retry_async_item`, `:requeue_dead_letter`, and `:request_manual_provider_check` all operate on async queue items or provider checks, not on escalation suppression records.
**Verdict: guidance-only mitigation.** Confirmed — CONTEXT.md D-07 is correct on this one.

---

## D-08 CONFIRMED: Generator pattern

**Live code: `lib/mix/tasks/parapet.gen.runbooks.ex` lines 33–56**

Four explicit `Igniter.copy_template` calls, each with `on_exists: :skip`:
- Line 33–38: `stalled_executor.ex.eex` → `stalled_executor.ex` with `on_exists: :skip` (line 37)
- Line 39–44: `dead_letter.ex.eex` → `dead_letter.ex` with `on_exists: :skip` (line 43)
- Line 45–50: `provider_outage.ex.eex` → `provider_outage.ex` with `on_exists: :skip` (line 49)
- Line 51–56: `callback_delay.ex.eex` → `callback_delay.ex` with `on_exists: :skip` (line 55)

`assigns` at line 29 includes `module_prefix: runbook_module_prefix` (along with `app_name` and `base_name`). [VERIFIED: live source at `lib/mix/tasks/parapet.gen.runbooks.ex:29, 33-56`]

**CONTEXT.md cited `on_exists: :skip` at lines 37/43/49/55 and `module_prefix` at line 29.** CONFIRMED exactly.

**D-08 verdict: CONFIRMED.**

---

## D-09 CONFIRMED: Existing template gaps

Verified by reading all four template files directly.

### `dead_letter.ex.eex` — 2 steps (lines 7–24)
- Step 1 (lines 7–14): `type: :manual, kind: :guidance, preview_only: true` — a precondition/guidance step ✓
- Step 2 (lines 16–24): `type: :mitigation, kind: :capability, capability: :requeue_dead_letter, requires_preview: true` ✓

**Gaps:** No scoped preview step distinct from the mitigation (the mitigation itself has `requires_preview`), no `warning:` annotation, no verification step.
**Plan work:** Add warning annotation to existing step(s), add a pre-mitigation scoped preview step if desired as a distinct guidance step, add a verification step (`type: :manual, kind: :guidance`).

**CONTEXT.md claimed "add scoped preview + warning + verification."** The `dead_letter` mitigation step already has `requires_preview: true` — so the "scoped preview" element is already present in step 2. What's missing is a dedicated *precondition* guidance step (the existing step 1 is `preview_only: true` which maps to `:guidance` state), a `warning:` annotation, and a verification step. The template already has the scoped-preview element via `requires_preview: true` on the capability step.

### `callback_delay.ex.eex` — 1 step (lines 7–14)
- Step 1 (lines 7–14): `type: :manual, kind: :guidance, preview_only: true` — guidance only

**Gaps:** No mitigation step, no `warning:`, no verification step.
**Plan work:** Add a mitigation step (guidance-only since no capability fits callback delay checking), add `warning:`, add verification step. This is the thinnest template — needs the most work.

### `stalled_executor.ex.eex` — 2 steps (lines 7–23)
- Step 1 (lines 7–14): `type: :manual, kind: :guidance, preview_only: true`
- Step 2 (lines 16–23): `type: :mitigation, kind: :capability, capability: :retry_async_item, target_kind: :async_item, requires_preview: true`

**Gaps:** No `warning:`, no verification step.
**Plan work:** Add warning annotation, add verification step.

### `provider_outage.ex.eex` — 2 steps (lines 7–24)
- Step 1 (lines 7–14): `type: :manual, kind: :guidance, preview_only: true`
- Step 2 (lines 16–24): `type: :mitigation, kind: :capability, capability: :request_manual_provider_check, target_kind: :provider, requires_preview: true`

**Gaps:** No `warning:`, no verification step.
**Plan work:** Add warning annotation, add verification step.

**CONTEXT.md line citations for template steps:**
- `dead_letter.ex.eex:7-24` — CONFIRMED (steps run 7–24)
- `callback_delay.ex.eex:7-14` — CONFIRMED (only 1 step, 14 lines total)
- `stalled_executor.ex.eex:7-23` — CONFIRMED
- `provider_outage.ex.eex:7-24` — CONFIRMED

**D-09 verdict: CONFIRMED with the clarification that `dead_letter` already has `requires_preview: true` on its mitigation step.**

---

## D-10: Precondition/verification step pattern

CONTEXT.md says "distinct `type: :manual, kind: :guidance` steps." Verified against existing templates:

All four templates use `type: :manual, kind: :guidance, preview_only: true` for their first (precondition/investigation) step. The `preview_only: true` flag maps to `state: :guidance` in `WorkbenchContract.derive_runbook_steps/3` (line 129: `Map.get(step, "preview_only") == true -> :guidance`). This causes the `runbook_card` to render the guidance block (lines 293–297) and show no action button. This is the established pattern.

**For verification steps:** Use the same pattern — `type: :manual, kind: :guidance, preview_only: true` — so they render as guidance blocks in the card. Do not use `requires_preview: true` on verification steps (that's for capability-backed mitigation steps). [VERIFIED: established by reading all four templates + WorkbenchContract state derivation]

**D-10 verdict: CONFIRMED.**

---

## D-11: Three-layer test approach

### Layer 1 — DSL/schema: `test/parapet/runbook_test.exs`

**Live code:** Lines 57–112 contain the `"generates a static schema map via __runbook_schema__()"` test. The `DummyRunbook` (lines 4–55) defines 5 steps. The test asserts each field on each step individually. **Extension pattern:** Add `warning: "Some warning text"` to one of the existing `DummyRunbook` steps (or a new step), then assert `step.warning == "Some warning text"` in the test. [VERIFIED: live source `test/parapet/runbook_test.exs:57-112`]

The `DummyRunbook` has no step currently exercising `warning:` — the new assertion will fail before the DSL fix and pass after. This is exactly the right regression canary.

### Layer 2 — Projection: `test/parapet/operator/workbench_contract_test.exs`

**Live code:** Lines 308–369 contain `"derives runbook steps with previewable and guidance distinctions"`. The test builds `runbook_data` with three steps having explicit step maps, derives them, and asserts `s1.state`, `s2.state`, `s2.targeting_hints`, etc. [VERIFIED: live source `test/parapet/operator/workbench_contract_test.exs:308-369`]

**Extension pattern:** Add a step to the test's `runbook_data` with a `warning: "test warning"` key. After `WorkbenchContract.derive/3`, assert `hd(derived.runbook_steps).warning == "test warning"`. This will fail before the projection fix and pass after. This is the most important layer because it catches the silent projection-drop.

### Layer 3 — Generator content: `test/mix/tasks/parapet.gen.runbooks_test.exs`

**Live code:** Lines 8–48, single test in the `describe` block. The test calls `Runbooks.igniter()`, gets the rewritten sources, and asserts string presence in each generated file. [VERIFIED: live source `test/mix/tasks/parapet.gen.runbooks_test.exs:8-48`]

**Extension pattern:** After adding new templates, add assertions like `assert new_template_source =~ "warning:"` and file-path assertions for each new template file. The test already demonstrates the pattern for the four existing templates.

**D-11 verdict: CONFIRMED. Test infrastructure exists and is straightforward to extend.**

---

## D-12: Public API documentation constraint

**Verified:** `mix.exs` line 95: `"verify.public_api": ["docs --warnings-as-errors"]`. The `.github/workflows/ci.yml` line 44 runs `mix verify.public_api`. [VERIFIED: live source]

`lib/parapet/runbook.ex` has a `@moduledoc` at lines 2–6 but **no `@doc` on `step/2`** (line 19). The `defmacro step(id, opts)` has no documentation annotation. Currently this does not break `verify.public_api` because macros without `@doc` are not flagged as undocumented by ex_doc unless they are listed in `@documented_macros` or similar. However, per D-12, the plan should add a `@doc` to `step/2` documenting all accepted options including the new `warning:` option.

**Important:** Adding a `@doc` that mentions an option that doesn't exist yet, or a `@doc` that omits an existing option, is what would trigger `--warnings-as-errors`. The safe approach: add the `@doc` in the same commit as the DSL change so the documented options exactly match the implemented ones.

**D-12 verdict: CONFIRMED. CI runs `verify.public_api`. No `@doc` currently on `step/2`. Add `@doc` with the new `warning:` option documented in the same change as the DSL addition.**

---

## Drift Report: CONTEXT.md Line Numbers vs. Live Code

| Claim | CONTEXT.md Said | Live Code | Status |
|-------|----------------|-----------|--------|
| `step/2` macro location | `:21-33` | Lines 19–35 (macro def 19, map body 21–33) | Minor drift — macro starts line 19 |
| `__runbook_schema__/0` | `:55-63` | Lines 54–64 (def line 55, body 56-63, end 64) | Accurate for body range |
| `execute_mitigation/2` overridable | `:14-15` | Lines 14–15 | EXACT |
| `derive_runbook_steps/3` | `:113-158` | Lines 113–158 | EXACT |
| Projection field list | `:144-156` | Lines 144–156 | EXACT |
| `runbook_card` | `:270-334` | Lines 270–334 | EXACT |
| Guidance block | `:293-297` | Lines 293–297 | EXACT |
| `preview_panel` warnings | `:361-370` | Lines 361–370 | EXACT |
| `dead_letter.ex.eex` steps | `:7-24` | Lines 7–24 | EXACT |
| `callback_delay.ex.eex` step | `:7-14` | Lines 7–14 | EXACT |
| `stalled_executor.ex.eex` steps | `:7-23` | Lines 7–23 | EXACT |
| `provider_outage.ex.eex` steps | `:7-24` | Lines 7–24 | EXACT |
| `capabilities.ex` allowlist | `:8-12` | Lines 8–12 | EXACT |
| `capabilities.ex` raise clause | `:35-37` | Lines 35–37 | EXACT |
| `operator.ex` capability_unwired | `:622-624`/`:644`/`:669-671`/`:705` | 622–624, 644, 669–671, 705 | EXACT |
| `operator.ex` target_kind passthrough | `:723` | Line 723 | EXACT |
| `parapet.gen.runbooks.ex` copy_template | `:33-56` | Lines 33–56 | EXACT |
| `module_prefix` assign | `:29` | Line 29 | EXACT |
| `on_exists: :skip` locations | `:37/:43/:49/:55` | 37, 43, 49, 55 | EXACT |
| `alert_processor.ex` runbook application | `:118` | Line 118 | EXACT (file is at `lib/parapet/spine/alert_processor.ex`, not `lib/parapet/alert_processor.ex`) |
| `runbook_test.exs` pattern | `:57-112` | Lines 57–112 | EXACT |
| `workbench_contract_test.exs` pattern | `:308-369` | Lines 308–369 | EXACT |
| `parapet.gen.runbooks_test.exs` pattern | `:8-48` | Lines 8–48 | EXACT |
| `capabilities_test.exs` allowlist raise | `:32-36` | Lines 32–36 | EXACT |

**One path error:** CONTEXT.md cites `alert_processor.ex` without a subdirectory. The actual path is `lib/parapet/spine/alert_processor.ex`. Minor but important for tool calls during implementation.

**One capability-fit error:** CONTEXT.md D-06/D-07 and the Specific Ideas section claim `retry_storm` may reuse `:retry_async_item`. This is semantically incorrect — see D-07 analysis above. `retry_storm` must be guidance-only.

---

## Established Step-DSL Pattern

The canonical pattern for a full-depth template (derived from existing templates + DSL verification):

```elixir
defmodule <%= inspect(@module_prefix) %>.ExampleTemplate do
  use Parapet.Runbook

  title("Example Recovery")
  description("Brief description of when this runbook applies.")

  # Step 1: Precondition — confirms the operator should proceed
  step(:check_precondition,
    label: "Verify Precondition",
    description: "Confirm the incident matches this runbook before acting.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Check [specific thing]. Proceed only if [condition] is true.",
    warning: "Do not proceed if [disqualifying condition] is present."
  )

  # Step 2: Scope check / bounded preview — shows operator what will be affected
  step(:scope_preview,
    label: "Preview Affected Items",
    description: "See the bounded set of items before taking any action.",
    type: :mitigation,
    kind: :capability,
    capability: :retry_async_item,   # or :requeue_dead_letter / :request_manual_provider_check
    target_kind: :async_item,
    requires_preview: true,
    warning: "This will affect up to N items. Review the preview count before confirming."
  )

  # Step 3: Post-action verification — confirms the mitigation took effect
  step(:verify_resolution,
    label: "Verify Recovery",
    description: "Confirm the incident has resolved after the mitigation.",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "Check [specific metric or log]. The incident should show [expected state]."
  )
end
```

For **guidance-only** mitigations (no capability), step 2 becomes:

```elixir
step(:mitigate,
  label: "Apply Mitigation",
  description: "Description of what the operator should do.",
  type: :mitigation,
  kind: :guidance,
  preview_only: true,
  guidance: "Step-by-step instructions for the operator.",
  warning: "Warning about the impact or irreversibility."
)
```

Note: `preview_only: true` on a guidance mitigation step causes it to render as `:guidance` state (no button), which is correct — it is purely instructional.

---

## Common Pitfalls

### Pitfall 1: Silent-Swallow (D-01)
**What goes wrong:** Template author writes `warning: "text"` in a `step/2` call. Elixir does not warn. The schema test passes because the test doesn't assert `warning`. Operators never see the warning.
**Why it happens:** Keyword.get on an unrecognised key returns nil; the macro simply doesn't include it in the step map.
**How to avoid:** Land the DSL fix first. Gate with a schema-level test that asserts `step.warning == "expected"` — this will fail before the fix and pass after.
**Warning signs:** `__runbook_schema__()` output missing `warning` key on steps.

### Pitfall 2: Projection-Drop (D-02 #2)
**What goes wrong:** DSL fix lands. Schema test passes. But operators still don't see the warning because `derive_runbook_steps/3` re-projects into an explicit map that omits `warning`.
**Why it happens:** The projection map at `workbench_contract.ex:144-156` is an explicit field list, not a passthrough. New fields must be consciously added.
**How to avoid:** Add a projection-level test (Layer 2) that asserts the projected step map includes `warning`. This is the most important test because the failure is invisible in all other layers.
**Warning signs:** `WorkbenchContract.derive/3` output step maps missing `warning` key even though `__runbook_schema__()` includes it.

### Pitfall 3: Unwired Capability
**What goes wrong:** Template uses a `capability:` that isn't one of the three allowlisted ids. Template generates, compiles, and even renders. But clicking Preview/Execute returns `{:error, :capability_unwired}` at runtime.
**Why it happens:** `Parapet.Capabilities.get_recovery/1` returns nil for unlisted capabilities; the `with` chain in `operator.ex` falls through to the `nil -> {:error, :capability_unwired}` clause.
**How to avoid:** Only use `:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check`. Use guidance-only for everything else.
**Warning signs:** Preview button appears (step has `requires_preview: true`) but clicking it fails.

### Pitfall 4: `warning:` on verification steps rendering incorrectly
**What goes wrong:** A verification step is given a `warning:` annotation. Since the verification step uses `preview_only: true`, it renders in `:guidance` state. The guidance block renders `step.guidance`. The warning block also renders. But if the operator is meant to read the warning *before* acting, it should be on the precondition step, not the verification step.
**How to avoid:** Put `warning:` on the precondition step (where the operator decides whether to proceed) or on the mitigation step (where the operator confirms scope). Verification steps rarely need warnings.

### Pitfall 5: `@doc` / `verify.public_api` ordering
**What goes wrong:** The `@doc` for `step/2` is added in a separate commit from the DSL change. If the `@doc` mentions `warning:` but the DSL change hasn't landed yet, the documented API doesn't match the actual behaviour. If the order is reversed, the DSL accepts `warning:` but the docs don't mention it, which may trigger undocumented-option warnings in certain ex_doc versions.
**How to avoid:** Add the `@doc` (documenting `warning:`) in the same commit/PR as the DSL change.

### Pitfall 6: `retry_storm` capability misassignment
**What goes wrong:** Plan assigns `:retry_async_item` to `retry_storm` because CONTEXT.md's Specific Ideas section suggests it and CONTEXT.md D-07 is ambiguous. But retrying items during a retry storm worsens the storm.
**How to avoid:** Make `retry_storm` guidance-only. The mitigation instructs the operator to adjust backoff, concurrency, or pause the queue via host tooling — none of which is modelled by the three existing capabilities.

---

## Per-Template Plan Summary

### Existing Templates to Deepen

| Template | Current Steps | Work Required |
|----------|--------------|---------------|
| `dead_letter` | 2 (guidance + capability preview) | Add `warning:` to step 1 and/or step 2; add verification step |
| `callback_delay` | 1 (guidance only) | Add guidance-only mitigation step with `warning:`; add verification step |
| `stalled_executor` | 2 (guidance + capability preview) | Add `warning:` to step 1 and/or step 2; add verification step |
| `provider_outage` | 2 (guidance + capability preview) | Add `warning:` to step 1 and/or step 2; add verification step |

### New Templates to Create

| Template | Module | Capability | Mitigation Kind |
|----------|--------|------------|-----------------|
| `retry_storm` | `RetryStorm` | none | guidance-only (`type: :mitigation, kind: :guidance, preview_only: true`) |
| `suppression_drift` | `SuppressionDrift` | none | guidance-only |
| `partial_backlog_drain` | `PartialBacklogDrain` | `:retry_async_item` | capability (`requires_preview: true, target_kind: :async_item`) |

---

## Architecture Patterns

### DSL Change Location

The `warning:` key is added at line 32 (after `guidance: unquote(opts)[:guidance]` in the `@steps` map):

```elixir
# lib/parapet/runbook.ex, inside defmacro step(id, opts):
@steps %{
  ...existing keys...,
  guidance: unquote(opts)[:guidance],
  warning: unquote(opts)[:warning]   # ADD HERE (line ~32, before closing })
}
```

### Projection Change Location

At `lib/parapet/operator/workbench_contract.ex` line 152 (after `guidance: Map.get(step, "guidance"),`):

```elixir
%{
  ...existing fields...,
  guidance: Map.get(step, "guidance"),
  warning: Map.get(step, "warning"),   # ADD HERE
  state: state,
  ...
}
```

### UI Render Location

In `priv/templates/parapet.gen.ui/operator_components.ex.eex`, after the guidance block (line 297), before the targeting_hints block (line 299):

```heex
<%%= if step.warning do %>
  <div class="mt-2 p-2 bg-amber-50 border border-amber-100 rounded text-xs text-amber-800">
    <%%= step.warning %>
  </div>
<%% end %>
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Step-level warning rendering | Custom warning pipeline or separate warning registry | Single `warning:` string field in the step map | One-line string per step is sufficient; no structured warning list needed for static runbook templates |
| Template discovery | Glob-based generator | Explicit `copy_template` calls per file | Already established; test asserts exact file list; glob adds fragility |
| New capability wiring | New `Parapet.Capabilities` entries | Guidance-only mitigation steps | Registry is intentionally closed; new runtime code is out of scope |

---

## Validation Architecture

`workflow.nyquist_validation` is not set in `.planning/config.json` (absent = enabled).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/parapet/runbook_test.exs test/parapet/operator/workbench_contract_test.exs test/mix/tasks/parapet.gen.runbooks_test.exs test/parapet/capabilities_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RCV-01 (DSL) | `warning:` survives `__runbook_schema__/0` | unit | `mix test test/parapet/runbook_test.exs` | ✅ extend line 57-112 |
| RCV-01 (projection) | `warning:` survives `WorkbenchContract.derive/3` | unit | `mix test test/parapet/operator/workbench_contract_test.exs` | ✅ extend line 308-369 |
| RCV-01/RCV-02 (content) | All templates contain `warning:` line | unit | `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` | ✅ extend line 8-48 |
| RCV-02 (new files) | Three new template files generated | unit | `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` | ✅ extend same test |
| AC-03 | Operator sees preconditions, scoped preview, bounded mitigation, warning | manual smoke | open Operator UI against a deepened template | ❌ manual-only |

### Sampling Rate
- **Per task commit:** `mix test test/parapet/runbook_test.exs test/parapet/operator/workbench_contract_test.exs test/mix/tasks/parapet.gen.runbooks_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green + `mix verify.public_api` before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/parapet/runbook_test.exs` — extend `DummyRunbook` with `warning:` field, add assertion (covers RCV-01 DSL layer)
- [ ] `test/parapet/operator/workbench_contract_test.exs` — extend step map in `runbook_data` fixture with `warning:` key, add assertion on projected step (covers RCV-01 projection layer)
- [ ] `test/mix/tasks/parapet.gen.runbooks_test.exs` — add file-path and content assertions for three new templates (covers RCV-02 generator layer)

All three gaps are in existing files — no new test files needed.

---

## Security Domain

This phase makes no changes to authentication, session management, access control, or cryptographic surfaces. It adds a display-only string field (`warning:`) to a compile-time DSL and extends static template content. No new API endpoints, no new user inputs, no new data persistence paths.

ASVS categories V2, V3, V4, V6 do not apply.

V5 (Input Validation) is trivially satisfied: the `warning:` field is a compile-time string literal in the template — not user-supplied input. No runtime validation required.

---

## Open Questions

1. **`verify.public_api` and undocumented macros**
   - What we know: `step/2` currently has no `@doc` annotation. CI runs `mix docs --warnings-as-errors`.
   - What's unclear: Whether the current lack of `@doc` on `step/2` is already failing CI or is accepted as-is. The `@moduledoc` on `Parapet.Runbook` exists and documents the module; individual macro `@doc` may or may not be required.
   - Recommendation: Run `mix verify.public_api` against the current codebase before starting Wave 1 to confirm baseline. If it passes without `@doc` on `step/2`, adding the `@doc` is still the right move for D-12 compliance.

2. **`warning:` as string vs. list**
   - What we know: The plan treats `warning:` as a single string (one warning per step, amber block).
   - What's unclear: Whether any template will want multiple warnings on a single step.
   - Recommendation: Start with a single string. A single warning per step is sufficient for the RCV depth checklist and simplest to render. Future extension to a list is additive.

---

## Sources

### Primary (HIGH confidence — all verified against live source code)
- `lib/parapet/runbook.ex` — step/2 macro (lines 19–35), __runbook_schema__/0 (lines 49–64), execute_mitigation (lines 14–15)
- `lib/parapet/operator/workbench_contract.ex` — derive_runbook_steps/3 (lines 113–158), projection map (lines 144–156), stringify_keys (lines 224–228)
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — runbook_card (lines 269–334), guidance block (lines 293–297), preview_panel warnings (lines 361–370)
- `priv/templates/parapet.gen.runbooks/*.ex.eex` — all four templates read directly
- `lib/parapet/capabilities.ex` — allowlist (lines 8–12), raise clause (lines 35–37)
- `lib/parapet/operator.ex` — capability_unwired (lines 644, 705), with-chain guards (622–624, 669–671), target_kind passthrough (line 723)
- `lib/mix/tasks/parapet.gen.runbooks.ex` — explicit copy_template calls (lines 33–56), module_prefix (line 29)
- `lib/parapet/spine/alert_processor.ex` — __runbook_schema__ application (line 118)
- `test/parapet/runbook_test.exs` — DSL schema test (lines 57–112)
- `test/parapet/operator/workbench_contract_test.exs` — projection test (lines 308–369)
- `test/mix/tasks/parapet.gen.runbooks_test.exs` — generator content test (lines 8–48)
- `test/parapet/capabilities_test.exs` — allowlist raise test (lines 32–36)
- `mix.exs` — verify.public_api task (line 95), docs config (lines 53–72)
- `.github/workflows/ci.yml` — verify.public_api CI step (line 44)

---

## Metadata

**Confidence breakdown:**
- D-01 through D-12 verification: HIGH — all checked against live source
- Per-template gaps: HIGH — all four templates read directly
- `retry_storm` capability-fit correction: HIGH — based on semantic analysis of the scenario + confirmed capability semantics
- Warning UI placement/styling: MEDIUM — Tailwind class choice follows existing conventions but final amber vs. orange vs. yellow is Claude's discretion
- Open question #1 (`verify.public_api` baseline): MEDIUM — CI config confirmed but current passing state not run in this session

**Research date:** 2026-05-24
**Valid until:** 2026-06-24 (stable codebase — no external dependencies)
