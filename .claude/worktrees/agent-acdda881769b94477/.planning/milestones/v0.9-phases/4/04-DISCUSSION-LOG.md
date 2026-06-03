# Phase 4: Unified Install Path (DX) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 4-Unified Install Path (DX)
**Areas discussed:** Install flow coverage and order, Prompting and automation model, Optional integration handling, Multi-node doctor posture

---

## Install flow coverage and order

| Option | Description | Selected |
|--------|-------------|----------|
| Thin wrapper | Keep `mix parapet.install` narrow and require manual `gen.spine`, `gen.prometheus`, and `gen.ui` follow-up | |
| Full auto stack | Always run `spine -> install wiring -> prometheus -> ui -> integrations` with minimal prompting | |
| Opinionated staged orchestrator | Auto-run core install in the right order, then gate UI and integrations explicitly | ✓ |

**User's choice:** Delegated to agent recommendation synthesis. Selected the opinionated staged orchestrator.
**Notes:** Chosen because it best matches Parapet’s host-owned posture, least-surprise DX, and the Phase 4 goal of encoding the paved road without hiding architectural choices.

---

## Prompting and automation model

| Option | Description | Selected |
|--------|-------------|----------|
| Interactive wizard | Prompt heavily through install decisions | |
| Flag-first noninteractive | Prefer pure flags and no prompts | |
| Hybrid prompt-with-flags | Default-heavy installer with prompts only for unresolved high-impact branches and full flag parity | ✓ |
| Plan-first preview/apply | Add a more explicit preview/apply layer | |

**User's choice:** Delegated to agent recommendation synthesis. Selected the hybrid prompt-with-flags model.
**Notes:** The maintainer explicitly asked to shift routine decisions left and minimize future questioning. The selected model keeps CI/docs deterministic while preserving a calm, human-friendly first-run path.

---

## Optional integration handling

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-detect and auto-enable | Infer integration enablement from deps/config and turn it on automatically | |
| Detect, then ask; explicit opt-in | Detect present deps, but require explicit prompt or flags before wiring integrations | ✓ |
| Core install only | Leave integrations entirely to manual post-install work | |

**User's choice:** Delegated to agent recommendation synthesis. Selected detection-informed explicit opt-in.
**Notes:** Selected to preserve compile-out cleanliness, keep support surface honest, and avoid silent magic. Integration enablement should remain visible in generated host-owned code.

---

## Multi-node doctor posture

| Option | Description | Selected |
|--------|-------------|----------|
| Warn-only advisory | Doctor reports risk but never meaningfully gates | |
| Mixed severity with mode-aware threshold | Severity-based checks with different local/CI fail thresholds | ✓ |
| Strict-by-default blocking | Fail hard on cluster concerns by default | |
| Split surface with runtime verification | Separate static and runtime verification modes | ✓ |

**User's choice:** Delegated to agent recommendation synthesis. Selected a combined posture: mixed severity by default, plus explicit runtime verification mode.
**Notes:** The selected direction is strong without overclaiming. It keeps local DX calm, lets CI enforce real risk, and stays honest about what static analysis cannot prove in clustered setups.

---

## the agent's Discretion

- Exact prompt wording and flag naming
- Exact summary/report formatting
- Exact internal helper structure for installer orchestration
- Exact doctor output schema and threshold flag names

## Deferred Ideas

None.
