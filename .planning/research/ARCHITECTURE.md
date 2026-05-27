# Architecture Research — v1.1 Actionable Recovery

**Domain:** Elixir/Phoenix OSS SRE Library — wiring executable recovery into the existing operator UI
**Researched:** 2026-05-27
**Confidence:** HIGH (all named modules read directly from source on `main`; integration points and data flow verified against live code)
**Supersedes:** the v0.10 baseline previously stored at this path (kept in git history)

---

## Executive Summary

**The biggest architectural finding is that v1.1 is mostly a wiring milestone, not a redesign.** Every load-bearing seam already exists on `main`:

- `Parapet.Operator.preview_runbook_step/3` and `Parapet.Operator.confirm_runbook_step/4` are **already implemented** in `lib/parapet/operator.ex` (lines 647–745).
- `Parapet.Capabilities` is **already a running Agent** supervised under `Parapet.Internal.Application`, with `register_recovery/2`, `get_recovery/1`, `capabilities/1`. It allowlists exactly three capability ids today: `:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check`.
- `Parapet.Runbook` DSL already accumulates `capability:`, `target_kind:`, `requires_preview:`, `preview_only:`, `warning:` per step.
- The generated `OperatorComponents` template already renders `preview_panel/1` with a "Confirm Recovery" button wired to `phx-click="confirm_mitigation"`, and `OperatorDetailLive` template already implements `handle_event("preview_mitigation", ...)` / `handle_event("confirm_mitigation", ...)` that call `Parapet.Operator.preview_runbook_step/3` and `confirm_runbook_step/4`.
- `Parapet.Operator.ActionPayload`, `Parapet.Automation.ClaimService`, `Parapet.Automation.CircuitBreaker`, and the `Parapet.Spine.ActionClaim` schema are all in place.

**What is _not_ in place — and what v1.1 must build:**

1. **`Parapet.Recovery` behaviour module** — does not exist. Host apps currently register actions via raw `Parapet.Capabilities.register_recovery/2` calls with anonymous functions, not via a behaviour. This is a documented gap the thread calls out as the v1.1 wedge (Shape candidate A).
2. **The Confirm path does not flow through `ClaimService`.** Today, `Parapet.Operator.confirm_runbook_step/4` calls `capability.execute.(incident, target_refs)` directly without a multi-node claim. The Oban auto-execution path (`Parapet.Automation.Executor`) _does_ claim; the operator-clicked path does _not_. This is the most important architectural defect to close.
3. **Six prebuilt playbooks** (retry storm, suppression drift, stalled async, dead-letter drain, deploy-tied incident, cardinality blowout) — none exist as host-app templates.
4. **Demo seed** — `examples/demo_app/priv/repo/seeds.exs` does not seed a recovery-eligible incident.
5. **`Parapet.Capabilities` allowlist** — hardcoded to three atoms. Six new prebuilt playbooks will require either expanding the allowlist or removing it.

The downstream consumer (the roadmap) should phase v1.1 as a series of small surgical PRs around an already-live skeleton, not a greenfield design.

---

## System Overview — Where v1.1 Lands in the Existing Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│                      EXISTING OPERATOR ARCHITECTURE                       │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  Host app's MyApp.Recovery module                                         │
│      ↓ (NEW v1.1: `use Parapet.Recovery`)                                 │
│  Parapet.Capabilities (Agent, supervised)         ← REGISTRY (exists)     │
│      ↓                                                                    │
│  Parapet.Operator.preview_runbook_step/3   ── reads Capabilities          │
│  Parapet.Operator.confirm_runbook_step/4   ── reads Capabilities + EXECS  │
│      ↑                                                                    │
│  Parapet.OperatorDetailLive (generated)    ── handle_event(preview/confirm)│
│      ↑                                                                    │
│  Operator clicks Preview / Confirm in browser                             │
│                                                                           │
│  ─── Parallel auto-execution path (already complete) ───                  │
│                                                                           │
│  Alertmanager webhook → Spine.Incident → Automation.Executor (Oban)       │
│      ↓                                                                    │
│  Automation.ClaimService (Ecto-backed multi-node claim)  ── GAP for UI    │
│      ↓                                                                    │
│  CircuitBreaker.gate/4 ── counts ToolAudit rows                           │
│      ↓                                                                    │
│  Operator.execute_runbook_step/3 → Runbook.execute_mitigation/2           │
│      ↓                                                                    │
│  Evidence.run_operator_command/1 → TimelineEntry + ToolAudit (one txn)    │
└───────────────────────────────────────────────────────────────────────────┘

v1.1 work is the diff between "UI button works" and "UI button claims + audits"
```

**Invariant for v1.1:** the operator-clicked path (Confirm) and the alert-driven path (Executor) must reach the **same** mitigation entry point through the **same** claim service and produce the **same** TimelineEntry / ToolAudit shape. Today they don't — the operator path skips `ClaimService`. Closing that gap is the architectural heart of v1.1.

---

## 1. The `Parapet.Recovery` Behaviour

### Recommendation: Mirror `Parapet.Integration` exactly in mechanism, but with a recovery-specific callback set

`Parapet.Integration` is a 27-line file. Its entire job is to declare `@callback setup() :: any()` so that `Parapet.attach(adapters: [...])` can call `adapter_module.setup/0` uniformly. It produces compile-time warnings for missing implementations and standardizes the activation seam.

`Parapet.Recovery` should follow the same convention pattern but expose the callbacks recovery actions actually need.

### Proposed shape

```elixir
defmodule Parapet.Recovery do
  @moduledoc """
  Behaviour for host-app recovery action modules.

  Host apps activate recovery actions uniformly via:

      Parapet.Recovery.attach([MyApp.Recovery.RetryDLQ, MyApp.Recovery.ClearSuppression])

  or by listing modules in config:

      config :parapet, recovery_actions: [MyApp.Recovery.RetryDLQ, ...]
  """

  @doc "Stable atom identifying this action across audit logs and the runbook DSL."
  @callback id() :: atom()

  @doc "Human-readable label for the operator UI Preview header."
  @callback label() :: String.t()

  @doc "Optional target_kind hint (e.g. :async_item, :queue, :provider, :feature_flag)."
  @callback target_kind() :: atom() | nil

  @doc """
  Compute the Preview payload from the incident.
  Returns {:ok, %{count: integer, target_refs: list, warnings: list, ...}}
  or {:error, reason} to block the Preview from rendering.
  """
  @callback preview(incident :: Parapet.Spine.Incident.t(), step :: map()) ::
              {:ok, map()} | {:error, term()}

  @doc """
  Execute the bounded mutation given the previewed scope. MUST be idempotent
  against the target_refs returned by preview/2.
  """
  @callback execute(incident :: Parapet.Spine.Incident.t(), target_refs :: list()) ::
              {:ok, map()} | {:error, term()}

  @optional_callbacks [target_kind: 0]

  defmacro __using__(_opts) do
    quote do
      @behaviour Parapet.Recovery
      def target_kind, do: nil
      defoverridable target_kind: 0
    end
  end

  @doc """
  Registers a list of recovery action modules into Parapet.Capabilities.
  Idempotent — safe to call multiple times.
  """
  def attach(modules) when is_list(modules) do
    Enum.each(modules, fn module ->
      if Code.ensure_loaded?(module) and function_exported?(module, :id, 0) do
        Parapet.Capabilities.register_recovery(module.id(),
          name: module.label(),
          target_kind: module.target_kind(),
          preview: &module.preview/2,
          execute: &module.execute/2
        )
      end
    end)
  end
end
```

### Why this differs from `Parapet.Integration`

| Aspect | `Parapet.Integration` | `Parapet.Recovery` (proposed) |
|--------|----------------------|-------------------------------|
| Callback count | 1 (`setup/0`) | 4 (`id/0`, `label/0`, `preview/2`, `execute/2`) + 1 optional |
| Activation entry point | `Parapet.attach(adapters: [...])` | `Parapet.Recovery.attach([...])` (separate seam) |
| Registration mechanism | Module name lookup at call time (`Code.ensure_loaded?`) | Pushes into `Parapet.Capabilities` Agent state |
| Compile-out behavior | Module simply isn't called if missing | Module simply isn't registered if missing |
| Allowlist | None | Inherits the `Parapet.Capabilities @valid_capabilities` allowlist (which must be widened — see below) |

The mechanism is the same idiom (behaviour + uniform activation function). The callback set is larger because preview/execute are core to the recovery model in a way that `setup/0` is not for telemetry attachment.

### Critical companion change: widen `Parapet.Capabilities @valid_capabilities`

`Parapet.Capabilities.register_recovery/2` today raises `ArgumentError` for any id not in:

```elixir
@valid_capabilities [:retry_async_item, :requeue_dead_letter, :request_manual_provider_check]
```

The six v1.1 playbooks need ids like `:back_off_retry_intent`, `:clear_suppression_bounded`, `:requeue_stalled_async`, `:drain_dead_letter`, `:revert_correlated_flag`, `:disable_high_cardinality_label`. The allowlist must either be:

- **Option A (recommended):** widened to include the six new ids explicitly. Keeps the allowlist as a documented contract.
- **Option B:** removed entirely; let host apps register any atom. Loses the safety rail.

**Recommendation: Option A.** The allowlist is a real safety boundary that prevents typos becoming runtime capability holes. It's already a documented v1.x experimental surface.

### Where the behaviour module lives

`lib/parapet/recovery.ex` — new module, sibling to `lib/parapet/integration.ex`.

---

## 2. Registry / Dispatcher — Don't Add a New One

### Recommendation: Reuse `Parapet.Capabilities` (existing Agent) — no new GenServer

The brief asks whether parapet needs a new GenServer/registry. **It does not.** `Parapet.Capabilities` is already:

- A supervised `Agent` (line 20 of `lib/parapet/capabilities.ex`).
- Started in `Parapet.Internal.Application.start/2` (`{Parapet.Capabilities, []}`).
- Exposes `register_recovery/2`, `get_recovery/1`, `capabilities/1`.
- Already used by `Parapet.Operator.preview_runbook_step/3` (line 657) and `Parapet.Operator.confirm_runbook_step/4` (line 705).

The thread proposes "Shape candidate A (compile-time-safe Behaviour)" vs "Shape candidate B (runtime registry)" — but the registry already exists either way. The thread's real question is whether **how host apps populate it** should be compile-time-checked (Behaviour) or pure-runtime (raw `register_recovery/2` calls). The Behaviour wins by giving dialyzer + compile warnings without removing the runtime Agent.

### Application-env vs Agent: defer this to v1.2

The downstream-consumer note mentions "registry-state-off-Application-env thread is v1.2's problem." The current implementation already keeps registry state in the Agent, **not** in `Application.put_env`. That's good — Application env is the wrong place for cross-node mutable state and the existing design already avoids it. v1.2 can revisit whether the Agent itself is the right home (vs. ETS, Registry, or compile-time module attribution), but v1.1 inherits a working design.

**v1.1 does not need to touch this seam.** The Agent is fine for single-node read-mostly workloads. Operator UI click rates are measured in clicks/hour, not requests/sec.

### Why compile-time module attribution alone is not enough

A pure compile-time approach (e.g. `@behaviour Parapet.Recovery` modules discovered via `:code.all_loaded`) would:
- Break under hot code reload and dynamic adapter loading.
- Force a recompile to add or remove a recovery action.
- Lose the ability to do per-environment activation (`config :parapet, recovery_actions: [...]` differs in dev vs prod).
- Lose `target_kind` and `preview/execute` function captures, which are not easily reconstructed from compile-time module metadata.

The Behaviour + `attach/1` + Agent design captures the best of both: dialyzer/compile-warning safety from the Behaviour, runtime flexibility from `Parapet.Recovery.attach/1`.

---

## 3. Operator UI Integration

### What already exists in `priv/templates/parapet.gen.ui/`

Three EEx templates generate into the host app's `lib/<host>_web/live/parapet/`:

| Generated file | What it does today | v1.1 change |
|---------------|--------------------|-------------|
| `operator_live.ex` | Queue index LiveView | None |
| `operator_detail_live.ex` | Detail LiveView with `handle_event("preview_mitigation", ...)` and `handle_event("confirm_mitigation", ...)` already calling `Parapet.Operator.preview_runbook_step/3` and `confirm_runbook_step/4` | Minor: pass through registered recovery actions and improved flash messages on `{:short_circuited, ...}` / `{:conflicted, ...}` paths once Confirm routes through ClaimService |
| `operator_components.ex` | Renders `runbook_card/1`, `preview_panel/1` with "Confirm Recovery" button, warning blocks | Minor: render new claim-conflict / circuit-breaker badges; otherwise no shape change |

### What v1.1 actually adds to `Parapet.OperatorComponents`

Reading the existing `operator_components.ex.eex` template, the recovery UI is already wired:

- Line 281: `runbook_card/1` iterates `step.state` (`:guidance`, `:executable`, `:previewable`, `:executed`).
- Lines 319–325: Preview / Execute buttons with `phx-click="preview_mitigation"`.
- Lines 343–403: `preview_panel/1` with target_kind, count, warnings, idempotency caveats, and the Confirm button.
- Line 387: `phx-click="confirm_mitigation"`.

**The UI does not need new components.** The work in `OperatorComponents` is content additions:

1. A small `claim_state_badge/1` component to render `claimed` / `executed` / `conflicted` / `short_circuited` from the new `ActionClaim` row associated with the step. (Existing template uses `step.state == :executed` — needs to also consider claim state.)
2. A circuit-breaker indicator when `Parapet.Automation.CircuitBreaker.allow?/2` returns `false` for the step — currently the operator can click Preview and see no warning about a near-trip; the breaker only fires under the Oban auto-exec path.

### What's generated into `lib/<host>_web/live/parapet/`

The three files above are generated once via `mix parapet.gen.ui` (or `mix parapet.install --with-ui`). They are host-owned with `on_exists: :skip` semantics. v1.1 must **not** break the host-owned contract: any changes to template content go into `priv/templates/parapet.gen.ui/*.eex` and only affect new adopters running the generator after v1.1.

For existing adopters, parapet must document in CHANGELOG.md the manual diff to apply (e.g., the `confirm_mitigation` handler now expects `{:short_circuited, reason}` returns from `Parapet.Operator.confirm_runbook_step/4`).

### New file in the generator (optional, v1.2): per-action recovery module scaffold

The runbook generator already exists (`mix parapet.gen.runbooks`). A natural v1.1+ companion is `mix parapet.gen.recovery <action_id>` which scaffolds a `MyApp.Recovery.<Action>` module implementing the new `Parapet.Recovery` behaviour. **The thread notes the Igniter flag-based idiom guidance applies** (`prompts/V1-SLO-WIZARD-BUNDLES.md`). This is a stretch goal for v1.1 — not load-bearing for the wedge.

---

## 4. Data Flow on Confirm Click — Module-by-Module Trace

### Today (live on `main`)

```
Browser: operator clicks "Confirm Recovery"
    ↓ phx-click="confirm_mitigation" with step, incident_id, token
    
<HostApp>Web.Parapet.OperatorDetailLive.handle_event/3
  (file: lib/<host>_web/live/parapet/operator_detail_live.ex, generated)
    ↓ builds %Parapet.Operator.ActionPayload{action_type: :execute_mitigation,
                                              idempotency_key: Ecto.UUID.generate()}

Parapet.Operator.confirm_runbook_step/4
  (file: lib/parapet/operator.ex, lines 690–745)
    ↓ valid_payload? check (line 696)
    ↓ extract_module from incident.runbook_data (line 697)
    ↓ parse_step_id (line 698)
    ↓ Parapet.Capabilities.get_recovery(capability_id) (line 705)
    ↓ find_recent_preview/3 — looks up "recovery_preview" TimelineEntry by token (line 706)
    ↓ Verifies preview hasn't expired (line 707)
    ↓ *** DIRECT CALL: capability.execute.(incident, target_refs) (line 710) ***
    ↓ Evidence.run_operator_command/1 (line 723)
        ├── inserts incident_changeset (no-op change) 
        ├── inserts TimelineEntry of type "recovery_confirmed"
        └── inserts ToolAudit with tool_name="operator_confirm_recovery"
    ↓ returns {:ok, %{...}}

OperatorDetailLive: assigns updated incident_detail, flashes "Mitigation confirmed and executed"
```

**Gap:** no `ClaimService.claim_action/1`. No `ActionClaim` row. No multi-node coordination. No circuit breaker check before execute. The auto-execution path (`Parapet.Automation.Executor`) has all of these; the operator-clicked path skips them.

### Target (v1.1)

```
Browser: operator clicks "Confirm Recovery"
    ↓ phx-click="confirm_mitigation" with step, incident_id, token
    
<HostApp>Web.Parapet.OperatorDetailLive.handle_event("confirm_mitigation", ...)
    ↓ builds %ActionPayload{action_type: :execute_mitigation, idempotency_key: <ui_token>}

Parapet.Operator.confirm_runbook_step/4   *** MODIFIED ***
    ↓ valid_payload?
    ↓ extract_module / parse_step_id
    ↓ Parapet.Capabilities.get_recovery(capability_id)
    ↓ find_recent_preview + expiry check
    ↓ *** NEW: Parapet.Automation.ClaimService.claim_action/1 ***
        idempotency_key: payload.idempotency_key (NOT a fresh UUID — use the one from preview token chain)
        action_kind: "operator"     ← distinguishes from "automation"
        action_key: step_id
        breaker_step_id: step_id    ← engages CircuitBreaker
    ↓ {:won, claim}
        ↓ capability.execute.(incident, target_refs)
        ↓ Evidence.run_operator_command/1 → TimelineEntry "recovery_confirmed" + ToolAudit
        ↓ ClaimService.mark_executed/1
        ↓ returns {:ok, result}
    ↓ {:short_circuited, _claim, reason}
        ↓ append TimelineEntry "recovery_short_circuited" with reason
        ↓ returns {:error, {:short_circuited, reason}}
    ↓ {:conflicted, claim}
        ↓ returns {:error, {:conflicted, claim.id}}

OperatorDetailLive handle_event branches on the new error variants:
    ↓ {:short_circuited, :circuit_breaker_tripped} → flash "Recovery short-circuited: circuit breaker tripped"
    ↓ {:conflicted, _} → flash "Another node is already executing this recovery"
    ↓ default → existing flash
```

### Module path summary (v1.1 target)

| Layer | Module | Function | Notes |
|-------|--------|----------|-------|
| UI event | `<HostApp>Web.Parapet.OperatorDetailLive` | `handle_event("confirm_mitigation", ...)` | Generated; host-owned |
| Public API | `Parapet.Operator` | `confirm_runbook_step/4` | Stable v1.0 (frozen). v1.1 changes the **internal flow** but the function signature and return contract must remain backward-compatible. Adding new `{:error, {:short_circuited, ...}}` return shapes is additive. |
| Claim | `Parapet.Automation.ClaimService` | `claim_action/1` | Already exists; called by `Automation.Executor`. v1.1 calls it from the operator path too. |
| Breaker | `Parapet.Automation.CircuitBreaker` | `gate/4` | Already engaged by ClaimService when `breaker_step_id` opt is supplied. |
| Registry lookup | `Parapet.Capabilities` | `get_recovery/1` | Already exists. |
| Capability execute | `module.execute/2` via `Parapet.Recovery` behaviour | `execute/2` | Behaviour callback in host module (new in v1.1). |
| Audit | `Parapet.Evidence` | `run_operator_command/1` | Existing transactional Incident + TimelineEntry + ToolAudit insert. |
| Storage | `Parapet.Spine.{Incident,TimelineEntry,ToolAudit,ActionClaim}` | (schemas) | All exist. v1.1 does **not** add new schemas. |

### Where error/recovery branches live

| Failure | Module | Branch |
|---------|--------|--------|
| Invalid payload | `Parapet.Operator.confirm_runbook_step/4` | `{:error, :invalid_payload}` |
| Missing runbook | `Parapet.Operator.extract_module/1` | `{:error, :missing_runbook}` |
| Unknown step | `Parapet.Operator.validate_step_exists/1` | `{:error, :step_not_found}` |
| Capability unregistered | `Parapet.Capabilities.get_recovery/1` returns nil → `Parapet.Operator.confirm_runbook_step/4` | `{:error, :capability_unwired}` |
| Stale preview token | `Parapet.Operator.confirm_runbook_step/4` | `{:error, :stale_preview}` |
| **NEW v1.1: Circuit breaker tripped** | `Parapet.Automation.ClaimService.run_gates/3` → `breaker_gate/3` | `{:short_circuited, claim, "circuit_breaker_tripped"}` |
| **NEW v1.1: Multi-node race lost** | `Parapet.Automation.ClaimService.acquire_claim/2` | `{:conflicted, existing_claim}` |
| **NEW v1.1: Incident already resolved** | `ClaimService.incident_state_gate/1` | `{:short_circuited, claim, "already_resolved"}` |
| Capability execute returned error | host's `execute/2` callback | `{:error, host_reason}` |

The new v1.1 branches are inherited for free by routing the operator path through ClaimService.

---

## 5. Build Order — Dependency-Aware Phase Decomposition

This ordering ensures each piece is testable when its consumers reference it.

### Phase 1: Behaviour + Registry Widening (Foundation, unblocked)

**Deliverables:**
- `lib/parapet/recovery.ex` — `Parapet.Recovery` behaviour module
- `lib/parapet/capabilities.ex` — widen `@valid_capabilities` to include the six new ids
- `test/parapet/recovery_test.exs` — behaviour-conformance helpers + `attach/1` idempotency
- `test/parapet/capabilities_test.exs` — extend existing test to assert the new ids

**Rationale:** This is the public-API foundation. Every downstream piece (playbooks, demo, docs, UI wiring) references either `use Parapet.Recovery` or one of the new capability ids. Must land first so the playbook modules in Phase 3 compile against a real behaviour.

**Does not depend on:** anything new.

**Blocks:** Phase 3 (playbooks need the behaviour), Phase 4 (demo seed), Phase 6 (docs).

### Phase 2: Wire Confirm path through `ClaimService` (Architectural fix)

**Deliverables:**
- `lib/parapet/operator.ex` — modify `confirm_runbook_step/4` to invoke `Parapet.Automation.ClaimService.claim_action/1` with `action_kind: "operator"`, `breaker_step_id: step_id`. Branch on `{:won, _}` / `{:short_circuited, _, _}` / `{:conflicted, _}`.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — `handle_event("confirm_mitigation", ...)` branches on the new error shapes with operator-friendly flash messages.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — add `claim_state_badge/1` and surface circuit-breaker state visually.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` — regenerate or hand-apply the same changes (drift smoke test).
- `test/parapet/operator_test.exs` — add cases for short-circuit, conflict, breaker-tripped on the Confirm path.

**Rationale:** This closes the architectural gap (the operator path skipping the claim service) before any new playbook lands. If new playbooks land first, every test would silently exercise the broken path.

**Depends on:** Phase 1 (the behaviour stabilizes the capability registration shape).

**Blocks:** Phase 3 (playbooks rely on the claim-protected path to make their idempotency guarantees real).

### Phase 3: Six Prebuilt Recovery Playbooks (Host-app templates)

**Deliverables:**
- `priv/templates/parapet.gen.recovery/retry_storm.ex.eex`
- `priv/templates/parapet.gen.recovery/suppression_drift.ex.eex`
- `priv/templates/parapet.gen.recovery/stalled_async.ex.eex`
- `priv/templates/parapet.gen.recovery/dead_letter_drain.ex.eex`
- `priv/templates/parapet.gen.recovery/deploy_tied_incident.ex.eex`
- `priv/templates/parapet.gen.recovery/cardinality_blowout.ex.eex`
- `lib/mix/tasks/parapet.gen.recovery.ex` — new generator (Igniter `copy_template` with `on_exists: :skip`)
- Companion runbook templates updated in `priv/templates/parapet.gen.runbooks/*.ex.eex` to reference the new capability ids via the existing `capability:` step attribute.

**Rationale:** Templates encode the "Behaviour shape" landed in Phase 1 and exercise the claim-protected Confirm path landed in Phase 2. Each template is a generated host-owned `MyApp.Recovery.<Action>` module that `use Parapet.Recovery`.

**Depends on:** Phase 1 (behaviour exists), Phase 2 (Confirm path is correct).

**Blocks:** Phase 4 (demo seed wires one of these), Phase 6 (docs reference the templates by name).

### Phase 4: Demo Seed + Smoke Test

**Deliverables:**
- `examples/demo_app/priv/repo/seeds.exs` — seed at least one open incident with `runbook_data["module"]` pointing to a generated `DemoApp.Recovery.<Action>` and a step whose `capability:` matches.
- `examples/demo_app/lib/demo_app/recovery/` — generated recovery action modules (one is enough for the demo; the rest are demo-able).
- `examples/demo_app/lib/demo_app/application.ex` — `Parapet.Recovery.attach([DemoApp.Recovery.RetryDLQ, ...])` in `start/2`.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` — extend to assert Preview renders then Confirm executes and records `recovery_confirmed` TimelineEntry.

**Rationale:** This is the smoke test for the wedge. A fresh `iex -S mix phx.server` in `examples/demo_app/` shows a runbook with a Preview-able + Confirm-able action. The CI smoke test asserts the full chain works end-to-end.

**Depends on:** Phase 3 (templates exist to generate from).

### Phase 5: Audit Propagation Verification + ToolAudit Schema Validation

**Deliverables:**
- `test/parapet/operator_audit_propagation_test.exs` — assert every Confirm produces both a `TimelineEntry` of type `recovery_confirmed` (or `recovery_short_circuited`) AND a `ToolAudit` row with the correct `tool_name` and `input` map.
- `test/parapet/automation/claim_service_test.exs` — extend to cover the `action_kind: "operator"` case.

**Rationale:** Lightweight verification phase. The audit emission is already correct in `Evidence.run_operator_command/1`; this phase just proves it under all three terminal outcomes (won, short-circuited, conflicted).

**Depends on:** Phase 2, Phase 3.

### Phase 6: Documentation + CHANGELOG Migration Notes

**Deliverables:**
- `docs/operator-ui.md` — Phase 7 section updated to describe the claim-protected Confirm path.
- `docs/integrations/recovery-actions.md` (new) — host-app guide for writing a `Parapet.Recovery` module.
- `CHANGELOG.md` — Release Please entry calling out:
  - New `Parapet.Recovery` behaviour
  - New `mix parapet.gen.recovery` task
  - Widened `Parapet.Capabilities` allowlist
  - Confirm path now claims (additive return variants; existing `{:ok, _}` / `{:error, atom}` returns unchanged)
- Update `prompts/parapet-engineering-dna-from-sibling-libs.md` references if needed (probably not — that's research material, not adopter docs).

**Rationale:** Docs go last so they describe what shipped, not what was planned. Migration notes mention the new error variants so adopters who already customized their generated `OperatorDetailLive` can hand-apply the new branches.

**Depends on:** all prior phases.

### Phase ordering rationale (summary)

```
P1 (Behaviour + Allowlist) ──→ P2 (Claim Confirm) ──→ P3 (Playbooks)
                                                          │
                                                          ▼
                                                   P4 (Demo Seed)
                                                          │
                                                          ▼
                                                   P5 (Audit Tests)
                                                          │
                                                          ▼
                                                   P6 (Docs/Changelog)
```

**Why P2 must precede P3, not the other way around:** if playbooks land first, every adopter who runs `mix parapet.gen.recovery` between P3 and P2 gets templates whose generated Confirm path will work but won't be claim-protected. Closing the gap second creates a v1.1.1 patch obligation. Closing it first is the conservative path.

**Why P1 must precede P2:** Phase 2 doesn't strictly _require_ the behaviour, but adding new error branches to a public function whose return shape will then change again in Phase 1 (when the behaviour shifts how `execute/2` errors are surfaced) doubles the test churn.

---

## 6. Compile-Out-Cleanly Constraint

### How it works in `Parapet.Integration`

`Parapet.Integration` itself is a small behaviour module. The adapter modules under `lib/parapet/integrations/` use `Code.ensure_loaded?` at the call site in `Parapet.attach/1`:

```elixir
# lib/parapet.ex lines 41–43
if Code.ensure_loaded?(module) do
  apply(module, :setup, [])
end
```

If the host hasn't compiled the adapter (because it doesn't depend on the underlying library), `Code.ensure_loaded?` returns false and the call is skipped.

### Applying the same mechanism to `Parapet.Recovery`

The `Parapet.Recovery` behaviour module itself is always compiled — it's part of `parapet` core, just like `Parapet.Integration`. There's no per-integration dependency for the behaviour module itself.

The compile-out concern applies to **host recovery action modules** that depend on host-side ecosystem libraries. For example, `DemoApp.Recovery.RetryDLQ` depends on `Oban`. If Oban isn't a dependency, the module shouldn't break compilation.

**Pattern:** wrap the entire recovery action module in `Code.ensure_loaded?` at compile time, the same way `Parapet.Automation.Executor` does:

```elixir
# lib/parapet/automation/executor.ex line 1
if Code.ensure_loaded?(Oban.Worker) do
  defmodule Parapet.Automation.Executor do
    use Oban.Worker, ...
    # ...
  end
end
```

A generated host playbook for stalled async would follow the same shape:

```elixir
# Generated into lib/<host>/recovery/stalled_async.ex
if Code.ensure_loaded?(Oban) do
  defmodule <%= inspect(@app_module) %>.Recovery.StalledAsync do
    use Parapet.Recovery

    @impl true
    def id, do: :requeue_stalled_async
    @impl true
    def label, do: "Requeue Stalled Async Jobs"
    @impl true
    def target_kind, do: :async_item
    @impl true
    def preview(incident, _step), do: # ... reads Oban queue state
    @impl true
    def execute(incident, target_refs), do: # ... requeues
  end
end
```

If Oban is absent from the host app, the module never compiles, `Parapet.Recovery.attach/1` filters it out via `Code.ensure_loaded?(module)`, and `Parapet.Capabilities.get_recovery(:requeue_stalled_async)` returns nil. The UI then shows the step as `:guidance` (advisory only) instead of `:executable`, because the `Parapet.Operator.WorkbenchContract.derive_runbook_steps/3` logic checks capability presence via existing pathways.

### The three layers that must all compile-out cleanly

| Layer | Mechanism | Failure mode if dep missing |
|-------|-----------|----------------------------|
| `Parapet.Recovery` behaviour itself | None — no host deps | Always compiles (part of parapet core) |
| Generated host recovery module | Wrap in `if Code.ensure_loaded?(HostDep)` | Module simply isn't defined |
| `Parapet.Recovery.attach/1` | `Code.ensure_loaded?(module)` per-arg | Skips missing modules silently |
| Lookup at click time | `Parapet.Capabilities.get_recovery/1` returns nil | UI degrades step to `:guidance` |

The pattern is well-established in the codebase. v1.1 should make the compile-out guard a **mandatory comment in the generator template** (the EEx file in `priv/templates/parapet.gen.recovery/`) so every generated playbook follows the pattern. This matches how `lib/parapet/automation/executor.ex` already protects itself.

### What v1.1 must NOT do

- **Do not** introduce a runtime `Application.get_env(:parapet, :recovery_enabled?)` flag. The compile-out happens at module-definition time, not at call time.
- **Do not** add hard runtime calls to host-side libraries from anything in `lib/parapet/recovery.ex`. The behaviour module is generic.
- **Do not** put recovery action modules in `lib/parapet/recovery/<action>.ex` — those would be parapet-owned and unable to compile out cleanly when their host deps are absent. They live in host apps via `priv/templates/parapet.gen.recovery/`.

---

## Component Inventory: New vs Modified

### New Components

| Component | Type | Location | Notes |
|-----------|------|----------|-------|
| `Parapet.Recovery` | New behaviour module | `lib/parapet/recovery.ex` | 4 callbacks + `attach/1`; mirrors `Parapet.Integration` idiom |
| `mix parapet.gen.recovery` | New Mix task | `lib/mix/tasks/parapet.gen.recovery.ex` | Igniter `copy_template` with `on_exists: :skip` |
| `retry_storm.ex.eex` + 5 siblings | New templates | `priv/templates/parapet.gen.recovery/` | One per JTBD-MAP failure mode |
| `recovery-actions.md` | New doc | `docs/integrations/` | Host-app authoring guide for `Parapet.Recovery` modules |
| Demo recovery actions | New host code | `examples/demo_app/lib/demo_app/recovery/` | At least one for the smoke test |
| Demo recovery seed | New seed data | `examples/demo_app/priv/repo/seeds.exs` (extended) | One open incident with a Preview-able + Confirm-able runbook step |

### Modified Components

| Component | File | Change | Why |
|-----------|------|--------|-----|
| `Parapet.Capabilities` | `lib/parapet/capabilities.ex` | Widen `@valid_capabilities` from 3 to 9 atoms (or remove the allowlist) | Six new playbooks need new ids |
| `Parapet.Operator.confirm_runbook_step/4` | `lib/parapet/operator.ex` lines 690–745 | Wrap `capability.execute.(...)` call in `Parapet.Automation.ClaimService.claim_action/1` with `action_kind: "operator"` and `breaker_step_id: step_id`; branch on `{:short_circuited, _, _}` and `{:conflicted, _}` | Operator path must claim like the auto-execution path does; closes the multi-node + breaker gap |
| `Parapet.Operator.preview_runbook_step/3` | `lib/parapet/operator.ex` lines 647–683 | Pass `target_refs` from `preview/2` callback explicitly so Confirm has them | Preview-to-Confirm continuity for idempotency |
| `OperatorDetailLive` template | `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` lines 123–142 | Branch on new `{:error, {:short_circuited, ...}}` / `{:error, {:conflicted, _}}` shapes with operator-friendly flash messages | Surface the new claim outcomes |
| `OperatorComponents` template | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | Add `claim_state_badge/1`; surface CircuitBreaker state in `runbook_card/1` | Operator visibility into breaker / conflict state |
| Existing runbook templates | `priv/templates/parapet.gen.runbooks/*.ex.eex` | Reference new capability ids in `step capability: :...` attributes where appropriate | Wire prebuilt playbooks into prebuilt runbooks |
| `Parapet.Operator.WorkbenchContract` | `lib/parapet/operator/workbench_contract.ex` lines 119–165 | Optionally extend `derive_runbook_steps/3` to project claim state into `step.state` | UI cleanliness; not strictly required if `claim_state_badge/1` reads claims separately |
| `examples/demo_app/lib/demo_app/application.ex` | demo app supervision tree | Call `Parapet.Recovery.attach([DemoApp.Recovery.RetryDLQ, ...])` | Activate registered actions for the demo |
| `CHANGELOG.md` | repo root | Document additive return variants on `confirm_runbook_step/4`; new behaviour; new task | Release Please consumption |

### No new components required

| What was considered | Why not needed |
|---------------------|---------------|
| New GenServer for recovery dispatch | `Parapet.Capabilities` Agent already supervised and used by `Parapet.Operator` |
| New Ecto schemas | `Incident`, `TimelineEntry`, `ToolAudit`, `ActionClaim` cover preview/confirm/short-circuit/conflict |
| New Oban queue | Operator-clicked Confirm is synchronous in the LiveView process; auto-exec already uses `Parapet.Automation.Executor` on `:default` queue |
| Compile-time recovery module discovery | The Behaviour + `attach/1` + Agent pattern is idiomatic and avoids hot-reload pain |
| New Application env keys | All config flows through `config :parapet, recovery_actions: [...]` + `Parapet.Recovery.attach/1` |
| New `Parapet.Operator.execute_recovery/4` public function | `confirm_runbook_step/4` is already the public seam; widening its internal behavior is additive |

---

## Architectural Patterns

### Pattern 1: Behaviour as the host-app extension point (mirrors Integration)

**What:** Every host-app extension point in parapet is a `@behaviour Parapet.<Name>` + a uniform `Parapet.<Name>.attach/1` (for Integration, `Parapet.attach(adapters: [...])`). v1.1 adds `Parapet.Recovery` with the same shape.

**When to use:** Any new host-side plug point — recovery actions, notifiers, evidence sources.

**Trade-offs:** Behaviours give dialyzer + compile warnings; the cost is that adding a new callback later is a breaking change for adopters. v1.1's 4-callback design should be considered carefully because callback addition is a breaking change.

**Key invariant:** Compile-out cleanly. If a host's recovery module wraps in `if Code.ensure_loaded?(HostDep)`, `Parapet.Recovery.attach/1` skips it silently when missing.

### Pattern 2: Single claim service for both auto and operator paths

**What:** Both the alert-driven `Parapet.Automation.Executor` (Oban) path and the operator-clicked `Parapet.Operator.confirm_runbook_step/4` path route their mitigation execution through `Parapet.Automation.ClaimService.claim_action/1`. The `action_kind` field on `ActionClaim` distinguishes them (`"automation"` vs `"operator"`).

**When to use:** Whenever a recovery action could be triggered from multiple sources (operator, automation, MCP) and multi-node coordination matters.

**Trade-offs:** Adds a DB round-trip to every operator click. At operator click rates (clicks/hour), this is invisible. Gains: free circuit breaker, free multi-node race protection, free idempotency, free claim-as-evidence for post-incident review.

**Key invariant:** `action_kind` must be set per source. Mixing operator and automation under the same `action_kind` would let a busy operator unintentionally trip the circuit breaker against themselves.

### Pattern 3: ActionPayload as the audit-contract entry seam (already established)

**What:** Every mutating operator command receives an `ActionPayload` struct that validates `actor`, `reason`, `correlation_id`, and (for `:execute_mitigation`) `idempotency_key`. The struct is the trust boundary.

**When to use:** Always. v1.1 inherits this without change.

**Trade-offs:** Slight verbosity. Worth it — every audit row downstream traces back to a validated payload.

**Key invariant:** Generated LiveView code MUST build a fresh `ActionPayload` per `handle_event` and MUST set `action_type: :execute_mitigation` with a fresh `idempotency_key` for the Confirm step.

### Pattern 4: Compile-out cleanly via `Code.ensure_loaded?` wrapping (already established)

**What:** Modules that depend on optional host libraries wrap their entire `defmodule` in `if Code.ensure_loaded?(Dep) do ... end`. Already used by `Parapet.Automation.Executor` (Oban).

**When to use:** Every generated host recovery action that depends on an ecosystem library.

**Trade-offs:** Hides the module from `iex` autocomplete when dep is absent. That's fine — if the dep is absent the module shouldn't be callable anyway.

**Key invariant:** The `Parapet.Recovery.attach/1` function must call `Code.ensure_loaded?(module)` before invoking callbacks, so wrapped-out modules in the recovery_actions config silently drop.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Adding a parallel registry for recovery actions

**What people do:** Create `Parapet.Recovery.Registry` GenServer separate from `Parapet.Capabilities`.

**Why it's wrong:** `Parapet.Capabilities` is the existing recovery registry. Adding a second one means `Parapet.Operator.confirm_runbook_step/4` would need to query both, and the two could drift. The Phase 7 design already chose `Parapet.Capabilities`; v1.1 inherits.

**Do this instead:** Keep using `Parapet.Capabilities`. `Parapet.Recovery.attach/1` writes into it via the existing `register_recovery/2` API.

### Anti-Pattern 2: Skipping ClaimService on the operator path "because it's synchronous"

**What people do:** Argue that since the operator is a single human clicking once, `ClaimService` is unnecessary overhead.

**Why it's wrong:** Multiple operators can click Confirm concurrently from different sessions; one node can be processing a Confirm while another node's automation worker tries the same action; the circuit breaker is not engaged when the operator path skips claiming. The alert-driven path already proved you need claims for these — the operator path has the exact same risk profile.

**Do this instead:** Always claim. `action_kind: "operator"` distinguishes the source for audit trail without removing the protection.

### Anti-Pattern 3: Inventing new TimelineEntry types per playbook

**What people do:** Add `retry_storm_executed`, `suppression_drift_executed`, `dead_letter_drained` as distinct TimelineEntry types.

**Why it's wrong:** TimelineEntry types are an audit-discoverable surface. Adding playbook-specific types means every consumer (the retrospective generator, the UI timeline renderer, doctor checks) needs to learn each new type. The existing `recovery_confirmed` and `mitigation_executed` types already capture this; the **payload** carries the playbook identity via `capability_id`.

**Do this instead:** Keep `recovery_confirmed` (operator path) and `mitigation_executed` (automation path) as the canonical types. Encode playbook identity in the payload.

### Anti-Pattern 4: Removing the `@valid_capabilities` allowlist instead of widening it

**What people do:** Treat the allowlist as a v1.0 mistake and rip it out so any atom can be a capability id.

**Why it's wrong:** The allowlist is a deliberate typo-prevention rail. A typo in a runbook template (`:retri_storm` instead of `:retry_storm`) currently fails loudly at registration with `ArgumentError`. Without the allowlist, it would fail silently at click time when `get_recovery/1` returns nil.

**Do this instead:** Widen the allowlist to the union of v1.0 + v1.1 capabilities. Document the list in `@valid_capabilities` with a comment citing where each id is consumed.

### Anti-Pattern 5: Per-playbook handler events in the generated LiveView

**What people do:** Generate `handle_event("preview_retry_storm", ...)`, `handle_event("preview_suppression_drift", ...)` etc., one per playbook.

**Why it's wrong:** Every new playbook then requires a generator change. The existing `preview_mitigation` / `confirm_mitigation` events with `phx-value-step` already dispatch by step id, and step id maps to capability id via the runbook DSL. Six playbooks = zero new event handlers needed.

**Do this instead:** Keep one `preview_mitigation` and one `confirm_mitigation` event. Use `phx-value-step` for routing.

### Anti-Pattern 6: Putting recovery action modules in `lib/parapet/recovery/<action>.ex`

**What people do:** Define `Parapet.Recovery.RetryStorm`, `Parapet.Recovery.SuppressionDrift` inside the parapet hex package.

**Why it's wrong:** Those modules would depend on host-side libraries (Oban, Mailglass, Rulestead). Either parapet hard-depends on them (breaks "compile out cleanly") or every module is wrapped in `Code.ensure_loaded?` shims and parapet ships dead code for users who don't use that dep.

**Do this instead:** Templates in `priv/templates/parapet.gen.recovery/*.ex.eex` that generate into `lib/<host>/recovery/<action>.ex` in the adopter's tree. Host owns the code, host owns the deps.

---

## Parallel-Subsystem Temptations and How to Avoid Them

| Temptation | Why It Feels Right | Why It's a Parallel Subsystem | How to Avoid |
|------------|--------------------|-------------------------------|--------------|
| `Parapet.Recovery.Dispatcher` GenServer | "Behaviours register, but something has to dispatch at click time" | `Parapet.Operator.confirm_runbook_step/4` is already the dispatcher | Keep dispatch in `Operator`; behaviour is registration only |
| Per-action Oban queues | "Each playbook has different latency characteristics" | One worker queue is enough; auto-exec already uses `:default` | Queue partitioning is a v1.3 concern if at all |
| `Parapet.Recovery.PreviewCache` ETS table | "Looking up previews from TimelineEntry every click is wasteful" | `find_recent_preview/3` already does this with reasonable selectivity; preview windows are 5 minutes | Profile before caching; ETS adds invalidation pain |
| `Parapet.Recovery.RateLimiter` | "Operators might spam Confirm" | `CircuitBreaker` already counts `ToolAudit` rows in a window; that IS the rate limiter | Reuse `CircuitBreaker.gate/4` via `breaker_step_id` |
| Two `action_kind` values per source ("manual_operator" vs "ui_operator") | "Different audit needs" | One operator value is fine; payload.actor carries the operator identity | `"operator"` only |
| Capability discovery via `:code.all_loaded` introspection | "Avoid the Agent" | Drops dynamic registration; conflicts with config-driven activation | Keep the Agent |

---

## Data Flow: Three Scenarios End-to-End

### Scenario A: Operator clicks Preview then Confirm (the wedge)

```
[Browser] Operator clicks "Preview" on a runbook step
    ↓ phx-click="preview_mitigation" step=requeue_dead_letter incident_id=abc-123

[Generated]  HostAppWeb.Parapet.OperatorDetailLive.handle_event/3
    └─ builds ActionPayload{action_type: :preview_mitigation, actor: "operator_ui", ...}

[Parapet]    Parapet.Operator.preview_runbook_step/3
    ├─ extract_module → MyApp.Runbooks.AsyncBacklog
    ├─ parse_step_id → :requeue_dead_letter (step atom)
    ├─ MyApp.Runbooks.AsyncBacklog.__runbook_schema__() → schema with steps
    ├─ Enum.find(steps) → step %{capability: :requeue_dead_letter, ...}
    ├─ Parapet.Capabilities.get_recovery(:requeue_dead_letter)
    │    └─ Agent.get returns %{preview: fn, execute: fn, ...}
    ├─ compute_preview/3 → calls capability.preview.(incident, step)
    │    └─ MyApp.Recovery.RequeueDeadLetter.preview/2 returns
    │       {:ok, %{count: 47, target_refs: ["dlq-001", ...], warnings: [...]}}
    ├─ Builds preview payload with token + 5-minute expiry
    └─ Evidence.run_operator_command/1
        ├─ inserts TimelineEntry type="recovery_preview", payload=preview_data
        └─ inserts ToolAudit tool_name="operator_preview_recovery"

[Browser] UI re-renders, shows preview_panel with count=47, warnings, Confirm button

[Browser] Operator reviews → clicks "Confirm Recovery"
    ↓ phx-click="confirm_mitigation" step token

[Generated]  handle_event("confirm_mitigation", ...)
    └─ builds ActionPayload{action_type: :execute_mitigation, idempotency_key: <uuid>}

[Parapet]    Parapet.Operator.confirm_runbook_step/4    *** NEW IN v1.1 ***
    ├─ extract_module / parse_step_id / Capabilities.get_recovery
    ├─ find_recent_preview/3 — finds TimelineEntry with matching token
    ├─ Verifies expires_at > now (5-min window)
    │
    ├─ *** NEW: Parapet.Automation.ClaimService.claim_action/1 ***
    │   ├─ action_kind: "operator"
    │   ├─ action_key: "requeue_dead_letter"
    │   ├─ breaker_step_id: "requeue_dead_letter"
    │   ├─ idempotency_key: payload.idempotency_key
    │   ├─ INSERT INTO action_claims ON CONFLICT DO NOTHING
    │   ├─ run_gates/3
    │   │   ├─ incident_state_gate → "open" ✓
    │   │   ├─ breaker_gate → CircuitBreaker.gate/4
    │   │   │   └─ counts ToolAudit rows in past hour for this step_id
    │   │   │       if < 3 → :ok
    │   │   │       else → {:short_circuit, "circuit_breaker_tripped"}
    │   │   ├─ suppression_gate → :ok
    │   │   └─ custom_gate → :ok
    │   └─ {:won, claim}
    │
    ├─ capability.execute.(incident, target_refs)
    │   └─ MyApp.Recovery.RequeueDeadLetter.execute/2 → {:ok, %{requeued: 47}}
    │
    ├─ Evidence.run_operator_command/1
    │   ├─ inserts TimelineEntry type="recovery_confirmed"
    │   │   payload: %{step_id, capability, result}
    │   └─ inserts ToolAudit tool_name="operator_confirm_recovery"
    │
    └─ ClaimService.mark_executed/1 → UPDATE action_claims SET status='executed'

[Generated] handle_event returns {:noreply, ...}
    └─ flash "Mitigation confirmed and executed"
    └─ assigns updated incident_detail (which re-renders with step.state = :executed)
```

### Scenario B: Two operators race on Confirm (multi-node safety)

```
[Node 1] Operator A clicks Confirm
[Node 2] Operator B clicks Confirm (same incident, same step, 200ms apart)

Both LiveViews call Parapet.Operator.confirm_runbook_step/4
    ↓
Both call ClaimService.claim_action/1 with same (incident_id, "operator", "requeue_dead_letter")
    ↓
Only ONE wins the ON CONFLICT DO NOTHING insert into action_claims
    └─ Node 1: {:won, claim}     → executes, marks claim "executed"
    └─ Node 2: {:conflicted, existing_claim} → returns {:error, {:conflicted, claim_id}}

Node 2 LiveView flashes: "Another node is already executing this recovery."
```

### Scenario C: Recovery action's host dep is absent at compile time

```
mix.exs of host app does NOT include {:oban, ...}

Generated lib/host_app/recovery/stalled_async.ex:
  if Code.ensure_loaded?(Oban) do
    defmodule HostApp.Recovery.StalledAsync do
      use Parapet.Recovery
      # ...
    end
  end

At compile time: Code.ensure_loaded?(Oban) returns false
    → Module HostApp.Recovery.StalledAsync is never defined

At application start:
  Parapet.Recovery.attach([HostApp.Recovery.StalledAsync, ...])
    ↓
  Code.ensure_loaded?(HostApp.Recovery.StalledAsync) returns false
    ↓
  Skipped silently. Other modules in the list register normally.

At runtime:
  Operator views an incident whose runbook has a stalled_async step
    ↓
  WorkbenchContract.derive_runbook_steps/3 projects step.state
    ↓
  Parapet.Capabilities.get_recovery(:requeue_stalled_async) returns nil
    ↓
  step.state degrades to :guidance (per existing logic in workbench_contract.ex line 133)
    ↓
  UI renders guidance text, no Preview/Confirm button shown
```

This is the same compile-out-cleanly contract that `Parapet.Integration` upholds today — verified by reading `Parapet.attach/1` lines 41–43 and `Parapet.Automation.Executor` line 1.

---

## Confidence Assessment

| Area | Confidence | Evidence |
|------|------------|----------|
| Existing operator/capability/claim architecture | HIGH | All modules read directly from source on `main` |
| `Parapet.Recovery` behaviour callback shape | HIGH for mechanism (mirrors `Parapet.Integration`); MEDIUM for exact callback set | The 4-callback design (id/label/preview/execute) reflects what `Parapet.Capabilities.register_recovery/2` already accepts. The exact callback names could shift (e.g., `name/0` vs `label/0`) but the count and shape are dictated by existing code |
| Claim-service wiring for operator path | HIGH | The auto-execution path proves the pattern; copying it to the operator path is a small, well-bounded refactor of `Parapet.Operator.confirm_runbook_step/4` |
| Build order rationale | HIGH | Dependencies are explicit (behaviour → claim wiring → templates → demo seed → tests → docs) |
| Compile-out mechanism | HIGH | Identical pattern already used by `Parapet.Automation.Executor` for Oban; verified at `lib/parapet/automation/executor.ex` line 1 |
| Allowlist widening risk | HIGH | `@valid_capabilities` is plainly visible in `lib/parapet/capabilities.ex` lines 14–18; widening is mechanical |
| UI components needed | HIGH | Read all three generator templates; the work is content addition, not new components |

**One LOW-confidence area:** whether v1.1 should ship a `mix parapet.gen.recovery <action>` generator or wait for v1.2. The thread implies the playbook templates ship in v1.1; whether they ship via the install path or as standalone templates is a phase-decomposition call the roadmap can make. The architecture supports either.

---

## Sources

All read directly from `main` (HIGH confidence):

- `lib/parapet/integration.ex` — `Parapet.Integration` behaviour (the pattern to mirror)
- `lib/parapet/capabilities.ex` — Agent-backed recovery registry, `@valid_capabilities` allowlist
- `lib/parapet/runbook.ex` — DSL with `capability:`, `warning:`, `requires_preview:` step keys
- `lib/parapet/operator.ex` — `preview_runbook_step/3` (line 647), `confirm_runbook_step/4` (line 690), the gap where ClaimService is bypassed
- `lib/parapet/operator/action_payload.ex` — audit envelope
- `lib/parapet/operator/workbench_contract.ex` — step state derivation, including `:guidance` degradation when capability missing
- `lib/parapet/automation/claim_service.ex` — `claim_action/1` and gate composition
- `lib/parapet/automation/executor.ex` — proof that operator path can mirror auto-exec
- `lib/parapet/automation/circuit_breaker.ex` — `gate/4` and `allow?/2`
- `lib/parapet/internal/application.ex` — confirms `Parapet.Capabilities` is supervised
- `lib/parapet.ex` — `attach/1` pattern with `Code.ensure_loaded?` (lines 41–43)
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — existing Preview/Confirm UI surface
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — `handle_event("preview_mitigation"|"confirm_mitigation", ...)` already wired
- `docs/operator-ui.md` Phase 7 — design context for Preview/Confirm + named capabilities
- `.planning/threads/actionable-recovery-design.md` — v1.1 wedge definition
- `.planning/PROJECT.md` — v1.1 milestone scope

---

*Architecture research for: Parapet v1.1 Actionable Recovery — wiring executable runbook recovery into the existing operator UI*
*Researched: 2026-05-27*
