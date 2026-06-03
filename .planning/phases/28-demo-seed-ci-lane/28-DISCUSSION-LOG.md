# Phase 28: Demo Seed + CI Lane - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 28-demo-seed-ci-lane
**Mode:** assumptions
**Areas analyzed:** Demo Capability + Runbook Module; CI Scenarios (headless); Capabilities Agent Startup + Claim-Conflict Shape; `mix demo.reset` + Seed Replayability

## Assumptions Presented

### A. Demo Capability + Runbook Module
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Author `DemoApp.Runbooks.StalledExecutor` (`use Parapet.Runbook`) + `DemoApp.Recovery.RetryAsyncItem` (`use Parapet.Recovery`); mitigate step `kind: :capability, capability: :retry_async_item, requires_preview: true` | Confident | runbook.ex DSL; stalled_executor.ex.eex template; recovery.ex:56 execute contract |
| Reuse frozen-allowlist atom `:retry_async_item` — no new id | Confident | capabilities.ex:14-20 allowlist; :44-47 raises on non-allowlisted |
| Seed `runbook_data["module"]` must point at the compiled module (inline `"steps"` returns `:missing_runbook`) | Confident | operator.ex:1097-1113 `extract_module/1` (verified live) |
| `execute/2` mutates a `Parapet.Spine.ActionItem` (no new migration) | Confident | concurrency_bootstrap.ex:62-72 ActionItem columns; operator.ex:820 invocation |

### B. CI Scenarios — Headless ExUnit
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Drive all 4 scenarios as `:smoke`-tagged headless ExUnit via `Parapet.Operator` API (not LiveViewTest/Wallaby) | Confident | operator_detail_live.ex:103-166 (handlers are thin wrappers); ci.yml:139 `mix test --only smoke` |
| Scenario→tuple map: `{:ok,_}`+audit / `:preview_expired` / `:incident_resolved` / `{:conflicted,_}` | Confident | operator.ex:42-47, :767-769, :996-1000, :857-885, :939-949 |
| Existing `demo` job + `release_gate needs:[…demo]` satisfies criterion #3 | Confident | ci.yml:94-139, :141-142 |

### C. Capabilities Agent Startup + Claim-Conflict Shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Start `Parapet.Capabilities` in demo supervision tree + `Parapet.Recovery.attach([...])` at boot (not seeds-only) | Confident | application.ex:8-13 (no Capabilities child today); capabilities.ex:22-24 named singleton; operator.ex:722/:956 capability_unwired |
| Claim-conflict expressed sequentially (first wins, second `{:conflicted,_}`); do NOT reuse core ConcurrencyCase/ConcurrencyRepo | Likely | claim_service.ex:107-110/126-133 unique on_conflict; demo sandbox shares one connection; harness is core-only test/support |

### D. `mix demo.reset` + Seed Replayability
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `demo.reset` = `ecto.drop + ecto.create + ecto.migrate + seeds`; seeds stay always-insert | Confident | create_incident partial unique index on open correlation_key (concurrency_bootstrap.ex:46-48); mix.exs:51 setup alias to mirror |
| Add capability-backed incident as a new seed block; update trailing IO.puts | Confident | seeds.exs:8/:63/:86 existing 3-incident structure |

## Corrections Made

No corrections — user confirmed all assumptions ("Yes, proceed").

## External Research

None performed — codebase fully determined every decision (analyzer reported no research gaps).
</content>
