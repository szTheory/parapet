---
phase: 27
slug: prebuilt-playbooks
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-28
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 27-RESEARCH.md "## Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib) + `Igniter.Test` (content assertions, no module compilation) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~3–10 seconds (single generator test); full suite per project norms |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/parapet.gen.runbooks_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~10 seconds (generator test)

---

## Per-Task Verification Map

> Task IDs are assigned during planning (step 8). This map is keyed by requirement +
> observable behavior; the planner/executor binds each row to a concrete task ID.

| Requirement | Wave | Secure / Observable Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|------|------------------------------|-----------|-------------------|-------------|--------|
| PB-01 (Retry Storm) | 1 | `retry_storm.ex` generated; `warning:` present; no `capability:` key | content assertion | `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` | ✅ exists (test :77–82) | ⬜ pending |
| PB-02 (Suppression Drift) | 1 | `suppression_drift.ex` generated; hardened `warning:` states *why* automated clearing is unsafe (mass-escalation / re-suppression) | content assertion | same | ✅ exists (test :84–89) | ⬜ pending |
| PB-03 (Stalled Async) | 1 | `stalled_executor.ex` generated; `capability: :retry_async_item` + `warning:` | content assertion | same | ✅ exists (test :44–51) | ⬜ pending |
| PB-04 (Dead-Letter Drain) | 1 | `dead_letter.ex` generated; `capability: :requeue_dead_letter` + `warning:` | content assertion | same | ✅ exists (test :53–59) | ⬜ pending |
| PB-05 (Deploy-Tied Incident) | 1 | `deploy_tied_incident.ex` generated; module `DeployTiedIncident`; `capability: :revert_feature_flag`; `target_kind:`; `requires_preview: true`; `warning:` | content assertion | same | ❌ W0 — new template | ⬜ pending |
| PB-06 (Cardinality Blowout) | 1 | `cardinality_blowout.ex` generated; module `CardinalityBlowout`; `capability: :disable_metric_label`; `target_kind:`; `requires_preview: true`; `warning:` | content assertion | same | ❌ W0 — new template | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex` — new template (PB-05 deliverable)
- [ ] `priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex` — new template (PB-06 deliverable)
- [ ] Generator wiring: two `Igniter.copy_template(..., on_exists: :skip)` calls in `lib/mix/tasks/parapet.gen.runbooks.ex`
- [ ] Extend `test/mix/tasks/parapet.gen.runbooks_test.exs` with two new assertion blocks

*No framework install needed — ExUnit + `Igniter.Test` already in the suite. Template + generator + test should land atomically so the test is never red against a missing template.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Runnable Preview→Confirm round-trip against seeded data | PB-03/PB-04/PB-05/PB-06 | Requires demo app + seeded incident (Phase 28 Demo Seed) | Deferred to Phase 28 — out of scope here |

*Phase 27 proves Preview→Confirm **structurally** (step declares `requires_preview: true` + `target_kind:` + `warning:`); the operator path is already implemented and tested in Phases 25/26.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (two new templates)
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
