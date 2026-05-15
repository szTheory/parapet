# Phase 4 Validation

## Requirements Map

| Requirement ID | Description | Verification Step |
|----------------|-------------|-------------------|
| AI-HITL-01 | System monitors Scoria workflow approval pauses as durable HITL states, not generic queues. | `mix test test/parapet/spine/action_item_test.exs` |
| AI-HITL-02 | System can trigger alerts on stale or expiring workflow approval requests. | `mix test test/parapet/integrations/scoria_test.exs` |
| AI-HITL-03 | System extends the LiveView Operator UI to deep-link into Scoria's durable evidence and approval UI. | `mix test test/parapet/operator_ui_integration_test.exs` |
