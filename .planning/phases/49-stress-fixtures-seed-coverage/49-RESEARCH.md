# Phase 49: Stress fixtures & seed coverage - Research

**Researched:** 2026-06-28
**Domain:** Elixir/Phoenix demo-app seed fixtures, headless-Chrome screenshot capture, Ecto-sandbox LiveView contract tests
**Confidence:** HIGH (every claim verified by reading the current source this session)

## Summary

Phase 49 is a pure **demo-app fixtures/scripts/tests** phase. CONTEXT.md (D-01..D-12) already locks every decision down to file paths and line numbers; this research **verifies those facts against the current code** and defines the validation/test strategy. The verdict: the locked decisions are accurate. Every line reference and seam named in CONTEXT.md was confirmed, with two clarifying corrections that the planner must internalize (neither changes a decision — they make the decisions implementable):

1. **Journeys are NOT seed-driven.** The `mixed_status` "journeys across `:healthy`/`:degraded`/`:down`" coverage cannot be produced by a seed — the demo's `operator_live.ex` (and the lib template) **hardcode** a 4-journey list (`Login/Signup/Checkout/Webhooks`, statuses `:healthy/:healthy/:degraded/:healthy`) directly in `mount/3`. No `:down` journey is rendered anywhere today. So `mixed_status` seed coverage of journeys is **already satisfied by the existing hardcoded mount** for healthy+degraded; `:down` is reachable only on the gallery's hardcoded fixtures, not via seeds. The seed's job for `mixed_status` is incidents + escalation + action-item diversity, not journeys. (See Architectural Responsibility Map.)

2. **Every escalation status is producible from `runbook_data["escalation"]` + a timeline event**, and the existing per-scenario helpers already demonstrate all five states. `mixed_status` composes from existing helpers — it does not need new escalation mechanics.

**Primary recommendation:** Add the five scenarios as small composable private helpers in `demo_seed_scenarios.exs`, reusing the existing `Parapet.Evidence.create_incident/1` + `append/3` + `ActionItem.changeset |> Repo.insert` conventions verbatim; compose `stress = long_string + max_items + mixed_status`. Extend `capture_operator_ui_screenshots.sh` with four `/parapet/_gallery` captures (desktop+mobile × light+dark) reusing the existing `capture()` helper. Add a gallery render contract test + one fixture-existence pin test to `operator_smoke_test.exs`, self-seeding inside the Ecto sandbox. Commit no rasters (Phase 50 owns baselines).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Scenario taxonomy + `seed/1` dispatch | Demo seed module (`demo_seed_scenarios.exs`) | — | `@scenarios` list + dispatch + typo-guard already live here `[VERIFIED: read demo_seed_scenarios.exs:4,8-42]` |
| `PARAPET_DEMO_SCENARIO` selection | Demo seed entrypoint (`seeds.exs`) | — | Reads env at `:7`, calls `DemoSeedScenarios.seed(scenario)` `[VERIFIED: read seeds.exs:7-8]` |
| Incident/timeline/action-item creation | `Parapet.Evidence.*` + `Parapet.Spine.ActionItem` (lib, used by demo) | — | All existing helpers route through `Evidence.create_incident/1`, `Evidence.append_timeline/2` (via `append/3`), and `ActionItem.changeset \|> DemoApp.Repo.insert` `[VERIFIED: read demo_seed_scenarios.exs:44-350, evidence.ex:58-95]` |
| Incident **state** diversity (open/investigating/resolved) | Seed (`state:` attr) | — | `Incident` validates `state in ["open","investigating","resolved"]` `[VERIFIED: incident.ex:57]` |
| **Journey** status diversity (:healthy/:degraded/:down) | **LiveView mount (hardcoded), NOT seed** | Gallery hardcoded fixtures (for `:down`) | `operator_live.ex(.eex)` hardcodes journeys in `mount/3`; seeds cannot influence them `[VERIFIED: operator_live.ex.eex:14-19; demo operator_live.ex:14-19]` |
| **Escalation** status diversity (suppressed/requested/executed/short-circuited/idle) | Seed (`runbook_data["escalation"]` + timeline event) | `WorkbenchContract.derive_escalation_summary/2` | Status derived from runbook_data + latest escalation timeline event `[VERIFIED: workbench_contract.ex:267-349]` |
| **Action-item** kind/state diversity | Seed (`ActionItem.changeset`) | — | `@kinds` = exact_follow_up/suppressed_delivery/stalled_workflow/orphaned_callback/dead_letter; state open/resolved `[VERIFIED: action_item.ex:16-22,43-44]` |
| Queue pagination (cross page boundary) | Seed count (≥31 active) → `Parapet.Operator.list_incident_queue/1` | — | `@default_queue_page_size 30`, `@max_queue_page_size 100`, `@active_queue_states ["open","investigating"]` `[VERIFIED: operator.ex:22-24]` |
| Screenshot capture (DB-backed: operator pages + gallery) | `capture_operator_ui_screenshots.sh` | — | DB-backed audit-capture script; queries Repo for an active detail id `[VERIFIED: read capture_operator_ui_screenshots.sh]` |
| Gallery DB-less dev preview | `gallery_preview.sh --shot` (LEAVE UNTOUCHED) | — | Separate concern: `PARAPET_DEMO_GALLERY_ONLY=true`, free-port, no Repo `[VERIFIED: read gallery_preview.sh]` |
| Gallery route rendering (Repo-free) | `GalleryLive` (hardcoded fixtures) | — | Mount assigns only in-memory fixtures, no Repo/Ecto calls `[VERIFIED: gallery_live.ex:7-21]` |
| Contract/fixture tests | `operator_smoke_test.exs` (ConnCase + Ecto sandbox) | — | Existing demo-contract home; self-seeds in sandbox `[VERIFIED: read operator_smoke_test.exs + conn_case.ex]` |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIXTURE-01 | `long_string` overflow scenario | D-02 fields confirmed creatable via `create_incident` (title/description/correlation_key/runbook_data steps), `append/3` (external_link url), and `ActionItem` (external_id/title). All free-form strings — no validation blocks long content `[VERIFIED: evidence.ex:58, action_item.ex:39-45]` |
| FIXTURE-02 | `empty` scenario (seeds nothing) | D-03: a `seed("empty")` that runs no helpers. Smoke test self-seeds in sandbox so it does NOT depend on dev-DB seeds `[VERIFIED: operator_smoke_test.exs:57-68]` |
| FIXTURE-03 | `max_items` density / cross page boundary | D-04: ≥31 active incidents crosses page size 30 `[VERIFIED: operator.ex:23 @default_queue_page_size 30]` |
| FIXTURE-04 | `mixed_status` — every distinct status visual | D-05: incident states + escalation states (5) + action-item kinds. Journeys already hardcoded (see Map). `[VERIFIED: incident.ex:57, workbench_contract.ex:339-349, action_item.ex:16-22]` |
| FIXTURE-05 | `stress` combined scenario, screenshotted | D-06: union of three; must seed ≥1 active incident for the capture script's detail-id query `[VERIFIED: capture_operator_ui_screenshots.sh:35-45]` |
| GALLERY-02 | Gallery covered by capture script + contract test | D-07 (capture script gallery captures) + D-10 (render contract test). Gallery is Repo-free `[VERIFIED: gallery_live.ex:7, router.ex:22-24]` |

## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01..D-12, verbatim summary)
- **D-01:** Extend `@scenarios` (`response recovery escalation history all`) with `long_string`, `empty`, `max_items`, `mixed_status`, `stress`. Same `PARAPET_DEMO_SCENARIO` seam (`seeds.exs:7`), no new env var. Add each name to `@scenarios` so the `seed/1` catch-all keeps reporting valid options + rejecting typos. Keep existing five untouched.
- **D-02:** `long_string` — long, hyphen-free, machine-shaped strings in title/description/correlation_key/runbook step labels+descriptions/timeline external_link URLs/ActionItem external_id+title. Exercises Phase-48 `break-all`/`min-w-0`/`truncate` hardening (D-16/D-17).
- **D-03:** `empty` — seeds nothing. `/parapet`, `/parapet/actions`, `/parapet/history` render designed empty states. Smoke test self-seeds in sandbox, unaffected.
- **D-04:** `max_items` — ~30–40 active incidents (cross page size 30) + dense action items + long timeline.
- **D-05:** `mixed_status` — every distinct rendered status visual in one seed (incident states; journeys :healthy/:degraded/:down; escalation suppressed/manual_trigger_requested/recently_executed/recently_short_circuited/idle; action-item kinds). NOT a literal injection of the six brand color tokens.
- **D-06:** `stress` = union of `long_string` + `max_items` + `mixed_status`; guarantees ≥1 open/investigating incident; reuse per-scenario helpers (compose, don't duplicate).
- **D-07:** Extend `capture_operator_ui_screenshots.sh` with `/parapet/_gallery` captures (desktop+mobile, light+dark) run against a `PARAPET_DEMO_SCENARIO=stress`-seeded DB. Gallery needs no DB seed (server-up only).
- **D-08:** Leave `gallery_preview.sh --shot` untouched (DB-less dev preview). Do not fold the two scripts.
- **D-09:** No rasters committed this phase. PNG output stays `tmp`/parameterized. Committed baseline manifest is Phase 50.
- **D-10:** Add gallery render contract test to `operator_smoke_test.exs`: `get(conn, "/parapet/_gallery")` → 200, assert operator-component markers render, prove DB-independence. Account for `live_session :parapet_gallery`.
- **D-11:** Add fixture-existence pin: sandbox test driving each new scenario via `DemoApp.DemoSeedScenarios.seed("…")`, asserting it runs cleanly and produces expected shape. Seed helpers must be sandbox-safe.
- **D-12:** RED-scaffold-then-green cadence. Fixture pins in demo test suite vs lib-side helper test is planner's discretion — prefer existing files (no proliferation).

### Claude's Discretion
- Exact long-string content; precise `max_items` count (≥31); exact action-item/journey/escalation mix for `mixed_status` (as long as D-04/D-05 coverage holds).
- Composable private helpers reused by `stress` vs inline.
- Exact gallery capture window sizes (reuse existing convention).
- Exact gallery render-test markers; one fixture test with sub-cases vs one per scenario.

### Deferred Ideas (OUT OF SCOPE)
- Committed screenshot baseline manifest + re-run/compare procedure, byte-parity test, off-palette-hex gate, motion assertion, `v1.6-MILESTONE-AUDIT.md` — **Phase 50**.
- Wiring brand status triplets (watch/burning/exhausted/unknown/ai) literally into operator journey rendering — out of scope (markup/affordance change).
- Automated browser a11y/interaction testing (Playwright + axe-core) — post-v1.6.
- Folding `gallery_preview.sh` + `capture_operator_ui_screenshots.sh` together — kept separate by design.

## Project Constraints (from CLAUDE.md / memory)
- No `./CLAUDE.md` present in repo root; the GSD memory index governs. Relevant directives:
  - **Demo-only, no public API/telemetry/markup change** (milestone fence, inherited 44/47/48).
  - **DB-less gallery DX** (`user_local-multi-oss-elixir-uis`, `parapet-v1.6-gallery-preview-dx`): keep the gallery Repo-free; do not introduce Docker/PG dependencies into the DB-less path.
  - **Demo seeds run against a separate non-sandbox dev DB**; tests self-seed inside the sandbox (never `mix run seeds.exs` in a test).

## Standard Stack

No new dependencies. This phase uses only what the demo app already has.

### Core (already present, used as-is)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Parapet.Evidence` | in-repo | `create_incident/1`, `append_timeline/2`, `log_tool_audit/1` — the only sanctioned write path | All existing seed helpers use it `[VERIFIED: evidence.ex:58,91,101]` |
| `Parapet.Spine.ActionItem` | in-repo | ActionItem changeset for dense action-item seeding | Existing `stalled_async_executor/0` uses `ActionItem.changeset \|> DemoApp.Repo.insert` `[VERIFIED: demo_seed_scenarios.exs:229-239]` |
| `Phoenix.LiveViewTest` + `DemoAppWeb.ConnCase` | in-repo | Rendered-state contract tests against Ecto sandbox | The demo-contract harness `[VERIFIED: operator_smoke_test.exs, conn_case.ex]` |
| headless Chrome/Chromium (`--headless=new`) | host-provided | Screenshot capture | Existing `capture()` helper convention `[VERIFIED: capture_operator_ui_screenshots.sh:58-67]` |

**Installation:** None. No `mix.exs` change, no new Hex package, no new npm package.

## Package Legitimacy Audit

> **N/A — no external packages installed this phase.** All code uses in-repo modules and host-provided Chrome. No `npm install` / `mix deps.get` / new dependency. The Package Legitimacy Gate is not applicable.

## Architecture Patterns

### System Architecture Diagram

```
PARAPET_DEMO_SCENARIO=<name>  (env)
        │
        ▼
  seeds.exs:7  System.get_env("PARAPET_DEMO_SCENARIO","all")
        │
        ▼
  DemoSeedScenarios.seed(<name>)        ──guard──▶ raise ArgumentError if not in @scenarios
        │ (dispatch on string)
        ├─ "long_string"  ─┐
        ├─ "empty"         │  (composes per-scenario private helpers)
        ├─ "max_items"     │
        ├─ "mixed_status"  │
        └─ "stress" ───────┴─▶ long_string + max_items + mixed_status (union)
                                     │
                                     ▼
                 Parapet.Evidence.create_incident/1   (incident + state)
                 append/3  → Evidence.append_timeline/2  (notes, status_change,
                              external_link, escalation_* events)
                 ActionItem.changeset |> DemoApp.Repo.insert  (action items)
                                     │
                                     ▼
                          (separate non-sandbox dev DB)
                                     │
        ┌────────────────────────────┴───────────────────────────────┐
        ▼                                                             ▼
 capture_operator_ui_screenshots.sh                          operator_smoke_test.exs
 (DB-backed; queries active incident id;                     (Ecto sandbox; SELF-SEEDS;
  captures /parapet, /actions, /history,                      drives DemoSeedScenarios.seed
  /incidents/:id, AND /parapet/_gallery)                      in-sandbox; asserts shape +
        │                                                      gallery render 200)
        ▼
   PNG → tmp/parameterized OUTPUT_DIR (no rasters committed)

  ── separate concern, untouched ──
 gallery_preview.sh --shot  (PARAPET_DEMO_GALLERY_ONLY=true, no Repo, free port)
```

### Recommended file touch-set (no new files unless a fixture-test split is chosen)
```
examples/demo_app/priv/repo/demo_seed_scenarios.exs   # +5 scenarios, +composable helpers
examples/demo_app/scripts/capture_operator_ui_screenshots.sh  # +4 gallery captures
examples/demo_app/test/demo_app/operator_smoke_test.exs       # +gallery contract, +fixture pins
# UNTOUCHED: seeds.exs (seam already complete), gallery_preview.sh, gallery_live.ex,
#            router.ex, application.ex, all priv/templates/*.eex, lib/parapet/*
```

### Pattern 1: New scenario = compose private helpers
**What:** Each new scenario is a `seed("<name>")` clause that calls small private helpers; `stress` calls the union.
**When to use:** All five new scenarios.
**Example (shape verified against existing code):**
```elixir
# Source: demo_seed_scenarios.exs (existing convention, lines 8-42)
@scenarios ~w(response recovery escalation history all long_string empty max_items mixed_status stress)

def seed("long_string"), do: long_string_incident()
def seed("empty"), do: :ok                      # seeds nothing by design (D-03)
def seed("max_items"), do: max_items_dense()
def seed("mixed_status"), do: mixed_status_spread()
def seed("stress") do                            # D-06 union, reuse helpers
  long_string_incident()
  max_items_dense()
  mixed_status_spread()
end
# existing seed("response") .. seed("all") unchanged
def seed(scenario), do: raise ArgumentError, "unknown PARAPET_DEMO_SCENARIO=#{inspect(scenario)}; ..."
```
**Note:** `seed("empty")` must return a value the entrypoint tolerates (`seeds.exs:8` ignores the return). `:ok` is fine. **Do not** let `empty` fall through to the catch-all (it would raise) — it needs its own explicit clause **declared before** the catch-all `[VERIFIED: demo_seed_scenarios.exs:39-42]`.

### Pattern 2: Incident with escalation status (for mixed_status)
**What:** Escalation status is derived, not stored. Set `runbook_data["escalation"]` + append the matching timeline event.
**Mapping (verified `workbench_contract.ex:339-349`):**
| Target status | runbook_data["escalation"] | timeline event to append |
|---------------|-----------------------------|--------------------------|
| `:suppressed` | `suppressed_until` = future ISO8601 | `escalation_suppressed` |
| `:manual_trigger_requested` | `pending_trigger: true`, `trigger_requested_at` recent | `escalation_trigger_requested` |
| `:recently_executed` | (any/none) | `escalation_executed` |
| `:recently_short_circuited` | (any/none) | `escalation_short_circuited` |
| `:idle` | no escalation key | (none) |

These exactly mirror the existing helpers — `checkout_webhook_failures/0` (requested), `stalled_async_executor/0` (suppressed), `signup_email_resolved/0` (executed), `retry_storm/0` (short-circuited). `mixed_status` can call those four plus one bare open incident (idle) `[VERIFIED: demo_seed_scenarios.exs:105-295, workbench_contract.ex:339-349]`.

### Pattern 3: Dense action items (for max_items / mixed_status)
**What:** Insert N `ActionItem`s via changeset.
**Constraints (verified `action_item.ex:16-45`):**
- `kind` ∈ `exact_follow_up | suppressed_delivery | stalled_workflow | orphaned_callback | dead_letter` (validated — an out-of-list kind raises).
- `state` ∈ `open | resolved` (only `open` shows in `action_items_query/0` `[VERIFIED: operator.ex:52-57]`).
- Required: `title`, `integration`, `external_id`.
- `incident_id` is a binary_id FK → must reference a created incident.
```elixir
# Source: demo_seed_scenarios.exs:229-239 (existing convention)
%Parapet.Spine.ActionItem{}
|> Parapet.Spine.ActionItem.changeset(%{
  title: "...", integration: "demo", external_id: "ext-...",
  kind: "stalled_workflow", state: "open", incident_id: incident.id
})
|> DemoApp.Repo.insert()
```

### Anti-Patterns to Avoid
- **Trying to seed journey `:down`.** Journeys are hardcoded in `mount/3` (`operator_live.ex(.eex):14-19`) with only `:healthy`/`:degraded`. No seed path exists. Do not invent one (would be an out-of-scope LiveView/markup change). `:down` lives only on the gallery's hardcoded fixtures.
- **Literal brand-token injection for mixed_status.** `:watch/:burning/:exhausted` fall through `journey_color/1` to a bare `po-chip` `[VERIFIED: operator_components.ex.eex:1565-1568]`. Wiring them 1:1 is out of scope (D-05, Deferred).
- **Running `mix run seeds.exs` from a test.** Demo seeds hit the separate non-sandbox dev DB; tests must self-seed inside the sandbox (`operator_smoke_test.exs:57-68` documents this).
- **Adding a new theming/env seam.** Reuse `?parapet_theme=light|dark` and `--window-size` (existing capture contract).
- **Committing PNGs.** Phase 50 owns baselines (D-09).
- **Adding Repo/Ecto to the gallery.** `PARAPET_DEMO_GALLERY_ONLY` drops `DemoApp.Repo` from the supervision tree (`application.ex:12-22`); any Repo call from `GalleryLive` would crash that mode.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Insert an incident + escalation job | Direct `Repo.insert(%Incident{})` | `Parapet.Evidence.create_incident/1` | Wraps the insert in an `Ecto.Multi` and conditionally enqueues escalation; the sanctioned write path `[VERIFIED: evidence.ex:58-69]` |
| Append a timeline entry | Direct `%TimelineEntry{}` insert | the existing `append/3` private helper | Already wraps `Evidence.append_timeline/2` with the `{:ok, _}` match `[VERIFIED: demo_seed_scenarios.exs:348-350]` |
| Select an active incident id for the detail screenshot | New query in the script | the existing `DETAIL_ID` Ecto query in the capture script | Already filters `state in ["open","investigating"]`, orders by `updated_at`, regex-extracts the UUID `[VERIFIED: capture_operator_ui_screenshots.sh:35-45]` |
| Theme + size a screenshot | New chrome invocation | the existing `capture()` helper | Handles `?parapet_theme=`/`&parapet_theme=` query-string branching and `--window-size` `[VERIFIED: capture_operator_ui_screenshots.sh:47-67]` |
| Ecto sandbox setup | New test case template | `DemoAppWeb.ConnCase` | Checks out the sandbox in shared mode for non-async tests `[VERIFIED: conn_case.ex:20-28]` |
| Escalation-status state machine | Hand-set a status field | runbook_data + timeline event (derived) | `WorkbenchContract.derive_escalation_summary/2` computes it; there is no stored status field `[VERIFIED: workbench_contract.ex:267-349]` |

**Key insight:** Status visuals are **derived**, not stored. To exercise a status you produce the *evidence* that derives to it (escalation runbook_data + a timeline event), exactly as the existing four scenarios already do. `mixed_status`/`stress` are therefore re-compositions of proven helpers, not new mechanics.

## Runtime State Inventory

> This is a demo-fixtures phase, **not** a rename/refactor/migration. No string-rename or migration is involved. Inventory included for completeness:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Demo dev DB (`demo_app_dev`, separate non-sandbox) holds whatever the last `mix run seeds.exs` wrote. New scenarios add rows when selected; idempotency is not required (operator re-seeds as needed). | None — re-seeding is the intended workflow |
| Live service config | None — no external service holds the new scenario names | None |
| OS-registered state | None — no scheduler/launchd/pm2 registration | None |
| Secrets/env vars | `PARAPET_DEMO_SCENARIO` (existing, no new var); capture script honors `PARAPET_DEMO_URL`, `CHROME_BIN`, `OUTPUT_DIR` ($1) — all existing | None — reuse |
| Build artifacts | None — no compiled artifact carries scenario names; `.exs` is interpreted | None |

**Nothing requires a data migration.** New scenarios only add insert paths.

## Common Pitfalls

### Pitfall 1: `empty` falling through to the typo-guard
**What goes wrong:** If `seed("empty")` has no explicit clause it hits the catch-all and **raises** `ArgumentError`.
**Why it happens:** The catch-all `seed(scenario)` (`:39-42`) is the typo-guard; pattern clauses are tried top-down.
**How to avoid:** Add an explicit `def seed("empty"), do: :ok` (or a body that seeds nothing) **above** the catch-all, and add `"empty"` to `@scenarios`.
**Warning signs:** `mix run priv/repo/seeds.exs` with `PARAPET_DEMO_SCENARIO=empty` raising "unknown ... expected one of".

### Pitfall 2: Expecting journeys to vary by seed
**What goes wrong:** Planner writes a seed that "sets a `:down` journey" and asserts it renders — it never will.
**Why it happens:** Journeys are hardcoded in `mount/3`, independent of DB state.
**How to avoid:** Treat journey coverage for `mixed_status` as already satisfied by the existing hardcoded healthy+degraded mount; do not assert `:down` from a seeded page. Assert escalation/incident/action-item diversity instead.
**Warning signs:** A fixture-pin assertion looking for `journey_color(:down)` output on `/parapet`.

### Pitfall 3: Test depending on the dev DB
**What goes wrong:** A fixture-pin test that runs `mix run seeds.exs` or expects pre-seeded rows fails non-deterministically (the sandbox is empty per-test).
**Why it happens:** Demo seeds write the separate non-sandbox dev DB; the test sandbox is isolated and rolled back.
**How to avoid:** Drive `DemoApp.DemoSeedScenarios.seed("<name>")` **inside** the test (the sandbox is the active Repo because `Application.put_env(:parapet, :repo, DemoApp.Repo)` and `Parapet.Evidence.repo()` resolves to `DemoApp.Repo`, which is sandboxed in `ConnCase`). Then assert via `DemoApp.Repo.aggregate(...)`. This mirrors the existing self-seed convention (`operator_smoke_test.exs:57-68`).
**Warning signs:** Flaky counts; a test that passes only after a manual `mix run seeds.exs`.

### Pitfall 4: Gallery route swallowed by `/parapet/:id`
**What goes wrong:** `_gallery` is captured as an incident id → Ecto binary_id cast error / wrong LiveView.
**Why it happens:** Phoenix matches in declaration order; an earlier `:id` catch-all would swallow `_gallery`.
**How to avoid:** Nothing to do — `live_session :parapet_gallery` declares `/parapet/_gallery` **before** the operator session's `:id` catch-all (`router.ex:22-31`). The contract test confirms 200 (regression guard). Do **not** reorder routes.
**Warning signs:** `get("/parapet/_gallery")` returning a detail-LiveView render or a 500 cast error.

### Pitfall 5: Capture script `stress` seed missing an active incident
**What goes wrong:** `DETAIL_ID` query returns empty → script exits non-zero (`:42-45`).
**Why it happens:** The script requires ≥1 `open`/`investigating` incident for the detail screenshots.
**How to avoid:** `stress` (via `mixed_status` + `max_items`) must seed ≥1 active incident (D-06 guarantee). The `max_items` dense active set already satisfies this.
**Warning signs:** "Unable to select a demo incident id for detail screenshots."

### Pitfall 6: Headless-Chrome single-frame truncation for the gallery
**What goes wrong:** The gallery is a long scrolling page (19 components × states); a 1100px-tall window clips it.
**Why it happens:** `--screenshot` captures one viewport frame at `--window-size` height.
**How to avoid:** Use **tall** gallery window sizes (the sibling `gallery_preview.sh` uses `1440,5200` desktop / `414,7600` mobile `[VERIFIED: gallery_preview.sh:130-133]`). Reuse those heights for the new gallery captures in `capture_operator_ui_screenshots.sh` (the operator-page captures use `1440,1100` / `390,844` which are correct for those shorter pages — keep them).
**Warning signs:** Gallery PNG cut off mid-page.

### Pitfall 7: Quoting/portability in the bash capture script
**What goes wrong:** Spaces in `CHROME_BIN` path (macOS `/Applications/Google Chrome.app/...`) break unquoted expansion.
**Why it happens:** Already handled — the script quotes `"$CHROME_BIN"` everywhere.
**How to avoid:** New gallery captures must call the existing `capture()` helper (quoting is already correct) rather than inlining a new chrome invocation. Theme query-string branching (`?` vs `&`) is also handled by `capture()`. The gallery path has no query string, so `?parapet_theme=` is appended (the `else` branch) — correct.
**Warning signs:** "No such file or directory" for the chrome binary on macOS.

## Code Examples

### Gallery render contract test (D-10)
```elixir
# Source: pattern from operator_smoke_test.exs (existing ConnCase asserts)
test "GET /parapet/_gallery renders the operator-component gallery (DB-independent)", %{conn: conn} do
  conn = get(conn, "/parapet/_gallery")
  assert conn.status == 200
  # Stable operator-component markers (verified present in gallery_live.ex render):
  assert conn.resp_body =~ "parapet-ui"                      # gallery_live.ex:26
  assert conn.resp_body =~ "Parapet Operator UI Gallery"     # gallery_live.ex:28
  assert conn.resp_body =~ "po-operator-title"               # operator_nav rendered (components:543)
  assert conn.resp_body =~ "po-chip"                          # status chips rendered
end
```
Markers verified: `parapet-ui`, `Parapet Operator UI Gallery` `[VERIFIED: gallery_live.ex:26,28]`; `po-operator-title` + nav labels `Respond/Actions/History` come from `operator_nav` which the gallery renders `[VERIFIED: operator_components.ex.eex:543,546-548; gallery_live.ex:49]`. The gallery mount uses **only** in-memory fixtures (no Repo) — this test therefore also proves DB-independence `[VERIFIED: gallery_live.ex:7-21]`.

### Fixture-existence pin (D-11)
```elixir
# Source: self-seed convention from operator_smoke_test.exs:57-68
test "each new scenario seeds cleanly with the expected shape" do
  alias DemoApp.DemoSeedScenarios
  alias Parapet.Spine.Incident

  # registry: every new name is reported as valid
  for name <- ~w(long_string empty max_items mixed_status stress) do
    assert name in DemoSeedScenarios.scenarios()
  end

  # empty → zero incidents
  DemoSeedScenarios.seed("empty")
  assert DemoApp.Repo.aggregate(Incident, :count) == 0

  # max_items → crosses one queue page (page size 30)
  DemoSeedScenarios.seed("max_items")
  active = DemoApp.Repo.aggregate(
    from(i in Incident, where: i.state in ["open", "investigating"]), :count)
  assert active > 30

  # mixed_status → incidents across all three states (fresh sandbox per-test if split,
  # else assert distinct states present among seeded rows)
  # stress → ≥1 active incident (capture-script precondition)
end
```
**Sandbox safety:** `Parapet.Evidence.repo()` resolves to the configured `:parapet, :repo` = `DemoApp.Repo` (`config.exs:4`), which `ConnCase` checks out under the sandbox — so every seed helper writes the sandboxed test DB and rolls back `[VERIFIED: config.exs:4, conn_case.ex:20-28, evidence.ex:22]`. No `escalation_policy` is configured (`config.exs` has none), so `create_incident/1` does **not** enqueue an escalation worker job — runbook_data escalation is stored data only, fully test-safe `[VERIFIED: evidence.ex:71-85, config.exs:1-8]`.

**Note on per-scenario isolation:** If multiple `seed(...)` calls run in one test, counts accumulate within that test's sandbox. Prefer **one assertion per scenario** with `seed` near the assert, or split into separate `test` blocks (each gets a fresh sandbox). Either satisfies D-11; planner's discretion (D-12).

### Capture-script gallery extension (D-07)
```bash
# Source: append after the existing operator-page captures in capture_operator_ui_screenshots.sh
# Reuse the existing capture() helper; gallery needs no DB seed (server-up only).
# Use TALL windows (gallery is a long scrolling page — see gallery_preview.sh:130-133).
capture "operator-gallery-desktop-light" "1440,5200" "/parapet/_gallery" "light"
capture "operator-gallery-desktop-dark"  "1440,5200" "/parapet/_gallery" "dark"
capture "operator-gallery-mobile-light"  "414,7600"  "/parapet/_gallery" "light"
capture "operator-gallery-mobile-dark"   "414,7600"  "/parapet/_gallery" "dark"
```
The script is invoked after the demo server is up and the DB is seeded with `PARAPET_DEMO_SCENARIO=stress`. The gallery captures hit the same `BASE_URL` with no DB dependency `[VERIFIED: capture_operator_ui_screenshots.sh:30,69-82]`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Five demo scenarios (`response recovery escalation history all`) | Ten scenarios (+ `long_string empty max_items mixed_status stress`) | This phase | Audit re-runnable against worst-case data |
| Capture script covers operator pages only | + `/parapet/_gallery` (desktop+mobile, light+dark) | This phase (D-07) | Single canonical audit-capture script covers stress scenario + gallery |
| Gallery proven by manual walkthrough only | + automated render contract test | This phase (D-10) | Route regression + DB-independence pinned in CI |

**Deprecated/outdated:** None. No existing seed/script/test is removed or replaced — all additions are additive.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | (none) | — | All claims in this research were verified against the current source this session. The table is intentionally empty. |

**If this table is empty:** All claims were verified — no user confirmation needed. The two "clarifications" in the Summary (journeys hardcoded; escalation derived) are **verified facts**, not assumptions.

## Open Questions

1. **`mixed_status` action-item kind spread — how many distinct kinds to show?**
   - What we know: 5 valid kinds exist; only `state: "open"` items appear in the queue/actions view (`action_items_query/0`).
   - What's unclear: D-05 says "action items spanning the rendered kinds" without a count.
   - Recommendation: Seed one `open` ActionItem per kind (5 total), each attached to an active incident, so the Actions page shows all five rendered kinds. Cheap and exhaustive. (Claude's discretion per CONTEXT.)

2. **`max_items` exact count.**
   - What we know: ≥31 crosses page 1; D-04 suggests ~30–40.
   - Recommendation: 35 active incidents (clears the boundary with margin, keeps seed time low). (Claude's discretion.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | seeds + tests | ✓ (project builds) | — | — |
| PostgreSQL (`demo_app_dev`) | DB-backed capture + `mix run seeds.exs` | host-dependent | — | tests use Ecto sandbox; gallery preview is DB-less |
| headless Chrome/Chromium | `capture_operator_ui_screenshots.sh` gallery captures | host-dependent (`CHROME_BIN` auto-detect) | — | script exits with a clear message if absent; **not required for tests** |

**Missing dependencies with no fallback:** None for the test/seed path (sandbox + interpreted `.exs`). Chrome is only needed to *run* the capture script locally; the script already degrades with a clear error if Chrome is absent, and **Phase 49's test gate does not invoke the capture script** (it asserts the script's *coverage* via the gallery render test + fixture pins, not by executing headless Chrome in CI).

**Missing dependencies with fallback:** Postgres for the dev-DB capture path — fully covered for tests by the Ecto sandbox; the gallery preview path is DB-less by design.

## Validation Architecture

> nyquist_validation is enabled (key absent in `.planning/config.json` → treat as enabled).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) + `Phoenix.LiveViewTest` |
| Config file | `examples/demo_app/test/test_helper.exs` (+ `DemoAppWeb.ConnCase` support) |
| Quick run command | `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` |
| Full suite command | `cd examples/demo_app && mix test` (demo) — lib suite `mix test` from repo root |

### Phase Requirements → Test Map
| Req ID | Behavior (ground truth) | Test Type | Automated Command | File Exists? |
|--------|--------------------------|-----------|-------------------|-------------|
| FIXTURE-01 | `long_string` scenario seeds cleanly; produces ≥1 incident with long machine-shaped fields | unit (sandbox seed pin) | `mix test test/demo_app/operator_smoke_test.exs` | ✅ (extend) |
| FIXTURE-02 | `empty` seeds zero incidents; `DemoApp.Repo.aggregate(Incident,:count) == 0` after `seed("empty")` | unit (sandbox seed pin) | same | ✅ (extend) |
| FIXTURE-03 | `max_items` seeds >30 active incidents (crosses queue page boundary) | unit (sandbox seed pin) | same | ✅ (extend) |
| FIXTURE-04 | `mixed_status` seeds incidents across open/investigating/resolved + escalation states + action-item kinds | unit (sandbox seed pin) | same | ✅ (extend) |
| FIXTURE-05 | `stress` seeds the union and ≥1 active incident (capture-script precondition); each new name in `scenarios()` | unit (sandbox seed pin) | same | ✅ (extend) |
| GALLERY-02 | `GET /parapet/_gallery` → 200 with operator-component markers; DB-independent; route not swallowed by `:id` | integration (ConnCase render) | same | ✅ (extend) |
| GALLERY-02 (script) | Capture script *covers* `/parapet/_gallery` desktop+mobile, light+dark | static (script contains the 4 capture lines) — optional grep pin | `grep -c '_gallery' examples/demo_app/scripts/capture_operator_ui_screenshots.sh` ⇒ ≥4 | ❌ Wave 0 (optional) |

**Ground-truth definitions (what to assert / what is the "true" signal):**
- **`empty`:** ground truth = row count. Assert `Repo.aggregate(Incident, :count) == 0` (and `ActionItem` == 0) in a fresh sandbox after `seed("empty")`.
- **`max_items`:** ground truth = active-incident count vs page size. Assert `count(state ∈ active) > 30`. Optionally drive `Parapet.Operator.list_incident_queue(page_size: 30)` and assert `has_next_page?` is true (proves the *boundary*, not just the count) `[VERIFIED: operator.ex:78-105]`.
- **`mixed_status`:** ground truth = distinct rendered statuses. Assert seeded incidents span all three states (`MapSet` of `i.state` ⊇ `{"open","investigating","resolved"}`); assert ≥1 action item per kind exists (or that distinct kinds ≥ N); escalation diversity is implied by reusing the four existing escalation helpers (each derives a distinct status — already pinned by their presence). Journey diversity is **N/A-by-design** for seeds (hardcoded in mount) — document as such, do not assert a seeded `:down`.
- **`stress`:** ground truth = union + active guarantee. Assert ≥1 active incident exists (so the capture script's `DETAIL_ID` query would succeed) and that long-string + dense rows are present.
- **GALLERY-02 route:** ground truth = HTTP 200 + presence of operator-component markers in `resp_body` from a route served without any DB seed. The route-ordering regression (not swallowed by `:id`) is proven implicitly by the 200 + gallery-specific markers (a detail LiveView would render incident chrome, not "Parapet Operator UI Gallery").

### Sampling Rate
- **Per task commit:** `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` (quick — the smoke suite is small).
- **Per wave merge:** `cd examples/demo_app && mix test` (full demo suite) + `mix test` at repo root (lib suite) to confirm no template/contract regression.
- **Phase gate:** Both suites green before `/gsd-verify-work`. The capture script is run manually once (operator + gallery, stress-seeded) to eyeball PNGs into `tmp`; **no rasters committed** (D-09).

### Wave 0 Gaps
- [ ] No new test *files* required — extend `examples/demo_app/test/demo_app/operator_smoke_test.exs` (gallery contract + fixture pins). Framework already installed/wired.
- [ ] (Optional) a static grep pin that `capture_operator_ui_screenshots.sh` contains the four `_gallery` capture lines — cheap regression that the script keeps gallery coverage. Planner's discretion (D-12 "no proliferation").
- [ ] RED scaffold first (D-12): write the gallery contract assert + fixture pins asserting the new facts **before** the seed/script edits land (they fail RED — scenarios don't exist yet / `_gallery` markers may differ), then flip green when D-01..D-11 are implemented.

*(No `conftest`/fixture-module gap: `ConnCase` already provides the sandbox + `conn`.)*

## Security Domain

> `security_enforcement` key absent → treat as enabled. This phase is **demo-only seed data, a bash screenshot script, and tests** — no auth, no crypto, no network input handling, no public API surface. Most ASVS categories are N/A-by-design.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Demo routes are explicitly unauthenticated by design (`router.ex:13-15` warns "demo only"); not Phase 49's concern |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A (demo) |
| V5 Input Validation | minimal | Seed data is author-controlled (not user input). `ActionItem`/`Incident` changesets already validate `kind`/`state` inclusion — seeds must use valid enum values `[VERIFIED: action_item.ex:43-44, incident.ex:57]` |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Untrusted URL/id interpolated into markup | Tampering/XSS | N/A here — but note the **existing** Phase-48 invariant: the not-found panel renders `@requested_id` as **escaped text only** (never raw-interpolated). Long-string fixtures feed `external_link` URLs; Phoenix HEEx auto-escapes interpolated strings, so long machine-shaped URLs are safe to seed `[VERIFIED: 48-CONTEXT D-02]` |
| Bash injection via env in capture script | Tampering | `OUTPUT_DIR`/`BASE_URL`/`CHROME_BIN` are operator-supplied, all quoted in the existing script; new gallery captures reuse `capture()` (already quoted). No new unquoted expansion introduced |
| Postinstall/supply-chain | — | N/A — no package install this phase |

**Net:** No new attack surface. The single security-relevant rule for the planner: seed `kind`/`state` values from the **validated enum lists** (else the changeset raises), and let HEEx auto-escaping handle long-string URLs/IDs (it does).

## Sources

### Primary (HIGH confidence — read this session)
- `examples/demo_app/priv/repo/demo_seed_scenarios.exs` — `@scenarios` (`:4`), `seed/1` dispatch + typo-guard (`:8-42`), per-scenario helpers (`:44-346`), `append/3` (`:348-350`)
- `examples/demo_app/priv/repo/seeds.exs` — `PARAPET_DEMO_SCENARIO` read (`:7-8`)
- `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` — `DETAIL_ID` query (`:35-45`), `capture()` (`:47-67`), capture lines (`:69-82`)
- `examples/demo_app/scripts/gallery_preview.sh` — DB-less `--shot` (untouched); tall gallery window sizes (`:130-133`)
- `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex` — hardcoded fixtures, no Repo (`:7-21`); markers (`:26,28,49`)
- `examples/demo_app/lib/demo_app_web/router.ex` — `live_session :parapet_gallery` + route order (`:22-31`)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` — hardcoded journeys (`:14-19`)
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` — ConnCase sandbox self-seed convention; existing asserts
- `examples/demo_app/test/support/conn_case.ex` — sandbox checkout/shared mode (`:20-28`)
- `examples/demo_app/lib/demo_app/application.ex` — `PARAPET_DEMO_GALLERY_ONLY` drops Repo (`:12-22`)
- `examples/demo_app/config/config.exs` — `:parapet, repo: DemoApp.Repo`, no escalation_policy (`:1-8`)
- `lib/parapet/operator.ex` — `@active_queue_states`, page sizes (`:22-24`), `action_items_query/0` (`:52-57`), `list_incident_queue/1` (`:78-105`)
- `lib/parapet/operator/workbench_contract.ex` — `derive_escalation_summary/2` + `escalation_status/3` (`:267-349`)
- `lib/parapet/evidence.ex` — `create_incident/1` (`:58-69`, escalation enqueue guarded `:71-85`), `append_timeline/2` (`:91-95`), `repo/0` (`:22`)
- `lib/parapet/spine/action_item.ex` — `@kinds`, changeset validations (`:16-45`)
- `lib/parapet/spine/incident.ex` — state inclusion (`:57`)
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — `journey_color/1` (`:1565-1568`), escalation status copy/badge (`:1647-1667`), nav (`:543-548`)
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` — `@default_page_size 30` (`:8`), hardcoded journeys (`:14-19`)
- `.planning/config.json` — workflow flags (nyquist absent → enabled)

### Secondary (MEDIUM)
- `.planning/phases/49-stress-fixtures-seed-coverage/49-CONTEXT.md`, `.planning/phases/48-pages-flows-microcopy/48-CONTEXT.md` (D-16/D-17 overflow checklist, designed empty/not-found states)

### Tertiary (LOW)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all modules read this session.
- Architecture/patterns: HIGH — every seam, helper signature, and derivation path read in source.
- Pitfalls: HIGH — each pitfall traces to a verified line (journeys hardcoded, typo-guard, sandbox isolation, route order, capture preconditions, tall-window truncation).
- Validation: HIGH — test harness, sandbox config, and ground-truth signals all verified.

**Research date:** 2026-06-28
**Valid until:** 2026-07-28 (stable internal code; re-verify only if the demo seed module, router, or capture script changes)
