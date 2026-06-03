# Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the operator-path-skips-claim defect by routing `Parapet.Operator.confirm_runbook_step/4` through `Parapet.Operator.ActionPayload` + `Parapet.Automation.ClaimService.claim_action/1` (the same path the Oban auto-execution caller `Parapet.Automation.Executor.perform/1` already uses). Add the additive return variants `{:short_circuited, reason}` and `{:conflicted, claim_id}` at the operator API boundary. Wire the Preview → Confirm UX surfaces in the demo operator LiveView so both new branches render with operator-actionable next steps, gated on a fresh Preview (5-minute expiry + `target_refs` hash gating). Covers UI-01, UI-02, UI-03, UI-04. Scope is **operator-API rewire + preview-token hash gating + LiveView branch arms + multi-node concurrency test** — NOT audit/TimelineEntry/ToolAudit shape (Phase 26), NOT emit-site wiring for `Parapet.Telemetry.RecoveryAction` (Phase 26), NOT prebuilt playbooks (Phase 27), NOT Stable-tier graduation (Phase 29). All new return-tuple variants are **additive** under the v1.0 freeze; existing `{:ok, result}` and `{:error, reason}` arms remain.
</domain>

<decisions>
## Implementation Decisions

### Operator-Path ClaimService Routing (UI-02, UI-04)

- **D-01:** `Parapet.Operator.confirm_runbook_step/4` calls `Parapet.Automation.ClaimService.claim_action/1` AFTER preview-token validation and BEFORE invoking `capability.execute.(...)`. Call arguments are sourced from the existing `%ActionPayload{}` arg: `action_kind: "operator"`, `action_key: to_string(step_id_atom)`, `breaker_step_id: step_id_atom`, `idempotency_key: payload.idempotency_key`. The atom `"operator"` is the missing third leg in the locked `@action_kinds` vocab at `lib/parapet/telemetry/recovery_action.ex:65-69` (`Executor` uses `"automation"`, `Escalation.Worker` uses `"escalation"`).
- **D-02:** Five-arm `case` on `claim_action/1`'s return, mirroring `Parapet.Automation.Executor.perform/1` (`lib/parapet/automation/executor.ex:29-47`) and `Parapet.Escalation.Worker.perform/1` (`lib/parapet/escalation/worker.ex:37-63`) one-to-one:
  - `{:won, claim}` → invoke `capability.execute.(incident, preview_entry.target_refs)` → `Parapet.Automation.ClaimService.mark_executed(claim)` → existing `{:ok, result}` happy-path return shape stays.
  - `{:short_circuited, claim, reason}` (internal 3-tuple at `claim_service.ex:51-58`) → returned as the **public 2-tuple** `{:short_circuited, reason}` at the operator-API boundary.
  - `{:conflicted, claim}` → returned as the public 2-tuple `{:conflicted, claim.id}`.
  - `{:error, reason}` → bubbles unchanged via the existing error arm.
- **D-03:** `{:ok, result}` and `{:error, reason}` return shapes from `confirm_runbook_step/4` are **NOT changed**. The two new variants are strictly additive under the v1.0 freeze (Phase 29 STAB-07 documents them in CHANGELOG as additive); adopter code that pattern-matches on `{:ok, _}` / `{:error, _}` keeps working.
- **D-04:** No new `action_kind` atoms. The vocab `"operator" | "automation" | "escalation"` is **locked** by Phase 23 (`recovery_action.ex:65-69`). `"operator"` is the right and only atom for this path.

### Preview Token Lifecycle (UI-01, UI-03)

