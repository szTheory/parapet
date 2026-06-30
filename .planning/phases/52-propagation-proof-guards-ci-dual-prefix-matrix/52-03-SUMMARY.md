---
phase: 52-propagation-proof-guards-ci-dual-prefix-matrix
plan: "03"
subsystem: prefix-propagation-proof
tags:
  - schema-prefix
  - propagation-proof
  - tdd
  - ecto-query
  - to_sql
  - get_meta
  - PROP-01
  - PROP-03
dependency_graph:
  requires:
    - "52-01 (Parapet.Spine.Schema.__prefix__() single trustworthy source)"
  provides:
    - "Parapet.MCP.Server.timeline_for_correlation_query/1 — @doc false pure query builder extracted from inlined get_incident_timeline join"
    - "test/parapet/spine/prefix_propagation_test.exs — PROP-01/PROP-03 positive proof: to_sql FROM+JOIN + get_meta insert_all/Multi + six-schema equality"
  affects:
    - "52-04 (CI dual-prefix matrix validates these tests pass on both legs)"
tech_stack:
  added: []
  patterns:
    - "@doc false pure query builder extracted to separate function (mirrors circuit_breaker.ex execution_count_query/3)"
    - "to_sql(:all, repo, query) for spine-spine join SQL prefix assertion (FROM + JOIN tokens)"
    - "Ecto.get_meta(struct, :prefix) for insert_all and Ecto.Multi write path prefix assertion"
    - "Leg-aware @prefix module attribute baked at compile time from Schema.__prefix__()"
    - "TDD RED/GREEN: failing test committed before implementation"
key_files:
  created:
    - test/parapet/spine/prefix_propagation_test.exs
  modified:
    - lib/parapet/mcp/server.ex
    - test/parapet/mcp/server_test.exs
decisions:
  - "timeline_for_correlation_query/1 placed after all execute_tool/2 clauses to avoid Elixir 'clauses not grouped' compiler warning"
  - "execution_count_query requires valid UUID for incident_id at to_sql time — use Ecto.UUID.generate() in test"
  - "Public leg check requires MIX_ENV=test in both compile and test invocations, not just PARAPET_SCHEMA_PREFIX= (the test env _build is separate from dev)"
metrics:
  duration: "6 minutes"
  completed: "2026-06-30"
  tasks_completed: 2
  files_modified: 3
status: complete
---

# Phase 52 Plan 03: Extract timeline builder + PROP-01/PROP-03 Propagation Proof Summary

Extract `mcp/server.ex`'s inlined join into a `@doc false` pure query builder and prove the compiled prefix propagates across both spine-spine joins (to_sql FROM+JOIN), the insert_all path (get_meta on ActionClaim), the Ecto.Multi path (get_meta on Incident), and all six spine schemas (__schema__(:prefix) equality) — on both the parapet and public legs.

## What Was Built

### Task 1: Extract timeline_for_correlation_query/1 from mcp/server.ex (D-07)

- Extracted `from(t in TimelineEntry, join: i in Incident, on: t.incident_id == i.id, where: i.correlation_key == ^correlation_key)` (lines 33-44) into `@doc false def timeline_for_correlation_query(correlation_key)`
- `execute_tool("get_incident_timeline", ...)` now delegates to `repo.all(timeline_for_correlation_query(correlation_key))`
- Function placed after all `execute_tool/2` clauses to avoid Elixir compiler warning about ungrouped clauses
- Mirrors `lib/parapet/automation/circuit_breaker.ex`'s `execution_count_query/3` pattern exactly
- Zero public API / telemetry / call-site-semantics change: `@doc false`, same Ecto.Query flows to `repo.all`
- `mix verify.public_api` exits 0 (no public API drift)

### Task 2: Create prefix_propagation_test.exs (PROP-01/PROP-03)

- `to_sql(:all, ConcurrencyRepo, Server.timeline_for_correlation_query("key-123"))` — asserts `"parapet"."parapet_timeline_entries"` on FROM and `"parapet"."parapet_incidents"` on JOIN (parapet leg); refutes `"parapet"."parapet_` on public leg
- `to_sql(:all, ConcurrencyRepo, CircuitBreaker.execution_count_query(...))` — asserts `"parapet"."parapet_tool_audits"` on FROM and `"parapet"."parapet_timeline_entries"` on JOIN (parapet leg)
- `Evidence.create_incident(...)` via Ecto.Multi — asserts `Ecto.get_meta(incident, :prefix) == @prefix`
- `ClaimService.claim_action(...)` via `insert_all` — asserts `Ecto.get_meta(claim, :prefix) == @prefix`
- Six-schema `__schema__(:prefix) == Parapet.Spine.Schema.__prefix__()` — unconditional, passes on both legs
- Leg-aware: `@prefix Parapet.Spine.Schema.__prefix__()` baked at module top; negative bare-table assertion gated behind `if @prefix`
- Rides the REAL extracted builder (not inline rebuild) — RESEARCH Pitfall 2 avoided
- No `to_sql(:insert_all, ...)` calls — RESEARCH Pitfall 3 avoided
- Asserts stable qualified-identifier tokens, never whole-SQL equality (D-10)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] timeline_for_correlation_query/1 placement caused Elixir compiler warning**
- **Found during:** Task 1 implementation
- **Issue:** Placing `@doc false def timeline_for_correlation_query/1` between the first and second `execute_tool/2` clauses caused `warning: clauses with the same name and arity should be grouped together`
- **Fix:** Moved `timeline_for_correlation_query/1` to after all `execute_tool/2` clauses (after the `{:error, :unknown_tool}` catch-all clause), before the private helpers
- **Files modified:** `lib/parapet/mcp/server.ex`
- **Commit:** a9071bc

