# Feature Research — v1.1 Actionable Recovery

**Domain:** SRE operator UI — executable runbook recovery actions (Guidance → Preview → Confirm) on top of an existing durable-evidence incident spine
**Researched:** 2026-05-27
**Confidence:** HIGH

> Scope discipline: this milestone adds the *executable recovery loop* to the existing parapet operator UI. The incident model, runbook DSL, ActionPayload envelope, ClaimService, TimelineEntry, ToolAudit, and circuit breakers already ship in v1.0. None of those features are re-derived here. The feature surface below is strictly what users do when they take a recovery action.

> Prior-art evidence: `Parapet.Capabilities` (lib/parapet/capabilities.ex), `Parapet.Operator.preview_runbook_step/3`, `Parapet.Operator.confirm_runbook_step/4`, `Parapet.Operator.WorkbenchContract` step-state derivation (`:guidance | :previewable | :executable | :executed`), `recovery_preview` / `recovery_confirmed` / `mitigation_executed` TimelineEntry types, and the seven `priv/templates/parapet.gen.runbooks/*.eex` templates collectively prove that the Phase 7 design exists in code but is not wired end-to-end (the capability allowlist is exactly 3 ids, the demo seed has zero capability-backed steps, and the Preview/Confirm UX is not yet rendered in the generated LiveView).

## Feature Landscape

### Table Stakes (Users Expect These)

Features any SRE operator UI shipping executable mitigations is expected to provide. Missing these makes parapet look like a half-built tool relative to PagerDuty Runbook Automation, Rundeck, or hand-rolled internal admin panels.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Named capability registration from the host app** | Operator never sees a recovery surface that runs arbitrary code; every action must be a named, host-declared capability with explicit args. PagerDuty Automation Actions, Rundeck Jobs, kubectl plugins, and Backstage scaffolder actions all share this shape. | LOW | Extend the existing `Parapet.Capabilities` allowlist (currently 3 ids: `:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check`) to cover the v1.1 playbook set, and ship a `Parapet.Recovery` behaviour (mirrors `Parapet.Integration`) so host modules implement `name/0`, `preview/2`, `execute/2`. |
| **Preview before any mutation** | A Confirm button without a Preview is a footgun. Operators expect to see "this will affect N objects" before committing. Already a documented principle (D-21 in `docs/operator-ui.md`). | LOW | The plumbing exists (`compute_preview/3`, 5-minute expiry, preview_token). Only the LiveView render needs wiring. |
| **Confirm button gated by a fresh preview** | Stale previews must be rejected — the state of the world can change between Preview and Confirm. | LOW | Already implemented: `find_recent_preview/3` rejects expired tokens with `:stale_preview`. |
| **Idempotency key on every confirm** | Operators retry network blips. Without an idempotency key, "did my click work?" becomes a footgun. | LOW | `Parapet.Operator.ActionPayload` already requires `:idempotency_key` for `:execute_mitigation` actions via `validate_mitigation_idempotency/1`. v1.1 should mint this client-side in the LiveView form. |
| **Audit row written for both Preview and Confirm** | Operators expect a tamper-evident trail of *both* what they considered and what they did. Standard in PagerDuty Runbook Automation (Automation Actions Log tab) and Rundeck (per-execution audit). | LOW | `Evidence.run_operator_command/1` already writes a `ToolAudit` row from `build_audit/2`. v1.1 should preserve this dual-write for Preview (`operator_preview_recovery`) and Confirm (`operator_confirm_recovery`). |
| **TimelineEntry of `type: :recovery_confirmed` (or `:recovery_action`)** | Operators inside the workbench expect actions to appear *in-line in the chronology* — not in a separate audit panel. This is the whole point of the canonical-timeline-is-truth posture (`docs/operator-ui.md` Phase 4). | LOW | Already implemented; v1.1 just consumes it via the generated LiveView. Decision needed: keep `"recovery_confirmed"` or rename to `"recovery_action"` for symmetry with the thread; **recommendation: keep `"recovery_confirmed"`** since it already exists and the operator-facing label can differ from the wire type. |
| **Resolved-capability + unwired-capability differentiation** | If a step references a capability the host hasn't registered, the UI must say so plainly ("Not wired") rather than rendering a dead button. | LOW | `confirm_runbook_step/4` already returns `{:error, :capability_unwired}`; the LiveView render needs to display "Not wired by host app" guidance instead of a Preview button. |
| **Visible "blast radius" string in the preview** | Operators expect language like *"Will re-enqueue 47 jobs from the `default` queue. No data destruction."* — not just a target_ref count. | LOW | The preview payload already carries `preconditions`, `warnings`, `idempotency_caveats`, and `count`. v1.1 adds a `summary` string that the capability returns and the UI renders verbatim. |
| **Operator identity attached to every action** | Confirm presses must be attributable to a real user, not "operator". Reused from the existing authenticated mount the host owns. | LOW | The existing operator UI mounts under the host's `:require_authenticated_user` pipeline; v1.1 reads the current user from socket assigns into the ActionPayload `:actor`. |
| **Reason/comment field on Confirm** | Standard in PagerDuty (incident notes), Rundeck (run options). Gives the future-reader of the timeline a "why now". | LOW | `ActionPayload.changeset/2` already requires `:reason`. v1.1 surfaces it as a textarea on the Confirm modal. |
| **Confirm-disabled state when preview returned errors** | If `preview/2` returns `{:error, _}` (e.g., "no dead-lettered items found"), the UI must not let the operator press Confirm. | LOW | `preview_runbook_step/3` returns `{:error, reason}` propagated up; LiveView gates the Confirm button on `{:ok, _}`. |
| **Failure surfacing in the timeline** | If `capability.execute.(...)` returns `{:error, reason}`, that error becomes a timeline entry. Operators must see failed attempts. | LOW | Currently `confirm_runbook_step/4` returns the error but doesn't append a `recovery_failed` entry. **v1.1 gap: must emit `type: "recovery_failed"` on capability execution error** so the chronology stays truthful. |
| **At-least-one demo-seeded executable recovery** | New adopters who run `iex -S mix phx.server` in `examples/demo_app/` must see the loop work end-to-end with zero extra setup. | LOW | Today's seed has 3 incidents, all guidance-only. v1.1 adds a 4th seeded incident with a capability-backed step + a demo host-app capability implementation that runs against in-memory state. |

