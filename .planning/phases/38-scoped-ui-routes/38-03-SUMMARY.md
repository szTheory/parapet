---
phase: 38-scoped-ui-routes
plan: 03
subsystem: ui
tags: [phoenix-liveview, generated-ui, route-scoping, compile-out, public-api]

requires:
  - phase: 38-scoped-ui-routes
    provides: Generated and demo scoped Operator UI route behavior from Plans 01 and 02
provides:
  - Generator router guidance for default `/parapet` and nested `/ops/parapet` host-owned mounts
  - Focused operator docs for scoped mounting through generated `operator_base_path`
  - Static guards for compile-out, public API, dependency, router ownership, route emitters, and external links
affects: [generated-operator-ui, operator-ui-docs, host-route-scopes, UIROUTE-01, UIROUTE-02, UIROUTE-03]

tech-stack:
  added: []
  patterns:
    - Generated router guidance documents default and nested host-owned scopes without adding generator options
    - Compile-out tests read dependency, lockfile, stable API, and core source surfaces for ownership drift
    - Integration tests reject direct local `/parapet` route emitters across generated templates and demo copies

key-files:
  created:
    - .planning/phases/38-scoped-ui-routes/38-03-SUMMARY.md
  modified:
    - priv/templates/parapet.gen.ui/router_snippet.ex.eex
    - lib/mix/tasks/parapet.gen.ui.ex
    - docs/operator-ui.md
    - test/mix/tasks/parapet.gen.ui_test.exs
    - test/parapet/operator_ui_integration_test.exs
    - test/parapet/operator_ui_compile_out_test.exs

key-decisions:
  - "Document scoped mounting as host-owned router guidance rather than adding a `mix parapet.gen.ui` option."
  - "Treat existing Phoenix entries in `mix.lock` as transitive dependency evidence, while continuing to reject direct root `:phoenix` and `:phoenix_live_view` deps."
  - "Keep external links outside the operator base-path seam; only local Operator UI emitters are routed through scoped helpers."

patterns-established:
  - "Router guidance parity: template and fallback notice carry the same default `/parapet` and scoped `/ops/parapet` examples."
  - "Route-surface guard: generated and demo route emitters may not use direct local `/parapet` literals."
  - "Boundary guard: stable API and core source scans reject Parapet-owned router/helper surfaces."

requirements-completed: [UIROUTE-01, UIROUTE-02, UIROUTE-03]

duration: 4min
completed: 2026-06-04
---

# Phase 38 Plan 03: Scoped Route Guidance and Boundary Guards Summary

**Generated Operator UI guidance now documents default and nested host mounts, with tests proving scoped route support did not widen Parapet router, auth, API, or dependency ownership.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-04T20:25:50Z
- **Completed:** 2026-06-04T20:29:22Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments

- Added default `/parapet` and nested `/ops/parapet` examples to the generated router snippet and generator fallback notice.
- Updated operator UI docs with focused scoped-route mounting guidance, generated `operator_base_path` behavior, and explicit host-owned auth/router ownership.
- Added compile-out and integration guards for direct Phoenix/LiveView root deps, stable public API route-helper drift, Parapet-owned router modules, route emitter literals, and external-link handling.
- Ran the Phase 38 focused lane, formatting check, warnings-as-errors compile, full suite, dependency diff, and core router scan.

## Task Commits

1. **Task 1: Update router guidance and focused docs for nested host scopes** - `e98eca6` (docs)
2. **Task 2 RED: Add scoped route boundary guards** - `2613c91` (test)
3. **Task 2 GREEN: Align compile-out guard with scoped route helpers** - `8f5af50` (test)
4. **Task 3: Run Phase 38 focused lane, full suite, and no-scope-expansion checks** - `f300260` (style)

## Files Created/Modified

- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` - Adds default and `/ops` scoped host-owned route examples.
- `lib/mix/tasks/parapet.gen.ui.ex` - Keeps fallback router notice in parity with the template without changing CLI shape.
- `docs/operator-ui.md` - Documents default and scoped mounts plus generated local-link derivation.
- `test/mix/tasks/parapet.gen.ui_test.exs` - Pins generator notices and formatted scoped helper assertions.
- `test/parapet/operator_ui_integration_test.exs` - Pins docs/guidance, route emitter guards, and external-link behavior.
- `test/parapet/operator_ui_compile_out_test.exs` - Adds dependency, lockfile, core router, and stable API manifest guards.

## Decisions Made

- Kept scoped mounting as generated host-owned guidance instead of adding CLI flags or a Parapet router abstraction.
- Treated `mix.lock` Phoenix entries as existing transitive dependency evidence; the boundary that matters for UIROUTE-03 is no direct root `:phoenix` or `:phoenix_live_view` dependency.
- Left external links on `external_link_url` plus `target="_blank"` and outside `operator_base_path`, because only local Operator UI routes should be scoped.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated stale compile-out assertion for scoped detail redirects**
- **Found during:** Task 2 GREEN verification
- **Issue:** The compile-out test still expected the legacy literal `/parapet/incidents/#{id}` redirect after Phase 38 moved detail redirects through `incident_detail_path(socket.assigns.operator_base_path, id)`.
- **Fix:** Updated the assertion to require the scoped helper and reject the legacy literal redirect.
- **Files modified:** `test/parapet/operator_ui_compile_out_test.exs`
- **Verification:** `mix test test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_integration_test.exs` passed with 24 tests, 0 failures.
- **Committed in:** `8f5af50`

**2. [Rule 1 - Bug] Applied formatter cleanup after new test assertions**
- **Found during:** Task 3 verification
- **Issue:** `mix format --check-formatted` failed on long assertions in Task 1/2 test edits.
- **Fix:** Ran `mix format` on the touched test files and reran the full Task 3 verification command.
- **Files modified:** `test/mix/tasks/parapet.gen.ui_test.exs`, `test/parapet/operator_ui_integration_test.exs`
- **Verification:** Full Task 3 command passed, including `mix format --check-formatted`.
- **Committed in:** `f300260`

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes preserved the planned route-scoping and boundary guard behavior. No CLI/API, dependency, auth, runtime, or router ownership surface changed.

## Issues Encountered

- The Task 2 RED run failed on the stale legacy literal redirect assertion, which confirmed the compile-out guard needed to be aligned with the scoped helper contract before GREEN.

## TDD Gate Compliance

- RED gate present: `2613c91 test(38-03): add scoped route boundary guards`
- GREEN gate present after RED: `8f5af50 test(38-03): align compile-out guard with scoped route helpers`
- Refactor/style gate present after GREEN: `f300260 style(38-03): format scoped route guard tests`

## Verification

- `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs` - 21 tests, 0 failures
- `mix test test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_integration_test.exs` - 24 tests, 0 failures
- `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_demo_contract_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` - 39 tests, 0 failures
- `mix format --check-formatted` - passed
- `mix compile --warnings-as-errors` - passed
- `mix test` - 548 tests, 0 failures
- `git diff --exit-code -- mix.exs mix.lock priv/parapet/public_api_stable.json docs/stability.md` - passed with no diff
- `! rg -n 'use Phoenix.Router|use Plug.Router|defmodule Parapet.*Router' lib/parapet` - passed with no matches

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

None. The route guidance and guard additions were already covered by the plan threat model, and no new endpoint, auth path, file access pattern, schema change, dependency surface, or stable public API surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 38 is ready for verifier review. Generated scoped routing, demo scoped routing, docs guidance, compile-out boundaries, and no-scope-expansion checks are all test-pinned.

## Self-Check: PASSED

- Found summary file and all six plan-modified files.
- Found task commits `e98eca6`, `2613c91`, `8f5af50`, and `f300260`.
- Stub scan found no tracked placeholder patterns in files created or modified by this plan.

---
*Phase: 38-scoped-ui-routes*
*Completed: 2026-06-04*
