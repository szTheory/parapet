---
phase: 21-runnable-demo-app
verified: 2026-05-25T17:00:00Z
status: gaps_found
score: 2/4 success criteria fully verified
gaps:
  - truth: "Operator UI at /parapet loads populated with seeded incidents including resolved state"
    status: failed
    reason: "Viewing resolved incidents via the History tab crashes with KeyError: key :incident_id not found in %Parapet.Spine.Incident{}. resolved_history_page/1 passes raw %Incident{} structs to queue_stream_item/1 which accesses item.incident_id — a field that does not exist on the schema. CR-01 from code review is confirmed. Additionally, no assets/js/app.js and no esbuild wiring means the LiveView WebSocket never connects, making all phx-click events (Acknowledge, Resolve, Trigger Escalation, History navigation) silently non-functional (CR-02)."
    artifacts:
      - path: "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
        issue: "resolved_history_page/1 at line 336 calls queue_stream_item/1 with %Incident{} structs; queue_stream_item accesses item.incident_id (line 234) which raises KeyError. Fix: pass each incident through WorkbenchContract.queue_row/1 before queue_stream_item/1."
      - path: "examples/demo_app/lib/demo_app_web/components/layouts.ex"
        issue: "Root layout has no <script src=\"/assets/app.js\"> tag. assets/js/ directory does not exist. esbuild is not in mix.exs deps or aliases. Without phoenix.js + phoenix_live_view JS, the LiveView WebSocket connection is never established."
    missing:
      - "assets/js/app.js importing phoenix_html, phoenix, phoenix_live_view and calling liveSocket.connect()"
      - "esbuild dep + assets.build alias in mix.exs"
      - "<script src={~p\"/assets/app.js\"} defer> tag in DemoAppWeb.Layouts root/1"
      - "Fix resolved_history_page/1 to map incidents through WorkbenchContract.queue_row/1 before queue_stream_item/1"

  - truth: "release_gate is wired into branch protection as a required status check"
    status: failed
    reason: "GitHub branch protection is not configured on main (API returns 404 Branch not protected). The CI job wiring is correct (release_gate needs: [test, demo], no continue-on-error) but the outer gate — making release_gate a required status check that blocks merging — was not completed. The SUMMARY documents this as a one-time manual step remaining, with the human approving the checkpoint without actually configuring it."
    artifacts:
      - path: ".github/workflows/ci.yml"
        issue: "CI wiring is correct. The gap is GitHub Settings branch protection, not the workflow file."
    missing:
      - "Configure release_gate as a required status check on main branch: GitHub Settings → Branches → branch protection rule → Required status checks → add release_gate. Or via CLI after workflow has run: gh api -X PUT repos/szTheory/parapet/branches/main/protection/required_status_checks -f 'checks[][context]=release_gate'"

human_verification:
  - test: "Run mix setup && mix phx.server from examples/demo_app, navigate to http://localhost:4000/parapet, click the History tab"
    expected: "No KeyError crash; resolved incidents list renders correctly"
    why_human: "CR-01 is a runtime crash triggered by navigating to the resolved history view — only observable in a running server with a seeded database"
  - test: "After adding assets/js/app.js and esbuild wiring, navigate to /parapet and click an incident row to open its detail panel"
    expected: "Detail panel opens with timeline entries, tool audit, and runbook with warning step visible and interactive (Acknowledge/Resolve buttons respond)"
    why_human: "CR-02 (no JavaScript) means LiveView interactivity is entirely non-functional; must be verified in a browser after the JS fix"
---

# Phase 21: Runnable Demo App Verification Report

