# Requirements — v1.3 Operator UI Polish & Design System

## Operator IA

- [x] **UI-IA-01**: Operator can land on `/parapet` and immediately understand what needs attention, why it matters, and where to go next.
- [x] **UI-IA-02**: Operator can navigate between active response, action items, and resolved history through explicit generated navigation.
- [x] **UI-IA-03**: Operator can open incident detail from both the active workbench and a detail URL without losing the evidence/action hierarchy.
- [x] **UI-IA-04**: Existing `/parapet/:id` deep links remain compatible while generated guidance introduces the preferred detail route.

## Design System

- [x] **UI-DS-01**: Generated UI components share consistent Tailwind surface, spacing, typography, radius, shadow, and status treatments.
- [x] **UI-DS-02**: Queue rows, overview cards, action cards, timeline rows, and navigation controls use clear affordances and selected/focus states.
- [x] **UI-DS-03**: Mutating action controls communicate audit outcome and risk before the operator clicks.
- [x] **UI-DS-04**: Micro-interactions are restrained, targeted to feedback/orientation, and avoid `transition-all`.
- [x] **UI-DS-05**: UI copy follows active-response language: impact, evidence, next safe action, audit, and recovery.

## Demo & Verification

- [ ] **UI-DEMO-01**: Demo seed data expresses active, investigating, resolved, recovery-previewable, guidance-only, warning, action-item, escalation, audit, external-link, and retrospective states.
- [ ] **UI-DEMO-02**: Demo routes expose the same generated Operator UI shape that adopters receive from `mix parapet.gen.ui`.
- [ ] **UI-VERIFY-01**: Tests cover generated route guidance, generated component contracts, and demo route smoke behavior.
- [ ] **UI-VERIFY-02**: Browser automation captures desktop and mobile screenshots for the response, actions, history, and detail paths.

## Future Requirements

- Team responder ownership, handoff, and shift-aware coordination remain deferred from this UI polish milestone.
- Cross-boundary journey correlation remains deferred to v1.4+.

## Out of Scope

- Changing the stable `Parapet.Operator` public API.
- Changing auth ownership; generated routes still require host app authentication.
- Adding a third-party UI component library or switching away from Tailwind.
- Building a hosted observability control plane.

## Traceability

| Requirement | Phase |
|-------------|-------|
| UI-IA-01 | 34 |
| UI-IA-02 | 34 |
| UI-IA-03 | 34 |
| UI-IA-04 | 34 |
| UI-DS-01 | 35 |
| UI-DS-02 | 35 |
| UI-DS-03 | 35 |
| UI-DS-04 | 35 |
| UI-DS-05 | 35 |
| UI-DEMO-01 | 36 |
| UI-DEMO-02 | 36 |
| UI-VERIFY-01 | 36 |
| UI-VERIFY-02 | 36 |