**2. [Rule 1 - Bug] execution_count_query requires valid UUID for incident_id**
- **Found during:** Task 2, first test run
- **Issue:** `CircuitBreaker.execution_count_query("inc-1", "step-1")` raised `Ecto.Query.CastError` because `"inc-1"` cannot be cast to `:binary_id` type
- **Fix:** Changed to `CircuitBreaker.execution_count_query(Ecto.UUID.generate(), "step-1")` — a valid UUID placeholder for `to_sql` parameter binding
- **Files modified:** `test/parapet/spine/prefix_propagation_test.exs`
- **Commit:** cf34d66 (in same commit)

**3. [Observation - Not a deviation] Public-leg compile requires MIX_ENV=test**
- The plan's acceptance criterion says `PARAPET_SCHEMA_PREFIX="" mix compile --force && PARAPET_SCHEMA_PREFIX="" mix test`. This works only for the `dev` env. The test suite uses `MIX_ENV=test` (separate `_build/test` artifact). The correct public-leg check is: `MIX_ENV=test PARAPET_SCHEMA_PREFIX="" mix compile --force && MIX_ENV=test PARAPET_SCHEMA_PREFIX="" mix test test/parapet/spine/prefix_propagation_test.exs` — confirmed exits 0.

### Pre-existing Failures (Out of Scope)

**`DocsPhase33Test` — `make up-auto` missing from demo README:** Pre-existing failure, present before Phase 52 changes. Logged in 52-01-SUMMARY.md. Not introduced by this plan.

## TDD Gate Compliance

- RED commit: `017eb98 test(52-03): add failing test for timeline_for_correlation_query/1 (TDD RED)` — test compiled with warning `Parapet.MCP.Server.timeline_for_correlation_query/1 is undefined or private`, 1 failure
- GREEN commit: `a9071bc feat(52-03): extract timeline_for_correlation_query/1 from mcp/server.ex (D-07)` — all 8 server tests pass
- Task 2 (new file): `cf34d66 feat(52-03): add PROP-01/PROP-03 prefix propagation proof tests` — all 5 propagation tests pass

Both RED/GREEN gates present.

## Threat Mitigations Applied

Per `<threat_model>` in PLAN.md:

- **T-52-05 (Tampering — spine↔spine joins + insert_all/Multi write paths):** Positive proof implemented: `to_sql` asserts the qualified `"parapet"."parapet_…"` on FROM and JOIN for both spine-spine join builders; `Ecto.get_meta` asserts the materialized prefix on the `insert_all` (ActionClaim) and Ecto.Multi (Incident) write paths. A regression that drops the prefix on any path will fail the test suite. Tests ride the REAL extracted builder (not inline rebuild), ensuring production call-site is pinned.
- **T-52-06 (Spoofing — test rebuilds query instead of pinning real site):** D-07 extraction + importing `Parapet.MCP.Server.timeline_for_correlation_query/1` ensures the test exercises the production call site. The grep acceptance check (`grep -c "timeline_for_correlation_query" test/parapet/spine/prefix_propagation_test.exs` returns 2) confirms the test calls the real builder.

## Known Stubs

None. All proof assertions exercise real production call sites; no placeholder or mock data for the prefix proof.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes introduced. The extracted `timeline_for_correlation_query/1` is `@doc false` and carries no new trust boundaries.

## Self-Check: PASSED

Verified files exist:
- FOUND: lib/parapet/mcp/server.ex
- FOUND: test/parapet/spine/prefix_propagation_test.exs
- FOUND: test/parapet/mcp/server_test.exs

Verified commits exist:
- FOUND: 017eb98 (TDD RED - server_test timeline_for_correlation_query)
- FOUND: a9071bc (feat - extract timeline_for_correlation_query/1)
- FOUND: cf34d66 (feat - prefix_propagation_test.exs)
