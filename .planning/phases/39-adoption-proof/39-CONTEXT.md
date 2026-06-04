# Phase 39: Adoption Proof - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Update adoption-facing docs and proof surfaces so archive maintenance and scoped Operator UI mounting are understandable and supportable by strangers. This phase documents and cross-references the already-hardened Phase 37 archive behavior and Phase 38 scoped route behavior; it does not change archive runtime semantics, add backup/restore ownership, add generator route flags, change auth/router ownership, add dependencies, or widen Parapet's public API.
</domain>

<decisions>
## Implementation Decisions

### Archive Maintenance Guidance
- **D-01:** Document the existing archive/export/prune behavior, not new archive runtime semantics.
- **D-02:** README and docs should cover `mix parapet.archive`, the default `priv/parapet/archive.jsonl` path, `--days`, `--path`, JSONL artifact plus manifest, structured success JSON, and failure messages with `stage`, `run_id`, counts, and paths.
- **D-03:** Keep the archive boundary explicit: Parapet archive maintenance is operational evidence export/prune for Parapet-owned records, not host backup/restore, object-store retention, or external provider data preservation.
- **D-04:** Document the resolved-retention limitation inherited from Phase 37: current retention means resolved incidents created before cutoff via `inserted_at < cutoff`, not incidents resolved before cutoff via a `resolved_at` field.

### Scoped Operator UI Mounting Guidance
- **D-05:** Deepen README and adoption-facing docs around default `/parapet` and scoped `/ops/parapet` Phoenix router examples.
- **D-06:** Preserve the Phase 38 model in all copy: generated Operator UI routes are host-owned, host apps own authentication and authorization, and scoped support does not require a generator flag, Parapet router abstraction, stable public API change, or dependency change.
- **D-07:** Explain that generated local links derive from the generated `operator_base_path` helper, so the same generated host-owned files can work at `/parapet` or nested mounts such as `/ops/parapet`.

### Troubleshooting Coverage
- **D-08:** Expand `docs/troubleshooting.md` and cross-link from README/operator UI docs for likely first archive failures: write, manifest, publish, delete-stage failures, missing `:parapet, :repo`, invalid retention/path usage, and safe rerun expectations after a failed archive.
- **D-09:** Add scoped UI mounting troubleshooting for stale generated UI files after route-scope support, scoped mounts that omit authenticated pipeline/live session protection, and broken local links caused by mounting only some Operator UI routes under a nested scope.
- **D-10:** Prefer a short gotchas block in `docs/operator-ui.md` plus fuller recovery steps in `docs/troubleshooting.md`, unless planning finds a cleaner existing docs location.

### Quality Risk Closeout
- **D-11:** Add a dated closeout addendum or explicit cross-reference to `.planning/QUALITY-EVALUATION.md` rather than rewriting the original audit narrative.
- **D-12:** The closeout should connect the original top risks to completed evidence: archive durability closed by Phase 37, scoped route compatibility closed by Phase 38, and adoption/supportability docs closed by Phase 39.
- **D-13:** If planning prefers a milestone close artifact instead of editing `.planning/QUALITY-EVALUATION.md`, it must link back to the quality evaluation and make future milestone planning able to distinguish closed risks from still-open risks.

### the agent's Discretion
- Exact README section placement, provided the first-contact path remains concise and points to fuller docs.
- Exact troubleshooting headings and example output snippets, provided they name real archive failure fields and real scoped UI mount paths.
- Whether quality closeout is a new section in `.planning/QUALITY-EVALUATION.md` or a milestone close artifact cross-linked from it.

### Folded Todos

None.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and adoption requirements
- `.planning/ROADMAP.md` - Phase 39 goal and success criteria.
- `.planning/REQUIREMENTS.md` - `ADOPT-01` through `ADOPT-03`.
- `.planning/PROJECT.md` - v1.4 trust-hardening posture, host-owned install model, and stable-main constraints.
- `.planning/STATE.md` - current milestone and phase position.
- `.planning/QUALITY-EVALUATION.md` - original quality risks and required closeout trail.

### Prior phase decisions and completion evidence
- `.planning/phases/37-archive-durability/37-CONTEXT.md` - locked archive boundary, evidence bundle, summary/failure shape, and retention semantics.
- `.planning/phases/37-archive-durability/37-03-SUMMARY.md` - ARCH-01 through ARCH-04 completion and verification evidence.
- `.planning/phases/38-scoped-ui-routes/38-CONTEXT.md` - locked scoped UI route ownership, route surface coverage, and stability boundaries.
- `.planning/phases/38-scoped-ui-routes/38-03-SUMMARY.md` - UIROUTE-01 through UIROUTE-03 completion and verification evidence.

