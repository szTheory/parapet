---
phase: 20
slug: governance-docs-completeness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 20 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) + shell smoke checks |
| **Config file** | `mix.exs` test config |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test`
- **After every plan wave:** Run `mix test --warnings-as-errors && mix docs --warnings-as-errors`
- **Before `/gsd:verify-work`:** Full suite green + `mix hex.build --dry-run` governance file check
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 20-01-01 | 01 | 1 | GOV-01 | — | N/A | smoke | `test -f CONTRIBUTING.md` | ❌ new | ⬜ pending |
| 20-01-02 | 01 | 1 | GOV-02 | — | N/A | smoke | `test -f SECURITY.md` | ❌ new | ⬜ pending |
| 20-01-03 | 01 | 1 | GOV-03 | — | N/A | smoke | `test -f CODE_OF_CONDUCT.md` | ❌ new | ⬜ pending |
| 20-02-01 | 02 | 1 | GOV-04 | — | N/A | smoke | `grep -i "1\.0\|OTP\|Postgres" README.md` | ✅ exists | ⬜ pending |
| 20-03-01 | 03 | 1 | DOCS-01 | — | N/A | smoke | `test -f docs/integrations/chimeway.md` | ❌ new | ⬜ pending |
| 20-03-02 | 03 | 1 | DOCS-02 | — | N/A | smoke | `test -f docs/integrations/mailglass.md` | ❌ new | ⬜ pending |
| 20-03-03 | 03 | 1 | DOCS-03 | — | N/A | smoke | `test -f docs/integrations/rindle.md` | ❌ new | ⬜ pending |
| 20-03-04 | 03 | 1 | DOCS-04 | — | N/A | smoke | `test -f docs/integrations/scoria.md` | ❌ new | ⬜ pending |
| 20-04-01 | 04 | 2 | DOCS-05 | — | N/A | smoke | `grep -i "provider-as-bundle\|bundle" docs/slo-authoring-guide.md` | ✅ exists | ⬜ pending |
| 20-05-01 | 05 | 2 | DOCS-06 | — | N/A | build | `mix docs --warnings-as-errors` | ✅ exists | ⬜ pending |
| 20-05-02 | 05 | 2 | GOV-05 | — | N/A | smoke | `mix hex.build --dry-run 2>&1 \| grep -E "CONTRIBUTING\|SECURITY\|CODE_OF_CONDUCT"` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

No Wave 0 required — no new test files needed for this phase. All validation uses file-existence checks, content grep, and build smoke commands against existing infrastructure.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README semver commitment reads naturally | GOV-04 | Prose quality judgment | Read the added section and confirm it states 1.0 semver commitment + Elixir/OTP/Postgres matrix clearly |
| Integration guide shape matches sigra.md template | DOCS-01–04 | Structural completeness | Compare each new guide against `docs/integrations/sigra.md` section headings |
| GitHub Private Vulnerability Reporting enabled in repo settings | GOV-02 | External GitHub UI | Log into GitHub → Settings → Code security → Enable private reporting |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
