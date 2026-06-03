# Phase 27: Prebuilt Playbooks - Research

**Researched:** 2026-05-28
**Domain:** Elixir EEx template authoring + Igniter generator wiring + ExUnit content assertions
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- D-01: Author exactly two net-new EEx templates: `deploy_tied_incident.ex.eex` (suffix `DeployTiedIncident`, PB-05) and `cardinality_blowout.ex.eex` (suffix `CardinalityBlowout`, PB-06).
- D-02: Reuse all four existing templates unchanged (no renames): `stalled_executor.ex.eex`, `dead_letter.ex.eex`, `retry_storm.ex.eex`, `suppression_drift.ex.eex`.
- D-03: Guidance-only templates carry no `capability:` key — structural absence is the guarantee.
- D-04: Harden `suppression_drift.ex.eex` warning to explain *why* automated clearing is unsafe (mass-trigger escalations or re-suppress incorrectly). Lightly reinforce `retry_storm.ex.eex` warning.
- D-05: Wire two new templates into the existing `mix parapet.gen.runbooks` task via two `Igniter.copy_template(...)` calls, `on_exists: :skip`.
- D-06: Do NOT build a per-template-selectable CLI (Phase 29 ADOP-01).
- D-07: New capability templates reference atoms only (`:revert_feature_flag`, `:disable_metric_label`), never a host module.
- D-08: No reference `Parapet.Recovery` capability impl shipped. Point adopters at Rulestead (PB-05) and cardinality analyzer (PB-06) via warning/comment text.
- D-09: Preview→Confirm proof is structural only in Phase 27: `requires_preview: true` + `target_kind:` + `warning:`. Runnable demo is Phase 28.
- D-10: No demo data seeding in Phase 27.
- D-11: Extend `test/mix/tasks/parapet.gen.runbooks_test.exs` with content assertions for the two new templates, mirroring the existing shape.
- D-12: No `mix.exs` changes, no new deps, no DSL changes.
- D-13: No DSL changes — templates use existing `use Parapet.Runbook` unchanged.

### Claude's Discretion

- Exact `warning:`/`guidance:` prose for the two new templates and the reframed `suppression_drift` warning.
- Exact step ids, labels, descriptions, and step count (should mirror 3-step investigate → mitigate → verify shape).
- Whether the moduledoc wiring pointer lives in `@moduledoc`, a comment, or step `guidance:` text.
- Exact `target_kind:` atom for the two new capability steps (e.g., `:feature_flag` / `:metric_label`).

### Deferred Ideas (OUT OF SCOPE)

- Runnable demo scenario / seed — Phase 28.
- CI lane for the recovery loop — Phase 28.
- Per-template-selectable generator (`mix parapet.gen.runbook <name>`) — Phase 29 ADOP-01.
- Shipped reference `Parapet.Recovery` capability impl — Phase 28/29.
- `mix parapet.doctor` adoption-signal check — Phase 29 ADOP-02.
- `Parapet.Recovery` Experimental → Stable graduation — Phase 29 STAB-07.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PB-01 | Retry Storm ships as guidance-only with explicit warning explaining why | Existing `retry_storm.ex.eex` verified; warning at line 14 confirmed present; hardening is text-only |
| PB-02 | Suppression Drift ships as guidance-only with architectural rationale documented | Existing `suppression_drift.ex.eex` verified; warning lines 14, 24 confirmed; reframing needed per D-04 |
| PB-03 | Stalled Async ships with `:retry_async_item` capability step | Existing `stalled_executor.ex.eex` verified; correct shape confirmed |
| PB-04 | Dead-Letter Drain ships with `:requeue_dead_letter` capability step | Existing `dead_letter.ex.eex` verified; correct shape confirmed |
| PB-05 | Deploy-Tied Incident ships with `:revert_feature_flag` capability step; Rulestead as example | New template needed; atom confirmed in `@valid_capabilities`; 3-step shape from analogs |
| PB-06 | Cardinality Blowout ships with `:disable_metric_label` capability step; cardinality analyzer as example | New template needed; atom confirmed in `@valid_capabilities`; 3-step shape from analogs |
</phase_requirements>

---

## Summary

