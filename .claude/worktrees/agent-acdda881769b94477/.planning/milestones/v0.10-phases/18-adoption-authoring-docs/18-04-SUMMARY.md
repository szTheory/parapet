---
phase: 18-adoption-authoring-docs
plan: "04"
subsystem: documentation
tags: [docs, integrations, sigra, accrue, rulestead, threadline, adopt-05]
dependency_graph:
  requires: ["18-01"]
  provides: [docs/integrations/sigra.md, docs/integrations/accrue.md, docs/integrations/rulestead.md, docs/integrations/threadline.md]
  affects: [docs/integrations/]
tech_stack:
  added: []
  patterns: [D-11 per-integration guide structure, operator-ui.md voice analog]
key_files:
  created:
    - docs/integrations/sigra.md
    - docs/integrations/accrue.md
    - docs/integrations/rulestead.md
    - docs/integrations/threadline.md
decisions:
  - "All four guides use identical uniform Parapet.attach(adapters: [...]) activation line per D-16; Rulestead-specific docs show the line only as valid, never as a crash"
  - "Rulestead guide explicitly documents OQ-3 gap: adopter must add Parapet.Metrics.Rulestead.metrics() to Telemetry.Metrics reporter or counter never reaches Prometheus"
  - "Accrue and Rulestead guides surface metrics only (no SLO slice claims); Threadline guide scoped to audit-evidence interoperability only (no metrics, no SLO slice)"
  - "sigra.md cross-links to getting-started.md and slo-reference.md; accrue.md cross-links to slo-authoring-guide.md; all cross-links use relative paths"
metrics:
  duration: "8 minutes"
  completed: "2026-05-24"
  tasks_completed: 2
  files_changed: 4
---

# Phase 18 Plan 04: Per-Integration Guides Summary

Four per-integration guides under `docs/integrations/` (Sigra, Accrue, Rulestead, Threadline) following the uniform D-11 structure, with honest per-integration scope and the OQ-3 Rulestead reporter-wiring note.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create docs/integrations/ and author sigra.md and accrue.md | 8e541ff | docs/integrations/sigra.md, docs/integrations/accrue.md |
| 2 | Author rulestead.md and threadline.md | 0839b6e | docs/integrations/rulestead.md, docs/integrations/threadline.md |

## Verification Results

- Anti-drift check 2: `Parapet.attach(adapters: [:rulestead])` appears only as the valid uniform activation line; `Parapet.Integrations.Rulestead.attach()` does not appear in any doc
- Anti-drift check 6: `grep "SLO slice"` returns 0 results in `accrue.md`, `rulestead.md`, `threadline.md`
- OQ-3 documented: `rulestead.md` explicitly instructs adopter to add `Parapet.Metrics.Rulestead.metrics()` to their `Telemetry.Metrics` reporter
- Threadline `Code.ensure_loaded?(Threadline)` guard documented
- No emojis in any file
- All four guides follow D-11 structure: Prerequisites, what it unlocks, activation, config keys, troubleshooting

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None. All four guides describe wired code surfaces verified against live source in 18-RESEARCH.md. Metric names (`parapet_journey_login_count`, `parapet_rulestead_flag_change_total`, etc.) match the live metrics modules.

## Threat Flags

No new network endpoints, auth paths, or trust-boundary surfaces introduced. Four Markdown files with no input parsing, auth, or I/O. T-18-04-01 (Rulestead activation drift) and T-18-04-02 (SLO slice claims drift) both confirmed mitigated by anti-drift checks above. T-18-04-03 (Rulestead metrics silent failure) mitigated by explicit OQ-3 reporter-wiring note in rulestead.md.

## Self-Check: PASSED

- docs/integrations/sigra.md: FOUND
- docs/integrations/accrue.md: FOUND
- docs/integrations/rulestead.md: FOUND
- docs/integrations/threadline.md: FOUND
- Commits 8e541ff, 0839b6e: verified in git log
