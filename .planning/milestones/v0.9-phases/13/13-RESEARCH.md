# Phase 13: Repair Generated Operator Resolve Flow - Research

**Researched:** 2026-05-23
**Domain:** Phoenix LiveView generated operator UI repair and proof-surface reconciliation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Runtime seam repair
- **D-01:** The generated queue LiveView `"resolve"` handler should call `Parapet.Operator.resolve_incident/2`, not `Parapet.Operator.record_note/3`.
- **D-02:** The queue and detail generated LiveViews should converge on the same public `Parapet.Operator` mutation seam so resolve semantics are consistent across operator entrypoints.
- **D-03:** The generated operator UI should stay thin and host-owned, while durable lifecycle behavior remains owned by the Phoenix-free `Parapet.Operator` boundary.

### Operator semantics
- **D-04:** In generated operator UI, `"Resolve"` means a real lifecycle transition to `resolved`, including the durable status-change evidence and retrospective behavior already encoded in `Parapet.Operator.resolve_incident/2`.
- **D-05:** Phase 13 should not redefine `"Resolve"` as a soft note-writing shortcut or require operators to leave the queue view just to perform a legitimate resolve action.

### Proof strategy
- **D-06:** The canonical regression backstop should be a two-layer proof: one cheap source-contract assertion that the generated queue template wires `"resolve"` to `Parapet.Operator.resolve_incident/2`, plus one narrow generated-runtime test that proves queue resolve changes incident state and removes it from the active lane.
- **D-07:** This proof should extend the existing targeted quick-run operator UI lane rather than introduce a new heavyweight browser or generated-host harness.
- **D-08:** The runtime test should prove the user-visible lifecycle outcome that matters for the milestone contract: active queue to resolved-history/archive progression, not just handler presence.

### Verification hierarchy
- **D-09:** The new resolve proof becomes part of the canonical Phase 3 runtime proof surface first; Phase 7 and Phase 12 should index that runtime proof rather than duplicate it inside closure-phase verification artifacts.
- **D-10:** Reconciliation updates after the fix should stay narrow and honest: update current truth surfaces that materially overstate closure, while leaving historical audit artifacts historical until a fresh rerun replaces them.

### Maintainer workflow posture
- **D-11:** For this phase and downstream planning in this repo, default harder toward one-shot, research-backed recommendations with low-impact decisions shifted left into assumptions and artifacts.
- **D-12:** Escalate only for the repo’s already-locked impact boundaries: public CLI/API contract, default install contents, auth ownership, dependency/support surface, runtime behavior, safety guarantees, operator semantics, durable evidence truth, irreversible schema/maintenance burden, or two medium-impact concerns moving at once.

### the agent's Discretion
- Whether the resolve runtime assertion belongs inside `test/parapet/generated_operator_live_paging_test.exs` or a nearby targeted generated-UI test, provided it stays in the existing quick-run proof set and remains obvious to maintainers.
- Exact wording of the reconciled verification and validation surfaces, provided they point clearly at the repaired runtime proof and do not imply a fresh milestone audit has already passed.
- Whether to leave the resolved-history public-seam cleanup for a later phase or capture it only as a deferred follow-up, provided Phase 13 still closes the broken resolve lifecycle and proof gap.

