# Phase 3: Operator UI Performance - Research

**Researched:** 2026-05-20 [VERIFIED: current_date]
**Domain:** Phoenix LiveView operator queue performance, Ecto keyset pagination, and proof-at-scale for generated host-owned UI [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]
**Confidence:** MEDIUM [VERIFIED: synthesis of codebase + cited docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use hybrid paged cursor navigation with streamed rows in-page, not offset pagination and not feed-style infinite scroll. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-02:** Drive queue state from URL params via LiveView `handle_params/3` so views remain shareable, inspectable, and host-owned. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-03:** Make the queue cursor deterministic with a stable tie-breaker. The intended ordering shape is active-state bucket first, then `updated_at`, then unique `id`. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-04:** Stream only the current visible page/window into the DOM. Do not fetch or render the full incident list on mount. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-05:** The default queue is active-only: `open` and `investigating`. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-06:** Resolved incidents belong in a separate history view or explicit status filter, not inline in the default queue. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-07:** Query and index design should optimize active queue and resolved history separately. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-08:** Use a medium-density, evidence-first row design for the primary queue. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-09:** Each row should show bounded triage facts only: state, severity if present, symptom-first title, one compact secondary line from durable triage fields such as `integration`, `fault_plane`, `affected_journey`, or `queue`, plus a compact age/update indicator. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-10:** Allow at most one compact attention chip per row such as correlated change, approval pending, or escalation waiting. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-11:** Keep impact summary, next safe action, full evidence facts, escalation chain, external links, trace links, runbook steps, and chronology in the detail pane rather than the queue row. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-12:** Keep realtime awareness, but do not silently reorder the operator’s visible queue while they are reading it. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-13:** Use an explicit "new incidents / changes available" affordance for background updates instead of fully live queue reordering. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-14:** It is acceptable for selected-incident detail, counters, and status badges to update live while the queue itself stays operator-paced. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-15:** Phase 3 requires layered proof, not a single benchmark or a single test. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-16:** Add a deterministic seeded integration test that proves the generated UI no longer loads the full queue and instead uses bounded cursor/stream behavior. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-17:** Add a reproducible benchmark task for queue fetch plus first-render behavior at a 50k+ incident dataset. This benchmark is advisory or in a dedicated perf lane, not the default merge gate. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-18:** Add telemetry instrumentation around queue/list behavior as a public proof surface, while keeping labels low-cardinality. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-19:** For future gray-area discussions in this project, prefer research-first recommendation synthesis and recommended defaults over asking the user to decide every low-impact detail. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **D-20:** Only escalate choices back to the user when they materially affect product posture, operator semantics, public API, or architectural direction. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]

