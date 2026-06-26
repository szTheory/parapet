---
phase: 48-pages-flows-microcopy
plan: 02
subsystem: ui
tags: [phoenix, liveview, heex, tailwind, microcopy, a11y, empty-state, skeleton, overflow, demo-mirror]

# Dependency graph
requires:
  - phase: 48-pages-flows-microcopy
    provides: "Wave-1 RED scaffold (48-01) — component-scoped source-string asserts pinning the not-found copy, the 3 component microcopy strings, and the contrast/integration gates that this plan flips green"
  - phase: 47-component-groups-meta-components
    provides: "incident_summary/1 + pinned _copy/1 action-rail/risk/preview strings (carried verbatim, untouched)"
provides:
  - "operator_nav/1 banner demoted <h1> -> <p class=\"po-operator-title\"> (D-05) — removes the duplicate per-page h1 source"
  - "incident_not_found/1 component (attrs operator_base_path default /parapet, requested_id required) rendering the D-02 locked not-found copy with @requested_id as escaped text only (T-48-01)"
  - "incident_summary/1 additive heading_level prop (default h2; detail page passes h1 in 48-03)"
  - "list_skeleton/1 reusable uniform skeleton (animate-pulse + aria-busy + aria-live + 3 matched h-16 rows, no literal Loading) for the Actions/History lists (D-09/D-10)"
  - "control_class(:secondary) helper for de-emphasized secondary actions"
  - "Standardized token-driven empty-state anatomy on the incident_list (:781) and Actions empties + a page_mode-aware History-empty designed state (D-11)"
  - "3 component-side D-13 microcopy rewrites (runbook title/description fallbacks, preview_panel line)"
  - "R1-R7 390px overflow fixes in the component layer (D-16)"
affects: [48-03, 48-04, 49-stress-fixtures]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Demo-mirror parity by assertion-pairing: every .eex edit lands in examples/demo_app/.../operator_components.ex in the SAME task (verified by escape-normalized diff)"
    - "break-all (machine strings) vs break-words (prose) + min-w-0 on flex/grid text children — D-17 390px discipline"
    - "Token-driven empty/error anatomy: var(--parapet-text) heading + var(--parapet-text-muted) body/icon, dashed-border non-interactive container, no hover:/transition"
    - "Reusable skeleton-or-nothing component keyed on @socket_connected (no spinner, ARIA-only loading state)"

key-files:
  created: []
  modified:
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - test/parapet/operator_ui_contrast_test.exs

key-decisions:
  - "control_class(:secondary) added — PATTERNS.md referenced a control_class(:secondary) variant that did not exist; added it (neutral white/ring token style) so the not-found secondary action renders consistently (Rule 3)"
  - "not-found action links route through the scoped operator_path/2 helper, not raw @operator_base_path <> string concat — the PATTERNS suggestion would have tripped the pre-existing route-emitter hygiene gate (Rule 1)"
  - "DATA-02 overflow-y-auto refute narrowed to @live_template_paths only — R1 intentionally adds overflow-y-auto to the components-layer preview_panel; the @live_template_paths copy preserves DATA-02 intent (anticipated by the 48-01 carry-forward note, Rule 3)"
  - "History-empty implemented by branching the shared incident_list empty on @page_mode rather than a separate component — incident_list already serves both active and history via page_mode"
  - "Empty-state anatomy inlined (not extracted to shared empty_state/1) — D-11 left extract-vs-inline to discretion; inline keeps demo-mirror parity trivial with no new shared-component surface"

patterns-established:
  - "Wave-2 green: component template + demo mirror edited in lockstep, flipping component-scoped 48-01 asserts green without churning pinned _copy/1 / Phase-47 strings"

requirements-completed: []  # FLOW-02/03/05, COPY-02..05, A11Y-06 are component-partial here; they flip fully complete once 48-03 wires the shells. 48-02 lands the component-layer building blocks only.

