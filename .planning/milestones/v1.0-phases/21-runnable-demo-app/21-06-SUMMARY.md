---
phase: 21-runnable-demo-app
plan: 06
subsystem: release-gate
tags: [github, branch-protection, ci, demo-app, gap-closure]

# Dependency graph
requires:
  - "21-04 (release_gate job wired in ci.yml)"
  - "21-05 (code-level demo gaps closed)"
provides:
  - "GitHub branch protection on main requiring release_gate"
  - "External confirmation that DEMO-03 now blocks merges on a red release_gate"

requirements-completed: [DEMO-03]

# Metrics
completed: 2026-05-25
---

# Phase 21 Plan 06: Branch Protection Summary

Confirmed the external GitHub gate required by DEMO-03.

## What Was Verified

- `.github/workflows/ci.yml` already contains `release_gate` with `needs: [test, demo]`.
- `gh api repos/szTheory/parapet/branches/main/protection` returned branch-protection data for `main` rather than a 404.
- The returned payload includes:
  - `required_status_checks.strict: false`
  - `checks: [{"context":"release_gate","app_id":null}]`

## Outcome

`release_gate` is configured as a required status check on `main`, so a failing demo smoke test blocks merges into the default branch.