**Phase Goal:** A runnable demo Phoenix app crystallizes the frozen surface as a live CI contract test and makes the getting-started guide walkable end-to-end.
**Verified:** 2026-05-25T17:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix setup && mix phx.server` succeeds and the Operator UI at `/parapet` loads, populated with seeded incidents (open, investigating, resolved), timeline entries, a tool audit, a runbook with a `warning:` step, and registered WebSaaS SLO state | FAILED | Initial HTTP 200 is confirmed (smoke test passes). Open + investigating incidents render in the queue. But: (a) the History tab (resolved incidents) crashes with `KeyError: key :incident_id not found in %Parapet.Spine.Incident{}` — CR-01; (b) no `assets/js/app.js` exists, so the LiveView WebSocket never connects and all interactive events are silently dropped — CR-02. The "resolved" requirement of SC-1 cannot be met with the History tab crashing. |
| 2 | The `demo` CI job is wired into `release_gate` as a required check and goes red if the Operator UI stops returning 200 — `continue-on-error` is never set | PARTIAL | CI wiring is fully correct: `demo` job has postgres:16-alpine service, runs smoke test, `release_gate` has `needs: [test, demo]`, no `continue-on-error` anywhere. YAML validates. Gap: GitHub branch protection for `main` is not configured (API returns 404); `release_gate` is not a required status check on the branch. Human approved the checkpoint without actually configuring protection. |
| 3 | `mix hex.build --dry-run` confirms `examples/demo_app/` is absent from the published package | VERIFIED | Root `mix.exs` `files:` whitelist is `~w(lib priv .formatter.exs mix.exs README* CHANGELOG* CONTRIBUTING* SECURITY* CODE_OF_CONDUCT* LICENSE* docs)`. `examples/` is absent by omission. SUMMARY confirms hex.build output shows no `examples/` paths. |
| 4 | The getting-started guide links to the demo app as a "Next steps" reference | VERIFIED | `docs/getting-started.md` Next steps section contains: `[Runnable Demo App](https://github.com/szTheory/parapet/tree/main/examples/demo_app) — explore a live, seeded Parapet setup end-to-end: incidents, timeline entries, runbook steps, and the Operator UI populated and ready to browse` |

**Score:** 2/4 success criteria fully verified (SC-3 and SC-4). SC-1 fails on resolved incident display. SC-2 is partial (CI wiring done, branch protection not configured).

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/demo_app/mix.exs` | App metadata, path dep on parapet, deps, setup alias | VERIFIED | `{:parapet, path: "../.."}` present; `setup:` alias includes all required steps; `tailwind` dep added |
| `examples/demo_app/config/config.exs` | Parapet repo + WebSaaS provider registration | VERIFIED | `config :parapet, repo: DemoApp.Repo, providers: [Parapet.SLO.StarterPack.WebSaaS]` |
| `examples/demo_app/lib/demo_app/repo.ex` | Ecto repo for the demo app | VERIFIED | `use Ecto.Repo, otp_app: :demo_app, adapter: Ecto.Adapters.Postgres` |
| `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs` | Spine tables + runbook_data + trace_id | VERIFIED | All 5 tables created; `add :runbook_data, :map` and `add :trace_id, :string` present at lines 21-22 |
| `examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs` | Fix: kind + incident_id on action_items | VERIFIED | Added during Plan 03 to fix missing columns discovered by smoke test |
| `examples/demo_app/lib/demo_app_web/router.ex` | Open /parapet routes with WARNING comment | VERIFIED | `live "/parapet", DemoAppWeb.Parapet.OperatorLive, :index`; comment `# WARNING: demo only — do not copy to production.` present; no `OperatorLive.Index` |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` | Generated Operator queue LiveView | VERIFIED (with CR-01 bug) | `defmodule DemoAppWeb.Parapet.OperatorLive`, no unresolved EEx tags. Bug: `resolved_history_page/1` crashes on resolved incidents |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` | Generated Operator detail LiveView | VERIFIED | `defmodule DemoAppWeb.Parapet.OperatorDetailLive`, no unresolved EEx tags |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | Generated Operator components | VERIFIED (CR-02 affects interactivity) | `defmodule DemoAppWeb.Parapet.OperatorComponents`; 8 `phx-click` events that silently drop without JS |
| `examples/demo_app/lib/demo_app_web/components/layouts.ex` | Root layout with HTML shell | STUB | Exists and has `def root(assigns)` and `def app(assigns)`. Missing: no `<script>` tag for `app.js`, no CSRF meta tag |
| `examples/demo_app/assets/css/app.css` | Tailwind CSS layers | VERIFIED | Imports `tailwindcss/base`, `components`, `utilities` |
| `examples/demo_app/assets/tailwind.config.js` | Tailwind content globs | VERIFIED | Content includes `live/parapet` and parapet templates glob |
| `examples/demo_app/assets/js/app.js` | JavaScript entry point for LiveView | MISSING | Directory `assets/js/` does not exist. No phoenix.js or phoenix_live_view JS wired. |
| `examples/demo_app/priv/repo/seeds.exs` | Realistic seed data via Evidence Stable API | VERIFIED | 3 incidents (open/investigating/resolved) via `Parapet.Evidence.create_incident`; runbook with `"warning"` step; 6 timeline entries; 1 tool audit; no `source:`/`alert_name:` keys |
| `examples/demo_app/test/demo_app/operator_smoke_test.exs` | DEMO-03 smoke test | VERIFIED | `@moduletag :smoke`; `get(conn, "/parapet")` with `assert conn.status == 200`; self-contained sandbox insert for count assertion |
| `examples/demo_app/test/support/conn_case.ex` | Phoenix.ConnTest case template | VERIFIED | `use Phoenix.ConnTest`, `@endpoint DemoAppWeb.Endpoint`, Ecto sandbox checkout |
| `.github/workflows/ci.yml` | demo + release_gate CI jobs | VERIFIED (with branch-protection gap) | `demo:` job with `needs: [test]`, `postgres:16-alpine` service, smoke test; `release_gate:` with `needs: [test, demo]`; no `continue-on-error`; YAML valid |
| `docs/getting-started.md` | Next steps link to the demo app | VERIFIED | Runnable Demo App bullet appended to Next steps |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `config/config.exs` | `DemoApp.Repo` | `config :parapet, repo: DemoApp.Repo` | VERIFIED | Present at line 3 |
| `lib/demo_app/application.ex` | `DemoAppWeb.Endpoint` | supervision tree child | VERIFIED | `DemoAppWeb.Endpoint` in children list |
| `lib/demo_app_web/router.ex` | `DemoAppWeb.Parapet.OperatorLive` | `live "/parapet"` route | VERIFIED | Exact match; no `OperatorLive.Index` |
| `lib/demo_app_web/live/parapet/operator_live.ex` | `Parapet.Operator` | `list_incident_queue` / `incident_detail` calls | VERIFIED | `Parapet.Operator.incident_detail` and `Parapet.Operator.list_incident_queue` called |
| `priv/repo/seeds.exs` | `Parapet.Evidence` | `create_incident`/`append_timeline`/`log_tool_audit` | VERIFIED | All three Evidence API calls present; `{:ok, _} =` pattern-match for loud failures |
| `test/demo_app/operator_smoke_test.exs` | `DemoAppWeb.Endpoint` | `get(conn, "/parapet")` | VERIFIED | HTTP test wired to endpoint |
| `.github/workflows/ci.yml release_gate` | `test + demo jobs` | `needs: [test, demo]` | VERIFIED | Line 94: `needs: [test, demo]` |
| `.github/workflows/ci.yml demo` | `examples/demo_app smoke test` | `mix test --only smoke` | VERIFIED | Command present in Run smoke test step |
| `release_gate` | GitHub branch protection | Required status check | NOT WIRED | Branch protection returns 404 — not configured |
| `layouts.ex root/1` | `assets/app.js` | `<script>` tag | NOT WIRED | No script tag; `assets/js/app.js` does not exist |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `operator_live.ex` | `queue_page.items` (active queue) | `Parapet.Operator.list_incident_queue/1` | YES — queries `parapet_incidents` via Parapet library | FLOWING |
| `operator_live.ex` | `queue_page.items` (resolved history) | `resolved_history_page/1` direct Ecto query on `Parapet.Spine.Incident` | CRASHES before returning — `item.incident_id` KeyError on `%Incident{}` structs | DISCONNECTED (crash) |
| `operator_live.ex` | `journeys` | Hardcoded list in `mount/3` | Static — not from WebSaaS SLO provider | STATIC |
| `operator_live.ex` | `action_items` | `DemoApp.Repo.all(Parapet.Operator.action_items_query())` | YES — real DB query | FLOWING |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Smoke test passes (GET /parapet = 200) | `cd examples/demo_app && mix test --only smoke` | Reports `2 tests, 0 failures` (per SUMMARY-03) | PASS (static verification) |
| No `continue-on-error` in ci.yml | `grep -q 'continue-on-error' .github/workflows/ci.yml` | NOT_FOUND | PASS |
| YAML syntax valid | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"` | Exit 0 | PASS |
| No unresolved EEx tags in generated LiveViews | `grep -rq '<%=' examples/demo_app/lib/demo_app_web/live/parapet/` (unresolved generator assigns) | None found (file uses normal HEEx `<%= %>` for logic, not unresolved `<%= @web_module %>` generator assigns) | PASS |
| `assets/js/app.js` exists | `ls examples/demo_app/assets/js/` | Directory missing | FAIL |
| Branch protection configured | `gh api repos/szTheory/parapet/branches/main/protection` | 404 Branch not protected | FAIL |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DEMO-01 | Plans 01, 02 | Runnable demo Phoenix app serving Operator UI at `/parapet` | PARTIAL | App skeleton, migrations, LiveViews, router all correct. Fails: resolved History tab crashes (CR-01); no JS so LiveView non-interactive (CR-02) |
| DEMO-02 | Plan 03 | Demo seeded with realistic evidence (all states, timeline, tool audit, runbook warning, WebSaaS SLO) | PARTIAL | Seeds verified correct (all three states, 6 timeline entries, 1 tool audit, runbook with warning step, WebSaaS in config). Fails: resolved incidents viewable only after CR-01 fix |
| DEMO-03 | Plans 03, 04 | Smoke test as required CI gate (GET 200, count > 0, release_gate, no continue-on-error) | PARTIAL | Smoke test passes, CI wiring correct, no continue-on-error. Fails: branch protection not configured (release_gate not a required check) |
| DEMO-04 | Plan 04 | Demo excluded from Hex package + linked from getting-started guide | SATISFIED | `examples/` absent from `files:` whitelist; getting-started.md links demo |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `operator_live.ex` | 234, 336 | `item.incident_id` accessed on `%Parapet.Spine.Incident{}` which has no such field | BLOCKER | History tab crashes with KeyError for every visitor who clicks it; seeds create a resolved incident so this is triggered immediately in any seeded demo |
| `components/layouts.ex` | root/1 | No `<script>` tag; `assets/js/app.js` missing | BLOCKER | LiveView WebSocket never connects; all phx-click events silently dropped; Operator UI is non-interactive |
| `application.ex` | start/2 | `DemoApp.ParapetInstrumenter.setup/0` never called | WARNING | Metrics telemetry events not attached (IN-02 from review) |
| `demo_app_web.ex` | 73 | `import Phoenix.LiveView.Helpers` (deprecated shim) | WARNING | Compilation warnings; may break on future LiveView update (WR-03 from review) |
| `operator_components.ex` | 461 | `Application.get_env(:parapet, :scoria)[:ui_url_resolver]` crashes with `nil` when `:scoria` not configured | WARNING | `action_item_card/1` crashes if any action items are seeded (WR-01 from review) |

---

## Human Verification Required

### 1. History Tab — Resolved Incidents

**Test:** After fixing CR-01 (`resolved_history_page/1` → map through `WorkbenchContract.queue_row/1` before `queue_stream_item/1`), run `mix setup && mix phx.server` and click the "History" tab at `/parapet`.
**Expected:** Resolved incidents list renders without a crash; the seeded "Signup email delivery degraded" incident appears.
**Why human:** Runtime crash — only observable in a running server with a seeded database.

### 2. JavaScript / LiveView Interactivity

**Test:** After adding `assets/js/app.js`, esbuild wiring, and `<script>` tag in layouts.ex, run `mix assets.build && mix phx.server` and navigate to `/parapet`. Click an incident row to open its detail panel. Click "Acknowledge" on an open incident.
**Expected:** Detail panel opens and shows timeline entries, tool audit entry, and the runbook with the "High cardinality risk" warning callout. "Acknowledge" button successfully transitions the incident state.
**Why human:** CR-02 is a browser-side JS issue — requires visual verification that LiveView WebSocket connects and interactive events work.

### 3. Branch Protection — release_gate Required Check

**Test:** Verify `release_gate` is a required status check on `main`: `gh api repos/szTheory/parapet/branches/main/protection/required_status_checks --jq '.checks'`
**Expected:** Output includes `release_gate` in the required checks list.
**Why human:** GitHub branch protection settings are outside the repository and cannot be verified by grep. The API currently returns 404.

---

## Gaps Summary

Two gaps block the phase goal:

**Gap 1 — Operator UI cannot display resolved incidents (SC-1, DEMO-01, DEMO-02)**

`operator_live.ex:resolved_history_page/1` passes raw `%Parapet.Spine.Incident{}` structs to `queue_stream_item/1`, which accesses `item.incident_id`. The `Incident` struct has no `:incident_id` field — only `:id`. This crashes with `KeyError` whenever the History tab is activated. Since the seeds create a resolved incident, this crash is triggered immediately in any seeded demo. Fix: add `alias Parapet.Operator.WorkbenchContract` and change the `Enum.map` in `resolved_history_page/1` to pipe each incident through `WorkbenchContract.queue_row/1` before `queue_stream_item/1`.

Separately, the app has no `assets/js/app.js`, no esbuild wiring, and no `<script>` tag in the root layout. Without phoenix.js and phoenix_live_view JS loaded, the LiveView WebSocket never connects. All phx-click events (Acknowledge, Resolve, Trigger Escalation, Preview, Confirm, History navigation, queue refresh) are silently dropped. The demo renders as a static HTML snapshot rather than a live reactive UI.

**Gap 2 — Branch protection not configured (SC-2, DEMO-03)**

`release_gate` is correctly wired in ci.yml (`needs: [test, demo]`, no `continue-on-error`). However the outer gate — making `release_gate` a required status check that prevents merging a broken Operator UI — is not configured in GitHub branch protection. The `gh api` call during checkpoint returned 404. The human approved the checkpoint without completing this step. The fix is a one-time GitHub Settings or `gh api` command that must be executed after the workflow has run on at least one PR (so the check name is selectable).

---

_Verified: 2026-05-25T17:00:00Z_
_Verifier: Claude (gsd-verifier)_
