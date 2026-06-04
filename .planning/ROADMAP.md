# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)

## Current Work

**v1.4 Trust Hardening & Host-App Compatibility** — close the repo-evidenced quality gaps most likely to damage adoption trust.

| Phase | Name | Goal | Requirements |
|---:|---|---|---|
| 37 | 3/3 | Complete    | 2026-06-04 |
| 38 | 3/3 | Complete    | 2026-06-04 |
| 39 | 2/2 | Complete   | 2026-06-04 |

## Phase Details

### Phase 37: Archive Durability

**Goal:** Make archive/export/prune behavior preserve complete durable evidence or fail loudly with actionable results.

**Success criteria:**

1. Archive maintenance treats incident evidence as a complete bundle for Parapet-owned records.
2. Partial failures return or surface actionable failure information.
3. Resolved-only retention remains test-pinned, including boundary dates and active/investigating exclusions.
4. Run summaries include counts and failure context useful to a host app or maintainer.

### Phase 38: Scoped UI Routes

**Goal:** Make generated Operator UI links, forms, redirects, and patches respect host-owned route scopes.

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 38-01-PLAN.md — Generated route base path and scoped template tests

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 38-02-PLAN.md — Demo scoped-route synchronization and runnable proof

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 38-03-PLAN.md — Router guidance, focused docs, and stability/security guards

**Success criteria:**

1. Generated templates support default `/parapet` mounting and at least one nested host scope such as `/ops/parapet`.
2. Demo app generated-copy tests prove template/demo synchronization.
3. Route changes do not alter auth ownership, router ownership, public API tier, or dependency surface.

### Phase 39: Adoption Proof

**Goal:** Update docs and proof surfaces so archive maintenance and scoped UI mounting are understandable and supportable by strangers.

**Plans:** 2/2 plans complete

Plans:
**Wave 1**

- [x] 39-01-PLAN.md — Archive and scoped UI adoption docs with focused guard tests

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 39-02-PLAN.md — Quality-evaluation closeout and final Phase 39 verification (completed 2026-06-04)

**Success criteria:**

1. README and docs include copy-pasteable archive maintenance guidance.
2. README and generated UI docs include default and scoped Phoenix router examples.
3. Troubleshooting notes cover the likely first errors for archive runs and scoped UI mounting.
4. `.planning/QUALITY-EVALUATION.md` or milestone close artifacts record which top risks were closed.
