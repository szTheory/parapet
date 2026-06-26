---
phase: 48-pages-flows-microcopy
plan: 03
subsystem: ui
tags: [phoenix, liveview, eex, operator, not-found, page-title, skeleton, a11y, microcopy, demo-mirror]

# Dependency graph
requires:
  - phase: 48-pages-flows-microcopy
    provides: "Wave-2 component layer (48-02) — incident_not_found/1, incident_summary heading_level prop, list_skeleton/1, operator_nav h1->p demotion"
  - phase: 48-pages-flows-microcopy
    provides: "Wave-1 RED scaffold (48-01) — the shell/service-scoped source-string + rendered-state gates this plan flips green"
provides:
  - "Parapet.Operator.fetch_incident_detail/1 :: {:ok, detail} | {:error, :not_found} — additive failure-tolerant helper (D-01)"
  - "Parapet.Operator.build_detail/1 (private) — shared workbench body so incident_detail/1 + fetch_incident_detail/1 reuse it without duplication"
  - "Detail LiveView in-page not-found panel wired through mount/handle_params + all 6 handle_event refresh sites (D-01/D-02), single h1 via heading_level=h1 (D-06), :page_title (D-07), nav aria-label=Incident context landmark (D-08), 6 D-13 flash strings + harmonized ack-success (no inspect leaks)"
  - "Shell LiveView per-page h1 (Response sr-only / Actions visible / History promoted), page_title/2 + :page_title assign (D-07), Actions/History wrapped in connected?-keyed skeleton with @socket_connected-gated empties (D-09/D-10), D-15 acknowledge/resolve flash rewrites"
  - "router_snippet catch-all-last regression comment (D-04/FLOW-04); demo layout runtime <.live_title> (D-07); one host-install-guide :page_title sentence"
affects: [48-04, 49-stress-fixtures]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Additive failure-path service helper: Ecto.UUID.cast precheck + Repo.get nil-guard collapses both binary_id stale-link exception classes (CastError + NoResultsError) to {:error, :not_found}; never rescue infra (D-01/D-03)"
    - "Detail not-found is an in-page render branch (no push_navigate) keeping operator nav + back-link chrome; @requested_id passed as a bare component prop (escaped text only, never an attribute) (T-48-01)"
    - "Connected?-keyed skeleton wraps each list at the shell layer; empty states only exist inside the connected branch so no empty-during-load lie (D-09/D-10)"
    - "Demo-mirror parity by assertion-pairing: every .eex edit lands in examples/demo_app/.../*.ex in the same task"
    - "Stale pre-existing source-string/render pins updated (not deleted) to track the planned D-01/D-06 behavior change (deviation Rule 1)"

key-files:
  created: []
  modified:
    - lib/parapet/operator.ex
    - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex
    - priv/templates/parapet.gen.ui/operator_live.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex
    - priv/templates/parapet.gen.ui/router_snippet.ex.eex
    - examples/demo_app/lib/demo_app_web/components/layouts.ex
    - docs/operator-ui.md
    - test/parapet/operator_ui_integration_test.exs
    - examples/demo_app/test/demo_app/operator_smoke_test.exs
    - test/parapet/operator_ui_compile_out_test.exs
    - test/parapet/generated_operator_live_paging_test.exs
    - test/mix/tasks/parapet.gen.ui_test.exs
    - test/mix/tasks/parapet.gen.ui_shift_left_test.exs

key-decisions:
  - "fetch_incident_detail/1 added additively; incident_detail/1 keeps its signature, @doc since: 1.0.0, and success-shape (now delegates to the shared private build_detail/1) — no breaking change, no major bump (D-01)"
  - "All 4 confirm_runbook_step refresh branches (:ok/:short_circuited/:conflicted/forward-compat other) plus trigger/suppress/preview route through one private refresh_incident_detail/2 that degrades to not-found if the incident vanished mid-action (D-01/D-02)"
  - "Rule 1: handle_params hardcoded socket_connected: true, defeating the skeleton + empty-gate in the dead render; switched to connected?(socket) so the disconnected skeleton and the empty-during-load gate are honest (D-09/D-10)"
  - "Rule 1: 6 stale pre-existing test pins updated to the planned D-01/D-06 behavior (incident_detail(id) -> fetch_incident_detail(id); incident_summary heading_level=h1; paging test socket marked connected via transport_pid; history smoke tests assert the connected render) — intent preserved, not deleted"
  - "Rule 1: the 48-01 RED rendered-copy assert matched a literal apostrophe; HEEx escapes it to &#39; in render/1 output, so @not_found_copy was corrected to the escaped form (a literal-apostrophe match can never pass against rendered HTML)"