### Deferred Ideas (OUT OF SCOPE)
- Pull the generated resolved-history pagination path fully behind a public `Parapet.Operator` read seam to remove duplicated repo/cursor logic.
- Add broader closure-proof coverage for generated operator UI runtime mutations beyond resolve once the narrow backstop is in place.
- Further centralize recommendation-first repo doctrine if future phases still reopen low-impact defaults despite `AGENTS.md`, `.planning/config.json`, and phase context artifacts.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| `SCALE-01.c` | Operator UI incident list uses efficient pagination or cursor-based scrolling. [VERIFIED: .planning/REQUIREMENTS.md] | Keep the queue on the existing bounded `Parapet.Operator.list_incident_queue/1` seam, repair only the queue `"resolve"` mutation, and prove the resolved incident disappears from the active lane without regressing the current bounded-page contract. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] |
| `AC-03` | Operator UI proof story for the Phase 3 acceptance surface is currently pending in Phase 13. [VERIFIED: .planning/REQUIREMENTS.md] | Reconcile Phase 3 and Phase 7 verification/validation artifacts so they point at the repaired runtime proof instead of continuing to imply closure based on a lane that never exercised queue-side resolve. [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

No repo-root `CLAUDE.md` exists, so there are no additional project constraints beyond `AGENTS.md` and the phase context. [VERIFIED: repository inspection]

## Summary

The defect is narrow and concrete: the generated queue LiveView handles `"resolve"` by calling `Parapet.Operator.record_note/3`, while the generated detail LiveView already calls `Parapet.Operator.resolve_incident/2`. That means queue-side resolve currently writes a note without changing incident state, so the active-queue to resolved-history/archive lifecycle described by Phase 3 and indexed by Phase 7 is not actually true at runtime. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

The safest implementation is to keep the generated UI thin and route queue-side resolve through the same public `Parapet.Operator.resolve_incident/2` seam already used by the detail view. That seam already performs the durable state change, writes `status_change` evidence, and attaches the retrospective payload expected by downstream archive/history behavior. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]

The current proof gap is also concrete: the targeted generated-runtime lane proves bounded paging, but it never exercises the `"resolve"` event, and its fake repo only supports read-only active-queue queries today. The right fix is to extend that existing lane with minimal write/query capabilities and add one cheap template assertion that guards against future rewiring back to `record_note/3`. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs]

**Primary recommendation:** Repair `priv/templates/parapet.gen.ui/operator_live.ex.eex` to call `Parapet.Operator.resolve_incident/2`, extend the existing generated-runtime harness so queue resolve visibly removes the incident from the active lane and exposes it in resolved history, then update only the Phase 3 and Phase 7 truth surfaces that currently overstate closure. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Resolve incident lifecycle mutation | API / Backend | Frontend Server (LiveView) | `Parapet.Operator.resolve_incident/2` owns the durable state transition, timeline entry, audit record, and retrospective generation; the LiveView should only construct the payload and invoke that seam. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex] |
| Queue state refresh after resolve | Frontend Server (LiveView) | API / Backend | The queue view uses `push_patch/2` plus `handle_params/3` to reload URL-owned queue state inside the same LiveView, while `Parapet.Operator.list_incident_queue/1` supplies the active-page data. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Resolved-history visibility after resolve | Frontend Server (LiveView) | Database / Storage | The generated LiveView currently owns the resolved-history branch and queries resolved incidents directly from the repo, so the runtime proof must exercise both the mutation seam and that local history branch. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] |
| Regression backstop for generated resolve flow | Frontend Server test lane | — | The existing quick-run proof set already compiles generated sources and renders the LiveView without a browser harness, so Phase 13 should extend that lane rather than add a heavier system. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | `1.1.30` locked; released 2026-05-05. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] | Generated operator queue/detail LiveViews, `handle_event/3`, `handle_params/3`, and `push_patch/2`. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] | The phase is repairing a LiveView event path and should follow LiveView’s current same-view patch flow instead of inventing a different navigation model. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Phoenix | `1.8.7` locked; released 2026-05-06. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] | Host app integration surface for generated LiveViews. [VERIFIED: mix.lock] | The generator is host-owned and depends on the host already having Phoenix; this phase must preserve that dependency posture. [VERIFIED: test/parapet/operator_ui_compile_out_test.exs] |
| Igniter | `0.7.9` locked; latest release visible in this session is `0.8.0` from 2026-05-09. [VERIFIED: mix.lock] [VERIFIED: mix hex.info igniter] | Generator harness used by `mix parapet.gen.ui` tests to compile generated files. [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs] | Phase 13 should stay on the current generator/testing surface and not widen scope into a dependency upgrade. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md] |
| ExUnit | Bundled with installed Elixir `1.19.5`. [VERIFIED: elixir --version] | Fast regression proof lane. [VERIFIED: test/test_helper.exs] | The repo already proves generated UI behavior through ExUnit, and the phase context explicitly rejects a new heavyweight browser harness. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ecto | `3.13.6` locked. [VERIFIED: mix.lock] | Build the `ActionPayload` changeset and apply the incident state transition inside `resolve_incident/2`. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/operator/action_payload.ex] | Use when extending the fake repo to support `Ecto.Multi` transaction/update behavior for the generated runtime test. [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: test/parapet/evidence_test.exs] |
| Phoenix.LiveViewTest | Provided by Phoenix LiveView `1.1.30`. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] | Render generated HEEx output to string and support LiveView interaction helpers when needed. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] | Use for the existing compiled-source generated-runtime lane; no new browser-level tool is needed. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Calling `Parapet.Operator.resolve_incident/2` from queue LiveView | Calling `Parapet.Operator.record_note/3` and treating `"Resolve"` as a note shortcut | Rejected by locked phase semantics because it leaves the incident active and breaks the durable lifecycle contract. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md] [VERIFIED: lib/parapet/operator.ex] |
| Extending `test/parapet/generated_operator_live_paging_test.exs` | Adding a browser or end-to-end harness | Rejected by locked proof strategy because the repo already has a fast generated-runtime lane and Phase 13 should stay bounded. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md] |
| Narrow Phase 3 / Phase 7 reconciliation | Rewriting the historical milestone audit artifact | Rejected by locked historical-boundary rules; the current audit remains historical until a fresh rerun replaces it. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |

