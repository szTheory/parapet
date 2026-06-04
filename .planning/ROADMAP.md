# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)

## Current Work

**v1.4 Trust Hardening & Host-App Compatibility** — close the repo-evidenced quality gaps most likely to damage adoption trust.

| Phase | Name | Goal | Requirements |
|---:|---|---|---|
| 37 | 2/3 | In Progress|  |
| 38 | Scoped UI Routes | Make generated Operator UI links, forms, redirects, and patches respect host-owned route scopes. | UIROUTE-01, UIROUTE-02, UIROUTE-03 |
| 39 | Adoption Proof | Update docs and proof surfaces so archive maintenance and scoped UI mounting are understandable and supportable by strangers. | ADOPT-01, ADOPT-02, ADOPT-03 |

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

**Success criteria:**
1. Generated templates support default `/parapet` mounting and at least one nested host scope such as `/ops/parapet`.
2. Demo app generated-copy tests prove template/demo synchronization.
3. Route changes do not alter auth ownership, router ownership, public API tier, or dependency surface.

### Phase 39: Adoption Proof

**Goal:** Update docs and proof surfaces so archive maintenance and scoped UI mounting are understandable and supportable by strangers.

**Success criteria:**
1. README and docs include copy-pasteable archive maintenance guidance.
2. README and generated UI docs include default and scoped Phoenix router examples.
3. Troubleshooting notes cover the likely first errors for archive runs and scoped UI mounting.
4. `.planning/QUALITY-EVALUATION.md` or milestone close artifacts record which top risks were closed.