patterns-established:
  - "Wave-3 green: shell + service edits land with byte-parity demo mirrors, flipping the remaining 5 lib + 6 demo RED gates green without churning previously-green tests beyond intent-preserving Rule-1 pin updates"

requirements-completed: [FLOW-01, FLOW-02, FLOW-03, FLOW-04, COPY-03, COPY-05, A11Y-06]

coverage:
  - id: D1
    description: "Parapet.Operator.fetch_incident_detail/1 returns {:error, :not_found} for malformed + missing UUIDs and {:ok, detail} for existing incidents; incident_detail/1 contract unchanged; shared private build_detail/1 (D-01/D-03)"
    requirement: "FLOW-03"
    verification:
      - kind: integration
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FLOW-03: detail with unknown UUID renders the not-found panel in-page (and the malformed-id sibling) — both green"
        status: pass
      - kind: command
        ref: "mix test test/parapet/ — lib suite green except the 2 pre-existing unrelated failures (DocsPhase33/ExecutorClusterSmoke)"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D2
    description: "Detail not-found wired through mount/handle_params + all 6 handle_event refresh sites; in-page panel with no push_navigate; single h1 via heading_level=h1; :page_title; nav aria-label=Incident context (D-01/D-02/D-06/D-07/D-08)"
    requirement: "FLOW-03"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_integration_test.exs#A11Y-06: main id + nav landmarks + Incident context nav present (source) — green; examples/demo_app/test/demo_app/operator_smoke_test.exs#A11Y-06 connected detail landmarks + FLOW-02 detail single-h1 + detail page_title — green"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D3
    description: "6 D-13 detail flash strings verbatim + harmonized ack-success; no #{inspect(reason)} in any user-facing flash (inspect lives only inside Logger calls) (D-13/D-15)"
    requirement: "COPY-03"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_integration_test.exs#COPY-03: the 10+1 re-authored microcopy strings + COPY/voice: no inspect( inside user-facing flash strings — both green"
        status: pass
      - kind: other
        ref: "grep: put_flash(...inspect(...) returns 0 matches in both detail templates; inspect(reason) appears only inside Logger.error calls"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D4
    description: "Shell per-page single h1 (Response/Actions/History) + :page_title via page_title/2; cockpit incident_summary stays h2 (D-06/D-07)"
    requirement: "FLOW-02"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_integration_test.exs#FLOW-02 :page_title source — green; examples/demo_app/test/demo_app/operator_smoke_test.exs#FLOW-02 each page renders exactly one h1 + page_title(view) per page — green"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D5
    description: "Actions/History wrapped in the connected?-keyed skeleton; empty states gated on @socket_connected; handle_params socket_connected bug fixed (D-09/D-10)"
    requirement: "FLOW-03"
    verification:
      - kind: integration
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#FLOW-03 disconnected skeleton on all list pages + empty-state-only-on-connected gates — both green"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D6
    description: "router_snippet keeps /parapet/:id catch-all LAST with the regression comment; demo layout renders runtime <.live_title>; host-doc :page_title sentence (D-04/D-07)"
    requirement: "FLOW-04"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_integration_test.exs#FLOW-04 route ordering + catch-all-last comment — green; demo layout <.live_title suffix=' · Parapet'>{assigns[:page_title] || 'Demo App'} present"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D7
    description: "T-48-01 mitigation holds: @requested_id passed only as a component prop rendered as escaped text, never interpolated into href/navigate/patch/src/action/id attributes"
    requirement: "A11Y-06"
    verification:
      - kind: other
        ref: "grep: (href|navigate|patch|src|action)={...requested_id...} returns 0 matches in both detail templates"
        status: pass
    human_judgment: false
    rationale: ""

# Metrics
duration: 18min
completed: 2026-06-26
status: complete
---

# Phase 48 Plan 03: Wave-3 Shell + Service Green Summary

