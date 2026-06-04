# Phase 39: Adoption Proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-04
**Phase:** 39-adoption-proof
**Mode:** assumptions
**Areas analyzed:** Archive Maintenance Guidance, Scoped Operator UI Mounting Guidance, Troubleshooting Coverage, Quality Risk Closeout

## Assumptions Presented

### Archive Maintenance Guidance

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 39 should document the existing archive/export/prune behavior, not change archive runtime semantics: `mix parapet.archive`, default `priv/parapet/archive.jsonl`, `--days`, `--path`, JSONL artifact plus manifest, structured success JSON, and failure messages with `stage`, `run_id`, counts, and paths. | Confident | `.planning/phases/37-archive-durability/37-CONTEXT.md`; `lib/parapet/evidence/archiver.ex`; `lib/mix/tasks/parapet.archive.ex`; `test/parapet/evidence/archiver_test.exs`; `test/mix/tasks/parapet.archive_test.exs`; `README.md` |

### Scoped Operator UI Mounting Guidance

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 39 should deepen README and adoption-facing docs around default `/parapet` and scoped `/ops/parapet` Phoenix router examples while preserving the Phase 38 model: generated, host-owned routes; host-owned auth; no generator flag, router abstraction, public API, or dependency change. | Confident | `.planning/phases/38-scoped-ui-routes/38-CONTEXT.md`; `docs/operator-ui.md`; `priv/templates/parapet.gen.ui/router_snippet.ex.eex`; `test/mix/tasks/parapet.gen.ui_test.exs`; `test/parapet/operator_ui_demo_contract_test.exs`; `README.md` |

### Troubleshooting Coverage

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Troubleshooting should be expanded in `docs/troubleshooting.md` and cross-linked from README/operator UI docs for the likely first failures: archive write/manifest/delete-stage failures, missing `:parapet, :repo`, invalid retention/path usage, rerunning after delete-stage failure, stale generated UI files after route-scope support, and scoped mounts that omit the authenticated pipeline/live session. Alternative placement is a short Operator UI-specific gotchas block in `docs/operator-ui.md` plus fuller recovery steps in `docs/troubleshooting.md`. | Likely | `docs/troubleshooting.md`; `lib/parapet/evidence/archiver.ex`; `lib/mix/tasks/parapet.archive.ex`; `test/parapet/evidence/archiver_test.exs`; `docs/operator-ui.md`; `test/mix/tasks/parapet.gen.ui_test.exs` |

### Quality Risk Closeout

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 39 should add a dated closeout addendum or explicit cross-reference to `.planning/QUALITY-EVALUATION.md` rather than rewriting the original audit narrative; acceptable alternatives are a "Top risks closed by Phases 37-39" section in that file or a milestone close artifact that links back to it. | Likely | `.planning/QUALITY-EVALUATION.md`; `.planning/phases/37-archive-durability/37-03-SUMMARY.md`; `.planning/phases/38-scoped-ui-routes/38-03-SUMMARY.md`; `.planning/REQUIREMENTS.md` |

## Corrections Made

No corrections - all assumptions confirmed.

## External Research

No external research was needed.
