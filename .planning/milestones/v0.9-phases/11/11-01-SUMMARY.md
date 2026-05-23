---
phase: 11-harden-multi-node-proof-rerunnability
plan: 01
status: completed
completed_at: 2026-05-22
---

# Phase 11 Plan 01 Summary

## Objective

Harden the peer-node proof lane so it stays honest and rerunnable when distributed Erlang is unavailable, while leaving the DB-backed `SCALE-02` proof lane unchanged.

## Completed Work

1. Added `start_distributed_node_for_peer_canary/0` and `stop_distributed_node_for_peer_canary/1` to `test/support/concurrency_case.ex` so the smoke lane now distinguishes a usable local distributed node from an unsupported environment.
2. Mapped distribution bootstrap failures such as `:nodistribution` and `:econnrefused` to a truthful skip reason that states the peer-node canary was not exercised and that the DB-backed contention suite remains the closure-grade proof for `SCALE-02`.
3. Replaced the smoke test's direct `ensure_distributed_node!/0` bootstrap with `case start_distributed_node_for_peer_canary() do ... end`, preserving the existing one-winner local-plus-peer race assertions on the happy path.
4. Added an explicit skip branch to `test/parapet/automation/executor_cluster_smoke_test.exs` that verifies the bounded unsupported-environment wording and confirms no false `{:cluster_mitigated, _node}` signal is emitted when peer execution does not run.

## Verification

```bash
mix test test/parapet/automation/executor_concurrency_test.exs test/parapet/automation/executor_cluster_smoke_test.exs test/mix/tasks/parapet.doctor_test.exs
```

Result: passed (`12 tests, 0 failures`).

## Commits

- `b51fef2` — `test(phase-11): add peer canary distribution helper`
- `aa3bf4e` — `test(phase-11): make peer smoke canary skip honestly`

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED
