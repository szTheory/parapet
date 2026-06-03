# V1.0 Stability Freeze — API Tiers + Deprecation Policy Design

**Topic:** How to freeze Parapet's public API and telemetry contract for 1.0 — stability tiers, deprecation-policy mechanics, and enforcement gate design.
**Researched:** 2026-05-25
**Confidence:** HIGH (Elixir idioms verified via official docs + Context7; library lessons from source inspection; telemetry contract conventions from keathley.io, rulestead DNA, official telemetry docs)

---

## 1. Decision Question

Parapet is preparing for v1.0. The maintainer has committed to **stability tiers + a deprecation policy** (not just a lighter "snapshot + document"). The decision question is:

> What exact tiering scheme should Parapet use? What does the deprecation-policy document say? How does the enforcement gate work? How are telemetry events frozen and versioned? And how does all of this build on the existing `verify.public_api` gate and `Parapet.Internal.*` namespace without reinventing what already exists?

---

## 2. Options Considered

### Option A: Two-tier (Stable / Internal) — "binary public vs internal"

**Description:** Only two labels. If a module is in `Parapet.Internal.*` or has `@moduledoc false`, it is internal and unsupported. Everything else is stable. No explicit experimental tier.

```elixir
# Stable — explicitly documented, semver-protected
defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for defining SLO providers.
  """
  @callback slos() :: [struct()]
end

# Internal — @moduledoc false, namespace signals non-public
defmodule Parapet.Internal.SafeHandler do
  @moduledoc false
  # ...
end
```

**Pros:**
- Simplest cognitive model for adopters: if it's in the docs, it's stable.
- No ambiguity about what "experimental" means in practice.
- Matches the existing Parapet pattern: `Parapet.Internal.*` is already the internal namespace.

**Cons:**
- New surfaces added in v1.x have no runway to mature before being promoted to stable — forces premature stability guarantees.
- Doesn't match Parapet's reality: several modules (e.g., `Parapet.MCP.*`, `Parapet.Automation.*`) are real but not fully crystallized.
- No mechanism to ship new integration slices without immediately freezing them.

**Tradeoff:** Good for a minimal, already-mature surface. Limiting when the library is still adding integration slices.

---

### Option B: Three-tier (Stable / Experimental / Internal) — "the Node.js/OpenTelemetry model"

**Description:** Three explicit tiers. Stable is semver-protected. Experimental gets one-minor-version deprecation before breaking. Internal gets no guarantee. Tiers are communicated via doc metadata (`@doc stability: :experimental`) and a dedicated stability-policy doc.

```elixir
defmodule Parapet.MCP.Server do
  @moduledoc """
  Read-only MCP server surface for Prometheus query integration.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in minor releases
  > with a single-version notice in CHANGELOG.md. It will be promoted to stable
  > when integration patterns solidify.
  """
end

defmodule Parapet.SLO.Provider do
  @moduledoc """
  Stable behaviour for defining SLO providers.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0. Its `@callback` contracts will not change
  > without a major-version bump and full deprecation cycle.
  """
  @doc since: "1.0.0"
  @callback slos() :: [struct()]
end
```

**Pros:**
- Matches reality: some Parapet surfaces are ready to freeze; others (MCP, Automation internals) are not.
- Gives adopters clear expectations without blocking library evolution.
- Aligns with what OpenTelemetry and Node.js use (Stability, Experimental, Internal).
- Lets the maintainer ship new surfaces without committing to them prematurely.

**Cons:**
- Slightly more bureaucracy for the maintainer to correctly assign tiers.
- If "experimental" is overused, it erodes trust.
- Requires a written policy document, CHANGELOG discipline, and ExDoc callout boxes.

**Tradeoff:** Best fit for a library at Parapet's stage — feature-complete but still evolving integrations.

---

### Option C: Four-tier with version labels (Stable / Beta / Experimental / Internal)

**Description:** Adds a "Beta" tier between Experimental and Stable, used for surfaces that have shipped and are working but whose API is not yet frozen.

**Pros:**
- Fine-grained.
- Used by large frameworks like Ash, Nx.