### Archive runtime and tests to document accurately
- `lib/parapet/evidence/archiver.ex` - archive summary/failure structs, manifest/staging behavior, retention language.
- `lib/mix/tasks/parapet.archive.ex` - CLI flags, output shape, and failure behavior.
- `lib/parapet/evidence/archive_worker.ex` - optional Oban worker result propagation.
- `test/parapet/evidence/archiver_test.exs` - archive bundle, manifest, failure, and rerun/idempotency proof.
- `test/mix/tasks/parapet.archive_test.exs` - CLI output and failure proof.
- `test/parapet/evidence/archive_worker_test.exs` - worker behavior proof.

### Scoped UI docs, templates, and proof surfaces
- `README.md` - first-contact install/operator guidance that needs adoption proof coverage.
- `docs/operator-ui.md` - generated UI mounting guide and scoped route explanation.
- `docs/troubleshooting.md` - existing common-obstacle guide to expand.
- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` - generated default and scoped router examples.
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` - generated route-producing workbench LiveView.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` - generated route-producing detail LiveView.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` - generated route-producing components.
- `test/mix/tasks/parapet.gen.ui_test.exs` - generator guidance and scoped helper assertions.
- `test/parapet/operator_ui_demo_contract_test.exs` - default and scoped demo route contract.
- `test/parapet/operator_ui_integration_test.exs` - route emitter and docs guidance guards.
- `test/parapet/operator_ui_compile_out_test.exs` - no-scope-expansion guards.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix parapet.archive` already provides the copy-pasteable operational entry point for archive maintenance.
- The Phase 37 archive implementation already exposes structured summary/failure information and manifest paths that docs can quote instead of inventing new support language.
- `docs/operator-ui.md` already includes default `/parapet` and scoped `/ops/parapet` Phoenix router examples; Phase 39 can reuse and cross-link rather than design new routing behavior.
- The generated router snippet already carries default and scoped route maps, making README docs and generator output alignable.
- `docs/troubleshooting.md` already has the right Q&A style for first-obstacle support notes.

### Established Patterns
- Parapet docs should lead with the paved road, then send advanced/manual details to focused guides.
- Generated UI remains host-owned and inspectable; docs should reinforce this instead of implying Parapet owns production auth or router policy.
- Archive maintenance is a trust-boundary support surface. Logs can help, but returned summaries, CLI output, manifest files, and explicit paths are the durable evidence operators can act on.
- Quality evaluation should remain an audit snapshot. Closeout should preserve the diagnosis while adding dated evidence that the top risks were addressed.

### Integration Points
- Update `README.md` with concise archive maintenance and scoped Operator UI mounting guidance, linking to deeper docs.
- Update `docs/operator-ui.md` with any missing gotchas or cross-links for scoped mounting.
- Update `docs/troubleshooting.md` with archive maintenance and scoped UI first-error recovery paths.
- Update `.planning/QUALITY-EVALUATION.md` or a milestone close artifact with a dated Phase 37-39 risk-closeout trail.
- Add or update focused docs tests only if existing tests already pin docs text or planner chooses a lightweight guard; this phase should not require runtime code changes.
</code_context>

<specifics>
## Specific Ideas

- Archive guidance should include commands like `mix parapet.archive`, `mix parapet.archive --days 30`, and `mix parapet.archive --path priv/parapet/archive.jsonl`.
- Archive troubleshooting should explain that a delete-stage failure after export/publish is different from a write/manifest failure before prune.
- Scoped UI docs should keep `/ops/parapet` as the canonical nested example because Phase 38 test-pinned that path.
- The README should not become a long operations manual; use short copy and link to `docs/operator-ui.md` and `docs/troubleshooting.md`.
- Quality closeout language should say the top archive and scoped-route risks are closed by named phases and verification artifacts, not that every quality-evaluation item is closed.
</specifics>

<deferred>
## Deferred Ideas

- Rich archive export formats beyond the current Parapet-owned evidence model remain future work.
- `resolved_at` retention semantics remain deferred to a later schema/migration phase if the product wants them.
- DB-backed archive run tables, object-store archive sinks, and archive status UI remain future explicit phases.
- Multi-tenant/operator-per-org UI semantics remain out of scope.
- Parapet-owned router modules, global route-helper replacement, auth policy changes, and generator route flags remain out of scope.

### Reviewed Todos (not folded)

None.
</deferred>
