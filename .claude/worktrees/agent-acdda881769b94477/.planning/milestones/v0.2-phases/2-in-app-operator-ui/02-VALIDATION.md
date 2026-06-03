# Phase 2 Validation Map

## Scope

Phase 2 ships four execution plans and must satisfy `UI-01` through `UI-04` without leaving the operator workbench contract, transactional mutation semantics, or host-auth security seam ambiguous.

## Requirement Coverage

| Requirement | Planned Coverage | Primary Verification |
|-------------|------------------|----------------------|
| UI-01 | `02-01-PLAN.md`, `02-02-PLAN.md` | `mix test test/parapet/operator/workbench_contract_test.exs test/parapet/operator_test.exs test/mix/tasks/parapet.gen.ui_test.exs` |
| UI-02 | `02-01-PLAN.md`, `02-03-PLAN.md`, `02-04-PLAN.md` | `mix test test/parapet/operator/action_payload_test.exs test/parapet/operator_test.exs test/mix/tasks/parapet.doctor_test.exs test/parapet/operator_ui_integration_test.exs` |
| UI-03 | `02-02-PLAN.md`, `02-04-PLAN.md` | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs` |
| UI-04 | `02-02-PLAN.md`, `02-03-PLAN.md`, `02-04-PLAN.md` | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/mix/tasks/parapet.doctor_test.exs test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_integration_test.exs` |

## Plan-Level Validation

### 02-01 Operator Boundary, Workbench Contract, and Transactional Commands

- Verify the workbench derivation contract is explicit and tested.
  - Command: `mix test test/parapet/operator/workbench_contract_test.exs`
  - Expected: Severity, affected journey, correlated change, approval state, recommendation state, and resolved ordering derive from named timeline/audit conventions rather than nonexistent schema columns.
- Verify audited action payload validation.
  - Command: `mix test test/parapet/operator/action_payload_test.exs`
  - Expected: Missing `actor`, `reason`, or `correlation_id` is rejected before any mutation path runs.
- Verify operator reads and writes use the transaction seam.
  - Command: `mix test test/parapet/operator_test.exs`
  - Expected: Queue sort and detail payload shape match the workbench contract, and each mutating command routes incident update, timeline append, and audit write through one transactional boundary.

### 02-02 Generated LiveView Workbench

- Verify host-owned generator output.
  - Command: `mix test test/mix/tasks/parapet.gen.ui_test.exs`
  - Expected: Generated files live under the host app, router guidance stays inside authenticated host scope, the three-pane desktop workbench and mobile index/detail flow both exist, and the UI prefers evidence plus external links over embedded charts.

### 02-03 Doctor Checks and Operator UI Docs

- Verify secure mount detection.
  - Command: `mix test test/mix/tasks/parapet.doctor_test.exs`
  - Expected: `mix parapet.doctor` reports a distinct `operator_ui` result for secure and insecure router placements in both human and CI-oriented output.
- Verify published docs build cleanly.
  - Command: `mix docs`
  - Expected: `docs/operator-ui.md` and README references render without warnings and describe authenticated mounting, immutable factual records, and audited mutations accurately.

### 02-04 Dependency Posture and Host-Facing Integration

- Verify compile posture against the real dependency baseline.
  - Command: `mix test test/parapet/operator_ui_compile_out_test.exs`
  - Expected: The repo remains safe when Phoenix packages exist only transitively in `mix.lock`, and any direct UI coupling is explicitly guarded or opt-in.
- Verify end-to-end host flow.
  - Command: `mix test test/parapet/operator_ui_integration_test.exs`
  - Expected: Generated UI assumptions, `Parapet.Operator`, and `mix parapet.doctor` compose correctly without Parapet taking ownership of auth or router policy.

## Exit Criteria

- All commands above pass on the phase branch.
- No plan relies on undocumented derived fields or separate non-transactional evidence inserts for a single operator mutation.
- Roadmap plan inventory remains aligned with the actual Phase 2 artifact set.