coverage:
  - id: D1
    description: "operator_nav banner h1 demoted to <p class=po-operator-title> (D-05) — removes the duplicate per-page h1 source"
    requirement: "FLOW-02"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_contrast_test.exs#operator components use semantic tokens for known dark-mode risk surfaces (text-white\">Active response workbench refute still passes)"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D2
    description: "incident_not_found/1 renders the D-02 locked copy (heading + body + both action links + Requested id); @requested_id is escaped text content only (T-48-01)"
    requirement: "FLOW-03"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_integration_test.exs#COPY-03: not-found heading + body copy pinned verbatim (D-02)"
        status: pass
      - kind: other
        ref: "grep: @requested_id never appears inside an (href|id|navigate|patch|src|action)={...} interpolation in either file"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D3
    description: "incident_summary/1 heading_level prop (default h2, renders h1 when passed h1); no other attr changed (D-06)"
    requirement: "FLOW-02"
    verification:
      - kind: integration
        ref: "mix compile --warnings-as-errors (lib) clean; attr block + h1/h2 branch present in both files"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D4
    description: "3 component-side D-13 microcopy strings present verbatim (runbook title/description fallbacks, preview_panel line); prior fallbacks gone"
    requirement: "COPY-03"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_integration_test.exs#COPY-03: the 10+1 re-authored microcopy strings (components section asserts: Untitled runbook / No runbook description... / This preview reflects...)"
        status: pass
    human_judgment: false
    rationale: "Test asserts both component (passing) and detail_live flash strings (48-03); the 3 component-string assertions in it are satisfied — the test as a whole stays RED only on the 48-03 detail strings."
  - id: D5
    description: "Standardized token-driven empty-state anatomy on :781 + Actions empties, page_mode-aware History-empty, cockpit all-clear kept as distinct hero, no hover:/transition on dashed cards (D-11)"
    requirement: "FLOW-03"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_contrast_test.exs (4 tests, 0 failures — DATA-03 token assertions hold)"
        status: pass
      - kind: other
        ref: "grep: no hover:/transition on any border-dashed empty/not-found container; migrated empties use var(--parapet-text)/var(--parapet-text-muted)"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D6
    description: "list_skeleton/1 reusable uniform skeleton (animate-pulse + aria-busy + aria-live + 3 h-16 token-bg rows, no literal Loading text) available to Actions/History (D-09)"
    requirement: "FLOW-03"
    verification:
      - kind: integration
        ref: "test/parapet/operator_ui_contrast_test.exs#DATA-06 animate-pulse assertion passes; def list_skeleton present in both files; no user-facing literal Loading string"
        status: pass
    human_judgment: false
    rationale: ""
  - id: D7
    description: "R1-R7 390px overflow fixes in the component layer (max-h bottom sheet, break-all/min-w-0 machine strings, grid-cols-1 base collapse); R6 incident_row truncate retained (D-16)"
    requirement: "FLOW-05"
    verification:
      - kind: integration
        ref: "mix compile --warnings-as-errors (lib) clean + mix test contrast/integration: component-scoped asserts green, DATA-02 refute narrowed and passing"
        status: pass
      - kind: manual_procedural
        ref: "390px zero-horizontal-scroll visual confirmation (D-17 9-point gate) — rendered-page check deferred to the 48-04 human gallery walkthrough"
        status: unknown
    human_judgment: true
    rationale: "Static utility application (break-all/min-w-0/max-h/grid-cols-1) is grep/compile-verified, but the actual zero-horizontal-scroll-at-390px outcome is a rendered visual property no unit test asserts — reserved for the blocking 48-04 /parapet/_gallery walkthrough."

# Metrics
duration: 13min
completed: 2026-06-26
status: complete
---

# Phase 48 Plan 02: Component-Layer Green (Wave 2) Summary

**Re-skinned operator_components.ex.eex + its demo mirror in lockstep: demoted the operator_nav banner h1→<p>, added the designed incident_not_found/1 panel (escaped @requested_id), the incident_summary heading_level prop, a reusable list_skeleton/1, one token-driven empty-state anatomy + a page_mode-aware History-empty, the 3 component microcopy rewrites, and the R1-R7 390px overflow fixes — flipping every component-scoped 48-01 RED assertion green.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-06-26T21:03:45Z
- **Completed:** 2026-06-26T21:17:29Z
- **Tasks:** 2
- **Files modified:** 3 (2 component templates + 1 test scope-narrowing)

