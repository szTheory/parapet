# Project Research Summary

**Project:** parapet v1.1 — Actionable Recovery
**Domain:** Elixir/Phoenix OSS SRE library — executable runbook recovery actions in an operator-in-the-loop workbench
**Researched:** 2026-05-27
**Confidence:** HIGH (all findings verified directly against live `main` source; thread + design docs cross-checked)

## Executive Summary

**v1.1 Actionable Recovery is a wiring milestone, not a redesign.** v1.0 already shipped every load-bearing primitive: the `Parapet.Capabilities` Agent-backed registry (with closed atom allowlist), `Parapet.Operator.preview_runbook_step/3` + `confirm_runbook_step/4` (with 5-min preview tokens and stale-preview rejection), `ActionPayload` (with `idempotency_key` enforced on `:execute_mitigation`), `Parapet.Automation.ClaimService` + `CircuitBreaker` (multi-node-safe), the `Parapet.Runbook` DSL (`:capability`, `:requires_preview`, `:preview_only`, `:warning`, `:guidance` step keys), and `WorkbenchContract.derive/3`'s `:guidance | :previewable | :executable | :executed` step-state projection. The generated `OperatorComponents` template already renders `preview_panel/1` with a Confirm button, and `OperatorDetailLive` already wires `phx-click="preview_mitigation"` / `phx-click="confirm_mitigation"` to those Operator functions.

**The recommended approach** is to close the small set of gaps that prevent the loop from being usable end-to-end: a `Parapet.Recovery` behaviour shim (mirrors `Parapet.Integration` exactly, 4 callbacks `id/0 | label/0 | preview/2 | execute/2`, plus an `attach/1` activation function); a widening of `@valid_capabilities` by 2 atoms (`:revert_feature_flag`, `:disable_metric_label`); routing the operator-clicked Confirm through `ClaimService` so it gets the same multi-node + circuit-breaker protection the auto-execution path already has; six prebuilt playbook templates (four capability-backed, two deliberately guidance-only by design); a `recovery_failed` TimelineEntry type for failure-surfacing; one demo-seeded executable incident; and adopter docs. Zero new runtime or dev dependencies. Zero `mix.lock` churn.

**The dominant risks are autonomous-remediation creep, Preview→Confirm TOCTOU, the multi-node claim leak (no lease TTL today), repeating the `Parapet.SLO` Application-env mistake in the new registry, and the "shipped ≠ adopted" gap.** Mitigations are architectural and must land *before* any capability ships: lock telemetry contract + add `lease_until` schema column up front; enforce non-`system:` actor on the human-Confirm path in the `ActionPayload` changeset; reuse the existing `Parapet.Capabilities` Agent (do not invent a parallel `Application.put_env` registry); freeze the `PreviewReport` shape with a closed key list; and ship the four prebuilt playbooks plus a `mix parapet.gen.recovery` Igniter task so adopters never face a blank page.

## Key Findings

### Recommended Stack

**No new dependencies. No version bumps. No `mix.exs` change.** v1.1 ships entirely on the v1.0 stack — Elixir `~> 1.19`, OTP 27, `ecto ~> 3.10`, `ecto_sql ~> 3.10`, `postgrex ~> 0.20`, `phoenix_live_view ~> 1.1` (host-side), `telemetry ~> 1.2`, with `oban`, `req`, `igniter`, `opentelemetry_api` already-optional. Stock Oban (≥ 2.17) provides `Oban.retry_job/1` + `Oban.cancel_job/1` — no `oban_pro` required. The whole milestone is pure additive code on the existing surface.

**Core technologies (all already on the v1.0 baseline):**
- `Parapet.Capabilities` Agent registry — capability registry already supervised; widen allowlist by 2 atoms
- `Parapet.Operator.{preview,confirm}_runbook_step` — public seam already shipped; v1.1 widens internal flow only
- `Parapet.Automation.{ClaimService,CircuitBreaker}` — multi-node + flap protection already proven; v1.1 routes the operator path through them
- `Parapet.Runbook` DSL — `:capability`, `:requires_preview`, `:preview_only`, `:warning`, `:guidance` keys already exist; v1.1 consumes them
- `Parapet.Spine.{TimelineEntry,ToolAudit,ActionClaim,ActionPayload}` — audit schemas already in place; v1.1 adds zero new schemas, one new free-form `type` string (`"recovery_failed"`), and one column (`lease_until` on `parapet_action_claims`)

