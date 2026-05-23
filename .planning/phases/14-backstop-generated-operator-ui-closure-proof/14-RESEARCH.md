# Phase 14: Backstop Generated Operator UI Closure Proof - Research

**Researched:** 2026-05-23
**Domain:** Generated Phoenix LiveView proof-chain reconciliation for operator resolve flow
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Canonical proof ownership
- **D-01:** Phase 3 remains the canonical runtime proof owner for generated operator UI behavior, including queue-side resolve lifecycle and the generated resolve regression lane.
- **D-02:** Phase 14 should strengthen and explicitly name the existing Phase 3 proof lane, then promote that proof upward into Phase 7 and Phase 12 verification hierarchy, rather than inventing a competing top-level runtime proof artifact.
- **D-03:** Closure phases should index canonical runtime proof and reconcile direct truth surfaces; they should not duplicate runtime evidence text as if they independently own behavior proof.

### Runtime seam and generated UI posture
- **D-04:** `Parapet.Operator` remains the sole canonical mutation seam for generated operator actions; generated templates must not encode alternate resolve semantics or UI-local lifecycle shortcuts.
- **D-05:** The generated operator UI should remain thin, host-owned wiring and presentation over the public operator seam, consistent with the repo's embedded-library posture and Phoenix maintainer expectations.
- **D-06:** Phase 14 should continue to treat generator/source-contract coverage as part of the real proof contract because this regression class is template drift as much as runtime drift.

### Proof-lane strategy
- **D-07:** The canonical resolve-flow backstop remains a two-layer proof lane: one cheap source-contract/generator assertion that generated queue resolve wires to `Parapet.Operator.resolve_incident/2`, plus one narrow generated-runtime lifecycle test proving queue removal and resolved-history visibility.
- **D-08:** Phase 14 should not introduce a browser E2E harness or a second bespoke proof lane unless the existing targeted ExUnit lane becomes insufficient to catch the real regression class.
- **D-09:** The backstop should be named and surfaced clearly enough in verification and validation artifacts that future milestone reruns fail obviously when generated resolve wiring drifts.

### Active truth surfaces and historical boundary
- **D-10:** Once a repaired runtime seam has fresh canonical proof, active truth surfaces should be reconciled even if a fresh milestone audit rerun has not yet happened.
- **D-11:** `SCALE-01.c` and `AC-03` should move out of pending in live tracker surfaces now that Phase 13 repaired the seam and Phase 3 canonical proof reflects the rerun.
- **D-12:** `milestone closure readiness` remains pending until Phase 14 lands because this phase exists to close the remaining proof-chain coverage gap.
- **D-13:** Historical audit artifacts and execution summaries must remain historical; superseding truth should be additive and explicit rather than rewriting prior chronology.
- **D-14:** The active Phase 12 closure-proof surfaces live in `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md` and `12-VALIDATION.md`, and Phase 14 should reconcile them as active hierarchy inputs rather than treating them as frozen historical summaries.

### Workflow posture
- **D-15:** Low-impact artifact-reconciliation choices in this repo should be auto-decided in assumptions mode and recorded in context, with escalation reserved for the impact boundaries already locked in `AGENTS.md`.
- **D-16:** The maintainer-facing model should stay least-surprise and easy to teach: `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` tell what is true now; `VERIFICATION.md` is canonical proof; `VALIDATION.md` is the proof map; milestone audits and summaries are dated historical evidence.
- **D-17:** `docs/operator-ui.md` is not a milestone truth surface; it should change in this phase only if the named proof lane or operator-facing wording materially changes.

### Deferred runtime debt boundary
- **D-18:** The duplicated resolved-history read path in the generated template remains deferred runtime debt and should stay out of Phase 14 unless proof honesty or testability makes it impossible to keep deferred.