## Accomplishments

- **D-05 single-h1 source removal:** demoted the persistent `operator_nav` banner from `<h1>` to `<p class="po-operator-title">` (byte-identical classes/text) so each page can carry exactly one h1 once 48-03 adds the per-page heading.
- **incident_not_found/1 (D-02):** new dashed-border, brand-chrome panel rendering the locked not-found copy verbatim; `@requested_id` rendered as escaped HEEx text content only — verified by grep it never enters an `href`/`id`/attribute interpolation (T-48-01 mitigation).
- **incident_summary/1 heading_level prop (D-06):** additive `attr(:heading_level, :string, default: "h2")` branching the title between `<h1>`/`<h2>` (same classes); no other attr or output shape changed. 48-03's detail page passes `"h1"`.
- **Standardized empty-state anatomy + History-empty (D-11):** migrated the bare `text-stone-*` `incident_list` (:781) and Actions empties to one token-driven dashed-border anatomy (`var(--parapet-text)` heading, `var(--parapet-text-muted)` body/icon, optional single next-action link, no `hover:`/`transition`); added a page_mode-aware "No resolved incidents yet" History-empty; kept the cockpit all-clear as the distinct hero variant.
- **Reusable list_skeleton/1 (D-09/D-10):** `aria-live="polite"` + `aria-busy` keyed on `@socket_connected`, three matched `h-16` token-bg rows under `animate-pulse`, `aria-hidden`, zero literal "Loading" text — ready for 48-03's shell to wrap the Actions/History lists.
- **3 component microcopy rewrites (D-13):** runbook_card title (`Untitled runbook`) + description fallback, and the preview_panel line — verbatim; the pinned `_copy/1` and Phase-47 strings left untouched.
- **R1-R7 390px overflow fixes (D-16):** preview_panel height-bound bottom sheet (R1), `min-w-0`/`break-all`/`break-words`/`grid-cols-1` collapses across action_item_card (R2), preview grid (R3), suspect-changes chip (R4), runbook step wrapper (R5), and the incident_summary trace span (R7); incident_row `truncate` retained (R6).
- **Demo-mirror parity:** every edit landed in `examples/demo_app/.../operator_components.ex` in the same task — confirmed by an escape-normalized diff showing only the pre-existing `@web_module`/comment-style/formatter differences.

## Task Commits

1. **Task 1: operator_nav h1 demotion + not-found panel + incident_summary heading-level prop + component microcopy** - `37d0ed4` (feat)
2. **Task 2: standardized empty-state anatomy, uniform skeleton, R1-R7 overflow fixes** - `60af80c` (feat)

## Files Created/Modified

- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — operator_nav h1→p (D-05); new `incident_not_found/1` (D-02); `incident_summary/1` heading_level prop (D-06); new `list_skeleton/1` (D-09); `control_class(:secondary)`; standardized + History-aware empties (D-11); 3 microcopy rewrites (D-13); R1-R7 overflow utilities (D-16).
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` — byte-parallel demo mirror of every edit above (same task, assertion-pairing parity).
- `test/parapet/operator_ui_contrast_test.exs` — narrowed the DATA-02 `overflow-y-auto` refute to `@live_template_paths` only (R1 preview_panel lives in components), with an explanatory comment.

## 48-01 Assertions Flipped GREEN (component-scoped)

| Assertion | REQ | Now |
|---|---|---|
| COPY-03: not-found heading + body copy pinned verbatim (D-02) | COPY-03/FLOW-03 | **GREEN** |
| Route-emitter hygiene: no direct local route emitters (was tripped by the not-found links, fixed via operator_path/2) | — | **GREEN** (kept) |
| Contrast suite incl. DATA-02 (narrowed), DATA-03, DATA-06 animate-pulse, GROUP-01 break-words | DATA-02/03/06 | **GREEN** (4 tests, 0 failures) |
| COPY-03 #6 — the 3 *component* microcopy strings (Untitled runbook / No runbook description… / This preview reflects…) | COPY-03 | **GREEN** (the 3 component assertions in the test pass) |

**Remaining RED (out of scope — 48-03 territory, unchanged from the 48-01 baseline):** A11Y-06 Incident-context nav, FLOW-02 `:page_title` source + rendered single-h1/page_title, FLOW-04 router catch-all comment, COPY/voice D-15 inspect() in detail flashes, COPY-03 the 8 detail_live flash strings, and the rendered not-found/skeleton/empty-during-load gates. All live in `operator_detail_live.ex.eex` / `operator_live.ex.eex` / `router_snippet.ex.eex`, which this plan does not own.

## Test Evidence

- `mix compile --warnings-as-errors` (lib root): **clean** (exit 0).
- `mix test test/parapet/operator_ui_contrast_test.exs`: **4 tests, 0 failures.**
- `mix test test/parapet/operator_ui_integration_test.exs`: **29 tests, 5 failures** — all 5 are the 48-03-territory 48-01 RED gates (down from 6 at 48-01 start; the route-emitter hygiene test went green after the operator_path/2 fix).
- `cd examples/demo_app && mix compile`: **Generated demo_app app** (exit 0).
- `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs`: **17 tests, 6 failures** — identical to the 48-01 baseline (all shell-dependent; no regression).
- `mix test` (full lib suite): **570 tests, 7 failures** — the 5 expected 48-01 RED gates + 2 pre-existing unrelated failures (DocsPhase33 / ExecutorClusterSmoke), both confirmed failing on clean HEAD with this work stashed (see deferred-items.md).

## @requested_id Escape Verification (T-48-01)

`@requested_id` appears at exactly two sites per file: the `attr(:requested_id, :string, required: true)` declaration and `Requested id: <%= @requested_id %>` (escaped HEEx text content). A grep for `(href|id|navigate|patch|src|action)={...requested_id...}` returns **no matches** in either the template or the demo mirror — the high-severity reflected-XSS threat is mitigated as designed.

## Decisions Made

- **Added `control_class(:secondary)`** (Rule 3): the PATTERNS.md not-found snippet called `control_class(:secondary)`, but only `:primary/:destructive/:recovery/:warning/:warning_secondary/:success` existed. Added a neutral white/`var(--parapet-border)`-ring secondary variant in both files.
- **not-found links use `operator_path/2`, not raw concat** (Rule 1): the suggested `navigate={@operator_base_path <> "/history"}` tripped the pre-existing route-emitter hygiene gate (`refute ...operator_base_path...<>`). Routed both actions through the established `operator_path/2` scoped helper instead.
- **DATA-02 refute narrowed to `@live_template_paths`** (Rule 3): R1's intentional `overflow-y-auto` on `preview_panel` (a component) conflicted with the `@component_paths` DATA-02 refute. Narrowed exactly as the 48-01 carry-forward note anticipated; the `@live_template_paths` copy preserves DATA-02 intent.
- **History-empty via `@page_mode` branch, anatomy inlined** — `incident_list` already serves active + history through `page_mode`; D-11 left extract-vs-inline to discretion and inline keeps demo-mirror parity trivial.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] control_class(:secondary) variant did not exist**
- **Found during:** Task 1 (incident_not_found secondary action link)
- **Issue:** PATTERNS.md referenced `control_class(:secondary)`; no such clause was defined, so the not-found component would not compile.
- **Fix:** Added a `control_class(:secondary, width)` clause (neutral white bg, `var(--parapet-border)` ring, `text-stone-700`, `hover:bg-stone-50`) in both the template and the demo mirror.
- **Files modified:** priv/templates/parapet.gen.ui/operator_components.ex.eex, examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
- **Verification:** `mix compile --warnings-as-errors` clean; demo app compiles.
- **Committed in:** 37d0ed4 (Task 1)

**2. [Rule 1 - Bug] not-found links would have bypassed the scoped route helper**
- **Found during:** Task 1 (integration test run after first edit)
- **Issue:** The PATTERNS-suggested `navigate={@operator_base_path <> "/history"}` matched the pre-existing route-emitter hygiene refute (`(navigate|patch|href)={...operator_base_path...<>}`), turning a previously-green test red.
- **Fix:** Routed the not-found primary/secondary actions through `operator_path(@operator_base_path)` and `operator_path(@operator_base_path, :history)`.
- **Files modified:** both component files.
- **Verification:** the "generated and demo route emitters do not bypass scoped route helpers" test returned green (failures 6→5).
- **Committed in:** 37d0ed4 (Task 1)

**3. [Rule 3 - Blocking] DATA-02 overflow-y-auto refute conflicted with R1**
- **Found during:** Task 2 (R1 preview_panel height-bound fix)
- **Issue:** R1 adds `overflow-y-auto` to `preview_panel`, which lives in `@component_paths`; the DATA-02 refute in that loop (`refute content =~ "overflow-y-auto"`) would fail.
- **Fix:** Removed the now-conflicting refute from the `@component_paths` loop (the `@live_template_paths` loop retains the canonical DATA-02 refute), with an explanatory comment. This is exactly the narrowing the 48-01 SUMMARY's wave-2 carry-forward note specified.
- **Files modified:** test/parapet/operator_ui_contrast_test.exs
- **Verification:** contrast suite 4 tests, 0 failures.
- **Committed in:** 60af80c (Task 2)

---

**Total deviations:** 3 auto-fixed (2 blocking — Rule 3, 1 bug — Rule 1).
**Impact on plan:** All three were necessary to land the planned component edits without breaking previously-green gates; two (the route-helper and DATA-02 narrowing) were explicitly anticipated in the plan/PATTERNS/48-01 notes. No scope creep beyond the component layer.

## Issues Encountered

None beyond the three auto-fixed deviations above. Two pre-existing, unrelated full-suite failures (`DocsPhase33Test`, `ExecutorClusterSmokeTest`) were discovered, confirmed pre-existing (fail on clean HEAD), and logged to `deferred-items.md` per the scope boundary — not fixed.

## Known Stubs

None — no hardcoded empty values, placeholder text, or unwired components introduced. The empty/skeleton/not-found components are designed states driven by real assigns (`@incidents`, `@items`, `@socket_connected`, `@page_mode`, `@requested_id`).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The component-layer contract 48-03 depends on is in place: `incident_not_found/1` (name + `operator_base_path`/`requested_id` attrs), `incident_summary/1` `heading_level` prop, and `list_skeleton/1` (`socket_connected` attr) are stable and compile clean.
- **48-03 must:** wire `fetch_incident_detail/1` + the not-found render branch and `requested_id` assign into `operator_detail_live.ex.eex`; add per-page h1s + `:page_title` assigns to `operator_live`/`operator_detail_live`; wrap the Actions/History lists in `list_skeleton/1` + the `@socket_connected and Enum.empty?` empty gate; land the 8 detail_live flash microcopy strings (drop `inspect/1`); add the Incident-context nav and router catch-all comment. Those flips green the remaining 5 lib + 6 demo RED gates.

## Self-Check: PASSED

- `48-02-SUMMARY.md` exists on disk.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` exists (modified).
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` exists (modified).
- `test/parapet/operator_ui_contrast_test.exs` exists (modified — DATA-02 narrowing).
- `deferred-items.md` exists (out-of-scope discoveries logged).
- Commit `37d0ed4` (Task 1) present in git log.
- Commit `60af80c` (Task 2) present in git log.
- New component symbols `incident_not_found/1`, `list_skeleton/1`, and the `heading_level` attr confirmed present.
- Demo-mirror parity confirmed by escape-normalized diff (only pre-existing `@web_module`/comment-style/formatter differences remain).
- `@requested_id` confirmed escaped-text-only (no attribute interpolation) in both files.

---
*Phase: 48-pages-flows-microcopy*
*Completed: 2026-06-26*
