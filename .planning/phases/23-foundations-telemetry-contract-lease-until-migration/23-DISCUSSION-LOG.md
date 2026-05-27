# Phase 23: Foundations — Telemetry Contract + `lease_until` Migration - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 23-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 23-foundations-telemetry-contract-lease-until-migration
**Mode:** assumptions
**Calibration tier:** minimal_decisive (vendor_philosophy = opinionated)
**Areas analyzed:** Migration shape, Self-healing claim semantics, Telemetry contract module + docs placement

## Assumptions Presented

### Migration shape (`lease_until` column)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add `lease_until :utc_datetime_usec, null: false` via single `def change`: add nullable → `execute` backfill `claimed_at + INTERVAL '5 minutes'` → set NOT NULL. Lease default for new rows computed at write time in `ClaimService`, NOT a DB `default:`. Add partial index `WHERE status='claimed'`. | Confident | `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs`; `lib/parapet/spine/action_claim.ex:35,44,75-77`; `lib/parapet/automation/claim_service.ex:23`; `priv/repo/migrations/20260521010000…:26` (partial-index convention) |
| Lease duration is a module-level constant in `ClaimService` (`@default_lease_ms = 5 * 60 * 1_000`). NOT Application-env configurable in v1.1. | Confident | Research SUMMARY.md L240 (5-min recommendation); existing 5-min preview token expiry in `Parapet.Operator`; Pitfall 13 (Application-env mistake from v0.10 `Parapet.SLO`); `.planning/threads/slo-state-off-application-env.md` |

### Self-healing claim semantics

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `claim_action/1` self-heals stale claims via single atomic `UPDATE … SET status='claimed', idempotency_key=$new, attempt_count=attempt_count+1, claimed_at=$now, lease_until=$now+@default_lease_ms WHERE (incident_id, action_kind, action_key)=(...) AND status='claimed' AND lease_until < $now RETURNING *`. Update-in-place, NOT insert-new. Returns `{:won, claim}` on success (bumped `attempt_count`); falls through to existing `{:conflicted, claim}` on 0 rows. | Confident | `lib/parapet/spine/action_claim.ex:75-77` (unique constraint forces update-in-place); `lib/parapet/automation/claim_service.ex:74-97` (existing on-conflict + select pattern); `:16-25` (statuses list — `"expired"` reserved, unused in steal path); `:119-129` (short-circuit reason vocab) |
| Stolen rows NOT transitioned to `"expired"` as a separate write. The in-place UPDATE collapses the steal into one atomic statement. `"expired"` status stays unused by Phase 23 — reserved for future cleanup. | Confident | Pitfall 4 (multi-node leak) — splitting the steal into two writes re-opens the race; `lib/parapet/spine/action_claim.ex:16-25` |
| Concurrency test: ONE new sequential test in `test/parapet/automation/claim_service_test.exs` — insert row with `lease_until` in past, call `claim_action/1`, assert `{:won, claim}` + `claim.id` matches original (update-in-place) + `claim.attempt_count == 2`. NO concurrent-stealer harness. | Likely | `test/parapet/automation/claim_service_test.exs:9-83` (existing insert-time race test covers concurrent dimension); Postgres MVCC + UPDATE WHERE makes concurrent-stealer outcome deterministic |

### Telemetry contract module + docs placement

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Ship `Parapet.Telemetry.RecoveryAction` (file `lib/parapet/telemetry/recovery_action.ex`) under Experimental tier, mirroring `Parapet.Telemetry.AsyncDelivery` 1:1. Module `@moduledoc` carries `> #### Experimental {: .warning}` callout. | Confident | `lib/parapet/telemetry/async_delivery.ex` (330-line template); `lib/parapet/automation/claim_service.ex:5-10` (Experimental admonition shape); `docs/stability.md:141` (closed vocab is non-negotiable under v1.0 freeze) |
| Frozen event family: 7 event tuples — `:previewed`, `:preview_failed`, `:confirmed`, `:short_circuited`, `:conflicted`, `:executed (start/stop/exception)` triplet under `:telemetry.span/3`. | Confident | Research SUMMARY.md L54 (`:telemetry.span/3` convention); `lib/parapet/operator.ex:23` (`[:parapet, :operator, :queue, :page]` operator-namespace precedent); covers full Preview → Confirm → Execute lifecycle |
| Measurement keys: `count` everywhere; `duration_ms` + `duration_native` on span stop/exception; `system_time` on span start. | Confident | Standard `:telemetry.span/3` shape (`Telemetry.Metrics.distribution`-compatible) |
| Metadata keys with closed vocabularies: `capability_id`, `action_kind` (`"operator"/"automation"/"escalation"`), `outcome` (`:previewed/:confirmed/:short_circuited/:conflicted/:succeeded/:failed`), `short_circuit_reason` (matches existing gate outputs), `failure_class` (`:precondition_failed/:provider_unavailable/:partial_failure/:internal_error`), `actor_kind` (`:human/:system`), `refs` sub-map (`incident_ref/claim_ref/step_ref/preview_ref`). | Confident | `lib/parapet/automation/claim_service.ex:119-129` (short-circuit reason vocab); research SUMMARY.md L135 (failure-class vocab); `docs/stability.md:141` (closed-vocab freeze rule) |
| `docs/telemetry.md` adds top-level section "## Recovery Action Family (Experimental)" AFTER "## Semantic Guarantees" with own Experimental admonition. `docs/stability.md` adds row to Experimental Modules table near `:49`. | Confident | `docs/telemetry.md:3-10` (file-level Stable header that must NOT be re-tiered); `:131` (Semantic Guarantees insertion anchor); `docs/stability.md:24-39,49` (table conventions) |
| Ship `test/parapet/telemetry/recovery_action_test.exs` in Phase 23 (mirrors `test/parapet/telemetry/async_delivery_test.exs:1-61`). Module-introspection-only — no emit-site assertions. | Confident | `test/parapet/telemetry/async_delivery_test.exs:1-61` (template — never asserts emits, only contract surface); emit-site assertion is Phase 26 territory |
| NO lease-aware `mix parapet.doctor` check in Phase 23. Defer to Phase 29 (ADOP-02). | Confident | `lib/mix/tasks/parapet.doctor.ex:316-322` (existing static check unrelated to lease); roadmap "S complexity" budget; research SUMMARY.md L109 (adoption signal → adopter phase) |

## Corrections Made

No corrections — user selected "Yes, proceed". All assumptions confirmed.

## Auto-Resolved

Not applicable — assumptions presented in interactive mode, all confirmed by user.

## External Research

None — every decision grounded in existing code patterns:
- Migration shape: original migration file + schema module
- Self-healing UPDATE: existing unique constraint + standard Postgres `UPDATE … RETURNING`
- Contract module: `Parapet.Telemetry.AsyncDelivery` 330-line template
- Contract test: `async_delivery_test.exs` template
- Tier conventions: `docs/stability.md` + existing Experimental admonitions
- Event naming precedent: `[:parapet, :operator, :queue, :page]`
- 5-min lease: research SUMMARY.md L240 (pre-decided in research, not a fresh question)
