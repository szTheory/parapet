---
phase: 32
slug: ci-supply-chain-hardening
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-03
---

# Phase 32 — Validation Strategy

## Validation Contract

The phase is validated by workflow/config structure checks and release-maintenance documentation checks.

## Automated Evidence

| Requirement | Evidence | Status |
|-------------|----------|--------|
| MAT-01 | `32-VERIFICATION.md` verifies Elixir/OTP CI matrix definitions. | green |
| MAT-02 | `32-VERIFICATION.md` verifies SHA-pinned GitHub Actions and no floating action refs. | green |
| MAT-03 | `32-VERIFICATION.md` verifies Dependabot config for Mix and GitHub Actions. | green |
| MAT-04 | `32-VERIFICATION.md` verifies branch protection documentation for `release_gate`. | green |

## Validation Sign-Off

- [x] Supply-chain hardening checks are automated or source-verifiable.
- [x] No manual-only checks remain in the phase artifact; applying branch protection remains an operator setup step documented in `docs/branch-protection.md`.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-03
