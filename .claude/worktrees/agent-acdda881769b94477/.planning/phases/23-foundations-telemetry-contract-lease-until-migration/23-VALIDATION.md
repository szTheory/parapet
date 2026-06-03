---
phase: 23
slug: foundations-telemetry-contract-lease-until-migration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from RESEARCH.md "Validation Architecture" section (lines 695-735).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (bundled with Elixir 1.19.5 / OTP 28) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/parapet/telemetry/recovery_action_test.exs test/parapet/automation/claim_service_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | Quick ~5s · Full ~60s (existing baseline) |

---

## Sampling Rate

- **After every task commit:** Run quick command (above)
- **After every plan wave:** Run `mix test && mix verify.public_api`
- **Before `/gsd:verify-work`:** Run `mix test && mix verify.public_api && mix credo --strict && mix dialyzer`
- **Max feedback latency:** ~5 seconds for quick · ~60 seconds full

---

## Per-Task Verification Map

> Task IDs are placeholders pending planner-produced PLAN.md(s). Each requirement is mapped to a concrete test command + file. Threat Ref column is `—` because Phase 23 is internal DDL/contract work with no new user-facing inputs (see RESEARCH.md "Security Domain"). Status column populated by execute-phase.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-XX-01 | XX | 1 | FND-01 (migration) | — | N/A | smoke | `mix ecto.migrate && mix ecto.rollback && mix ecto.migrate` | ❌ W0 | ⬜ pending |
| 23-XX-02 | XX | 2 | FND-01 (self-heal) | — | Expired-lease row is updated in place; `{:won, claim}` with bumped `attempt_count` and same `id` | unit/db | `mix test test/parapet/automation/claim_service_test.exs --tag unboxed` | ❌ W0 (new test function) | ⬜ pending |
| 23-XX-03 | XX | 2 | FND-01 (attrs) | — | Fresh `claim_action/1` writes `lease_until = claimed_at + 5 min` | unit/db | `mix test test/parapet/automation/claim_service_test.exs` | ✅ (extends existing) | ⬜ pending |
| 23-XX-04 | XX | 1 | FND-02 (event families) | — | `RecoveryAction.event_families/0` returns exact frozen list of 8 concrete event tuples | unit | `mix test test/parapet/telemetry/recovery_action_test.exs` | ❌ W0 | ⬜ pending |
| 23-XX-05 | XX | 1 | FND-02 (vocab guards) | — | `normalize_outcome/1`, `normalize_short_circuit_reason/1`, `normalize_failure_class/1`, `normalize_actor_kind/1`, `normalize_action_kind/1` raise / return error for unknown atoms | unit | `mix test test/parapet/telemetry/recovery_action_test.exs` | ❌ W0 | ⬜ pending |
| 23-XX-06 | XX | 1 | FND-02 (shape_metadata) | — | `shape_metadata/2` strips private keys, builds `:refs` sub-map with the four documented refs | unit | `mix test test/parapet/telemetry/recovery_action_test.exs` | ❌ W0 | ⬜ pending |
| 23-XX-07 | XX | 2 | FND-02 (tier gate) | — | `mix verify.public_api` classifies new module as `:experimental` (regex `~r/####\s+Experimental\s*\{:\s*\.warning\}/` matches the moduledoc) | gate | `mix verify.public_api` | ✅ (existing task runs against compiled module) | ⬜ pending |
| 23-XX-08 | XX | 2 | FND-02 (docs) | — | `docs/telemetry.md` has new "## Recovery Action Family (Experimental)" section enumerating all 8 events + measurement keys + metadata keys + closed vocabularies; `docs/stability.md` has new row in Experimental Modules table | manual | review + `grep -F "Recovery Action Family (Experimental)" docs/telemetry.md && grep -F "Parapet.Telemetry.RecoveryAction" docs/stability.md` | ❌ W0 (doc sections) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Files that MUST exist (created or modified) before any other wave can verify against them:

- [ ] `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` — FND-01 migration (single `def change` with add nullable → execute backfill → modify NOT NULL)
- [ ] `lib/parapet/spine/action_claim.ex` — add `field(:lease_until, :utc_datetime_usec)` + changeset update (cast + validate_required) — companion to migration (RESEARCH OQ-3)
- [ ] `lib/parapet/automation/claim_service.ex` — add `lease_until` to `attrs`, add self-heal UPDATE branch inside `acquire_claim/2` (RESEARCH OQ-2), add `:lease_until` to `returning_fields/0`
- [ ] `lib/parapet/telemetry/recovery_action.ex` — FND-02 contract module (mirror `lib/parapet/telemetry/async_delivery.ex` 1:1)
- [ ] `test/parapet/telemetry/recovery_action_test.exs` — FND-02 contract test (mirror `test/parapet/telemetry/async_delivery_test.exs`)
- [ ] `test/parapet/automation/claim_service_test.exs` — new test function: expired-lease self-heal proof
- [ ] `test/support/concurrency_bootstrap.ex` — DDL update to include `lease_until` (required for the new concurrency test to insert rows; RESEARCH Finding #3)
- [ ] `docs/telemetry.md` — new "## Recovery Action Family (Experimental)" section after Semantic Guarantees (~line 131)
- [ ] `docs/stability.md` — new Experimental Modules row (~line 49)

*No new framework install required — ExUnit is bundled.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `mix ecto.migrate` on a DB with pre-existing `parapet_action_claims` rows succeeds and backfills `lease_until = claimed_at + INTERVAL '5 minutes'` for every existing row | FND-01 SC#1 | Requires a Postgres DB with seeded prior-migration state; ExUnit's `Ecto.Adapters.SQL.Sandbox` resets between tests so cannot prove cross-migration data-preservation under sandbox | (1) Run `mix ecto.reset` then `mix ecto.rollback --to 20260521010000` to apply only the create migration; (2) Seed a row in `parapet_action_claims` with explicit `claimed_at`; (3) Run `mix ecto.migrate` to apply the new migration; (4) Query `SELECT lease_until - claimed_at FROM parapet_action_claims` and assert the interval equals `5 minutes` for the seeded row. |
| `docs/telemetry.md` Recovery Action section is human-readable and complete | FND-02 SC#2 | Doc completeness is judgment-grade, not parseable; grep can confirm presence of the section header but not whether every event + key + vocab is enumerated | Review the new section against `lib/parapet/telemetry/recovery_action.ex`'s `@event_families`, `@public_metadata_keys`, and vocab guards; confirm every constant has a documented counterpart in prose. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s (quick) / < 60s (full)
- [ ] `nyquist_compliant: true` set in frontmatter (set after planner produces PLAN.md and Task IDs in the verification map are filled)

**Approval:** pending
