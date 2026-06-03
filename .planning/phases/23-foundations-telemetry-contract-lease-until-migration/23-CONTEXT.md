# Phase 23: Foundations — Telemetry Contract + `lease_until` Migration - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock the v1.1 telemetry event family `[:parapet, :operator, :recovery_action, ...]` under the **Experimental** stability tier AND add the `lease_until` claim-lease column to `parapet_action_claims` BEFORE any capability code ships. Both decisions are irreversible-on-publish under the v1.0 freeze, so they land first. Covers requirements FND-01 and FND-02. Scope is **schema migration + telemetry contract module + docs + contract test** — NOT emit-site wiring (Phase 26), NOT capability behaviour (Phase 24), NOT operator-path closure (Phase 25).
</domain>

<decisions>
## Implementation Decisions

### Migration Shape (FND-01)

- **D-01:** `lease_until :utc_datetime_usec, null: false` added via a **single** `def change` migration: (1) add column nullable, (2) `execute "UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'"` to backfill, (3) `modify :lease_until, :utc_datetime_usec, null: false`. Type matches the existing `claimed_at :utc_datetime_usec, null: false` (`lib/parapet/spine/action_claim.ex:35`) and the `timestamps(type: :utc_datetime_usec)` convention (`:44`).
- **D-02:** Default lease for new rows is computed **at write time in `ClaimService`** (now + lease duration), NOT a Postgres `default:`. Computing default at DB level decouples lease from the claim wall-clock and breaks test injection (`now: ...` opt at `lib/parapet/automation/claim_service.ex:23`).
- **D-03:** **Lease duration is a module-level constant** in `ClaimService` — `@default_lease_ms 5 * 60 * 1_000`. NOT Application-env configurable in v1.1. Avoids repeating the v0.10 `Parapet.SLO` Application-env mistake (Pitfall 13); matches research SUMMARY.md L240 and the existing 5-min preview token expiry already in `Parapet.Operator`.
- **D-04:** Add a single **partial index** `CREATE INDEX … ON parapet_action_claims (lease_until) WHERE status = 'claimed'`. Keeps the expired-sweep query selective; mirrors the established status-partitioned index convention at `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs:26`.

### Self-Healing Claim Semantics (FND-01 success criterion #3)

- **D-05:** `claim_action/1` self-heals stale claims via a **single atomic statement** — `UPDATE parapet_action_claims SET status='claimed', idempotency_key=$new, attempt_count=attempt_count+1, claimed_at=$now, lease_until=$now+@default_lease_ms, updated_at=$now WHERE (incident_id, action_kind, action_key)=(...) AND status='claimed' AND lease_until < $now RETURNING *`. Row is **updated in place** (NOT insert-new — would violate the unique constraint at `lib/parapet/spine/action_claim.ex:75-77`).
- **D-06:** New `claim_action/1` flow: existing `insert_all on_conflict: :nothing` winner path → on conflict, attempt the self-heal UPDATE → if UPDATE returns 1 row, return `{:won, claim}` (same shape as existing winner path, with `attempt_count` bumped); if UPDATE returns 0 rows, fall through to existing `{:conflicted, claim}` path at `claim_service.ex:74-97`.
- **D-07:** Stolen rows are **NOT** transitioned to `"expired"` status as a separate write. The UPDATE-in-place pattern collapses the steal into one atomic SQL statement. The `"expired"` value in `@statuses` (`action_claim.ex:16-25`) remains unused by Phase 23 — reserved for future cleanup/archival work, not the steal path.
- **D-08:** Concurrency test in `test/parapet/automation/claim_service_test.exs` adds ONE sequential test: (a) insert a `parapet_action_claims` row directly with `status: "claimed"` + `lease_until` in the past (simulated crashed-node remnant); (b) call `ClaimService.claim_action/1` with the same `(incident_id, action_kind, action_key)`; (c) assert `{:won, claim}` AND `claim.id == original_id` (update-in-place proof) AND `claim.attempt_count == 2` (bump-counter proof). **No** concurrent-stealer-vs-stealer Task.async harness — the unique constraint + Postgres MVCC + the UPDATE WHERE clause make outcome a foregone conclusion.

