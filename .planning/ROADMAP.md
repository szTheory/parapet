# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, shipped 2026-06-03. Active-response IA, generated design-system consolidation, rich demo seeds, and browser-backed polish verification.

## Current Work

### Phase 34 — Operator IA & Navigation Foundation — Complete 2026-06-03

**Goal:** Reframe the generated Operator UI around active response, actions, and history without changing stable Operator API semantics.

**Requirements:** UI-IA-01, UI-IA-02, UI-IA-03, UI-IA-04

**Success criteria:**
- `/parapet` presents active response as the primary landing experience.
- Generated route guidance and demo routes expose response, actions, history, and incident detail lanes.
- Existing `/parapet/:id` detail route remains available for compatibility.

### Phase 35 — Design-System Consolidation — Complete 2026-06-03

**Goal:** Tighten the generated Tailwind component system so repeated UI elements share clear visual rules and interaction affordances.

**Requirements:** UI-DS-01, UI-DS-02, UI-DS-03, UI-DS-04, UI-DS-05

**Success criteria:**
- Shared component helpers define navigation, overview, cards, status, actions, and touch targets.
- Mutating action cards communicate audit outcome and risk clearly.
- Motion stays restrained, targeted, and reduced-motion-safe.

### Phase 36 — Demo State Coverage & Browser Verification — Complete 2026-06-03

**Goal:** Make the demo app express every important Operator UI state and verify the generated experience in-browser.

**Requirements:** UI-DEMO-01, UI-DEMO-02, UI-VERIFY-01, UI-VERIFY-02

**Success criteria:**
- Seeds cover active, investigating, resolved, recovery, escalation, external evidence, action items, and retrospective states.
- Smoke tests cover new routes.
- Browser screenshots verify desktop and mobile render paths.
