# Phase 28: Demo Seed + CI Lane - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the recovery loop end-to-end in the demo app and contract-test it in CI. The Preview → Confirm machinery already ships in Parapet core + the demo LiveView (Phases 23–27, all complete): `Parapet.Operator.confirm_runbook_step/4` routes through `Parapet.Automation.ClaimService.claim_action/1` with `action_kind: "operator"`, returning `{:ok, result}` | `{:short_circuited, reason}` | `{:conflicted, claim_id}` | `{:error, reason}`; 5-minute preview expiry + `target_refs_hash` gating; enriched `recovery_confirmed` / `recovery_failed` TimelineEntry + ToolAudit writes; a 4-arm demo LiveView. **What does NOT exist yet:** the demo app has no `Parapet.Capabilities` agent in its supervision tree, no host `Parapet.Recovery` capability impl, no compiled runbook module, no capability-backed seeded incident, no recovery CI scenarios, and no `mix demo.reset`. Phase 28 adds exactly those. Covers DEMO-05 (seeded capability-backed incident demonstrating Preview → Confirm via the operator UI, seeded as part of `mix setup`) and DEMO-06 (CI demo lane exercises four scenarios: happy-path Confirm, expired-preview retry, short-circuit on resolved incident, claim-conflict between two simulated operators).

Scope is **demo wiring (agent + capability + runbook module + seed) + headless CI scenarios + `mix demo.reset` + release_gate continuity**. NOT new core API or vocab (Phase 23 froze `@short_circuit_reasons` / `@action_kinds`). NOT changes to `confirm_runbook_step/4` / `compute_preview/3` / the LiveView handlers (Phase 25 shipped them). NOT new runbook templates (Phase 27). NOT Stable-tier graduation, `mix parapet.gen.recovery`, doctor adoption signal, or `docs/recovery-actions.md` (Phase 29). All demo wiring rides the Experimental-tier recovery surface unchanged.
</domain>

<decisions>
## Implementation Decisions

### A. Demo Capability + Runbook Module (DEMO-05 — Success Criterion #1)

- **D-01:** Author **two new compiled modules** in the demo app:
  - `DemoApp.Runbooks.StalledExecutor` (`use Parapet.Runbook`) — 3-step investigate(guidance) → mitigate(capability) → verify(guidance) shape, near-copy of `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex`. The mitigate step declares `kind: :capability, capability: :retry_async_item, target_kind: :async_item, requires_preview: true`.
  - `DemoApp.Recovery.RetryAsyncItem` (`use Parapet.Recovery`) — implements the 4 behaviour callbacks (`id/0 → :retry_async_item`, `label/0`, `preview/2`, `execute/2`).
- **D-02:** Reuse the frozen-allowlist atom `:retry_async_item` (`lib/parapet/capabilities.ex:14-20`) — **no new capability id**. A non-allowlisted id (e.g. `:restart_worker`) makes `register_recovery/2` raise `ArgumentError` at attach time (`capabilities.ex:44-47`) and breaks app boot.
- **D-03:** The seeded incident's `runbook_data` MUST set the `"module"` string key pointing at `DemoApp.Runbooks.StalledExecutor` (e.g. `runbook_data: %{"module" => to_string(DemoApp.Runbooks.StalledExecutor)}`). `confirm_runbook_step/4` / `preview_runbook_step/3` resolve the module via `extract_module/1`, which requires a `"module"` (or `:module`) binary and otherwise returns `{:error, :missing_runbook}` (verified `lib/parapet/operator.ex:1097-1113`). The current inline-`"steps"` seed (`seeds.exs:13-46`) would NOT work for Preview/Confirm.
- **D-04:** `execute/2` mutates **demo DB state** so success criterion #1 ("executes the capability against demo DB state") is real — operate on a `Parapet.Spine.ActionItem` (insert one and/or flip its `state`/`kind`) keyed to the incident. `ActionItem` already exists (columns `kind`/`state`/`incident_id`, per `test/support/concurrency_bootstrap.ex:62-72`) — no new migration. `execute/2`'s contract is `{:ok, map()} | {:error, term()}` (`lib/parapet/recovery.ex:56`); it is invoked as `capability.execute.(incident, preview_entry.target_refs)` (`operator.ex:820`).

### B. CI Scenarios — Headless ExUnit via `Parapet.Operator` API (DEMO-06 — Success Criteria #2, #3)