### Claude's Discretion
- Exact wording of the re-verified Phase 3, Phase 7, and Phase 12 proof artifacts, provided they clearly preserve canonical proof ownership and do not imply that a fresh milestone audit rerun already passed.
- Exact updates to `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md`, provided they tell the current truth coherently and preserve the historical boundary around `.planning/v0.9-MILESTONE-AUDIT.md`.
- Exact naming of the resolve-flow backstop lane in proof artifacts, provided the lane is obviously rerunnable and easy for future maintainers and GSD automation to find.

### Deferred Ideas (OUT OF SCOPE)
- Pull the generated resolved-history pagination path fully behind a public `Parapet.Operator` read seam to remove the remaining duplicated repo/cursor logic.
- Expand generated operator proof coverage beyond resolve once the current regression class is explicitly backstopped and closure-proof indexing is stable.
- Re-run `$gsd-audit-milestone` after Phase 14 lands so the fresh milestone audit replaces the historical `gaps_found` artifact with new closure evidence.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `milestone closure readiness` | Future milestone reruns must catch generated operator UI resolve regressions through the Phase 3, Phase 7, and Phase 12 proof hierarchy without widening runtime scope. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] | Keep the canonical runtime backstop in the existing generated-runtime and source-contract test lane, promote that named lane into Phase 3/7/12 verification and validation surfaces, then reconcile `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` while leaving `.planning/v0.9-MILESTONE-AUDIT.md` historical. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

No repo-root `CLAUDE.md` exists, so there are no additional project constraints beyond `AGENTS.md`, `.planning/config.json`, and the phase context. [VERIFIED: repository inspection] [VERIFIED: AGENTS.md] [VERIFIED: .planning/config.json]

## Summary

Phase 14 should stay narrow. The generated resolve seam is already repaired in `priv/templates/parapet.gen.ui/operator_live.ex.eex`, the targeted generated-runtime lane already proves active-queue removal plus resolved-history visibility, and the source-contract tests already assert `Parapet.Operator.resolve_incident/2` instead of `record_note/3`. The remaining gap is proof-chain discoverability and closure-surface promotion, not another runtime feature edit. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs]

The smallest executable scope is therefore: name the existing backstop consistently as the `generated resolve-flow proof lane`, point Phase 3 canonical proof at that named lane explicitly, point Phase 7 and Phase 12 at Phase 3 as index layers, and update live tracker surfaces so `SCALE-01.c` and `AC-03` reflect repaired truth while `milestone closure readiness` remains pending until the Phase 14 closure surfaces land. Historical audit artifacts should not be edited. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md] [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

`docs/operator-ui.md` should change only if needed to align wording to the canonical lane name. The current doc already states the correct runtime behavior and targeted test lane, so this should be a wording-only update, not a semantics or UI-contract rewrite. [VERIFIED: docs/operator-ui.md] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-UI-SPEC.md] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]

