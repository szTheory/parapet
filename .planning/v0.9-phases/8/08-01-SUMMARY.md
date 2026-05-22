---
phase: 08-close-day-1-install-and-doctor-verification
plan: 01
status: completed
completed_at: 2026-05-21
---

# Phase 08 Plan 01 Summary

## Objective

Create the missing closure-grade Phase 4 verification artifact using fresh installer, doctor, docs, and fresh-host smoke evidence.

## Completed Work

1. Re-ran the targeted proof commands required by the plan: `mix test test/mix/tasks/parapet.install_test.exs`, `mix test test/mix/tasks/parapet.doctor_test.exs`, and the README/operator UI doc-contract grep.
2. Ran a fresh Phoenix host smoke lane in `/Users/jon/parapet_phase8_smoke`, captured the initial no-Oban compile failure, fixed the optional-worker compile-out and optional-module call sites in the library, then reran the smoke lane successfully through `mix parapet.install`, `mix parapet.doctor`, and `mix parapet.doctor cluster`.
3. Added `.planning/v0.9-phases/4/VERIFICATION.md` in the repo’s closure-grade format with observable truths, behavioral spot-checks, plan output checks, explicit requirement coverage, and a non-empty manual verification section.
4. Kept the proof honest about scope: core install by default, UI explicit opt-in only, host-owned auth preserved, and `mix parapet.doctor cluster` recorded as a runtime honesty/reporting surface rather than distributed-correctness proof.

## Verification

```bash
mix test test/mix/tasks/parapet.install_test.exs
mix test test/mix/tasks/parapet.doctor_test.exs
rg -n 'mix parapet\.install|mix parapet\.doctor|--with-ui|--skip-ui|cluster|does \*\*not\*\* provide its own authentication system' README.md docs/operator-ui.md
mix parapet.install
mix parapet.doctor
mix parapet.doctor cluster
```

Result: passed. The automated proof lanes were green, the fresh-host install summary completed after the optional-dependency fixes, and the doctor outputs preserved the intended warning/skip honesty boundaries.

## Deviations from Plan

### [Rule 1 - Bug] Optional no-Oban host compile leaks in the public Day-1 path

- Found during: fresh-host smoke lane
- Issue: a clean Phoenix host could not compile `:parapet` because optional Oban-backed modules and call sites leaked into the default install path.
- Fix: wrapped the optional Oban workers with `Code.ensure_loaded?(Oban.Worker)` and converted optional call sites in `lib/parapet/evidence.ex`, `lib/parapet/notifier.ex`, `lib/parapet/spine/alert_processor.ex`, and `lib/parapet/plug/metrics.ex` to guarded `apply/3` usage so no-Oban/no-OpenTelemetry hosts compile cleanly.
- Files modified: `lib/parapet/automation/executor.ex`, `lib/parapet/escalation/worker.ex`, `lib/parapet/notifier/oban_worker.ex`, `lib/parapet/evidence/archive_worker.ex`, `lib/parapet/probe/oban_scheduler.ex`, `lib/parapet/evidence.ex`, `lib/parapet/notifier.ex`, `lib/parapet/spine/alert_processor.ex`, `lib/parapet/plug/metrics.ex`
- Verification: reran the targeted install/doctor test files and reran the fresh-host smoke lane successfully.

## Self-Check: PASSED