**Installation:**
```bash
# No new packages are required for this phase.
mix test test/parapet/generated_operator_live_paging_test.exs \
  test/parapet/operator_ui_integration_test.exs \
  test/mix/tasks/parapet.gen.ui_test.exs
```

**Version verification:** LiveView `1.1.30` and Phoenix `1.8.7` are the locked versions in this repo and were confirmed in this session with `mix hex.info`; Igniter is locked at `0.7.9` while `0.8.0` exists upstream, which is out of scope for this repair phase. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info igniter]

## Architecture Patterns

### System Architecture Diagram

```text
Operator clicks "Resolve" in generated queue UI
  -> OperatorLive.handle_event("resolve", %{"id" => id}, socket)
    -> load incident from host Repo
    -> build Parapet.Operator.ActionPayload
    -> Parapet.Operator.resolve_incident/2
      -> Parapet.Evidence.run_operator_command/1
        -> update incident.state = "resolved"
        -> insert TimelineEntry(type: "status_change", new_state: "resolved")
        -> insert/broadcast ToolAudit
    -> push_patch back into current LiveView URL
      -> handle_params/3 reloads queue state
        -> active scope: Parapet.Operator.list_incident_queue/1
        -> resolved scope: generated resolved_history_page/1
  -> rendered result:
    -> incident disappears from active lane
    -> incident appears in resolved-history lane
    -> archive path remains eligible because archive only targets resolved incidents
```

This diagram reflects the current intended ownership split already present in the repo; Phase 13 repairs the broken queue-side edge, not the broader architecture. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/evidence/archiver.ex]

### Recommended Project Structure

```text
priv/templates/parapet.gen.ui/
├── operator_live.ex.eex          # queue event wiring and resolved-history branch
├── operator_detail_live.ex.eex   # already-correct resolve seam
└── operator_components.ex.eex    # queue/detail actions and labels

test/parapet/
├── generated_operator_live_paging_test.exs  # runtime lane to extend
├── operator_ui_integration_test.exs         # source-contract assertions
└── operator_ui_compile_out_test.exs         # compile/dependency seam assertions

.planning/v0.9-phases/
├── 3/VERIFICATION.md
├── 3/03-VALIDATION.md
├── 7/VERIFICATION.md
└── 7/07-VALIDATION.md
```

The planner should keep edits within these surfaces unless implementation proves a narrowly-related helper extraction is unavoidable. [VERIFIED: repository inspection] [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]

### Pattern 1: Queue Mutations Go Through `Parapet.Operator`
**What:** Generated UI builds an action payload and delegates durable mutation semantics to the Phoenix-free operator boundary. [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex] [VERIFIED: lib/parapet/operator.ex]
**When to use:** Any queue/detail action that changes incident lifecycle or writes audited operator evidence. [VERIFIED: lib/parapet/operator.ex]
**Example:**
```elixir
# Source: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
case Parapet.Operator.resolve_incident(incident, payload) do
  {:ok, _result} ->
    {:noreply, push_navigate(socket, to: "/parapet/#{id}")}

  {:error, _reason} ->
    {:noreply, put_flash(socket, :error, "Failed to resolve")}
end
```

