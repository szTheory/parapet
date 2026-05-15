# Phase 2 Decisions: Eval-Driven SLOs

**Date:** 2026-05-13
**Phase:** 2

This document captures the resolved architectural branches for Phase 2, derived from deep ecosystem research and the goal of providing an operator-grade, highly ergonomic SRE experience.

## 1. SLO Registry Architecture: Migrate to `Provider` Behaviour

**Decision:** We will deprecate the runtime `Application.put_env` registry pattern used in Phase 1 (`Parapet.SLO.define`) and migrate to a data-first `Provider` behaviour.

**Rationale:**
- **Idiomatic Elixir:** This closely matches successful libraries like PromEx, Telemetry.Metrics, and Oban.
- **Testability & Safety:** Runtime mutation of the global application environment introduces test pollution and obscures static analysis. A pure `slos/0` callback returning structs guarantees compile-time validation.
- **GitOps Ready:** It forces the user to define their SLOs explicitly in code (e.g., `MyApp.Observability.slos()`), avoiding "magic" and making the configuration highly auditable.

## 2. Telemetry to Metrics Bridge: `Parapet.Metrics.Scoria`

**Decision:** We will build a translation layer that strictly controls cardinality when moving from Scoria telemetry to Prometheus metrics.

**Rationale:**
- Scoria will emit `[:scoria, :eval, :completed]` telemetry.
- `Parapet.Metrics.Scoria` will attach to this event and translate it into a Prometheus counter (e.g., `scoria_evaluation_total`).
- **Cardinality Rules:** We will strictly enforce low-cardinality tags (e.g., `guardrail`, `passed`, `model_name`). High-cardinality data like `trace_id` or `prompt_hash` will be aggressively stripped to prevent TSDB bloat and cluster OOM events.

## 3. Burn Rate Alerting

**Decision:** We will generate multi-burn-rate PromQL alerting rules rather than naive static thresholds.

**Rationale:**
- Calculating simple `errors / total > X%` over a single window (like 5m) fails drastically on low-volume AI endpoints (causing severe alert fatigue).
- By adopting the Sloth/Pyrra (Google SRE handbook) methodology, `mix parapet.gen.prometheus` will generate multiple windows (5m, 30m, 1h, 6h, 3d) to reliably alert on rapid error-budget burns without false positives on isolated low-traffic failures.
