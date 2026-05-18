---
phase: 07
plan: 01
subsystem: runbooks
tags:
  - runbook
  - code-generation
  - schema
depends_on: []
requires: []
provides:
  - runbook_generator
  - capability_schema
affects:
  - Phase 7 host-owned modules
tech_stack:
  - Elixir
  - Igniter
key_files:
  created:
    - lib/mix/tasks/parapet.gen.runbooks.ex
    - priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex
    - priv/templates/parapet.gen.runbooks/dead_letter.ex.eex
    - priv/templates/parapet.gen.runbooks/provider_outage.ex.eex
    - priv/templates/parapet.gen.runbooks/callback_delay.ex.eex
    - test/mix/tasks/parapet.gen.runbooks_test.exs
  modified:
    - lib/parapet/runbook.ex
    - test/parapet/runbook_test.exs
decisions:
  - We defaulted preview_only and requires_preview to false for backward compatibility with existing simple mitigations.
  - The generator copies fixed templates to create host-owned modules instead of using dynamic workflow DSLs.
duration: 5 minutes
completed_date: 2026-05-18
---
# Phase 7 Plan 01: Host-Owned Runbook Catalog Summary

Built the fixed host-owned runbook catalog and enriched the runbook schema contract so Phase 7 has concrete generated modules to attach to incidents and render in the operator UI.

## Activities Performed
1. Extended `Parapet.Runbook.step/2` and `__runbook_schema__/0` to carry `kind`, `capability`, `target_kind`, `requires_preview`, `preview_only`, and `guidance`.
2. Created `Mix.Tasks.Parapet.Gen.Runbooks` as an Igniter generator to write host-owned module files.
3. Bound templates `StalledExecutor`, `DeadLetter`, `ProviderOutage`, and `CallbackDelay` to the new enriched schema.
4. Tied steps securely to the specific Phase 7 capability vocabulary: `:retry_async_item`, `:requeue_dead_letter`, and `:request_manual_provider_check`.
5. Wrote comprehensive tests for both the schema extraction and code generation.

## Deviations from Plan
None - plan executed exactly as written.

## Threat Flags
None.

## Known Stubs
None.

## Self-Check: PASSED