### Pattern 2: Same-LiveView State Changes Reload Through `push_patch/2`
**What:** Queue-affecting events patch the current LiveView URL and let `handle_params/3` recompute visible queue state. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
**When to use:** Queue refresh, paging, and post-mutation active-lane reloads inside the current queue LiveView. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
**Example:**
```elixir
# Source: priv/templates/parapet.gen.ui/operator_live.ex.eex
{:noreply, push_patch(socket, to: queue_path(socket, %{"id" => id}))}
```
Source support: LiveView documents `push_patch/2` for navigation within the current LiveView and states that `handle_params/3` runs on patch. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Pattern 3: Generated Runtime Proof Uses Compiled Templates, Not a Browser Harness
**What:** Tests compile generated template output, mount the LiveView module directly, and render HTML strings for assertions. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs]
**When to use:** Fast regression coverage for generated UI behavior that should remain in the repo’s quick lane. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]
**Example:**
```elixir
# Source: test/parapet/generated_operator_live_paging_test.exs
{:ok, socket} = live_module.mount(%{}, %{}, socket)
{:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)
html = render_live(live_module, socket)
```

### Anti-Patterns to Avoid
- **Re-implementing lifecycle semantics in the template:** The queue LiveView should not decide that `"resolve"` means “write a note”; that duplicates and contradicts the public operator contract. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: lib/parapet/operator.ex]
- **Adding a new proof harness for a narrow regression:** The phase context explicitly prefers extending the existing targeted lane over introducing browser/E2E infrastructure. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]
- **Widening Phase 13 into resolved-history seam cleanup:** The direct repo-backed resolved-history branch is real technical debt, but it is explicitly deferred unless it blocks the runtime proof. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Incident resolve lifecycle | Ad hoc state mutation or note-writing logic in the LiveView | `Parapet.Operator.resolve_incident/2` | The public seam already writes the state change, timeline evidence, tool audit, and retrospective consistently. [VERIFIED: lib/parapet/operator.ex] |
| Resolve-flow regression harness | New browser/E2E stack | Extend `test/parapet/generated_operator_live_paging_test.exs` plus source-contract assertions | The existing lane already compiles generated files and renders the LiveView in under a second locally; it only lacks mutation coverage. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: local test run 2026-05-23] |
| Fake repo transactional behavior | One-off test-only lifecycle logic inside the LiveView test body | Reuse the `DummyRepo.transaction/1` pattern already present in `test/parapet/evidence_test.exs` | The repo already has a working fake `Ecto.Multi` transaction pattern that can be adapted for generated-runtime tests. [VERIFIED: test/parapet/evidence_test.exs] |

**Key insight:** The repair is not “make resolve do more work”; the work already exists in `Parapet.Operator.resolve_incident/2`. The real job is to stop bypassing that seam and to make the existing quick proof lane capable of catching that bypass. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]

## Common Pitfalls

### Pitfall 1: Fixing the Template but Not the Guardrail
**What goes wrong:** The queue template is repaired once, but future generator edits can silently switch it back to `record_note/3`. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
**Why it happens:** Current source-contract tests do not assert the queue-side resolve seam directly. [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs]
**How to avoid:** Add one explicit assertion that the generated queue template contains `Parapet.Operator.resolve_incident` and does not route `"resolve"` through `record_note`. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]
**Warning signs:** Green paging tests with no queue-side resolve assertion, or source tests that only assert `"handle_event(\"resolve\""` exists. [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs]

### Pitfall 2: Proving Handler Presence Instead of User-Visible Outcome
**What goes wrong:** Tests confirm a function call exists but never prove the incident leaves the active queue and becomes visible in resolved history. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]
**Why it happens:** The current generated-runtime lane is read-only and only checks bounded-page rendering. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs]
**How to avoid:** Extend the fake repo to persist incident updates and serve resolved-history queries, then assert both active-lane removal and resolved-history appearance after `"resolve"`. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/evidence_test.exs]
**Warning signs:** Tests pass even though `priv/templates/parapet.gen.ui/operator_live.ex.eex` still calls `record_note/3`. [VERIFIED: local test run 2026-05-23] [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]

