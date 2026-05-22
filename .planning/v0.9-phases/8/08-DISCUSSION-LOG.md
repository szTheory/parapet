# Phase 8: Close Day-1 Install and Doctor Verification - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `08-CONTEXT.md` — this log preserves the assumptions, research, and corrections that shaped them.

**Date:** 2026-05-21
**Phase:** 08-close-day-1-install-and-doctor-verification
**Mode:** assumptions + advisor research
**Areas analyzed:** verification artifact shape, proof standard, end-to-end boundary, AC-01 interpretation, reconciliation scope, maintainer left-shift policy

## Assumptions Presented

### Verification artifact shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 8 should produce one canonical verification artifact for the underlying Phase 4 work instead of folding closure into summaries or validation. | Confident | `.planning/v0.9-phases/2/VERIFICATION.md`, `.planning/v0.9-phases/5/VERIFICATION.md`, `.planning/v0.9-MILESTONE-AUDIT.md` |
| The artifact should stay thin and executable-first rather than becoming a prose-heavy source of truth. | Confident | `.planning/v0.9-phases/6/06-CONTEXT.md`, `.planning/v0.9-phases/7/07-CONTEXT.md`, Elixir/Phoenix OSS repo norms researched during this session |

### Proof standard
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Public Day-1 closure requires more than repo-internal task tests; it should include doc-contract checks and a fresh Phoenix host smoke lane. | Likely | `test/mix/tasks/parapet.install_test.exs`, `test/mix/tasks/parapet.doctor_test.exs`, `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md`, Phoenix/Igniter generator proof norms researched during this session |
| The fresh-host proof lane should stop at install, doctor, and docs handoff rather than pulling in Prometheus/Grafana/provider runtime infrastructure. | Confident | `.planning/ROADMAP.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, `README.md`, `docs/operator-ui.md`, Phase 5 verification posture |

### End-to-end boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| “End-to-end” for Phase 8 should mean fresh host adoption through `mix parapet.install` -> `mix parapet.doctor` -> docs handoff consistency. | Likely | `.planning/ROADMAP.md`, `lib/mix/tasks/parapet.install.ex`, `lib/mix/tasks/parapet.doctor.ex`, `README.md` |
| Real multi-node correctness proof remains Phase 5 work; Phase 8 only needs to verify that doctor surfaces those boundaries honestly. | Confident | `.planning/v0.9-phases/5/VERIFICATION.md`, `lib/mix/tasks/parapet.doctor.ex`, `test/mix/tasks/parapet.doctor_test.exs` |

### AC-01 interpretation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `AC-01` is stale wording and should be corrected during closure instead of forcing UI into the default install path. | Confident | `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md`, `lib/mix/tasks/parapet.install.ex`, `README.md`, `docs/operator-ui.md` |
| The coherent shipped contract is core install by default with operator UI as an explicit opt-in extra when LiveView is present. | Confident | `lib/mix/tasks/parapet.install.ex`, `test/mix/tasks/parapet.install_test.exs`, `README.md`, `docs/operator-ui.md` |

### Reconciliation scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 8 should reconcile only the directly covered proof surfaces and leave milestone-wide tracker sync to Phase 9. | Confident | `.planning/ROADMAP.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, `.planning/v0.9-phases/6/06-CONTEXT.md`, `.planning/v0.9-phases/7/07-CONTEXT.md` |

### Maintainer left-shift policy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Low-impact DX choices should be auto-resolved from product DNA and locked phase decisions unless they materially change public posture. | Confident | `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md`, `prompts/parapet-engineering-dna-from-sibling-libs.md`, `prompts/parapet-brand-identity-deep-research.md` |

## Corrections Made

The initial assumptions were expanded with advisor-style research instead of user-specified corrections.

### Research-backed refinements
- Added a fresh Phoenix host smoke lane to the proof recommendation so “end-to-end” stays honest and Phoenix-idiomatic rather than relying only on repo-internal task tests.
- Narrowed the reconciliation default to direct proof surfaces only, leaving `STATE.md` and wider milestone sync to Phase 9.
- Converted the unclear `AC-01` assumption into an explicit correction path: update requirement wording instead of widening the default install surface.
- Captured an explicit left-shift policy for future GSD work so low-impact DX questions are decided from locked product posture by default.

## Research Inputs Used

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/v0.9-MILESTONE-AUDIT.md`
- `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md`
- `.planning/phases/04-unified-install-path-dx/RESEARCH.md`
- `.planning/phases/04-unified-install-path-dx/04-VALIDATION.md`
- `.planning/phases/04-unified-install-path-dx/04-01-SUMMARY.md`
- `.planning/phases/04-unified-install-path-dx/04-02-SUMMARY.md`
- `.planning/phases/04-unified-install-path-dx/04-03-SUMMARY.md`
- `.planning/v0.9-phases/2/VERIFICATION.md`
- `.planning/v0.9-phases/5/VERIFICATION.md`
- `.planning/v0.9-phases/6/06-CONTEXT.md`
- `.planning/v0.9-phases/7/07-CONTEXT.md`
- `lib/mix/tasks/parapet.install.ex`
- `lib/mix/tasks/parapet.doctor.ex`
- `test/mix/tasks/parapet.install_test.exs`
- `test/mix/tasks/parapet.doctor_test.exs`
- `README.md`
- `docs/operator-ui.md`
- `prompts/parapet-engineering-dna-from-sibling-libs.md`
- `prompts/parapet-brand-identity-deep-research.md`
- `prompts/sre-observability-elixir-lib-deep-reseach.md`
- `prompts/elixir-telemetry-space-deep-research.md`
- `prompts/parapet-integration-opportunities.md`
- `prompts/prior-art/SOURCE-CANONICAL.md`
- mirrored prior-art docs under `prompts/prior-art/`

## External Prior-Art Themes Applied

- Phoenix/Igniter generators prove generated host-owned seams in fresh apps rather than relying solely on internal AST/unit tests.
- Optional admin/operator/UI surfaces in Phoenix-adjacent tools stay explicit and host-authenticated rather than silently joining the default path.
- Strong OSS proof posture favors rerunnable commands, docs-as-contract, and narrow statement of guarantee boundaries instead of prose attestation.

## Deferred Ideas

- Add a repo-level instruction surface to encode the maintainer’s left-shift preference for low-impact decisions.
- Consider a stronger release-candidate or example-host CI lane later if Parapet wants to claim broader public runtime coverage than Phase 8 currently owns.