**Anti-stack (explicit rejections to keep in scope-creep guardrails):** `oban_pro`/`oban_web`, `phoenix_storybook`, `commanded`/event-sourcing, `nimble_options`, `salad_ui`, `gen_state_machine`, custom JSON Schema validators, `tesla`. All would violate either "compile out cleanly when absent" or "host-owned beats remote magic."

Detailed analysis: `STACK.md`.

### Expected Features

Five feature categories drive the wedge. Two of the six playbooks stay **guidance-only by design** (Retry Storm, Suppression Drift) because every obvious automated mitigation makes the failure worse — a deliberate carry-over of the v0.10 "guidance-only runbooks where no allowlisted capability fits" decision.

**Must have (table stakes):**
- Named capability registration from the host app via behaviour — operators never invoke arbitrary code
- Preview before any mutation (with structured `count`, `target_refs`, `preconditions`, `warnings`, `idempotency_caveats`, `summary`)
- Confirm gated by a fresh preview (5-min token expiry already enforced)
- Idempotency key on every confirm (already required on `:execute_mitigation` `ActionPayload`)
- ToolAudit + TimelineEntry written for both Preview and Confirm in one transaction
- `recovery_failed` TimelineEntry when capability `execute/2` returns `{:error, _}` — current gap
- `"Not wired"` UI state for steps whose capability the host hasn't registered
- Reason/comment textarea on Confirm
- At-least-one demo-seeded executable recovery

**Should have (differentiators):**
- Every Confirm flows through the same `ActionPayload → ClaimService → CircuitBreaker` pipeline as v0.8 escalation — operators *cannot* accidentally skip these
- Recovery action *is* a TimelineEntry inline in the canonical chronology — no sidebar audit log
- Capability id allowlist enforced at registration time — typo prevention rail
- Structured preview output (typed map, not stdout) — MCP read-only server can reason over it
- Explicit short (5-min) preview expiry with countdown in UI
- Recovery-action telemetry under the existing `:telemetry.span/3` convention

**Defer (v1.2+):**
- Adapter-provided capabilities (Rulestead → `:revert_feature_flag` auto-binding)
- MCP server rendering Preview without executing
- Per-capability cooldown rules (on top of CircuitBreaker)
- Per-incident recovery history sidebar
- Cross-incident recovery correlation

**Anti-features (explicit declines, document in scope-creep guardrails):**
- Autonomous remediation (no-human-in-the-loop execution from the UI) — invalidates audit narrative
- Cross-app / multi-tenant action scoping — v1.4+ concern
- Approval workflows — host can wrap the Confirm primitive
- Custom action UIs beyond Guidance → Preview → Confirm
- Arbitrary shell-job execution (the Rundeck pattern)
- In-UI rollback / generic "undo"
- Bulk recovery ("retry all 14 incidents")

The six playbooks:
1. **Retry Storm** — guidance-only (automated mitigations worsen the symptom)
2. **Suppression Drift** — guidance-only (auto-clear invalidates provider reputation)
3. **Stalled Async** — capability `:retry_async_item` (already allowlisted)
4. **Dead-Letter Drain** — capability `:requeue_dead_letter` (already allowlisted)
5. **Deploy-Tied Incident** — capability `:revert_feature_flag` (NEW)
6. **Cardinality Blowout** — capability `:disable_metric_label` (NEW)

Detailed analysis: `FEATURES.md`.

### Architecture Approach

**The architectural heart of v1.1 is a single defect to close: the operator-clicked Confirm path bypasses `ClaimService` today.** The auto-execution path (`Parapet.Automation.Executor` via Oban) claims, gates through CircuitBreaker, and audits — the operator path skips all three. Closing that gap is more important than any new feature, because every new playbook lands on broken safety semantics until it is fixed.

