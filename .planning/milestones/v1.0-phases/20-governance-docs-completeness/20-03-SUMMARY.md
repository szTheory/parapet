---
phase: 20-governance-docs-completeness
plan: "03"
subsystem: docs/integrations
tags: [documentation, integration-guides, chimeway, mailglass, rindle, scoria]
dependency_graph:
  requires: []
  provides: [DOCS-01, DOCS-02, DOCS-03, DOCS-04]
  affects: [docs/integrations/chimeway.md, docs/integrations/mailglass.md, docs/integrations/rindle.md, docs/integrations/scoria.md]
tech_stack:
  added: []
  patterns: [sigra.md five-section integration guide template, rulestead.md no-pre-built-SLO pattern, rulestead.md reporter-wiring-required pattern]
key_files:
  created:
    - docs/integrations/chimeway.md
    - docs/integrations/mailglass.md
    - docs/integrations/rindle.md
    - docs/integrations/scoria.md
  modified: []
decisions:
  - "D-08: All four guides follow sigra.md five-section template exactly (title+intro, Prerequisites, What it unlocks, Activation, Config keys, Troubleshooting)"
  - "Content derived from integration module source (.ex files) — no event names invented from memory (T-20-03 threat mitigation)"
  - "Scoria guide covers both value props: Prometheus metrics AND evidence-spine (incidents/action items) per Pitfall 4"
  - "Rindle guide lists all seven [:rindle, :media, ...] events per Pitfall 5"
metrics:
  duration: "2 minutes"
  completed_date: "2026-05-25"
  tasks_completed: 2
  files_created: 4
---

# Phase 20 Plan 03: Integration Guides (Chimeway, Mailglass, Rindle, Scoria) Summary

Four missing integration guides authored under `docs/integrations/`, each matching the `sigra.md` five-section golden template, with content verified against integration module source code — closing DOCS-01 through DOCS-04.

## What Was Built

### Task 1: Chimeway, Mailglass, and Rindle guides (DOCS-01, DOCS-02, DOCS-03)
**Commit:** bc1636d

**docs/integrations/chimeway.md** — Chimeway notification delivery integration guide:
- Handler id `parapet-chimeway-delivery-events` attaching `[:chimeway, :event, :failed]`
- Documents `provider_feedback` vs `webhook_ingest` routing via `callback_delay?/1`
- References `Parapet.SLO.ChimewayDelivery` with three slices (`chimeway_provider_acceptance`, `chimeway_callback_confirmation`, `chimeway_callback_freshness`)
- Three troubleshooting Q&As: missing metrics (reporter wiring), duplicate attach conflict, event routing distinction

**docs/integrations/mailglass.md** — Mailglass email delivery integration guide:
- Handler id `parapet-mailglass-delivery` via `:telemetry.attach_many/4` for three events
- Documents three event families: `outbound` (send-stop), `provider_feedback` (reconcile-stop), `webhook_ingest` (webhook exception)
- References `Parapet.SLO.MailglassDelivery` with four slices
- Three troubleshooting Q&As: missing metrics, duplicate attach, `latency_ms` / `delay_ms` field behaviour

**docs/integrations/rindle.md** — Rindle media processing integration guide:
- Handler id `parapet-rindle-async` via `:telemetry.attach_many/4` for all seven events
- Lists all seven `[:rindle, :media, ...]` events including `reconciliation_delayed` (Pitfall 5)
- Documents three async families: `stage`, `backlog`, `callback`
- References `Parapet.SLO.RindleAsync` with five slices
- Three troubleshooting Q&As: duplicate attach, `pipeline_stage` string-to-atom normalization, `retry_state` inference from `attempt`/`attempt_number`

### Task 2: Scoria guide (DOCS-04)
**Commit:** 4246624

**docs/integrations/scoria.md** — Scoria AI/LLM integration guide:
- Covers both value propositions (Pitfall 4): Prometheus metrics AND evidence-spine integration
- Two Prometheus metrics: `scoria_evaluation_total` (tags: `guardrail`, `passed`, `model_name`) and `scoria_mcp_errors_total` (tags: `reason`, `tool_name`)
- Evidence-spine: config-deployed events create incidents with runbook data; stale workflows create action items; resumed workflows resolve them
- Reporter wiring instruction: `Parapet.Metrics.Scoria.metrics() ++ your_other_metrics()`
- Lists all 7 events and all 5 handler IDs
- No pre-built SLO provider; links to `docs/slo-authoring-guide.md`
- Cross-links `docs/telemetry.md` for additive-only stability rules
- Documents low-cardinality safe labels `[:model, :provider, :tool_name]`
- Three troubleshooting Q&As: missing metrics (reporter wiring), duplicate attach (5 handler IDs), high-cardinality metadata stripping

## Verification Results

```
All four guides exist: PASS (chimeway.md, mailglass.md, rindle.md, scoria.md)
Each has exactly 5 H2 sections: PASS (all four)
mix test: 352 tests, 0 failures
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all guides reference real module attributes and handler IDs verified against `.ex` source files.

## Threat Flags

None — this plan creates four static Markdown files. No runtime code, input, or network surface added.

## Self-Check: PASSED

- docs/integrations/chimeway.md: EXISTS
- docs/integrations/mailglass.md: EXISTS
- docs/integrations/rindle.md: EXISTS
- docs/integrations/scoria.md: EXISTS
- Commit bc1636d: EXISTS
- Commit 4246624: EXISTS
