---
phase: 24-recovery-behaviour-capability-allowlist
plan: "02"
subsystem: capabilities
tags:
  - capabilities
  - allowlist
  - stability-docs
  - rcv-03
dependency_graph:
  requires:
    - "24-01 (Parapet.Recovery behaviour module — the new atoms will be consumed by attach/1)"
  provides:
    - "@valid_capabilities widened to 5 atoms (RCV-03)"
    - "docs/stability.md Experimental Modules table row for Parapet.Recovery"
  affects:
    - "lib/parapet/capabilities.ex — module attribute widened"
    - "docs/stability.md — one row inserted"
tech_stack:
  added: []
  patterns:
    - "Compile-time allowlist via module attribute (@valid_capabilities) enforced by guard + raise"
    - "docs/stability.md Experimental Modules table row format (Pattern 9)"
key_files:
  created: []
  modified:
    - lib/parapet/capabilities.ex
    - docs/stability.md
decisions:
  - "D-09: Widened @valid_capabilities from 3 to 5 in locked order per ROADMAP success criterion"
  - "D-10: raise branch at capabilities.ex:42-45 left untouched — inspect(@valid_capabilities) auto-reflects widened list"
  - "D-11: lib/parapet/telemetry/recovery_action.ex not touched — vocab agreement enforced solely by @valid_capabilities"
  - "D-15: Parapet.Recovery row inserted alphabetically between Parapet.MCP.PrometheusClient and Parapet.Telemetry.RecoveryAction"
metrics:
  duration: "~8 min"
  completed: "2026-05-27T22:33:57Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 24 Plan 02: Capability Allowlist Widening Summary

Widened `@valid_capabilities` in `lib/parapet/capabilities.ex` from 3 atoms to 5 (appending `:revert_feature_flag` and `:disable_metric_label`), and added the `Parapet.Recovery` row to the Experimental Modules table in `docs/stability.md`. Closes RCV-03.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Widen @valid_capabilities from 3 atoms to 5 | 18b174b | lib/parapet/capabilities.ex |
| 2 | Add Parapet.Recovery row to docs/stability.md | 7625df4 | docs/stability.md |

## Widened @valid_capabilities

The `@valid_capabilities` module attribute at `lib/parapet/capabilities.ex:14-19` now contains exactly 5 atoms in the locked order (per D-09 and ROADMAP.md success criterion #3):

```elixir
@valid_capabilities [
  :retry_async_item,
  :requeue_dead_letter,
  :request_manual_provider_check,
  :revert_feature_flag,
  :disable_metric_label
]
```

The `register_recovery/2` raise branch at lines 42-45 was NOT touched — it already interpolates `inspect(@valid_capabilities)` so the widened atoms flow through automatically. The error message now renders: `"Valid ids are: [:retry_async_item, :requeue_dead_letter, :request_manual_provider_check, :revert_feature_flag, :disable_metric_label]"`.

## Existing Test Compatibility

The `assert_raise ArgumentError, ~r/Invalid recovery capability id/` regex at `test/parapet/capabilities_test.exs:32-36` captures only the error message prefix — it still matches unchanged. `mix test test/parapet/capabilities_test.exs` exits 0 with 4 tests, 0 failures.

## docs/stability.md Row

One new row inserted alphabetically between `Parapet.MCP.PrometheusClient` and `Parapet.Telemetry.RecoveryAction` in the Experimental Modules table:

```markdown
| `Parapet.Recovery` | Host-app-facing recovery action behaviour + activation function |
```

Row shape matches adjacent rows: pipe, backtick-wrapped module name, pipe, sentence-case noun phrase with no trailing period, pipe.

## Files NOT Modified

- `lib/parapet/telemetry/recovery_action.ex` — its `allowed_public_keys/1` enumerates metadata KEY names, not value vocabularies. Atom-vocab agreement is enforced solely by `@valid_capabilities` (D-11). Zero drift risk.
- `test/parapet/capabilities_test.exs` — no test modifications per plan requirement.
- `lib/parapet/capabilities.ex` lines 42-45 (raise branch) — byte-for-byte unchanged (D-10).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — both files are production-ready with no placeholder content.

## Self-Check: PASSED

- `lib/parapet/capabilities.ex` exists and has 5 atoms in @valid_capabilities: VERIFIED
- `:revert_feature_flag` appears exactly once: VERIFIED (grep count=1)
- `:disable_metric_label` appears exactly once: VERIFIED (grep count=1)
- `docs/stability.md` contains exactly one `| \`Parapet.Recovery\` |` row: VERIFIED (grep count=1)
- Row positioned between PrometheusClient and RecoveryAction: VERIFIED (awk order check)
- `mix compile --warnings-as-errors` exits 0: VERIFIED
- `mix test test/parapet/capabilities_test.exs` exits 0 (4 tests, 0 failures): VERIFIED
- `lib/parapet/telemetry/recovery_action.ex` not in git diff: VERIFIED
- `git diff --name-only HEAD~2 HEAD` lists exactly `docs/stability.md` and `lib/parapet/capabilities.ex`: VERIFIED
- Task 1 commit 18b174b exists: VERIFIED
- Task 2 commit 7625df4 exists: VERIFIED

### Note on Full Suite

`mix test` shows 366 tests, 1 failure. The failure is `Parapet.Automation.ExecutorClusterSmokeTest` ("test shared claim semantics survive one local-plus-peer race canary") — a pre-existing environment-conditional cluster smoke test that times out when a distributed Erlang peer cannot be started (`:peer.start_link` times out). This test is unrelated to Plan 02 changes. The PROJECT.md key decisions table documents this pattern: "Environment-conditional peer canary — Skips cleanly without distributed Erlang instead of failing hard with `:nodistribution`". No action required.
