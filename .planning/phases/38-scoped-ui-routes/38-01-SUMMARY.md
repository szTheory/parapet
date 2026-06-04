---
phase: 38-scoped-ui-routes
plan: 01
subsystem: ui
tags: [phoenix-liveview, generated-ui, route-scoping, operator-ui]

requires:
  - phase: 38-scoped-ui-routes
    provides: Phase 38 route-scoping context, research, validation strategy, and UI contract
provides:
  - Generated OperatorLive and OperatorDetailLive base-path derivation from current LiveView URI
  - Generated OperatorComponents scoped route helpers for nav, queue, history, and incident detail links
  - Generated-source guards for route-producing surfaces and form-surface audit coverage
affects: [generated-operator-ui, host-route-scopes, UIROUTE-01, UIROUTE-02, UIROUTE-03]

tech-stack:
  added: []
  patterns:
    - Generated host-owned `operator_base_path` defaults to `/parapet` and derives nested scopes from URI paths through the final `parapet` segment
    - Route-producing generated components accept `operator_base_path` and build local links through scoped helper functions

key-files:
  created:
    - .planning/phases/38-scoped-ui-routes/38-01-SUMMARY.md
  modified:
    - priv/templates/parapet.gen.ui/operator_live.ex.eex
    - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - test/mix/tasks/parapet.gen.ui_test.exs
    - test/parapet/generated_operator_live_paging_test.exs

key-decisions:
  - "Keep scoped route ownership in generated host-owned LiveView/component code rather than adding a Parapet router abstraction."
  - "Derive the active Operator UI base path from the current LiveView URI path only, ignoring scheme, host, query, and user params as redirect targets."
  - "Treat generated forms as an audited surface only; no generated route-bearing form surfaces were found, so no form route handling was added."

patterns-established:
  - "Generated base-path seam: `@default_operator_base_path`, `operator_base_path/1`, and `operator_base_path_from_path/1` live in generated LiveViews."
  - "Component route helpers: `operator_path/1`, `operator_path/2`, `queue_item_path/3`, and `incident_detail_path/2` receive the active base path."
  - "Generated-source guards reject direct local `/parapet` route literals in route-producing surfaces while allowing default base-path declarations."

requirements-completed: [UIROUTE-01, UIROUTE-02, UIROUTE-03]

duration: 8min
completed: 2026-06-04
---

# Phase 38 Plan 01: Scoped Operator UI Route Helpers Summary

**Generated Operator UI routes now derive and thread a host-owned base path so `/parapet` and nested mounts like `/ops/parapet` render local navigation correctly.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-04T19:35:49Z
- **Completed:** 2026-06-04T19:43:37Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added generated `operator_base_path` helpers to `OperatorLive` and `OperatorDetailLive`, defaulting to `/parapet` and deriving scoped mounts from the current LiveView URI path.
- Threaded `operator_base_path` into route-producing generated components for nav, action-center returns, queue rows, pagination, history links, action rail history links, detail refreshes, and back links.
- Added generated-source and runtime render tests proving default `/parapet` and scoped `/ops/parapet` behavior while preserving external-link handling.
- Added route-surface guards for `push_patch`, `push_navigate`, `navigate`, `patch`, `href`, `queue_page_path`, `queue_item_path`, `history_path`, `incident_detail_path`, and `detail_back_path`.

## Task Commits

1. **Task 1: Add generated base-path derivation to LiveView templates** - `feced4d` (feat)
2. **Task 2: Thread scoped base path through route-producing components and runtime render tests** - `7726c8e` (feat)
3. **Task 3: Add route-surface and form-surface guards for generated templates** - `1023218` (test)

## Files Created/Modified

- `priv/templates/parapet.gen.ui/operator_live.ex.eex` - Derives `operator_base_path`, assigns it, and uses it for queue, history, patch, and pagination paths.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` - Derives `operator_base_path` for detail refresh navigation and back links.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` - Accepts `operator_base_path` in route-producing components and builds local route helpers from it.
- `test/mix/tasks/parapet.gen.ui_test.exs` - Pins generated source contracts, route-surface guards, external-link preservation, and no route-bearing generated forms.
- `test/parapet/generated_operator_live_paging_test.exs` - Adds runtime render proof for `/ops/parapet` response and history links.

## Decisions Made

- Kept route scope ownership in generated host-owned modules to preserve auth/router ownership and the compile-out boundary.
- Derived the base path by parsing `URI.parse(uri).path`, splitting path segments, and keeping segments through the final `parapet` segment.
- Preserved queue query behavior with `URI.encode_query/1`; scoped tests assert behavior without depending on query key order.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first RED test attempt was blocked by local Postgres reporting too many clients. Waiting for unrelated local DB pressure to drop allowed the planned tests to run without changing project code or dependencies.

## Form Audit

No generated route-bearing form surfaces found.

Command run:

```bash
rg -n '<form|form_for|phx-submit|action=' priv/templates/parapet.gen.ui/operator_live.ex.eex priv/templates/parapet.gen.ui/operator_detail_live.ex.eex priv/templates/parapet.gen.ui/operator_components.ex.eex || true
```

Result: no matches.

## Verification

- `mix test test/mix/tasks/parapet.gen.ui_test.exs` - 5 tests, 0 failures
- `mix test test/parapet/generated_operator_live_paging_test.exs` - 5 tests, 0 failures
- `mix test test/parapet/generated_operator_live_paging_test.exs test/mix/tasks/parapet.gen.ui_test.exs` - 10 tests, 0 failures
- Form audit command - no matches
- Dependency surface check - no `mix.exs` or `mix.lock` changes

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

None. The URI-derived base-path trust boundary was already covered by the plan threat model, and no new network endpoint, auth path, file access pattern, schema change, or dependency surface was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 02 can build on generated scoped route behavior. Generated UI local routes now have a single inspectable base-path seam, and tests guard both scoped rendering and accidental direct `/parapet` route literals.

## Self-Check: PASSED

- Found summary and all five plan-modified files.
- Found task commits `feced4d`, `7726c8e`, and `1023218`.

---
*Phase: 38-scoped-ui-routes*
*Completed: 2026-06-04*