### Telemetry Contract Module (FND-02)

- **D-09:** Ship a new module `Parapet.Telemetry.RecoveryAction` (file: `lib/parapet/telemetry/recovery_action.ex`) mirroring `Parapet.Telemetry.AsyncDelivery` exactly — closed `@event_families` list, `allowed_public_keys/1` per family, `shape_metadata/2` ref-key allowlist, bounded outcome-atom vocab. Module tier: **Experimental** (`@moduledoc` carries `> #### Experimental {: .warning}` callout in the same shape as `claim_service.ex:5-10`).
- **D-10:** Frozen event family enumerates **seven** event tuples (the `executed` triplet counts as one `:telemetry.span/3` family):
  - `[:parapet, :operator, :recovery_action, :previewed]`
  - `[:parapet, :operator, :recovery_action, :preview_failed]`
  - `[:parapet, :operator, :recovery_action, :confirmed]`
  - `[:parapet, :operator, :recovery_action, :short_circuited]`
  - `[:parapet, :operator, :recovery_action, :conflicted]`
  - `[:parapet, :operator, :recovery_action, :executed, :start | :stop | :exception]` (single `:telemetry.span/3` triplet)
- **D-11:** Measurement keys: `count` (every event), `duration_ms` and `duration_native` (span events only — `start` carries `system_time`; `stop`/`exception` carry both `duration` measurements).
- **D-12:** Metadata keys (closed vocabularies):
  - `capability_id` — atom from `Parapet.Capabilities` allowlist (5 atoms after Phase 24; 3 today)
  - `action_kind` — `"operator" | "automation" | "escalation"`
  - `outcome` — `:previewed | :confirmed | :short_circuited | :conflicted | :succeeded | :failed`
  - `short_circuit_reason` — closed atom vocab matching existing gate outputs in `claim_service.ex:119-129` (e.g. `:incident_resolved`, `:breaker_open`, `:preview_expired`, `:target_refs_drift`)
  - `failure_class` — `:precondition_failed | :provider_unavailable | :partial_failure | :internal_error`
  - `actor_kind` — `:human | :system`
  - `refs` (sub-map) — `incident_ref`, `claim_ref`, `step_ref`, `preview_ref`
- **D-13:** `docs/telemetry.md` adds a new top-level section "## Recovery Action Family (Experimental)" placed **after** "## Semantic Guarantees" (`docs/telemetry.md:131`), with its own Experimental admonition header distinct from the file-level "stable as of v1.0.0" header (`:3-10`). Enumerates every event name, measurement key, metadata key, and vocabulary.
- **D-14:** `docs/stability.md` adds `Parapet.Telemetry.RecoveryAction` as a new row in the Experimental Modules table (between `Parapet.MCP.PrometheusClient` and `Parapet.Automation.CircuitBreaker` near `:49`). Provides symmetric tier registration for `mix verify.public_api` and for adopters scanning what's safe to depend on.

### Contract Test (FND-02 success criterion #4 — guards the freeze)

- **D-15:** Ship `test/parapet/telemetry/recovery_action_test.exs` in Phase 23, mirroring `test/parapet/telemetry/async_delivery_test.exs:1-61` exactly. Asserts: event-family list, allowed public keys per family, outcome-atom vocabulary, `short_circuit_reason` vocabulary, `failure_class` vocabulary, `shape_metadata/2` ref extraction, `span` triplet membership.
- **D-16:** **No** emit-site assertions in Phase 23 — the contract test is module-introspection only (matches the existing AsyncDelivery test pattern, which never asserts a real event was emitted). Emit-site wiring + per-callsite assertion is Phase 26 (Audit Propagation) territory.

### Out of Scope for Phase 23

