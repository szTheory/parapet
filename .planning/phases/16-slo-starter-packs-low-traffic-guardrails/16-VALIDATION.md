---
phase: 16
slug: slo-starter-packs-low-traffic-guardrails
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `16-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/parapet/slo/starter_pack/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~10s (starter_pack subset); full suite a few seconds more |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/slo/starter_pack/`
- **After every plan wave:** Run `mix test && mix verify.public_api`
- **Before `/gsd:verify-work`:** Full suite must be green AND `mix verify.public_api` passes
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

> Task IDs are assigned by the planner; link them here during execution. Rows below
> map each phase requirement to its automated proof (from RESEARCH § Validation Architecture).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | — | 0 | SLO-01 | — | N/A | unit | `mix test test/parapet/slo/starter_pack/web_saas_test.exs` | ❌ W0 | ⬜ pending |
| TBD | — | 1 | SLO-01 | — | `WebSaaS.slos/0` returns exactly 3 SliceSpecs (HTTP avail, login, Oban) with documented objectives | unit | `mix test test/parapet/slo/starter_pack/web_saas_test.exs` | ❌ W0 | ⬜ pending |
| TBD | — | 1 | SLO-01 | T-dead-alert | HTTP slice targets `parapet_http_request_count` w/ `status_class=~"2xx\|3xx"`; Oban `parapet_oban_jobs_total` state="success"; login `parapet_journey_login_count` outcome="success" | unit | same | ❌ W0 | ⬜ pending |
| TBD | — | 1 | SLO-01 | T-cardinality | Every WebSaaS slice matcher key passes `LabelPolicy.assert_safe!` | unit | same | ❌ W0 | ⬜ pending |
| TBD | — | 1 | SLO-01 | T-flap | Each WebSaaS slice has non-zero `min_total_rate`; generator output contains denominator guard `> <min_total_rate>` | integration | same | ❌ W0 | ⬜ pending |
| TBD | — | 0 | SLO-02 | — | N/A | unit | `mix test test/parapet/slo/starter_pack/delivery_saas_test.exs` | ❌ W0 | ⬜ pending |
| TBD | — | 1 | SLO-02 | — | `DeliverySaaS.slos/0` returns WebSaaS 3 + Mailglass + Chimeway slices when stubs present | unit | `mix test test/parapet/slo/starter_pack/delivery_saas_test.exs` | ❌ W0 | ⬜ pending |
| TBD | — | 1 | SLO-02 | T-compileout | `DeliverySaaS.slos/0` drops delivery slices cleanly when Mailglass/Chimeway absent (only 3 WebSaaS slices remain) | unit | same | ❌ W0 | ⬜ pending |
| TBD | — | 1 | SLO-02 | T-drift | Delivery slices delegate to `MailglassDelivery.slos()` / `ChimewayDelivery.slos()` — no duplicated SliceSpec names | unit | same | ❌ W0 | ⬜ pending |
| TBD | — | 1 | SLO-01, SLO-02 | — | New pack modules are fully documented (`mix verify.public_api` / `mix docs --warnings-as-errors` passes) | integration | `mix verify.public_api` | depends on impl | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/parapet/slo/starter_pack/` — create test directory
- [ ] `test/parapet/slo/starter_pack/web_saas_test.exs` — stubs for SLO-01 (metric names, objectives, LabelPolicy, denominator guard, generator output, provider registration)
- [ ] `test/parapet/slo/starter_pack/delivery_saas_test.exs` — stubs for SLO-02 (conditional loading with/without `test/support` stubs, delegation, no SliceSpec drift)

*ExUnit already configured (`test/test_helper.exs`) — no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification (ExUnit + `mix verify.public_api`).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