### Claude's Discretion
- Exact cursor token encoding and helper API surface [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- Exact page size inside the recommended bounded range [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- Exact queue chip vocabulary and truncation rules [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- Exact banner copy for "new incidents / changes available" [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- Exact telemetry event names and benchmark harness layout, as long as they remain coherent with existing telemetry/API discipline [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Rich card-style queue variants or compact-vs-comfortable density toggles — defer unless active operator usage proves a real need [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- History-focused analytics or retrospective browsing UX beyond a clean resolved-history view — separate phase/material scope [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- Fully live reordering queues or feed-style incident browsing — intentionally out of scope for the primary operator workbench [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCALE-01 | Operator UI Incident list utilizes efficient pagination or cursor-based scrolling to prevent large payload rendering issues. [VERIFIED: .planning/REQUIREMENTS.md] | Use active-only keyset pagination in `Parapet.Operator`, drive page state from `handle_params/3`, render only a bounded page via LiveView streams, and prove bounded behavior with deterministic tests plus an advisory 50k+ benchmark. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt] |
</phase_requirements>

## Summary

The current generator mounts by loading `Repo.all(Parapet.Operator.queue_query())` into `@incidents`, and the current queue query sorts all incidents by a computed active/resolved bucket plus `updated_at`, with no pagination, active-only filter, or stable `id` tie-breaker. That means the repo currently violates D-04 and does not yet satisfy the v0.9 queue-scaling requirement. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/REQUIREMENTS.md]

Phoenix LiveView 1.1.30 documents `handle_params/3` as the correct hook for URL-driven in-place state changes and documents streams as the mechanism for efficiently managing large collections, but it also warns that stream limits do not save an unbounded initial mount. PostgreSQL documents that large `OFFSET` values are inefficient and that paginated subsets need a unique `ORDER BY`. Those two facts make the recommended plan straightforward: bound the query first, use keyset pagination instead of offset pagination, and stream only the current page into the DOM. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt] [CITED: https://www.postgresql.org/docs/18/queries-limit.html]

Parapet should keep the public queue semantics inside `Parapet.Operator`, not inside generated LiveViews. The generated UI should become a thin host-owned adapter that reads URL params, calls a bounded Operator API, streams one page, and surfaces explicit "new incidents / changes available" refresh affordances without silent queue reordering. That matches the repo’s existing host-owned UI posture and the phase decisions. [VERIFIED: docs/operator-ui.md] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]

**Primary recommendation:** Add an active-only keyset pagination API to `Parapet.Operator`, back it with an index-aligned `updated_at`/`id` ordering, and refactor the generated LiveView to load and stream one URL-addressable page at a time. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [VERIFIED: lib/mix/tasks/parapet.gen.archive_indexes.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://www.postgresql.org/docs/18/queries-limit.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Active incident queue query shape | API / Backend [VERIFIED: reasoning over phase scope] | Database / Storage [VERIFIED: reasoning over phase scope] | `Parapet.Operator` is already the Phoenix-free queue boundary, and the queue must leverage database ordering/indexes rather than client-side filtering. [VERIFIED: lib/parapet/operator.ex] |
| Cursor parsing and page semantics | Frontend Server (SSR) [VERIFIED: reasoning over phase scope] | API / Backend [VERIFIED: reasoning over phase scope] | LiveView `handle_params/3` owns URL state, while the Operator boundary should validate and execute the bounded query semantics. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| DOM list rendering and bounded row updates | Frontend Server (SSR) [VERIFIED: reasoning over phase scope] | Browser / Client [VERIFIED: reasoning over phase scope] | LiveView streams push diffs, but the browser still pays for every rendered row, so the server must only render the current page/window. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt] |
| Query/index alignment | Database / Storage [VERIFIED: reasoning over phase scope] | API / Backend [VERIFIED: reasoning over phase scope] | The queue’s latency target depends on matching filter and sort keys to composite indexes; the current generated migration only adds `[:state, :inserted_at]`. [VERIFIED: lib/mix/tasks/parapet.gen.archive_indexes.ex] |
| Background freshness banner and manual refresh | Frontend Server (SSR) [VERIFIED: reasoning over phase scope] | API / Backend [VERIFIED: reasoning over phase scope] | Operator-paced freshness is a LiveView UX rule, but it depends on backend list metadata and low-cardinality telemetry. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] |
| Performance proof and telemetry | API / Backend [VERIFIED: reasoning over phase scope] | Frontend Server (SSR) [VERIFIED: reasoning over phase scope] | The benchmark and tests should measure query time, fetched row count, and first render behavior from the same public queue seam the generated UI uses. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [VERIFIED: docs/operator-ui.md] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | `1.1.30` locked; latest stable patch published 2026-05-05 [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] | URL-driven server-rendered operator UI, `handle_params/3`, and streams for bounded DOM updates [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt] | The phase decisions already require `handle_params/3` and streamed rows, and LiveView documents both patterns directly. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Ecto | `3.13.6` locked; latest stable published 2026-05-19 is `3.14.0` [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto] | Query composition for keyset filters, scoped status filters, and deterministic ordering [CITED: https://hexdocs.pm/ecto/Ecto.Query.html] | The queue should stay in explicit Ecto query code inside `Parapet.Operator`, which fits the repo’s data-first API posture. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: prompts/parapet-engineering-dna-from-sibling-libs.md] |
| Ecto SQL | `3.13.5` locked; latest stable published 2026-05-19 is `3.14.0` [VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto_sql] | Migration and index work for active-queue and history-query alignment [VERIFIED: lib/mix/tasks/parapet.gen.archive_indexes.ex] | This phase must exploit database indexes, not only UI diffing, and the repo already uses generated Ecto migrations for index work. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/mix/tasks/parapet.gen.archive_indexes.ex] |
| PostgreSQL ordering rules | Server capability, not an app dependency [CITED: https://www.postgresql.org/docs/18/queries-limit.html] [CITED: https://www.postgresql.org/docs/15/functions-comparisons.html] | Deterministic ordering and efficient keyset-style page boundaries | PostgreSQL explicitly warns about large `OFFSET` and requires unique ordering for stable subsets, which is exactly the incident queue problem. [CITED: https://www.postgresql.org/docs/18/queries-limit.html] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:telemetry` | Project dep `~> 1.2`; current lock is already present in the repo [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Low-cardinality proof surface for queue fetch count, fetch duration, render count, and refresh-banner events [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] | Use for public perf proof events; do not emit per-incident IDs or cursor values. [VERIFIED: .planning/PROJECT.md] [VERIFIED: prompts/parapet-engineering-dna-from-sibling-libs.md] |
| Benchee | Latest stable `1.5.0`, published 2025-10-21 [VERIFIED: mix hex.info benchee] | Advisory reproducible benchmark lane for 50k+ seeded incidents [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] | Use in a `bench/` or dedicated Mix task lane, not the default CI merge gate. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [CITED: https://github.com/bencheeorg/benchee/blob/main/README.md] |
| Benchee HTML | Latest stable `1.0.1`, published 2023-12-27 [VERIFIED: mix hex.info benchee_html] | Optional artifact output if maintainers want visual benchmark reports | Use only if a human-friendly perf report is valuable; it is not required for the phase’s acceptance proof. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom queue-specific keyset helper in `Parapet.Operator` [VERIFIED: recommendation synthesis] | Flop + FlopPhoenix `0.26.x` components [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/flop_phoenix] | Flop is solid for generic filter/sort/pagination UIs, but this phase has fixed operator semantics, a host-owned generator seam, and explicit cursor rules, so a narrow first-party helper is the better fit. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [VERIFIED: docs/operator-ui.md] |
| Hybrid paged cursor navigation [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] | Feed-style infinite scrolling with viewport events [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt] | LiveView supports viewport-driven stream pagination, but the phase explicitly rejects feed-style browsing because silent reordering is bad for mutable operator queues. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] |
| Keyset pagination [VERIFIED: recommendation synthesis] | `LIMIT/OFFSET` pagination [CITED: https://www.postgresql.org/docs/18/queries-limit.html] | PostgreSQL documents that large offsets are inefficient and that page subsets need unique ordering, so offset pagination is the wrong default for a 50k+ mutable queue. [CITED: https://www.postgresql.org/docs/18/queries-limit.html] |

**Installation:** No new runtime dependency is required for the queue refactor itself because Phoenix LiveView, Ecto, and Ecto SQL are already locked in the repo. [VERIFIED: mix.exs] [VERIFIED: mix.lock]

```elixir
# Optional advisory benchmark lane only
{:benchee, "~> 1.5", only: :dev, runtime: false}
```

```bash
mix deps.get
```

**Version verification:** Phoenix `1.8.7` was published 2026-05-06, Phoenix LiveView `1.1.30` was published 2026-05-05, Ecto `3.14.0` and Ecto SQL `3.14.0` were published 2026-05-19, and Benchee `1.5.0` was published 2025-10-21. The repo is already locked to Phoenix `1.8.7`, LiveView `1.1.30`, Ecto `3.13.6`, and Ecto SQL `3.13.5`, so the plan should target the current lock unless a separate dependency-upgrade task is introduced. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info benchee]

## Architecture Patterns

### System Architecture Diagram

```text
Browser
  -> URL params (`cursor`, `dir`, optional `id`) [VERIFIED: phase decision D-02]
LiveView `handle_params/3`
  -> validate params and derive page request [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
  -> call `Parapet.Operator.list_active_incidents/1` [VERIFIED: recommendation synthesis]
Parapet.Operator
  -> build active-only Ecto query
  -> apply deterministic keyset boundary (`updated_at`, `id`)
  -> fetch `limit + 1` rows to compute page info [VERIFIED: recommendation synthesis]
Repo / PostgreSQL
  -> use composite index aligned to `state`, `updated_at`, `id` [VERIFIED: recommendation synthesis]
Parapet.Operator
  -> return `%{rows, page_info, freshness_snapshot}` [VERIFIED: recommendation synthesis]
LiveView
  -> `stream(..., reset: true)` the current page only [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt]
  -> render evidence-first medium-density rows [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
Realtime updates
  -> update counters/detail live
  -> set "changes available" banner without mutating visible page order [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
Proof surfaces
  -> ExUnit seeded boundedness tests
  -> advisory Benchee 50k+ lane
  -> low-cardinality telemetry events [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
```

### Recommended Project Structure

```text
lib/
├── parapet/operator.ex                     # Public queue/detail boundary; add bounded queue API here
├── parapet/operator/queue_cursor.ex        # Cursor encode/decode + validation helper if extracted
└── mix/tasks/                              # Optional advisory benchmark Mix task if bench/ is not preferred

priv/
└── templates/parapet.gen.ui/
   ├── operator_live.ex.eex                # URL params + stream wiring
   └── operator_components.ex.eex          # Stream-backed queue rows + refresh affordance

test/
├── parapet/operator/queue_pagination_test.exs
├── parapet/operator_ui_integration_test.exs
└── mix/tasks/parapet.gen.ui_test.exs

bench/
└── operator_ui_perf.exs                   # Advisory 50k+ benchmark harness
```

### Pattern 1: Public Active-Queue Page API
**What:** Replace `queue_query/0` as the generated UI’s primary list entrypoint with a bounded page API such as `list_active_incidents(opts)` that returns rows plus cursor metadata. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: recommendation synthesis]
**When to use:** Use for the default active queue and any history view introduced later; keep raw `queue_query/0` internal or deprecated for generated UI usage. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
**Example:**

```elixir
# Source patterns: Ecto dynamic/order_by interpolation and LiveView URL-param loading
# https://hexdocs.pm/ecto/Ecto.Query.html
# https://hexdocs.pm/phoenix_live_view/live-navigation.html
def list_active_incidents(%{after: after_cursor, limit: limit}) do
  base =
    from(i in Incident,
      where: i.state in ["open", "investigating"],
      order_by: [desc: i.updated_at, desc: i.id],
      limit: ^(limit + 1)
    )

  query =
    case after_cursor do
      nil ->
        base

      %{updated_at: updated_at, id: id} ->
        from(i in base,
          where: i.updated_at < ^updated_at or
                   (i.updated_at == ^updated_at and i.id < ^id)
        )
    end

  rows = Evidence.repo().all(query)
  # trim to `limit`, compute next cursor, return page info
end
```

### Pattern 2: `handle_params/3` Owns Queue Navigation
**What:** Keep queue page, selected incident, and explicit refresh actions in URL params so navigation stays shareable and inspectable. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
**When to use:** Use for initial load, next/previous page, row selection, and refresh-banner acknowledgement. [VERIFIED: phase scope]
**Example:**

```elixir
# Source: https://hexdocs.pm/phoenix_live_view/live-navigation.html
def handle_params(params, _uri, socket) do
  page_request = parse_queue_params(params)
  %{rows: rows, page_info: page_info} = Parapet.Operator.list_active_incidents(page_request)

  {:noreply,
   socket
   |> assign(:page_info, page_info)
   |> stream(:incidents, rows, reset: true)}
end
```

### Pattern 3: Stream the Current Page, Not the Whole Queue
**What:** Use LiveView streams for diff-friendly page replacement, but always pair them with a bounded query result because stream limits do not protect an oversized first mount. [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt]
**When to use:** Use for page replacement and for inserting background refresh results only after the operator explicitly accepts them. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
**Example:**

```heex
<!-- Source pattern: https://context7.com/phoenixframework/phoenix_live_view/llms.txt -->
<div id="incident-list" phx-update="stream">
  <div :for={{dom_id, incident} <- @streams.incidents} id={dom_id}>
    <.incident_row incident={incident} selected_id={@selected_id} />
  </div>
</div>
```

### Anti-Patterns to Avoid
- **Mount-time `Repo.all(queue_query())`:** This is the current generator behavior and it hard-fails the 50k+ requirement because every active incident is loaded and rendered before any stream diffing can help. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
- **`LIMIT/OFFSET` for the main mutable queue:** PostgreSQL documents that large offsets are inefficient and paged subsets require unique ordering, so offset-based browsing is the wrong default here. [CITED: https://www.postgresql.org/docs/18/queries-limit.html]
- **Queue reordering on background updates:** The phase explicitly rejects silently moving visible incidents while the operator is reading. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- **Putting cursor logic into HEEx templates:** The repo’s existing posture is a Phoenix-free Operator seam with host-owned generated UI, so query semantics belong in `Parapet.Operator`, not in ad hoc template branches. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: docs/operator-ui.md]
- **Using only `updated_at` as the sort key:** PostgreSQL requires a unique order for stable subsets, so `id` must be the deterministic tie-breaker. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [CITED: https://www.postgresql.org/docs/18/queries-limit.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Large-list DOM retention | A client-side virtual list or bespoke JS scroller [VERIFIED: recommendation synthesis] | LiveView streams plus bounded server-side pages [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt] | The product is intentionally host-owned, Phoenix-first, and server-rendered; the phase only needs one bounded page in the DOM, not a custom virtualization subsystem. [VERIFIED: docs/operator-ui.md] |
| Generic table state engine | A broad filtering/sorting framework for this one queue [VERIFIED: recommendation synthesis] | A narrow first-party queue page helper in `Parapet.Operator` [VERIFIED: lib/parapet/operator.ex] | The queue semantics are already product-specific and operator-sensitive, so a small explicit helper is lower-risk than a generic abstraction. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] |
| Ad hoc perf measurement | One-off `IO.inspect` timing or wall-clock shell scripts [VERIFIED: recommendation synthesis] | Benchee advisory benchmark + deterministic ExUnit assertions [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [CITED: https://github.com/bencheeorg/benchee/blob/main/README.md] | This phase needs repeatable proof, not anecdotes. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] |
| Queue freshness side state | Hidden client-side queue snapshots [VERIFIED: recommendation synthesis] | Explicit server-owned `changes_available?` banner state [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] | Hidden state undermines inspectability and operator trust. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] |

**Key insight:** Phase 3 is not primarily a rendering problem. It is a query-boundary problem first, a URL-state problem second, and a DOM-diff problem third. If the first query is not bounded and deterministic, every other optimization is cosmetic. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt] [CITED: https://www.postgresql.org/docs/18/queries-limit.html]

## Common Pitfalls

### Pitfall 1: Assuming streams fix an unbounded first render
**What goes wrong:** The LiveView uses streams but still loads the full active queue on mount, so the initial query and initial HTML payload stay huge. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
**Why it happens:** LiveView stream limits apply on the client after items are streamed; the docs explicitly note the first `mount/3` render must already be bounded. [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt]
**How to avoid:** Fetch only the current page from `Parapet.Operator` before calling `stream(..., reset: true)`. [VERIFIED: recommendation synthesis]
**Warning signs:** `mount/3` still calls `Repo.all(queue_query())`, or the page assigns contain a plain full `@incidents` list. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]

### Pitfall 2: Using unstable ordering across pages
**What goes wrong:** Incidents duplicate, disappear, or jump pages when several rows share the same `updated_at`. [VERIFIED: recommendation synthesis]
**Why it happens:** PostgreSQL warns that pagination subsets need a unique order, and the phase decisions already require `id` as the stable tie-breaker. [CITED: https://www.postgresql.org/docs/18/queries-limit.html] [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
**How to avoid:** Order by `updated_at DESC, id DESC` within the active queue and encode both values in the cursor boundary. [VERIFIED: recommendation synthesis]
**Warning signs:** Tests only assert `updated_at` ordering or benchmark data includes duplicate timestamps with paging failures. [VERIFIED: recommendation synthesis]

### Pitfall 3: Keeping the current computed bucket sort for the active queue
**What goes wrong:** The query keeps a `CASE` expression that groups active before resolved even though the default queue is active-only, reducing the planner’s chance to use a simple composite index. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
**Why it happens:** The current `queue_query/0` still reflects the older combined active/resolved list shape. [VERIFIED: lib/parapet/operator.ex]
**How to avoid:** Split active queue and resolved history query APIs so the default queue uses `WHERE state IN (...)` with index-aligned sort keys. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [VERIFIED: recommendation synthesis]
**Warning signs:** `EXPLAIN` continues to show sort work on the queue query after Phase 2 index work. [ASSUMED]

### Pitfall 4: Silent queue mutation from realtime updates
**What goes wrong:** A websocket update moves rows while an operator is reading, which breaks calm triage and least-surprise browsing. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
**Why it happens:** LiveView makes it easy to stream inserts immediately, but the product posture explicitly rejects feed-style queue behavior. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [VERIFIED: prompts/parapet-brand-identity-deep-research.md]
**How to avoid:** Update counters and selected-incident detail live, but buffer queue changes behind a `changes_available?` affordance that repatches or reloads the current page on demand. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
**Warning signs:** Background update handlers call `stream_insert/4` into the visible queue without a user action. [VERIFIED: recommendation synthesis]

## Code Examples

Verified patterns from official sources:

### URL-state updates with `handle_params/3`
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/live-navigation.html
def handle_params(params, _uri, socket) do
  socket =
    case params["sort_by"] do
      sort_by when sort_by in ~w(name company) -> assign(socket, sort_by: sort_by)
      _ -> socket
    end

  {:noreply, load_users(socket)}
end
```

### Stream-backed template container
```heex
<!-- Source: https://context7.com/phoenixframework/phoenix_live_view/llms.txt -->
<div id="posts" phx-update="stream">
  <div :for={{dom_id, post} <- @streams.posts} id={dom_id}>
    {post.title}
  </div>
</div>
```

### Dynamic `order_by` interpolation in Ecto
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Query.html
values = [asc: :name, desc_nulls_first: :population]
from(c in City, order_by: ^values)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Load all rows into `@incidents` on mount and render them with a plain `for` loop [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [VERIFIED: priv/templates/parapet.gen.ui/operator_components.ex.eex] | Use `handle_params/3` for URL-owned page changes and LiveView streams for bounded collection updates [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt] | LiveView streams are documented in the current LiveView 1.1.x docs and examples, and the repo is already locked to 1.1.30. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] | The generated operator UI can keep server-rendered ergonomics without paying the cost of rendering the whole queue. [VERIFIED: recommendation synthesis] |
| Offset pagination for long tables [CITED: https://www.postgresql.org/docs/18/queries-limit.html] | Keyset pagination with deterministic tie-breakers [VERIFIED: recommendation synthesis] | PostgreSQL has long documented offset inefficiency and the need for unique ordering. [CITED: https://www.postgresql.org/docs/18/queries-limit.html] | Better scaling and more stable browsing under a mutable incident queue. [VERIFIED: recommendation synthesis] |
| Combined active-and-resolved queue with computed bucket sort [VERIFIED: lib/parapet/operator.ex] | Active queue and resolved history queried separately [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] | This phase’s locked decisions define active-only as the default queue. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] | Simpler index alignment and calmer operator semantics. [VERIFIED: recommendation synthesis] |

**Deprecated/outdated:**
- `queue_query/0` as the generated UI’s main list seam is outdated for v0.9 because it currently returns an unbounded query and still mixes active/resolved ordering assumptions. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `EXPLAIN` should improve after replacing the computed bucket sort with active-only filtering and an index-aligned sort. [ASSUMED] | Common Pitfalls | If the host app’s real schema or data distribution behaves differently, the plan may need an extra index or a different query split. |

## Open Questions (RESOLVED)

1. **Does Phase 3 need a user-visible resolved-history screen now, or only the active-queue performance seam?**
   - Resolution: Phase 3 must ship the active-queue performance seam and storage/query alignment for a separate resolved-history path, but it does not need a full new resolved-history screen in this phase. Plans should ensure resolved incidents are no longer part of the default queue and that generator-backed indexes support a later explicit history surface. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]

2. **What page size should the phase standardize on for proof and UX?**
   - Resolution: Use `30` rows per page as the default queue and benchmark target for planning and proof. This aligns with the UI design contract, stays bounded for first render, and still exercises the queue/page behavior meaningfully in the perf lane. [VERIFIED: .planning/v0.9-phases/3/03-UI-SPEC.md] [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Implementation, tests, benchmark task | ✓ [VERIFIED: elixir --version] | `1.19.5` [VERIFIED: elixir --version] | — |
| Mix | Tests, generator verification, benchmark task | ✓ [VERIFIED: mix --version] | `1.19.5` [VERIFIED: mix --version] | — |
| Node.js | Research-time `ctx7` CLI fallback only, not phase implementation [VERIFIED: execution audit] | ✓ [VERIFIED: node --version] | `v22.14.0` [VERIFIED: node --version] | — |
| `npx` | Research-time `ctx7` CLI fallback only, not phase implementation [VERIFIED: execution audit] | ✓ [VERIFIED: npx --version] | `11.1.0` [VERIFIED: npx --version] | — |

**Missing dependencies with no fallback:**
- None for planning or implementation on this machine. [VERIFIED: execution audit]

**Missing dependencies with fallback:**
- Benchee is not currently declared in `mix.exs`, but the benchmark lane can be added as a dev-only dependency without affecting runtime consumers. [VERIFIED: mix.exs] [VERIFIED: mix hex.info benchee]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit [VERIFIED: test/test_helper.exs] |
| Config file | `test/test_helper.exs` [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/parapet/operator_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs -x` [VERIFIED: repository inspection] |
| Full suite command | `mix test` [VERIFIED: .github/workflows/ci.yml] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCALE-01 | Queue API fetches only a bounded page with deterministic cursor semantics and active-only default scope. [VERIFIED: .planning/REQUIREMENTS.md] | unit/integration | `mix test test/parapet/operator/queue_pagination_test.exs -x` | ❌ Wave 0 [VERIFIED: repository inspection] |
| SCALE-01 | Generated LiveView uses `handle_params/3` + streams instead of loading all incidents on mount. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] | generator integration | `mix test test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs -x` | Partial; new assertions needed [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs] |
| SCALE-01 | 50k+ queue fetch plus first-render behavior is reproducibly benchmarked outside the default gate. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md] | advisory perf | `mix run bench/operator_ui_perf.exs` or equivalent dedicated task [ASSUMED] | ❌ Wave 0 [VERIFIED: repository inspection] |

### Sampling Rate
- **Per task commit:** `mix test test/parapet/operator_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs -x` [VERIFIED: repository inspection]
- **Per wave merge:** `mix test` [VERIFIED: .github/workflows/ci.yml]
- **Phase gate:** Full suite green plus advisory perf lane captured in phase artifacts before `/gsd-verify-work`. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]

### Wave 0 Gaps
- [ ] `test/parapet/operator/queue_pagination_test.exs` — deterministic keyset boundary, active-only scope, and tie-breaker coverage for `updated_at`/`id`. [VERIFIED: repository inspection]
- [ ] Extend `test/parapet/operator_ui_integration_test.exs` — assert generated UI no longer contains mount-time `Repo.all(queue_query())` and does contain stream wiring plus `handle_params/3` pagination behavior. [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
- [ ] `bench/operator_ui_perf.exs` or dedicated Mix task — advisory 50k+ fetch + first-render benchmark. [VERIFIED: repository inspection]
- [ ] Add dev-only Benchee dependency if the benchmark lane is accepted. [VERIFIED: mix.exs] [VERIFIED: mix hex.info benchee]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: docs/operator-ui.md] | Keep generated LiveViews mounted inside host-owned authenticated `live_session`/router scope; Parapet’s doctor already checks for unsafe mounts. [VERIFIED: docs/operator-ui.md] [VERIFIED: test/parapet/operator_ui_integration_test.exs] |
| V3 Session Management | no [VERIFIED: phase scope] | Host app session handling remains out of scope for this phase. [VERIFIED: docs/operator-ui.md] |
| V4 Access Control | yes [VERIFIED: docs/operator-ui.md] | Queue browsing must stay behind host authorization, and cursor params must never widen scope beyond authorized incidents. [VERIFIED: docs/operator-ui.md] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| V5 Input Validation | yes [VERIFIED: phase scope] | Validate `handle_params/3` cursor/page inputs and fall back to the first page on invalid params. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| V6 Cryptography | no [VERIFIED: recommendation synthesis] | This phase does not require cryptographic features if cursor params are treated as validated navigation state rather than a privilege-bearing secret. [ASSUMED] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oversized or malformed queue params causing heavy queries | Denial of service | Clamp page size, validate cursor structure in `handle_params/3`, and reject invalid values to the first page. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Unauthorized exposure of operator routes | Information disclosure | Preserve host-authenticated LiveView mounting and doctor verification; do not move queue data into a public endpoint. [VERIFIED: docs/operator-ui.md] [VERIFIED: test/parapet/operator_ui_integration_test.exs] |
| High-cardinality perf telemetry | Denial of service / information disclosure | Emit only bounded labels such as queue scope, direction, page size bucket, and result bucket; never emit incident IDs or cursor values. [VERIFIED: .planning/PROJECT.md] [VERIFIED: prompts/parapet-engineering-dna-from-sibling-libs.md] |

## Sources

### Primary (HIGH confidence)
- `lib/parapet/operator.ex` — current public queue/detail seam and existing queue ordering. [VERIFIED: lib/parapet/operator.ex]
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` — current mount-time full queue load and UI state shape. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — current queue row rendering shape. [VERIFIED: priv/templates/parapet.gen.ui/operator_components.ex.eex]
- `lib/mix/tasks/parapet.gen.archive_indexes.ex` — currently generated queue-related indexes. [VERIFIED: lib/mix/tasks/parapet.gen.archive_indexes.ex]
- `docs/operator-ui.md` — host-owned UI posture and security guidance. [VERIFIED: docs/operator-ui.md]
- `mix.lock` and `mix hex.info {phoenix,phoenix_live_view,ecto,ecto_sql,benchee}` — locked and latest package versions with release dates. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info benchee]
- Phoenix LiveView live navigation docs — `handle_params/3`, `push_patch/2`, and URL-owned state. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
- Phoenix LiveView stream examples via Context7 — stream container requirements, reset, and the warning that mount must already be bounded. [CITED: https://context7.com/phoenixframework/phoenix_live_view/llms.txt]
- Ecto query docs — dynamic query and `order_by` interpolation patterns. [CITED: https://hexdocs.pm/ecto/Ecto.Query.html]
- PostgreSQL docs — `LIMIT/OFFSET` caveats and row comparison semantics. [CITED: https://www.postgresql.org/docs/18/queries-limit.html] [CITED: https://www.postgresql.org/docs/15/functions-comparisons.html]
- Benchee README/docs — repeatable benchmark configuration with timing and memory measurement. [CITED: https://github.com/bencheeorg/benchee/blob/main/README.md]

### Secondary (MEDIUM confidence)
- `https://hex.pm/packages/flop_phoenix` — package positioning for the alternative considered section. [CITED: https://hex.pm/packages/flop_phoenix]

### Tertiary (LOW confidence)
- None. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - The repo’s actual dependency lock and the current official docs/releases were verified directly. [VERIFIED: mix.lock] [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto]
- Architecture: MEDIUM - The main direction is strongly supported by locked phase decisions and official docs, but exact queue API shape and page-size defaults remain implementation discretion. [VERIFIED: .planning/v0.9-phases/3/3-CONTEXT.md]
- Pitfalls: HIGH - The current codebase already exhibits the main failure mode, and the offset/ordering issues are explicitly documented upstream. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] [CITED: https://www.postgresql.org/docs/18/queries-limit.html]

**Research date:** 2026-05-20 [VERIFIED: current_date]
**Valid until:** 2026-06-19 because Phoenix/LiveView and Hex package release cadence is active enough that package-version guidance should be refreshed within 30 days. [VERIFIED: mix hex.info phoenix_live_view] [VERIFIED: mix hex.info ecto]