- **D-17:** **No** lease-aware `mix parapet.doctor` check in Phase 23. Doctor's existing claim-aware static check at `lib/mix/tasks/parapet.doctor.ex:316-322` stays untouched. Lease-aware adoption checks (count of attached capabilities, lease-staleness warnings) land in Phase 29 (ADOP-02), not here. Keeps Phase 23 inside its "S (low-code, high-leverage; single coherent PR)" complexity budget.
- **D-18:** **No** changes to `Parapet.Operator.confirm_runbook_step/4`. The operator-path-skips-ClaimService defect is Phase 25's architectural closure. Phase 23 only makes `claim_action/1` ready for both call paths (operator + Oban) by adding self-heal; it does not wire the operator path through.

### Claude's Discretion

- Exact migration filename (timestamp + descriptive slug, e.g. `20260528010000_add_lease_until_to_parapet_action_claims.exs`).
- Exact wording of the Experimental admonition in `Parapet.Telemetry.RecoveryAction.@moduledoc` and of the new `docs/telemetry.md` Experimental section (must match the established phrasing in existing Experimental modules + `docs/stability.md` tier definitions).
- Exact public function signatures on `Parapet.Telemetry.RecoveryAction` — must mirror `AsyncDelivery` shape (`event_families/0`, `allowed_public_keys/1`, `shape_metadata/2`, vocab guards) but the concrete spec lines can mirror style rather than be word-for-word identical.

### Folded Todos

None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/SUMMARY.md` — v1.1 research synthesis (capability-registration design, claim-lease defect closure, recovery-action telemetry under `:telemetry.span/3`, default lease = 5 min).
- `.planning/threads/actionable-recovery-design.md` — v1.1 seed thread.
- `.planning/research/PITFALLS.md` — Pitfall 4 (multi-node claim leak — what `lease_until` closes), Pitfall 11 (telemetry drift — what the contract module closes), Pitfall 13 (Application-env mistake — why lease duration is a module constant).
- `.planning/phases/19-api-telemetry-freeze/19-CONTEXT.md` — telemetry contract freeze + tier-detection mechanism (single source of truth = ExDoc admonition callout); the Experimental admonition shape the new module must mirror.
- `lib/parapet/spine/action_claim.ex` — schema for `parapet_action_claims`; `:35` (`claimed_at`), `:44` (`timestamps` type), `:16-25` (`@statuses`), `:75-77` (unique constraint that constrains the steal pattern).
- `lib/parapet/automation/claim_service.ex` — `claim_action/1` (`:23` time injection; `:74-97` insert+select winner path; `:119-129` short-circuit reason vocab).
- `lib/parapet/automation/executor.ex` — Oban auto-execution caller of `claim_action/1` (return-shape contract).
- `lib/parapet/escalation/worker.ex` — second caller of `claim_action/1` (return-shape contract).
- `lib/parapet/operator.ex` — `:23` `[:parapet, :operator, :queue, :page]` precedent for the operator namespace; `confirm_runbook_step/4` is the Phase 25 wire-up target (NOT touched in Phase 23).
- `lib/parapet/capabilities.ex` — current 3-atom allowlist (widens to 5 in Phase 24); the `capability_id` vocab anchor.
- `lib/parapet/telemetry/async_delivery.ex` — **the template for the new contract module** (330 lines: `@event_families`, `allowed_public_keys/1`, `shape_metadata/2`, ref-key allowlist at `:104-117`, vocab guards).
- `test/parapet/telemetry/async_delivery_test.exs` — **the template for the new contract test** (`:1-61` module-introspection-only pattern).
- `test/parapet/automation/claim_service_test.exs` — existing concurrency test (`:9-83` insert-time race); new expired-lease self-heal test slots in alongside.
- `test/support/concurrency_bootstrap.ex` — concurrency test infrastructure.
- `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs` — original migration; new migration must `ALTER TABLE` + backfill the existing column shape. `:15` (`claimed_at` non-null), `:26` (status-partitioned index convention).
- `docs/telemetry.md` — `:3-10` file-level Stable header (do NOT touch); `:131` Semantic Guarantees section (place new Experimental section after).
- `docs/stability.md` — `:24-39` Stable Modules table; `:49` Experimental Modules table insertion point; `:141` outcome-atom freeze rule (why closed vocab matters in Phase 23).
- `lib/mix/tasks/verify.public_api.ex` — public-API gate; new module must pass via Experimental admonition (no code changes here, just behavior).
- `lib/mix/tasks/parapet.doctor.ex` — `:316-322` existing claim-aware check (do NOT touch in Phase 23).
- `.planning/ROADMAP.md` — Phase 23 entry (`:176-189`); Phase 24/25/26/29 dependency direction.
- `.planning/REQUIREMENTS.md` — FND-01 (`:15`), FND-02 (`:16`).
- `mix.exs` — `files:` whitelist (no changes expected; `lib/parapet/telemetry/**/*.ex` already included via wholesale `lib`).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Telemetry.AsyncDelivery` (`lib/parapet/telemetry/async_delivery.ex`, ~330 lines) is the full template for the new `Parapet.Telemetry.RecoveryAction` contract module — closed `@event_families`, `allowed_public_keys/1` per family, `shape_metadata/2` ref-key allowlist, bounded vocab guards. The new module copies this structure 1:1.
- `test/parapet/telemetry/async_delivery_test.exs` is the full template for the new contract test — module-introspection-only assertions (event family list, key allowlists, vocab membership), never asserts an emit.
- `Parapet.Spine.ActionClaim` already declares `"expired"` in `@statuses` (`action_claim.ex:24`) — a reserved status value that Phase 23 does NOT yet write into rows, but downstream cleanup phases can.
- `ClaimService.claim_action/1` already supports a `now:` opt for test time injection (`claim_service.ex:23`); the lease default is computed against that same clock.
- Existing `(status, claimed_at)` partial index pattern at `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs:26` is the convention the new `(lease_until) WHERE status='claimed'` partial index mirrors.

