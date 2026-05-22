# Phase 4 Plan: Operator UI Surfacing

## Plan Set

| Plan | Wave | Goal |
|------|------|------|
| `04-01` | 1 | Add the durable escalation command seam and worker-visible suppression or trigger semantics. |
| `04-02` | 2 | Derive escalation-aware workbench state and actor distinctions from durable evidence. |
| `04-03` | 3 | Update generated LiveView/UI templates and docs to surface the new contract. |

## Execution Order

1. `04-01` must land first because the UI cannot truthfully project or control escalation state without a durable backend seam.
2. `04-02` builds on that seam to provide the stable payload the generated UI will render.
3. `04-03` closes the loop in host-owned templates and docs once the backend contract is fixed.

## Requirement Coverage

- `UI-01` is covered directly by all three plans:
  - `04-01` for durable trigger and suppression behavior
  - `04-02` for escalation summary and system-actor projection
  - `04-03` for rendered escalation surfacing and bounded controls
