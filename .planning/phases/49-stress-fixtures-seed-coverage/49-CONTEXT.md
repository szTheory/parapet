# Phase 49: Stress fixtures & seed coverage - Context

**Gathered:** 2026-06-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

The demo app carries **reproducible stress scenarios** — long-string/overflow, empty-collection,
max-items/dense, mixed-status, and a combined `stress` scenario — all selectable via
`PARAPET_DEMO_SCENARIO`, **and** the `/parapet/_gallery` route plus the combined `stress` scenario
are covered by the screenshot capture script and asserted by a demo contract test. The point is
to re-run the audit against worst-case data on demand.

Requirements in scope: **FIXTURE-01..05, GALLERY-02**.

**Fixed milestone boundaries (v1.6, inherited from Phases 44/47/48):** demo-only fixtures, scripts,
and tests — **no public API or telemetry contract change**, **no markup/palette/logo change**, and
the operator UI stays **host-owned / generated**. This phase only adds demo seed data, extends a
demo screenshot script, and adds demo tests. It exercises the worst-case data that the Phase-48
390px overflow checklist (D-17), the not-found state, and the empty/loading states were built to
withstand — it does **not** add new UI affordances. This phase clarifies HOW to seed and capture,
never WHETHER to add operator-UI capabilities. Committing screenshot **baselines / manifest** is
**Phase 50**, not here (repo-lean: no rasters committed this phase).
</domain>

<decisions>
## Implementation Decisions

### A. Scenario taxonomy & seed wiring (FIXTURE-01, 02, 03, 05)

- **D-01:** Extend `examples/demo_app/priv/repo/demo_seed_scenarios.exs` `@scenarios`
  (currently `response recovery escalation history all`) with **five new named scenarios**:
  `long_string`, `empty`, `max_items`, `mixed_status`, and a combined `stress`. All selectable
  through the **existing** `PARAPET_DEMO_SCENARIO` seam (`seeds.exs:7` →
  `DemoSeedScenarios.seed(scenario)`) — no new env var, no new seam. Add each new name to the
  `@scenarios` list so the `seed(scenario)` catch-all (`:39-42`) keeps reporting valid options and
  rejecting typos. Keep the existing five scenarios untouched.
- **D-02:** **`long_string`** (FIXTURE-01) — incidents whose `title`, `description`,
  `correlation_key`, runbook step labels/descriptions, timeline `external_link` URLs, and
  `ActionItem` `external_id`/`title` are deliberately long, hyphen-free, and machine-shaped
  (long module names, unbroken IDs/UUIDs, deep query-string URLs). This exercises the Phase-48
  `break-all`/`min-w-0`/`truncate` overflow hardening (D-16/D-17) on the real operator pages.
- **D-03:** **`empty`** (FIXTURE-02) — seeds **nothing** (no incidents, no timeline, no action
  items), so `/parapet`, `/parapet/actions`, and `/parapet/history` all render their **designed
  empty states** (Phase-48 D-10/D-11). The existing demo smoke test "at least one seeded incident
  exists" is **self-seeded inside the Ecto sandbox** (`operator_smoke_test.exs`) and does **not**
  depend on `PARAPET_DEMO_SCENARIO`, so an `empty` dev seed does not break the suite.
- **D-04:** **`max_items`** (FIXTURE-03) — a dense list scenario seeding **enough active incidents
  to exceed one queue page** (queue page size is **30**, max **100** — `operator.ex:23-24`,
  `operator_live.ex.eex:8`) plus a dense set of action items and a long timeline, so pagination,
  scroll, and dense-list rendering are exercised. Target ~30–40 active incidents (cross the page
  boundary without ballooning seed time).
- **D-05:** **`mixed_status`** (FIXTURE-04) — surfaces **every distinct status visual the operator
  UI actually renders, in one seed** (the confirmed reading of "all six status triplets at once"):
  incidents across `open` / `investigating` / `resolved`; journeys across `:healthy` / `:degraded`
  / `:down` (`journey_color/1`, `operator_components.ex.eex:1565-1567`); escalation summaries across
  `suppressed` / `manual_trigger_requested` / `recently_executed` / `recently_short_circuited` /
  idle (`escalation_status_*`, `:1647-1667`); and action items spanning the rendered kinds.
  **NOT** a literal injection of the six brand color tokens (healthy/watch/burning/exhausted/
  unknown/ai from `tokens.css:25-30`) — those are not wired 1:1 into operator journeys
  (`:watch/:burning/:exhausted` fall through `journey_color/1` to a colorless `po-chip`), and
  wiring them would be out-of-scope markup change. Values-only, in-scope.
- **D-06:** **`stress`** (FIXTURE-05, the combined scenario that is screenshotted) = the **union**
  of `long_string` + `max_items` + `mixed_status` data, composed so a single seed exercises
  worst-case overflow + density + status diversity **and guarantees at least one
  open/investigating incident exists** (the capture script selects a detail-incident id by querying
  for an active incident — `capture_operator_ui_screenshots.sh` — and exits non-zero if none).
  Reuse the per-scenario seed helpers (compose, don't duplicate).

### B. Screenshot capture coverage (FIXTURE-05, GALLERY-02)

- **D-07:** **Extend `examples/demo_app/scripts/capture_operator_ui_screenshots.sh`** to be the
  single canonical "screenshot capture script": add `/parapet/_gallery` captures (desktop **and**
  mobile, light **and** dark — matching the existing `capture` theme/size convention) and run it
  against a `PARAPET_DEMO_SCENARIO=stress`-seeded DB so the **combined stress scenario** is covered
  across desktop+mobile and light+dark (FIXTURE-05) **and** the gallery route is covered
  (GALLERY-02). The gallery route is served by the same booted demo server and renders from
  hardcoded fixtures, so it needs no DB seed — only that the server is up.
- **D-08:** **Leave `examples/demo_app/scripts/gallery_preview.sh --shot` untouched** as the
  zero-infra (`PARAPET_DEMO_GALLERY_ONLY=true`, DB-less) **dev preview** for the gallery (Phase
  44/46 artifact, honors the user's "DB-less gallery on a free loopback port" DX). It is a separate
  concern from the canonical audit-capture script — do not fold them together.
- **D-09:** **No rasters committed this phase** (repo-lean). The capture script's PNG output stays
  parameterized/`tmp`; the **committed screenshot baseline manifest + re-run/compare procedure is
  Phase 50** (GUARD-05). Phase 49 proves the script *covers* the stress scenario + gallery, not
  that baselines are committed.

### C. Demo contract test (GALLERY-02) + fixture existence pins (FIXTURE-01..05)

- **D-10:** Add a **gallery render contract test** to the existing demo-contract home
  `examples/demo_app/test/demo_app/operator_smoke_test.exs`: `get(conn, "/parapet/_gallery")` → 200
  and assert key operator-component markers render. This asserts the route (GALLERY-02) and proves
  it is **DB-independent** (gallery renders from hardcoded fixtures — `gallery_live.ex:7`, "NO
  Repo/Ecto calls"). Account for the `live_session :parapet_gallery` declared in
  `examples/demo_app/lib/demo_app_web/router.ex:22` (declared so `_gallery` isn't swallowed by the
  `:id` catch-all).
- **D-11:** Add a **fixture-existence pin**: a sandbox test that drives each new scenario via
  `DemoApp.DemoSeedScenarios.seed("long_string" | "empty" | "max_items" | "mixed_status" |
  "stress")` and asserts it runs cleanly and produces the expected shape (e.g. `empty` → zero
  incidents; `max_items` → > one queue page; `mixed_status` → incidents across all three states;
  each new name appears in `DemoSeedScenarios.scenarios()`). Seed helpers must be sandbox-safe
  (`Parapet.Evidence.*` against the test repo, same convention as the existing helpers).
- **D-12:** Test cadence mirrors prior phases: a RED scaffold that asserts the new gallery/contract
  facts before the seed/script edits land, flipped green when D-01..D-11 are implemented. Whether
  the fixture pins live in the demo test suite vs a small lib-side helper test is planner's
  discretion — keep to the **existing** test files where possible (no proliferation).

### Claude's Discretion
- Exact long-string content, the precise incident count for `max_items` (≥31 to cross the page),
  and the exact action-item/journey/escalation mix for `mixed_status` — as long as D-04/D-05's
  coverage goals hold.
- Whether to factor the new scenarios as small composable private helpers reused by `stress`, vs
  inline — D-06 only requires `stress` be the union and reuse, not a specific factoring.
- Exact gallery capture window sizes (reuse the existing script's desktop/mobile/theme convention).
- Exact assertion markers in the gallery render test, and whether the fixture-existence pins are
  one test with sub-cases or one per scenario.

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/48-pages-flows-microcopy/48-CONTEXT.md` (D-16/D-17 390px overflow checklist,
  designed empty/loading/not-found states — the worst-case data these fixtures exercise) and
  `.planning/phases/44-foundations-token-re-skin-fonts-audit-apparatus/44-CONTEXT.md` (gallery
  apparatus, `PARAPET_DEMO_GALLERY_ONLY` DB-less boot, six brand status triplets in
  `tokens.css:25-30`, N/A-by-design convention).
- `examples/demo_app/priv/repo/demo_seed_scenarios.exs` (`@scenarios` `:4`; per-scenario seed
  helpers `:8-306`; `append/3` timeline helper `:348`; the `seed(scenario)` typo-guard `:39-42`)
  and `examples/demo_app/priv/repo/seeds.exs` (`PARAPET_DEMO_SCENARIO` read `:7`).
- `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` (DB-backed operator-page capture;
  detail-id query; `capture name size path theme` helper — extend for `/parapet/_gallery`) and
  `examples/demo_app/scripts/gallery_preview.sh` (DB-less `--shot` dev preview — leave untouched).
- `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex` (hardcoded fixtures, no Repo —
  `:1-20`) and `examples/demo_app/lib/demo_app_web/router.ex` (`live_session :parapet_gallery`,
  `/parapet/_gallery` route `:22-23`).
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` (the demo contract test home; sandbox
  self-seed convention; existing route/render asserts).
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` (queue page size `@default_page_size 30`
  `:8`; hardcoded journeys block `:14-18`; `action_items_query` mount `:11`).
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` (`journey_color/1` `:1565-1567`;
  `escalation_status_copy/badge` `:1647-1667`; `escalation_chain_status_*` `:1768-1778`; chip
  tones) and `lib/parapet/operator.ex` (`@active_queue_states` `:22`, queue page sizes `:23-24`,
  `action_items_query/0` `:52`, `list_incident_queue/1` `:78`).
- `examples/demo_app/lib/demo_app/application.ex` (`PARAPET_DEMO_GALLERY_ONLY` DB-less boot
  `:8-20`).

No external specs — requirements fully captured in the decisions above.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`DemoSeedScenarios` per-scenario helpers** (`login_service_spike/0`, `checkout_webhook_failures/0`,
  `stalled_async_executor/0`, `retry_storm/0`, `signup_email_resolved/0`, `tool_audit/0`,
  `append/3`) — compose these into the new scenarios; `stress` is their union plus long-string +
  density variants.
- **`PARAPET_DEMO_SCENARIO` seam** already exists end-to-end (`seeds.exs:7` →
  `@scenarios` list + `seed/1` dispatch + typo-guard) — only the scenario *set* expands.
- **`capture_operator_ui_screenshots.sh` `capture()` helper** (name/size/path/theme, desktop+mobile,
  light+dark) — the pattern to extend for the gallery; it already themes via `?parapet_theme=`.
- **`gallery_preview.sh --shot`** already captures the gallery DB-less (free-port,
  `PARAPET_DEMO_GALLERY_ONLY`) — the dev-preview counterpart, left as-is.
- **`operator_smoke_test.exs`** (`DemoAppWeb.ConnCase`, Ecto sandbox, sandbox self-seed) — the seam
  for the gallery contract test and the fixture-existence pins.
- **Gallery hardcoded fixtures** (`gallery_live.ex`, overflow/empty/long-string per-component
  states) already exercise component-level stress; Phase 49 adds **page-level seed** stress + the
  gallery's screenshot/test coverage.

### Established Patterns
- **Demo seeds run against a separate non-sandbox dev DB**; tests must self-seed inside the sandbox
  (documented in `operator_smoke_test.exs`) — fixture pins follow this, not `mix run seeds.exs`.
- **`PARAPET_DEMO_GALLERY_ONLY` drops `DemoApp.Repo`** from the supervision tree
  (`application.ex:8-20`) — the gallery must stay Repo-free for that mode to keep working.
- **Queue pagination is bounded** (`@default_queue_page_size 30`, `@max_queue_page_size 100`) —
  `max_items` must cross 30 to prove the second page / dense list.
- **Screenshot scripts theme via `?parapet_theme=light|dark`** and size via `--window-size` — the
  established capture contract (do not introduce a new theming seam).

### Integration Points
- `seeds.exs` → `DemoSeedScenarios.seed/1`: the only wiring point for new scenarios.
- `capture_operator_ui_screenshots.sh` is run after the demo server is up and the DB is seeded with
  the chosen scenario; it queries the Repo for an active detail-incident id (so `stress` must seed
  ≥1 active incident).
- `/parapet/_gallery` is served by the same demo `Endpoint`; the capture script reaches it over the
  same `BASE_URL` with no DB dependency.
</code_context>

<specifics>
## Specific Ideas

- **Confirmed reading of FIXTURE-04 "all six status triplets":** every distinct status visual the
  operator UI actually renders (incident states + journey statuses + escalation states + chip
  tones) in one view — **not** a literal injection of the six brand color tokens, which would be
  out-of-scope markup change.
- **Confirmed "the screenshot capture script":** extend the DB-backed
  `capture_operator_ui_screenshots.sh` to carry both stress-scenario and gallery coverage; keep
  `gallery_preview.sh --shot` as the separate DB-less dev preview.
- **Six brand status triplets (reference only, not 1:1 in operator UI):** healthy / watch / burning
  / exhausted / unknown / ai (`brandbook/tokens/tokens.css:25-30`). Operator UI maps to chip tones
  neutral/success/warning/danger/info and journey statuses `:healthy/:degraded/:down`.
</specifics>

<deferred>
## Deferred Ideas

- Committed screenshot **baseline manifest** + documented re-run/compare procedure, template↔demo
  byte-parity test, off-palette-hex gate, motion/reduced-motion assertion, and
  `v1.6-MILESTONE-AUDIT.md` — **Phase 50** (Guardrails, parity & idempotence gate).
- Wiring the six **brand** status triplets (watch/burning/exhausted/unknown/ai) literally into
  operator journey rendering — out of scope (markup/affordance change past v1.6's values-only
  re-skin; would be its own API/UI phase).
- Automated browser a11y/interaction testing (Playwright + axe-core) — deferred post-v1.6.
- Folding `gallery_preview.sh` and `capture_operator_ui_screenshots.sh` into one script — kept
  separate by design (DB-less dev preview vs DB-backed audit capture).

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
</content>
</invoke>
