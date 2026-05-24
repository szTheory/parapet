---
phase: 18-adoption-authoring-docs
plan: "03"
subsystem: documentation
tags: [slo-authoring, journey-slicing, low-traffic, decision-tree, docs]
dependency_graph:
  requires: []
  provides: [docs/slo-authoring-guide.md]
  affects: [docs/slo-reference.md (cross-linked)]
tech_stack:
  added: []
  patterns: [prose-led second-person voice, nested bullet decision tree, plain fence for PromQL, adopter-flows.md voice analog]
key_files:
  created: [docs/slo-authoring-guide.md]
  modified: []
decisions:
  - "Decision tree rendered as nested bullet tree per Claude's discretion in CONTEXT.md (D-14) - no new Mermaid tooling"
  - "ASCII-only characters throughout to match existing doc voice (adopter-flows.md uses no non-ASCII)"
  - "Both tasks authored in a single file write since the file did not exist - committed together with a fix commit for ASCII normalization"
metrics:
  duration: "2m 30s"
  completed_date: "2026-05-24"
  tasks_completed: 2
  files_created: 1
---

# Phase 18 Plan 03: SLO Authoring Guide Summary

Created `docs/slo-authoring-guide.md` - a prose-led conceptual guide teaching journey-slicing via a decision tree anchored to the real WebSaaS slices, plus a low-traffic section quoting the Generator's exact rendered guard, windows, multipliers, min_total_rate default, synthetic-probe fallback, and the lower-the-objective anti-pattern.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author journey-slicing decision tree (SLO-03) | 9e73841 | docs/slo-authoring-guide.md (created) |
| 2 | Author Low-Traffic and Low-Volume Services section (SLO-04) | 9e73841 | docs/slo-authoring-guide.md (extended in same write) |

## What Was Built

`docs/slo-authoring-guide.md` (113 lines) covering:

**Journey-slicing decision tree (SLO-03):**
- Opens with prose framing: SLOs should track user-visible journeys, not raw system health
- Nested bullet decision tree with spine litmus: "Does this failure directly prevent a user task?"
- Good examples anchored to all three real WebSaaS slices (`web_saas_login_journey`, `web_saas_http_availability`, `web_saas_oban_job_success`)
- Bad example: CPU/memory gauge SLO (does not directly prevent a user task)
- Cross-links to `docs/slo-reference.md` for the full slice catalog (no duplication)
- Custom slice authoring section showing provider registration pattern

**Low-traffic and low-volume services section (SLO-04):**
- Verbatim rendered guard shape (plain fence, no language tag)
- Concrete `web_saas_login_journey` `:page` example: `parapet:web_saas_login_journey:error_ratio:5m > 0.0144 and parapet:web_saas_login_journey:total_rate:5m > 0.01`
- `min_total_rate: 0.01` default named (from `Parapet.SLO.SliceSpec` struct default), overridable per-slice
- Six windows listed verbatim: `["5m", "30m", "1h", "2h", "6h", "3d"]`
- Multipliers: 14.4x (`:page`/5m), 6.0x (`:ticket`/30m), 1.0x (`:warning`/6h)
- Extended-window approach mapped to real 6h/3d Generator windows
- `Parapet.Metrics.Probe` named as real synthetic-probe fallback with its two metrics: `parapet.probe.run.total` and `parapet.probe.run.duration.ms`

**"What not to do" section (anti-patterns):**
- Explicitly names "Lower the objective to silence noise" as the wrong move
- Infrastructure metric SLOs as noise producers
- Raw PromQL without denominator guard
- "No data" misread as "green"

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Non-ASCII typographic characters replaced with ASCII equivalents**
- **Found during:** Post-write verification check for emojis/non-ASCII
- **Issue:** Em dashes (U+2014), arrows (U+2192), and multiplication signs (U+00D7) were used as typographic improvements; however, existing docs (adopter-flows.md, slo-reference.md) use ASCII only
- **Fix:** Replaced all em dashes with ` - `, all arrows with `->`, all multiplication signs with `x`
- **Files modified:** docs/slo-authoring-guide.md
- **Commit:** b6ecbc6

## Threat Model Compliance

**T-18-03-01 (Tampering/drift - low-traffic guard description):** Mitigated. Guard shape quoted verbatim from `generator.ex:106`. `min_total_rate: 0.01` sourced from `slice_spec.ex:27,43`. Six windows from `generator.ex:10`. Multipliers from `generator.ex:196-199`. Concrete `web_saas_login_journey` example is arithmetically correct (0.001 * 14.4 = 0.0144).

**T-18-03-02 (Repudiation - lower-the-objective anti-pattern):** Mitigated. "Lower the objective to silence noise" named explicitly as the wrong move in the "What not to do" section, with the correct alternative (denominator guard + extended windows + synthetic probes) described throughout.

## Known Stubs

None. The guide references only real, implemented surfaces: `web_saas_*` slices are in `Parapet.SLO.StarterPack.WebSaaS`, `Parapet.Metrics.Probe` is implemented in `lib/parapet/metrics/probe.ex`, generator behavior verified in `lib/parapet/slo/generator.ex`.

## Threat Flags

None. Single Markdown file with no input parsing, auth, cryptography, or I/O.

## Self-Check: PASSED

- `docs/slo-authoring-guide.md` exists: CONFIRMED
- Commit 9e73841 exists: CONFIRMED
- Commit b6ecbc6 exists: CONFIRMED
- All anti-drift greps pass (min_total_rate 0.01, six windows verbatim, 0.0144 example, Parapet.Metrics.Probe, lower-the-objective named, slo-reference cross-link, three WebSaaS slices, litmus phrase)
- 113 lines (minimum 70): CONFIRMED
- No non-ASCII characters: CONFIRMED