### Established Patterns
- **Telemetry as API**: documented events carry semver guarantees (PROJECT.md Constraints). Adding new events under Experimental is the documented evolution path; closed vocab atoms are non-negotiable because changing them is BREAKING (`docs/stability.md:141`).
- **Closed-vocab metadata via guards in a contract module**: `AsyncDelivery` uses guard-bound family lists and explicit `allowed_public_keys` per family rather than free-form maps. Same pattern applies to `RecoveryAction`.
- **`:telemetry.span/3` triplet conventions**: `:start | :stop | :exception` count as one event family with two measurement modes (`system_time` on start; `duration` + `duration_native` on stop/exception).
- **Module-level Experimental admonition**: `claim_service.ex:5-10`, `action_claim.ex:5-10`, `executor.ex:5-10` all carry the `> #### Experimental {: .warning}` callout in the `@moduledoc`. The new `RecoveryAction` module follows the same shape so `verify.public_api` classifies it correctly.
- **Migration backfill via `execute`**: standard Ecto pattern for non-null column adds — add nullable, backfill via raw SQL, set NOT NULL. Single migration file keeps the operation atomic for `mix ecto.migrate`.
- **Hard-coded safety knobs over Application-env**: lease duration is module-level constant. Same rule as the v0.10 `Parapet.SLO` registry migration thread (`.planning/threads/slo-state-off-application-env.md`).

