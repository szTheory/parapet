---
phase: 29-stability-adopter-onboarding
plan: "04"
subsystem: docs
tags: [docs, exdoc, recovery, adopter-guide, cross-links]
dependency_graph:
  requires: [29-01, 29-02, 29-03]
  provides: [recovery-actions-guide, exdoc-wiring, cross-links, ADOP-03]
  affects: [docs/recovery-actions.md, mix.exs, docs/getting-started.md, docs/operator-ui.md]
tech_stack:
  added: []
  patterns:
    - ExDoc extras + groups_for_extras two-step registration (both-or-silent-failure)
    - slo-authoring-guide.md structural analog (conviction intro, decision frame, authoring, examples, what-not-to-do)
    - operator-ui.html forward-reference (not re-derivation) of Preview/Confirm UX
key_files:
  created:
    - docs/recovery-actions.md
  modified:
    - mix.exs
    - docs/getting-started.md
    - docs/operator-ui.md
decisions:
  - "recovery-actions.md uses operator-ui.html anchor link (not re-derivation) for Preview/Confirm UX per D-14"
  - "Four worked examples correspond exactly to capability-backed playbook templates (D-15); guidance-only excluded"
  - "ExDoc wiring: both extras and groups_for_extras updated in same commit to avoid silent-failure trap (D-16 / Pitfall 1)"
  - "Cross-links: getting-started.md uses docs/recovery-actions.md (relative .md form); operator-ui.md uses recovery-actions.html (ExDoc .html form) consistent with intra-doc ExDoc links"
metrics:
  duration: "4 minutes"
  completed: "2026-05-29"
  tasks_completed: 3
  files_created: 1
  files_modified: 3
---

# Phase 29 Plan 04: Recovery Actions Guide (ADOP-03) Summary

**One-liner:** `docs/recovery-actions.md` adopter guide for authoring host recovery capabilities — conviction-statement intro, decision frame, generator walkthrough, 4-callback authoring, Preview/Confirm by reference, 3 error semantics, 4 worked examples, what-not-to-do — wired into ExDoc and cross-linked from getting-started.md and operator-ui.md.

## What Was Built

**Task 1 — `docs/recovery-actions.md`** (commit aa4dd44)

Adopter guide mirroring `docs/slo-authoring-guide.md`'s structure:

- Conviction-statement intro establishing the "second half of the job" framing
- "When to wire a recovery capability" decision frame — two decision trees for capability vs. guidance-only; notes that 2 of 6 shipped playbooks are guidance-only by design
- "Authoring a recovery capability" — `mix parapet.gen.recovery <NAME>` invocation (citing scaffold paths from 29-02-SUMMARY.md), 4 frozen callbacks (`id/0`, `label/0`, `preview/2`, `execute/2`) with complete annotated examples, `Parapet.Recovery.attach/1` boot wiring, and `mix parapet.doctor recovery` adoption signal (citing :skip/:warn signals from 29-03-SUMMARY.md)
- "Preview/Confirm UX" — REFERENCE to `operator-ui.html#phase-7-preview-first-recovery` (not re-derived); summarizes 3-state flow at pointer level; documents 5-minute preview expiry
- "Error semantics" — `{:short_circuited, reason}` (3 reasons: `:breaker_open`, `:incident_state_changed`, `:preview_expired`), `{:conflicted, claim_id}` (multi-node claim guard), and `:recovery_failed` TimelineEntry type (execute/2 returned {:error, _}); cross-referenced to stability.html
- "Worked examples" — 4 examples, one per capability-backed playbook (D-15): Stalled Async (`:retry_async_item`), Dead-Letter Drain (`:requeue_dead_letter`), Deploy-Tied Incident (`:revert_feature_flag`), Cardinality Blowout (`:disable_metric_label`). Each shows realistic `preview/2` + `execute/2` implementation with domain-appropriate preview map keys, preconditions, and warnings
- "What not to do" — 5 recovery anti-patterns mirroring slo-authoring-guide.md structure

File: 372 lines (well above 120-line minimum).

**Task 2 — `mix.exs`** (commit e0b71c4)

Added `"docs/recovery-actions.md"` to BOTH the `extras:` list (line 71, after `slo-authoring-guide.md`) and the `groups_for_extras: Guides` list (line 89). Both lists updated in same commit per D-16 / Pitfall 1. `files:` glob at line 43 untouched. `grep -c "docs/recovery-actions.md" mix.exs` returns exactly 2.

**Task 3 — `docs/getting-started.md` + `docs/operator-ui.md`** (commit b6b277d)

- `getting-started.md`: Added 5th bullet to "## Next steps": `- [Recovery Actions Guide](docs/recovery-actions.md) — author host recovery capabilities and wire them to runbook steps`
- `operator-ui.md`: Added forward-reference sentence after line 208 (end of "Named Capabilities" subsection): `See the [Recovery Actions Guide](recovery-actions.html) for step-by-step authoring instructions, worked examples, and the error semantics for each capability outcome.`
- `mix docs` exits 0 with no undefined/broken-reference warnings; `doc/recovery-actions.html` rendered and confirmed in Guides sidebar group.

## Verification Results

- `mix compile --warnings-as-errors` exits 0
- `mix docs` exits 0 (no undefined/broken-reference warnings for recovery-actions.md)
- `doc/recovery-actions.html` exists and is in the Guides sidebar group
- `grep -c "docs/recovery-actions.md" mix.exs` returns 2 (one in `extras`, one in `Guides`)
- `git diff mix.exs` shows NO change to `files:` glob at line 43 (D-16 invariant)
- `grep "recovery-actions" docs/getting-started.md` matches (D-17)
- `grep "recovery-actions" docs/operator-ui.md` matches (D-17)
- All 4 capability atoms present in worked examples (D-15)
- Guidance-only playbooks (retry storm, suppression drift) absent from worked examples
- `grep -niE "short_circuited|conflicted|recovery_failed" docs/recovery-actions.md` returns 8 matches

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — the worked examples use real `def id`, `def label`, `def preview`, `def execute` implementations with realistic domain logic. No placeholder content that blocks the guide's goal.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. This plan edits documentation files and ExDoc config only. T-29-07 (Information Disclosure / docs surface) and T-29-08 (build correctness) mitigations applied as planned: the guide describes the host-owned, allowlist-bounded capability model without secret material; the both-lists grep==2 acceptance + `mix docs` clean-build gate satisfy T-29-08.

## Self-Check: PASSED

Files created:
- FOUND: docs/recovery-actions.md

Commits:
- FOUND: aa4dd44 (docs(29-04): write recovery-actions.md adopter guide)
- FOUND: e0b71c4 (chore(29-04): wire recovery-actions.md into ExDoc extras + Guides group)
- FOUND: b6b277d (docs(29-04): add cross-links in getting-started.md and operator-ui.md)
