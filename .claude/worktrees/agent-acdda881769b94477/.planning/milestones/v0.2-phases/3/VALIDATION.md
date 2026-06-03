# Phase 3: Nyquist Compliance E2E Verification Plan

This document outlines the end-to-end verification plan for Phase 3 to ensure Nyquist compliance.

## Verification Scenarios

### 1. Parapet Adapter Initialization
**Requirement:** System correctly initializes provided integration adapters.
**Verification Steps:**
- Create a test setup invoking `Parapet.attach(adapters: [:rulestead, :mailglass, :chimeway, :accrue, :rindle, :threadline])` with the sibling libraries mocked or present in the test environment.
- Verify that the `setup/0` function of each enabled adapter is called successfully.
- Verify that telemetry event handlers are registered to the correct events for each adapter.

### 2. Capability Registration
**Requirement:** Mitigations are stored and available in the capability registry.
**Verification Steps:**
- Start the application with an adapter that registers capabilities (e.g., `Rulestead`).
- Call `Parapet.capabilities(:mitigation)`.
- Assert that the returned list contains the registered capabilities (e.g., `toggle_flag`) with the correct MFA tuple structure and schema definitions.
- Assert that the LiveView Operator UI can safely fetch and `apply/3` these mitigation functions dynamically.

### 3. Clean Compilation Without Sibling Libraries
**Requirement:** The core functionality must compile out cleanly when sibling dependencies are missing.
**Verification Steps:**
- Ensure none of the sibling libraries (`Rulestead`, `Mailglass`, `Chimeway`, `Accrue`, `Rindle`, `Threadline`) are included in the standard `mix.exs` dependencies for the core project.
- Run a clean `mix compile --force`.
- Assert the compilation finishes without warnings about missing dependencies or undefined functions.
- Run `mix test` to confirm tests pass, proving that the `Code.ensure_loaded?/1` guards successfully isolated the modules and `rescue` blocks prevent runtime crashes when telemetry events are mishandled.