**Primary recommendation:** Treat Phase 14 as proof-index and tracker reconciliation work with, at most, minimal naming/grep-hardening in the existing generated tests; do not add new runtime seams, new test harnesses, or resolved-history seam cleanup. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Queue-side resolve mutation | API / Backend | Frontend Server (LiveView) | `Parapet.Operator.resolve_incident/2` owns the durable lifecycle transition; the generated LiveView only builds the payload and invokes that seam. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] |
| Post-resolve queue refresh | Frontend Server (LiveView) | API / Backend | The generated LiveView uses `push_patch/2` and `handle_params/3` to refresh same-view URL state after resolve while `Parapet.Operator.list_incident_queue/1` supplies active-queue data. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Resolved-history visibility | Frontend Server (LiveView) | Database / Storage | The generated template still owns the resolved-history query branch directly, so the runtime backstop must keep asserting active-lane removal and history appearance without widening scope into seam cleanup. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |
| Closure-proof indexing | Frontend Server test lane | Documentation / planning surfaces | The actual regression backstop lives in the targeted ExUnit lane, while Phase 3, Phase 7, and Phase 12 artifacts only index and name that proof. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md] [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | repo-locked via existing app dependencies. [VERIFIED: mix.lock] | Same-LiveView patch flow for queue refresh after resolve. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] | Phase 14 should preserve the existing `push_patch/2` plus `handle_params/3` pattern instead of inventing a new navigation seam. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| ExUnit | bundled test framework. [VERIFIED: test/test_helper.exs] | Existing generated-runtime and source-contract backstop lane. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs] | The backstop already exists and passes in the targeted quick lane, so Phase 14 should reuse it. [VERIFIED: local `mix test` run 2026-05-23] |
| Repo planning artifacts | existing `.planning` proof surfaces. [VERIFIED: repository inspection] | Canonical proof, validation mapping, and live tracker truth. [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/7/07-VALIDATION.md] [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md] | This phase is primarily a proof-surface reconciliation phase. [VERIFIED: .planning/ROADMAP.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `rg` / shell assertions | local CLI tools. [VERIFIED: repo usage in existing validation files] | Fast proof-link and tracker-surface verification. [VERIFIED: .planning/v0.9-phases/7/07-VALIDATION.md] [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md] | Use for Phase 14 artifact reconciliation after the targeted tests are green. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |
| `python3` | local CLI tool already used by proof artifacts. [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md] | Cross-file coherence checks when verifying proof-index surfaces. [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md] | Use only if Phase 14 adds another multi-file proof-link assertion similar to Phase 12. [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing the existing generated resolve tests | Add a new browser E2E harness | Rejected because locked context says the current targeted ExUnit lane is the intended backstop. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |
| Updating Phase 3 canonical proof and indexing upward | Create a new top-level runtime `VERIFICATION.md` for Phase 14 | Rejected because canonical runtime proof must stay with Phase 3 and Phase 14 is a closure/index phase. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |
| Leaving resolved-history seam cleanup deferred | Pull resolved-history reads behind a new public operator API now | Rejected for this phase because it widens runtime scope beyond the proof-chain gap. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |

**Installation:**
```bash
# No new packages are required for Phase 14.
mix test test/parapet/generated_operator_live_paging_test.exs \
  test/parapet/operator_ui_integration_test.exs \
  test/mix/tasks/parapet.gen.ui_test.exs
```

**Version verification:** No dependency upgrade is required or recommended for this phase; the work stays on the repo’s current Phoenix LiveView, ExUnit, and planning-artifact surfaces. [VERIFIED: mix.lock] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Generated queue Resolve click
  -> OperatorLive.handle_event("resolve", %{"id" => id}, socket)
    -> Parapet.Operator.resolve_incident(incident, payload)
      -> durable incident state change + evidence writes
    -> push_patch within same LiveView
      -> handle_params/3 reloads active queue
        -> active queue via Parapet.Operator.list_incident_queue/1
        -> resolved history via generated resolved_history_page/1

Proof hierarchy for the same seam
  -> generated runtime test proves active queue removal + resolved history visibility
  -> source-contract tests prove generator/template wiring
  -> Phase 3 VERIFICATION.md names the lane canonically
  -> Phase 7 / Phase 12 index that Phase 3 proof
  -> ROADMAP / REQUIREMENTS / STATE tell current truth
  -> milestone audit stays historical
```

The recommended architecture change is documentary, not structural: the runtime/test/data flow already exists and should be surfaced consistently instead of replaced. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

### Recommended Project Structure

```text
.planning/v0.9-phases/3/
├── VERIFICATION.md          # canonical runtime proof owner
└── 03-VALIDATION.md         # canonical sampling map

.planning/v0.9-phases/7/
├── VERIFICATION.md          # Phase 7 closure index
└── 07-VALIDATION.md         # Phase 7 proof map

.planning/phases/12-backfill-closure-phase-verification-surfaces/
├── 12-VERIFICATION.md       # active closure-proof surface
└── 12-VALIDATION.md         # closure-proof validation map

test/parapet/
├── generated_operator_live_paging_test.exs
├── operator_ui_integration_test.exs
└── ../mix/tasks/parapet.gen.ui_test.exs
```

Primary edit targets for Phase 14 are the proof surfaces above plus `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, and possibly `docs/operator-ui.md` for wording alignment only. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] [VERIFIED: docs/operator-ui.md]

### Pattern 1: Canonical Runtime Proof Lives in Phase 3
**What:** Phase 3 owns the runtime proof for generated resolve behavior. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
**When to use:** Any proof text describing actual generated operator resolve behavior or rerunnable commands. [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md]
**Example:**
```markdown
| Generated runtime bounded-page and resolve-lifecycle proof | `mix test test/parapet/generated_operator_live_paging_test.exs` | 2 tests, 0 failures | ✓ PASS |
```
Source: `.planning/v0.9-phases/3/VERIFICATION.md`. [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md]

### Pattern 2: Closure Phases Index, They Do Not Re-Prove
**What:** Later proof artifacts cite Phase 3 and keep fresh milestone audit reruns separate. [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md] [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md]
**When to use:** Phase 7 and Phase 12 verification/validation updates. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
**Example:**
```markdown
| 1 | Phase 7 already created the canonical runtime-proof artifact for the underlying operator UI performance work, including the repaired generated queue resolve lane. | ✓ VERIFIED | `.planning/v0.9-phases/3/VERIFICATION.md` remains the canonical Phase 3 verification report... |
```
Source: `.planning/v0.9-phases/7/VERIFICATION.md`. [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md]

### Pattern 3: Same-LiveView Refresh Uses `push_patch/2`
**What:** Queue mutations stay inside the current LiveView and reload via `handle_params/3`. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
**When to use:** Post-resolve queue refresh behavior and associated proof wording. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
**Example:**
```elixir
case Parapet.Operator.resolve_incident(incident, payload) do
  {:ok, _result} ->
    {:noreply, push_patch(socket, to: queue_path(socket, %{"id" => id}))}
```
Source: `priv/templates/parapet.gen.ui/operator_live.ex.eex`. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Anti-Patterns to Avoid

- **Creating a second runtime proof owner:** Phase 14 should not introduce a competing runtime proof artifact when Phase 3 already owns that responsibility. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
- **Editing `.planning/v0.9-MILESTONE-AUDIT.md` to tell current truth:** The audit is historical evidence and should remain unchanged. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
- **Using Phase 14 to fix the resolved-history public seam:** That is explicitly deferred runtime debt. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
- **Turning `docs/operator-ui.md` into a tracker surface:** The doc may align wording, but milestone truth still belongs in `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, and verification artifacts. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Generated resolve regression backstop | New UI automation stack | Existing three-file generated UI test lane | The existing lane already passes and covers runtime plus source wiring. [VERIFIED: local `mix test` run 2026-05-23] [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] |
| Closure proof promotion | New proof hierarchy model | Existing Phase 3 -> Phase 7 -> Phase 12 verification chain | The repo already standardized this model in Phase 12. [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md] |
| Current-truth reconciliation | Rewriting historical summaries or audit files | Narrow updates to `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` | Locked context says active truth is additive and historical chronology must remain intact. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |

**Key insight:** The smallest scope is to promote an already-working backstop into the proof hierarchy, not to invent a new one. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs]

## Common Pitfalls

### Pitfall 1: Re-Proving Runtime Behavior in Phase 7 or Phase 12
**What goes wrong:** Closure artifacts start restating Phase 3 behavior as if they independently verified it. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
**Why it happens:** The phase is about proof-chain gaps, which makes it easy to drift into duplicate runtime narratives. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
**How to avoid:** Keep runtime commands and behavior details in Phase 3, and let Phase 7 / Phase 12 cite them. [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md]
**Warning signs:** New Phase 14 wording that looks like a standalone runtime verification report. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]

### Pitfall 2: Widening Scope into Resolved-History Seam Cleanup
**What goes wrong:** The phase turns into a refactor of `resolved_history_page/1` instead of closing the proof-chain gap. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
**Why it happens:** The historical audit correctly notes the duplicated resolved-history read path. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
**How to avoid:** Leave that debt deferred unless a proof assertion cannot stay honest without it. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
**Warning signs:** Proposed edits to `lib/parapet/operator.ex` or new public read APIs for resolved history. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]

### Pitfall 3: Forgetting the Live Tracker Surfaces
**What goes wrong:** Phase 3/7/12 proof docs get fixed, but `ROADMAP.md`, `REQUIREMENTS.md`, or `STATE.md` still tell stale truth. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
**Why it happens:** The proof-chain issue spans runtime proof, closure indexes, and tracker artifacts. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]
**How to avoid:** Sequence tracker reconciliation after proof-surface promotion in the same phase. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
**Warning signs:** `SCALE-01.c` and `AC-03` remain `Pending` in `.planning/REQUIREMENTS.md` after Phase 14 proof updates land. [VERIFIED: .planning/REQUIREMENTS.md]

## Code Examples

Verified patterns from repo sources:

### Generated Runtime Backstop
```elixir
{:noreply, socket} = live_module.handle_event("resolve", %{"id" => "inc-001"}, socket)
{:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)
active_html = render_live(live_module, socket)

refute active_html =~ ">Active incident 1<"

{:noreply, socket} =
  live_module.handle_params(
    %{"status" => "resolved"},
    "http://example.com/parapet?status=resolved",
    socket
  )

resolved_html = render_live(live_module, socket)
assert resolved_html =~ ">Active incident 1<"
```
Source: `test/parapet/generated_operator_live_paging_test.exs`. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs]

### Source-Contract Guardrail
```elixir
assert content =~ "Parapet.Operator.resolve_incident(incident, payload)"
refute content =~ "Parapet.Operator.record_note(incident, \"Resolved\", payload)"
```
Source: `test/parapet/operator_ui_integration_test.exs`. [VERIFIED: test/parapet/operator_ui_integration_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Closure surfaces referenced general queue proof without a consistently named generated resolve backstop. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] | Closure surfaces should cite the explicit `generated resolve-flow proof lane` composed of the runtime and source-contract tests already in repo. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-UI-SPEC.md] | The gap was surfaced by the 2026-05-23 milestone audit and constrained by the 2026-05-23 Phase 14 context/UI-SPEC. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] | Future reruns can fail on one named lane instead of depending on inference across multiple artifacts. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |

**Deprecated/outdated:**
- Treating `.planning/v0.9-MILESTONE-AUDIT.md` as a live truth surface is outdated for this phase; active truth belongs in the current tracker and verification artifacts. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

## Assumptions Log

All claims in this research were verified or cited in this session; no user confirmation is required before planning. [VERIFIED: research session evidence]

## Open Questions

1. **Should the tests themselves be renamed to include the exact phrase `generated resolve-flow proof lane`?**
   - What we know: The runtime and source-contract coverage already exist and pass. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs] [VERIFIED: local `mix test` run 2026-05-23]
   - What's unclear: The locked context requires the lane to be clearly named, but it does not require renaming test case titles if proof-surface wording is already sufficient. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
   - Recommendation: Prefer naming the lane in Phase 3 / Phase 7 / Phase 12 / `docs/operator-ui.md` first; rename test descriptions only if grep-based discoverability still feels weak. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-UI-SPEC.md]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus shell `rg` assertions. [VERIFIED: test/test_helper.exs] [VERIFIED: .planning/v0.9-phases/7/07-VALIDATION.md] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs`. [VERIFIED: local `mix test` run 2026-05-23] |
| Full suite command | `mix test` plus proof-link reconciliation grep(s) across the edited planning files. [VERIFIED: .planning/v0.9-phases/3/03-VALIDATION.md] [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `milestone closure readiness` | The named generated resolve-flow proof lane remains executable and Phase 3 / Phase 7 / Phase 12 / tracker surfaces all point at it honestly. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] | targeted integration + artifact reconciliation | `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` then `rg -n "generated resolve-flow proof lane|generated_operator_live_paging_test|operator_ui_integration_test|parapet.gen.ui_test|resolve_incident/2|fresh milestone audit rerun remains separate work" .planning/v0.9-phases/3/VERIFICATION.md .planning/v0.9-phases/3/03-VALIDATION.md .planning/v0.9-phases/7/VERIFICATION.md .planning/v0.9-phases/7/07-VALIDATION.md .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md docs/operator-ui.md`. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: .planning/v0.9-phases/7/07-VALIDATION.md] [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md] | ✅ |

