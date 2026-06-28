---
phase: 49
slug: stress-fixtures-seed-coverage
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-28
---

# Phase 49 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + `Phoenix.LiveViewTest` via `DemoAppWeb.ConnCase` |
| **Config file** | `examples/demo_app/test/test_helper.exs` (+ `test/support/conn_case.ex` Ecto sandbox) |
| **Quick run command** | `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` |
| **Full suite command** | `cd examples/demo_app && mix test` (demo) + `mix test` at repo root (lib) |
| **Estimated runtime** | ~10–20 seconds (smoke suite is small) |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs`
- **After every plan wave:** Run `cd examples/demo_app && mix test` AND `mix test` at repo root (catch template/contract regression)
- **Before `/gsd-verify-work`:** Both suites green; capture script run once manually (operator + gallery, stress-seeded) to eyeball PNGs into `tmp` — **no rasters committed** (D-09)
- **Max feedback latency:** ~20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-RED  | scaffold | 0 | all | — | seeds use validated enum values | unit+integration (RED) | `mix test test/demo_app/operator_smoke_test.exs` | ✅ (extend) | ⬜ pending |
| FIXTURE-01 | seed | 1 | FIXTURE-01 | — | HEEx auto-escapes long URLs/IDs | unit (sandbox seed pin) | `mix test test/demo_app/operator_smoke_test.exs` | ✅ (extend) | ⬜ pending |
| FIXTURE-02 | seed | 1 | FIXTURE-02 | — | `seed("empty")` ⇒ 0 incidents | unit (sandbox seed pin) | same | ✅ (extend) | ⬜ pending |
| FIXTURE-03 | seed | 1 | FIXTURE-03 | — | `max_items` > 30 active (crosses page) | unit (sandbox seed pin) | same | ✅ (extend) | ⬜ pending |
| FIXTURE-04 | seed | 1 | FIXTURE-04 | — | incidents span open/investigating/resolved + escalation + kinds | unit (sandbox seed pin) | same | ✅ (extend) | ⬜ pending |
| FIXTURE-05 | seed | 1 | FIXTURE-05 | — | `stress` = union + ≥1 active; each name in `scenarios()` | unit (sandbox seed pin) | same | ✅ (extend) | ⬜ pending |
| GALLERY-02 (route) | test | 2 | GALLERY-02 | — | `GET /parapet/_gallery` → 200, DB-independent, not swallowed by `:id` | integration (ConnCase render) | same | ✅ (extend) | ⬜ pending |
| GALLERY-02 (script) | script | 2 | GALLERY-02 | — | capture script covers `/parapet/_gallery` desktop+mobile, light+dark | static grep pin (optional) | `grep -c '_gallery' examples/demo_app/scripts/capture_operator_ui_screenshots.sh` ⇒ ≥4 | ❌ W0 (optional) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Ground-truth definitions (the "true" signal asserted):**
- **`empty`:** `Repo.aggregate(Incident, :count) == 0` (and `ActionItem` == 0) in a fresh sandbox after `seed("empty")`.
- **`max_items`:** `count(state ∈ active) > 30`; optionally drive `Parapet.Operator.list_incident_queue(page_size: 30)` and assert `has_next_page?` true (proves the boundary, not just the count).
- **`mixed_status`:** `MapSet` of seeded `i.state` ⊇ `{"open","investigating","resolved"}`; ≥1 action item per kind (or distinct kinds ≥ N). Escalation diversity implied by reusing the four existing escalation helpers. **Journey diversity is N/A-by-design for seeds** (journeys hardcoded in `operator_live.ex` mount) — do NOT assert a seeded `:down` journey.
- **`stress`:** ≥1 active incident exists (capture script's `DETAIL_ID` query must succeed) + long-string + dense rows present.
- **GALLERY-02 route:** HTTP 200 + operator-component markers in `resp_body` from a route served with no DB seed. Route-ordering regression proven implicitly by 200 + gallery-specific markers.

---

## Wave 0 Requirements

- [ ] No new test *files* required — extend `examples/demo_app/test/demo_app/operator_smoke_test.exs` (gallery contract test + fixture-existence pins). Framework already installed/wired.
- [ ] RED scaffold first (D-12): write the gallery contract assert + fixture pins asserting the new facts **before** the seed/script edits land (fail RED — scenarios don't exist yet), then flip green when D-01..D-11 implemented.
- [ ] (Optional) static grep pin that `capture_operator_ui_screenshots.sh` contains the four `_gallery` capture lines — planner's discretion (D-12 "no proliferation").

*No `conftest`/fixture-module gap: `ConnCase` already provides the sandbox + `conn`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Stress-scenario + gallery screenshots render correctly (no overflow/clipping) | FIXTURE-05, GALLERY-02 | Visual judgment; no rasters committed this phase (Phase 50 owns baselines) | Run `capture_operator_ui_screenshots.sh` against a `PARAPET_DEMO_SCENARIO=stress`-seeded DB; eyeball PNGs in `tmp` (desktop+mobile, light+dark) |

*All scenario-shape and route facts have automated verification; only the visual PNG eyeball is manual (and deferred to Phase 50 for committed baselines).*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — existing infra covers all)
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter (planner/checker confirms)

**Approval:** pending
