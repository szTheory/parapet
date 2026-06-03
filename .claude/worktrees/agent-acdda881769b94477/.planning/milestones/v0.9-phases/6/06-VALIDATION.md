# Phase 6: Verify Cardinality Protection Validation

## Nyquist Validation Coverage

| Requirement | Verification Method | Status |
|-------------|---------------------|--------|
| PERF-01.a | `06-01-PLAN.md` reruns `mix test test/mix/tasks/parapet.doctor_test.exs` and a live `mix parapet.doctor cardinality` advisory spot-check, then writes the bounded proof into `.planning/v0.9-phases/1/VERIFICATION.md`. | PLANNED |
| PERF-01.b | `06-01-PLAN.md` reruns `mix compile --force --warnings-as-errors` and `mix test test/parapet/metrics/validator_test.exs`, then writes the proof into `.planning/v0.9-phases/1/VERIFICATION.md`. | PLANNED |
| Phase-readiness reconciliation | `06-02-PLAN.md` updates `.planning/v0.9-phases/1/VALIDATION.md`, `.planning/REQUIREMENTS.md`, and the stale Phase 1 summary/UAT wording so local proof surfaces agree without overstating the live doctor result. | PLANNED |

## Gap Analysis

- Execution has not started yet, so all coverage is planned rather than covered.
- `mix parapet.doctor cardinality` is intentionally counted as an advisory spot-check only; a live `skip` result proves command availability and workspace posture, not requirement closure by itself.
- Phase 6 readiness requires both plan files and this validation artifact before execution so the Nyquist gate is explicit about what evidence must be rerun and what documentation must be reconciled.