Phase 27 is a small, well-bounded template-authoring phase. Six verification passes against the live codebase confirm that every CONTEXT.md assumption is accurate. The two net-new EEx templates copy an exact, tested 3-step shape from `stalled_executor.ex.eex` and `dead_letter.ex.eex`. The generator task is a flat `Igniter.copy_template` chain — two new calls append cleanly at line 109. The generator test is a single `test` block with per-template `Rewrite.source!` + content-assertion blocks; the new templates extend this pattern identically. No DSL, schema, dep, or operator-path changes are required.

The only content judgment calls are: (a) prose for the two new templates' `warning:`/`guidance:` fields and `suppression_drift` reframe, (b) the `target_kind:` atom for each new step, and (c) where to place the wiring-pointer comment (D-08). Everything else is mechanical mirroring.

**Primary recommendation:** Author the two new templates to exactly mirror `stalled_executor.ex.eex` structure. Append two `Igniter.copy_template` calls to the generator. Add two content-assertion blocks to the single `test "creates fixed runbook files..."` block. Harden `suppression_drift` warning inline. One coherent PR.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Template EEx authoring | `priv/templates/` | — | Host-owned runbook modules; template is static text, no runtime logic |
| Generator wiring | `lib/mix/tasks/parapet.gen.runbooks.ex` | — | Igniter task owns the copy-template chain |
| Capability atom resolution | `lib/parapet/capabilities.ex` (Agent) | Host app (registration) | Allowlist guard is at `register_recovery/2`, not at template compile time |
| Preview→Confirm rendering | `lib/parapet/operator.ex` (untouched) | Host LiveView | Phase 27 only declares the step shape; operator path already handles it |
| Test assertions | `test/mix/tasks/parapet.gen.runbooks_test.exs` | — | Content assertions via `Igniter.Test` / `Rewrite.source!` |

---

## Verification Results

### Check 1: `lib/parapet/runbook.ex` DSL — CONFIRMED [VERIFIED: codebase]

The `step/2` macro (line 45) accepts exactly the documented opts:

| Opt | Present | Notes |
|-----|---------|-------|
| `:kind` | Yes | `:guidance` or `:capability` |
| `:capability` | Yes | atom, nil if not set |
| `:target_kind` | Yes | atom or string, nil if not set |
| `:requires_preview` | Yes | default `false` |
| `:preview_only` | Yes | default `false` |
| `:guidance` | Yes | nil if not set |
| `:warning` | Yes | nil if not set |
| `:type` | Yes | `:manual` or `:mitigation` |
| `:auto_execute` | Yes | default `false` |

**No allowlist validation of `capability:` exists in `runbook.ex`** — the macro stores the atom verbatim. Templates compile regardless of allowlist membership. [VERIFIED: codebase]

Note: `lib/parapet/runbook.ex:36` docs list `capability` as accepting `:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check` — this is stale doc copy from before Phase 24 widened the allowlist. The two new atoms are valid at registration time; the doc text does not affect compilation. Planner should note this doc text may warrant a comment or doc update (minor, discretionary).

### Check 2: `lib/parapet/capabilities.ex` — CONFIRMED [VERIFIED: codebase]

`@valid_capabilities` (lines 14–20) contains all five atoms:
```
:retry_async_item
:requeue_dead_letter
:request_manual_provider_check
:revert_feature_flag        ← PB-05 new template atom
:disable_metric_label       ← PB-06 new template atom
```

Allowlist guard is at `register_recovery/2` line 29: `when id in @valid_capabilities`. No guard exists in `runbook.ex`. Templates referencing these atoms compile cleanly; enforcement fires only at host registration time. [VERIFIED: codebase]

### Check 3: Capability template shape (`stalled_executor.ex.eex`, `dead_letter.ex.eex`) — CONFIRMED [VERIFIED: codebase]

**EEx module header:**
```elixir
defmodule <%= inspect(@module_prefix) %>.<Suffix> do
  use Parapet.Runbook
  title("...")
  description("...")
```

**3-step pattern** (same in both analogs):

| Step | `type:` | `kind:` | `capability:` | `requires_preview:` | `preview_only:` | `warning:` |
|------|---------|---------|---------------|--------------------|-----------------| -----------|
| investigate | `:manual` | `:guidance` | — | — | `true` | present (stalled); in guidance on dead_letter |
| mitigate | `:mitigation` | `:capability` | atom | `true` | — | present |
| verify | `:manual` | `:guidance` | — | — | `true` | — |

