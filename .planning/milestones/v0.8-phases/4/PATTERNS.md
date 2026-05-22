# Phase 4: Operator UI Surfacing - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/operator.ex` | command boundary | audited mutation | `lib/parapet/operator.ex` existing acknowledge/preview paths | exact |
| `lib/parapet/escalation/worker.ex` | worker | durable gate | `lib/parapet/escalation/worker.ex` existing short-circuit pattern | exact |
| `lib/parapet/operator/workbench_contract.ex` | derived projection | evidence-to-view-model | `lib/parapet/operator/workbench_contract.ex` existing triage derivation | exact |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | LiveView | event-to-command | existing acknowledge/preview handlers | exact |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | SSR components | typed rendering | existing runbook/timeline components | role-match |
| `test/parapet/operator_test.exs` | command tests | repo-backed seam tests | current operator command and preview tests | exact |
| `test/parapet/operator/workbench_contract_test.exs` | derivation tests | pure struct projection | current triage derivation tests | exact |

## Pattern Assignments

### `lib/parapet/operator.ex` (command boundary, audited mutation)

**Analog:** existing acknowledge and preview/confirm command helpers

**Atomic operator-command pattern**
```elixir
Evidence.run_operator_command(
  incident_changeset: incident_changeset,
  timeline_attrs: timeline_attrs,
  audit_attrs: audit_attrs
)
```

Apply this exact seam to manual escalation trigger and suppression commands. New controls should update bounded incident state and append chronology atomically, not perform ad hoc repo writes.

---

### `lib/parapet/escalation/worker.ex` (worker, durable gate)

**Analog:** current state-based short-circuit branch

```elixir
%{state: state} when state in ["investigating", "resolved"] ->
  Parapet.Evidence.append_timeline(incident_id, %{
    type: "escalation_short_circuited",
    payload: %{"reason" => "already_#{state}"}
  })
```

Phase 4 should extend this pattern with suppression-aware short-circuiting and explicit timeline reasons like `suppressed_until` or `manual_trigger`.

---

### `lib/parapet/operator/workbench_contract.ex` (derived projection, evidence-to-view-model)

**Analog:** current triage-summary merge and chronology ordering

```elixir
sorted_entries = Enum.sort_by(entries, & &1.inserted_at, {:desc, DateTime})
snapshot = find_latest(sorted_entries, ["triage_snapshot"])
triage_payload = build_triage_payload(triage_summary, snapshot)
```

Follow the same pattern for escalation status: derive compact current-state facts from incident summary plus the latest relevant typed entries, keeping chronology authoritative.

---

### `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` (LiveView, event-to-command)

**Analog:** existing event handlers for `acknowledge`, `preview_mitigation`, and `confirm_mitigation`

```elixir
payload = %Parapet.Operator.ActionPayload{
  actor: "operator_ui",
  reason: "Acknowledged via UI",
  correlation_id: Ecto.UUID.generate(),
  action_type: :acknowledge
}
```

New escalation controls should reuse this event -> `ActionPayload` -> `Parapet.Operator` pattern with distinct action types and reasons.

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (SSR components, typed rendering)

**Analog:** existing runbook card and suspect-changes card

These components already implement card-based rendering and state badges. Reuse that structure for:
- escalation summary panel
- typed system-action timeline rows
- bounded manual control cluster below summary context

Do not continue the generic `inspect(entry.payload)` rendering path for new escalation events.

---

### `test/parapet/operator_test.exs` (command tests, repo-backed seam tests)

**Analog:** current tests for `incident_detail/1`, command transactions, preview, and confirm

The in-test `DummyRepo` plus `Ecto.Multi.to_list/1` reduction already exercise the operator seam without a database. Reuse that harness for new manual escalation APIs and incident summary updates.

---

### `test/parapet/operator/workbench_contract_test.exs` (derivation tests, pure projection)

**Analog:** current tests that combine `Incident` and `TimelineEntry` structs to assert durable derivation

Keep this file as the main proof surface for escalation-summary projection and actor-distinction hints because it avoids UI coupling and makes chronology rules explicit.

## Shared Patterns

### Explicit system identity

**Source:** `lib/parapet/automation/executor.ex`
```elixir
actor: "system:automation:executor"
```

Apply this exact identity consistently in derived actor classification and timeline rendering. Phase 4 should not infer system actions heuristically if the actor is already explicit.

### Generated UI stays host-owned

**Source:** `test/parapet/operator_ui_integration_test.exs`

The repo already treats generated UI templates as the canonical operator surface and tests them structurally. Phase 4 should continue editing templates and template tests rather than introducing Phoenix UI code under `lib/parapet/`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | - | - | Every planned change extends an existing seam directly. |