### Pitfall 3: Carrying Forward Broken Verify Commands
**What goes wrong:** Planner or executor copies `mix test ... -x` from older artifacts and the verification step fails before the actual tests run. [VERIFIED: .planning/v0.9-phases/3/03-01-SUMMARY.md] [VERIFIED: .planning/v0.9-phases/3/VALIDATION.md]
**Why it happens:** Historical planning surfaces still contain `-x` commands from earlier workflow conventions. [VERIFIED: repository grep for `mix test ... -x`]
**How to avoid:** Use plain `mix test ...` for the quick lane on this machine, or `--max-failures 1` if fail-fast behavior is important. [VERIFIED: mix test option output] [VERIFIED: local test run 2026-05-23]
**Warning signs:** `** (Mix) Could not invoke task "test": 1 error found! -x : Unknown option`. [VERIFIED: local test run 2026-05-23]

## Code Examples

Verified patterns from repo and official docs:

### Queue Resolve Should Reuse the Existing Public Mutation Seam
```elixir
# Source: lib/parapet/operator.ex and priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
payload = %Parapet.Operator.ActionPayload{
  actor: "operator_ui",
  reason: "Resolved via UI",
  correlation_id: Ecto.UUID.generate(),
  action_type: :resolve
}

case Parapet.Operator.resolve_incident(incident, payload) do
  {:ok, _result} -> {:noreply, push_patch(socket, to: queue_path(socket, %{"id" => id}))}
  {:error, _reason} -> {:noreply, put_flash(socket, :error, "Failed to resolve")}
end
```

### Same-View Live Navigation Should Flow Through `handle_params/3`
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/live-navigation.html
{:noreply, push_patch(socket, to: ~p"/pages/#{@page + 1}")}
```
LiveView documents that `handle_params/3` runs on `push_patch/2` for the current LiveView. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Generated Runtime Lane Can Assert Rendered Outcome Without a Browser
```elixir
# Source: test/parapet/generated_operator_live_paging_test.exs
{:ok, socket} = live_module.mount(%{}, %{}, socket)
{:noreply, socket} = live_module.handle_params(%{}, "http://example.com/parapet", socket)
html = render_live(live_module, socket)
assert html =~ "Active incident 1"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Queue template treats `"resolve"` as `record_note/3` | Queue and detail views both use `Parapet.Operator.resolve_incident/2` | Required now by Phase 13 locked decisions. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md] | Restores the real lifecycle transition and makes active-queue/history/archive truth possible again. [VERIFIED: lib/parapet/operator.ex] |
| Runtime proof only covers bounded paging | Runtime proof also exercises queue-side resolve outcome | Required now by Phase 13 locked decisions. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md] | Future reruns can catch this exact regression class instead of relying on summary-only closure claims. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] |
| Validation artifacts prescribe `mix test ... -x` | Use plain `mix test ...` on Elixir/Mix `1.19.5` | Confirmed in this session on 2026-05-23. [VERIFIED: mix --version] [VERIFIED: local test run 2026-05-23] | Planner should not inherit a broken verification command. [VERIFIED: local test run 2026-05-23] |

**Deprecated/outdated:**
- `mix test ... -x` in current planning artifacts is outdated for this installed Mix version and should not be copied into Phase 13 plans. [VERIFIED: .planning/v0.9-phases/3/VALIDATION.md] [VERIFIED: local test run 2026-05-23]

## Assumptions Log

All material claims in this research were verified in the current session or cited from official documentation. No user confirmation is required for assumption-only claims. [VERIFIED: research session outputs]

## Open Questions (RESOLVED)

1. **Should the resolve runtime proof live inside `generated_operator_live_paging_test.exs` or a nearby generated-UI test file?**
   - Resolution: Keep the runtime proof in `test/parapet/generated_operator_live_paging_test.exs` for Phase 13.
   - Reason: It already compiles generated sources, owns the queue-state rendering helpers, and can absorb the minimal write-path and resolved-history support needed for this regression without adding a new harness. Split only if implementation reveals a concrete readability problem, not preemptively. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/evidence_test.exs] [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]

