# Phase 1: Scoria AI Integration Architectural Decisions

This document synthesizes deep research into Parapet's sibling-library DNA, Elixir observability idioms (PromEx, Telemetry), and SRE best practices to resolve the 3 core architectural decisions for Phase 1 of the v0.4 Scoria integration.

## 1. Dashboard Strategy

**Decision:** Should we create a standalone `scoria_dashboard.json` or dynamically append panels to the existing Parapet `main_dashboard.json`?

**Recommendation:** Create a standalone **`scoria_dashboard.json`**.

### Tradeoffs
*   **Standalone (`scoria_dashboard.json`)**
    *   *Pros:* Idiomatic to the Elixir/PromEx ecosystem (which provisions separate `phoenix.json`, `ecto.json`, etc.). Safely adheres to the "host-owned generated code" principle—users can freely modify their `main_dashboard.json` without fear that a subsequent generator will corrupt their customizations.
    *   *Cons:* Slightly increases dashboard sprawl (violates the pure "build 6 dashboards" SRE ideal by adding a 7th).
*   **Appended (`main_dashboard.json`)**
    *   *Pros:* Centralizes visibility into a single "executive health" pane, which is an SRE best practice for solo founders.
    *   *Cons:* Extremely brittle to implement via code generators. Dynamically injecting JSON into a user-modified Grafana dashboard is error-prone and violates the principle of least surprise.

### Rationale
Parapet's engineering DNA strictly dictates that "Embedded and host-owned beats remote magic." If we generate a `main_dashboard.json`, the user owns it. Dynamically injecting Scoria panels later risks overwriting their layout. By following the PromEx pattern of discrete, domain-specific dashboards, we maintain generator safety. Users can easily pin their favorite Scoria RED metrics to their main dashboard manually if they desire a unified view.

---

## 2. Module Namespace

**Decision:** Where should the Scoria telemetry handler live? (`Parapet.Scoria.SRETelemetryHandler`, `Parapet.Metrics.Scoria`, or `Parapet.Integrations.Scoria`)

**Recommendation:** Use **`Parapet.Integrations.Scoria`**.

### Tradeoffs
*   **`Parapet.Metrics.Scoria`**
    *   *Pros:* Groups by function. Matches `Parapet.Metrics.Http` and `Parapet.Metrics.Oban`.
    *   *Cons:* Inaccurate scope. The Scoria integration translates telemetry into *both* Prometheus metrics and Ecto Incidents. It is not strictly a metric exporter.
*   **`Parapet.Scoria.SRETelemetryHandler`**
    *   *Pros:* Highly specific.
    *   *Cons:* Pollutes the root `Parapet` namespace with external library names, breaking the "narrow public surface" DNA.
*   **`Parapet.Integrations.Scoria`**
    *   *Pros:* Perfectly aligns with Parapet's sibling-lib DNA (alongside `Accrue`, `Chimeway`, `Mailglass`). Centralizes all external-library coupling in one bounded context.

### Rationale
The integration is responsible for an end-to-end reliability loop (metrics generation and incident translation). Placing it in `Parapet.Integrations.Scoria` establishes a clear seam. As Parapet's DNA states: "Prefer runtime options and explicit adapter seams over hidden global config." Keeping external integrations isolated in `Parapet.Integrations.*` ensures that core modules remain decoupled from optional sibling libraries.

---

## 3. Generator Architecture

**Decision:** Should Scoria observability be a dedicated `mix parapet.gen.scoria` task, or conditionally included via a `--with-scoria` flag on existing generators?

**Recommendation:** Build a dedicated **`mix parapet.gen.scoria`** Igniter task.

### Tradeoffs
*   **Flag (`mix parapet.gen.grafana --with-scoria`)**
    *   *Pros:* Fewer commands for the user to discover.
    *   *Cons:* Couples the core telemetry generators to every possible external integration. As Parapet integrates with more tools, the flag list will grow exponentially, muddying the core CLI surface.
*   **Dedicated Task (`mix parapet.gen.scoria`)**
    *   *Pros:* Composable, modular, and adheres to "small sharp packages." Igniter tasks are designed to be composable. If a user adopts Scoria six months after installing Parapet, they can just run the Scoria generator to wire up the new telemetry handlers and dashboards.
    *   *Cons:* Requires the user to run an additional command when initially setting up the project if they want Scoria from day one.

### Rationale
Parapet's DNA mandates: "Keep optional dependencies truly optional; they must compile out cleanly." A dedicated generator is the ultimate manifestation of this rule. It ensures the base `parapet.gen.grafana` and `parapet.gen.prometheus` remain completely ignorant of Scoria. The `mix parapet.gen.scoria` task can use Igniter to elegantly inject the `Parapet.Integrations.Scoria` supervisor into the application tree, drop the `scoria_dashboard.json` into `priv/`, and append PromQL rules to the Prometheus config. This maximizes developer ergonomics by keeping the installation surfaces focused and composable.