**Cons:**
- Four tiers is one tier too many for a focused library like Parapet.
- "Beta" vs "Experimental" is not intuitive — adopters will not understand the difference.
- Parapet is not a large multi-subsystem framework.

**Verdict:** Discard. Three tiers is the right ceiling.

---

### Option D: No formal tier system — semver + CHANGELOG discipline only

**Description:** No tier labels. Rely entirely on semantic versioning, a CHANGELOG with explicit "Breaking Changes" sections, and the existing `verify.public_api` gate to catch undocumented modules.

**Pros:**
- Zero new bureaucracy.
- Standard Elixir OSS expectation.

**Cons:**
- Doesn't tell adopters which modules are safe to depend on vs which might change.
- Forces every adopter to read every CHANGELOG entry to find breaking changes.
- The maintainer has explicitly rejected this lighter model — the decision is to do tiers + policy.

**Verdict:** Already decided against this. Not a candidate.

---

## 3. What's Idiomatic in Elixir/Phoenix/Ecto/Plug

The Elixir ecosystem converges on the following conventions. These are verified against official docs (HIGH confidence):

### Module visibility mechanics

| Mechanism | Purpose | Example |
|-----------|---------|---------|
| `Parapet.Internal.*` namespace | Hard signal: not public, no guarantees | `Parapet.Internal.SafeHandler` (already done) |
| `@moduledoc false` | Hides from ExDoc; callable but invisible | Used for generated/glue modules |
| `@doc false` | Hides a single function from docs | Individual implementation helpers |
| `@doc deprecated: "..."` | Soft deprecation — docs annotation only, no compile warning | Signals intent without noise |
| `@deprecated "..."` | Hard deprecation — compile-time warning when called | Forces adopter awareness |
| `@doc since: "1.0.0"` | Marks when an API surface was introduced | Standard Elixir idiom |
| ExDoc `> #### Note {: .warning}` callout | Doc-rendered stability tier label | Used by Ecto, Phoenix, Nx |

### Elixir's own deprecation model (official, HIGH confidence)

Elixir uses a three-stage process:
1. **Soft-deprecation**: CHANGELOG + docs mark it deprecated, no warning emitted.
2. **Hard-deprecation**: `@deprecated` attribute emits compile-time warning. The alternative MUST have existed for at least **three minor versions** before hard-deprecation.
3. **Removal**: Only at major version boundaries.

Source: https://hexdocs.pm/elixir/compatibility-and-deprecations.html

### Telemetry contract conventions (HIGH confidence)

From Chris Keathley's authoritative blog post (https://keathley.io/blog/telemetry-conventions.html) and the official `:telemetry` library docs:

- **Telemetry events are an API and breaking them is more costly than breaking functional interfaces.** Functional breaks surface at compile time. Telemetry breaks surface in production when dashboards stop working.
- **Event names must be static** — they should not vary by module, configuration, or runtime. `[:parapet, :delivery, :outbound]` is stable; `[:parapet, dynamic_name()]` is not.
- **Evolution happens through metadata**, not by versioning event names. If you need new context, add a new metadata key. Don't rename the event.
- **Every event must be documented**: measurements, metadata keys, execution context.
- **Test telemetry like a functional interface** — the `:telemetry_test` module's `attach_event_handlers/2` is the mechanism.

Rulestead's prior art (from `rulestead-telemetry-observability-and-audit.md`) codifies this as a `backwards_compatibility_contract` section in `api_stability.md`:
- Event names: stable; renaming requires ≥2 minor versions of dual-emission.
- Measurements: additions allowed; removal/rename requires deprecation.
- Metadata keys: additions allowed; removal/rename requires deprecation.

### `@doc since:` idiom (HIGH confidence)

```elixir
@doc since: "1.0.0"
def attach(opts), do: ...
```

Elixir's official writing-documentation guide recommends `@doc since: "version"` to annotate when a function was introduced. ExDoc renders this in the function signature. This is the idiomatic way to communicate API age, and it's what the Elixir standard library itself uses.

---

