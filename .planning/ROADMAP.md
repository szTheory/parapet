# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- [x] **v1.4 Trust Hardening & Host-App Compatibility** — Phases 37-39, 8 plans, shipped 2026-06-04. Archive: [v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- [x] **v1.5 Brand Book & Logo System** — Phases 40-43, 11 plans, shipped 2026-06-24. Archive: [v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- [x] **v1.6 Operator UI Brand & Design-System Audit** — Phases 44-50, 25 plans, shipped 2026-06-29. Archive: [v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)

## Phases

<details>
<summary>✅ v1.5 Brand Book & Logo System (Phases 40-43) — SHIPPED 2026-06-24</summary>

- [x] Phase 40: Brand Pressure-Test & Critique Gate (1/1 plans) — completed 2026-06-23
- [x] Phase 41: Logo Exploration & User Selection Gate (6/6 rounds) — completed 2026-06-24
- [x] Phase 42: Token System & HTML Brand Book (3/3 plans) — completed 2026-06-24
- [x] Phase 43: Collateral, Wiring & QA/Audit Gate (3/3 plans) — completed 2026-06-24

Full detail: [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)

</details>

<details>
<summary>✅ v1.6 Operator UI Brand & Design-System Audit (Phases 44-50) — SHIPPED 2026-06-29</summary>

- [x] Phase 44: Foundations — token re-skin, fonts & audit apparatus (4/4 plans) — completed 2026-06-25
- [x] Phase 45: Primitive components (4/4 plans) — completed 2026-06-25
- [x] Phase 46: Navigation, shell & data-display (4/4 plans) — completed 2026-06-26
- [x] Phase 47: Component groups / meta-components (3/3 plans) — completed 2026-06-26
- [x] Phase 48: Pages, flows & microcopy (4/4 plans) — completed 2026-06-28
- [x] Phase 49: Stress fixtures & seed coverage (3/3 plans) — completed 2026-06-28
- [x] Phase 50: Guardrails, parity & idempotence gate (3/3 plans) — completed 2026-06-28

Full detail: [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)

</details>

## Next Milestone

Not yet defined — start with `/gsd-new-milestone`. Candidate follow-up work (deferred from v1.5/v1.6):

- Token → Tailwind/daisyUI theme generator + HEEx component snippets for the generated Operator UI (v1.6 adopts token *values* in-place; the generator is separate-concern scope).
- ExUnit-pin the v1.6 known gaps (TOKEN-04 explicit `--radius-*` custom properties; Phase-48 FLOW/COPY/A11Y-06 rendered-state assertions) to convert the human-verified facts into automated coverage.
- Automated browser a11y/interaction testing (Playwright + axe-core) as demo dev-dependencies.
- Raster exports: PNG/ICO favicons and OpenGraph social-card images.
- Animated/motion logo, Figma source-of-truth, multi-page PDF brand book.
- Stable telemetry manifest (`telemetry_stable.json` + drift gate) — the durable WR-01 fix (D-21).

## Progress Table

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 40. Brand Pressure-Test & Critique Gate | v1.5 | 1/1 | Complete | 2026-06-23 |
| 41. Logo Exploration & User Selection Gate | v1.5 | 6/6 | Complete | 2026-06-24 |
| 42. Token System & HTML Brand Book | v1.5 | 3/3 | Complete | 2026-06-24 |
| 43. Collateral, Wiring & QA/Audit Gate | v1.5 | 3/3 | Complete | 2026-06-24 |
| 44. Foundations — token re-skin, fonts & audit apparatus | v1.6 | 4/4 | Complete | 2026-06-25 |
| 45. Primitive components | v1.6 | 4/4 | Complete | 2026-06-25 |
| 46. Navigation, shell & data-display | v1.6 | 4/4 | Complete | 2026-06-26 |
| 47. Component groups / meta-components | v1.6 | 3/3 | Complete | 2026-06-26 |
| 48. Pages, flows & microcopy | v1.6 | 4/4 | Complete | 2026-06-28 |
| 49. Stress fixtures & seed coverage | v1.6 | 3/3 | Complete | 2026-06-28 |
| 50. Guardrails, parity & idempotence gate | v1.6 | 3/3 | Complete | 2026-06-28 |