### Differentiators (Competitive Advantage)

These are the features that make parapet's recovery surface *not* a worse version of PagerDuty Runbook Automation or Rundeck. They derive directly from parapet's engineering DNA (host-owned, embedded, evidence-spine-coherent) and the existing parapet-only primitives the thread names.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Recovery actions wrapped in `Parapet.Operator.ActionPayload` automatically inherit circuit-breaker + multi-node claim** | PagerDuty/Rundeck require operators to configure rate limits per-job and serialize via external coordination. Parapet ships this for free because every Confirm goes through `Evidence.run_operator_command/1` → ClaimService → ToolAudit-backed CircuitBreaker. The same primitive that v0.8 used for *system-executed* mitigation is reused for *operator-confirmed* mitigation. | LOW | Plumbing already exists. The differentiator is that the host app *cannot* accidentally execute a recovery action that skips circuit-breaker or claim semantics — those checks run in `Evidence.run_operator_command/1` regardless of whether the trigger is operator-Confirm, escalation policy, or auto_execute runbook. |
| **The recovery action *is* a TimelineEntry — the audit log and the operator workbench are the same view** | PagerDuty surfaces automation runs in a sidebar log. Rundeck surfaces them in `/project/.../executions`. Both require operators to context-switch to investigate "did the action work?" Parapet's recovery appears inline in the canonical chronology immediately under the triage block. Same view as the alert, the escalation, and the deploy marker. | LOW | This falls out of writing `type: "recovery_confirmed"` to the timeline. The differentiator is the workbench's *commitment* to one chronology rather than a sidebar. |
| **Capability ID allowlist enforced at registration time** | Compare to Rundeck where any Job ID can be invoked from any context — ACLs are bolt-on. Parapet's `register_recovery/2` rejects unknown ids at registration (raises `ArgumentError`). Host apps cannot register an arbitrary "delete_all_users" capability and expose it through the runbook DSL. | LOW | Already enforced: `@valid_capabilities` list in `Parapet.Capabilities`. v1.1 extends the allowlist by ~2 ids; the discipline holds. |
| **Preview output is structured, not free-text** | PagerDuty/Rundeck show stdout from job dry-runs. Parapet's preview is a typed map: `count`, `target_refs`, `preconditions`, `warnings`, `idempotency_caveats`, `summary`. An AI investigation copilot (the MCP read-only server, v0.5) can reason over it without parsing prose. | MEDIUM | Already implemented; v1.1 standardizes the shape across all 6 playbooks. Documenting this contract on `Parapet.Recovery` behaviour is the v1.1 work. |
| **Preview expiry is short and explicit (5 min)** | A 30-minute-old preview is a security/safety hazard — state has drifted. PagerDuty doesn't enforce this; Rundeck doesn't either. Parapet does, via `expires_at` on the preview token. | LOW | Already implemented (`DateTime.add(300, :second)`); v1.1 surfaces the countdown in the UI so operators see "Preview expires in 2:47". |
| **The capability registry is also where adapter integrations register their recovery hooks** | The same `Parapet.Capabilities` registry that backs the host-app behaviour can hold adapter-provided recoveries (e.g., a future Rulestead adapter registering `:revert_feature_flag`). This is the "integration sets up its own recovery surface" pattern, mirroring how `Parapet.Integration.setup/0` already works for telemetry attach. | MEDIUM | The mechanism exists; v1.1 doesn't need to ship an adapter-provided recovery. It needs to *document* that the allowlist accommodates both host-app and adapter-registered capabilities so v1.4+ adapter recovery can land without breaking the contract. |
| **Recovery actions emit their own telemetry events** | `[:parapet, :operator, :recovery_action, :start | :stop | :exception]` follows the existing `:telemetry.span/3` convention used elsewhere. Adopters' existing Prometheus stacks gain recovery-action visibility for free; teams that monitor SRE-of-SRE can see whether the workbench is actually being used. | LOW | New events; documented in the v1.1 telemetry-as-API contract. |
| **Demo-seed proves the loop in one keystroke** | Most SRE products' demos require an account, a tour, and seeded customer data. Parapet's demo loop is `iex -S mix phx.server` → click a seeded incident → click Preview → click Confirm → see the timeline update. End-to-end, locally, in <60 seconds. | LOW | Adds one capability-backed incident + a `DemoApp.Recovery.RetryDeadLetter` module that wires the capability against an in-memory list. The demo *is* the smoke test for the wedge. |