The investigate step in `stalled_executor` carries `warning:` directly. In `dead_letter`, the warning is on the guidance step and also on the mitigate step. Either placement is acceptable — planner picks.

**`target_kind:` value:** Both existing capability templates use `:async_item`. New templates should use a domain-appropriate atom (discretionary per D-08): `:feature_flag` and `:metric_label` are idiomatic.

### Check 4: Guidance-only template shape (`retry_storm.ex.eex`, `suppression_drift.ex.eex`) — CONFIRMED [VERIFIED: codebase]

Every step: `kind: :guidance, preview_only: true`. No `capability:` key anywhere. Both have 3 steps (assess / reduce / verify; identify / clear / verify).

**`retry_storm.ex.eex` warning (line 14):** "Do not apply retry-accelerating mitigations during a storm — executing retries on storming items will worsen worker exhaustion and extend the incident." — already strong. D-04 says lightly reinforce; minimal edit or leave as-is satisfies PB-01.

**`suppression_drift.ex.eex` warnings (lines 14, 24):**
- Line 14: "Suppressions older than expected may be silently blocking incident escalations — do not dismiss this runbook without reviewing the full suppression list, as impacted incidents will not have escalated to on-call."
- Line 24: "Clearing a suppression may immediately trigger escalation for the affected incident — ensure on-call is aware and ready to respond before proceeding."

Both warnings focus on on-call readiness, NOT on why automated clearing is architecturally unsafe. D-04 requires adding/reframing a warning explaining the guidance-only rationale: automated clearing could mass-trigger escalations or re-suppress incorrectly. The planner must add this to the step 2 warning (or as a new warning on step 1). PB-02 success criterion is not met by current text. [VERIFIED: codebase]

### Check 5: Generator task (`lib/mix/tasks/parapet.gen.runbooks.ex`) — CONFIRMED [VERIFIED: codebase]

The task is a flat `Igniter.copy_template` pipe chain (lines 32–109) followed by `Igniter.add_notice`. Currently generates 7 templates. The exact call shape:

```elixir
|> Igniter.copy_template(
  Path.join([:code.priv_dir(:parapet), "templates", "parapet.gen.runbooks", "<file>.ex.eex"]),
  Path.join([lib_dir, "<file>.ex"]),
  assigns,
  on_exists: :skip
)
```

`assigns` = `[app_name: app_name, base_name: base_name, module_prefix: runbook_module_prefix]`

`lib_dir` = `Path.join(["lib", "#{app_name}", "parapet", "runbooks"])`

The two new calls append between line 109 and `Igniter.add_notice`. No other code changes needed in this file.

### Check 6: Generator test (`test/mix/tasks/parapet.gen.runbooks_test.exs`) — CONFIRMED [VERIFIED: codebase]

**Structure:** One `describe` block, one `test` block. All assertions live in the single test. Pattern for each template:

```elixir
# File presence assertion (line 15-43):
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/<file>.ex"))

# Content assertions (line 44-99):
<name>_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/<file>.ex")
  |> Rewrite.Source.get(:content)

assert <name>_source =~ "defmodule Test.Parapet.Runbooks.<Suffix> do"
assert <name>_source =~ "capability: :<atom>"   # capability templates only
assert <name>_source =~ "warning:"
```

Guidance-only templates (`retry_storm`, `suppression_drift`) assert only `defmodule ...` + `warning:`. Capability templates additionally assert the `capability:` atom string. The new templates extend this with:

```elixir
# File presence:
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/deploy_tied_incident.ex"))
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/cardinality_blowout.ex"))

# Content:
deploy_tied_incident_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/deploy_tied_incident.ex")
  |> Rewrite.Source.get(:content)
assert deploy_tied_incident_source =~ "defmodule Test.Parapet.Runbooks.DeployTiedIncident do"
assert deploy_tied_incident_source =~ "capability: :revert_feature_flag"
assert deploy_tied_incident_source =~ "warning:"

cardinality_blowout_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/cardinality_blowout.ex")
  |> Rewrite.Source.get(:content)
assert cardinality_blowout_source =~ "defmodule Test.Parapet.Runbooks.CardinalityBlowout do"
assert cardinality_blowout_source =~ "capability: :disable_metric_label"
assert cardinality_blowout_source =~ "warning:"
```

