# Phase 48: Pages, flows & microcopy - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-26
**Phase:** 48-pages-flows-microcopy
**Mode:** assumptions (+ 6 parallel advisor-researcher deep-dives at user request)
**Areas analyzed:** Page semantics & titles · Empty/loading/error states · Not-found / no-data ·
Flow & back-nav & compat route · Microcopy & voice · Mobile 390px · Test-gate strategy

## Assumptions Presented

### Page semantics / single h1 (FLOW-02, A11Y-06)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Two h1s on every page; demote `incident_summary` h1 → h2, keep nav as single page h1 | Confident | `operator_components.ex.eex:543` (nav h1) + `:840` (summary h1) |

### Page title (FLOW-02, A11Y-06)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Host owns `<.live_title>`; generated LiveViews assign `:page_title`; patch demo layout to prove it | Confident | `layouts.ex:12` hardcoded "Demo App"; no `:page_title` assign in templates |

### Empty / loading / error states (FLOW-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Empty states exist; loading = connected/disconnected skeleton (extend to Actions/History); permission-denied = N/A-by-design | Confident | skeleton `operator_live.ex.eex:247`; empties `:613,728,781,961`; auth host-owned `router_snippet:2-3` |

### Not-found incident detail (FLOW-03 + FLOW-04) — the fork
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `incident_detail/1` `Repo.get!` raises on bad `/parapet/:id` (no designed no-data state) | Likely → Confident | `operator.ex:117` `get!`; binary_id PK ⇒ NoResultsError (404) + CastError (500) |

### Flow & compat route (FLOW-01, FLOW-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No dead-ends; `/parapet/:id` resolves alongside `/parapet/incidents/:id`; add ordering guard | Confident | `router_snippet:16-17`; integration asserts `:71-77,334-339` |

### Microcopy & voice (COPY-01..05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| COPY-04 already passes; re-author flash errors + runbook/preview fallbacks; leave `_copy/1` pinned helpers | Confident | grep clean; pinned strings `operator_ui_integration_test.exs:186-196` |

### Mobile 390px + test gate (FLOW-05, cross-cutting)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 390px mostly handled; residual values-only; one-h1 count must be scoped per rendered page; 4-wave cadence, no new test files | Confident | Phase 45-47 stacking; `operator_components` defines 2 legit h1s |

## Corrections Made

No assumptions were rejected. The user's directive: for each area, **research deeply via
subagents** (pros/cons/tradeoffs, Elixir/Phoenix/Ecto idiom, ecosystem lessons from sibling
libs/successful tools, DX/UX, brandbook + `prompts/` research, JTBD lenses, accessibility/
performance pillars) and **one-shot a coherent locked recommendation**. Six parallel
`gsd-advisor-researcher` agents ran; their decisive recommendations were synthesized verbatim into
CONTEXT.md decisions D-01..D-19.

### Not-found fork — user decision
- **Question:** how to handle `Repo.get!` raising on a stale `/parapet/:id`.
- **User chose:** "Fix it — designed not-found state."
- **Research refinement:** implement as an **additive** `fetch_incident_detail/1 ::
  {:ok,_}|{:error,:not_found}` (precheck `Ecto.UUID.cast/1` + `Repo.get` nil-guard, collapsing
  both `NoResultsError` and `Ecto.Query.CastError` — the malformed-id 500 is the real bug), keep
  the public `incident_detail/1` nil-tolerant with unchanged success-shape (no breaking change),
  and render a designed in-page panel that keeps operator orientation (no `push_navigate` away,
  no host error page). Locked in D-01/D-02.

## External Research

Six `gsd-advisor-researcher` subagents (web + repo grounded). Key sources cited:
- **Not-found:** ecto#909 (get! wrong exception on invalid UUID), elixirforum CastError→500 vs
  NoResultsError→404, phoenix_ecto `Plug.Exception`. → additive nil-safe fetch + dual-exception
  collapse + designed panel.
- **Page semantics:** Phoenix LiveView live-layouts / `live_title` (prefix/suffix/default). →
  per-live_action `:page_title` assign + demo-layout patch + distinct per-page h1 + heading-level
  prop on the shared `incident_summary`.
- **Empty/loading:** LiveView dead-vs-live render (#3551), stuck-loading-bar (#1193). →
  skeleton-or-nothing, extend uniformly, gate empty on `@socket_connected`, one empty-state
  anatomy, unavailable/permission-denied = N/A-by-design.
- **Microcopy:** incident.io realtime-response, PagerDuty incident-response. → 10 strings
  re-authored (+1 harmonized), `inspect` dropped from flashes, state-unchanged-first error copy,
  pinned helpers untouched.
- **Mobile 390px:** Tailwind max-height / dvh classes. → R1–R7 values-only fixes (preview
  bottom-sheet height bound is the top severity — clipped Confirm blocks recovery) + 9-point
  responsive checklist.
- **Test gate:** Phoenix.LiveViewTest (`page_title/1`, `element/2`, render). → split source-string
  vs rendered (demo `operator_smoke_test.exs`); single-h1 via regex count (not Floki — `lazy_html`
  backend; not source grep); bounded COPY-04 regex; 4-wave cadence, no new test files.