**Major components:**
1. **`Parapet.Recovery` behaviour** — NEW; 4 callbacks (`id/0`, `label/0`, `preview/2`, `execute/2`) + 1 optional (`target_kind/0`); mirrors `Parapet.Integration` mechanism exactly; `Parapet.Recovery.attach/1` registers modules into the existing `Parapet.Capabilities` Agent. Compile-time `@behaviour` warnings give DX wins; host modules use `Code.ensure_loaded?` to compile out cleanly when their host deps are absent.
2. **`Parapet.Capabilities`** — EXISTS; widen `@valid_capabilities` by 2 atoms. No structural change. Do **not** spin up a parallel registry.
3. **`Parapet.Operator.confirm_runbook_step/4`** — EXISTS; v1.1 wraps the existing `capability.execute.(...)` call inside `ClaimService.claim_action/1` with `action_kind: "operator"`, `breaker_step_id: step_id`. Adds additive `{:short_circuited, ...}` / `{:conflicted, ...}` error variants — backward compatible.
4. **`Parapet.Spine.ActionClaim`** — EXISTS; v1.1 adds `lease_until` column + self-healing on expired-lease rows (close Pitfall 4).
5. **LiveView Preview/Confirm UX** — `OperatorDetailLive` and `OperatorComponents` templates already render the surface; v1.1 adds `claim_state_badge`, branches on the new error variants for operator-friendly flashes, surfaces the countdown to preview expiry.
6. **Six playbook templates + Igniter generator** — NEW templates in `priv/templates/parapet.gen.recovery/`; `mix parapet.gen.recovery` Igniter task scaffolds host capability modules with `c:preview/2` + `c:execute/2` stubs.
7. **Demo seed + adopter docs** — extend `examples/demo_app/priv/repo/seeds.exs` with one capability-backed incident; `examples/demo_app/lib/demo_app/recovery.ex` implements `@behaviour Parapet.Recovery`; `docs/recovery-actions.md` adopter guide; doctor check for unwired capabilities.

**Key invariant:** both the operator-clicked path and the alert-driven path reach the same mitigation entry point through the same claim service and produce the same TimelineEntry / ToolAudit shape. `action_kind` distinguishes the source (`"operator"` vs `"automation"`) for audit attribution without removing the protection.

**Compile-out-cleanly contract:** generated host playbooks wrap in `if Code.ensure_loaded?(HostDep)`, exactly as `Parapet.Automation.Executor` already does for Oban. `Parapet.Recovery.attach/1` filters missing modules silently; `WorkbenchContract.derive_runbook_steps/3` degrades steps to `:guidance` when their capability is unregistered.

Detailed analysis: `ARCHITECTURE.md`.

### Critical Pitfalls

Fourteen pitfalls identified; the top five drive phase ordering:

1. **Autonomous-remediation creep** (Pitfall 8) — every PR titled "auto-execute trusted capabilities" or "remember last Confirm" is a step backward. Enforce in code: `ActionPayload.changeset/2` rejects `actor` starting with `system:` on the human-Confirm path. Codify the rule in `CONTRIBUTING.md`, `Parapet.Recovery` `@moduledoc`, and `docs/operator-ui.md`. This is an *ongoing* concern, not a single-phase fix.
2. **Preview → Confirm TOCTOU** (Pitfalls 1+3) — Confirm must be gated on a server-side state machine where the preview's resolved target set is the exact input to `execute/2`. The capability behaviour must have *separate* `c:preview/2` and `c:execute/2` callbacks (not a single `c:run/2 + opts[:dry_run]`); the `PreviewReport` carries the frozen scope; `execute/2` never re-resolves.
3. **Application-env registry repeats the `Parapet.SLO` mistake** (Pitfall 13) — the v1.2 thread `slo-state-off-application-env.md` exists precisely because Application env is the wrong store. v1.1 must not copy it. Use the existing `Parapet.Capabilities` Agent (already in the supervision tree, already test-isolatable). 100 async tests registering distinct capabilities must all pass without bleeding.
4. **Multi-node claim leak** (Pitfall 4) — claims commit before `execute/2` starts; a node crash mid-execution leaves the claim in `status: "claimed"` forever. Add a `lease_until` column to `parapet_action_claims` with default 5 minutes; `claim_action/1` self-heals expired leases atomically. This is a schema migration — land it in v1.1 or pay forever.
5. **"Shipped ≠ adopted" gap** (Pitfall 14) — the v0.10 LEARN-22-C echo. Ship the four prebuilt playbooks *before* the custom-capability authoring deep-dive; ship `mix parapet.gen.recovery` Igniter task; doctor check reports adoption signal; LEARNINGS file at v1.1 close.