**Note:** The existing test does NOT compile the generated modules — purely text content assertions. Phase 27 must not deviate from this. [VERIFIED: codebase]

### Check 7: Preview output shape (`lib/parapet/operator.ex`) — CONFIRMED [VERIFIED: codebase]

`compute_preview/3` (line 1003) builds the base preview map with keys: `"capability"`, `"step_id"`, `"target_kind"`, `"target_refs"`, `"count"`, `"preconditions"`, `"warnings"`, `"idempotency_caveats"`, `"expires_at"`, `"preview_token"`, `"target_refs_hash"`. Host `capability.preview.(incident, step)` can merge additional keys.

The template step's `requires_preview: true` signals the operator path to gate execution behind this preview. The template's `target_kind:` value is used as fallback when `capability.target_kind` is nil (line 1010). Phase 27 only needs to declare these keys in the step — the operator path is fully implemented and untouched.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Template variable interpolation | Custom string builder | EEx `<%= inspect(@module_prefix) %>` — already used in all 7 templates |
| Generator file copy with conflict handling | Custom file writer | `Igniter.copy_template/4` with `on_exists: :skip` — already used |
| Test content assertions on generated files | File I/O + string matching | `Igniter.Test.test_project/1` + `Rewrite.source!/2` + `=~` — already used |

---

## Common Pitfalls

### Pitfall 1: `target_kind:` mismatch between template step and generator assign
**What goes wrong:** The step `target_kind:` atom in the template and the `target_kind` in the host's `register_recovery/2` call must match for `compute_preview` to pick up the right value (line 1010 uses `capability.target_kind || step.target_kind`). A mismatch doesn't break Phase 27 (no runtime wiring), but the guidance/warning text should document the intended atom so adopters wire it correctly.
**How to avoid:** Pick `:feature_flag` and `:metric_label` as the `target_kind:` values (idiomatic, matches the capability names) and document them in the template's `guidance:` or moduledoc.

### Pitfall 2: `suppression_drift` warning hardening is on the *mitigate* step, not a new step
**What goes wrong:** Adding a fourth step or restructuring the template breaks the existing test assertion shape (though the existing test only checks `warning:` presence, not step count).
**How to avoid:** Add the guidance-only rationale to the `warning:` of step 2 (`:clear_stale_suppressions`). The existing "Clearing a suppression may immediately trigger escalation" text can be extended inline.

### Pitfall 3: Generator test appends go inside the single existing `test` block
**What goes wrong:** Creating a second `test` block would also work, but mismatches the existing one-test-for-everything convention.
**How to avoid:** Append all new file-presence asserts to the `files` check block and all new content-assertion blocks after line 99, still inside the single `test "creates fixed runbook files..."` block.

### Pitfall 4: `runbook.ex` doc lists only 3 capability atoms
**What goes wrong:** `lib/parapet/runbook.ex` line 36's `@doc` for `capability:` lists only `:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check`. If a reviewer reads only this doc, they might believe the new atoms are invalid.
**How to avoid:** The doc text is informational, not enforced. The real allowlist is in `capabilities.ex`. Optionally update the `runbook.ex` doc to mention all 5 atoms (low-effort, improves accuracy). This is discretionary — no functional impact on Phase 27 deliverables.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, no separate install) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PB-01 | `retry_storm.ex` file generated with `warning:` present | Content assertion | `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` | Exists (line 77–82) |
| PB-02 | `suppression_drift.ex` file generated with `warning:` present (hardened text not currently asserted — see gap below) | Content assertion | same | Exists (line 84–89) |
| PB-03 | `stalled_executor.ex` generated with `capability: :retry_async_item` and `warning:` | Content assertion | same | Exists (line 44–51) |
| PB-04 | `dead_letter.ex` generated with `capability: :requeue_dead_letter` and `warning:` | Content assertion | same | Exists (line 53–59) |
| PB-05 | `deploy_tied_incident.ex` generated; module `DeployTiedIncident`; `capability: :revert_feature_flag`; `warning:` present | Content assertion | same | NOT YET — Wave 0 gap |
| PB-06 | `cardinality_blowout.ex` generated; module `CardinalityBlowout`; `capability: :disable_metric_label`; `warning:` present | Content assertion | same | NOT YET — Wave 0 gap |