### Integration Points
- `ClaimService.claim_action/1` ↔ `Parapet.Automation.Executor` (Oban auto-execution; existing caller) ↔ `Parapet.Escalation.Worker` (escalation caller). Return-shape `{:won, claim}` / `{:conflicted, claim}` MUST stay stable; the steal path returns the same `{:won, claim}` (with bumped `attempt_count`).
- `Parapet.Operator.confirm_runbook_step/4` is the Phase 25 wire-up target — Phase 23 only readies `claim_action/1` for both call paths; does NOT touch operator code.
- `docs/telemetry.md` ↔ `docs/stability.md` ↔ `lib/mix/tasks/verify.public_api.ex` — three surfaces that must stay synchronized: doc enumerates events, stability tags the module, gate enforces module-level admonition.
- The frozen event surface in Phase 23 is the contract the future `Parapet.Recovery` callbacks (Phase 24) emit against; Phase 26 wires the emit-sites; Phase 29 graduates `Parapet.Recovery` to Stable while the telemetry family stays Experimental until v1.2+ usage proves it.

### Concurrency / Multi-Node Constraints
- The unique constraint `(incident_id, action_kind, action_key)` (`action_claim.ex:75-77`) makes update-in-place the ONLY safe steal mechanism — inserting a parallel row would violate the constraint and crash.
- Postgres MVCC + `UPDATE … WHERE lease_until < now() RETURNING *` is atomic against concurrent stealers — exactly one stealer wins under default isolation; no `SELECT FOR UPDATE` needed.
- `claimed_at + INTERVAL '5 minutes'` backfill is deterministic on the existing rows — no order dependence, no clock dependence in the migration.
</code_context>

<specifics>
## Specific Ideas

- **Single coherent PR**: roadmap calls Phase 23 "S (low-code, high-leverage; single coherent PR)". Migration + contract module + docs + test land together in one PR; do NOT split into multiple PRs (the docs would temporarily reference an uncompilable module).
- **The migration backfill formula is exactly `claimed_at + INTERVAL '5 minutes'`** — not `now() + 5 min`. This pins the lease to the original claim wall-clock, which is the right semantics for existing rows (a claim made 2 hours ago should already be expired after migration).
- **The contract test must run in CI from day one of Phase 23 — not behind an Experimental tag.** Experimental tier governs the surface's external stability promise, NOT whether the surface is tested. The whole point of the contract test is to lock the enumerated shape against a one-line `@event_families` change in a later phase.
- **Module placement: `lib/parapet/telemetry/recovery_action.ex`** mirrors `lib/parapet/telemetry/async_delivery.ex`. The `Parapet.Telemetry.*` namespace is the established home for contract modules.
- **Lease duration constant is private** (`@default_lease_ms`), not a public function. Adopters do NOT tune it. If a v1.2 capability ever needs a longer lease, that becomes a `capability_id`-scoped override at the capability level, not a global knob (research SUMMARY.md L240).
</specifics>

<deferred>
## Deferred Ideas

- **Lease-aware `mix parapet.doctor` checks** — adoption signal (capability count, lease-staleness warnings, missing-callback checks). Phase 29 (ADOP-02). Avoid bleeding into Phase 23's "S" complexity budget.
- **Transitioning stolen claim rows to `"expired"` status as a separate write** — collapsed into the in-place UPDATE for Phase 23. If a future analytics need emerges (counting steals), add a `previous_idempotency_key` column or a `claim_steals` telemetry event family then; not now.
- **Concurrent-stealer-vs-stealer test harness** — Postgres MVCC + the UPDATE WHERE clause make outcome deterministic; harness adds test time without proving anything new. Skipped.
- **Per-capability cooldown / breaker scope (vs system-scoped breaker)** — v1.2 candidate per REQUIREMENTS.md `:85`.
- **Configurable lease duration per environment** — explicitly rejected (re-introduces the Application-env mistake). If pressure surfaces later, expose at the capability level, not globally.
- **MCP Preview surface (read-only) for recovery actions** — v1.3+ per REQUIREMENTS.md `:84` (MCP stability-tier mismatch).
- **`Parapet.Telemetry.RecoveryAction` graduating to Stable** — Phase 29 graduates `Parapet.Recovery` to Stable; the telemetry family stays Experimental through v1.1 because real-world emit-site usage hasn't burned in yet. Graduation candidate for v1.2 once Phase 26's emit-sites have shipped.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
