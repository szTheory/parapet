---
phase: 38-scoped-ui-routes
verified: 2026-06-04T20:34:35Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
---

# Phase 38: Scoped UI Routes Verification Report

**Phase Goal:** Make generated Operator UI links, forms, redirects, and patches respect host-owned route scopes.
**Verified:** 2026-06-04T20:34:35Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Generated templates support default `/parapet` and nested `/ops/parapet` mounts. | VERIFIED | `operator_live.ex.eex` and `operator_detail_live.ex.eex` define `@default_operator_base_path "/parapet"`, derive `operator_base_path(uri)` in `handle_params/3`, and route local surfaces through `@operator_base_path`. `generated_operator_live_paging_test.exs` renders `/ops/parapet` and refutes unscoped `href="/parapet`. |
| 2 | Generated route helpers, links, redirects, forms, and LiveView patches respect a host-owned base path. | VERIFIED | `push_patch` calls use `queue_path(socket, ...)`; `push_navigate` calls use `incident_detail_path(socket.assigns.operator_base_path, id)`; HEEx `patch`, `navigate`, and `href` local surfaces use `queue_page_path`, `history_path`, `detail_back_path`, `operator_path`, `queue_item_path`, or `incident_detail_path` with `operator_base_path`. Form audit found no generated route-bearing forms. |
| 3 | Route helpers live in generated host-owned modules, not Parapet-owned router framework. | VERIFIED | Helpers are private in generated LiveView/component templates and demo copies. Core scan found no `use Phoenix.Router`, `use Plug.Router`, or `defmodule Parapet.*Router` under `lib/parapet`. |
| 4 | Demo app generated-copy tests prove template/demo synchronization. | VERIFIED | Demo copied LiveViews/components mirror `operator_base_path` helper shape, `router.ex` contains default and `/ops` scopes, `operator_ui_demo_contract_test.exs` and `operator_ui_integration_test.exs` assert template/demo helper parity and route maps. |
| 5 | Demo proof covers default `/parapet` and scoped `/ops/parapet`. | VERIFIED | `examples/demo_app/test/demo_app/operator_smoke_test.exs` covers `/parapet`, `/parapet/actions`, `/parapet/history`, detail routes, plus `/ops/parapet`, `/ops/parapet/actions`, `/ops/parapet/history`, and scoped detail routes. Demo smoke command passed, 10 tests. |
| 6 | Router guidance documents default and nested host-owned scopes without changing router ownership. | VERIFIED | `router_snippet.ex.eex`, fallback guidance in `lib/mix/tasks/parapet.gen.ui.ex`, and `docs/operator-ui.md` include default `/parapet`, scoped `/ops/parapet`, `scope "/ops"`, and host-owned auth/router language. |
| 7 | Route changes do not alter auth ownership, router ownership, public API tier, or dependency surface. | VERIFIED | `git diff -- mix.exs mix.lock priv/parapet/public_api_stable.json docs/stability.md` had no diff. Compile-out tests scan direct dependencies, core router definitions, and stable API manifest route-helper drift. |
| 8 | External links are not rewritten through the Operator base path. | VERIFIED | Component templates and demo copies preserve `external_link_url(...)`, `href={@url}`, `target="_blank"`, and integration tests assert external surfaces do not use `operator_base_path`. |
| 9 | Phase implementation has no blocker anti-patterns or unresolved human-only checks. | VERIFIED | Anti-pattern scan over modified implementation/test/doc surfaces found no `TBD`, `FIXME`, `XXX`, TODO/HACK/placeholder, empty implementation, or console-only patterns. Validation strategy states all phase behaviors have automated verification; no human-only checks remain. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | Scoped base path derivation and queue/history route helpers | VERIFIED | 584 lines; contains `operator_base_path`, `queue_page_path`, `queue_path`, `history_path`; wired from `handle_params/3`, `push_patch`, and render assigns. |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | Scoped detail refresh and back navigation | VERIFIED | 297 lines; contains `operator_base_path`, `incident_detail_path`, `detail_back_path`; wired into `push_navigate` and detail render. |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | Scoped nav, queue, history, detail, and action-rail links | VERIFIED | 1582 lines; route-producing components accept `operator_base_path`; external links remain external. |
| `priv/templates/parapet.gen.ui/router_snippet.ex.eex` | Generated default and nested route guidance | VERIFIED | Contains default `/parapet`, scoped `/ops/parapet`, `scope "/ops"`, and host auth warning. |
| `lib/mix/tasks/parapet.gen.ui.ex` | Generator fallback notice matching route guidance | VERIFIED | Fallback guidance includes same default and nested examples; no new CLI option or public API. |
| `docs/operator-ui.md` | Focused scoped mounting docs | VERIFIED | Documents default/scoped mounts, generated `operator_base_path`, and host-owned auth/router control. |
| Demo copied LiveViews/components/router | Runnable demo route proof | VERIFIED | Demo LiveViews/components mirror scoped helper shape; router contains default scope plus `/ops` scope and `:parapet_operator_scoped` live session. |
| Tests listed in Phase 38 plans | Contract, render, smoke, compile-out, and integration proof | VERIFIED | Focused root lane passed 39 tests; demo smoke passed 10 tests; full suite passed 548 tests. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `handle_params/3` URI | `socket.assigns.operator_base_path` | `operator_base_path(uri)` | WIRED | Present in generated and demo `OperatorLive` and `OperatorDetailLive`; default assigned in `mount/3`, current URI assigned in `handle_params/3`. |
| `OperatorLive`/`OperatorDetailLive` render | `OperatorComponents` | `operator_base_path={@operator_base_path}` | WIRED | Nav, action center, incident list, and action rail receive the assign in generated templates and demo copies. |
| Queue params | Scoped patch hrefs | `URI.encode_query/1` | WIRED | `queue_path/3` and `queue_item_path/3` merge filtered params and append `URI.encode_query(params)` under `operator_base_path`. |
| Generated templates | Demo copied LiveViews | Same helper identifiers | WIRED | Integration/demo contract tests assert matching `operator_base_path`, `queue_page_path`, `history_path`, `detail_back_path`, `operator_path`, `queue_item_path`, and `incident_detail_path` identifiers. |
| Demo router | Demo smoke tests | `/ops` scope around `/parapet` route map | WIRED | Router has `scope "/ops"` and `live_session :parapet_operator_scoped`; smoke tests request scoped response/actions/history/detail URLs. |
| Router snippet template | Generator fallback notice | Same default and `/ops` examples | WIRED | Both surfaces include default `/parapet`, scoped `/ops/parapet`, and `scope "/ops"` examples. |
| Compile-out tests | `mix.exs`, core files, stable manifest | Static dependency/API assertions | WIRED | `operator_ui_compile_out_test.exs` asserts no direct Phoenix/LiveView deps, no Parapet-owned router modules, and no route-helper entries in `public_api_stable.json`. |