### What is Testable in Phase 27 vs Deferred to Phase 28

**Phase 27 testable (generator content assertions):**
- File is generated at the correct path
- Module name contains the correct suffix (`DeployTiedIncident`, `CardinalityBlowout`)
- `capability:` key contains the correct atom literal string
- `warning:` key is present
- `requires_preview: true` — assertable if planner adds it (currently no existing template asserts this field; it can be added)

**Structural proof of Preview→Confirm capability:**
The template declares `requires_preview: true`, `target_kind: :<atom>`, and `warning:`. The operator path at `lib/parapet/operator.ex` already handles these. The structural proof is satisfied by the content assertions above — no runtime test needed in Phase 27.

**Deferred to Phase 28 (not testable in Phase 27):**
- Runnable Preview against a seeded incident (requires demo app + seeded data)
- Confirm execution via the operator LiveView
- E2E Preview→Confirm round-trip for PB-03/PB-04/PB-05/PB-06
- `requires_preview: true` enforcement at the operator level (already implemented; tested in Phase 25/26 tests, not re-tested here)

### Sampling Rate
- **Per task commit:** `mix test test/mix/tasks/parapet.gen.runbooks_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] Two new template files must exist before the test can pass: `priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex` and `priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex` — these are the Phase 27 deliverables, not pre-existing infrastructure gaps. The test + generator wiring + template authoring should land as one atomic task.
- [ ] No framework install needed — ExUnit + Igniter.Test already in the test suite.

*(No conftest / shared fixture gaps — `Igniter.Test` is imported directly in the test file.)*

---

## Standard Stack

No new packages. The standard stack for this phase is the already-installed project stack:

| Library | Version | Purpose |
|---------|---------|---------|
| `igniter` | `~> 0.7.9` | `Igniter.copy_template/4`, `Igniter.Test.test_project/1` |
| `ex_unit` | stdlib | Test assertions |
| EEx | stdlib | Template interpolation |

**No installation step required.**

---

## Code Examples

### New capability template skeleton (mirrors `stalled_executor.ex.eex` exactly)
```elixir
# Source: priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex (verified)
defmodule <%= inspect(@module_prefix) %>.<Suffix> do
  use Parapet.Runbook

  title("...")
  description("...")

  step(:investigate_<name>,
    label: "...",
    description: "...",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "...",
    warning: "..."  # optional on investigate step
  )

  step(:mitigate_<name>,
    label: "...",
    description: "...",
    type: :mitigation,
    kind: :capability,
    capability: :<atom>,
    target_kind: :<kind>,
    requires_preview: true,
    warning: "..."
  )

  step(:verify_recovery,
    label: "Verify Recovery",
    description: "...",
    type: :manual,
    kind: :guidance,
    preview_only: true,
    guidance: "..."
  )
end
```

### Generator call shape (mirrors existing 7 calls)
```elixir
# Source: lib/mix/tasks/parapet.gen.runbooks.ex (verified)
|> Igniter.copy_template(
  Path.join([:code.priv_dir(:parapet), "templates", "parapet.gen.runbooks", "deploy_tied_incident.ex.eex"]),
  Path.join([lib_dir, "deploy_tied_incident.ex"]),
  assigns,
  on_exists: :skip
)
|> Igniter.copy_template(
  Path.join([:code.priv_dir(:parapet), "templates", "parapet.gen.runbooks", "cardinality_blowout.ex.eex"]),
  Path.join([lib_dir, "cardinality_blowout.ex"]),
  assigns,
  on_exists: :skip
)
```

### Test assertion block shape (mirrors existing blocks)
```elixir
# Source: test/mix/tasks/parapet.gen.runbooks_test.exs (verified)
assert Enum.any?(files, &String.contains?(&1, "lib/test/parapet/runbooks/deploy_tied_incident.ex"))

deploy_tied_incident_source =
  Rewrite.source!(igniter.rewrite, "lib/test/parapet/runbooks/deploy_tied_incident.ex")
  |> Rewrite.Source.get(:content)