### Sampling Rate

- **Per task commit:** Run the three-file generated UI test lane. [VERIFIED: local `mix test` run 2026-05-23]
- **Per wave merge:** Run the test lane plus the proof-link `rg` reconciliation check. [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md]
- **Phase gate:** All edited proof surfaces must cite the same named lane, and active tracker surfaces must no longer contradict repaired Phase 3 truth. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]

### Wave 0 Gaps

- None — the runtime/source backstop files and validation infrastructure already exist. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Preserve the existing host-auth guidance for generated operator routes; do not weaken docs wording around authenticated mounting. [VERIFIED: docs/operator-ui.md] [VERIFIED: test/parapet/operator_ui_integration_test.exs] |
| V3 Session Management | no | No session behavior changes are in scope for Phase 14. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |
| V4 Access Control | yes | Keep the generated UI host-owned and avoid introducing alternate operator mutation seams outside `Parapet.Operator`. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |
| V5 Input Validation | yes | Preserve existing queue param normalization and the LiveView patch flow already exercised by the generated runtime lane. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] |
| V6 Cryptography | no | No cryptographic behavior is touched by this phase. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Template drift bypasses the canonical resolve seam | Tampering | Keep the source-contract assertions that require `resolve_incident/2` and forbid `record_note/3` in generated resolve wiring. [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs] |
| Closure artifacts claim proof that no longer maps to a rerunnable lane | Repudiation | Name the lane consistently in Phase 3 / Phase 7 / Phase 12 and verify proof links with grep. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] [VERIFIED: .planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md] |
| Docs drift weakens the operator auth story | Elevation of privilege | Limit `docs/operator-ui.md` edits to proof-lane wording and preserve authenticated-route guidance. [VERIFIED: docs/operator-ui.md] [VERIFIED: test/parapet/operator_ui_integration_test.exs] |