Note: `gsd-sdk query verify.key-links` reported "Source file not found" for natural-language `from` fields in the plan frontmatter. Manual key-link verification above resolves those links against the concrete files.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `operator_live.ex.eex` | `operator_base_path` | Current LiveView URI in `handle_params/3` parsed by `URI.parse(uri).path`; fallback default in `mount/3` | Yes | FLOWING |
| `operator_live.ex.eex` | `queue_params` / scoped queue paths | `queue_params(params, page_mode)` plus `visible_queue_params`; `queue_path/3` uses active `operator_base_path` and `URI.encode_query/1` | Yes | FLOWING |
| `operator_detail_live.ex.eex` | Detail back/refresh path | `operator_base_path(uri)` assigned in `handle_params/3`; `incident_detail_path/2` and `detail_back_path/2` use it | Yes | FLOWING |
| `operator_components.ex.eex` | Local link base path | `operator_base_path` attr passed from parent LiveViews, defaulting to `/parapet` | Yes | FLOWING |
| Demo copied files | Scoped route rendering | Same generated helper shape plus demo `/ops` router scope | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Focused Phase 38 route contracts pass | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_demo_contract_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` | 39 tests, 0 failures | PASS |
| Demo default and scoped routes are runnable | `cd examples/demo_app && MIX_ENV=test mix test test/demo_app/operator_smoke_test.exs` | 10 tests, 0 failures | PASS |
| Formatting is clean | `mix format --check-formatted` | exit 0 | PASS |
| Warnings-as-errors compile is clean | `mix compile --warnings-as-errors` | exit 0 | PASS |
| Full suite regression | `mix test` | 548 tests, 0 failures | PASS |
| Form route audit | `rg -n '<form|form_for|phx-submit|action=' priv/templates/parapet.gen.ui/operator_live.ex.eex priv/templates/parapet.gen.ui/operator_detail_live.ex.eex priv/templates/parapet.gen.ui/operator_components.ex.eex || true` | no matches | PASS |
| Boundary diff guard | `git diff -- mix.exs mix.lock priv/parapet/public_api_stable.json docs/stability.md` | no diff | PASS |
| Core router ownership guard | `rg -n 'use Phoenix.Router|use Plug.Router|defmodule Parapet.*Router' lib/parapet` | no matches | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| Conventional probes | `find scripts -path '*/tests/probe-*.sh' -type f` | No Phase 38 probes declared or discovered | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| UIROUTE-01 | 38-01, 38-02, 38-03 | Generated Operator UI route helpers, links, redirects, forms, and LiveView patches respect a host-owned base path when mounted under a non-default scope such as `/ops/parapet`. | SATISFIED | Generated and demo LiveViews derive `operator_base_path` from URI; route-producing helpers consume it; scoped render tests and route-surface guards pass. |
| UIROUTE-02 | 38-01, 38-02, 38-03 | The generated template and demo app copy stay synchronized and test-pinned for both default `/parapet` and scoped route mounting. | SATISFIED | Demo copies mirror helper shape; demo contract/integration tests assert drift guards; demo smoke proves default and scoped routes. |
| UIROUTE-03 | 38-01, 38-02, 38-03 | Scoped-route support does not change Parapet's auth ownership, router ownership, public API stability tier, or dependency surface. | SATISFIED | No dependency/stable-manifest/stability-doc diff; core router scan empty; compile-out tests cover direct deps, stable API, and router ownership. |

No orphaned Phase 38 requirements found: `.planning/REQUIREMENTS.md` maps only UIROUTE-01, UIROUTE-02, and UIROUTE-03 to Phase 38, and all three are declared by every Phase 38 plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| n/a | n/a | none | n/a | Anti-pattern scan over Phase 38 implementation/test/doc surfaces found no blocker or warning markers. |

### Human Verification Required

None. The Phase 38 validation strategy states all phase behaviors have automated verification, and the verifier found no remaining visual/user-flow/external-service uncertainty that blocks pass.

### Gaps Summary

No gaps found. Phase 38 satisfies the roadmap success criteria, UIROUTE requirements, locked context decisions, and plan must-haves.

---

_Verified: 2026-06-04T20:34:35Z_
_Verifier: the agent (gsd-verifier)_
