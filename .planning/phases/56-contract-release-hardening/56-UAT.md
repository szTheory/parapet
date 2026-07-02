---
status: complete
phase: 56-contract-release-hardening
source: [56-VERIFICATION.md]
started: 2026-07-02T18:45:00Z
updated: 2026-07-02T18:50:00Z
bespoke_gate_added: false
mix_ci_alias_added: false
---

## Current Test

[testing complete]

## Tests
<!-- All three acceptance criteria are automated. No human verification required.
     Enforcement backstop is the already-existing CI (ci.yml lint + test jobs).
     No new gate or mix ci alias was added — deferred to v1.8 / CI-01 (D-10). -->

### 1. SAFE-01 — Public API manifest zero-drift

expected: |
  `mix verify.public_api` (no `--write`) exits 0; `priv/parapet/public_api_stable.json`
  is unchanged; `Parapet.Evidence.schema_prefix/0` is the sole prefix-related export
  (pre-existing Stable since v1.0.3); phases 53–55 added zero new public exports.
result: pass
source: automated
coverage_id: D1
proof_command: |
  mix verify.public_api && test -z "$(git status --short priv/parapet/public_api_stable.json)" && echo ZERO_DRIFT
proof_output: "ZERO_DRIFT (exit 0; manifest unchanged)"
ci_backstop: "ci.yml lint job — 'Verify Public API' step (line 55–56); runs on every push/PR"
evidence_file: .planning/phases/56-contract-release-hardening/56-SAFE-01-EVIDENCE.md
verified_by: "56-02-PLAN.md execution (commit 56c0a08) + local re-run at 56-04 verification"

### 2. SAFE-02 — Telemetry contract frozen at 35 families + bare :source behavioral assertion

expected: |
  `mix test test/telemetry_contract_test.exs` passes: 35 tests, 0 failures, confirming
  exactly 35 telemetry event families with no `[:parapet, :schema, ...]` event.
  `mix test test/parapet/metrics/ecto_test.exs` passes: 4 tests, 0 failures, with Test 4
  proving that a live ConcurrencyRepo spine query emits `metadata.source == "parapet_incidents"`
  (bare table name, no schema qualifier — `@schema_prefix` does not leak into Prometheus label
  cardinality).
result: pass
source: automated
coverage_id: D2, D3
proof_command: |
  mix test test/telemetry_contract_test.exs
  mix test test/parapet/metrics/ecto_test.exs
proof_output: |
  "35 tests, 0 failures" (telemetry contract)
  "4 tests, 0 failures" (ecto source behavioral, Test 4 passes)
ci_backstop: "ci.yml test job — 'Test' step (mix test); 4-cell matrix (3 × OTP + parapet/public schema_prefix axis)"
evidence_file: 56-01-SUMMARY.md
verified_by: "56-01-PLAN.md execution (commits cb474a7 + c70bf9d) + local re-run at 56-04 verification"

### 3. SAFE-04 — Two-part honest feat(schema) CHANGELOG entry

expected: |
  CHANGELOG.md contains a `### Features` block under `## Unreleased` with a `feat(schema)`
  two-part entry:
  (a) Headline reassurance: data never moves automatically (true for new AND existing installs).
  (b) Distinct existing-adopter action-required line: `config :parapet, schema_prefix: nil`
      + link to `docs/upgrade-1.x.md`.
  The false unqualified banner "No action required for existing installs" is absent.
  Both parts are structurally adjacent in the same bullet body so release-please lifts them
  together into the v1.7 GitHub release note.
result: pass
source: automated
coverage_id: D4
proof_command: |
  grep -q 'feat' CHANGELOG.md && grep -q 'schema_prefix: nil' CHANGELOG.md && grep -q 'docs/upgrade-1.x.md' CHANGELOG.md && ! grep -q 'No action required for existing installs' CHANGELOG.md && echo OK
  awk '/^### Features/{f=1} f&&/schema_prefix: nil/{a=1} f&&/never move|not migrated|migrated automatically|does not move/{r=1} END{exit (a&&r)?0:1}' CHANGELOG.md && echo BOTH_PARTS_PRESENT
proof_output: "OK\nBOTH_PARTS_PRESENT"
ci_backstop: "ci.yml release-please workflow renders Unreleased feat entry into v1.7 GitHub release note"
evidence_file: 56-03-SUMMARY.md
verified_by: "56-03-PLAN.md execution (commit 73ec64c) + local re-run at 56-04 verification"

## Summary

total: 3
passed: 3
issues: 0
pending: 0
skipped: 0
blocked: 0
human_verification_required: 0

## Enforcement Note (D-10)

No bespoke milestone-gate mix task was added. No `mix ci` alias was added.
Enforcement of all three done-criteria is the **already-existing CI**:

- SAFE-01 → `ci.yml` lint job "Verify Public API" step
- SAFE-02 → `ci.yml` test job "Test" step (mix test; full matrix)
- SAFE-04 → `ci.yml` release-please workflow (renders feat entry into GitHub release note)

Bespoke CI gate deferred to v1.8 / CI-01 per D-10.

## Gaps

[none — all 3 acceptance criteria automated; 0 human verification required]
