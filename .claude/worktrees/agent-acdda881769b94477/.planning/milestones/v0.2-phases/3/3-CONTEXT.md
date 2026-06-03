# Phase 3 Context: Sibling Ecosystem Integrations

## Architectural Alignment
- **Dependency & Packaging Strategy:** Single Monorepo with `Code.ensure_loaded?/1` guards. No separate Hex packages.
- **Adapter Activation Strategy:** Explicit Host Config. The host explicitly opts-in via their application tree or config (`Parapet.attach(adapters: [...])`).
- **UI Extensibility Seam:** Capability-Based UI Registration. Adapters register mitigation capabilities into Parapet's spine, and the host-generated Operator UI dynamically renders `Parapet.capabilities(:mitigation)`.

This aligns with ECO-01 through ECO-05 requirements and Parapet's "compile out cleanly" constraint.