---
phase: 23-foundations-telemetry-contract-lease-until-migration
plan: "01"
subsystem: telemetry-contract
tags: [telemetry, contract-module, experimental-tier, recovery-action, v1.1]
dependency_graph:
  requires: []
  provides:
    - Parapet.Telemetry.RecoveryAction (contract module, Experimental tier)
    - docs/telemetry.md Recovery Action Family section
    - docs/stability.md Experimental Modules row
  affects:
    - mix verify.public_api (new module classified :experimental)
    - Phase 26 emit-sites (can call shape_metadata/2 for contract-conformant payloads)
tech_stack:
  added: []
  patterns:
    - Frozen @event_families + closed vocab maps (mirrors AsyncDelivery 1:1)
    - Experimental admonition in @moduledoc (verify.public_api detection)
    - shape_metadata/2 ref-key allowlist + known ref mappings
    - normalize_enum/3 private helper for ArgumentError vocab guards
key_files:
  created:
    - lib/parapet/telemetry/recovery_action.ex
    - test/parapet/telemetry/recovery_action_test.exs
  modified:
    - docs/telemetry.md
    - docs/stability.md
decisions:
  - "Mirrors AsyncDelivery 1:1 in structure per D-09 — closed @event_families, allowed_public_keys/1 per family, shape_metadata/2 ref-key allowlist, bounded vocab guards"
  - "Experimental tier via @moduledoc admonition only (no @stability attribute) per Phase 19 D-02 — verify.public_api regex detects correctly"
  - "event_families/0 returns 8 concrete tuples (5 single-shot + 3 span sub-events) per OQ-1 resolution — span triplet fully enumerated for Phase 26 emit-site verifiability"
  - "No emit-site code in Phase 23 per D-16 — contract test is module introspection only"
  - "All public functions tagged @doc since: '1.1.0' (ships in v1.1, not v1.0)"
metrics:
  duration_minutes: 6
  completed: "2026-05-27T12:25:57Z"
  tasks_completed: 2
  files_created: 2
  files_modified: 2
---

# Phase 23 Plan 01: RecoveryAction Telemetry Contract Summary

Shipped `Parapet.Telemetry.RecoveryAction` — the machine-readable contract module for the `[:parapet, :operator, :recovery_action, ...]` telemetry family under the Experimental stability tier, with a 4-test module-introspection guard and documentation in both `docs/telemetry.md` and `docs/stability.md`.

## What Landed

### 8 Concrete Event Tuples (frozen in @event_families)

```elixir
[:parapet, :operator, :recovery_action, :previewed]
[:parapet, :operator, :recovery_action, :preview_failed]
[:parapet, :operator, :recovery_action, :confirmed]
[:parapet, :operator, :recovery_action, :short_circuited]
[:parapet, :operator, :recovery_action, :conflicted]
[:parapet, :operator, :recovery_action, :executed, :start]
[:parapet, :operator, :recovery_action, :executed, :stop]
[:parapet, :operator, :recovery_action, :executed, :exception]
```

The `:executed` triplet is one logical span family with three sub-events — all three are
enumerated as concrete tuples per OQ-1 so Phase 26 emit-sites can pattern-match against them.

### Closed Vocabularies Shipped

- **outcome** (6 atoms): `:previewed`, `:confirmed`, `:short_circuited`, `:conflicted`, `:succeeded`, `:failed`
- **short_circuit_reason** (4 atoms): `:incident_resolved`, `:breaker_open`, `:preview_expired`, `:target_refs_drift`
- **failure_class** (4 atoms): `:precondition_failed`, `:provider_unavailable`, `:partial_failure`, `:internal_error`
- **actor_kind** (2 atoms): `:human`, `:system`
- **action_kind** (3 strings): `"operator"`, `"automation"`, `"escalation"`
- **refs keys** (4): `:incident_ref`, `:claim_ref`, `:step_ref`, `:preview_ref`

### Experimental Admonition Shape

```elixir
> #### Experimental {: .warning}
>
> This module is **experimental** in v1.x. Its API may change in a minor release with a
> single-version notice in CHANGELOG.md. See
> [Stability & Deprecation Policy](stability.html) for details.
```

`mix verify.public_api` output: `"module": "Parapet.Telemetry.RecoveryAction", "has_docs": true, "tier": "experimental"` — gate exits 0.

## Verification Results

| Check | Result |
|-------|--------|
| `mix test test/parapet/telemetry/recovery_action_test.exs` | 4 tests, 0 failures |
| `mix verify.public_api` | Exit 0; RecoveryAction classified :experimental |
| `mix compile --warnings-as-errors` | Exit 0, no warnings |
| `event_families/0` returns length 8 | `mix run -e '...'` prints `8` |
| `normalize_outcome(:succeeded)` returns `:succeeded` | Confirmed |
| `normalize_outcome(:bogus)` raises ArgumentError | Confirmed |
| `## Recovery Action Family (Experimental)` in telemetry.md | Present |
| `Parapet.Telemetry.RecoveryAction` row in stability.md | Present |
| Stable header at telemetry.md line 3 unchanged | Confirmed |
| Closed vocab atoms enumerated in telemetry.md | Confirmed |

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1: RecoveryAction module | f23ac3e | feat(23-01): ship Parapet.Telemetry.RecoveryAction contract module |
| Task 2: Test + docs | 641ec82 | feat(23-01): ship contract test + docs for RecoveryAction telemetry family |

## Deviations from Plan

None — plan executed exactly as written.

The `Mix.Tasks.Parapet.InstallTest` failure observed during full suite run (`8 failures` vs
`7 on main`) is a pre-existing worktree environment issue (Igniter `mix.exs` lookup fails
in git worktree context — not triggered by main checkout). Scope-excluded per deviation
boundary rule: pre-existing failure in an unrelated file.

## Known Stubs

None — this plan ships a contract module with fully implemented behavior. No hardcoded
empty values, no placeholder text, no data sources left unwired.

## Threat Flags

None — this plan introduces no new attack surface. `Parapet.Telemetry.RecoveryAction` is
a pure contract/introspection module with no network endpoints, no authentication paths,
no file access, and no schema changes at trust boundaries.

## PR Note

Per D-17, this plan lands together with `23-02-SUMMARY.md` (FND-01 `lease_until` migration
+ ClaimService self-heal) in a single coherent PR. Both plans are Wave 1 with zero
`files_modified` overlap.

## Self-Check: PASSED

- `lib/parapet/telemetry/recovery_action.ex` — FOUND
- `test/parapet/telemetry/recovery_action_test.exs` — FOUND
- `docs/telemetry.md` (modified) — FOUND
- `docs/stability.md` (modified) — FOUND
- Commit f23ac3e — FOUND
- Commit 641ec82 — FOUND
