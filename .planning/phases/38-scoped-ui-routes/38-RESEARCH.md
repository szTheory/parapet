# Phase 38: Scoped UI Routes - Research

**Researched:** 2026-06-04 [VERIFIED: gsd init.phase-op]
**Domain:** Phoenix LiveView generated UI route scoping in host-owned generated code [VERIFIED: .planning/phases/38-scoped-ui-routes/38-CONTEXT.md]
**Confidence:** HIGH [VERIFIED: codebase grep + official Phoenix/LiveView docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

All constraints in this section are copied from `.planning/phases/38-scoped-ui-routes/38-CONTEXT.md`. [VERIFIED: file read]

### Locked Decisions
## Implementation Decisions

### Route Base Ownership
- **D-01:** Keep route ownership in generated, host-owned UI files. Add or preserve a generated base-path seam that defaults to `/parapet` and can represent nested mounts such as `/ops/parapet`.
- **D-02:** Prefer an inspectable generated-code approach over a Parapet-owned router framework. Acceptable implementation shapes include deriving the base path from the current LiveView URI or generating an explicit editable base-path helper/default in the scaffold, provided the host remains in control.

### Route Surface Coverage
- **D-03:** Cover all route-producing surfaces in the generated Operator UI, not just top-level navigation links: `push_patch`, `push_navigate`, `navigate`, `patch`, `href`, back links, queue pagination, history links, and incident detail links.
- **D-04:** Include form/submit surfaces in the audit, but do not invent form route handling unless planning finds an actual route-bearing form action. Current mutating controls appear to be LiveView events/buttons, not submitted forms.

### Demo And Generated-Copy Proof
- **D-05:** Test-pin both generated template behavior and checked-in demo copies for the default `/parapet` mount and one scoped mount such as `/ops/parapet`.
- **D-06:** Treat template/demo drift as a phase failure. The generator and runnable demo must prove the same route behavior, not just one or the other.

### Stability Boundaries
- **D-07:** Do not add new runtime dependencies, stable public APIs, auth behavior, or Parapet-owned router modules in Phase 38.
- **D-08:** Keep changes scoped to generated UI templates, demo copies, generator guidance, docs/guidance that directly support the route seam, and tests.
- **D-09:** Preserve the existing compile-out boundary: Parapet core must not gain a direct Phoenix or LiveView runtime dependency.

### the agent's Discretion
- Exact base-path helper name, storage location, and function signatures inside generated host-owned modules.
- Whether scoped behavior is proven through existing generated compile tests, a focused generated-vs-demo contract test, or both, provided both default and scoped mounts are pinned.
- Exact scoped example path, though `/ops/parapet` is preferred because it matches the phase prompt and host-owned admin-scope use case.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Broader adoption docs for default and scoped mounting belong to Phase 39, except for minimal generator guidance required to make Phase 38 understandable.
- Archive maintenance docs and quality-evaluation closeout belong to Phase 39.
- Multi-tenant/operator-per-org UI semantics remain out of scope for v1.4.
- Parapet-owned router modules, global route-helper replacement, auth policy changes, and new dependencies are explicitly out of scope.

### Reviewed Todos (not folded)

None.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UIROUTE-01 | Generated Operator UI route helpers, links, redirects, forms, and LiveView patches respect a host-owned base path when mounted under a non-default scope such as `/ops/parapet`. [VERIFIED: .planning/REQUIREMENTS.md] | Use generated route helper functions that derive or accept `operator_base_path`, then route every `push_patch`, `push_navigate`, `navigate`, `patch`, `href`, back link, queue pagination, history link, and incident detail link through those helpers. [VERIFIED: codebase grep; CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] |
| UIROUTE-02 | The generated template and demo app copy stay synchronized and test-pinned for both default `/parapet` and scoped route mounting. [VERIFIED: .planning/REQUIREMENTS.md] | Extend generator output tests, generated LiveView render tests, demo contract tests, and demo copied-file assertions to cover `/parapet` and `/ops/parapet`. [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs + test/parapet/operator_ui_demo_contract_test.exs] |
| UIROUTE-03 | Scoped-route support does not change Parapet's auth ownership, router ownership, public API stability tier, or dependency surface. [VERIFIED: .planning/REQUIREMENTS.md] | Keep changes in generated host-owned files, demo copies, router guidance, docs, and tests; preserve compile-out tests that reject direct `:phoenix` and `:phoenix_live_view` dependencies in core. [VERIFIED: test/parapet/operator_ui_compile_out_test.exs + mix.exs] |
</phase_requirements>

## Summary

Phase 38 should be planned as a generated-code route-normalization pass, not as a new routing abstraction. [VERIFIED: .planning/phases/38-scoped-ui-routes/38-CONTEXT.md] The current generated templates and checked-in demo copies emit literal `/parapet` paths from `operator_live`, `operator_detail_live`, and `operator_components`, including LiveView `patch`, `navigate`, `push_patch`, `push_navigate`, queue pagination, history links, incident detail links, and one plain history anchor. [VERIFIED: codebase grep]

The most planner-friendly implementation is an explicit generated `operator_base_path` seam that defaults to `/parapet`, derives `/ops/parapet` from the current `handle_params/3` URI, and is passed into components as an assign. [VERIFIED: .planning/phases/38-scoped-ui-routes/38-CONTEXT.md; CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] Phoenix LiveView invokes `handle_params/3` after `mount/3` and before initial render, and again for live patches, so it is the right place to capture the current scoped URL for route generation. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]

