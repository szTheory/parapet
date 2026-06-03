---
phase: 33
slug: documentation-polish
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir Mix, ExDoc, Docker Compose |
| **Config file** | `mix.exs`, `examples/demo_app/docker-compose.yml` |
| **Quick run command** | `mix format --check-formatted && MIX_ENV=dev mix docs --warnings-as-errors` |
| **Full suite command** | `mix compile --warnings-as-errors && MIX_ENV=dev mix docs --warnings-as-errors` |
| **Estimated runtime** | ~90 seconds locally, plus Docker smoke time when available |

---

## Sampling Rate

- **After every task commit:** Run `mix format --check-formatted && MIX_ENV=dev mix docs --warnings-as-errors`
- **After every plan wave:** Run `mix compile --warnings-as-errors && MIX_ENV=dev mix docs --warnings-as-errors`
- **Before `$gsd-verify-work`:** Full suite must be green, and Docker Compose smoke must be run or explicitly marked unavailable
- **Max feedback latency:** 120 seconds for docs/build checks; Docker smoke is allowed to exceed this because it builds containers

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | DX-03 | — | N/A | docs/source + ExUnit | `mix test test/parapet/docs_phase_33_test.exs && MIX_ENV=dev mix docs --warnings-as-errors` | ✅ | ✅ green |
| 33-01-02 | 01 | 1 | DX-04 | — | N/A | docs/source + ExUnit | `mix test test/parapet/docs_phase_33_test.exs && MIX_ENV=dev mix docs --warnings-as-errors` | ✅ | ✅ green |
| 33-01-03 | 01 | 1 | MAT-05 | — | N/A | source + ExUnit | `mix test test/parapet/docs_phase_33_test.exs` | ✅ | ✅ green |
| 33-01-04 | 01 | 1 | MAT-06 | — | N/A | source + ExUnit | `mix test test/parapet/docs_phase_33_test.exs` | ✅ | ✅ green |
| 33-02-01 | 02 | 2 | MAT-07 | — | N/A | docs/source + ExUnit | `mix test test/parapet/docs_phase_33_test.exs && MIX_ENV=dev mix docs --warnings-as-errors` | ✅ | ✅ green |
| 33-02-02 | 02 | 2 | MAT-08 | — | N/A | compose/smoke + ExUnit | `mix test test/parapet/docs_phase_33_test.exs && cd examples/demo_app && docker compose config` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Generated Validation Tests

| Test File | Requirements Covered | Command | Status |
|-----------|----------------------|---------|--------|
| `test/parapet/docs_phase_33_test.exs` | DX-03, DX-04, MAT-05, MAT-06, MAT-07, MAT-08 | `mix test test/parapet/docs_phase_33_test.exs` | ✅ green |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Demo app starts through Docker Compose and serves Operator UI | MAT-08 | Docker may be unavailable in the agent execution environment | Run `cd examples/demo_app && docker compose up --build`, then `curl -f http://localhost:${WEB_PORT:-4000}/parapet`, then `docker compose down -v` |

---

## Validation Audit 2026-06-03

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

**Gap filled:** Added durable ExUnit coverage for the Phase 33 documentation contract. Earlier verification relied on command transcripts and source assertions in plan summaries; the new test file now guards the migration guide, deployment guide, ExDoc guide/branding wiring, package whitelist, maintainer release procedure, contributor commit taxonomy, and demo Compose documentation.

**Config note:** `.planning/config.json` does not define `workflow.nyquist_validation`; no explicit disable flag was present, so validation proceeded under the workflow default.

**Audit commands:**

- `mix test test/parapet/docs_phase_33_test.exs`
- `mix format --check-formatted test/parapet/docs_phase_33_test.exs mix.exs`
- `MIX_ENV=dev mix docs --warnings-as-errors`
- `cd examples/demo_app && docker compose config >/dev/null`

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual Docker fallback
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s for non-Docker checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-03
