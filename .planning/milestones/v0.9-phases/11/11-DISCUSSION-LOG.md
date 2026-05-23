# Phase 11: harden-multi-node-proof-rerunnability - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `11-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-05-22
**Phase:** 11-harden-multi-node-proof-rerunnability
**Mode:** assumptions
**Areas analyzed:** Proof hierarchy, Smoke lane degradation, Verification reconciliation, Doctor and runtime posture

## Assumptions Presented

### Proof hierarchy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `SCALE-02` should stay anchored in the real Postgres-backed contention suite, with the `:peer` lane treated as a narrow canary rather than a required always-on proof surface. | Confident | `.planning/phases/05-multi-node-safety-verification/05-CONTEXT.md`, `test/support/concurrency_case.ex`, `test/support/concurrency_bootstrap.ex`, `test/parapet/automation/executor_concurrency_test.exs`, `.planning/v0.9-phases/5/VERIFICATION.md`, `.planning/v0.9-MILESTONE-AUDIT.md` |

### Smoke lane degradation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The failing `:peer` smoke lane should degrade to an explicit bounded skip or equivalent non-failing outcome when distributed Erlang is unavailable, instead of crashing on `Node.start/2`. | Confident | `test/parapet/automation/executor_cluster_smoke_test.exs`, `.planning/ROADMAP.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, live rerun of `mix test test/parapet/automation/executor_cluster_smoke_test.exs` on 2026-05-22 |

### Verification reconciliation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 5 verification artifacts should describe the peer-node lane as environment-conditional and rerunnable rather than as an unconditional passing proof lane in all environments. | Confident | `.planning/v0.9-phases/5/VERIFICATION.md`, `.planning/v0.9-phases/5/05-VALIDATION.md`, `.planning/REQUIREMENTS.md`, `.planning/v0.9-MILESTONE-AUDIT.md` |

### Doctor and runtime posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 11 should not widen `mix parapet.doctor` into claiming or proving distributed correctness; doctor remains advisory while executable proof stays in tests and verification docs. | Likely | `lib/mix/tasks/parapet.doctor.ex`, `test/mix/tasks/parapet.doctor_test.exs`, `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md`, `.planning/phases/05-multi-node-safety-verification/05-CONTEXT.md` |

## Corrections Made

None. The user accepted the assumptions as presented.

## Notes

- Confirmed locally that the current peer-canary test fails in this workspace with `:nodistribution` during `ensure_distributed_node!/0`.
- No external research was needed; the codebase and planning artifacts were sufficient to lock the phase decisions.