**Primary recommendation:** Add generated, editable path helpers in host-owned LiveViews/components, derive the base path from the current URI by taking the path through the final `parapet` segment, and test both generated and demo copies for `/parapet` and `/ops/parapet`. [VERIFIED: codebase grep; CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html]

## Project Constraints (from AGENTS.md)

- Use a recommendation-first, codebase-first planning and execution posture by default. [VERIFIED: AGENTS.md]
- Treat `.planning/config.json` `workflow.discuss_mode = "assumptions"` as the repo's default interactive posture. [VERIFIED: AGENTS.md + .planning/config.json]
- Auto-decide low-impact implementation details and state assumptions in artifacts instead of asking routine questions. [VERIFIED: AGENTS.md]
- Escalate for changes to public CLI/API contract, default install contents, auth ownership, dependency/support surface, runtime behavior, safety guarantees, operator semantics, durable evidence truth model, irreversible schema/maintenance burden, or two medium-impact concerns at once. [VERIFIED: AGENTS.md]
- Do not widen product scope, milestone status claims, runtime guarantees, or governance based on AGENTS.md. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Operator UI base-path derivation | Frontend Server / LiveView | Browser / Client | LiveView receives the current URI in `handle_params/3`; client links consume already-rendered local paths. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] |
| Router mount scope | Host Phoenix Router | Generated UI guidance | Phoenix `scope` prefixes route paths, and Parapet decisions keep router ownership with the host app. [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html; VERIFIED: 38-CONTEXT.md] |
| Route-producing UI helpers | Generated host-owned UI modules | Parapet generator templates | `mix parapet.gen.ui` writes LiveViews/components into host web namespace and the templates currently own route string construction. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex + priv/templates/parapet.gen.ui/*.eex] |
| Auth and authorization | Host Phoenix app | `parapet.doctor` warning checks | Existing docs and doctor checks require authenticated host scopes; Phase 38 must not take auth ownership. [VERIFIED: docs/operator-ui.md + lib/mix/tasks/parapet.doctor.ex + 38-CONTEXT.md] |
| Public API and dependency surface | Parapet core | Tests | Existing compile-out tests verify core does not depend directly on Phoenix or LiveView. [VERIFIED: test/parapet/operator_ui_compile_out_test.exs + mix.exs] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | Elixir 1.19.5, Mix 1.19.5 | Build and test runtime for this repo. | Project declares `elixir: "~> 1.19"` and local toolchain matches. [VERIFIED: mix.exs + elixir --version] |
| Phoenix | locked 1.8.7 | Host app router semantics and LiveView host framework. | Demo app uses Phoenix, but Parapet core must not add direct Phoenix dependency. [VERIFIED: mix deps + examples/demo_app/mix.exs + test/parapet/operator_ui_compile_out_test.exs] |
| Phoenix LiveView | locked 1.1.30 | Generated Operator UI modules use LiveView navigation, patching, and component rendering. | Current generated templates call LiveView APIs and docs define `patch`, `navigate`, `push_patch`, and `push_navigate` semantics. [VERIFIED: mix deps + priv/templates/parapet.gen.ui/*.eex; CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] |
| Igniter | locked 0.7.9 | Code generation for `mix parapet.gen.ui`. | Existing generator is an Igniter Mix task and tests use `Igniter.Test`. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex + test/mix/tasks/parapet.gen.ui_test.exs] |
| ExUnit | bundled with Elixir | Generator, contract, compile-out, and generated LiveView tests. | Existing tests are ExUnit modules under `test/`. [VERIFIED: rg --files test] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Ecto / Ecto SQL | locked 3.13.6 / 3.13.5 in root project | Existing generated LiveView queue/history data access. | Keep existing generated query behavior unchanged while altering route paths. [VERIFIED: mix deps + priv/templates/parapet.gen.ui/operator_live.ex.eex] |
| Phoenix.Component | from LiveView 1.1.x | Component attrs and HEEx link rendering. | Use component attrs such as `operator_base_path` when passing route base into generated components. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Generated local path helpers | `Phoenix.VerifiedRoutes` `~p` | `~p` verifies static routes against a router, but this phase has host-owned, editable generated files and dynamic scope derivation, so route verification would either require host router coupling or new generated setup. [CITED: https://phoenix.hexdocs.pm/Phoenix.VerifiedRoutes.html; VERIFIED: 38-CONTEXT.md] |
| Deriving base from current URI | Explicit constant only, e.g. `@operator_base_path "/parapet"` | A constant is simple but requires manual host editing for nested scopes; deriving from URI proves default and nested mounts without changing CLI/API. [VERIFIED: 38-CONTEXT.md; VERIFIED: codebase grep] |
| Parapet-owned router module | Library route framework | Explicitly out of scope and would violate router ownership and dependency boundaries. [VERIFIED: 38-CONTEXT.md + .planning/REQUIREMENTS.md] |

**Installation:** No package installation is recommended for Phase 38. [VERIFIED: 38-CONTEXT.md + mix.exs]

**Version verification:** `mix deps` reports Phoenix 1.8.7, Phoenix LiveView 1.1.30, Igniter 0.7.9, Ecto 3.13.6, and Ecto SQL 3.13.5 in the root project. [VERIFIED: mix deps]

## Package Legitimacy Audit

No new external packages should be installed in Phase 38. [VERIFIED: 38-CONTEXT.md] Slopcheck is not required because this phase should not add packages. [VERIFIED: package_legitimacy_protocol applies only to phases that install external packages]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | n/a | n/a | n/a | n/a | n/a | No install recommended. [VERIFIED: 38-CONTEXT.md] |

**Packages removed due to slopcheck [SLOP] verdict:** none. [VERIFIED: no package install]
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package install]

## Architecture Patterns

### System Architecture Diagram

```text
Host router scope
  /parapet OR /ops/parapet
        |
        v
Generated OperatorLive / OperatorDetailLive
  mount/3 -> default assigns
  handle_params(params, uri, socket)
        |
        v
derive operator_base_path from URI path through final "parapet" segment
        |
        +--> push_patch / push_navigate helpers
        |
        +--> render(assigns)
               |
               v
        OperatorComponents receive operator_base_path
               |
               +--> nav links
               +--> queue patches and pagination
               +--> history links
               +--> incident detail links
               +--> back links
```

This diagram represents the recommended data flow for generated host-owned code. [VERIFIED: codebase grep; CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]

### Recommended Project Structure

```text
priv/templates/parapet.gen.ui/
├── operator_live.ex.eex          # derive/pass base path and build queue/history paths
├── operator_detail_live.ex.eex   # derive/pass base path and build detail/back redirects
├── operator_components.ex.eex    # accept base path attr and build component links
└── router_snippet.ex.eex         # document default and nested host scopes

examples/demo_app/lib/demo_app_web/
├── router.ex                     # checked-in demo route map
└── live/parapet/*.ex             # generated-copy files kept in sync

test/
├── mix/tasks/parapet.gen.ui_test.exs
└── parapet/*operator_ui*_test.exs
```

The files above are the current implementation and proof surface for the generated Operator UI. [VERIFIED: rg --files]

### Pattern 1: Generated Base-Path Helper

**What:** Generate local helpers that normalize the current LiveView URI into an `operator_base_path`, defaulting to `/parapet`. [VERIFIED: 38-CONTEXT.md]
**When to use:** Use this in `handle_params/3` for `OperatorLive` and `OperatorDetailLive`, then store the result in socket assigns. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]
**Example:**

```elixir
# Source: recommended generated-code pattern from Phase 38 context and LiveView handle_params docs.
def handle_params(params, uri, socket) do
  operator_base_path = operator_base_path(uri)

  {:noreply,
   socket
   |> assign(:operator_base_path, operator_base_path)
   |> assign(...)}
end

defp operator_base_path(uri) when is_binary(uri) do
  uri
  |> URI.parse()
  |> Map.get(:path)
  |> operator_base_path_from_path()
end

defp operator_base_path_from_path(path) when is_binary(path) do
  segments = String.split(path, "/", trim: true)

  case Enum.find_index(Enum.reverse(segments), &(&1 == "parapet")) do
    nil ->
      "/parapet"

    reverse_index ->
      keep = length(segments) - reverse_index
      "/" <> Enum.join(Enum.take(segments, keep), "/")
  end
end

defp operator_base_path_from_path(_path), do: "/parapet"
```

### Pattern 2: One Route Builder Per Route Concept

**What:** Generate helpers such as `operator_path(base_path)`, `operator_path(base_path, :actions)`, `operator_path(base_path, :history)`, `incident_detail_path(base_path, incident)`, and `queue_path(base_path, queue_params, extra_params)`. [VERIFIED: current helpers exist as `queue_path`, `queue_base_path`, `history_path`, and `incident_detail_path` in templates]
**When to use:** Use this for every route-producing surface instead of embedding `/parapet` in HEEx or event handlers. [VERIFIED: codebase grep]
**Example:**

```elixir
# Source: adapted from current queue_path helper in operator_live.ex.eex.
defp operator_path(base_path), do: base_path
defp operator_path(base_path, :actions), do: base_path <> "/actions"
defp operator_path(base_path, :history), do: base_path <> "/history"
defp operator_path(base_path, {:incident, id}), do: base_path <> "/incidents/#{id}"
```

### Pattern 3: Pass Base Path Into Components Explicitly

**What:** Generated components should accept `operator_base_path` as an attr or assign and use it for nav, queue, history, and detail links. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]
**When to use:** Use for `operator_nav`, `action_center`, `incident_list`, and any component that renders a local Operator UI link. [VERIFIED: codebase grep]
**Example:**

```elixir
# Source: Phoenix.Component attr docs + current generated component structure.
attr :active, :atom, required: true
attr :operator_base_path, :string, default: "/parapet"

def operator_nav(assigns) do
  ~H"""
  <.nav_item href={operator_path(@operator_base_path)} active={@active == :response}>Respond</.nav_item>
  <.nav_item href={operator_path(@operator_base_path, :actions)} active={@active == :actions}>Actions</.nav_item>
  <.nav_item href={operator_path(@operator_base_path, :history)} active={@active == :history}>History</.nav_item>
  """
end
```

### Anti-Patterns to Avoid

- **Literal `/parapet` links outside base-path helpers:** This is the current failure mode for nested host scopes. [VERIFIED: codebase grep]
- **Using `push_patch` for detail LiveView navigation:** LiveView docs say patch is for the current LiveView; detail routes that mount `OperatorDetailLive` should use `navigate`/`push_navigate`. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]
- **Introducing Parapet router/auth modules:** This violates locked phase boundaries and public dependency posture. [VERIFIED: 38-CONTEXT.md]
- **Adding Phoenix/LiveView to Parapet core deps:** Existing compile-out tests reject direct core dependencies on `:phoenix` and `:phoenix_live_view`. [VERIFIED: test/parapet/operator_ui_compile_out_test.exs]
- **Only updating templates and not demo copies:** Template/demo drift is a locked phase failure. [VERIFIED: 38-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LiveView navigation semantics | Custom JS router or browser history shim | Phoenix LiveView `patch`, `navigate`, `push_patch`, `push_navigate` | LiveView already defines current-LiveView patching and same-session navigation behavior. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] |
| Query-string encoding | Manual string concatenation for query params | `URI.encode_query/1` | Existing generated code already uses `URI.encode_query/1`. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] |
| Host router ownership | Parapet-owned router module | Host router plus generated router snippet | Phoenix supports scoped routes, and Phase 38 requires host-owned router scope. [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html; VERIFIED: 38-CONTEXT.md] |
| Route surface discovery | Ad hoc visual QA only | `rg` audits plus generated/demo contract tests | Existing failures are literal strings and testable rendered hrefs/patches. [VERIFIED: codebase grep + test files] |

**Key insight:** The hard part is route-surface completeness, not path concatenation. [VERIFIED: codebase grep] Plan tasks should first enumerate every route-bearing surface, then replace them through a small generated helper set and assert no nested-scope render leaks unscoped local paths. [VERIFIED: 38-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Updating Nav Only
**What goes wrong:** `/ops/parapet` nav works but queue pagination, history rows, detail redirects, or back links still go to `/parapet`. [VERIFIED: codebase grep]
**Why it happens:** Current literals are spread across three template files and demo copies. [VERIFIED: codebase grep]
**How to avoid:** Use a route-surface checklist covering `push_patch`, `push_navigate`, `navigate`, `patch`, `href`, back links, queue pagination, history links, and incident detail links. [VERIFIED: 38-CONTEXT.md]
**Warning signs:** Tests only assert `operator_nav` or only grep one template. [VERIFIED: existing tests currently assert literal detail/nav paths]

### Pitfall 2: Losing LiveView Semantics
**What goes wrong:** Queue selection remounts the LiveView or detail navigation tries to patch across LiveViews. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]
**Why it happens:** `patch` and `navigate` look interchangeable but have different LiveView lifecycle behavior. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]
**How to avoid:** Keep queue/pagination/history-within-current-LiveView on `patch`/`push_patch`, and keep detail LiveView transitions on `navigate`/`push_navigate`. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html; VERIFIED: current template structure]
**Warning signs:** `patch={incident_detail_path(...)}` or `push_patch(to: detail_path(...))` appears in generated code. [VERIFIED: current detail uses `navigate`, not `patch`]

### Pitfall 3: Base Path Not Available On Initial Render
**What goes wrong:** First disconnected render emits `/parapet` before `handle_params/3` assigns the scoped base path. [ASSUMED]
**Why it happens:** Generated components default to `/parapet` unless the LiveView assigns a scoped base before rendering. [ASSUMED]
**How to avoid:** Keep a safe default in `mount/3`, then assign the derived base in `handle_params/3`; LiveView docs state `handle_params/3` is invoked after mount and before initial render. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]
**Warning signs:** Render tests call `mount/3` and `render/1` without `handle_params/3` and expect scoped links. [VERIFIED: generated_operator_live_paging_test.exs currently calls both]

### Pitfall 4: Treating Route Scope As Auth Ownership
**What goes wrong:** Planner adds auth hooks, new auth modules, or router ownership changes while solving path scope. [VERIFIED: 38-CONTEXT.md]
**Why it happens:** Router scope and authenticated scope are adjacent in Phoenix routers. [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html]
**How to avoid:** Only update generated path construction and minimal route guidance; leave auth policy and `live_session` ownership to host code. [VERIFIED: 38-CONTEXT.md + docs/operator-ui.md]
**Warning signs:** Changes to `Parapet.Operator`, public API manifest, or new Phoenix dependencies in `mix.exs`. [VERIFIED: priv/parapet/public_api_stable.json + mix.exs]

## Code Examples

Verified patterns from official sources and existing code:

### LiveView Patch For Current LiveView

```elixir
# Source: LiveView docs and current generated queue_path usage.
{:noreply, push_patch(socket, to: queue_path(@operator_base_path, queue_params, extra_params))}
```

Use this for queue filtering, selected incident query params, and pagination within `OperatorLive`. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html; VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex]

### LiveView Navigate For Detail LiveView

```elixir
# Source: LiveView docs and current generated detail redirect usage.
{:noreply, push_navigate(socket, to: operator_path(@operator_base_path, {:incident, id}))}
```

Use this when transitioning to or remounting `OperatorDetailLive`. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html; VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex]

### Scoped Render Assertion

```elixir
# Source: existing generated LiveView compile/render test pattern.
socket = configured_socket(live_module, URI.parse("http://example.com/ops/parapet/history"))
{:ok, socket} = live_module.mount(%{}, %{}, socket)
socket = Phoenix.Component.assign(socket, :live_action, :history)
{:noreply, socket} = live_module.handle_params(%{}, "http://example.com/ops/parapet/history", socket)
html = render_live(live_module, socket)

assert html =~ ~s[href="/ops/parapet/incidents/]
refute html =~ ~s[href="/parapet]
```

Use this pattern for default and nested route render proofs. [VERIFIED: test/parapet/generated_operator_live_paging_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phoenix helper modules as the only route-generation path | Phoenix VerifiedRoutes `~p` and explicit `path/2`/`path/3` for runtime conn/socket/URI cases | Phoenix 1.7+ era [ASSUMED] | Verified routes are useful in host app code, but Phase 38 should avoid coupling generated library templates to a Parapet-owned router. [CITED: https://phoenix.hexdocs.pm/Phoenix.VerifiedRoutes.html; VERIFIED: 38-CONTEXT.md] |
| LiveView `live_patch` / `live_redirect` helpers | `<.link patch={...}>`, `<.link navigate={...}>`, `push_patch/2`, `push_navigate/2` | LiveView 0.18+ era [ASSUMED] | Current generated code already uses the modern `<.link>` API. [VERIFIED: priv/templates/parapet.gen.ui/*.eex; CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html] |

**Deprecated/outdated:**
- Global route-helper replacement is not appropriate for Phase 38 because router ownership remains with the host and no public routing API should be added. [VERIFIED: 38-CONTEXT.md]
- Custom client-side routing is not appropriate because LiveView already provides local patch and navigation semantics. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Initial disconnected render could leak `/parapet` before `handle_params/3` unless tests include the actual LiveView lifecycle. | Common Pitfalls | Low; LiveView docs say `handle_params/3` runs before initial render, but tests should still model the lifecycle. |
| A2 | Phoenix helper-to-VerifiedRoutes transition timing is Phoenix 1.7+ era. | State of the Art | Low; historical timing does not affect Phase 38 implementation. |
| A3 | LiveView `<.link>` replacement of older helpers is LiveView 0.18+ era. | State of the Art | Low; current generated code already uses `<.link>`. |

## Open Questions

1. **Should demo router itself add `/ops/parapet` routes or should tests simulate scoped URI only?**
   - What we know: Phase requires generated templates and demo copy behavior for default and one scoped mount. [VERIFIED: 38-CONTEXT.md]
   - What's unclear: The context does not lock whether the runnable demo router must expose both route maps at once. [VERIFIED: 38-CONTEXT.md]
   - Recommendation: Keep the demo's default route map stable and add a generated/demo-copy render contract for `/ops/parapet`; only add demo scoped routes if smoke tests need an actual runnable endpoint. [ASSUMED]

2. **Should compatibility detail route `/parapet/:id` remain generated for nested scopes?**
   - What we know: Current route map includes preferred `/parapet/incidents/:id` and compatibility `/parapet/:id`. [VERIFIED: router_snippet.ex.eex + docs/operator-ui.md]
   - What's unclear: Phase 38 does not explicitly decide whether nested examples must include both preferred and compatibility routes. [VERIFIED: 38-CONTEXT.md]
   - Recommendation: Preserve both route shapes under any host scope because removing compatibility would alter route behavior. [VERIFIED: 38-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Compile/test generated code | yes | 1.19.5 | none needed. [VERIFIED: elixir --version] |
| Mix | Test and generator tasks | yes | 1.19.5 | none needed. [VERIFIED: mix --version] |
| Git | Optional research commit | yes | 2.41.0 | none needed. [VERIFIED: git --version] |
| Docker | Demo smoke path if planner chooses full demo app run | yes | 29.5.2 | Use ExUnit render tests if Docker is unnecessary. [VERIFIED: docker --version] |
| Chromium | Existing demo screenshot script path if planner broadens smoke proof | yes | `/opt/homebrew/bin/chromium` | Use ExUnit route contract tests for this phase. [VERIFIED: command -v chromium] |
| Context7 CLI | Docs lookup | no | n/a | Official HexDocs web pages were used. [VERIFIED: command -v ctx7] |

**Missing dependencies with no fallback:** none found for the recommended plan. [VERIFIED: environment audit]

**Missing dependencies with fallback:** Context7 CLI is unavailable; official Phoenix and LiveView HexDocs were used instead. [VERIFIED: command -v ctx7; CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix. [VERIFIED: test files + mix.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: rg --files test] |
| Quick run command | `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_demo_contract_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` [VERIFIED: test files exist] |
| Full suite command | `mix test` [VERIFIED: Mix/ExUnit project] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| UIROUTE-01 | Generated links, patches, redirects, and route helpers render `/parapet` by default and `/ops/parapet` when mounted under nested scope. | unit/render contract | `mix test test/parapet/generated_operator_live_paging_test.exs test/mix/tasks/parapet.gen.ui_test.exs` | yes; needs scoped assertions. [VERIFIED: test files] |
| UIROUTE-02 | Template and demo copy stay synchronized for default and scoped route behavior. | contract | `mix test test/parapet/operator_ui_demo_contract_test.exs test/parapet/operator_ui_integration_test.exs` | yes; needs scoped synchronization assertions. [VERIFIED: test files] |
| UIROUTE-03 | No auth/router/API/dependency ownership change. | regression/static | `mix test test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_integration_test.exs` | yes; may need stronger no-new-dep/public-API assertion. [VERIFIED: test files] |

### Sampling Rate

- **Per task commit:** run the quick route-focused command above. [VERIFIED: existing targeted test lane in docs/operator-ui.md]
- **Per wave merge:** run `mix test`. [VERIFIED: Mix/ExUnit project]
- **Phase gate:** full suite green before `$gsd-verify-work`. [VERIFIED: GSD workflow expectation]

### Wave 0 Gaps

- [ ] Add scoped route assertions to `test/parapet/generated_operator_live_paging_test.exs` for `/ops/parapet`, including history detail links and queue patches. [VERIFIED: existing file]
- [ ] Add generator output assertions in `test/mix/tasks/parapet.gen.ui_test.exs` for the generated base-path seam and absence of raw local `/parapet` literals outside helper/default definitions. [VERIFIED: existing file]
- [ ] Add demo-copy scoped assertions in `test/parapet/operator_ui_demo_contract_test.exs` or `test/parapet/operator_ui_integration_test.exs`. [VERIFIED: existing files]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Host app authenticated scope and `live_session`; Parapet must not own auth. [VERIFIED: docs/operator-ui.md + 38-CONTEXT.md] |
| V3 Session Management | yes | Host Phoenix session and LiveView `fetch_live_flash`; no change in Phase 38. [VERIFIED: examples/demo_app/lib/demo_app_web/router.ex] |
| V4 Access Control | yes | Host-owned authorization policies; generated UI remains inside host scope. [VERIFIED: docs/operator-ui.md + 38-CONTEXT.md] |
| V5 Input Validation | yes | Preserve existing event parsing such as `Integer.parse(minutes)` and route/query handling through `URI.encode_query/1`. [VERIFIED: operator_detail_live.ex.eex + operator_live.ex.eex] |
| V6 Cryptography | no direct change | Do not add cryptography or token handling in this phase. [VERIFIED: 38-CONTEXT.md] |

### Known Threat Patterns for Phoenix LiveView Generated Route Scoping

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Auth bypass by moving routes outside protected scope | Elevation of privilege | Keep auth/router ownership in host router guidance and preserve doctor warning checks. [VERIFIED: docs/operator-ui.md + lib/mix/tasks/parapet.doctor.ex] |
| Open redirect or external navigation injection | Tampering | Generate local paths only; LiveView `push_patch` and `push_navigate` `:to` options require local paths. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html] |
| Scoped path confusion leaking users to unprotected default mount | Spoofing / Elevation of privilege | Derive base path from current URI and assert nested route renders do not emit unscoped `/parapet` local links. [VERIFIED: 38-CONTEXT.md; VERIFIED: codebase grep] |
| Query parameter corruption in queue pagination | Tampering | Continue using `URI.encode_query/1` for queue params. [VERIFIED: priv/templates/parapet.gen.ui/operator_live.ex.eex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/38-scoped-ui-routes/38-CONTEXT.md` - locked implementation decisions, scope, and canonical refs. [VERIFIED: file read]
- `.planning/REQUIREMENTS.md` - UIROUTE-01 through UIROUTE-03. [VERIFIED: file read]
- `AGENTS.md` - project planning posture and escalation boundaries. [VERIFIED: file read]
- `priv/templates/parapet.gen.ui/*.eex` - current generated route-producing surfaces. [VERIFIED: codebase grep]
- `examples/demo_app/lib/demo_app_web/live/parapet/*.ex` and `examples/demo_app/lib/demo_app_web/router.ex` - checked-in demo copies and route map. [VERIFIED: codebase grep]
- `test/mix/tasks/parapet.gen.ui_test.exs`, `test/parapet/generated_operator_live_paging_test.exs`, `test/parapet/operator_ui_demo_contract_test.exs`, `test/parapet/operator_ui_integration_test.exs`, `test/parapet/operator_ui_compile_out_test.exs` - existing proof surfaces. [VERIFIED: file read]
- Phoenix LiveView live navigation docs - `patch`, `navigate`, `push_patch`, `push_navigate`, and `handle_params/3` semantics. [CITED: https://phoenix-live-view.hexdocs.pm/live-navigation.html]
- Phoenix LiveView `Phoenix.LiveView` docs - local path requirements for `push_patch`, `push_navigate`, and `redirect`. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html]
- Phoenix Router docs - route scopes and nested path behavior. [CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html]
- Phoenix VerifiedRoutes docs - path generation, path prefixes, and router-coupled verification. [CITED: https://phoenix.hexdocs.pm/Phoenix.VerifiedRoutes.html]
- Phoenix.Component docs - component attrs and HEEx component structure. [CITED: https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html]

### Secondary (MEDIUM confidence)

- `mix deps` and `mix hex.info` output - locally installed and recent Hex package versions. [VERIFIED: mix deps + mix hex.info]

### Tertiary (LOW confidence)

- Historical version timing for Phoenix VerifiedRoutes and LiveView `<.link>` adoption. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and dependency posture were verified with `mix deps`, `mix.exs`, and tests. [VERIFIED: mix deps + mix.exs]
- Architecture: HIGH - locked phase decisions and official Phoenix/LiveView docs agree that route scope belongs in host router/generated code, not Parapet core. [VERIFIED: 38-CONTEXT.md; CITED: https://phoenix.hexdocs.pm/Phoenix.Router.html]
- Pitfalls: HIGH - current literal route surfaces were found by grep and map directly to UIROUTE requirements. [VERIFIED: codebase grep]

**Research date:** 2026-06-04 [VERIFIED: current_date]
**Valid until:** 2026-07-04 for project-specific route plan; re-check Phoenix/LiveView docs if upgrading dependencies. [ASSUMED]