- **D-05:** **Keep** the existing "newest `recovery_preview` `TimelineEntry` per (incident_id, step_id) is the active preview" storage model (`lib/parapet/operator.ex:782-819` + `lib/parapet/operator/workbench_contract.ex:167-206`). Do NOT introduce a `parapet_preview_tokens` table, a per-key ETS cache, or a `GenServer`-held map. The infrastructure is 90% in place — Phase 25 reuses it.
- **D-06:** 5-minute expiry stays at its current `compute_preview/3` write site (`lib/parapet/operator.ex:751`, expires_at = utc_now + 300s). On confirm, today's `DateTime.compare(preview_entry.expires_at, DateTime.utc_now())` gate at `operator.ex:707` keeps doing the time check, but on the stale branch it returns **the new** `{:short_circuited, :preview_expired}` instead of today's `{:error, :stale_preview}` at `operator.ex:736`. The atom `:preview_expired` is in the Phase 23 frozen `@short_circuit_reasons` map at `lib/parapet/telemetry/recovery_action.ex:46-51`.
- **D-07:** Add a `target_refs_hash` field to the preview payload — SHA-256 of the canonicalized `target_refs` list (sort + `:erlang.term_to_binary` + `:crypto.hash(:sha256, _)` + `Base.encode16(case: :lower)`). Written in `compute_preview/3` adjacent to the existing `preview_token` line (`operator.ex:752`); re-computed at confirm time over the live `target_refs` and compared. On mismatch, return `{:short_circuited, :target_refs_drift}` (also in the locked vocab at `recovery_action.ex:46-51`). The preview payload already merges arbitrary `host_data` keys at `operator.ex:771-772`, so adding `"target_refs_hash"` is a one-line additive shape change.
- **D-08:** "Confirm without fresh Preview" rejection (success criterion #1) leans on `find_recent_preview/3`'s existing `{:error, :mismatched_preview}` branch at `operator.ex:817`. Surfaced to the LiveView as a flash + "Re-Preview" prompt — no new server-side gate. The LiveView's `@detail.derived.active_preview` gate (`operator_detail_live.ex:187-189`) continues to hide the Confirm affordance when no fresh preview exists; the additional handler arm guards the race where the preview expires between render and click.
- **D-09:** `WorkbenchContract.find_active_preview/1` (`workbench_contract.ex:167-206`) already filters out expired previews via `:194-203` — **no change** to that derivation. The LiveView consumer surface (`@detail.derived.active_preview`) keeps its current contract.

### LiveView Branch Surfacing (UI-01, UI-04)

- **D-10:** LiveView edits land in:
  - `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` — the `handle_event("confirm_mitigation", ...)` clause at `:123-142`.
  - `examples/demo_app/lib/demo_app_web/components/operator_components.ex` — the `preview_panel/1` component at `:342-403`.
  These are the only LiveView surfaces Parapet ships (no LiveView under `lib/parapet/`); the demo is the reference adopters copy from, so Phase 25's UX wiring lives there.
- **D-11:** `handle_event("confirm_mitigation", ...)` grows from 2 arms to **4 arms**:
  - `{:ok, _result}` → existing success flash, no change.
  - `{:short_circuited, reason}` → reason-specific flash (`:preview_expired` → "Preview expired — please re-Preview before confirming"; `:incident_resolved` → "Incident already resolved — no action needed"; `:breaker_open` → "Circuit breaker open — recovery temporarily disabled"; `:target_refs_drift` → "Target state changed since Preview — please re-Preview") **plus a "Re-Preview" button** that reuses the existing `phx-click="preview_mitigation"` handler at `operator_detail_live.ex:103-121`.
  - `{:conflicted, _claim_id}` → verbatim flash from ROADMAP success criterion #2: **"Another node is executing this recovery — refresh to see the outcome"**.
  - `{:error, reason}` → existing generic error flash at `:140`.
- **D-12:** `preview_panel/1` component renders **action name** (= capability label fetched via `Parapet.Capabilities.get_recovery(id).name`) as a new field. Blast-radius indicator (`preview.data["count"]` at `:363`) and target_kind (`preview.data["target_kind"]` at `:359`) **already render** — no rework. Add `target_refs_hash` to the preview-payload round-trip for the Confirm submit (hidden form field or stored in the LiveView assigns; plan-phase picks one).

### Multi-Node Concurrency Test (Success Criteria #2, #4)

- **D-13:** New test file `test/parapet/operator/confirm_concurrency_test.exs`. Uses the established harness: `Parapet.TestSupport.ConcurrencyCase` + `unboxed_run` + `ConcurrencyRepo.insert` + the `Task.async` pair with `send(parent, {:ready, ...})` rendezvous + `:go` broadcast — verbatim pattern from `test/parapet/automation/executor_concurrency_test.exs:1-78` and `test/parapet/automation/claim_service_test.exs:1-50`.
- **D-14:** Test asserts: two simulated operators call `Parapet.Operator.confirm_runbook_step/4` against the same `(incident_id, action_kind: "operator", action_key)` after each takes a valid Preview. Exactly one task gets `{:ok, _result}`; the other gets `{:conflicted, _claim_id}`. The `_claim_id` matches the winner's claim row id, observable via `Parapet.Repo.get(Parapet.Spine.ActionClaim, _claim_id)`.
- **D-15:** No new test for the short-circuit branches — `:preview_expired` and `:target_refs_drift` are exercised via standard `async: true` unit tests against `Parapet.Operator.confirm_runbook_step/4` with synthetic time injection (`now:` opt at `lib/parapet/automation/claim_service.ex:23` is the established pattern; mirror for operator if needed). Plan-phase decides whether unit tests live in `test/parapet/operator_test.exs` (existing) or a new `test/parapet/operator/preview_lifecycle_test.exs`.

### Telemetry Emission Posture

- **D-16:** Phase 25 **may** emit `Parapet.Telemetry.RecoveryAction` events from the operator path (`:short_circuited`, `:conflicted`, `:previewed`, `:confirmed`) only if trivially in scope of the wiring work. Full emit-site coverage (including `:executed` span and `:preview_failed`) is **Phase 26 territory** and the contract module from Phase 23 already locks the vocab. The four success criteria do NOT require telemetry emission — they require the right return tuples + LiveView branches + concurrency-test proof.

### Out of Scope for Phase 25

- **D-17:** **No** changes to `Parapet.Telemetry.RecoveryAction` event family list, vocabularies, or `shape_metadata/2`. Phase 23 froze that surface.
- **D-18:** **No** changes to `Parapet.Recovery` behaviour callbacks. Phase 24 locked the 4-callback shape.
- **D-19:** **No** new `TimelineEntry` types (`:recovery_confirmed`, `:recovery_failed`). AUD-01/02/03 ship in Phase 26. The existing `type: "recovery_confirmed"` string write at `operator.ex:713` stays as-is — Phase 26 normalizes the timeline shape.
- **D-20:** **No** ToolAudit row writes from the new operator path beyond what `Parapet.Operator.Evidence.run_operator_command/1` (`operator.ex:723-727`) already does. AUD-02 is Phase 26.
- **D-21:** **No** prebuilt playbooks (`Retry Storm`, `Suppression Drift`, `Stalled Async`, `Dead-Letter Drain`, `Deploy-Tied Incident`, `Cardinality Blowout`). PB-01..PB-06 land in Phase 27.
- **D-22:** **No** `mix parapet.gen.recovery <NAME>` Igniter task (ADOP-01) and **no** `mix parapet.doctor` adoption-signal check (ADOP-02). Phase 29.
- **D-23:** **No** Stable-tier graduation for any v1.1 surface. Phase 29 STAB-07.

### Claude's Discretion

- Exact wording of the four `:short_circuited` reason flash strings beyond ROADMAP-spec'd ones ("Preview expired", "Incident already resolved"). The four reasons all live in the locked vocab; plan-phase picks copy.
- Whether `target_refs_hash` round-trips through a hidden form field or LiveView assigns (D-12). Both are correct; plan-phase picks one.
- Whether short-circuit unit tests live in `test/parapet/operator_test.exs` or a new `test/parapet/operator/preview_lifecycle_test.exs` (D-15). Plan-phase picks.
- Whether to opportunistically emit `Parapet.Telemetry.RecoveryAction.:short_circuited` / `:conflicted` from the operator path during Phase 25 (D-16). Default: emit only if it costs <10 lines per emit-site; otherwise defer to Phase 26.

### Folded Todos

None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — UI-01 (`:32`), UI-02 (`:33`), UI-03 (`:34`), UI-04 (`:35`); Phase 25 traceability (`:118-121`).
- `.planning/ROADMAP.md` — Phase 25 entry at `:136-149`; dependency direction (Phase 24 prerequisite, Phase 26 dependent).
- `.planning/phases/23-foundations-telemetry-contract-lease-until-migration/23-CONTEXT.md` — Phase 23 froze the `@short_circuit_reasons` vocab (`:preview_expired`, `:target_refs_drift`, `:incident_resolved`, `:breaker_open`) and the `@action_kinds` vocab (`"operator"`); Phase 25 emits against the frozen vocab.
- `.planning/phases/24-recovery-behaviour-capability-allowlist/24-CONTEXT.md` — confirms `Parapet.Recovery` callbacks are arity-2 on `preview`/`execute` (D-01 in Phase 24), so the operator path captures arity-2 functions through `Parapet.Capabilities`. Phase 25 does NOT touch `Parapet.Recovery`.
- `.planning/research/SUMMARY.md` — v1.1 research synthesis; preview/confirm flow design and 5-min expiry rationale.
- `.planning/threads/actionable-recovery-design.md` — v1.1 seed thread.
- `lib/parapet/operator.ex` — **the central edit target.** `:23` operator namespace precedent; `:103-121` (preview_mitigation handler — already wires the host-app Preview path); `:657` (`Parapet.Capabilities.get_recovery/1` read); `:707` (existing expiry gate — translates to `{:short_circuited, :preview_expired}`); `:711` (`capability.execute.(incident, preview_entry.target_refs)` — this call moves **inside** the `{:won, claim}` arm); `:713` (existing `type: "recovery_confirmed"` TimelineEntry write — DO NOT touch in Phase 25); `:723-727` (existing `{:ok, result}` happy-path return — stays); `:736` (existing `{:error, :stale_preview}` — replaced with `{:short_circuited, :preview_expired}`); `:750-780` (`compute_preview/3` — add `target_refs_hash` field at `:752`); `:767` (`capability.preview.(incident, step)` — Preview-side call); `:782-819` (`find_recent_preview/3` — keep, surface `:mismatched_preview` to LiveView).
- `lib/parapet/operator/action_payload.ex` — `:44-50` `:execute_mitigation` action_type already requires `:idempotency_key`. **No edits needed.**
- `lib/parapet/operator/workbench_contract.ex` — `:167-206` `find_active_preview/1` already filters out expired previews via `:194-203`. **No edits needed.** LiveView consumer surface stays unchanged.
- `lib/parapet/automation/claim_service.ex` — `:23` (`now:` time injection); `:51-58` (`{:short_circuited, claim, reason}` internal 3-tuple → wrapped to public 2-tuple); `:74-97` (insert+select winner path); `:119-129` (short-circuit reason mapping). **No edits needed** — the operator path becomes a third caller.
- `lib/parapet/automation/executor.ex` — `:29-47` (**the template** for the operator-path five-arm `case` on `claim_action/1`'s return). Uses `action_kind: "automation"`.
- `lib/parapet/escalation/worker.ex` — `:37-63` (second working precedent of the five-arm pattern). Uses `action_kind: "escalation"`.
- `lib/parapet/telemetry/recovery_action.ex` — `:46-51` (`@short_circuit_reasons` frozen vocab — `:preview_expired`, `:target_refs_drift`, `:incident_resolved`, `:breaker_open`); `:65-69` (`@action_kinds` frozen vocab — `"operator" | "automation" | "escalation"`). **DO NOT edit** — Phase 23 froze.
- `lib/parapet/capabilities.ex` — `:14-18` 5-atom allowlist (set by Phase 24); the read path the operator confirms against via `get_recovery/1`.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` — `:103-121` `preview_mitigation` handler (re-used by Re-Preview button); `:123-142` `confirm_mitigation` handler (**grows from 2 arms to 4**); `:187-189` `@detail.derived.active_preview` consumer (no edit).
- `examples/demo_app/lib/demo_app_web/components/operator_components.ex` — `:342-403` `preview_panel/1` (add action name; blast-radius `:363` and target_kind `:359` already render).
- `test/parapet/automation/executor_concurrency_test.exs` — `:1-78` **the template** for `test/parapet/operator/confirm_concurrency_test.exs`. Uses `ConcurrencyCase`, `unboxed_run`, `Task.async` rendezvous + `:go` signal.
- `test/parapet/automation/claim_service_test.exs` — `:1-50` second concurrency-test precedent.
- `test/parapet/operator_test.exs` — existing unit-test home for operator-API contract assertions; short-circuit branch tests slot in here (or a new `preview_lifecycle_test.exs`).
- `test/support/concurrency_bootstrap.ex` — `ConcurrencyCase` + `ConcurrencyRepo` harness.
- `docs/stability.md` — Phase 25 does NOT add a row; `Parapet.Recovery` (Phase 24) and `Parapet.Telemetry.RecoveryAction` (Phase 23) rows already exist. The two new return-tuple variants on `confirm_runbook_step/4` are additive under the existing Stable tier of `Parapet.Operator`; CHANGELOG migration note about additive-only is **Phase 29 STAB-07**.
- `docs/telemetry.md` — Phase 25 does NOT add a section; Phase 23 already documented the `:short_circuited` / `:conflicted` outcomes under the Experimental Recovery Action family.
- `mix.exs` — no changes expected; no new dependencies.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Parapet.Automation.Executor.perform/1` (`lib/parapet/automation/executor.ex:29-47`) is the **full template** for the operator-path five-arm `case` on `claim_action/1`. Copy the arm shape one-to-one; substitute `"automation"` → `"operator"`.
- `Parapet.Escalation.Worker.perform/1` (`lib/parapet/escalation/worker.ex:37-63`) is the second working precedent.
- `Parapet.Operator.ActionPayload` (`lib/parapet/operator/action_payload.ex:44-50`) **already exists** with the exact `:execute_mitigation` action_type + required `:idempotency_key` shape Phase 25 consumes. Zero edits.
- `Parapet.Operator.compute_preview/3` (`operator.ex:750-780`) already emits `preview_token` (`:752`) and `expires_at = utc_now + 300s` (`:751`). Add `target_refs_hash` adjacent.
- `Parapet.Operator.find_recent_preview/3` (`operator.ex:782-819`) already token-matches and parses `expires_at`. The seam `{:error, :stale_preview}` at `operator.ex:736` is where `{:short_circuited, :preview_expired}` substitutes in.
- `Parapet.Operator.WorkbenchContract.find_active_preview/1` (`workbench_contract.ex:167-206`) already filters expired previews. LiveView consumer (`operator_detail_live.ex:187-189`) keeps its current contract.
- Demo LiveView `confirm_mitigation` handler (`operator_detail_live.ex:123-142`) and `preview_panel/1` component (`operator_components.ex:342-403`) already render most UI-01 fields — blast-radius indicator (`:363`), target_kind (`:359`). Phase 25 adds action name + new arms.
- `Parapet.TestSupport.ConcurrencyCase` + `unboxed_run` + `ConcurrencyRepo` (`test/support/concurrency_bootstrap.ex`) is the established multi-node test harness; `executor_concurrency_test.exs:1-78` shows the rendezvous + `:go` pattern.

### Established Patterns

- **Five-arm `claim_action/1` `case` is the dispatch idiom**: every caller (`Executor`, `Escalation.Worker`, now `Operator`) implements the same five-arm `case`. Adding a third caller is mechanical.
- **Additive-only return variants under v1.0 freeze**: new error-shape tuples must not break adopter pattern matching on `{:ok, _}` / `{:error, _}`. Phase 25 uses **distinct** `{:short_circuited, _}` and `{:conflicted, _}` head atoms — never nested inside the existing `:error` arm.
- **Frozen closed-vocab atoms**: `@short_circuit_reasons` (`recovery_action.ex:46-51`) and `@action_kinds` (`:65-69`) were locked in Phase 23. Phase 25 emits against the existing vocab; never invents new atoms.
- **Demo-LiveView as the reference adopter surface**: Parapet ships no `lib/parapet/**/live/` modules; the demo app's LiveView is what adopters copy from. UI changes live in `examples/demo_app/lib/demo_app_web/live/`.
- **TimelineEntry-backed preview storage**: previews live as TimelineEntries with `type: "recovery_preview"`. No separate `parapet_preview_tokens` table — the spine handles preview lifecycle through the same audit surface that Phase 26 will normalize.
- **`unboxed_run` for multi-node tests**: BEAM sandboxes can't multi-node-test under Ecto SQL Sandbox; the `ConcurrencyCase` + `unboxed_run` pattern is the established escape hatch.

### Integration Points

- `Parapet.Operator.confirm_runbook_step/4` becomes the third caller of `Parapet.Automation.ClaimService.claim_action/1`. The existing two callers (`Executor`, `Escalation.Worker`) stay unchanged — the only operator-side change is adding the `case` block and translating the internal 3-tuple to the public 2-tuple.
- `ActionPayload` flows: LiveView builds it at `operator_detail_live.ex:129-130` → passes to `Parapet.Operator.confirm_runbook_step/4` → operator extracts `idempotency_key` for `claim_action/1`. No new `ActionPayload` fields.
- `Parapet.Capabilities.get_recovery/1` (`capabilities.ex`) returns the registry struct whose `name` field becomes the "action name" in the Preview panel. Read path already exists; UI-side just renders it.
- LiveView `@detail.derived.active_preview` → `WorkbenchContract.find_active_preview/1` → `find_recent_preview/3` is the read chain that gates the Confirm affordance. **Unchanged by Phase 25.**
- The Phase 23 `lease_until` self-heal at `claim_service.ex:51-58` already returns `{:short_circuited, claim, :breaker_open}` and `{:short_circuited, claim, :incident_resolved}` — Phase 25 doesn't add new short-circuit branches at the ClaimService level; it surfaces existing ones.

### Concurrency / Multi-Node Constraints

- The operator-path Confirm becomes claim-protected exactly the same way the Oban path is: `(incident_id, action_kind, action_key)` unique constraint at `lib/parapet/spine/action_claim.ex:75-77` enforces single-winner semantics; Postgres MVCC + the `UPDATE … WHERE lease_until < now() RETURNING *` self-heal makes the loser see `{:conflicted, claim}` deterministically.
- Two operators racing on the same step against different nodes both go through the same DB-level claim. Test asserts that the loser sees `{:conflicted, _claim_id}` and the winner sees `{:ok, _result}`.
- The 5-min lease on `parapet_action_claims.lease_until` (Phase 23 FND-01) protects against crashed-node executions — if the winner crashes mid-execute, the loser's next Confirm after 5 min self-heals and proceeds. This is already in place; Phase 25 just consumes it.
- No new cross-node sync. The `Parapet.Capabilities` Agent is per-node (Phase 24 D-12); both nodes have the same allowlist + same registered capabilities by virtue of identical boot-time `attach/1` calls on each node.
</code_context>

<specifics>
## Specific Ideas

- **The five-arm `claim_action/1` `case` lives inside `confirm_runbook_step/4`**, not in a new wrapper module. The function already exists at `lib/parapet/operator.ex:` and is the right home — adding a wrapper module would fragment the operator surface.
- **The new return-tuple variants are 2-tuples**: `{:short_circuited, reason}` and `{:conflicted, claim_id}` — NOT 3-tuples. The internal `claim_service.ex:51-58` 3-tuple is unwrapped at the operator boundary; adopters see a clean 2-tuple.
- **The `target_refs_hash` algorithm is SHA-256 over canonicalized `term_to_binary`**, not a custom-rolled scheme. Format: `Base.encode16(:crypto.hash(:sha256, :erlang.term_to_binary(Enum.sort(target_refs))), case: :lower)`. Picks SHA-256 because (a) collision-resistant for any plausible target_refs size, (b) no new deps (`:crypto` is stdlib), (c) the hash is informational-only — it isn't a security token.
- **The Re-Preview button reuses `phx-click="preview_mitigation"`** (already wired at `operator_detail_live.ex:103-121`), not a new handler. The flash + button slot into the existing flash component.
- **The verbatim conflict-flash text is "Another node is executing this recovery — refresh to see the outcome"** per ROADMAP success criterion #2. Don't paraphrase.
- **Phase 25 is one coherent PR.** Operator API edit + LiveView edits + concurrency test + unit tests land together. Splitting the operator API from the LiveView would temporarily render the new variants invisible to adopters.
- **No `mix.exs` changes.** Phase 25 is zero new runtime or dev deps — `:crypto` is stdlib; the test harness is already in `test/support/`.
- **The `_claim_id` in `{:conflicted, claim_id}` is the integer/UUID PK of the winning row** (whatever `Parapet.Spine.ActionClaim`'s `id` field is — check `action_claim.ex` for type). Adopters do NOT pattern-match on the value; it's there for operator-UI display ("claim #1234 in flight").
</specifics>

<deferred>
## Deferred Ideas

- **`:recovery_confirmed` / `:recovery_failed` `TimelineEntry` types**, formal `ToolAudit` row writes from the operator Confirm path — Phase 26 (AUD-01, AUD-02, AUD-03). The existing `type: "recovery_confirmed"` string write at `operator.ex:713` stays as-is in Phase 25.
- **`Parapet.Telemetry.RecoveryAction` emit-sites** (`:previewed`, `:preview_failed`, `:confirmed`, `:short_circuited`, `:conflicted`, `:executed` span triplet) — Phase 26. Phase 25 may opportunistically emit `:short_circuited` and `:conflicted` only if trivially cheap (<10 lines per emit-site, D-16); otherwise full emit-coverage is Phase 26.
- **6 prebuilt playbooks** (PB-01..PB-06) — Phase 27.
- **`mix parapet.gen.recovery <NAME>` Igniter scaffolder** — Phase 29 (ADOP-01).
- **`mix parapet.doctor` adoption-signal check** — Phase 29 (ADOP-02).
- **`docs/recovery-actions.md` adopter guide** — Phase 29 (ADOP-03).
- **`Parapet.Recovery` graduation Experimental → Stable** + CHANGELOG additive-variant migration note — Phase 29 (STAB-07).
- **Per-capability cooldown / breaker scope** — v1.2 (`.planning/REQUIREMENTS.md:85`).
- **`parapet_preview_tokens` table / ETS-backed preview cache** — explicitly rejected. TimelineEntry-backed storage is the right shape under the v1.0 spine.
- **Configurable preview-token lease via Application env** — explicitly rejected. 5-min constant matches the `claim_action/1` `@default_lease_ms` and the v0.10 SLO Application-env rejection rationale (Pitfall 13).
- **Audit-side dedupe of `:recovery_confirmed` TimelineEntries** (one per Confirm vs one per execute) — Phase 26.
- **MCP Preview surface (read-only) for the new operator path** — v1.3+ per REQUIREMENTS.md `:84`.

### Reviewed Todos (not folded)

None — no pending todos matched this phase.
</deferred>
