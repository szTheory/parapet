---
phase: 18-adoption-authoring-docs
plan: "05"
subsystem: docs-config
tags: [docs, mix-exs, extras, validation, anti-drift]
dependency_graph:
  requires: ["18-02", "18-03", "18-04"]
  provides: ["docs-extras-registered", "phase-gate-green"]
  affects: ["mix.exs", "hexdocs-rendering"]
tech_stack:
  added: []
  patterns: ["ExDoc extras registration", "anti-drift grep suite"]
key_files:
  created: []
  modified:
    - mix.exs
decisions:
  - "ExDoc flattens docs/integrations/*.md to doc/*.html (not doc/integrations/*.html) — standard ExDoc behavior; all 7 files rendered correctly under doc/"
metrics:
  duration_minutes: 2
  completed_date: "2026-05-24"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 18 Plan 05: Register Docs + Phase Validation Gate Summary

Seven new documentation files registered in mix.exs extras and full phase validation gate passed (anti-drift suite, mix docs --warnings-as-errors, mix test, mix verify.public_api all green).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Register seven new docs in mix.exs extras (D-01) | b5364cf | mix.exs |
| 2 | Run the docs build and full anti-drift validation gate | n/a (validation-only, no source changes) | — |

## What Was Built

**Task 1 — mix.exs extras registration:** Appended seven new doc paths to the `extras:` list in `defp docs` after `"docs/telemetry.md"`, matching existing four-space indentation and trailing-comma style:

- `docs/getting-started.md`
- `docs/troubleshooting.md`
- `docs/slo-authoring-guide.md`
- `docs/integrations/sigra.md`
- `docs/integrations/accrue.md`
- `docs/integrations/rulestead.md`
- `docs/integrations/threadline.md`

`groups_for_extras`, the `package files:` whitelist, and `skip_undefined_reference_warnings_on` were not changed. `mix compile` exited 0 after the edit.

**Task 2 — Anti-drift suite + phase gate:** All eight anti-drift checks from 18-VALIDATION.md passed; all three phase gate commands exited 0.

## Validation Gate Results

### Anti-drift suite (8/8 passing)

| Check | Command | Result |
|-------|---------|--------|
| 1 | `grep -c "docs/getting-started.md\|..." mix.exs` | 7 (PASS) |
| 2a | `grep -q "Parapet.attach(adapters: [:rulestead])" rulestead.md` | PRESENT (valid uniform line) |
| 2b | `grep -rn "Parapet.Integrations.Rulestead.attach()" docs/` | 0 results (PASS) |
| 2c | `grep -rniE "rulestead.*(raises\|UndefinedFunctionError)..."` | 0 results (PASS) |
| 3 | `grep -rn "config :parapet, :slos" docs/getting-started.md` | 0 results (PASS) |
| 4 | `grep "min_total_rate" docs/slo-authoring-guide.md` | References 0.01 (PASS) |
| 5 | `grep -E '"5m".*"30m".*"1h".*"6h".*"3d"' slo-authoring-guide.md` | 1 match (PASS) |
| 6 | `grep -l "SLO slice" accrue/rulestead/threadline.md` | 0 matches (PASS) |
| 7 | `mix docs --warnings-as-errors` | exit 0 (PASS) |
| 8 | All 7 HTML files rendered | PASS (see note below) |

### Phase gate

| Command | Result |
|---------|--------|
| `mix test` | 311 tests, 0 failures — exit 0 |
| `mix verify.public_api` | exit 0 |
| `mix docs --warnings-as-errors` | exit 0 |

### Rendered HTML files (check 8)

ExDoc flattens `docs/integrations/*.md` to `doc/*.html` (standard ExDoc behavior — no `doc/integrations/` subdirectory is created). All seven files were confirmed present:

- `doc/getting-started.html` (14.1 KB)
- `doc/troubleshooting.html` (15.6 KB)
- `doc/slo-authoring-guide.html` (20.3 KB)
- `doc/sigra.html` (12.0 KB)
- `doc/accrue.html` (11.7 KB)
- `doc/rulestead.html` (13.0 KB)
- `doc/threadline.html` (11.9 KB)

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Notes

**Check 8 path clarification:** The acceptance criterion says `ls doc/integrations/` would show `.html` files. ExDoc's actual behavior flattens the hierarchy — `docs/integrations/sigra.md` renders to `doc/sigra.html` (not `doc/integrations/sigra.html`). This is standard ExDoc behavior for extras and does not affect hexdocs.pm rendering. All seven files exist and were confirmed.

## Known Stubs

None. All seven docs are fully authored (from prior plans 18-02, 18-03, 18-04) and wired into the extras list. No placeholder content.

## Threat Flags

None. This plan is a dev-only ExDoc config edit and validation-only commands. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

All files and commits verified:
- `mix.exs` exists and contains all seven new doc paths (grep -c returns 7)
- Commit b5364cf exists in git log
- All 7 HTML files rendered under `doc/`
- `mix test`: 311 tests, 0 failures
- `mix verify.public_api`: exit 0
- `mix docs --warnings-as-errors`: exit 0