assert deploy_tied_incident_source =~ "defmodule Test.Parapet.Runbooks.DeployTiedIncident do"
assert deploy_tied_incident_source =~ "capability: :revert_feature_flag"
assert deploy_tied_incident_source =~ "warning:"
```

---

## Environment Availability

Step 2.6: SKIPPED — Phase 27 is purely code/template/test changes. No external services, CLIs, runtimes, or databases are required beyond `mix test`.

---

## Package Legitimacy Audit

No new packages. SKIPPED.

---

## Open Questions

1. **`runbook.ex` doc text lists only 3 capability atoms (line 36)**
   - What we know: The doc is informational; enforcement is in `capabilities.ex`. New atoms are already allowlisted.
   - What's unclear: Whether the planner should include a doc-text update as a subtask.
   - Recommendation: Low-effort optional subtask — update the `@doc` for `capability:` to list all 5 valid atoms. Does not affect test or delivery.

2. **`target_kind:` value for new templates**
   - What we know: `:async_item` is used by both existing capability templates. New templates target feature flags and metric labels.
   - What's unclear: Whether to use `:feature_flag` / `:metric_label` or more specific atoms.
   - Recommendation: `:feature_flag` and `:metric_label` are idiomatic and self-documenting. Discretion per D-08.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**All claims in this research were verified against the live codebase — no assumed knowledge used for any structural assertion.**

---

## Sources

### Primary (HIGH confidence — verified from codebase)
- `lib/parapet/runbook.ex` — step opts, macro shape, no allowlist validation
- `lib/parapet/capabilities.ex` — `@valid_capabilities` list, `register_recovery/2` guard
- `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` — capability template shape
- `priv/templates/parapet.gen.runbooks/dead_letter.ex.eex` — capability template shape
- `priv/templates/parapet.gen.runbooks/retry_storm.ex.eex` — guidance-only shape, current warning text
- `priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex` — guidance-only shape, current warning text needing hardening
- `lib/mix/tasks/parapet.gen.runbooks.ex` — Igniter chain shape, assigns, lib_dir
- `test/mix/tasks/parapet.gen.runbooks_test.exs` — test structure, assertion pattern
- `lib/parapet/operator.ex` (lines 1003–1038) — `compute_preview` output shape

---

## Metadata

**Confidence breakdown:**
- Template shape to mirror: HIGH — verified from two analog templates
- Generator wiring: HIGH — verified from live task code
- Test assertion pattern: HIGH — verified from live test code
- Capability atom validity: HIGH — verified from `@valid_capabilities`
- Suppression drift warning gap: HIGH — verified by reading current warning text

**Research date:** 2026-05-28
**Valid until:** 2026-06-28 (stable Elixir library; no fast-moving ecosystem deps)

---

## RESEARCH COMPLETE

**Phase:** 27 - Prebuilt Playbooks
**Confidence:** HIGH

### Key Findings

- All CONTEXT.md assumptions verified against the live codebase — no corrections needed.
- The two new templates must mirror `stalled_executor.ex.eex` exactly: 3-step investigate/mitigate/verify, EEx `<%= inspect(@module_prefix) %>.<Suffix>` header, `capability:` atom + `target_kind:` + `requires_preview: true` on the mitigate step.
- `suppression_drift.ex.eex` step 2 warning needs a new sentence explaining the guidance-only architectural rationale (current text focuses on on-call readiness only; PB-02 requires "why no automated mitigation").
- Generator wiring is two `Igniter.copy_template` calls appended between line 109 and `Igniter.add_notice` — mechanical, no logic changes.
- Test extension is two sets of: one `Enum.any?` file-presence assert + one `Rewrite.source!` + three content asserts, all appended inside the single existing `test` block.
- `compute_preview` in `operator.ex` uses `capability.target_kind || step.target_kind` (line 1010) — the `target_kind:` atom chosen in the templates is the fallback the host adopter's preview implementation will see.

### File Created
`.planning/phases/27-prebuilt-playbooks/27-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Template shape | HIGH | Two analog templates read verbatim |
| Generator wiring | HIGH | Exact call shape verified in live code |
| Test pattern | HIGH | Full test file read; all assertion patterns mapped |
| Capability atoms | HIGH | `@valid_capabilities` confirmed |
| Preview output shape | HIGH | `compute_preview` read verbatim |

### Ready for Planning
Research complete. Planner can create PLAN.md.
