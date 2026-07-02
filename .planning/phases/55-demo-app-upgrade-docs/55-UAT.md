---
status: complete
phase: 55-demo-app-upgrade-docs
source: [55-VERIFICATION.md]
started: 2026-07-01T21:05:00Z
updated: 2026-07-01T21:15:00Z
---

## Current Test

[testing complete]

## Tests
<!-- All four checkpoints shifted left into automated assertions.
     Covered by test/parapet/docs_phase_55_test.exs (Parapet.DocsPhase55Test),
     which runs untagged in the default `mix test` and gates release_gate. -->

### 1. upgrade-1.x.md structure — per-block recompile lines, rollback/half-migrated, FAQ
expected: |
  Every config block is followed (within its subsection) by `mix deps.compile parapet --force`;
  the Rollback section covers Track A, Track B, and half-migrated recovery with the
  single-transaction guarantee; the FAQ is substantive and answers the "do-nothing upgrader"
  scenario.
result: pass
source: automated
coverage_id: D1, D2
verified_by: "Parapet.DocsPhase55Test — 'upgrade-1.x.md structure (UAT 1)'"

### 2. upgrade-1.x.md tone & cross-doc verbatim accuracy
expected: |
  TL;DR leads with a data-never-moves reassurance; the "Action Required" caveat is honest
  (does not falsely claim no action required); the Track A config line, recompile command,
  and six ALTER TABLE SET SCHEMA lines stay consistent with the doctor, the move generator,
  and the six spine schema modules.
result: pass
source: automated
coverage_id: D1
verified_by: "Parapet.DocsPhase55Test — 'upgrade-1.x.md tone and cross-source consistency (UAT 2)'"

### 3. deployment.md "Schema location" single-source compliance
expected: |
  The deployment.md "Schema location" subsection routes to upgrade-1.x.md and restates no
  Track A/B mechanics (no config blocks, no ALTER TABLE, no GRANT SQL, no recompile command).
result: pass
source: automated
coverage_id: D5
verified_by: "Parapet.DocsPhase55Test — 'deployment.md single-source compliance (UAT 3)'"

### 4. README.md schema note placement & tone
expected: |
  The README Installation schema note routes to migration-v1.md Step 3, sits after the
  `mix parapet.install` block (byte-offset check), and restates no mechanics; migration-v1.md
  has the Step 3 schema-location step among seven steps.
result: pass
source: automated
coverage_id: D6
verified_by: "Parapet.DocsPhase55Test — 'README schema note placement and tone (UAT 4)'"

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none — all checkpoints automated; 0 human verification required]