- **D-05:** Drive all four scenarios as **headless ExUnit** in a new `:smoke`-tagged file `examples/demo_app/test/demo_app/recovery_loop_test.exs`. Each scenario builds a `%Parapet.Operator.ActionPayload{}` (mirroring the LiveView's literal payloads at `operator_detail_live.ex:103-166`), calls `preview_runbook_step/3` to write the preview, reads the token back (`WorkbenchContract.find_active_preview/1` or the `recovery_preview` timeline payload), then calls `confirm_runbook_step/4`. **No** `Phoenix.LiveViewTest`, **no** Wallaby/browser.
- **D-06:** Scenario → assertion mapping (the four `confirm_runbook_step/4` return tuples, `operator.ex:42-47`):
  - **Happy-path** → `{:ok, _}` AND assert a `recovery_confirmed` TimelineEntry + a `ToolAudit` row were written (success arm, `operator.ex:857-885`).
  - **Expired preview** → age the preview past `expires_at` (utc_now+300s), assert `{:short_circuited, :preview_expired}` (`operator.ex:767-769`); plan-phase picks the time-injection mechanism (synthetic `expires_at` write vs. a `now:` opt).
  - **Resolved mid-flow** → flip the incident to `"resolved"` between Preview and Confirm, assert `{:short_circuited, :incident_resolved}` (mapped from ClaimService `"already_resolved"`, `operator.ex:996-1000`; the gate is `allowed_states: ["open","investigating"]` at `operator.ex:790`).
  - **Claim-conflict** → see D-08.
- **D-07:** The CI `demo` job continuity (success criterion #3) is satisfied by the existing wiring: the new tests are `:smoke`-tagged so `mix test --only smoke` (`ci.yml:139`) picks them up; `release_gate` already `needs: [lint, test, demo]` (`ci.yml:141-142`). Plan-phase verifies the `demo` job seeds + provisions the DB sufficiently for the new scenarios (it already runs `ecto.create && ecto.migrate` and `mix run priv/repo/seeds.exs` at `ci.yml:134-137`).

### C. Capabilities Agent Startup + Claim-Conflict Shape (the two hard wiring problems)

- **D-08:** **Sequential** claim-conflict, NOT a true wall-clock race. Call `confirm_runbook_step/4` twice against the same `(incident_id, action_kind: "operator", action_key)` after a valid Preview: the first wins (`{:ok, _}`), the second hits the `(incident_id, action_kind, action_key)` row-level unique constraint and returns `{:conflicted, claim_id}`. Assert exactly one success and one `{:conflicted, _}`. **Do NOT** reuse core's `Parapet.TestSupport.ConcurrencyCase` / `ConcurrencyRepo` / `unboxed_run` — that harness lives in core `test/support` and is not shipped to the demo (dependent) project, and the demo's SQL sandbox shares one connection so two `Task.async` confirms would serialize anyway. The conflict path is driven purely by `insert_all ... on_conflict: :nothing, conflict_target: [:incident_id, :action_kind, :action_key]` (`claim_service.ex:107-110, 126-133`), so a committed first claim makes the second deterministically conflict (`operator.ex:939-949`).
- **D-09:** Start `Parapet.Capabilities` in the demo supervision tree (add as a child in `DemoApp.Application.start/1`, currently `application.ex:8-13`) AND register the capability at **application boot** via `Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` (immediately after `Supervisor.start_link/2`, or as a tiny registration child). The agent is a named singleton (`capabilities.ex:22-24`), so one boot-time registration serves both `mix phx.server` and every CI test process. Registering **only** in `seeds.exs` (dev DB) would leave the CI test process unregistered → `{:error, :capability_unwired}` (`operator.ex:722, 956`).

### D. `mix demo.reset` + Seed Replayability (DEMO-05 — Success Criterion #4)

- **D-10:** Implement `demo.reset` as drop+recreate, NOT idempotent seeds: add alias `"demo.reset": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]` to `examples/demo_app/mix.exs` (mirrors the existing `setup` alias chain at `:51`). Leave `seeds.exs` always-insert — `create_incident` enforces a partial unique index on open `correlation_key` (`concurrency_bootstrap.ex:46-48`), so a naive re-seed without a drop would crash; drop+recreate makes replayability free.
- **D-11:** Add the capability-backed incident as a **new seed block** in `examples/demo_app/priv/repo/seeds.exs` (alongside the existing 3 incidents), with `runbook_data["module"]` per D-03, and update the trailing `IO.puts` count line. The seed runs under both `mix setup` (`mix.exs:51`) and `mix demo.reset`.

### Claude's Discretion

- Exact step ids / labels / descriptions / `target_kind` value and the concrete `preview/2` and `execute/2` bodies of the demo capability — should mirror the `stalled_executor` template shape and return the documented 5-field preview map (count, target_refs, preconditions, warnings, summary), but specifics are open.
- The time-injection mechanism for the expired-preview scenario (synthetic `expires_at` write vs. a `now:` opt) — plan-phase picks (D-06).
- Whether the boot-time capability registration is an inline call after `Supervisor.start_link/2` or a dedicated registration child (D-09) — both correct; plan-phase picks.
- Whether the four scenarios live in one `recovery_loop_test.exs` or split across files, and whether to also keep/extend the existing `operator_smoke_test.exs` — plan-phase picks.
- Whether `execute/2` inserts a fresh `ActionItem` or flips an existing seeded one (D-04) — plan-phase picks the more legible demo narrative.

### Folded Todos

None — `todo.match-phase 28` returned no matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — DEMO-05 (`:58`), DEMO-06 (`:59`); Phase 28 traceability (`:130-131`).
- `.planning/ROADMAP.md` — Phase 28 entry "Demo Seed + CI Lane" (`:180-194`) with the four success criteria; depends on Phase 27 (templates exist); Phase 29 depends on Phase 28 (demo proves the loop before docs name it).
- `.planning/phases/25-wire-confirm-through-claimservice-preview-confirm-ux/25-CONTEXT.md` — the Preview → Confirm operator API, the four return tuples, 5-min expiry + `target_refs_hash`, the demo LiveView surfaces, and the concurrency-test harness Phase 25 used (which Phase 28 deliberately does NOT reuse — see D-08).
- `.planning/phases/27-prebuilt-playbooks/27-CONTEXT.md` — the runbook template catalog the demo runbook module is modeled on; D-10 there explicitly defers the runnable demo scenario to Phase 28.
- `.planning/threads/actionable-recovery-design.md` — v1.1 seed thread.
- `lib/parapet/recovery.ex` — `:56` `execute/2` contract (`{:ok, map()} | {:error, term()}`); the 4 `@callback`s + `attach/1` (`:87`) + `__using__/1` the demo capability module implements.
- `lib/parapet/capabilities.ex` — `:14-20` 5-atom allowlist (use `:retry_async_item`); `:22-24` named-singleton `start_link/1` (add to demo supervision tree); `:44-47` `register_recovery/2` raises on non-allowlisted id; `get_recovery/1` read path.
- `lib/parapet/operator.ex` — `:42-47` `confirm_result` return contract; `:670` `preview_runbook_step/3`; `:749` `confirm_runbook_step/4`; `:756/:1097-1113` `extract_module/1` requires `"module"` key (else `{:error, :missing_runbook}`); `:722/:956` `{:error, :capability_unwired}` when agent not registered; `:767-769` `:preview_expired` gate; `:790/:996-1000` resolved-state gate → `:incident_resolved`; `:820` `capability.execute.(incident, target_refs)`; `:857-885` `recovery_confirmed` TimelineEntry + ToolAudit success-arm write; `:939-949` `{:conflicted, claim_id}` arm; `:1005-1017` `compute_preview/3` writes `preview_token`/`expires_at`/`target_refs_hash` into the `recovery_preview` timeline payload. **Read-only — Phase 28 does NOT edit operator.ex.**
- `lib/parapet/automation/claim_service.ex` — `:107-110, 126-133` `insert_all ... on_conflict: :nothing, conflict_target: [:incident_id, :action_kind, :action_key]` (the unique constraint that makes the sequential second claim deterministically conflict). **Read-only context.**
- `lib/parapet/operator/workbench_contract.ex` — `:198-204` `find_active_preview/1` returns the active preview (incl. token) and filters expired ones — the test reads the token back through this surface.
- `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` — the template the demo `DemoApp.Runbooks.StalledExecutor` module is a near-copy of (3-step shape, `:retry_async_item` capability step).
- `examples/demo_app/lib/demo_app/application.ex` — `:8-13` supervision tree (add `Parapet.Capabilities` child + boot-time `attach`).
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` — `:103-166` `preview_mitigation` / `confirm_mitigation` handlers showing the literal `%ActionPayload{}` shape the headless test mirrors. **Read-only — Phase 25 shipped it.**
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` — `preview_panel/1` (how the browser surfaces the seeded preview). **Read-only.**
- `examples/demo_app/priv/repo/seeds.exs` — current 3-incident seed (`:8/:63/:86`); add the capability-backed incident block + update the trailing `IO.puts`.
- `examples/demo_app/mix.exs` — `:51` `setup` alias (mirror for `demo.reset`); add the `demo.reset` alias.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` — `:4` `@moduletag :smoke` pattern the new scenario tests follow.
- `examples/demo_app/test/support/conn_case.ex` + `examples/demo_app/test/test_helper.exs` — sandbox connection model (shared single connection → D-08 sequential conflict).
- `.github/workflows/ci.yml` — `:94-139` the `demo` job (postgres service, setup-beam 1.19.0/27.2, deps.get, ecto.create+migrate, seed, `mix test --only smoke`); `:141-142` `release_gate` `needs: [lint, test, demo]`. Plan-phase confirms the job provisions enough for the four scenarios.
- `examples/demo_app/config/config.exs` — `:3-5` points the Parapet repo at `DemoApp.Repo` for standalone `mix run`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **The entire Preview → Confirm loop already ships** — `Parapet.Operator.confirm_runbook_step/4`, `preview_runbook_step/3`, `compute_preview/3`, the ClaimService routing, the frozen vocabs, the enriched audit writes, and the 4-arm demo LiveView (Phases 23–27). Phase 28 only *wires the demo to use it* and *tests it*; it edits no core module.
- **`Parapet.Recovery` behaviour + `attach/1`** (`lib/parapet/recovery.ex`) and **`Parapet.Capabilities` Agent** (`lib/parapet/capabilities.ex`) are the host-integration surface — the demo capability is an ordinary `use Parapet.Recovery` module, registered via `attach/1` at boot.
- **`stalled_executor.ex.eex` template** (`priv/templates/parapet.gen.runbooks/`) is the near-exact shape for `DemoApp.Runbooks.StalledExecutor`.
- **`Parapet.Spine.ActionItem`** already exists with `kind`/`state`/`incident_id` columns — the demo `execute/2` mutates it with no new migration.
- **The CI `demo` job + `:smoke` tag** (`ci.yml:94-139`, `operator_smoke_test.exs:4`) already exist; new scenarios slot in as `:smoke`-tagged tests with no workflow restructure. `release_gate` already requires `demo`.
- **The existing `setup` alias** (`examples/demo_app/mix.exs:51`) is the chain `demo.reset` mirrors.

### Established Patterns

- **`runbook_data["module"]` resolution**: durable incidents reference a compiled runbook module by string; `extract_module/1` does `String.to_existing_atom` and returns `{:error, :missing_runbook}` otherwise. Inline `"steps"` (today's seed) is display-only and does NOT support Preview/Confirm.
- **Named-singleton Capabilities agent**: one boot-time `attach/1` serves all processes (server + tests). Registering in seeds-only would miss the test process.
- **Additive-only return tuples under v1.0 freeze**: the four `confirm_runbook_step/4` variants are stable; the demo + tests consume them, never extend them.
- **Frozen closed vocabs**: `@short_circuit_reasons` / `@action_kinds` (`lib/parapet/telemetry/recovery_action.ex`) were locked in Phase 23 — the demo emits `action_kind: "operator"` and asserts `:preview_expired` / `:incident_resolved`; it invents no atoms.
- **Demo-LiveView as reference adopter surface**: Parapet ships no `lib/parapet/**/live/` — the demo is what adopters copy. The demo capability/runbook/seed is therefore also the worked reference Phase 29's `docs/recovery-actions.md` will point at.
- **`:smoke`-tagged demo CI lane**: the demo's CI contract runs `mix test --only smoke`; recovery-loop coverage lands as `:smoke` tests.

### Integration Points

- `DemoApp.Application.start/1` → starts `Parapet.Capabilities` + `Parapet.Recovery.attach([DemoApp.Recovery.RetryAsyncItem])` → registry now answers `get_recovery(:retry_async_item)`.
- Seed → `Parapet.Evidence.create_incident/1` with `runbook_data["module"] = DemoApp.Runbooks.StalledExecutor` → operator UI / tests resolve the capability step.
- Headless test → `%ActionPayload{}` → `preview_runbook_step/3` → read token via `WorkbenchContract.find_active_preview/1` → `confirm_runbook_step/4` → assert one of the four return tuples + (happy-path) TimelineEntry/ToolAudit.
- Claim-conflict → two sequential `confirm_runbook_step/4` calls → `ClaimService` unique-constraint `on_conflict: :nothing` → `{:ok,_}` then `{:conflicted, claim_id}`.
- CI `demo` job → seeds + `mix test --only smoke` → `release_gate` gate.

### Concurrency / Multi-Node Constraints

- The demo SQL sandbox shares **one** connection across processes (`conn_case.ex`, `test_helper.exs` manual mode), so two `Task.async` confirms serialize rather than race — hence D-08's sequential approximation, which still exercises the real `(incident_id, action_kind, action_key)` unique-constraint conflict path deterministically.
- Core's `Parapet.TestSupport.ConcurrencyCase` / `ConcurrencyRepo` / `unboxed_run` harness (used by Phase 25's core concurrency test) lives in core `test/support` and is **not** available to the demo dependent project — do not reach for it.
- A genuinely concurrent two-connection race would require standing up a second non-sandboxed Repo in the demo test env — out of scope; flag if fidelity is ever challenged (see D-08 "If wrong").
</code_context>

<specifics>
## Specific Ideas

- **The seeded recovery incident must carry `runbook_data["module"]`** pointing at a compiled `use Parapet.Runbook` module — inline `"steps"` is display-only and breaks Preview/Confirm with `:missing_runbook`. This is the single most load-bearing detail of the phase (verified `operator.ex:1097-1113`).
- **Reuse the allowlisted `:retry_async_item` atom** — never invent a capability id (raises `ArgumentError` at attach, breaks boot).
- **Capability is registered at application boot, not in seeds** — the named singleton must answer for both the running server and the CI test process.
- **All four CI scenarios are headless ExUnit through `Parapet.Operator`** — no LiveViewTest, no browser. The LiveView handlers are thin wrappers over the same calls.
- **Claim-conflict is sequential** (first confirm wins, second `{:conflicted,_}`) — deterministic, sandbox-safe, exercises the real unique constraint. Core's concurrency harness is unavailable to the demo project.
- **`mix demo.reset` = `ecto.drop + ecto.create + ecto.migrate + seeds`** — drop+recreate makes replayability free; seeds stay always-insert.
- **`execute/2` mutates a `Parapet.Spine.ActionItem`** so "executes against demo DB state" is literally true; `ActionItem` already exists (no new migration).
- **Phase 28 edits no core module** — `lib/parapet/operator.ex`, `recovery.ex`, `capabilities.ex`, `claim_service.ex` are all read-only context; the work lives entirely under `examples/demo_app/` plus `.github/workflows/ci.yml` verification.
</specifics>

<deferred>
## Deferred Ideas

- **A genuinely concurrent two-connection claim race** (second non-sandboxed demo Repo) — out of scope; the sequential conflict (D-08) tests the same contract deterministically. Revisit only if conflict fidelity is challenged.
- **`mix parapet.gen.recovery <NAME>` Igniter scaffolder** (ADOP-01) — Phase 29.
- **`mix parapet.doctor` recovery-action adoption signal** (ADOP-02) — Phase 29.
- **`docs/recovery-actions.md` adopter guide** (ADOP-03) — Phase 29; the demo capability/runbook authored here becomes its worked reference.
- **`Parapet.Recovery` Experimental → Stable graduation + CHANGELOG additive-variant migration note** (STAB-07) — Phase 29.
- **New runbook templates / template renames** — Phase 27 closed; Phase 28 consumes the existing catalog.
- **Browser/Wallaby E2E of the demo Preview → Confirm** — rejected; headless ExUnit through the operator API is the deterministic contract test. (Manual browser click-through is a HUMAN-UAT item per success criterion #1, not an automated CI scenario.)

### Reviewed Todos (not folded)

None — `todo.match-phase 28` returned no matches.
</deferred>
</content>
</invoke>
