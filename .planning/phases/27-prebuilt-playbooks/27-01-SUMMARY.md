---
phase: 27-prebuilt-playbooks
plan: 01
subsystem: runbooks
tags: [elixir, eex, parapet-runbook, igniter, generator, capabilities, feature-flag, cardinality]

# Dependency graph
requires:
  - phase: 26-audit-propagation
    provides: confirm_runbook_step audit path, ClaimService, RecoveryAction telemetry
  - phase: 24-recovery-behaviour
    provides: Parapet.Capabilities allowlist with :revert_feature_flag and :disable_metric_label atoms
provides:
  - deploy_tied_incident.ex.eex EEx template: 3-step capability runbook for :revert_feature_flag
  - cardinality_blowout.ex.eex EEx template: 3-step capability runbook for :disable_metric_label
  - suppression_drift hardening: step-2 warning explains mass-escalation + incorrect-re-suppression rationale
  - Generator wiring for both new templates (copy_template with on_exists: :skip)
  - Generator test extended with file-presence + content assertions for both new templates
  - runbook.ex @doc accuracy: :capability doc now lists all 5 valid atoms
affects: [28-demo-seed, phase-29-recovery-behaviour-stable]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Capability runbook 3-step shape: investigate (guidance, preview_only) → mitigate (capability, requires_preview, warning) → verify (guidance, preview_only)"
    - "Atom-only capability references in templates: no host module coupling at template compile time"
    - "on_exists: :skip on all generator copy_template calls: re-running never clobbers adopter edits"

key-files:
  created:
    - priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex
    - priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex
  modified:
    - priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex
    - lib/mix/tasks/parapet.gen.runbooks.ex
    - test/mix/tasks/parapet.gen.runbooks_test.exs
    - lib/parapet/runbook.ex

key-decisions:
  - "D-13 accepted: runbook.ex @doc accuracy fix (5-atom list) is in-scope nicety — D-13 intent is no DSL/behavior changes, and a @doc string is neither. The stale 3-atom doc went stale at Phase 24."
  - "Templates reference capabilities by atom only (:revert_feature_flag, :disable_metric_label) — no host module alias — so they compile with zero optional-dep coupling."
  - "suppression_drift step-2 warning hardened inline (no new step, no capability key) — guidance-only structural guarantee holds."

patterns-established:
  - "Capability template pattern: investigate→mitigate→verify; only mitigate step carries capability:, target_kind:, requires_preview: true"
  - "Wiring pointer in template guidance text: identifies the integration surface (Rulestead for :revert_feature_flag, mix parapet.doctor cardinality / Parapet.Metrics.Validator for :disable_metric_label) without naming a host module"

requirements-completed: [PB-01, PB-02, PB-03, PB-04, PB-05, PB-06]

# Metrics
duration: 3min
completed: 2026-05-28
---

# Phase 27 Plan 01: Prebuilt Playbooks Summary

**Six JTBD-MAP prebuilt runbook templates fully wired: two new capability templates (deploy_tied_incident via :revert_feature_flag, cardinality_blowout via :disable_metric_label) authored in the stalled_executor 3-step shape, suppression_drift guidance-only warning hardened with architectural rationale, generator updated to emit all six, test suite green at 491/0.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-28T18:00:56Z
- **Completed:** 2026-05-28T18:03:42Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Created `deploy_tied_incident.ex.eex`: 3-step capability runbook with `capability: :revert_feature_flag`, `target_kind: :feature_flag`, `requires_preview: true`, Rulestead wiring pointer in guidance text
- Created `cardinality_blowout.ex.eex`: 3-step capability runbook with `capability: :disable_metric_label`, `target_kind: :metric_label`, `requires_preview: true`, `mix parapet.doctor cardinality` + `Parapet.Metrics.Validator` reference in guidance text
- Hardened `suppression_drift.ex.eex` step-2 warning with mass-escalation + incorrect-re-suppression architectural rationale; file remains capability-free (0 `capability:` keys)
- Updated `lib/parapet/runbook.ex` @doc `:capability` list from 3 atoms to all 5 (accuracy fix accepted per D-13 note)
- Wired both new templates into `lib/mix/tasks/parapet.gen.runbooks.ex` with `on_exists: :skip`
- Extended generator test with file-presence and content assertions for both new templates; `mix test`: 491 tests, 0 failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Author deploy_tied_incident + cardinality_blowout templates, harden suppression_drift** - `63a24bd` (feat)
2. **Task 2: Wire templates into generator and extend test** - `694299c` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex` - New: Deploy-Tied Incident capability runbook (PB-05), :revert_feature_flag
- `priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex` - New: Cardinality Blowout capability runbook (PB-06), :disable_metric_label
- `priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex` - Modified: step-2 warning hardened with mass-escalation + incorrect-re-suppression rationale (PB-02)
- `lib/mix/tasks/parapet.gen.runbooks.ex` - Modified: two new copy_template calls for deploy_tied_incident and cardinality_blowout
- `test/mix/tasks/parapet.gen.runbooks_test.exs` - Modified: file-presence + content assertions for both new templates
- `lib/parapet/runbook.ex` - Modified: @doc :capability list updated to include all 5 valid atoms

## Decisions Made

- **D-13 accepted** — `runbook.ex` @doc accuracy fix (adding `:revert_feature_flag` and `:disable_metric_label` to the `@doc` atom list) is in scope. D-13's intent is no DSL/behavior changes, and a `@doc` string is neither. The stale 3-atom doc was left behind when Phase 24 widened `@valid_capabilities` to 5 atoms. Fixed here since this phase's two new templates introduce exactly those two atoms.
- Both new templates reference their capabilities by atom only — no `Code.ensure_loaded?`, no module alias — ensuring zero optional-dep coupling at template compile time.

## Deviations from Plan

None — plan executed exactly as written. The D-13 accuracy fix was explicitly scoped in the plan's task 1 action text as a discretionary in-scope nicety.

## Issues Encountered

None. `mix compile` clean; `mix test` 491/0 on first attempt.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All six JTBD-MAP prebuilt playbooks are now emitted by `mix parapet.gen.runbooks`
- Adopters running the generator get the full six-playbook catalog: two guidance-only (retry_storm, suppression_drift) + four capability-backed (stalled_executor, dead_letter, deploy_tied_incident, cardinality_blowout)
- Phase 28 (demo seed) can proceed: at least one runbook with a Preview-able + Confirm-able action is fully wired

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Work is pure EEx template authoring + generator/test edits. T-27-01 (guidance-only structural guarantee) verified: `grep -c 'capability:' suppression_drift.ex.eex` (comment-filtered) == 0.

## Self-Check: PASSED

- `priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex` exists: FOUND
- `priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex` exists: FOUND
- Commit 63a24bd exists: FOUND
- Commit 694299c exists: FOUND
- `mix test test/mix/tasks/parapet.gen.runbooks_test.exs`: 1 test, 0 failures
- `mix test` (full suite): 491 tests, 0 failures

---
*Phase: 27-prebuilt-playbooks*
*Completed: 2026-05-28*