2. **Does Phase 13 need to pull resolved-history reads behind `Parapet.Operator` now?**
   - Resolution: No. Keep resolved-history seam cleanup deferred and out of Phase 13 scope unless the repaired runtime proof proves impossible without it.
   - Reason: The milestone audit identifies that branch as separate technical debt, and the locked phase boundary says not to widen the phase beyond the broken resolve lifecycle and proof gap by default. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and run ExUnit proof lanes | ✓ [VERIFIED: `command -v elixir`] | `1.19.5` [VERIFIED: elixir --version] | — |
| Mix | Run targeted verification commands and Hex metadata lookups | ✓ [VERIFIED: `command -v mix`] | `1.19.5` [VERIFIED: mix --version] | — |
| Node.js | Existing generator/test toolchain support in this repo | ✓ [VERIFIED: `command -v node`] | `v22.14.0` [VERIFIED: node --version] | — |
| Hex package metadata | Current Phoenix/LiveView/Igniter version checks | ✓ [VERIFIED: mix hex.info phoenix_live_view] | Current in-session lookup succeeded on 2026-05-23. [VERIFIED: mix hex.info phoenix_live_view] | Use `mix.lock` if offline, but release-date freshness is reduced. [VERIFIED: mix.lock] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: environment audit]

**Missing dependencies with fallback:**
- None. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: elixir --version] |
| Config file | `test/test_helper.exs`. [VERIFIED: repository inspection] |
| Quick run command | `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` [VERIFIED: local test run 2026-05-23] |
| Full suite command | `mix test` [VERIFIED: repository conventions] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| `SCALE-01.c` | Queue-side `"resolve"` keeps the bounded active-queue architecture intact while removing the resolved incident from the active lane. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md] | generator integration | `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | ✅ existing lane; needs new assertions and fake-repo write support. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] |
| `AC-03` | Phase 3 / Phase 7 acceptance truth is only considered satisfied after the repaired runtime proof is indexed by the current verification surfaces. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] | doc reconciliation + proof-link check | `rg -n "resolve_incident|record_note|Generated operator resolve action|Phase 3|Phase 7|SCALE-01.c|AC-03" .planning/v0.9-phases/3/VERIFICATION.md .planning/v0.9-phases/3/03-VALIDATION.md .planning/v0.9-phases/7/VERIFICATION.md .planning/v0.9-phases/7/07-VALIDATION.md docs/operator-ui.md` | ✅ files exist; wording needs repair after the runtime lane is updated. [VERIFIED: repository inspection] |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs` [VERIFIED: local test run 2026-05-23]
- **Per wave merge:** `mix test` [VERIFIED: repository conventions]
- **Phase gate:** Full targeted lane green, then proof-surface reconciliation checks green before `/gsd-verify-work`. [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]

### Wave 0 Gaps

- [ ] `test/parapet/generated_operator_live_paging_test.exs` — extend fake repo beyond read-only active queue so it can persist `resolve_incident/2` effects and serve resolved-history queries. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: lib/parapet/evidence.ex]
- [ ] `test/parapet/operator_ui_integration_test.exs` and/or `test/mix/tasks/parapet.gen.ui_test.exs` — add explicit queue resolve seam assertions for `Parapet.Operator.resolve_incident` and absence of `record_note` in that path. [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs]
- [ ] `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/3/03-VALIDATION.md`, `.planning/v0.9-phases/7/VERIFICATION.md`, `.planning/v0.9-phases/7/07-VALIDATION.md` — update wording so these files point at the repaired runtime proof and stop implying closure from an unexercised resolve path. [VERIFIED: .planning/v0.9-phases/3/VERIFICATION.md] [VERIFIED: .planning/v0.9-phases/7/VERIFICATION.md] [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: docs/operator-ui.md] | Generated UI must live inside the host app’s authenticated scope; Parapet does not ship auth ownership. [VERIFIED: docs/operator-ui.md] [VERIFIED: test/parapet/operator_ui_integration_test.exs] |
| V3 Session Management | yes [VERIFIED: docs/operator-ui.md] | Host-managed `live_session` / authenticated mount remains the standard control. [VERIFIED: docs/operator-ui.md] |
| V4 Access Control | yes [VERIFIED: docs/operator-ui.md] | Keep operator actions inside host-owned protected routes and do not widen mutation entrypoints. [VERIFIED: docs/operator-ui.md] [VERIFIED: AGENTS.md] |
| V5 Input Validation | yes [VERIFIED: lib/parapet/operator/action_payload.ex] | `Parapet.Operator.ActionPayload` validates required audit metadata before mutating commands proceed. [VERIFIED: lib/parapet/operator/action_payload.ex] |
| V6 Cryptography | no material change in this phase. [VERIFIED: phase scope] | Existing UUID/correlation ID generation remains unchanged. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] |