**Added the additive failure-tolerant `fetch_incident_detail/1` (shared `build_detail/1`), wired the in-page not-found panel through the detail LiveView mount + all 6 refresh sites with its single h1 / :page_title / Incident-context nav landmark / 6 D-13 flash rewrites (no inspect leaks), gave each shell page exactly one h1 + a :page_title with connected?-keyed skeletons and honest empty-during-load gates, locked the route ordering with a regression comment, and patched the demo layout for runtime titles — flipping the remaining 5 lib + 6 demo RED gates green with byte-parity demo mirrors.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-26T21:20:25Z
- **Completed:** 2026-06-26T21:39:09Z
- **Tasks:** 3
- **Files modified:** 14 (1 service + 2 detail LiveViews + 2 shell LiveViews + 1 router snippet + 1 demo layout + 1 host doc + 6 test files)

## Accomplishments

- **Service (D-01/D-03):** added `Parapet.Operator.fetch_incident_detail/1 :: {:ok, detail} | {:error, :not_found}` — `Ecto.UUID.cast/1` precheck collapses the `CastError` class (malformed ids) and `Evidence.repo().get/2` + nil-guard collapses the `NoResultsError` class (missing UUIDs); extracted the shared post-fetch body into private `build_detail/1` so `incident_detail/1` reuses it with its signature/`@doc since: "1.0.0"`/success-shape unchanged. No `DBConnection`/infra rescue (outages stay the host's 5xx).
- **Detail not-found wiring (D-01/D-02):** `mount`/`handle_params` and all 6 `handle_event` refresh sites route through `fetch_incident_detail/1` via private `assign_incident_detail/2` + `refresh_incident_detail/2`, degrading to the in-page `<.incident_not_found>` panel (inside `main#parapet-main`, keeping operator nav + back-link chrome) with **no `push_navigate`**.
- **Detail semantics:** `incident_summary` passed `heading_level="h1"` (single descriptive h1, D-06); private `page_title/2` + `:page_title` assign (`Incident: <title>` / `Incident detail`, D-07); back-link/context strip wrapped in `<nav aria-label="Incident context">` (D-08).
- **Detail microcopy (D-13/D-15):** the 6 detail flash strings + harmonized ack-success applied verbatim; every `#{inspect(reason)}` dropped from user-facing flashes and moved into `Logger.error` calls only.
- **Shell per-page h1 (D-06):** Response sr-only `Active response`; Actions visible `Action queue`; History `<h2>`→`<h1>` (`Review resolved incidents`); the Response cockpit `incident_summary` stays default `<h2>`.
- **Shell titles + skeleton (D-07/D-09/D-10):** private `page_title/2` (`:index`/`:actions`/`:history`) + `:page_title` assign; Actions and History lists wrapped in the same connected?-keyed skeleton (`animate-pulse` + `aria-busy` + three `h-16` rows, no literal "Loading"); empty states now live inside the connected branch so none renders during the disconnected load.
- **Shell flash voice (D-15):** rewrote the `operator_live` acknowledge/resolve flashes (dropped `successfully` / `Failed to`) to the evidence-first, state-unchanged-first register.
- **Router + layout + doc (D-04/D-07):** added the explanatory `/parapet/:id` catch-all-last regression comment to both scopes of `router_snippet.ex.eex`; patched the demo `layouts.ex` to `<.live_title suffix=" · Parapet">{assigns[:page_title] || "Demo App"}</.live_title>`; added one host-install-guide sentence about `:page_title` / `<.live_title>` (no host root layout auto-patch).
- **Demo-mirror parity:** every `.eex` edit mirrored into `examples/demo_app/.../operator_detail_live.ex` and `operator_live.ex`; the router-snippet edit paired with the (already-commented) demo router; `layouts.ex` is demo-only.

## 48-01 Assertions Flipped GREEN (shell/service-scoped)

| Gate | Layer | REQ | Now |
|---|---|---|---|
| COPY-03: the 6 detail flash strings + ack-success verbatim | lib source-string | COPY-03 | **GREEN** |
| COPY/voice: no inspect( in flashes; no banned constructions | lib source-string | COPY/D-15 | **GREEN** |
| FLOW-02: operator_live + operator_detail assign :page_title via page_title/ | lib source-string | FLOW-02 | **GREEN** |
| FLOW-04: router catch-all-last explanatory comment | lib source-string | FLOW-04 | **GREEN** |
| A11Y-06: detail nav[aria-label="Incident context"] (source) | lib source-string | A11Y-06 | **GREEN** |
| FLOW-02: each page renders exactly one h1 (Response/Actions/History/detail/queue-selected) | demo rendered | FLOW-02 | **GREEN** |
| FLOW-03: unknown-UUID detail renders the in-page not-found panel | demo rendered | FLOW-03 | **GREEN** |
| FLOW-03: malformed /parapet/123 renders not-found (not a 500) | demo rendered | FLOW-03 | **GREEN** |
| FLOW-02: page_title(view) per page | demo rendered | FLOW-02 | **GREEN** |
| FLOW-03: uniform disconnected skeleton on Actions/History | demo rendered | FLOW-03 | **GREEN** |
| FLOW-03: empty state only on connected render, not during load | demo rendered | FLOW-03 | **GREEN** |

All 12 Phase-48 RED assertions (6 lib + 6 demo) are now green across 48-02 + 48-03.

## Test Evidence

- `mix compile --warnings-as-errors` (lib root): **clean** (exit 0).
- `mix test test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_contrast_test.exs`: **33 tests, 0 failures.**
- `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs`: **17 tests, 0 failures.**
- `cd examples/demo_app && mix test` (full demo suite): **25 tests, 0 failures.**
- `mix test` (full lib suite): **570 tests, 2 failures** — both pre-existing and unrelated (`DocsPhase33Test`, `ExecutorClusterSmokeTest`), already logged in `deferred-items.md` and confirmed not to reference any operator/`fetch_incident_detail`/`page_title`/`incident_not_found` surface.
- **No-inspect-leak (D-15):** `grep -E "put_flash\([^)]*inspect\("` → 0 matches in both detail templates; `inspect(reason)` appears only inside `Logger.error` calls.
- **No-infra-rescue (D-03):** `fetch_incident_detail/1` only handles `Ecto.UUID.cast/1` `:error` and `Repo.get/2` `nil`; no `rescue` of `DBConnection`/infra exceptions.
- **Escape (T-48-01):** `grep -E "(href|navigate|patch|src|action)={...requested_id...}"` → 0 matches; `@requested_id` is only a component prop rendered as escaped text.

## Demo-Mirror + Router Parity

- `operator_detail_live.ex.eex` ↔ `examples/demo_app/.../operator_detail_live.ex`: identical edits (mount/handle_params/6 refresh sites/render branch/nav wrap/heading_level/page_title/flash strings), differing only in module/repo names + EEx escaping.
- `operator_live.ex.eex` ↔ `examples/demo_app/.../operator_live.ex`: identical edits (per-page h1/page_title/2/skeleton wraps/socket_connected fix/flash voice).
- `router_snippet.ex.eex` catch-all-last comment paired with the demo router (which already carried a `catch-all` ordering comment from a prior phase).
- `layouts.ex` is demo-only (no host root layout patched, per D-07).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] handle_params hard-coded socket_connected: true, defeating the skeleton + empty-during-load gate**
- **Found during:** Task 3 (skeleton + empty-gate demo asserts)
- **Issue:** `operator_live` `handle_params` assigned `socket_connected: true` unconditionally, overriding `mount`'s `connected?(socket)`. The disconnected static render therefore reported connected, so the new Actions/History skeleton showed `aria-busy="false"` and the empty state rendered during load — the exact empty-during-load lie D-10 closes.
- **Fix:** changed `handle_params` to `socket_connected: connected?(socket)` in the template and the demo mirror.
- **Files modified:** priv/templates/parapet.gen.ui/operator_live.ex.eex, examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex
- **Verification:** demo skeleton + empty-gate asserts green; `aria-busy="true"` now present in the disconnected render of all three list pages.
- **Committed in:** f48003f (Task 3)

**2. [Rule 1 - Bug] 48-01 RED rendered-copy assert matched a literal apostrophe that HEEx escapes**
- **Found during:** Task 2 (not-found rendered asserts)
- **Issue:** `@not_found_copy "This incident isn't in the evidence store"` was matched against `render(view)`, but HEEx escapes `'` to `&#39;` in rendered HTML, so the literal-apostrophe match could never pass even with the panel rendering correctly.
- **Fix:** corrected `@not_found_copy` to the HTML-escaped form `This incident isn&#39;t in the evidence store` (a rendered-state assertion must match rendered output).
- **Files modified:** examples/demo_app/test/demo_app/operator_smoke_test.exs
- **Verification:** unknown-UUID + malformed-id not-found asserts green; the not-found panel renders the locked D-02 copy.
- **Committed in:** 9d88fbd (Task 2)

**3. [Rule 1 - Bug] Stale pre-existing source-string/render pins conflicted with the planned D-01/D-06 behavior change**
- **Found during:** Tasks 2-3 (full lib + demo suite)
- **Issue:** Pre-existing green tests pinned the old detail refresh literal `Parapet.Operator.incident_detail(id)` (operator_ui_integration `:63`, operator_ui_compile_out `:37`, gen.ui `:175`), the bare `<.incident_summary detail={@incident} />` ordering needle (gen.ui shift-left `:37`), the History smoke content in the static render (operator_smoke `GET /parapet/history`, `/ops/parapet/history`), and the generated-paging link asserts against a disconnected test socket — all of which the planned D-01 (fetch helper), D-06 (heading_level=h1), and D-09/D-10 (connected-gated lists) changes intentionally moved.
- **Fix:** updated each pin to track the new correct behavior (intent preserved, none deleted): `incident_detail(id)` → `fetch_incident_detail(id)` + `refresh_incident_detail(id)`; the ordering needle → `heading_level="h1"`; the History smoke content asserted on the connected `live/2` render; the paging test socket marked connected via `transport_pid: self()` (what `connected?/1` checks) since its asserts are connected-state link generation.
- **Files modified:** test/parapet/operator_ui_integration_test.exs, test/parapet/operator_ui_compile_out_test.exs, test/mix/tasks/parapet.gen.ui_test.exs, test/mix/tasks/parapet.gen.ui_shift_left_test.exs, examples/demo_app/test/demo_app/operator_smoke_test.exs, test/parapet/generated_operator_live_paging_test.exs
- **Verification:** all six files green; full lib suite back to the 2 pre-existing unrelated failures only.
- **Committed in:** 9d88fbd (Task 2 — the two integration/smoke pins) and f48003f (Task 3 — the remaining four)

---

**Total deviations:** 3 auto-fixed (all Rule 1 — 2 genuine bugs surfaced by the new gates + 1 batch of intent-preserving stale-pin updates).
**Impact on plan:** All necessary to land the planned shell/service edits without leaving previously-green tests red or shipping a dishonest skeleton/empty-gate. No scope creep beyond the shell + service layer; `incident_detail/1` contract, the host root layout, and the pinned `_copy/1` / Phase-47 strings were all left untouched.

## Threat Surface Scan

No new security-relevant surface beyond the plan's `<threat_model>`. T-48-02 (binary_id dual-exception 500) is mitigated by `fetch_incident_detail/1`; T-48-01 (reflected XSS via `@requested_id`) holds (escaped-text-only prop, grep-verified); T-48-04 (not-found masking infra) honored (no `DBConnection` rescue). No new endpoints, auth paths, file access, or schema changes.

## Known Stubs

None — every new render path is driven by real assigns (`@incident`, `@incident_not_found`, `@requested_id`, `@socket_connected`, `@page_title`). The not-found panel, skeletons, and empty states are designed states, not placeholders.

## Issues Encountered

None beyond the three auto-fixed Rule-1 deviations above. The 2 full-suite failures (`DocsPhase33Test`, `ExecutorClusterSmokeTest`) are pre-existing, unrelated, and already logged in `deferred-items.md`.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The full Phase-48 shell + service contract is in place: the operator flow is navigable end-to-end (response → actions → history → detail) with one descriptive h1 per page, descriptive page titles, the designed in-page not-found panel for stale links, connected-gated skeletons/empties, the locked route ordering, and the harmonized error microcopy.
- **48-04 (`autonomous: false`) remains:** full-suite gate (lib + demo `mix test`), audit-matrix flip (the `unavailable`/`permission-denied` N/A-by-Design rows), and the **blocking human `/parapet/_gallery` walkthrough** (copy reading-flow at 390px, heading-hierarchy legibility after the h1 demotion, empty-state "feels designed not broken", keyboard focus-visibility). All automated gates are green entering 48-04.

## Self-Check: PASSED

- `48-03-SUMMARY.md` exists on disk.
- `lib/parapet/operator.ex` modified — `fetch_incident_detail/1` + private `build_detail/1` confirmed present (grep count 2).
- Both detail LiveViews + both shell LiveViews + router snippet + demo layout + host doc modified.
- Commit `0e14eda` (Task 1, service helper) present in git log.
- Commit `9d88fbd` (Task 2, detail not-found + microcopy) present in git log.
- Commit `f48003f` (Task 3, shell semantics + router + demo layout) present in git log.
- `mix test test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_contrast_test.exs` → 33 tests, 0 failures.
- `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` → 17 tests, 0 failures.
- No-inspect-leak, no-infra-rescue, and T-48-01 escape greps all clean.

---
*Phase: 48-pages-flows-microcopy*
*Completed: 2026-06-26*