Honorable mentions that also drive design: TimelineEntry/ToolAudit noise drowning recovery signal (Pitfall 6 — three-tier audit contract: telemetry for clicks, ToolAudit for every `execute/2` call, TimelineEntry only for operator-visible facts deduped per hour); capability behaviour DX cliff (Pitfall 7 — exactly 2 required callbacks, defaults for the rest); telemetry contract drift (Pitfall 11 — lock all `[:parapet, :recovery, ...]` event names in a single PR before any capability ships); multi-tenant assumptions creeping into schema (Pitfall 10 — no `tenant_id` columns in v1.1); demo seed that misleads more than it demonstrates (Pitfall 12 — must include short-circuit and Preview-without-Confirm scenarios, must be `mix demo.reset`-replayable, must not be destructive).

Detailed analysis: `PITFALLS.md` (14 pitfalls, technical-debt patterns, integration gotchas, performance traps, security mistakes, UX pitfalls, looks-done-but-isn't checklist, recovery strategies).

## Implications for Roadmap

The two researchers produced different orderings: ARCHITECTURE proposes 6 phases starting with the behaviour module; PITFALLS proposes 8 phases starting with telemetry contract + schema migration. The reconciliation below adopts PITFALLS' risk-mitigating front-loading (lock contracts and schema *before* any capability ships) but keeps ARCHITECTURE's pragmatic 6-phase shape by collapsing the telemetry-contract + schema-migration steps into one foundational phase. The result is **7 phases** (Phase 7 optional — generator/docs/adoption may slide to v1.2 if scope pressure mounts).

### Phase 1: Foundations — Telemetry Contract + `lease_until` Migration
**Rationale:** Both telemetry naming and schema columns become irreversible the moment they ship under the v1.0 stability freeze. Lock them in one low-code, high-leverage PR before any capability or behaviour ships. This is the "land it now or pay forever" gate. (PITFALLS 4, 6, 11.)
**Delivers:**
- Full `[:parapet, :recovery, ...]` telemetry event family documented in `docs/telemetry.md` (preview-show, preview-render-failure, confirm-clicked, claim-conflicted, claim-short-circuited, execute-span start/stop, execute-result success/failure) following the existing `[:parapet, :slo, :evaluation, :start | :stop]` and `[:parapet, :runbook, :step, :executed]` shapes.
- `verify.telemetry_contract` mix task asserting docs match emitted events (catches drift at CI time).
- Migration adding `lease_until :utc_datetime_usec` (and `claimed_at` index if missing) on `parapet_action_claims`.
- `ClaimService.claim_action/1` self-heals expired leases via `UPDATE ... WHERE id = ? AND lease_until < now() RETURNING *`.
- Audit contract (three-tier) documented in `docs/operator-ui.md`: TimelineEntry for operator-visible facts (deduped per hour), ToolAudit one-per-`execute/2`, telemetry for high-frequency clicks.
**Addresses:** Telemetry-as-API differentiator; idempotency-via-lease guarantee; audit-signal-not-noise.
**Avoids:** Pitfalls 4, 6, 11 (claim leak, audit noise, telemetry drift).

### Phase 2: `Parapet.Recovery` Behaviour + Capability Allowlist Widening
**Rationale:** The public-API foundation. Every downstream phase references either `use Parapet.Recovery` or one of the new capability ids. The 4-callback design ships frozen in v1.1 because `Parapet.Recovery` is Stable-tier from day one — adding required callbacks in v1.2 is breaking under the v1.0 stability promise.
**Delivers:**
- `lib/parapet/recovery.ex` — behaviour with `c:id/0`, `c:label/0`, `c:preview/2`, `c:execute/2` required; `c:target_kind/0` optional; `attach/1` registers into `Parapet.Capabilities` via existing `register_recovery/2`; defaults for `label/0`, `description/0`, `expected_duration_ms/0` from `use Parapet.Recovery` macro.
- `Parapet.Recovery.PreviewReport` struct — closed key list (`summary`, `scope`, `warnings`, `blast_radius :: :exact | :bounded | :broad`, `target_refs`, `count`, `preconditions`, `idempotency_caveats`); adding fields is additive (minor-bump); removing requires major.
- `Parapet.Recovery.ExecutionResult` struct — closed key list with bounded error vocabulary (`:precondition_failed`, `:provider_unavailable`, `:partial_failure`, `:internal_error`).
- `Parapet.Capabilities @valid_capabilities` widened by 2 atoms (`:revert_feature_flag`, `:disable_metric_label`); the other four playbooks reuse existing ids.
- `c:execute/2` signature locked at arity 2 (`incident, preview_report`) — no opts, no `correlated_incidents`, no cross-app surface (PITFALLS 9, 10).
- `ActionPayload.changeset/2` enforces non-`system:` actor on the human-Confirm path (PITFALLS 8 hard rule).
- Tests asserting 100 async registrations don't bleed (PITFALLS 13 — Application-env-free).
**Avoids:** Pitfalls 7 (DX cliff), 8 (autonomous creep), 9 (cross-app leak), 10 (multi-tenant assumptions), 13 (Application-env registry).

### Phase 3: Wire Confirm Through `ClaimService` (Architectural Defect Closure)
**Rationale:** The operator-clicked path must reach the same mitigation entry point as the alert-driven path, through the same claim service. Close this gap *before* any new playbook lands — otherwise every test silently exercises the broken path. (ARCHITECTURE's most important finding.)
**Delivers:**
- `Parapet.Operator.confirm_runbook_step/4` modified to call `ClaimService.claim_action/1` with `action_kind: "operator"`, `breaker_step_id: step_id`, idempotency_key from the preview token chain (not freshly minted).
- Branches on `{:won, _}` / `{:short_circuited, _, _}` / `{:conflicted, _}` — additive return variants; existing `{:ok, _}` / `{:error, atom}` returns unchanged (backward compatible).
- `recovery_failed` TimelineEntry type on capability `execute/2` error (closes FEATURES gap).
- `OperatorDetailLive` template branches on new error shapes with operator-friendly flashes ("Another node is executing this recovery", "Circuit breaker tripped").
- `OperatorComponents` template gets `claim_state_badge/1` and CircuitBreaker indicator.
- LiveView subscribes to incident-state PubSub; Confirm button disables with banner when incident resolves mid-decision (PITFALLS 5).
- Idempotency key generated **at Preview render time**, stored in socket assigns, reused for Confirm (PITFALLS 2).
- Server-side state machine: Confirm button does not render until `socket.assigns.recovery_step.status == :previewed` (PITFALLS 1).
**Avoids:** Pitfalls 1 (auto-execute Confirm), 2 (double-Confirm duplicate), 5 (stale incident state).

### Phase 4: Six Playbook Templates + Existing Runbook Updates
**Rationale:** Templates encode the behaviour shape (Phase 2) and exercise the claim-protected Confirm path (Phase 3). Each template generates a host-owned `MyApp.Recovery.<Action>` module under `lib/<host>/recovery/`, wrapped in `if Code.ensure_loaded?(HostDep)` for compile-out-cleanly.
**Delivers:**
- `priv/templates/parapet.gen.recovery/{retry_storm,suppression_drift,stalled_async,dead_letter_drain,deploy_tied_incident,cardinality_blowout}.ex.eex` — six templates.
- Two guidance-only templates (Retry Storm, Suppression Drift) ship with explicit `warning:` blocks documenting *why* they decline to automate.
- Four capability-backed templates ship with structured PreviewReport returns including `blast_radius`, `target_refs`, `preconditions`, `warnings`, `summary`.
- Existing `priv/templates/parapet.gen.runbooks/*.ex.eex` updated to reference the new capability ids via the already-supported `capability:` step attribute.
- Per-prebuilt-playbook docs (one small dedicated page each) — content ships in Phase 7, scaffolding lands here.
**Avoids:** Pitfall 8 (autonomous creep — guidance-only by design for two playbooks).

### Phase 5: Demo Seed + Audit Propagation Tests
**Rationale:** The demo *is* the smoke test for the wedge. If the demo doesn't work end-to-end with `iex -S mix phx.server`, v1.1 isn't shipped. Audit propagation verification lands here because it exercises the full Phase 1–4 stack.
**Delivers:**
- `examples/demo_app/priv/repo/seeds.exs` — adds one open incident with a `:requeue_dead_letter`-backed runbook step.
- `examples/demo_app/lib/demo_app/recovery.ex` — host capability module implementing `@behaviour Parapet.Recovery`; real, reversible action against demo DB state (not a no-op).
- `examples/demo_app/lib/demo_app/application.ex` — `Parapet.Recovery.attach([DemoApp.Recovery.RequeueDeadLetter])` in `start/2`.
- `mix demo.reset` task — re-seeds; demo replayable (PITFALLS 12).
- Demo CI lane (extends the Phase 21 v1.0 contract test) exercises Preview-without-Confirm, short-circuit (incident-already-resolved), and successful-Confirm paths.
- `test/parapet/operator_audit_propagation_test.exs` — asserts every Confirm produces both a TimelineEntry of correct type AND a ToolAudit row with correct `tool_name` + `input`; covers won/short-circuited/conflicted outcomes.
- `test/parapet/automation/claim_service_test.exs` — extended to cover `action_kind: "operator"` case + expired-lease self-healing.
- ConcurrencyCase test for double-Confirm idempotency.
**Avoids:** Pitfall 12 (misleading demo), reverifies 2 (double-Confirm), 4 (claim leak), 5 (stale state) end-to-end.

### Phase 6: Stability Tier Declaration + CHANGELOG Migration Notes
**Rationale:** `Parapet.Recovery` ships Stable-tier from day one (the behaviour shape cannot churn). The stability machinery (moduledoc callouts, `docs/stability.md` table entries, CHANGELOG additive-return-variant notes) is a deliberate phase, not an afterthought, because the v1.0 freeze posture is what made the prior milestone credible.
**Delivers:**
- `Parapet.Recovery` `@moduledoc` includes `> #### Stable {: .info}` callout.
- `docs/stability.md` Stable Modules table updated with `Parapet.Recovery`, `Parapet.Recovery.PreviewReport`, `Parapet.Recovery.ExecutionResult`.
- `CHANGELOG.md` Release Please entry: new behaviour, widened allowlist, additive `confirm_runbook_step/4` return variants, new `recovery_failed` TimelineEntry, new `lease_until` schema column with default + backfill, new telemetry event family.
- Migration notes for adopters who customized their generated `OperatorDetailLive`: how to hand-apply the new claim-aware error branches.
- `docs/operator-ui.md` Phase 7 section marked "implemented in v1.1.0" with version notes.
**Avoids:** Pitfall 11 (telemetry drift caught in stability table); locks the v1.1 contract before adopters integrate.

### Phase 7 (optional, may slide to v1.2): Adopter Onboarding — `mix parapet.gen.recovery` + Docs + Doctor Check
**Rationale:** Closes the "shipped ≠ adopted" gap (PITFALLS 14). The Igniter task removes the blank-page problem for custom capability authoring; the doctor check signals adoption pain; the LEARNINGS file is the v0.10 LEARN-22-C graduation. If scope pressure mounts at v1.1 close, this phase may slide to v1.2 — but the four prebuilt playbooks from Phase 4 + the demo from Phase 5 must already be enough to land the wedge.
**Delivers:**
- `lib/mix/tasks/parapet.gen.recovery.ex` — Igniter `copy_template` task with `on_exists: :skip`; scaffolds `lib/<host>/recovery/<action>.ex` with `c:preview/2` + `c:execute/2` stubs + a unit test.
- `docs/recovery-actions.md` — adopter authoring guide with "your first custom capability in 10 minutes" path matching the getting-started 30-minutes-to-first-alert structure.
- Per-prebuilt-playbook hexdoc pages (six small dedicated pages).
- Troubleshooting guide entries (capability registered but doesn't show in UI; Preview blank; Confirm clicked but nothing happens; claim stuck for 5 minutes).
- `mix parapet.doctor` adoption check: "X capabilities registered, Y runbook steps mapped, Z recovery executions in the last 30 days"; warns when capabilities are registered but no runbook references them, or vice versa.
- `mix parapet.doctor` unwired-capability check: warns if a generated runbook references a capability id not registered in `Parapet.Capabilities`.
- `mix parapet.doctor` recovery-route-auth check: scoped equivalent of the existing "Unsecured operator UI LiveView found" warning.
- v1.1 LEARNINGS file at phase close.
**Avoids:** Pitfall 14 (documentation/adoption gap).

### Phase Ordering Rationale

- **Why Phase 1 is foundational, not behaviour-first:** PITFALLS Pitfall 4 (claim leak) and Pitfall 11 (telemetry drift) become *irreversible* under stability tier the moment any capability ships. ARCHITECTURE's "behaviour first" ordering is more pragmatic but leaves the schema/telemetry decisions to whichever PR happens to land them — which is exactly how naming drift and "schema gap" patches end up in v1.1.1. Front-loading these is cheap (low-code, high-leverage) and turns Phase 2 into a clean public-API design exercise without dragging schema decisions into it.
- **Why Phase 2 must precede Phase 3:** The Confirm-path changes in Phase 3 are easier to test against a stable behaviour shape. Adding new error branches to `confirm_runbook_step/4` while the behaviour callback set is still in flux doubles the test churn.
- **Why Phase 3 must precede Phase 4:** if playbooks land first, every adopter who generates one between Phase 4 and Phase 3 gets a runbook whose Confirm path will work but won't be claim-protected. Closing the gap second creates a v1.1.1 patch obligation. Closing it first is the conservative path. (Directly from ARCHITECTURE's stated rationale.)
- **Why Phase 5 (demo + tests) is single-phased:** the demo is the integration test. Audit propagation verification needs the demo's seeded incident to exercise end-to-end. Splitting them across phases means either tests run against a non-existent demo or the demo lacks the assertions that prove it works.
- **Why Phase 6 (stability) precedes Phase 7 (adoption):** stability tier declarations are part of the *contract* that adopters integrate against. Adoption tooling (Phase 7) references the contract; the contract has to exist first.
- **Why Phase 7 is optional:** the four prebuilt playbooks + the demo seed already cover ≥80% of adopter use cases. The Igniter task and adoption-signal docs are amplifiers, not load-bearing for the wedge. If the maintainer hits scope pressure, sliding Phase 7 to v1.2 is acceptable — *provided* the LEARNINGS file still ships at v1.1 close.

### Research Flags

Phases likely needing deeper research during planning (`/gsd:plan-phase --research-phase <N>`):

- **Phase 1:** the telemetry event family naming choice has stability-freeze implications. Worth a one-pass review of the existing `[:parapet, :slo, :evaluation, ...]`, `[:parapet, :runbook, :step, :executed]`, and `[:parapet, :operator, ...]` conventions to make sure the new family fits the established shape exactly. Also: lease duration default — 5 minutes is the proposed value but capability-bounded leases (e.g., 30 min for DLQ drains) may need to ship in v1.1.0 if any prebuilt playbook exceeds 5 min.
- **Phase 3:** the `idempotency_key` lifecycle (Preview-mint → socket assigns → Confirm reuse → claim_service `on_conflict`) is the single most subtle change in v1.1. Worth a short research phase to confirm the key derivation strategy (hash of `(incident_id, step_id, preview_session_id, preview_report)` vs UUID seeded at preview render) and how it interacts with `Phoenix.LiveView.connect_info`.
- **Phase 7:** the `mix parapet.gen.recovery` Igniter task shape — whether to land in v1.1 or v1.2 — depends on how much overlap exists with the planned `mix parapet.gen.slo` task (v1.2). Worth a quick prompt to check if the two should share a common `mix parapet.gen.*` skeleton.

Phases with standard patterns (skip research-phase):

- **Phase 2:** behaviour module design has a clear template (`Parapet.Integration`); the four required callbacks fall out directly from `Parapet.Capabilities.register_recovery/2`'s existing shape.
- **Phase 4:** template authoring is well-trodden (seven existing runbook templates in `priv/templates/parapet.gen.runbooks/`); the six new templates follow the same EEx + `Code.ensure_loaded?` pattern.
- **Phase 5:** demo seed extensions and ConcurrencyCase test patterns are established (Phase 21 v1.0 contract test).
- **Phase 6:** stability tier declarations follow the v1.0 freeze playbook exactly.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Every claim verified directly against `lib/parapet/**`, `mix.exs`, and the demo's `mix.exs`. Zero new deps is a strong, evidence-backed claim. |
| Features | HIGH | All table-stakes + differentiator features map to either existing v1.0 code or a single small additive change. Anti-features are grounded in `.planning/PROJECT.md`'s out-of-scope list. |
| Architecture | HIGH for mechanism (mirroring `Parapet.Integration`, reusing `ClaimService` / `Capabilities`); MEDIUM for the exact behaviour callback names (`c:label/0` vs `c:name/0`, `c:target_kind/0` optionality). The mechanism is dictated by existing code; the names are bikeshed-able. |
| Pitfalls | HIGH | Fourteen pitfalls all traceable to specific code (ActionPayload, ClaimService, Executor) or to documented prior-art decisions (LEARN-22-C, slo-state-off-application-env thread). Pitfall ranking is grounded in stability-freeze irreversibility. |

**Overall confidence:** HIGH.

### Gaps to Address

- **Behaviour callback names (Phase 2):** `c:label/0` vs `c:name/0` vs `c:title/0` — bikeshed; pick one and freeze. Recommendation: `c:id/0` (atom) + `c:label/0` (string), distinct from the `:name` key currently used in `register_recovery/2`.
- **`mix parapet.gen.recovery` ship-or-slide (Phase 7):** depends on v1.1 scope budget at phase close. The architecture supports either path; the roadmap should mark Phase 7 explicitly as "stretch" with a v1.2 fallback.
- **Lease duration policy (Phase 1):** single global default vs per-capability declaration. Recommendation: ship 5-minute global default in v1.1.0 with capability-extensible lease in v1.1.1 *only if* a prebuilt playbook needs >5min (currently none do based on PITFALLS analysis).
- **Per-capability cooldown rules (deferred to v1.2):** the CircuitBreaker today is `system:`-scoped; PITFALLS Integration Gotchas explicitly recommend *not* applying it to human-Confirm. A separate cooldown surface may be needed in v1.2 — flag for v1.2 roadmap, not v1.1.
- **MCP server rendering Preview (deferred to v1.2):** AI-investigation-copilot value is real but the MCP server is in `experimental` tier; coupling v1.1 Stable surfaces to it would create a stability mismatch. Flag for v1.2.

## Sources

### Primary (HIGH confidence)
- `lib/parapet/operator.ex` (lines 647–745) — `preview_runbook_step/3`, `confirm_runbook_step/4`, `find_recent_preview/3`
- `lib/parapet/capabilities.ex` — Agent registry, `@valid_capabilities` allowlist, `register_recovery/2`
- `lib/parapet/operator/action_payload.ex` — `:execute_mitigation` enum, `idempotency_key` enforcement
- `lib/parapet/operator/workbench_contract.ex` — `derive_runbook_steps/3` step-state machine, `active_preview` projection, `:guidance` degradation
- `lib/parapet/automation/{claim_service,circuit_breaker,executor}.ex` — claim acquisition, gate composition, Oban worker convention, `:system:automation:executor` URN
- `lib/parapet/runbook.ex` — DSL with `:capability`, `:requires_preview`, `:preview_only`, `:warning`, `:guidance` step keys
- `lib/parapet/integration.ex` — the behaviour pattern to mirror
- `lib/parapet/spine/{action_claim,timeline_entry,tool_audit,incident}.ex` — schemas with kind vocabularies, free-form `type` strings
- `lib/parapet.ex` — `attach/1` with `Code.ensure_loaded?` (lines 41–43)
- `lib/parapet/internal/application.ex` — confirms `Parapet.Capabilities` is supervised
- `priv/templates/parapet.gen.ui/{operator_components,operator_detail_live}.ex.eex` — existing Preview/Confirm UI surface
- `priv/templates/parapet.gen.runbooks/*.ex.eex` — seven existing runbook templates
- `mix.exs` — declared deps (no v1.1 changes needed)
- `examples/demo_app/{mix.exs,priv/repo/seeds.exs}` — demo state (zero capability-backed seeds today)
- `docs/operator-ui.md` Phase 7 — Preview-First Recovery design (D-20/D-21 safety principles)
- `docs/stability.md` — stability tiers, telemetry freeze, breaking-vs-additive matrix
- `.planning/PROJECT.md` — v1.1 milestone scope, anti-feature precedents, key decisions
- `.planning/threads/actionable-recovery-design.md` — v1.1 wedge definition, "Lean: A" behaviour shape decision
- `.planning/threads/slo-state-off-application-env.md` — anti-pattern parapet is already paying for (Pitfall 13)
- `.planning/phases/22-release-readiness-1-0-cut/22-LEARNINGS.md` — LEARN-22-C (LEARNINGS as default), LEARN-22-E (v1.0 froze detection; v1.1 is execute)

### Secondary (MEDIUM confidence)
- `prompts/sre-best-practices-solo-founder-deep-research.md` — operator-in-the-loop, AI Level 1/2/3 distinction, "narrow audited human-approved" rule
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned beats remote magic, operator UX is product scope, behavioural seams over magical DSLs
- `.planning/research/PITFALLS.md` (v0.10 baseline) — discipline patterns transfer across milestones
- Hexdocs Oban (≥ 2.17): `Oban.retry_job/1`, `Oban.cancel_job/1` are stock — no `oban_pro` needed

### Tertiary (LOW confidence)
- PagerDuty Runbook Automation, Rundeck competitor docs (FEATURES.md competitor analysis) — WebSearch-verified against vendor docs but not deeply hands-on

---
*Research completed: 2026-05-27*
*Ready for roadmap: yes*