### Anti-Features (Commonly Requested, Often Problematic)

The thread explicitly puts these out of scope, but they will be requested. Documenting *why* they're declined makes future scope creep cheap to reject.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Autonomous remediation (no-human-in-the-loop execution from the UI)** | "If we can preview-and-confirm, why can't we just confirm automatically when the preview looks safe?" Big-platform marketing trains operators to expect this. | The whole product posture is *evidence-first, operator-in-the-loop*. Autonomous execution invalidates the audit narrative ("who decided?"), creates a worse failure mode for retry storms ("the automation retried the storm"), and turns parapet into the autopilot-AI category it explicitly rejects (per `.planning/PROJECT.md` Out of Scope: "Unbounded autonomous incident-response agent"). The v0.8 `auto_execute_on:` runbook surface is the *only* sanctioned autonomous path, and it's bounded by circuit-breakers, alert-name match, and `:system` URN identity. | Keep `auto_execute_on:` as the narrow sanctioned mechanism. Do not add a "confirm-on-preview" or "trust me" mode to the operator UI. |
| **Cross-app / multi-tenant action scoping** | "Our parapet instance manages 50 customer Phoenix apps; can the operator UI execute a recovery against a *specific* customer's app?" | Multi-tenant capability scoping is a control-plane feature, not a reliability-substrate feature. It explodes the trust model (one operator can break across-tenant), the audit model (which tenant's audit trail?), and the failure model (claim-service must become tenant-aware). It's also explicitly Out of Scope per `.planning/PROJECT.md` Out of Scope: "hosted observability SaaS". | Recovery actions execute against the single host application that mounts the operator UI. Multi-app coordination is a v1.4+ cross-boundary journey concern, not a v1.1 recovery-action concern. |
| **Approval workflows (multi-step approve-then-execute chains)** | "Our compliance team requires a second engineer to approve every prod action." | Adds a second principal to every Confirm and turns the operator UI into a workflow engine. Parapet is not Sox-compliance scope. Hosts that need this can wrap `Parapet.Operator.confirm_runbook_step/4` in their own approval surface and call it after their approval succeeds — the underlying primitive doesn't need to know. | Document the integration recipe ("intercept Confirm in your LiveView, post to your own approval queue, only call `confirm_runbook_step/4` on approval") rather than building it. |
| **Custom action UIs beyond Guidance → Preview → Confirm** | "Our retry action needs three sliders for batch size, delay, and concurrency." | Each custom UI multiplies the operator surface, breaks the canonical chronology presentation, and erodes the safety claim ("operators see the same three-state model everywhere"). | Recovery action parameters live in the capability's `preview/2` output as structured data. If a capability needs configurable batch size, it's two `step(:retry_small, ...)` + `step(:retry_large, ...)` definitions in the runbook, not a custom UI control. |
| **Arbitrary shell-job execution (the Rundeck pattern)** | "Just give us a button that runs a Mix task." | Turns the operator UI into a remote shell. Once operators have one shell button, every future "fix" becomes a shell snippet rather than a named capability, and the capability allowlist degrades into theater. | Capabilities must be named in `Parapet.Capabilities`'s allowlist. If a host app wants ad-hoc Mix task execution, they can build it outside the parapet operator UI; parapet declines that surface intentionally. |
| **In-UI rollback of the recovery action itself ("undo")** | "What if the operator confirms a recovery that makes things worse — can they undo it?" | Undo is a property of the underlying capability, not the operator UI. A capability like `:requeue_dead_letter` is reversible by design (move items back); a capability like `:revert_feature_flag` is reversible by toggling again; a capability like `:disable_metric_label` is reversible by re-enabling. Building a generic "undo" surface implies parapet knows the inverse semantics of every host capability — it doesn't. | Capabilities document their reversibility in `preview/2`'s `idempotency_caveats` string. Operators read that before confirming. Reversal, when needed, is a second named capability the operator runs explicitly. |
| **Bulk recovery ("retry all 14 incidents at once")** | "Our workbench has 14 stalled-async incidents from the same outage; I want to fix them in one click." | Bulk amplifies blast radius and undermines the per-incident preview semantic. The existing exact-item recovery pattern (D-22 in `docs/operator-ui.md` Phase 6) is correct. | Surface the *correlation* (same `correlation_key`) so operators can navigate incidents quickly, but each Confirm is per-incident. |

## The Six Playbooks — "Good Recovery Behavior" Per Category

These are the 4–6 playbooks the v1.1 thread names. The thread already cuts each correctly; what follows is the specification for "good behavior" tight enough to write requirements from.

> Two of the six (Retry storm, Suppression drift) stay **guidance-only** in v1.1 — they have no allowlisted capability because the obvious mitigations make the failure worse. This is a deliberate carry-over from a v0.10 decision logged in `.planning/PROJECT.md` Key Decisions: "Guidance-only runbooks where no allowlisted capability fits". The remaining four ship with capabilities.

### 1. Retry Storm (guidance-only)

**Failure mode:** A downstream provider is failing; the host's retry logic is amplifying load and prolonging the outage.

**Why no Confirm-able mitigation:** Every obvious automated action (cap retries, clear in-flight retries, drain the retry queue) *worsens* the symptom by either dropping legitimate work or removing the back-pressure the provider needs. The right action is human judgment on the provider's status.

**Good runbook step set:**
1. `check_provider_status` — guidance; links to provider status page from the triage block
2. `inspect_retry_metrics` — guidance; links to Grafana panel for `oban_job_retry_total{queue}`
3. `coordinate_with_provider` — guidance; links to the runbook's contact channel
4. `decide_circuit_break` — guidance with `warning:` "Manual circuit-break decision: the host's retry behavior should not be silenced by parapet."

**Differentiator:** parapet does not pretend to fix this. PagerDuty Runbook Automation will happily wire a "cap retries" job. Parapet's posture is that some failure classes are worse-with-automation. Document this explicitly.

### 2. Suppression Drift (guidance-only)

**Failure mode:** A delivery provider (Mailglass, Chimeway) has suppressed legitimate recipients due to a misclassified bounce, and the suppression list has drifted from operator intent.

**Why no Confirm-able mitigation:** Auto-clearing suppression invalidates the provider's reputation protections and can re-suppress immediately. Clearing the wrong recipient creates a deliverability incident.

**Good runbook step set:**
1. `inspect_suppression_evidence` — guidance; surfaces the bounce reason + suppression timestamp from the existing async/delivery triage block
2. `confirm_legitimate_recipient` — guidance; "operator must verify with the recipient via an out-of-band channel"
3. `clear_per_recipient` — guidance with `warning:` "Suppression clearing is a per-recipient provider operation; bulk-clearing is not supported on purpose. Use the provider console for the specific verified recipient."

**Differentiator:** parapet's `Parapet.Integration` adapters for Mailglass/Chimeway *could* expose a `:clear_suppression` capability, and v1.4+ may. v1.1 keeps it guidance-only and documents the upgrade path.

### 3. Stalled Async — capability `:retry_async_item` (already in allowlist)

**Failure mode:** An Oban job is past its lease deadline; the worker died, or the job is genuinely stuck.

**Good preview output:**
- `count`: how many stalled items the capability would retry (typically 1, since exact-item recovery is preferred)
- `target_refs`: `[{kind: :async_item, external_id: "oban_job:42"}]`
- `preconditions`: `["Job 42 has exceeded its 10-minute lease", "No newer instance of this job is running"]`
- `warnings`: `["Side effects from the original attempt are not automatically reversed; verify the job is idempotent"]`
- `idempotency_caveats`: `"Standard Oban idempotency applies; same `correlation_id` argument is reused."`
- `summary`: `"Will retry Oban job 42 (`MyApp.Workers.SendInvoice`) past its 10-minute lease."`

**Good execute behavior:** Re-enqueue the specific job via the host-provided `:retry_async_item` capability. Capability uses Oban's `Oban.retry_job/1` or equivalent. Returns `{:ok, %{retried: 1}}`.

**Anti-behavior:** Do not "retry all stalled" in bulk. Exact-item is the contract.

### 4. Dead-Letter Drain — capability `:requeue_dead_letter` (already in allowlist)

**Failure mode:** An Oban dead-letter queue has accumulated items from a structural failure that's now resolved (deploy fix, dependency upgrade, etc.).

**Good preview output:**
- `count`: how many dead-lettered items match the incident's `correlation_key`
- `target_refs`: list of specific dead-lettered job ids — bounded (e.g., cap at 50 with a `"See N more in DLQ"` overflow indicator)
- `preconditions`: `["DLQ has been stable for >5 minutes (no new arrivals)", "Underlying error class for these items is no longer present in recent successful runs"]`
- `warnings`: `["Requeued items will be re-processed from the start; partial side effects from the original attempt are not reversed"]` (copied from the existing `dead_letter.ex.eex` template, which is right)
- `summary`: `"Will requeue 14 items from the `payments_dlq` queue back to `payments`. Items range in age from 2h to 48h."`

**Good execute behavior:** Bounded per-item requeue, with circuit-breaker honoring `ToolAudit` history (the v0.8 circuit-breaker reads `ToolAudit` rows for flap-loop detection — this applies for free).

**Anti-behavior:** Do not requeue items still actively failing in the source queue. The preview's preconditions must enforce this.

### 5. Deploy-Tied Incident — capability `:revert_feature_flag` (NEW in v1.1 allowlist)

**Failure mode:** An incident's `correlated_change` field (already derived by `WorkbenchContract.derive/3` from `change_marker` timeline entries) points at a specific feature-flag flip; reverting the flag restores user-visible behavior.

**Good preview output:**
- `target_refs`: `[{kind: :feature_flag, external_id: "new_checkout", from: true, to: false}]`
- `preconditions`: `["Flag `new_checkout` was flipped 7m before incident open", "Flag has not been re-flipped since"]`
- `warnings`: `["Revert affects all users currently in the `new_checkout=true` cohort. In-flight checkouts may see inconsistent behavior."]`
- `summary`: `"Will revert feature flag `new_checkout` from `true` (set at 14:03) back to `false`."`

**Good execute behavior:** Calls into the host's `Parapet.Integrations.Rulestead`-equivalent path if Rulestead is configured, else into a host-provided callback. The capability ships with v1.1; the *Rulestead adapter binding* is v1.4+ (the v1.1 host registers the capability with their own implementation).

**Anti-behavior:** Do not revert all flags flipped in the same deploy. One flag, one revert, one Confirm. Operators can run the capability twice if multiple flags need reverting.

### 6. Cardinality Blowout — capability `:disable_metric_label` (NEW in v1.1 allowlist)

**Failure mode:** A Prometheus metric has acquired a high-cardinality label (e.g., `user_id` slipped through the cardinality validator); the TSDB is at risk and the alert is firing on parapet's own cardinality-monitor.

**Good preview output:**
- `target_refs`: `[{kind: :metric_label, metric: "checkout_failed_total", label: "user_id"}]`
- `preconditions`: `["`mix parapet.doctor cardinality` static analysis flagged this label", "Cardinality validator would reject this label at the v0.9 compile-time gate"]`
- `warnings`: `["Disabling this label drops historical TSDB data for it; cannot be restored without re-emitting metrics."]`
- `summary`: `"Will mark label `user_id` on metric `checkout_failed_total` as filtered. Future metric emissions will strip this label."`

**Good execute behavior:** Writes a host-app-managed filter rule (the host stores it; parapet doesn't run a metrics gateway). The capability ships with v1.1; the integration with the v0.9 cardinality validator is a stretch goal.

**Anti-behavior:** Do not auto-disable based on cardinality alerts. The operator confirms.

## Five Feature Categories (For Roadmap Phasing)

The roadmap will likely phase v1.1 around these. Each category is independent enough to be a phase boundary; they're listed in suggested execution order.

| # | Category | What's in it | Depends on |
|---|----------|--------------|------------|
| **1** | **Capability Registration API** | `Parapet.Recovery` behaviour with `name/0`, `target_kind/0`, `preview/2`, `execute/2`; extension of `Parapet.Capabilities` allowlist by 2 ids (`:revert_feature_flag`, `:disable_metric_label`); compile-time defensive guidance ("missing `@behaviour Parapet.Recovery` will warn") mirroring `Parapet.Integration`'s pattern | `Parapet.Capabilities` (exists), `Parapet.Integration` precedent (exists) |
| **2** | **Preview/Confirm UX in generated LiveView** | Three-state step rendering (`:guidance | :previewable | :executable | :executed`) → already in `WorkbenchContract.derive/3`; **new**: render the Preview output struct, the Confirm modal with reason textarea, the countdown to preview expiry, the unwired-capability "Not wired" state, the failure-surfacing `recovery_failed` timeline entry | Category 1, existing `WorkbenchContract`, existing `Parapet.Operator.preview_runbook_step/3` + `confirm_runbook_step/4` |
| **3** | **The Six Playbooks** | Update the seven existing runbook templates (`priv/templates/parapet.gen.runbooks/*.eex`) to use the v1.1 capability ids; document the guidance-only-by-design choice for Retry Storm + Suppression Drift; add the two new capability templates for Deploy-Tied + Cardinality Blowout | Category 1 (capability ids exist), Category 2 (UI renders them) |
| **4** | **Audit Propagation & Telemetry-as-API** | Document `[:parapet, :operator, :recovery_action, :start | :stop | :exception]` telemetry contract; add `type: "recovery_failed"` timeline entry on capability execution error; confirm `operator_preview_recovery` / `operator_confirm_recovery` ToolAudit rows; document the contract under `docs/stability.md` | Category 1, 2, 3 — pulls them together as a public surface |
| **5** | **Demo Seed + Adopter Guide** | Add a 4th seeded incident in `examples/demo_app/priv/repo/seeds.exs` with a `:requeue_dead_letter` capability-backed step; add `DemoApp.Recovery.RequeueDeadLetter` host module that wires the capability against in-memory state; add `docs/recovery-actions.md` (the v1.1 equivalent of v0.10's `docs/slo-authoring.md`) | All prior categories — the demo *is* the smoke test |

## Feature Dependencies

```
[1. Capability Registration API]
    └──requires──> [Parapet.Capabilities allowlist extension]
    └──requires──> [Parapet.Recovery behaviour]

[2. Preview/Confirm UX]
    └──requires──> [1. Capability Registration API]
    └──requires──> [WorkbenchContract step-state derivation]  (already exists)

[3. The Six Playbooks]
    └──requires──> [1. Capability Registration API]
    └──requires──> [2. Preview/Confirm UX]   (templates need a render target)
    └──enhances──> [existing v0.7/v0.8 runbook templates]

[4. Audit Propagation & Telemetry-as-API]
    └──enhances──> [1, 2, 3]
    └──requires──> [docs/stability.md surface]   (already exists)

[5. Demo Seed + Adopter Guide]
    └──requires──> [1, 2, 3, 4]   (demo is the smoke test of all of them)

[Retry Storm playbook] ──conflicts──> [autonomous "cap retries" execution]   (anti-pattern, decline)
[Suppression Drift playbook] ──conflicts──> [bulk "clear all suppressions"]   (anti-pattern, decline)
[Recovery action] ──enhances──> [v0.8 escalation policy]  (recovery is the surface escalation paths into)
```

### Dependency Notes

- **Category 1 must land before Category 2:** The LiveView render needs the `Parapet.Recovery` behaviour shape stable so it knows what `preview/2` returns. Otherwise UI work churns.
- **Category 3 depends on both 1 and 2:** A playbook template is useless if either the capability id isn't allowlisted (1) or the UI can't render its Preview output (2).
- **Category 5 (demo seed) is the v1.1 smoke test:** It's the closest thing to an integration test for the whole loop. If the demo doesn't work end-to-end, v1.1 isn't shipped.
- **Categories 1 and 4 form the public-surface contract:** Both need to land under `docs/stability.md` as `experimental` first (mirroring `Parapet.Operator.ActionPayload`'s `experimental` annotation), then graduate to `stable` only when there's adopter feedback.

## MVP Definition

### Launch With (v1.1)

Minimum viable recovery loop — what's needed for the wedge to land.

- [ ] **`Parapet.Recovery` behaviour** — single behaviour module mirroring `Parapet.Integration`'s shape; uses `@behaviour` for compile-time wiring; documented `experimental` in v1.1
- [ ] **`Parapet.Capabilities` allowlist extension** — add `:revert_feature_flag` and `:disable_metric_label` to the existing 3 ids
- [ ] **`recovery_failed` TimelineEntry type** — close the failure-surfacing gap in `confirm_runbook_step/4`
- [ ] **Generated LiveView renders Preview output** — `target_refs`, `summary`, `preconditions`, `warnings`, `idempotency_caveats`, expiry countdown
- [ ] **Generated LiveView renders Confirm modal** — reason textarea, idempotency_key minted client-side, capability label rendered prominently, "Not wired" state for unwired capabilities
- [ ] **Four capability-backed runbook templates updated** — Stalled Async, Dead-Letter Drain, Deploy-Tied Incident, Cardinality Blowout
- [ ] **Two guidance-only runbook templates documented** — Retry Storm + Suppression Drift, with the *reason* they stay guidance-only in `warning:` blocks
- [ ] **Demo seed adds a Preview-able + Confirm-able incident** — using `:requeue_dead_letter` against in-memory `DemoApp.Recovery.RequeueDeadLetter`
- [ ] **`docs/recovery-actions.md`** — adopter guide: how to declare a capability, what `preview/2` returns, what `execute/2` returns, how the audit appears, what `recovery_failed` means
- [ ] **Telemetry contract documented** — `[:parapet, :operator, :recovery_action, ...]` events in `docs/stability.md`
- [ ] **Doctor check for unwired capabilities** — `mix parapet.doctor` warns if a generated runbook references a capability id not registered in `Parapet.Capabilities`

### Add After Validation (v1.2+)

- [ ] **Adapter-provided capabilities** — Rulestead adapter registering `:revert_feature_flag` automatically; same pattern for future Mailglass `:clear_suppression`
- [ ] **Preview output rendered in MCP server** — the read-only MCP server can surface "what would this preview look like?" to AI investigation copilots without executing
- [ ] **Recovery-action telemetry → Grafana** — generated dashboard panel for "operator recovery actions per day"
- [ ] **Per-capability cooldown rules** — capabilities can declare `cooldown_seconds: 300` to layer on top of the existing circuit-breaker for predictable rate limits
- [ ] **Per-incident recovery history view** — sidebar showing every Preview + Confirm + recovery_failed for the incident, alongside the canonical chronology

### Future Consideration (v1.3+)

- [ ] **Cross-incident recovery correlation** — "this same capability was confirmed for 4 other incidents with `correlation_key: x` in the last hour" surfaced in the Preview
- [ ] **Recovery action templates in a starter pack** — `Parapet.Recovery.StarterPack.WebSaaS` mirroring `Parapet.SLO.StarterPack.WebSaaS` (v0.10) — registers a default set of capabilities the host opts into wholesale
- [ ] **Capability composition** — a runbook step that confirms two capabilities in a single Confirm (with explicit ordering). **Rejected for v1.1** as it complicates the preview semantics; keep flat for now.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| `Parapet.Recovery` behaviour | HIGH | LOW | P1 |
| Generated LiveView Preview/Confirm render | HIGH | MEDIUM | P1 |
| Four capability-backed playbooks (Stalled Async, DLQ, Flag Revert, Cardinality) | HIGH | MEDIUM | P1 |
| Demo-seeded executable recovery | HIGH | LOW | P1 |
| `recovery_failed` timeline type + telemetry-as-API contract | MEDIUM | LOW | P1 |
| `docs/recovery-actions.md` adopter guide | MEDIUM | LOW | P1 |
| Doctor check for unwired capabilities | MEDIUM | LOW | P1 |
| Two guidance-only playbooks (Retry Storm, Suppression Drift) updated with refreshed warnings | MEDIUM | LOW | P1 |
| Adapter-provided capability binding (Rulestead → `:revert_feature_flag`) | MEDIUM | MEDIUM | P2 |
| Per-capability cooldown rules | LOW | LOW | P2 |
| Per-incident recovery history sidebar | LOW | MEDIUM | P3 |
| Capability composition | LOW | HIGH | P3 (rejected for v1.1) |
| Bulk recovery / multi-incident action | NEGATIVE | HIGH | Declined (anti-feature) |
| Autonomous (no-Confirm) execution | NEGATIVE | LOW | Declined (anti-feature) |

**Priority key:**
- P1: Must have for v1.1
- P2: Should have, add in v1.2
- P3: Nice to have, future consideration
- Declined: Explicit non-feature, documented as such

## Competitor Feature Analysis

| Feature | PagerDuty Runbook Automation | Rundeck | Hand-rolled internal admin | parapet v1.1 approach |
|---------|------------------------------|---------|----------------------------|----------------------|
| **Named recovery actions** | "Automation Actions" — invocable from incidents; loosely scoped via tags | "Jobs" — every job is a YAML; ACL is bolt-on, not capability-enforced | Free-form Phoenix routes / Mix tasks | `Parapet.Capabilities` allowlist enforced at registration; host declares behaviour-backed modules |
| **Preview before execute** | No built-in preview; dry-run is per-job convention | No built-in preview; `--dry-run` flag if the underlying script supports it | Rare; usually a Confirm dialog at best | First-class: separate `preview/2` + `execute/2` callbacks with structured Preview output |
| **Audit log** | "Automation Actions Log" tab on incident detail; separate sidebar view | `/project/.../executions` — separate view from incident UI | Often missing or in app logs | `ToolAudit` row + `TimelineEntry` inline in the canonical chronology; same view as the incident |
| **Idempotency** | Per-job, optional | Per-job, optional | Usually missing | Required for `:execute_mitigation` ActionPayload (already enforced) |
| **Multi-node safety** | SaaS-managed; opaque | Requires custom Rundeck cluster config | Usually missing | DB-backed `ClaimService` (v0.9); same primitive used by escalation policies |
| **Circuit-breaker / flap protection** | Tag-based rate limiting; opt-in | None built-in | Usually missing | Ecto-backed circuit-breaker (v0.8) reads `ToolAudit` history; applies free to operator-confirmed actions |
| **Host-owned vs hosted** | Hosted SaaS (with self-hosted Process Automation option) | Self-hosted; runs as a Java service | Host-owned | Embedded as a library in the host Phoenix app; no separate process |
| **Capability registration surface** | Web UI + API | YAML files + Web UI | Code | Behaviour module in the host app's code |
| **Anti-feature: shell job execution** | Yes (the main use case) | Yes (the main use case) | Yes | Explicitly declined; capabilities are named, not arbitrary |

## What Makes parapet's Recovery Distinctive

Synthesized one-liner the roadmap can quote:

> **parapet's recovery surface is the only one where (a) every action is a named capability the host registers via a behaviour module, (b) every Confirm flows through the same `ActionPayload` → `ClaimService` → circuit-breaker pipeline that v0.8 already proved for escalation policies, and (c) the audit trail *is* the operator workbench — recovery actions appear inline in the canonical chronology, not in a sidebar log.**

The three primitives this builds on — `Parapet.Operator.ActionPayload`, `Parapet.Spine.TimelineEntry`, `Parapet.Spine.ToolAudit` — are already shipped, already documented, and already covered by the multi-node concurrency tests. v1.1 is the integration phase that turns them into a user-visible loop, not new infrastructure.

## Sources

### Internal (HIGH confidence)
- `.planning/PROJECT.md` — milestone scope, anti-feature precedents, key decisions
- `.planning/threads/actionable-recovery-design.md` — thread's open questions verbatim
- `.planning/research/JTBD-MAP.md` — "common recovery depth" as #1 gap
- `docs/operator-ui.md` — Phase 7 Preview-First Recovery section, D-20/D-21 safety principles
- `docs/adopter-flows.md` — JTBD #6 "trigger safe, bounded mitigation"
- `lib/parapet/operator/action_payload.ex` — existing ActionPayload contract
- `lib/parapet/operator/workbench_contract.ex` — `derive_runbook_steps/3` step-state machine, active_preview projection
- `lib/parapet/operator.ex` — `preview_runbook_step/3`, `confirm_runbook_step/4`, `find_recent_preview/3` (5-min expiry already enforced)
- `lib/parapet/capabilities.ex` — existing allowlist of 3 capability ids
- `lib/parapet/runbook.ex` — DSL with `:capability`, `:requires_preview`, `:preview_only` opts already wired
- `lib/parapet/integration.ex` — behaviour pattern v1.1 should mirror
- `priv/templates/parapet.gen.runbooks/` — seven existing templates (dead_letter, retry_storm, suppression_drift, stalled_executor, callback_delay, provider_outage, partial_backlog_drain)
- `examples/demo_app/priv/repo/seeds.exs` — confirms zero capability-backed seeded incidents today

### Domain research (HIGH confidence)
- `prompts/sre-best-practices-solo-founder-deep-research.md` — operator-in-the-loop posture, three AI levels (read-only, pre-approved safe actions, narrow autonomous), Google SRE alerting checklist
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — "host-owned beats remote magic", "operator UX is a product surface", "telemetry as API"

### Competitor analysis (MEDIUM confidence — WebSearch-only, verified against vendor docs)
- [Runbook Automation | PagerDuty](https://www.pagerduty.com/platform/automation/runbook/)
- [PagerDuty Automation Actions](https://support.pagerduty.com/main/docs/automation-actions)
- [Audit Trail Log — Rundeck](https://docs.rundeck.com/docs/administration/security/audit-trail.html)
- [ACL Policy GUI — Rundeck](https://docs.rundeck.com/docs/administration/security/acl-policy-editor.html)

---
*Feature research for: v1.1 Actionable Recovery — executable runbook recovery actions in the operator UI*
*Researched: 2026-05-27*