## Sources

### Primary (HIGH confidence)

- Repo artifacts and codebase inspection - `AGENTS.md`, `.planning/config.json`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, `.planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md`, `.planning/phases/14-backstop-generated-operator-ui-closure-proof/14-UI-SPEC.md`, `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/3/03-VALIDATION.md`, `.planning/v0.9-phases/7/VERIFICATION.md`, `.planning/v0.9-phases/7/07-VALIDATION.md`, `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md`, `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md`, `lib/parapet/operator.ex`, `priv/templates/parapet.gen.ui/operator_live.ex.eex`, `test/parapet/generated_operator_live_paging_test.exs`, `test/parapet/operator_ui_integration_test.exs`, `test/mix/tasks/parapet.gen.ui_test.exs`, and `docs/operator-ui.md`. [VERIFIED: repository inspection]
- Local targeted verification run on 2026-05-23 - `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` passed with `14 tests, 0 failures`. [VERIFIED: local `mix test` run 2026-05-23]

### Secondary (MEDIUM confidence)

- Phoenix LiveView official docs - `push_patch/2`, `handle_params/3`, and live navigation behavior used to justify same-LiveView refresh ownership. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

### Tertiary (LOW confidence)

- None. [VERIFIED: research session evidence]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 14 stays on existing repo surfaces and does not require dependency or architecture changes. [VERIFIED: mix.lock] [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md]
- Architecture: HIGH - Responsibility boundaries are directly stated in Phase 14 context and visible in current code/tests. [VERIFIED: .planning/phases/14-backstop-generated-operator-ui-closure-proof/14-CONTEXT.md] [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
- Pitfalls: HIGH - The current milestone audit and existing proof artifacts show the exact failure mode Phase 14 is closing. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md]

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 for repo-local proof-surface planning, unless Phase 14 execution materially changes the proof hierarchy first. [VERIFIED: research scope stability]