### Known Threat Patterns for Phoenix LiveView generated operator actions

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthenticated operator mutation surface | Spoofing / Elevation of Privilege | Preserve host-authenticated route mounting and doctor/auth guidance; Phase 13 should not move any auth boundary. [VERIFIED: docs/operator-ui.md] [VERIFIED: test/parapet/operator_ui_integration_test.exs] |
| UI action semantics drift from durable command semantics | Tampering | Route queue-side resolve through `Parapet.Operator.resolve_incident/2` so lifecycle semantics remain centralized and audited. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] |
| Missing audit trail on operator action | Repudiation | `resolve_incident/2` delegates to `Parapet.Evidence.run_operator_command/1`, which writes timeline and tool-audit evidence. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/evidence.ex] |

## Sources

### Primary (HIGH confidence)
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` - confirmed the broken queue `"resolve"` handler and current resolved-history branch. [VERIFIED: codebase]
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` - confirmed the already-correct resolve seam. [VERIFIED: codebase]
- `lib/parapet/operator.ex` - confirmed `resolve_incident/2` behavior, lifecycle evidence, and queue pagination seam. [VERIFIED: codebase]
- `lib/parapet/evidence.ex` - confirmed the transactional operator command seam. [VERIFIED: codebase]
- `test/parapet/generated_operator_live_paging_test.exs` - confirmed the current quick-run generated-runtime harness and its read-only limitation. [VERIFIED: codebase]
- `test/parapet/operator_ui_integration_test.exs`, `test/parapet/operator_ui_compile_out_test.exs`, `test/mix/tasks/parapet.gen.ui_test.exs` - confirmed current source-contract coverage and missing queue resolve assertion. [VERIFIED: codebase]
- `.planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md` - locked decisions, proof strategy, and scope constraints. [VERIFIED: codebase]
- `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/3/03-VALIDATION.md`, `.planning/v0.9-phases/7/VERIFICATION.md`, `.planning/v0.9-phases/7/07-VALIDATION.md` - current proof hierarchy and wording that Phase 13 must reconcile. [VERIFIED: codebase]
- `.planning/v0.9-MILESTONE-AUDIT.md` - current audit statement of the defect and proof blind spot. [VERIFIED: codebase]
- `mix hex.info phoenix_live_view`, `mix hex.info phoenix`, `mix hex.info igniter` - current locked-version and release-date checks. [VERIFIED: local tooling]
- `elixir --version`, `mix --version`, `node --version` - environment audit. [VERIFIED: local tooling]
- `https://hexdocs.pm/phoenix_live_view/live-navigation.html` - official LiveView `push_patch/2` and `handle_params/3` navigation guidance. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html` - official callback contracts for `handle_event/3` and `handle_params/3`. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` - official LiveView testing helpers. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html]

### Secondary (MEDIUM confidence)
- None. All material recommendations were grounded in codebase inspection, local tool output, or official docs. [VERIFIED: research session outputs]

### Tertiary (LOW confidence)
- None. [VERIFIED: research session outputs]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and roles were confirmed from `mix.lock`, `mix hex.info`, and code usage. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info igniter]
- Architecture: HIGH - the broken seam, correct seam, and proof boundaries are explicit in the templates, operator boundary, and phase context. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex] [VERIFIED: .planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md]
- Pitfalls: HIGH - each pitfall was observed directly in current code or commands, including the `-x` command drift. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: local test run 2026-05-23]

**Research date:** 2026-05-23
**Valid until:** 2026-06-22 for repo-local findings; re-check Hex package versions sooner if dependency decisions widen beyond this phase. [VERIFIED: phase scope] [VERIFIED: mix hex.info phoenix_live_view]
