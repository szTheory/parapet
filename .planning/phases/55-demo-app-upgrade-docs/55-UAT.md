---
status: testing
phase: 55-demo-app-upgrade-docs
source: [55-VERIFICATION.md]
started: 2026-07-01T21:05:00Z
updated: 2026-07-01T21:05:00Z
---

## Current Test

number: 1
name: upgrade-1.x.md structure — per-block recompile lines, rollback/half-migrated, FAQ
expected: |
  Every config block is immediately followed by `mix deps.compile parapet --force`;
  the Rollback section covers Track A and Track B and explicitly covers half-migrated
  recovery with an explanation of the single-transaction guarantee; the FAQ is
  substantive and answers the "do-nothing upgrader" scenario.
awaiting: user response

## Tests

### 1. upgrade-1.x.md structure — per-block recompile lines, rollback/half-migrated, FAQ
expected: |
  Read `docs/upgrade-1.x.md` in full and confirm: (a) the Track A config block
  (`config :parapet, schema_prefix: nil`) is immediately followed by the force-recompile
  line; (b) the Track B section has its own recompile line after `mix ecto.migrate`;
  (c) the Rollback section covers both Track A and Track B rollback and explicitly covers
  half-migrated recovery with an explanation of the single-transaction guarantee;
  (d) the FAQ is substantive and answers the "do-nothing upgrader" scenario.
  (Grep confirms `mix deps.compile parapet --force` appears 7×, but cannot confirm
  immediate adjacency to each block, nor judge FAQ completeness/tone.)
result: [pending]

### 2. upgrade-1.x.md tone & cross-doc verbatim accuracy
expected: |
  Read `docs/upgrade-1.x.md` and confirm the TL;DR leads with a clear reassurance
  ("your data never moves" or equivalent); the "Action Required" caveat is honest and
  correctly framed for do-nothing upgraders (does NOT falsely claim "no action required");
  and the verbatim Track A/B copy matches the `mix parapet.doctor` output and the
  generated migration as described in 54-CONTEXT D-04/D-17/D-18.
  (Reassure-then-instruct pattern, framing correctness, and cross-doc verbatim
  consistency require reading — cannot be asserted by grep.)
result: [pending]

### 3. deployment.md "Schema location" single-source compliance
expected: |
  Read the `docs/deployment.md` "Schema location" subsection (near Step 4) and confirm it
  reassures + routes to `upgrade-1.x.md` WITHOUT restating Track A/B mechanics (no config
  blocks, no ALTER TABLE steps, no GRANT SQL). Should be ~3–5 lines: reassurance + route.
result: [pending]

### 4. README.md schema note placement & tone
expected: |
  Read the `README.md` Installation section schema note (~lines 62–64) and confirm:
  (a) it is placed after the `mix parapet.install` block; (b) it routes to
  `migration-v1.md` Step 3 (not directly to `upgrade-1.x.md`); (c) tone is brief and
  reassuring, not alarming. Should be a one-line note.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
