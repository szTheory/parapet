# Pitfalls Research — v1.1 Actionable Recovery

**Domain:** Adding executable runbook recovery actions to an existing Elixir/Phoenix OSS SRE library (Parapet v1.0 → v1.1). Operator-in-the-loop only; host-owned execution; stability/telemetry contract already frozen.
**Researched:** 2026-05-27
**Confidence:** HIGH — pitfalls grounded in direct audit of `Parapet.Operator.ActionPayload`, `Parapet.Automation.{ClaimService,CircuitBreaker,Executor}`, `Parapet.Runbook`, the existing v0.8 auto-execution surface, `docs/operator-ui.md` Phase 7 design, the v1.0 stability tier doc, and the prior `.planning/research/PITFALLS.md` baseline from v0.10.

> **Read-this-first orientation.** v1.1 is *not* greenfield. The existing seams (`ActionPayload`, `ClaimService`, `CircuitBreaker`, `TimelineEntry`, `ToolAudit`, `Parapet.Runbook` DSL, the v0.8 `Parapet.Automation.Executor` and its `:system` identity convention) are already shipping under documented stability tiers. Most of the v1.1 pitfalls are about how those seams interact with a new operator-driven Confirm flow — not about inventing parallel infrastructure. Reaching for "let's make a new claim service for human-triggered actions" is a smell.

---

## Critical Pitfalls

### Pitfall 1: Confirm flow that auto-executes when the operator only meant to peek

**What goes wrong:**
The Confirm button is wired to a LiveView `phx-click` that calls the capability's execute path immediately. Either:
- The "Preview" button reuses the same handler with a flag that's easy to forget to check (`if params["confirm"], do: execute, else: preview`).
- The Confirm button is rendered next to Preview from the start, so an operator who clicked "Preview" to investigate ends up one keystroke or one accidental Enter-press away from mutating production.
- The handler short-circuits the preview render entirely if the capability returns `{:ok, :idempotent}` and treats the call as "well, it didn't change anything, so we may as well move on."

**Why it happens:**
The Phase 7 design in `docs/operator-ui.md` defines a three-state flow (Guidance → Preview → Confirm), but LiveView's natural ergonomic is one socket-event handler per button. Without explicit state in the LiveView assigns gating Confirm behind a Preview-rendered-successfully sentinel, the two buttons become two pieces of UI, not two states of a state machine.

**How to avoid:**
- Treat Preview → Confirm as a **server-side state machine** on the LiveView socket, not as two unrelated buttons. The Confirm button must not render until `socket.assigns.recovery_step.status == :previewed` AND the preview is for the exact same `(capability, resolved_args, idempotency_key)` triple the Confirm will execute against.
- Show the resolved args verbatim in the Preview block. Re-resolving args between Preview and Confirm is a separate footgun (see Pitfall 3).
- The capability behaviour must have a distinct `c:preview/2` callback that returns `{:ok, %PreviewReport{}}` and **must not** call any mutating code. Execute is a separate `c:execute/2` callback. Dialyzer + behaviour contract enforce this — two callbacks is not noise, it is the safety surface.
- Add a test that the LiveView never accepts a Confirm event without a prior Preview event in the same socket lifecycle. Use `Phoenix.LiveViewTest.element/3` + `render_click/2` and assert that clicking Confirm before Preview is either a no-op or returns a flash error.

**Warning signs:**
- Capability modules expose a single `c:run/2` callback used for both preview and execute, distinguished by an `opts[:dry_run]` flag. This is the wrong shape.
- LiveView handlers named `handle_event("recovery_action", ...)` (single handler) rather than `handle_event("preview_recovery", ...)` and `handle_event("confirm_recovery", ...)`.
- Tests that exercise "the recovery flow" by jumping straight to the execute path.

**Phase to address:**
**The phase that introduces the capability behaviour + LiveView flow.** This is the first place the safety posture is wired; if it lands wrong, everything downstream inherits the defect.

---

### Pitfall 2: Double-Confirm produces duplicate execution (idempotency-key gap)

**What goes wrong:**
Operator clicks Confirm. Network is slow. Operator clicks again. Or: operator's browser auto-retries the LiveView WebSocket message. Or: operator pastes the runbook URL into a second tab and clicks Confirm in both. The capability runs twice. If the capability is "requeue 47 dead-letter jobs," 94 jobs now exist.

**Why it happens:**
`Parapet.Operator.ActionPayload` already requires an `idempotency_key` for `:execute_mitigation` actions (`lib/parapet/operator/action_payload.ex:44-49`), and `Parapet.Automation.ClaimService` already uses `on_conflict: :nothing` against the unique `(incident_id, action_kind, action_key)` tuple. The pitfall is **not generating the idempotency key in the right place**:
- If the key is generated on Confirm-click (client → server), two clicks generate two keys → two claim rows → two executions. The `ClaimService` thinks they are different logical actions.
- If the key is bound to `(incident_id, step_id)` but not to the operator's specific Preview session, two operators previewing the same step at the same time both try to Confirm and collide; one wins, the other gets a confusing claim-conflict error.

**How to avoid:**
- Generate the idempotency key **at Preview render time**, store it in the LiveView socket assigns, and reuse the same key for the Confirm event. Format: `recovery_#{incident_id}_#{step_id}_#{preview_session_id}` where `preview_session_id` is a per-mount UUID. Double-clicks reuse the key (claim conflicts to the same row → second call returns the same outcome). Concurrent operators get different keys but the same `(action_kind, action_key)` tuple, so one wins the claim and the other gets a clean "another operator is executing this" message — not a duplicate execution.
- Make `ClaimService.claim_action/1`'s `{:conflicted, claim}` return shape the **primary success path for retries**: if the claim exists and is `status: "executed"`, return the previous outcome instead of erroring. This is what makes the second Confirm-click cleanly idempotent.
- Test: simulate two near-simultaneous Confirm clicks against the same `(incident, step)` via concurrent Tasks in a Concurrency test. Exactly one capability `c:execute/2` call. Exactly one `ToolAudit` row marked `success: true`. The losing call gets an audit row marked `success: false, output: %{reason: "claim_conflicted"}` (or chooses not to write at all — see Pitfall 6).

**Warning signs:**
- The idempotency key is built in the `handle_event("confirm_recovery", ...)` handler using `Ecto.UUID.generate/0` or `System.unique_integer/0`.
- The capability's `c:execute/2` callback receives `idempotency_key` as an opaque string it never uses for its own deduplication.
- `mix test` passes but a manual "click Confirm twice fast" in the demo seed produces two TimelineEntry rows.

**Phase to address:**
**Same phase as Pitfall 1.** The idempotency-key lifecycle is a property of the Preview → Confirm seam; it cannot be retrofitted without changing the LiveView shape.

---

### Pitfall 3: Resolved args drift between Preview and Confirm (TOCTOU)

**What goes wrong:**
Preview says "Will re-enqueue 47 jobs from `default` queue." Operator reads, thinks, confirms 30 seconds later. The capability re-reads "jobs in `default` past their lease" and finds 89 jobs (because another batch stalled in between). Operator sees `success: true, jobs_requeued: 89` in the timeline. The Preview lied — not because anyone wrote a lie, but because the resolved scope was recomputed.

**Why it happens:**
The natural way to write a capability is "the capability owns the logic; preview and execute both compute over current state." That's wrong for any capability whose scope is unbounded by definition. Stalled-async jobs, suppressed deliveries, dead-letter batches — all grow over time as the underlying failure mode continues.

