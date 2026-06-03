# Phase 3: Sibling Ecosystem Integrations

> **Purpose:** Deep architectural research and recommendations for integrating Parapet with sibling ecosystem libraries (Rulestead, Mailglass, Chimeway, Accrue, Threadline) without introducing hard dependencies.

## Executive Summary

Parapet's Phase 3 transitions the library from a generic observability tool into an opinionated, ecosystem-aware SRE platform. The goal is to provide deep integration (SLIs, incident correlation, and mutative Operator UI actions) for sibling libraries without violating the "compile out cleanly" DNA constraint.

**Core Recommendations:**
1. **Packaging:** Retain a single monorepo (`parapet`). Wrap adapter modules with `if Code.ensure_loaded?(SiblingModule)` to safely conditionally compile.
2. **Activation:** Require **explicit host config** (e.g., `Parapet.attach(adapters: [...])`). Avoid auto-discovery magic to maintain predictable developer ergonomics.
3. **UI Extensibility:** Leverage the **host-owned generated UI pattern**. The `parapet.gen.ui` task should inject capability-based rendering slots, with integration-specific LiveView components rendered conditionally based on runtime capability registration.

---

## A. Packaging/Dependency Strategy

We must support integrations without bloating the dependency tree for users who only want standard HTTP/Ecto metrics.

### Option 1: Monorepo with `Code.ensure_loaded?` (Recommended)
All integration adapters live inside the main `parapet` package (e.g., `lib/parapet/integrations/rulestead.ex`), but the entire module is wrapped in an `if Code.ensure_loaded?(Rulestead) do ... end` block.

* **Pros:**
  * **Zero Cost when Absent:** The compiler simply ignores the module if the dependency is missing.
  * **Single Release Cycle:** Maintains a single Hex package and version number, dramatically simplifying release engineering (Release Please, CI).
  * **DNA Alignment:** Already proven in Parapet v0.1 for Oban and Sigra.
* **Cons:**
  * Internal project tree gets slightly wider, though compiled bytecode remains small for the end-user.

### Option 2: Telemetry Attachments (Zero-Code Dependency)
Parapet purely listens to canonical telemetry events (e.g., `[:rulestead, :eval, :decide]`) and never references the `Rulestead` module directly.

* **Pros:**
  * Absolute decoupling. No `Code.ensure_loaded?` needed.
* **Cons:**
  * **Fatal for Phase 3:** Fails requirement #2 (Mutative actions). You cannot safely toggle a Rulestead feature flag without calling `Rulestead.set_flag/3`. Telemetry is one-way (passive).

### Option 3: Separate Hex Packages (`parapet_rulestead`, etc.)
Publishing distinct packages that depend on both `parapet` and the sibling library.

* **Pros:**
  * Cleanest theoretical dependency graph.
* **Cons:**
  * Multi-package repository release engineering is notoriously difficult. Introduces version drift risks (e.g., user upgrades `parapet` but forgets to upgrade `parapet_rulestead`).
  * Friction for adoption: "I have to install 3 packages just to get the default integrations."

**Decision:** **Monorepo with `Code.ensure_loaded?`**. It balances mutative capabilities with the "compile out cleanly" rule, fitting perfectly within the established DNA.

---

## B. Adapter Activation Strategy

Once compiled, how does Parapet know to start listening to Mailglass or offering Rulestead toggles?

### Option 1: Explicit Host Config (Recommended)
The host application explicitly registers the adapters in their supervision tree or a Parapet initialization block.
```elixir
# lib/my_app/application.ex
Parapet.attach(
  adapters: [
    Parapet.Integrations.Oban,
    Parapet.Integrations.Rulestead,
    Parapet.Integrations.Mailglass
  ]
)
```

* **Pros:**
  * **Principle of Least Surprise:** Developers know exactly what is running.
  * **Host-Owned:** The host controls the integration lifecycle, passing in required configuration (like tenant resolvers).
  * **Idiomatic:** Closely mimics `Oban.start_link(plugins: [...])` and `Telemetry.Metrics` patterns.
* **Cons:**
  * Slight increase in setup boilerplate.

### Option 2: Auto-Discovery Magic
Parapet automatically activates `Parapet.Integrations.Rulestead` if `Code.ensure_loaded?(Rulestead)` returns true.

* **Pros:**
  * "It just works" out of the box.
* **Cons:**
  * **High Risk:** The host application might have Rulestead in their mix.exs but hasn't configured its repo yet, leading to startup crashes driven by Parapet's invisible activation.
  * Violates the Elixir ethos of explicit over implicit.

**Decision:** **Explicit Host Config**. Sibling libraries prefer explicit boundaries. Activation must be an intentional act by the operator.

---

## C. The UI Extensibility Seam

The Parapet Operator UI must render mutative actions (like a Rulestead flag toggle) safely, even though the UI is host-generated code.

### The Challenge
If the `parapet.gen.ui` mix task hardcodes `Rulestead.toggle(...)` into the generated Phoenix LiveView, it will crash if the user removes Rulestead later, or if they generate the UI before adding Rulestead.

### The Solution: Capability-Based UI Registration & Protocol Seams
Instead of hardcoding sibling module calls in the UI, we invert the dependency using capabilities.

1. **The Abstract Component:** The generated Parapet Operator UI includes a generic `MitigationPanel` component.
2. **Capability Registration:** When `Parapet.Integrations.Rulestead` is explicitly attached at startup, it registers a "capability" with the Parapet spine.
   ```elixir
   Parapet.register_mitigation_action(
     id: :rulestead_toggle,
     label: "Toggle Feature Flag",
     module: Parapet.Integrations.Rulestead.UI,
     function: :render_toggle
   )
   ```
3. **Safe Rendering:** The host-generated UI queries `Parapet.capabilities(:mitigation)` and dynamically renders the registered actions. The actual rendering logic and mutation API calls are kept strictly within `lib/parapet/integrations/rulestead.ex` (which only compiled because `Code.ensure_loaded?` was true).

**Tradeoffs:**
* **Pros:** The generated UI remains static and safe. Users can add/remove Rulestead from their `mix.exs` without regenerating the Parapet UI. The integration logic is neatly encapsulated in the adapter.
* **Cons:** Requires a small capability registry in `Parapet.Operator` or `Parapet.Spine`, adding a bit of internal state management.

---

## Idiomatic Elixir & Sibling DNA Alignment

* **Oban / Telemetry.Metrics Pattern:** Explicitly passing adapters/plugins as a list to an `attach/1` or `start_link/1` function is the gold standard for Elixir library extensibility.
* **Compile-time vs Runtime:** Using `Code.ensure_loaded?` is evaluated at compile time if macro-driven, or cleanly branch-predicted at runtime. It avoids the `Application.ensure_started(:missing_app)` footgun.
* **Operator Ergonomics (DX):** By keeping the UI dynamic but the configuration explicit, the DX is seamless. If an integration breaks, the stack trace points cleanly to the explicit adapter config in `application.ex`, not a hidden auto-discovery macro.

## Final Recommendation Summary
Implement Phase 3 integrations inside the main `parapet` repository using `if Code.ensure_loaded?(Dependency)` guards. Require operators to explicitly declare active integrations via `Parapet.attach(adapters: [...])`. Build the UI extensibility seam around a capability-registration model, allowing the host-generated UI to safely render Rulestead or Mailglass mitigation panels without hardcoded module dependencies.