---
phase: 22
slug: release-readiness-1-0-cut
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
---

# Phase 22 — Validation Strategy

> Per-phase validation contract for release-readiness execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + shell workflow checks + GitHub/Hex manual confirmation |
| **Config file** | `mix.exs` and GitHub workflow YAML |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix verify.public_api && mix test && mix credo --strict && mix dialyzer && mix compile --no-optional-deps --warnings-as-errors` |
| **Estimated runtime** | CI/static gates: minutes; final manual release checks: operator-paced |

---

## Sampling Rate

- **After every task commit:** run the narrowest command proving the changed surface
- **After every plan wave:** re-run the affected workflow/build command set
- **Before `/gsd:verify-work`:** run the full proportionate gate and complete the manual cold-start walkthrough
- **Max feedback latency:** keep file-scope checks under ~5 minutes where possible

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 22-01-01 | 01 | 1 | REL-01 | T-22-01 | Lint lane owns release-quality gates | yaml/smoke | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` | ✅ exists | ⬜ pending |
| 22-01-02 | 01 | 1 | REL-01 | T-22-01 | Warnings-as-errors/doc gates remain green | build | `mix compile --warnings-as-errors && mix docs --warnings-as-errors` | ✅ exists | ⬜ pending |
| 22-02-01 | 02 | 2 | REL-02 | T-22-02 | Publish job only runs after Release Please creates a release | yaml/smoke | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-please.yml'))"` | ✅ exists | ⬜ pending |
| 22-02-02 | 02 | 2 | REL-02 | T-22-02 | Publish sequence preserves dry-run -> publish -> verify order | smoke | `rg -n "hex.publish --dry-run|hex.publish --yes|release_created" .github/workflows/release-please.yml` | ✅ exists | ⬜ pending |
| 22-03-01 | 03 | 3 | REL-03 | T-22-03 | Verification artifact names the full proportionate gate | doc/smoke | `test -f .planning/phases/22-release-readiness-1-0-cut/22-VERIFICATION.md` | ❌ new | ⬜ pending |
| 22-03-02 | 03 | 3 | REL-03 | T-22-03 | No security/perf/matrix scope creep in release gate | grep | `rg -n "security audit|perf|matrix|SHA-pin" .planning/phases/22-release-readiness-1-0-cut/22-VERIFICATION.md` | ❌ new | ⬜ pending |
| 22-04-01 | 04 | 4 | REL-04 | T-22-04 | `0.10.0` pin preserved until real tag exists | config/smoke | `rg -n 'release-as|bump-minor-pre-major|bump-patch-for-minor-pre-major' release-please-config.json` | ✅ exists | ⬜ pending |
| 22-04-02 | 04 | 4 | REL-04 | T-22-04 | External release truth explicitly checkpointed | cli/manual | `git tag --list 'v0.10*' | sort` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

No Wave 0 bootstrap is required. The repo already has the necessary workflows, Mix tasks, and release config surfaces to begin execution.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cold-start adopter walkthrough passes | REL-03 | Requires running the actual getting-started/demo path as an operator | Follow the release checklist artifact and confirm the bounded cold-start path works end to end |
| `HEX_API_KEY` exists in repo secrets | REL-02 | GitHub secrets are external to the repo | Verify in GitHub Settings -> Secrets and variables -> Actions |
| `v0.10.0` tag exists before pin removal | REL-04 | Release Please state/tag truth is external and time-sensitive | Confirm the exact tag exists before changing `release-as: "0.10.0"` |
| `hexdocs.pm/parapet/1.0.0/` resolves after cut | REL-02/04 | External post-publish truth | `curl -I https://hexdocs.pm/parapet/1.0.0/` and confirm success |

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit manual-only checkpoints
- [x] Sampling continuity preserved across all four plans
- [x] Wave 0 dependencies already exist
- [x] No watch-mode or long-running dev-server dependency in automated checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