## 4. Lessons From Comparable Libraries

### Ecto — right, wrong, footguns

**Right:**
- Ecto draws a hard line between `Ecto` (public), `Ecto.Adapters.*` (adapter surface — stable for adapter authors), and `Ecto.Query.*` (query DSL — stable). Internal implementation modules are not documented.
- Telemetry events (`[:my_app, :repo, :query]`) use a static structure that has been stable across 3.x without a single rename.
- The `Ecto.Repo` module explicitly documents what measurements and metadata each telemetry event includes.

**Wrong:**
- Ecto's telemetry documentation omits explicit stability guarantees — there is no written policy stating "these event names will not change without a major bump." Adopters rely on inferred stability.
- The `[:ecto, :repo, :init]` event and the app-prefixed `[:my_app, :repo, :query]` event naming was debated (issue #78 in ecto_sql, 2019) — the static naming won, but the design conversation happened late, after the library was already in wide use.

**Footgun:** Ecto's repo-name-prefixed telemetry (`[:my_app, :repo, :query]`) means the event name changes when the application name changes. Library authors who hook into Ecto telemetry must configure the prefix. Parapet already avoids this with its own top-level `[:parapet, ...]` namespace.

---

### Phoenix — right, wrong, footguns

**Right:**
- Phoenix documents telemetry events exhaustively in `Phoenix.Logger`. Event names like `[:phoenix, :endpoint, :stop]` have been stable across Phoenix 1.x.
- The `[:phoenix, :router_dispatch, :stop]` event includes explicit metadata fields documented in `Phoenix.Logger`.

**Wrong:**
- Phoenix's telemetry documentation does not state a written stability or breaking-change policy. The stability is inferred from Phoenix's general semver discipline.
- Phoenix's instrumenters system (pre-telemetry) was deprecated and removed across a major version — adopters who built on it faced significant churn.

**Footgun:** The Phoenix endpoint plug ordering issue (PromEx plug must come before `Plug.Telemetry` to avoid polluting request metrics) is a footgun documented in PromEx's own README but not in Phoenix's. Parapet's `mix parapet.doctor` checks already address the analogous footguns in Parapet's setup surface.

---

### Oban — right, wrong, footguns

**Right:**
- Oban is exemplary at upgrade guidance. Every breaking change in Oban's CHANGELOG explicitly names the migration path, the before/after behavior, and any required migration steps.
- Oban uses structured error messages with actionable copy when adopters have outdated migrations.

**Wrong:**
- Oban v2.10 added configurable telemetry event prefixes, then immediately yanked the version (v2.10.1 superseded it) because the feature introduced a breaking change in telemetry contracts. This is a concrete lesson: **configurable event name prefixes break the telemetry-as-API guarantee** by making event names dynamic.

**Footgun:** Configurable telemetry event prefixes. Parapet must never ship a `:event_prefix` option — all event names must be static under `[:parapet, ...]`. Oban learned this at the cost of a yanked release.

---

### Broadway — right, wrong, footguns

**Right:**
- Broadway documents 13 telemetry events with measurements and metadata.
- The `[:broadway, :topology, :init]` event exists as a clear initialization contract.

**Wrong:**
- Like Phoenix and Ecto, Broadway does not state a written telemetry stability policy. Stability is implied by the library's semver discipline.

**Footgun:** Broadway's telemetry events are not tested in a `telemetry_contract_test.exs` — there is no enforcement gate that would catch a contributor silently renaming an event or adding a metadata key that was previously documented as the complete set.

---

### Rulestead (sibling lib) — right

Rulestead's telemetry spec (from `rulestead-telemetry-observability-and-audit.md`) is the most thorough example in the sibling ecosystem:
- Canonical event tree: `[:rulestead, ...]` — all events versioned in `api_stability.md`.
- Explicit backwards-compatibility contract as a document section, not just implied by semver.
- `test/telemetry_contract_test.exs` that asserts event names, measurement keys, and metadata keys against a fixture file — **this is the enforcement gate Parapet needs**.
- Dual-emission strategy for event renames: the old name continues emitting alongside the new one for ≥2 minor versions.

---

### Absinthe — right, footgun

**Right:**
- Absinthe uses `@moduledoc false` extensively to hide internal modules from docs, making the boundary clear.

**Footgun:** Absinthe's internal module namespace (`Absinthe.Phase.*`, `Absinthe.Blueprint.*`) is extensive and partially callable by external code. Because these modules have `@moduledoc false` but not `@doc false`, their functions are reachable but undocumented — a recipe for accidental coupling. Parapet's `Parapet.Internal.*` namespace is cleaner because the namespace itself signals the boundary.

---

### Nx — right

Nx uses ExDoc callout boxes in moduledocs to signal experimental status:

```
> #### Experimental {: .warning}
>
> The function is experimental and its behavior can change in future releases.
```

This is the pattern Parapet should adopt for its experimental tier — doc-rendered, not just code-level.

---

### Bandit — right

Bandit's `bandit.ex` is a clean example: a narrow public module with exactly two public functions, `@doc false` on internal helpers within the public module, and internal implementations delegated to separate modules. The public API surface is intentionally minimal. Parapet's `Parapet.attach/1` follows this model.

---

## 5. DX/UX Considerations

### For adopters

- **Principle of least surprise**: An adopter should be able to look at any Parapet module and immediately know: is this safe to depend on? The answer should come from the module's moduledoc, not from reverse-engineering the namespace.
- **Callout boxes are visible**: ExDoc's `> #### Stable {: .info}` / `> #### Experimental {: .warning}` renders prominently in HexDocs — better than a buried doc paragraph.
- **Compile warnings are respected**: When a function is deprecated with `@deprecated`, the compile warning catches it at the moment of use. Adopters catch it during `mix compile`, not at runtime.
- **Breaking changes in CHANGELOG are scannable**: A "Breaking Changes" H2 section in CHANGELOG entries is the standard Phoenix/Ecto/Oban pattern. Adopters can scan the changelog for `## Breaking Changes` after a `mix deps.update`.

### For the maintainer

- **Don't add bureaucracy that won't be maintained**: If the tier system requires updating a separate tier registry file on every new module, it will drift. The source of truth must be in-module (moduledoc callout boxes) and in the `verify.public_api` gate.
- **The `Parapet.TestSupport.*` exclusion is already correct**: The existing gate excludes it. Don't regress this.
- **Experimental tier is the escape valve**: New surfaces (MCP, Automation) get experimental status at launch. The maintainer commits only to a written notice in CHANGELOG before changing them, not to a full deprecation cycle. This is honest.
- **Telemetry contract tests run in CI**: The enforcement gate must be a test file that runs in CI, not a manual checklist. Rulestead's `telemetry_contract_test.exs` pattern is the template.

---

## 6. Recommendation

### The Tiering Scheme

Use **three tiers**: Stable, Experimental, Internal.

| Tier | Namespace / Signal | What it means | Semver guarantee |
|------|--------------------|---------------|-----------------|
| **Stable** | Any `Parapet.*` module with `@moduledoc` containing a `> #### Stable {: .info}` callout + `@doc since: "1.0.0"` on public functions | Behavior, function signatures, callback contracts, telemetry event names/measurements/metadata will not change without a major version bump. Deprecation cycle required before removal. | ✓ Full semver protection |
| **Experimental** | Any `Parapet.*` module with `@moduledoc` containing a `> #### Experimental {: .warning}` callout | May change in a minor version. One-release notice in CHANGELOG required before a breaking change. | ✓ One-release notice only |
| **Internal** | `Parapet.Internal.*` namespace, or `@moduledoc false` | No guarantees. May change or be removed at any time without notice. | ✗ No guarantee |

#### Concrete classification for existing Parapet modules

**Stable at v1.0:**
- `Parapet` — `attach/1` (the primary activation function)
- `Parapet.Integration` — the uniform adapter behaviour
- `Parapet.SLO.Provider` — the core SLO behaviour `@callback slos/0`
- `Parapet.SLO.SliceSpec` — the SLO data structure
- `Parapet.Runbook` — the runbook DSL
- `Parapet.Escalation.Policy` — the escalation behaviour `@callback escalate/2`
- `Parapet.Notifier` — the notifier behaviour `@callback deliver/2`
- `Parapet.Evidence` — the core evidence API (create_incident, append_timeline, log_tool_audit)
- `Parapet.Operator` — the operator API (incident lifecycle functions)
- `Parapet.Deploy` — `mark/1`
- `Parapet.SLO.StarterPack.WebSaaS`, `Parapet.SLO.StarterPack.DeliverySaaS` — the starter packs
- All documented telemetry events in `docs/telemetry.md`

**Experimental at v1.0:**
- `Parapet.MCP.*` — MCP server surface (protocol not yet stable ecosystem-wide)
- `Parapet.Automation.*` (CircuitBreaker, ClaimService, Executor) — internal automation mechanics that some advanced adopters may call directly
- `Parapet.Metrics.*` — the metric-attachment modules (adopters typically do not call these; internal use only via `Parapet.Integration` setup, but they're not namespaced Internal)
- `Parapet.Probe`, `Parapet.Probe.*` — the synthetic probe surface
- `Parapet.Evidence.Archiver`, `Parapet.Evidence.Retrospective` — useful but their API is not yet hardened from real adoption feedback
- All integration modules (`Parapet.Integrations.*`) — they implement `Parapet.Integration` behaviour which is stable, but the integration-specific details may evolve

**Internal (already correct):**
- `Parapet.Internal.*` — unchanged; already `@moduledoc false`
- `Parapet.TestSupport.*` — already excluded from `verify.public_api` gate

#### The annotation pattern

```elixir
# Stable module
defmodule Parapet.SLO.Provider do
  @moduledoc """
  Behaviour for defining SLO providers.

  > #### Stable {: .info}
  >
  > This module is **stable** as of v1.0.0. The `@callback` contract will not change
  > without a major-version bump and a full deprecation cycle. See Parapet's
  > [Stability & Deprecation Policy](stability-policy.html) for details.
  """
  @doc since: "1.0.0"
  @callback slos() :: [struct()]
end

# Experimental module
defmodule Parapet.MCP.Server do
  @moduledoc """
  Read-only MCP server exposing Prometheus query and SLO surfaces.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its public API may change in a minor
  > release with a single-version notice in CHANGELOG.md. It will be promoted to
  > stable when MCP protocol adoption patterns solidify.
  """
end
```

---

### The Deprecation Policy Document

Create `docs/stability-policy.md` (added to `mix.exs` `extras:` and `docs/` `files:` whitelist). Contents:

**Stability tiers** — the three tiers with the table above.

**What counts as a breaking change in the Stable tier:**
- Removing or renaming a public function or callback
- Adding a required argument to a public function
- Changing a return type or struct field from its documented shape
- Removing or renaming a telemetry event name
- Removing or renaming a documented measurement key in any telemetry event
- Removing or renaming a documented metadata key in any telemetry event
- Changing the documented atom vocabulary for metadata values (e.g., renaming `:provider_accepted` to `:accepted`)

**What is NOT a breaking change:**
- Adding new public functions or callbacks (additive)
- Adding new optional arguments with documented defaults
- Adding new telemetry events
- Adding new measurement keys to existing events
- Adding new metadata keys to existing events (adopters' handlers must ignore unknown keys)
- Bug fixes that correct behavior to match documentation
- Changes inside `Parapet.Internal.*`
- Changes to any module marked Experimental (with one-release CHANGELOG notice)

**Deprecation policy for the Stable tier:**
1. **Soft deprecation**: Add `@doc deprecated: "Use X instead"` to docs AND add a CHANGELOG entry under `## Deprecated`. No compile warning yet.
2. **Hard deprecation** (next minor release minimum): Add `@deprecated "Use X instead"` to emit compile-time warnings. The alternative MUST exist.
3. **Removal**: Only in the next major version after hard deprecation has been in place for at least one minor release.

For the Experimental tier: a single CHANGELOG entry is sufficient notice before a breaking change. No formal deprecation cycle required.

**Telemetry contract:**
- Event names under `[:parapet, ...]` are stable and will not be renamed or removed without the full deprecation cycle described above.
- Documented measurements and metadata keys are stable. New keys may be added in minor releases.
- Raw provider payloads, `*_id` values, and keys not listed in `docs/telemetry.md` are NOT part of the contract — adopter handlers should use `Map.get/3` with a default for any key they consume.
- Parapet will never add a configurable `:event_prefix` option. Event names are static.

---

### The Enforcement Gate Design

Build on the **existing** `mix verify.public_api` task. Do not invent a new task. Extend it in three ways:

#### Extension 1: Tier manifest

The current `verify.public_api` task generates a JSON manifest of public modules and checks they have docs. Extend it to also output the stability tier for each module, read from module doc metadata:

```elixir
# How the task detects tier:
defp detect_tier(module) do
  case Code.fetch_docs(module) do
    {:docs_v1, _, _, _, %{"en" => moduledoc_text}, _, _} ->
      cond do
        String.contains?(moduledoc_text, "{: .info}") and
          String.contains?(moduledoc_text, "stable") -> :stable
        String.contains?(moduledoc_text, "{: .warning}") and
          String.contains?(moduledoc_text, "experimental") -> :experimental
        true -> :unclassified
      end
    _ -> :unclassified
  end
end
```

The task fails (non-zero exit) if any public module is `:unclassified`. This makes the tier annotation mandatory for all documented public modules — once added at v1.0, no new public module can ship without a declared tier.

#### Extension 2: Telemetry contract test

Create `test/telemetry_contract_test.exs` (following Rulestead's pattern):

```elixir
defmodule Parapet.TelemetryContractTest do
  use ExUnit.Case, async: true

  @documented_events [
    [:parapet, :delivery, :outbound],
    [:parapet, :delivery, :provider_feedback],
    [:parapet, :delivery, :webhook_ingest],
    [:parapet, :async, :stage],
    [:parapet, :async, :backlog],
    [:parapet, :async, :callback]
  ]

  @documented_measurements %{
    [:parapet, :delivery, :outbound] => [:count, :duration_ms],
    [:parapet, :delivery, :provider_feedback] => [:count, :duration_ms],
    [:parapet, :delivery, :webhook_ingest] => [:count, :duration_ms, :delay_ms],
    [:parapet, :async, :stage] => [:count, :duration_ms],
    [:parapet, :async, :backlog] => [:count, :delay_ms],
    [:parapet, :async, :callback] => [:count, :delay_ms]
  }

  @documented_metadata_keys %{
    [:parapet, :delivery, :outbound] => [:integration, :provider, :channel, :outcome, :fault_plane],
    # ... per family
  }

  describe "event name contract" do
    test "AsyncDelivery.event_families/0 matches documented contract" do
      actual = Parapet.Telemetry.AsyncDelivery.event_families()
      assert Enum.sort(actual) == Enum.sort(@documented_events),
             "Telemetry event families have drifted from the documented contract. " <>
             "Update docs/telemetry.md and this test together."
    end
  end

  describe "metadata key contract" do
    for family <- @documented_events do
      test "allowed_public_keys for #{inspect(family)} matches contract" do
        family = unquote(family)
        actual = Parapet.Telemetry.AsyncDelivery.allowed_public_keys(family)
        expected = @documented_metadata_keys[family]
        assert Enum.sort(actual) == Enum.sort(expected),
               "Metadata key contract drifted for #{inspect(family)}"
      end
    end
  end
end
```

This test is the machine-enforced contract that prevents telemetry drift — a contributor who renames a metadata key or adds a new event family without updating the contract will get a failing test in CI, not a silent dashboard break in production.

#### Extension 3: CHANGELOG discipline

The Release-Please-owned `CHANGELOG.md` already exists. Establish a convention: breaking changes to Stable surfaces **must** include a `## Breaking Changes` subsection in the release notes. This is enforced by human review + PR template, not by CI (CI cannot parse semantic intent).

---

### How Telemetry Events Get Frozen and Versioned

**Step 1: Declare the contract in `Parapet.Telemetry.AsyncDelivery`**

The module already exists and defines `@event_families`, `@allowed_public_keys`, `@delivery_outcomes`, etc. as module attributes. This is the machine-readable contract. Add a moduledoc callout marking it Stable.

**Step 2: Freeze `docs/telemetry.md` as the normative reference**

`docs/telemetry.md` already exists and documents all event families, measurements, and metadata. At v1.0, add a frontmatter/header line:

```
> This telemetry reference is **stable** as of v1.0.0. Changes to event names,
> measurements, or documented metadata keys are semver-major changes.
```

**Step 3: Additive-only evolution rules**

These rules go in `docs/stability-policy.md` and are enforced by `TelemetryContractTest`:
- New event families: allowed in minor releases; add to `@event_families` + `docs/telemetry.md` + test fixture simultaneously.
- New measurement keys: allowed in minor releases; add to `@documented_measurements` + docs + test fixture.
- New metadata keys: allowed in minor releases; same.
- Removing or renaming any of the above: BREAKING. Requires major version. Old event/key must dual-emit alongside new one for ≥1 minor release before removal.

**Step 4: Vocabulary atoms are part of the contract**

`@delivery_outcomes`, `@async_outcomes`, `@fault_planes`, `@retry_states` in `Parapet.Telemetry.AsyncDelivery` are already module attributes. Freezing them means: existing atom keys are stable, new atoms may be added in minor releases. The TelemetryContractTest should assert the atom maps match a fixture.

---

## 7. Coherence With Parapet's Vision and Other v1.0 Decisions

This design is coherent with the existing constraints and decisions:

- **"Telemetry as API" constraint** (PROJECT.md): The explicit `TelemetryContractTest` and additive-only rules operationalize this constraint as machine-enforced policy, not just a documented intent.
- **`mix verify.public_api` gate** (already in `mix.exs` aliases): The tier-manifest extension builds directly on the existing gate. No new Mix task needed.
- **`Parapet.Internal.*` namespace** (already in use): The three-tier model preserves and formalizes what already exists. No renames needed.
- **`Parapet.TestSupport.*` exclusion** (already in `verify.public_api`): Preserved unchanged.
- **`@deprecated` on `Parapet.SLO.define/2`** (already in `lib/parapet/slo.ex`): This is already a correct usage of the pattern. At v1.0, it gets a documented deprecation window in `stability-policy.md`.
- **`files:` whitelist in `mix.exs`** (already in use): `docs/stability-policy.md` must be added to the `files:` list and `docs:` extras.
- **ExDoc `docs --warnings-as-errors`** (already in `verify.public_api` alias): Ensures all Stable modules have docs — any undocumented Stable module fails CI.
- **OSS discipline with Release Please**: The CHANGELOG convention for "Breaking Changes" subsections maps directly to Release Please's commit type detection for `BREAKING CHANGE:` footers in conventional commits.
- **`Parapet.Integrations.*` as Experimental**: The `Parapet.Integration` behaviour is Stable (uniform activation contract), but the individual integration modules are Experimental. This is honest: adopters should not call `Parapet.Integrations.Sigra.setup/0` directly — they call `Parapet.attach(adapters: [:sigra])`. The integration modules are an implementation detail that happens to be in the public namespace, and making them Experimental gives the maintainer room to refactor adapter internals without a major bump.

---

## 8. Milestone Fit + Effort + Phase Chunking

### Milestone fit

All of this belongs in **v1.0**. The stability freeze is the defining commitment of v1.0. None of it should slip to v1.1 — once v1.0 ships without a formal stability declaration, adopters are already building on undefined guarantees.

### Rough effort

| Deliverable | Effort | Notes |
|-------------|--------|-------|
| Write `docs/stability-policy.md` | ~2h | Policy doc, written once |
| Classify all existing modules into tiers | ~3h | ~70 modules; most are obvious; Automation/Metrics need judgment |
| Add callout boxes to all Stable + Experimental moduledocs | ~4h | Mechanical, one per module |
| Add `@doc since: "1.0.0"` to all Stable public functions | ~3h | Mechanical grep + edit |
| Extend `verify.public_api` to check tier classification | ~3h | Code change to existing task |
| Write `test/telemetry_contract_test.exs` | ~4h | New test file; fixture-based |
| Add `docs/stability-policy.md` to `mix.exs` extras + `files:` | ~30min | Config change |
| Update `docs/telemetry.md` with stability header | ~30min | One paragraph |
| CHANGELOG discipline: document PR template for Breaking Changes | ~1h | PR template update |

**Total: approximately 21 hours of focused work, or 3-4 engineering days.**

### Suggested GSD phase chunking

**Phase A — Policy foundation (1 day):**
- Write `docs/stability-policy.md` (tiers table, what counts as breaking, deprecation cycle, telemetry additive-only rules)
- Update `docs/telemetry.md` with stability freeze header
- Add stability-policy.md to `mix.exs` extras and `files:`

**Phase B — Module classification pass (1 day):**
- Audit every non-Internal public module; assign Stable or Experimental
- Add ExDoc callout boxes to all moduledocs
- Add `@doc since: "1.0.0"` to all functions in Stable modules

**Phase C — Enforcement gate hardening (1 day):**
- Extend `verify.public_api` task to detect tier and fail on `:unclassified`
- Write `test/telemetry_contract_test.exs` with event family + measurement + metadata fixtures
- Confirm `mix verify.public_api` passes in CI with the extended gate

**Phase D — Deprecation housekeeping (0.5 day):**
- Finalize the `Parapet.SLO.define/2` deprecation: add hard `@deprecated` (already soft-deprecated), confirm the `Parapet.SLO.Provider` alternative has been available since v0.6+
- PR template update for "Breaking Changes" subsection discipline
- Audit CHANGELOG.md for any historical breaking changes that should be retroactively labeled

---

## 9. Sources

- Official Elixir deprecation policy: https://hexdocs.pm/elixir/compatibility-and-deprecations.html (HIGH confidence — official docs)
- Elixir `@deprecated` + `@doc deprecated:` mechanics: https://hexdocs.pm/elixir/Module.html (HIGH confidence — official docs)
- Elixir writing documentation / `@doc since:`: https://hexdocs.pm/elixir/writing-documentation.html (HIGH confidence — official docs)
- Chris Keathley — Telemetry Conventions: https://keathley.io/blog/telemetry-conventions.html (HIGH confidence — authoritative community source, widely cited)
- `:telemetry_test` module: https://hexdocs.pm/telemetry/telemetry_test.html (HIGH confidence — official docs)
- Ecto telemetry: https://hexdocs.pm/ecto/Ecto.Repo.html (HIGH confidence — official docs)
- Phoenix telemetry: https://hexdocs.pm/phoenix/telemetry.html (HIGH confidence — official docs)
- Broadway telemetry: https://hexdocs.pm/broadway/Broadway.html (HIGH confidence — official docs)
- Oban CHANGELOG (v2.10 telemetry prefix yank): https://hexdocs.pm/oban/changelog.html (MEDIUM confidence — inferred from search result summary)
- Rulestead telemetry contract prior art: `prompts/prior-art/rulestead-telemetry-observability-and-audit.md` (HIGH confidence — first-party sibling lib DNA)
- Bandit module structure: https://github.com/mtrudel/bandit/blob/main/lib/bandit.ex (HIGH confidence — source inspection)
- Parapet existing gate: `lib/mix/tasks/verify.public_api.ex` (HIGH confidence — source inspection)
- Parapet existing telemetry: `lib/parapet/telemetry/async_delivery.ex`, `docs/telemetry.md` (HIGH confidence — source inspection)
- Parapet engineering DNA: `prompts/parapet-engineering-dna-from-sibling-libs.md` (HIGH confidence — first-party)
- Ecto_sql telemetry naming debate: https://github.com/elixir-ecto/ecto_sql/issues/78 (MEDIUM confidence — issue thread, outcome inferred from current Ecto docs)