**How to avoid:**
- The capability's `c:preview/2` callback must **return a `%PreviewReport{}` struct containing the exact target set** (e.g., a list of job IDs, message IDs, queue snapshot timestamps). The `c:execute/2` callback receives the preview report and operates strictly on that frozen target set.
- The capability is responsible for handling "what if one of those jobs already completed between Preview and Confirm?" — typically by treating that as `success: true, skipped: [job_id, ...]`, not by silently expanding scope.
- The PreviewReport struct should be wire-stable enough to embed in the `ActionPayload.idempotency_key` derivation (hash of the report) so a Confirm against a stale Preview cleanly conflicts.
- Document this contract explicitly: **"Capabilities never re-resolve scope between Preview and Confirm."** Put it in the `Parapet.Recovery` behaviour `@moduledoc` and the recovery-authoring guide.

**Warning signs:**
- Capability modules where `c:execute/2` queries the database before doing the mutation.
- PreviewReport types that contain only a count (`%{job_count: 47}`) instead of identifiers (`%{job_ids: [...], snapshot_at: ~U[...]}`).
- The recovery-authoring guide doesn't mention the word "snapshot" or "frozen target set."

**Phase to address:**
**The capability behaviour design phase.** This is a contract decision, not an implementation detail — once a capability ships with a counts-only PreviewReport, the contract is set.

---

### Pitfall 4: Multi-node claim leak (claim won, executor crashes, claim never released)

**What goes wrong:**
Node A wins the claim via `ClaimService.claim_action/1` and starts executing the capability. Node A crashes (BEAM OOM, hardware failure, deploy mid-execution) before `mark_executed/1` runs. The claim row stays `status: "claimed"` forever. Subsequent Confirm attempts get `{:conflicted, %{status: "claimed"}}` and refuse to execute, even though the work was never actually completed.

**Why it happens:**
`ClaimService.claim_action/1` (`lib/parapet/automation/claim_service.ex:17-63`) wraps the claim acquisition + gates in a DB transaction, but the actual capability execution happens **outside** that transaction (it has to — capabilities call out to Oban, external APIs, etc.). The transaction commits the claim before execution starts. If execution crashes, the claim is orphaned.

The v0.8 `Parapet.Automation.Executor` partially handles this because it runs inside an Oban job which has its own retry/discard semantics, but a human-Confirm flow doesn't go through Oban by default.

**How to avoid:**
- **Add a `claimed_at` + `lease_until` column to `parapet_action_claims`** (already has `claimed_at`, just needs the TTL). On Confirm, the claim is created with `lease_until: now + 5 minutes` (configurable per capability).
- **The claim is considered free if `status == "claimed" AND lease_until < now()`.** Add a `claim_action/1` branch: if the conflicting row is expired, atomically reset it (`UPDATE ... WHERE id = ? AND lease_until < now() RETURNING *`) and treat as `:won`. This is what makes the claim self-healing without a separate sweeper process.
- For long-running capabilities, the capability can extend its own lease (`ClaimService.extend_lease(claim, additional_seconds)`).
- **Document the failure modes per capability:** a "dead-letter drain" that touches 10k jobs needs a longer default lease than a "feature flag toggle" that takes 50ms. Lease length is a capability declaration, not a global config.
- This is also where multi-node safety meets idempotency: a stale lease + the idempotency-key check means a retry-after-crash re-uses the same idempotency key, hits the capability's own dedup (e.g., Oban's `unique:`), and naturally no-ops.

**Warning signs:**
- The `action_claims` table has no `lease_until` column or no test that exercises lease expiry.
- Recovery actions hang in the operator UI forever after a node restart.
- Demo seed includes a "long-running" capability that times out at 30 seconds without a configured lease.

**Phase to address:**
**The phase that introduces the human-Confirm capability dispatch path.** The lease column is a schema migration; deferring it means a v1.2 schema migration that breaks claim ordering. This is "land it in v1.1 or pay forever."

---

### Pitfall 5: Stale incident state under Confirm (incident resolved while operator was deciding)

**What goes wrong:**
Operator opens the incident at 10:00, reviews the runbook, clicks Preview at 10:02, reads the report, walks away for coffee. At 10:05, another operator resolves the incident from a different tab. At 10:07, our operator returns and clicks Confirm. The capability runs against a resolved incident — and either:
- (a) Quietly succeeds, because the capability doesn't check incident state. Now there's a `:recovery_action` TimelineEntry on a resolved incident, which confuses the retrospective generator.
- (b) Crashes mid-execution because the incident state machine refuses the action, leaving the claim row stuck.

**Why it happens:**
`ClaimService.claim_action/1` already has an `incident_state_gate/1` (`lib/parapet/automation/claim_service.ex:119-120`) that short-circuits with `"already_#{state}"` if the incident isn't `open`. That gate is correct, but it runs *inside* the claim transaction, so the failure mode is `{:short_circuited, claim, "already_resolved"}`, which the LiveView must handle as a user-facing flash, not as an opaque error.

**How to avoid:**
- The LiveView **must subscribe to incident state changes via PubSub** (the existing `Parapet.Operator` already broadcasts; use it). When the assigned `incident.state` changes from `open` to anything else, the Confirm button is disabled with a banner: "This incident is now resolved. Refresh to see the latest state."
- The Confirm handler must explicitly pattern-match `{:short_circuited, _claim, "already_" <> state}` and render a user-friendly message ("Cannot run recovery: incident already #{state}"). Do not let the operator see an Ecto error or a generic 500.
- The LiveView should also re-fetch incident state immediately on Confirm-click (before posting to the ClaimService) as a fast-path; the ClaimService remains the authoritative gate.
- Test: open two LiveView sessions on the same incident. Resolve from session A. Click Confirm in session B. Assert: no capability call, friendly flash, no spurious TimelineEntry.

**Warning signs:**
- The recovery flow tests only cover the happy path (incident is `open`, capability succeeds).
- `incident.state` is read once at LiveView mount and cached for the session.
- The Confirm handler has no explicit branch for `{:short_circuited, _claim, _reason}`.

**Phase to address:**
**Same phase as Pitfall 1.** State staleness is a property of the Preview → Confirm flow; the PubSub wiring belongs with the rest of the LiveView state machine.

---

### Pitfall 6: TimelineEntry/ToolAudit noise drowns the actual recovery signal

**What goes wrong:**
Every Preview click, every Confirm click, every claim conflict, every short-circuit, every retry produces a TimelineEntry. By the time the operator has resolved the incident, the timeline has 47 entries for a single recovery action: preview-shown, preview-shown-again, preview-shown-again, confirm-clicked, claim-conflicted, confirm-clicked, short-circuited, confirm-clicked, claim-won, execute-started, execute-progress-1, execute-progress-2, ..., execute-completed, audit-written. The retrospective generator now produces 4 pages of garbage. The Phase 6 triage block is unreadable.

OR the opposite: only `success: true` outcomes write a TimelineEntry, so when an operator clicks Confirm three times because nothing is happening, there is no record of why. Post-incident, no one knows what was tried.

**Why it happens:**
Audit verbosity has no natural anchor. Without an explicit policy, every developer adding a new capability picks their own granularity, and the median pattern in Elixir codebases is "write to timeline at every interesting event" — which is way too much.

**How to avoid:**
Establish a **three-tier audit contract** in the `Parapet.Recovery` behaviour doc and enforce it via test fixtures:

1. **TimelineEntry** is for **operator-visible facts**: preview-rendered (one entry per distinct preview, with the resolved scope), confirm-executed (one entry per claim that reaches `executed` status), short-circuited (one entry per short-circuit reason; **deduped per `(incident, step, reason)` per hour** so a flapping breaker doesn't produce 600 rows).
2. **ToolAudit** is the **machine-grade execution record**: one row per call to `c:execute/2`, with `input` (the frozen target set), `output` (the result struct), `success` (boolean), `duration_ms`. Always written, even on failure. This is the row the retrospective generator reads for "what was tried."
3. **Telemetry events** (`[:parapet, :recovery, :preview | :confirm | :short_circuit | :execute_start | :execute_stop]`) carry the high-frequency stuff: every click, every gate decision. These flow to Prometheus and Loki, **not** to the Ecto timeline. **Frozen telemetry contract:** these event names must be settled in the v1.1 spec doc and never changed without a deprecation cycle (see Pitfall 11).
- Preview-click without a render-success should NOT write a TimelineEntry. Only the **rendered preview** (which has a resolved scope to display) is a fact worth durable storage.
- The retrospective generator (`Parapet.Evidence.Retrospective`) needs to learn about the new `type: :recovery_action` and `type: :recovery_short_circuit` timeline types; otherwise they fall through to the "Other" section and look like noise.

**Warning signs:**
- TimelineEntry rows for the same `(incident, step_id, reason)` appearing more than once per hour.
- The retrospective for a resolved incident contains the word "Preview" more than 3 times.
- A capability writes to TimelineEntry from inside `c:preview/2`. Preview is a read-only inspection; it should write at most one entry on render-success.
- No ToolAudit row exists for a failed capability execution. Failure is data, not absence-of-data.

**Phase to address:**
**The audit-propagation phase.** Establish the three-tier contract before any capability ships. Retrofitting "actually, preview-clicks shouldn't write" after 4 capabilities have shipped means a data migration on customer databases.

---

### Pitfall 7: Capability behaviour with too many required callbacks (DX cliff)

**What goes wrong:**
The first capability the parapet team writes (e.g., `RetryDLQ`) defines 7 callbacks: `c:name/0`, `c:label/0`, `c:description/0`, `c:preview/2`, `c:execute/2`, `c:rollback/2`, `c:expected_duration_ms/0`. Every host app that wants to add a custom recovery action must implement all 7. Most adopters implement 3 of them (`name`, `preview`, `execute`) and ship; the others are silently `nil`-returning, which breaks the operator UI in subtle ways three weeks later.

**Why it happens:**
Behaviour design tends toward maximalism — "we might need this signal someday, let's require it." The `Parapet.Integration` behaviour got this right in v0.10 (one required callback, others optional with sane defaults) but only after the v0.10 Phase 18 audit found the Rulestead `attach/0` defect. The lesson is fresh enough that we *should* avoid re-learning it; it is also fresh enough that the maintainer is primed to over-correct in the other direction (one giant callback that does everything).

**How to avoid:**
- **Two required callbacks: `c:preview/2` and `c:execute/2`.** Everything else has a default implementation supplied by `use Parapet.Recovery`:
  - `c:name/0` defaults to the module's last segment lowercased (`MyApp.Recovery.RetryDLQ` → `:retry_dlq`).
  - `c:label/0` defaults to a humanized version of the name (`"Retry DLQ"`).
  - `c:description/0` defaults to the module's `@moduledoc`.
  - `c:expected_duration_ms/0` defaults to `5_000`.
  - No `c:rollback/2` callback at all in v1.1. Rollback is a separate capability (e.g., `MyApp.Recovery.UnrequeueDLQ`) and the operator picks it explicitly. (Resist the scope creep — see Pitfall 8.)
- The Preview report struct shape is **defined by parapet, not by the capability**. `%Parapet.Recovery.PreviewReport{summary: String.t(), scope: map(), warnings: [String.t()], blast_radius: :exact | :bounded | :broad}`. Capabilities fill it; they don't redefine it. This is what makes the UI rendering uniform across capabilities.
- The `c:execute/2` return contract is `{:ok, %Parapet.Recovery.ExecutionResult{}} | {:error, term()}` — bounded atoms in the error vocabulary (`:precondition_failed`, `:provider_unavailable`, `:partial_failure`, `:internal_error`). The operator UI maps these to specific user-facing messages. Free-form error tuples are forbidden.
- Test: write a "minimal capability" example in the docs (3 lines of body inside `use Parapet.Recovery` + `def preview/2 + def execute/2`). Confirm it compiles, dispatches, and renders correctly in the demo. If the minimal example is 30 lines, the behaviour is too heavy.

**Warning signs:**
- More than 2 `@callback` declarations without `@optional_callbacks`.
- The recovery-authoring guide's "your first capability" example is longer than 30 lines.
- Behaviour callbacks return `term()` rather than typed structs.

**Phase to address:**
**The capability behaviour design phase.** The behaviour shape ships frozen in v1.1; adding required callbacks in v1.2 is breaking under the v1.0 stability promise (`Parapet.Recovery` will be Stable-tier from day 1 — see Pitfall 11).

---

### Pitfall 8: Autonomous-remediation creep dressed up as "smart defaults"

**What goes wrong:**
v1.1 ships operator-in-the-loop Confirm. v1.1.1 adds "if the same step has been Confirmed by an operator 3 times in the last hour for the same alert family, auto-execute on the 4th alert" as a "convenience." This is autonomous remediation in a trench coat. It bypasses the explicit Confirm contract, breaks the audit-first promise (no operator identity on the auto-fire), and re-opens the entire "what's the blast radius?" debate from the v0.8 escalation work.

OR, more subtly: a capability's Preview is so cheap and so detailed that the operator UI starts running Preview automatically on incident-open ("to save the operator a click"). Now the system is making calls to host capabilities without explicit operator action. Even if those calls are read-only, they may have rate limits, cost money (e.g., querying Stripe for a delivery list), or trigger downstream observability noise.

Note: parapet already has the v0.8 `auto_execute` flag in `Parapet.Runbook.step/2`. That's a deliberately bounded surface (it goes through `Parapet.Automation.Executor`, the circuit breaker, the `:system` identity convention, and explicitly Oban-queued). The pitfall is **conflating v1.1's human-Confirm path with that v0.8 surface**, or letting v1.1's human-Confirm path grow an auto-trigger.

**How to avoid:**
- **Hard architectural rule:** the `Parapet.Recovery` capability dispatch path (new in v1.1) never calls `c:execute/2` without an operator-supplied `ActionPayload` where `actor` is a non-`system:*` URN. Enforce in code: `ActionPayload.changeset/2` adds a validation that rejects `actor` starting with `system:` for any payload routed through the human-Confirm path. The v0.8 auto-execution surface still works (it has its own path through `Parapet.Automation.Executor` and uses `actor: "system:automation:executor"`), but the human-Confirm seam refuses system actors.
- **No "auto-preview"** in v1.1. Preview is always operator-triggered. Document this explicitly: "Preview is a deliberate operator action. The UI never previews on incident-load."
- **No "remember last operator's choice"** convenience features. Each Confirm is an independent decision.
- The boundary lives in code, not just docs: write a property-based test that for every value of `actor`, the human-Confirm path rejects it unless it's a URN that doesn't start with `system:`.
- When someone (including the maintainer) proposes a "smart" addition that reduces operator-click count, route the proposal through this question: **"Does this change remove a deliberate decision moment?"** If yes, it is autonomous-remediation creep regardless of how it's framed.

**Warning signs:**
- A PR titled "auto-execute trusted capabilities" or "skip preview for read-only actions" or "remember last Confirm."
- Capability code that reads incident state via PubSub and starts a preview without an operator event.
- The v0.8 `Parapet.Automation.Executor` is imported into the new v1.1 LiveView path.
- The `:system:` actor prefix is allowed through the human-Confirm changeset validation "just for this one capability."

**Phase to address:**
**Ongoing.** This is the dominant scope-creep vector for v1.1 and the entire v1.x line. Codify the rule in `CONTRIBUTING.md`, the `Parapet.Recovery` `@moduledoc`, and `docs/operator-ui.md`. Every PR touching the human-Confirm path must re-justify the actor-prefix rule.

---

### Pitfall 9: Cross-app correlation creeping into the capability dispatch shape

**What goes wrong:**
A v1.1 capability is designed with `c:execute(incident, args, opts)` where `opts` includes `:correlated_incidents` — a list of other incidents the host app thinks are related. The capability is supposed to ignore the field for now, but it's "convenient to have for v1.4+." Two phases later, an internal capability starts using it: "if there are correlated incidents in the same `correlation_key`, also resolve them." Now the v1.1 contract has a cross-app surface that adopters cannot reason about, and v1.4's cross-app correlation work inherits a partly-built API instead of designing one cleanly.

**Why it happens:**
The Roadmap notes v1.4+ for cross-boundary journey correlation. The temptation to "leave a hook for v1.4" is universal. The lesson from `Parapet.SLO.define/2`'s deprecation is exactly this: API surface added speculatively becomes API surface that has to be deprecated through a full cycle.

**How to avoid:**
- The `c:execute/2` signature is **strictly** `c:execute(incident :: Incident.t(), preview_report :: PreviewReport.t())`. No third opts argument. No `correlated_incidents` field on the PreviewReport. No `cross_app_*` anything.
- The `Parapet.Recovery.PreviewReport` struct has a closed key list defined as `defstruct/1` in v1.1. Adding fields requires a minor-version CHANGELOG entry (it's additive, so allowed under stability) but **removing fields requires a major bump**. This means adding speculative fields locks them in forever. The cost of speculation is high, by design.
- The `incident` parameter to `c:execute/2` is the single-app `Parapet.Spine.Incident` — no parent/child relationship surface, no `peer_incidents` association. If v1.4 needs that, it adds a new behaviour (`Parapet.Recovery.CrossApp`) rather than mutating the existing one.
- Write the v1.1 docs to explicitly say "Capabilities operate on exactly one incident. Cross-incident orchestration is a host-app concern outside parapet's scope."

**Warning signs:**
- The PreviewReport struct has a `peer_incidents`, `correlation_group`, `tenant_id`, or `organization_id` field that's documented as "unused for now."
- Capability examples in docs show `Enum.each(incidents, fn i -> ... end)` patterns.
- The `c:execute/2` callback has any opts beyond `(incident, preview_report)`.

**Phase to address:**
**The capability behaviour design phase.** Same architectural moment as Pitfalls 1, 3, 7.

---

### Pitfall 10: Multi-tenant assumptions silently baked into the v1.1 schema

**What goes wrong:**
Multi-tenant action scoping is explicitly deferred to v1.4+. But v1.1 needs to record "who ran this action" in the audit row. The developer adds a `tenant_id` column to `parapet_tool_audits` (defaulting to `nil`) "to make the v1.4 migration easier." Or worse: assumes the host app has a single tenant and writes the capability dispatch to look up "the org" via `Application.get_env`. Either way, v1.4 inherits a schema designed with the wrong assumptions.

The opposite trap: v1.1 designs the capability dispatch in a way that makes it impossible to add tenant scoping without breaking the public API in v1.4. E.g., capabilities are registered globally via `Parapet.Recovery.register/2` — there's no per-tenant registry hook.

**Why it happens:**
"Multi-tenant" sounds like a feature; "single-tenant" sounds like a deficit. Developers naturally feel pressure to "not paint themselves into a corner." But premature multi-tenancy is more expensive than premature single-tenancy because it shapes the entire data model.

**How to avoid:**
- **v1.1 is explicitly single-tenant per parapet instance.** A host app running multiple tenants either (a) runs separate parapet OTP apps per tenant (acceptable for the v1.x window) or (b) waits for v1.4. No middle ground in v1.1.
- **No `tenant_id` columns** on any new v1.1 schema (the capability dispatch should not require any new schema beyond what `ActionClaim`, `ToolAudit`, and `TimelineEntry` already have). If a column is added "for v1.4," that's the wrong design.
- The capability registry is module-global (matches `Parapet.Integration` for adapters). v1.4 will need to add a per-tenant registry layer; that's a new API, not a modification of v1.1's API. Mark this in the `Parapet.Recovery` `@moduledoc`: **"The capability registry is global to the parapet application. Multi-tenant scoping is not supported in v1.x."**
- The `actor` field in `ActionPayload` is the **only** identity surface in v1.1. It's free-form (URN string). If a multi-tenant host wants to encode tenant identity, they do so by convention (`actor: "user:42@org:7"`), not via parapet schema fields. v1.4 can add structured tenant fields then.
- Test: grep the v1.1 codebase for `tenant`, `organization`, `org_id`. Any match is a red flag and needs justification.

**Warning signs:**
- Migrations introducing `tenant_id` or `organization_id` columns on parapet tables in the v1.1 window.
- `Parapet.Recovery.register_for_tenant/2` or similar in the proposed API.
- The recovery-authoring guide mentions multi-tenant patterns at all.
- A "we'll just default it to nil for now" comment in a schema migration.

**Phase to address:**
**The schema-stability phase early in v1.1.** Once a column ships in a migration, removing it is breaking under the experimental tier policy (and brutal for adopters who've run the migration). The v1.4 graduation should be the only time tenant fields enter the schema.

---

### Pitfall 11: Telemetry contract drift introduced by new `[:parapet, :recovery, ...]` events

**What goes wrong:**
v1.1 introduces telemetry events for the new recovery dispatch path. The naming is decided ad-hoc during implementation: `[:parapet, :recovery, :preview, :start]`, `[:parapet, :recovery, :preview, :stop]`, `[:parapet, :recovery_action, :executed]`, `[:parapet, :recovery, :confirm_completed]`. Some events use `:span`/`:start`/`:stop` triplets, some are single events, some use `:execute` and some use `:executed`. v1.1 ships, adopters wire their Grafana dashboards, then v1.2 needs to "fix" the inconsistency — which breaks every adopter's dashboard.

**Why it happens:**
`docs/stability.md` says **"The `[:parapet, …]` telemetry event surface is frozen as of v1.0.0."** New event families are additive (allowed) but their names cannot drift after they ship. The maintainer knows this in principle, but if the events are scattered across 6 PRs adding capabilities, the naming consistency erodes invisibly.

**How to avoid:**
- **Land the full v1.1 telemetry contract in a single design doc and PR before any capability ships.** Define the exact event names, measurement keys, metadata keys for: preview-show, preview-render-failure, confirm-clicked, claim-conflicted, claim-short-circuited, execute-span-start, execute-span-stop, execute-result-success, execute-result-failure. Treat this as a frozen contract from the moment it merges.
- Naming convention: follow the existing `[:parapet, :slo, :evaluation, :start | :stop]` pattern for spans, and `[:parapet, :runbook, :step, :executed]` for one-shot events. Don't invent new shapes.
- Add to `docs/telemetry.md` (the public reference) in the same PR. If the docs and the code disagree, the docs are right and the code is wrong (and must be fixed before merging).
- Test: a `verify.telemetry_contract` mix task that asserts the documented events are exactly the events emitted by the codebase. Catches drift at CI time.

**Warning signs:**
- New telemetry events appearing in PRs without a corresponding update to `docs/telemetry.md`.
- Two events with similar names that differ in pluralization or verb tense (`:executed` vs `:execute_completed`).
- Events without a documented measurement/metadata schema.

**Phase to address:**
**The telemetry contract phase before any capability implementation.** This is exactly the "code surfaces land before the docs that name them" lesson from v0.10 Phase 18 (Key Decisions table) — applied to telemetry.

---

### Pitfall 12: Demo seed that misleads more than it demonstrates

**What goes wrong:**
The demo app seeds an incident with a recovery action and runs `iex -S mix phx.server`. But:
- (a) The seeded action is a no-op pretending to do something ("Preview: will retry 5 jobs. Confirm: ✓ Done."). The capability never touched anything real. Adopters who copy the pattern think their version "works" without realizing the demo lied.
- (b) The seeded action requires Postgres + Oban + Mailglass + Rindle all installed, so it only works if you ran 6 setup steps. Adopters who skip even one see a broken demo and conclude parapet is broken.
- (c) The seeded action is "delete a record" — destructive, irreversible, and trains adopters that recovery actions can be destructive. (They shouldn't be; in v1.1 they should be re-enqueue/retry/mark-resolved patterns.)
- (d) The seeded action works once. After Confirm, the demo is in a different state and re-running it shows nothing. Adopters can't replay the smoke test.

**Why it happens:**
Demo seeds are scoped under "polish" pressure. The demo must work end-to-end with one command. To achieve that, developers cut corners on what the seeded capability actually does.

**How to avoid:**
- **The demo seed must include at least one capability that does a real, reversible thing** against the demo app's own database — e.g., a "mark 3 stalled demo orders as needs-review" capability that flips a status column. The Preview shows the actual rows. The Confirm flips the column. Re-seeding restores them.
- **The demo seed must be replayable.** Provide a `mix demo.reset` task that wipes incidents, re-seeds the failure scenarios. Adopters can run the recovery smoke test repeatedly without manual cleanup.
- **At least one seeded capability must demonstrate Preview-without-Confirm** (operator looks, decides not to act, abandons). The demo's testing of the "didn't confirm" path is as important as the testing of the "did confirm" path — it proves Preview is safe.
- **At least one seeded capability must demonstrate the short-circuit path** (e.g., incident already resolved, claim already won by another operator). The demo's value comes from showing the safety nets working, not just the happy path.
- **The seeded actions must not be destructive.** No `DELETE FROM`. No external HTTP POSTs to live providers. The capability set should be: re-enqueue (Oban), flip-status (Ecto column update), mark-resolved (state transition). All reversible by `mix demo.reset`.
- The demo app's CI lane (Phase 21 contract test from v1.0) should exercise the recovery flow end-to-end — Preview rendered, Confirm executed, TimelineEntry/ToolAudit asserted, state changed.

**Warning signs:**
- Seeded capabilities whose `c:execute/2` body is `{:ok, %ExecutionResult{}}` with no side effects.
- The demo README has more than 3 setup steps before "run `mix demo.start`."
- A seeded capability does a `Repo.delete_all/1` or hits an external network endpoint.
- The demo can only be run once before requiring manual database cleanup.
- The CI lane skips the recovery flow tests.

**Phase to address:**
**The demo-seed phase, with explicit gate criteria.** A demo seed that's not in CI is a demo seed that will break silently. Both the seed and the CI lane land in the same phase.

---

### Pitfall 13: `Parapet.Recovery` registry repeating the `Parapet.SLO` Application-env mistake

**What goes wrong:**
v1.1 introduces a recovery registry: `Parapet.Recovery.register(MyApp.Recovery.RetryDLQ)` is called from the host app's `application/0` callback. The naïve implementation writes to `Application.put_env(:parapet, :recovery_capabilities, [...])` because that's what the v0.10-era `Parapet.SLO` does. Two months later, every test that touches recovery has to be `async: false` because the env collides. The v1.2 thread `slo-state-off-application-env.md` exists precisely to fix this in `Parapet.SLO`, and we'd be re-creating the same mistake one milestone later.

**Why it happens:**
Application env is the path of least resistance for "I need a global lookup table." It's how `Parapet.SLO` works today. New code naturally copies established patterns. The thread `slo-state-off-application-env.md` is in `.planning/threads/` but not yet acted on (target: v1.2). v1.1 work that lands before v1.2 will copy the bad pattern unless told otherwise.

**How to avoid:**
- **Do not use `Application.put_env/3` as the backing store for the recovery registry.** Use an ETS table owned by a `Parapet.Recovery.Registry` GenServer in the parapet supervision tree (the Option B pattern from `slo-state-off-application-env.md`).
- Make the registry **test-isolatable from day 1**: `Parapet.Recovery.Registry.checkout/1` per test (or use `Mox`-style stubbing of the registry GenServer), so recovery tests can be `async: true` without bleeding state.
- The registry's public API is `Parapet.Recovery.register/1` (idempotent — registering the same module twice is a no-op, not an error) and `Parapet.Recovery.all/0` (returns the current registered modules). Same shape as the SLO registry's future state — both should look alike when the SLO work lands in v1.2.
- If `Parapet.SLO`'s Application-env state can't be cleanly extracted before v1.1 ships (and it shouldn't be — `slo-state-off-application-env.md` is the v1.2 graduation candidate), document **in the v1.1 recovery registry's `@moduledoc`** that the recovery registry is intentionally not using Application env, with a link to the SLO thread for context. This prevents future contributors from "harmonizing" them in the wrong direction.
- Write the registry tests **before** the LiveView/capability tests, and structure them to demonstrate isolation: 100+ async tests registering distinct capabilities should all pass without bleeding. If this is hard, the design is wrong.

**Warning signs:**
- Any `Application.put_env(:parapet, :recovery_*, ...)` call anywhere in `lib/`.
- `async: false` on more than one recovery test, or any recovery test that uses `setup` to snapshot/restore Application env.
- A "convenience" wrapper that reads from `Application.get_env/3` to look up registered capabilities.

**Phase to address:**
**The first phase that introduces `Parapet.Recovery`.** The architectural pattern is decided when the module is created; fixing it later requires deprecation cycles on Stable-tier API. This is the v0.10 SLO mistake we already know about — do not repeat it.

---

### Pitfall 14: Documentation gap between "shipped" and "used" (the v0.10 LEARN-22-C echo)

**What goes wrong:**
v1.1 ships the recovery flow, hexdocs has perfect ExDoc, the demo seed works, CI is green. Three months later, the adoption survey shows: 80% of adopters know parapet has recovery actions, 12% have tried defining one, 3% have it running in production. The gap between "feature ships" and "feature gets used" is the documentation/onboarding gap — exactly what v0.10's Adopter Success milestone solved for SLOs (one-line starter packs, getting-started guide, per-integration guides).

**Why it happens:**
Recovery actions are a *new authoring surface* for adopters. Even a perfect capability behaviour requires the adopter to (a) understand when to author a custom capability vs. use a prebuilt one, (b) know the preview/execute contract, (c) wire it into their runbook, (d) test it locally, (e) trust it in production. Without explicit scaffolding, the cliff between "interesting feature" and "I actually shipped one" is steep.

The v0.10 LEARN-22-C lesson is "phase SUMMARYs ≠ LEARNINGS." The matching v1.1 lesson should be: **"shipped behaviour ≠ adopted behaviour."** Detection of this is the v0.10 muscle memory — apply it deliberately.

**How to avoid:**
- **Ship the prebuilt playbooks (the 4-6 from the milestone goal) before shipping the custom-capability authoring guide.** Adopters get value from the prebuilts immediately; only the most engaged subset will author custom ones in the first 3 months. The prebuilt playbooks ARE the adoption surface; the custom-capability docs are the depth surface.
- **Ship a `mix parapet.gen.recovery` Igniter task** in v1.1 that scaffolds a custom capability module with `c:preview/2` and `c:execute/2` stubs, a unit test, and a wiring example. Mirror the (planned for v1.2) `mix parapet.gen.slo` task shape. This removes the blank-page problem for custom capabilities.
- **The recovery-authoring guide must include a "your first custom capability in 10 minutes" path** matching the getting-started guide's 30-minutes-to-first-alert structure. It must end with a working capability registered and rendered in the operator UI — not at "now you understand the behaviour."
- **The troubleshooting guide must include recovery-specific Q&A:** "capability registered but doesn't show in UI" (runbook mapping missing), "Preview shows blank" (PreviewReport not returned), "Confirm clicked but nothing happens" (claim short-circuited — check the timeline), "claim stuck for 5 minutes" (lease expiry — see Pitfall 4).
- **Per-prebuilt-playbook documentation:** each of the 4-6 prebuilts (retry storm, suppression drift, etc.) gets a small dedicated doc page with: what alert it maps to, what Preview shows, what Confirm does, expected duration, blast radius. Adopters scanning hexdocs for "what does parapet do?" should find these pages first, not the abstract behaviour.
- **Adoption signal in `mix parapet.doctor`:** add a check that reports "X capabilities registered, Y runbook steps mapped, Z recovery executions in the last 30 days." Adopters who installed but haven't wired anything see a `warning` finding pointing to the recovery-authoring guide.
- Write the **v1.1 LEARNINGS file** at phase close (per the v0.10 LEARN-22-C graduation) with explicit attention to "what would prevent the next adoption gap?"

**Warning signs:**
- The recovery docs are 80% capability-authoring deep-dive and 20% prebuilt-usage walkthroughs.
- No `mix parapet.gen.recovery` Igniter task.
- The doctor check has no recovery-adoption signal.
- Hexdocs landing page doesn't mention recovery actions or links straight to the abstract behaviour.
- v1.1 ships without a LEARNINGS file.

**Phase to address:**
**The docs-and-adoption phase at the end of v1.1.** This is the v0.10 Phase 18 pattern — code surfaces land first (capabilities, prebuilts), then docs that name them. The phase ordering matters: prebuilts first, generator second, authoring guide third, troubleshooting fourth, doctor check fifth.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Reuse v0.8 `Parapet.Automation.Executor` for the human-Confirm path | One less GenServer to write | Couples the human and system paths; pollutes the `:system:` actor convention; breaks Pitfall 8's hard-rule enforcement | Never — these are architecturally distinct paths |
| Skip the `lease_until` column on `parapet_action_claims` | One less migration | Claim leaks on node restart become permanent operational pain; v1.2 migration breaks claim ordering | Never — schema decisions land at the original PR |
| Use `Application.put_env/3` for the recovery registry | Matches the existing `Parapet.SLO` pattern | Recreates the exact pain point `slo-state-off-application-env.md` exists to fix; doubles the v1.2 cleanup work | Never — known anti-pattern, paid for in `Parapet.SLO` |
| Allow free-form error tuples from `c:execute/2` | Capabilities can return whatever they want | UI cannot render coherent failure messages; retrospective generator can't categorize failures | Never — error vocabulary is part of the contract |
| Re-resolve scope inside `c:execute/2` | Capability code is simpler (no PreviewReport plumbing) | Preview/Confirm TOCTOU; Preview lies; adopter trust erodes | Never for any capability with unbounded target scope |
| Skip `mix parapet.gen.recovery` Igniter scaffold | One less task to maintain | Adoption gap; custom capability authoring stays as the engaged-only path | Only if a prebuilt playbook covers ≥95% of demand (unlikely) |
| Write all telemetry events ad-hoc across multiple PRs | Lower per-PR overhead | Event naming drift becomes locked-in via stability freeze; v1.2 forced to ship breaking telemetry changes | Never — telemetry contract is a single PR |
| Add `tenant_id` columns "for v1.4 readiness" | Easier v1.4 migration | v1.1 schema baked with wrong assumptions; speculative columns become deprecation surface | Never — v1.4 brings its own schema |
| Capability behaviour with `c:run/2 + opts[:dry_run]` instead of `c:preview/2 + c:execute/2` | One callback instead of two | TOCTOU risk; harder to enforce read-only Preview; harder to type-check; harder to render Preview reports uniformly | Never — preview and execute are semantically different |
| Write TimelineEntry on every preview click | "Comprehensive audit" | Operator UI timeline becomes unreadable; retrospective generator produces garbage | Never — render-success is the fact, click is telemetry |
| Hard-code lease duration globally (e.g., 5 minutes for all capabilities) | One config value | Long-running capabilities (DLQ drain) timeout mid-execution; short capabilities (flag toggle) block too long | Acceptable in v1.1.0 if every capability is bounded ≤ 30s; otherwise per-capability |
| Skip the demo CI lane for recovery flow | Faster CI | Demo silently breaks; the v1.0 contract-test pattern is undermined; adoption signal lost | Never — demo CI is the v1.0 contract |

## Integration Gotchas

Common mistakes when wiring v1.1 recovery into the existing v1.0 surfaces.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| `Parapet.Operator.ActionPayload` | Bypass it for "simple" capability calls | All Confirm-path executions go through `ActionPayload` changeset validation. Non-negotiable; reuses circuit breaker + claim service for free |
| `Parapet.Automation.ClaimService` | Spin up a parallel claim mechanism for human-Confirm | Reuse `ClaimService.claim_action/1`. Human-Confirm uses `action_kind: "recovery"`, system-auto uses `action_kind: "automation"`. Same table, different kind |
| `Parapet.Automation.CircuitBreaker` | Apply circuit breaker to human-Confirm path | **Don't.** Circuit breaker exists to flap-protect *system* execution. Humans clicking Confirm 4 times is not flap; it is the operator deciding the breaker is wrong. Document this explicitly |
| `Parapet.Spine.TimelineEntry` | Add `type: :recovery_preview`, `:recovery_confirm`, `:recovery_short_circuit`, `:recovery_execute_start`, `:recovery_execute_stop`, `:recovery_audit` (six new types) | Use exactly two new types: `:recovery_action` (one per successful execute) and `:recovery_short_circuit` (one per short-circuit, deduped per hour). Everything else is telemetry, not durable timeline |
| `Parapet.Spine.ToolAudit` | Write one ToolAudit row per intent (preview, confirm, execute) | One ToolAudit row per `c:execute/2` invocation only. Preview is read-only — no audit row |
| `Parapet.Runbook` DSL | Add a new `recovery_step/2` macro alongside `step/2` | Extend the existing `step/2` macro with `:capability` and `:requires_preview` opts (already present per `lib/parapet/runbook.ex:33-41`). Use what exists |
| `Parapet.Evidence.Retrospective` | Treat `:recovery_action` timeline entries as generic | Add an explicit section "Recovery actions taken" with capability name, operator, outcome, duration. Otherwise they get lumped into "Other" |
| `Parapet.Integration` behaviour | Conflate with `Parapet.Recovery` behaviour | Different surfaces. `Parapet.Integration` is for telemetry attachment (Sigra, Mailglass, etc.). `Parapet.Recovery` is for capability dispatch. Don't unify them |
| `Parapet.Operator.WorkbenchContract` | Add recovery state directly to the workbench struct | Add a `:recovery` sub-key to keep the surface bounded. Schema migrations on `WorkbenchContract` are stability-protected (it's Experimental) but bloat is still bad |
| Oban (for capability execution) | Run capabilities synchronously inside the LiveView Confirm handler | For capabilities expected to take >500ms, dispatch via Oban with `unique: [period: 3600, keys: [:incident_id, :action_key]]`. LiveView receives async result via PubSub. Idempotency-key flows through |

## Performance Traps

Patterns that work at small scale but fail at production scale.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `ClaimService.claim_action/1` with no DB index on `(incident_id, action_kind, action_key)` | Confirm latency creeps up as `parapet_action_claims` grows | Composite unique index already exists for the on-conflict target — verify it's present and add an explanatory comment | At ~10k action claims (~30 days of moderate use) |
| TimelineEntry timeline render in LiveView fetches all entries | Incident detail page slows after long-running incidents | Use the existing bounded-queue paging pattern from Phase 3 (`Parapet.Operator.list_incident_queue/1`-style) for the timeline too | At ~500 timeline entries per incident |
| Capability execution synchronously blocks the LiveView socket | A slow capability freezes the operator's UI for everyone watching | Long-running capabilities dispatch via Oban; UI subscribes to result PubSub | At any capability >500ms; user-visible at >2s |
| Preview report serialized to LiveView socket assigns is large (e.g., list of 10k job IDs) | LiveView memory growth, socket churn | PreviewReport stores a snapshot reference (e.g., a row in `parapet_action_claims` with the scope as JSONB), not the inline data. UI fetches paginated detail on demand | At any PreviewReport >100 items |
| No backpressure on telemetry events from rapid Confirm-clicks | `[:parapet, :recovery, :confirm]` storms Prometheus on flapping incidents | The Confirm handler is idempotency-keyed; rapid clicks produce one event per unique key. Document this rate limit | At >10 confirms/sec from one operator (rare; mostly a bot/test scenario) |
| Claim sweep query (for expired leases) scans the whole `parapet_action_claims` table | Sweep job slows down as the table grows | Partial index on `(lease_until) WHERE status = 'claimed'`; sweep query uses it | At ~50k action claims |
| TimelineEntry write contention on hot incidents | Multiple operators acting concurrently produce serialization conflicts | Existing `Parapet.Evidence.append_timeline/2` writes are individual transactions; should be fine. Verify by load-testing the demo seed | At >100 timeline writes/incident/min |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Capability allowed to mutate any database row the host app has access to | Adopter accidentally registers a `DeleteAllUsers` capability; one Confirm wipes production | The capability behaviour cannot enforce blast-radius limits in code. Mitigate via: (a) docs warning loudly; (b) `mix parapet.doctor` check that flags capabilities whose `c:execute/2` calls `Repo.delete_all/1`, `Repo.update_all/1`, or `Ecto.Adapters.SQL.query!/4` without explicit `where:`; (c) the `PreviewReport.blast_radius` field must be set, with `:broad` rendering a red warning in the UI |
| `ActionPayload.actor` is set to a non-validated string controllable by the LiveView client | Operator can spoof another operator's identity in audit logs | The `actor` is set server-side from the LiveView socket's assigned `current_user` (or equivalent), never from `params`. The Confirm handler ignores any client-supplied actor field |
| Recovery actions exposed on a public route | Anyone on the internet can trigger production mutations | The Operator UI mount is already documented as authentication-required (`docs/operator-ui.md`). v1.1 must extend this: doctor check that recovery-action LiveView routes are inside an authenticated `live_session`. Same check as the existing `Unsecured operator UI LiveView found` warning, scoped to recovery |
| Capability `c:execute/2` takes external input from incident metadata without validation | An attacker-crafted alert payload triggers a malicious capability arg | Capabilities must validate all incident-derived inputs before acting. The PreviewReport's `scope` is computed server-side from durable Ecto data, never from raw webhook payloads |
| `idempotency_key` containing PII or sensitive data | Audit logs leak data through the key string | The key is a system-generated UUID/hash, never derived from user emails, IDs, or names. Document this; the `Parapet.Recovery.PreviewReport` struct's key-derivation must use opaque hashing |
| Audit log mutability via direct database access | An adopter "cleans up" audit rows after an incident | The existing `Parapet.Spine.ToolAudit` schema has no `update/delete` API in `Parapet.Evidence`. Document in v1.1 that the audit table should be `INSERT`-only via DB role permissions (recommendation, not enforcement) |
| Sensitive capability outputs (e.g., user emails for "drain DLQ") logged in TimelineEntry payload | PII in operator UI and retrospective generator | The `Parapet.Recovery.ExecutionResult` struct must include a `:redacted_summary` field that the timeline writes; the full result is stored in a separate column with restricted access. Document the redaction pattern |

## UX Pitfalls

Operator experience mistakes specific to the recovery flow.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Preview button visible on guidance-only steps | Operator clicks, gets a no-op or error | The `Parapet.Runbook.step/2` macro already has `:kind` (`:guidance` vs `:capability`) — render Preview button only for `:capability` steps |
| Blast-radius indicator missing or vague ("This may affect some jobs") | Operator can't decide whether the action is safe | Required field in PreviewReport: `blast_radius: :exact \| :bounded \| :broad`. UI renders a colored chip: green/amber/red. `:broad` requires a confirmation checkbox before Confirm enables |
| No undo plan documented for any capability | Operator clicks Confirm, capability succeeds, then realizes it was wrong | Each prebuilt playbook documents its undo path (e.g., "To reverse a DLQ requeue, drain via the dead-letter queue"). The capability `@moduledoc` includes a `## Reversal` section. The UI links to it from the post-Confirm timeline entry |
| Preview report buried in a collapsible accordion | Operator skims, clicks Confirm without reading | The PreviewReport renders inline above the Confirm button, full-width, with `:warnings` rendered as a list, not in a tooltip |
| Confirm button label says "Confirm" with no specificity | Operator confirms something different from what they intended | Confirm label includes the action name: "Confirm: Re-enqueue 47 jobs". Dynamic from the resolved scope |
| No keyboard shortcut friction (Enter triggers Confirm) | Accidental Confirm on form fields | Confirm requires explicit click, not Enter. The button is not `type="submit"` on any form |
| Confirm "loading" state without timeout | Operator stares at a spinner forever if capability hangs | Confirm shows elapsed time after 5s ("Running — 7 seconds"). After 30s, offer "Cancel" (which doesn't actually cancel, but records operator intent and marks the lease cancelable; capability may complete anyway with audit reflecting the intent) |
| Success state collapses Preview into a check mark | Operator can't see what they just did | After success, the Preview report remains visible with "Completed at HH:MM" overlay. Operator can scroll back to verify what ran |
| Failure state shows raw Elixir error tuple | Operator sees `{:error, :precondition_failed}` and has no idea what to do | Failure renders user-friendly message keyed to the bounded error atom: `:precondition_failed` → "The incident state changed before the recovery could run. Refresh to see the latest state." Map every error atom to a sentence |
| Per-capability docs not linked from the operator UI | Operator wants to understand the capability mid-incident, has to leave the UI | Each Preview block includes a "Learn more" link to the capability's hexdoc page |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Capability behaviour:** Often missing optional callback defaults — verify a "minimal capability" (3-line example from docs) compiles and dispatches correctly.
- [ ] **Preview/Confirm flow:** Often missing PubSub subscription for incident state changes — verify cross-tab resolve+confirm produces friendly flash, not 500.
- [ ] **Idempotency key lifecycle:** Often missing per-mount UUID derivation — verify double-Confirm produces exactly one execution and one ToolAudit row.
- [ ] **Claim lease:** Often missing `lease_until` column — verify a simulated node crash mid-execution releases the claim after lease expiry.
- [ ] **Audit propagation:** Often missing the three-tier discipline — verify rapid clicks produce telemetry events but not TimelineEntry spam; verify failures still produce ToolAudit rows.
- [ ] **Prebuilt playbooks:** Often missing one of the 4-6 — verify each maps to a JTBD-MAP failure mode (retry storm, suppression drift, stalled async, dead-letter drain, deploy-tied incident, cardinality blowout) with at least Preview-able UI.
- [ ] **Demo seed:** Often missing the short-circuit scenario — verify the demo demonstrates a refused execution (incident already resolved, claim already won) in addition to the happy path.
- [ ] **`mix parapet.gen.recovery` Igniter task:** Often missing — verify it scaffolds a passing test and a working capability stub in under a minute.
- [ ] **Telemetry contract:** Often missing the dedicated docs section — verify `docs/telemetry.md` enumerates every new `[:parapet, :recovery, ...]` event before any code emits them.
- [ ] **`Parapet.Recovery.Registry`:** Often missing the ETS-based isolation — verify 100 async tests registering distinct capabilities all pass.
- [ ] **Doctor check for recovery adoption:** Often missing — verify `mix parapet.doctor` reports capability count and recent recovery executions.
- [ ] **Per-prebuilt-playbook docs:** Often missing — verify hexdocs has a dedicated page for each of the 4-6 prebuilts.
- [ ] **`docs/operator-ui.md` Phase 7 wiring:** Often missing — the design draft has been there since v0.3; v1.1 must mark the section as "implemented in v1.1.0" with version notes.
- [ ] **LEARNINGS file:** Often missing — write at v1.1 close per the v0.10 LEARN-22-C graduation.
- [ ] **Stability tier on `Parapet.Recovery`:** Often missing the explicit declaration — verify the moduledoc has the `> #### Stable {: .info}` callout and the module is listed in `docs/stability.md` Stable Modules table.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Capability registered as autonomous (Pitfall 8 slipped in) | MEDIUM | Add the actor-prefix validation, deprecate the autonomous capability, ship a CHANGELOG entry, write a security advisory if it touched production data |
| Claim leak (Pitfall 4) without lease column | HIGH | Ship lease column migration in patch release; for stuck claims in adopter DBs, provide `mix parapet.recovery.sweep` task to clear claims older than X minutes (operator-confirmed) |
| TimelineEntry noise (Pitfall 6) shipped to adopters | MEDIUM | Audit the dedup rules, ship a fix; provide `mix parapet.recovery.dedupe_timeline` for adopters to clean historical noise |
| `Application.put_env` registry (Pitfall 13) | HIGH | Same architectural lift as the v1.2 SLO registry migration; if shipped, must persist the bug until v2.0 because the API is Stable |
| Telemetry name drift (Pitfall 11) | HIGH | Cannot easily fix — the events are frozen. Either ship both old and new names in parallel (additive, allowed) or accept the drift as documented quirk |
| Demo seed misleading (Pitfall 12) | LOW | Reseed with a real capability, update CI lane, push patch; trust damage is limited because adopters typically inspect seeds |
| Multi-tenant assumptions in schema (Pitfall 10) | HIGH | Migration to drop unused columns is technically allowed (Experimental tier) but disruptive; better to leave the columns and not use them, accept the dead surface, fix in v1.4 |
| Behaviour API too heavy (Pitfall 7) | MEDIUM | Add `@optional_callbacks` and supply defaults in a minor release; existing implementations stay valid |
| Cross-app surface leaked (Pitfall 9) | MEDIUM | Deprecate the field via the standard cycle; remove at v2.0 |
| Documentation gap (Pitfall 14) | LOW (technically) / HIGH (adoption-wise) | Write the missing guides in a docs-only release; deploy via Hex docs (no version bump needed for major fixes via `mix docs`) |

## Pitfall-to-Phase Mapping

How v1.1 roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Auto-executing Confirm | Capability behaviour + LiveView seam phase | Test: Confirm without prior Preview is rejected; behaviour has separate `c:preview/2` + `c:execute/2` |
| 2. Double-Confirm duplicate execution | Capability behaviour + LiveView seam phase | Test: concurrent Confirm clicks produce exactly one execute call |
| 3. Resolved args drift (TOCTOU) | Capability behaviour phase | Test: scope frozen between Preview and Confirm; capability docs explicitly forbid re-resolution |
| 4. Multi-node claim leak | Schema phase (early) | Migration adds `lease_until`; test simulates expired lease and verifies self-healing |
| 5. Stale incident state under Confirm | LiveView seam phase | Test: cross-tab resolve+Confirm produces flash, no capability call |
| 6. TimelineEntry/ToolAudit noise | Audit propagation phase | Test: rapid clicks produce N telemetry events but ≤1 TimelineEntry; failures produce ToolAudit |
| 7. Capability behaviour too heavy | Capability behaviour phase | Minimal capability example compiles and dispatches in ≤30 LOC including the test |
| 8. Autonomous-remediation creep | Ongoing (capability behaviour phase + CONTRIBUTING) | Test: `actor` starting with `system:` rejected by `ActionPayload` changeset on the Confirm path |
| 9. Cross-app correlation leak | Capability behaviour phase | `c:execute/2` arity is strictly 2; PreviewReport struct has closed key list; grep for `correlat`, `peer_` returns nothing in new code |
| 10. Multi-tenant assumptions | Schema phase + ongoing | Grep for `tenant`, `organization`, `org_id` returns nothing in new v1.1 code |
| 11. Telemetry contract drift | Telemetry contract phase (before any capability) | `verify.telemetry_contract` mix task asserts docs match emitted events |
| 12. Misleading demo seed | Demo-seed phase | Demo CI lane exercises Preview-without-Confirm, short-circuit, and successful Confirm paths |
| 13. Application-env registry | First phase introducing `Parapet.Recovery` | 100 async tests register distinct capabilities without bleeding |
| 14. Documentation gap | Docs-and-adoption phase (last) | Prebuilt playbook docs exist; `mix parapet.gen.recovery` works; doctor check reports adoption signal; v1.1 LEARNINGS file shipped |

## Sources

- `.planning/PROJECT.md` — v1.1 milestone scope, decisions table, out-of-scope list (HIGH confidence)
- `.planning/threads/actionable-recovery-design.md` — capability behaviour shape candidates, Preview/Confirm UX, prebuilts list, audit contract, demo seed gap (HIGH)
- `.planning/threads/slo-state-off-application-env.md` — the registry anti-pattern parapet is already paying for; the fix shape (ETS + GenServer) (HIGH)
- `.planning/phases/22-release-readiness-1-0-cut/22-LEARNINGS.md` — LEARN-22-C (LEARNINGS as default), LEARN-22-E (v1.0 froze detection; v1.1 is execute) (HIGH)
- `docs/operator-ui.md` — Phase 7 Preview-First Recovery design draft (Guidance/Preview/Confirm); evidence-first design principles; bounded controls posture (HIGH)
- `docs/stability.md` — stability tiers, telemetry freeze, breaking-vs-additive matrix, deprecation cycle (HIGH)
- `lib/parapet/operator/action_payload.ex` — existing `ActionPayload` schema and validation; `:execute_mitigation` action type and idempotency-key requirement (HIGH, direct code)
- `lib/parapet/automation/claim_service.ex` — claim acquisition transaction, state gate, suppression gate, custom gate, return shapes (HIGH, direct code)
- `lib/parapet/automation/circuit_breaker.ex` — flap protection scoped to `system:` execution; counts via `ToolAudit` (HIGH, direct code)
- `lib/parapet/automation/executor.ex` — Oban worker convention, `:system:automation:executor` URN, `unique:` keys, short-circuit recording (HIGH, direct code)
- `lib/parapet/runbook.ex` — Runbook DSL with existing `:capability`, `:requires_preview`, `:warning`, `:guidance` opts (HIGH, direct code)
- `lib/parapet/spine/{action_claim,action_item,timeline_entry,tool_audit,incident}.ex` — existing schemas with kind vocabularies, state transitions, audit shape (HIGH, direct code)
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned beats remote magic; operator UX is product scope; behavioural seams over magical DSLs (HIGH)
- `prompts/sre-best-practices-solo-founder-deep-research.md` — operator-in-the-loop, AI Level 1/2/3 distinction, audit ≠ logs, "narrow audited human-approved" rule for production mutations (HIGH)
- `.planning/research/PITFALLS.md` (v0.10 baseline) — adopter-funnel, telemetry-as-API, redaction patterns, demo-seed traps; v1.1 PITFALLS inherits the discipline (MEDIUM — different milestone scope, but the discipline patterns transfer)
- `.planning/research/V1-STABILITY-FREEZE.md`, `V1-RELEASE-READINESS.md`, `V1-DEMO-APP.md`, `V1-SLO-WIZARD-BUNDLES.md` — v1.0 freeze posture, demo CI contract, Igniter task patterns to mirror (MEDIUM-HIGH)

---
*Pitfalls research for: v1.1 Actionable Recovery — adding executable runbook actions to the parapet operator UI*
*Researched: 2026-05-27*
