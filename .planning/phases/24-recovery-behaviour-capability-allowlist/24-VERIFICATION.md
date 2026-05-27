---
phase: 24-recovery-behaviour-capability-allowlist
verified: 2026-05-27T19:10:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 24: Recovery Behaviour + Capability Allowlist Verification Report

**Phase Goal:** Ship the host-app-facing capability-registration API — `Parapet.Recovery` behaviour with four callbacks (`id/0`, `label/0`, `preview/2`, `execute/2`) + a uniform crash-proof `attach/1` activation function — and widen the `Parapet.Capabilities` allowlist from 3 atoms to 5 (adds `:revert_feature_flag`, `:disable_metric_label`). Module ships under the **Experimental** tier per the v1.0 freeze contract.
**Verified:** 2026-05-27T19:10:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A host application can declare a recovery action by writing a module with `use Parapet.Recovery` and implementing `id/0`, `label/0`, `preview/2`, `execute/2` — Dialyzer surfaces missing callbacks at compile time. | VERIFIED | `lib/parapet/recovery.ex` declares all four `@callback` signatures with locked types; `defmacro __using__` injects only `@behaviour Parapet.Recovery`; 5 inline fixture modules in `test/parapet/recovery_test.exs` all use `use Parapet.Recovery` and implement all 4 callbacks; `mix compile --warnings-as-errors` exits 0. |
| 2 | `Parapet.Recovery.attach([SomeMissingModule, RealModule])` doesn't crash; logs/skips silently for unloaded modules. | VERIFIED | `attach/1` body uses `Enum.filter(&Code.ensure_loaded?/1)` as the first pipeline stage — silent, no log, no warn. Sync sweep test "silently skips an unloaded module" asserts `{:ok, []} = Recovery.attach([NonExistent.Module])`; "skips unloaded but registers loaded in a mixed list" asserts `{:ok, [:requeue_dead_letter]}` with `NonExistent.Module` in the list; both pass (107 tests, 0 failures). |
| 3 | `Parapet.Recovery.attach([SomeHostModule])` where `SomeHostModule.id/0` returns an atom outside the widened allowlist raises `ArgumentError` with a clear message naming the valid ids. | VERIFIED | `@valid_capabilities` in `lib/parapet/capabilities.ex` holds exactly 5 atoms in locked order; `register_recovery/2` raise branch interpolates `inspect(@valid_capabilities)` producing "Valid ids are: [:retry_async_item, :requeue_dead_letter, :request_manual_provider_check, :revert_feature_flag, :disable_metric_label]"; sync test "raises ArgumentError when fixture id/0 returns an out-of-allowlist atom" calls `Recovery.attach([FixtureInvalidId])` and asserts `assert_raise ArgumentError, ~r/Invalid recovery capability id/` — passes. |
| 4 | 100 async tests registering distinct recovery modules into `Parapet.Capabilities` all pass without bleeding state (the v0.10 SLO Application-env mistake is not repeated — the new registry uses the existing supervised Agent). | VERIFIED | `Parapet.RecoveryAsyncSweepTest` uses `async: true`; `for n <- 1..100 do` generates 100 test functions parameterized cyclically over all 5 allowlisted atoms; each test calls `Capabilities.register_recovery/2` then asserts per-key via `get_recovery/1` only; no `Application.put_env` (grep count=0); no `Capabilities.capabilities(:recovery)` call in production code paths (comment reference only); all 107 tests pass in 0.4s. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/parapet/recovery.ex` | `Parapet.Recovery` behaviour (4 callbacks) + `__using__/1` macro + `attach/1` activation function | VERIFIED | File exists, 107 LOC. Contains all 4 `@callback` declarations with locked signatures, `defmacro __using__(_opts)` injecting only `@behaviour Parapet.Recovery`, `def attach(modules) when is_list(modules)` with `Code.ensure_loaded?` filter and `Parapet.Capabilities.register_recovery/2` delegation via `&module.preview/2` and `&module.execute/2` function captures. Verbatim Experimental admonition present. |
| `lib/parapet/capabilities.ex` | Widened `@valid_capabilities` module attribute (5 atoms instead of 3) | VERIFIED | `@valid_capabilities` holds exactly 5 atoms in locked order: `:retry_async_item`, `:requeue_dead_letter`, `:request_manual_provider_check`, `:revert_feature_flag`, `:disable_metric_label`. Raise branch unchanged, still interpolates `inspect(@valid_capabilities)`. |
| `docs/stability.md` | Experimental Modules table row for `Parapet.Recovery` | VERIFIED | `| \`Parapet.Recovery\` | Host-app-facing recovery action behaviour + activation function |` appears at line 49, positioned between `Parapet.MCP.PrometheusClient` (line 48) and `Parapet.Telemetry.RecoveryAction` (line 50) — awk order check confirmed. |
| `test/parapet/recovery_test.exs` | Sync sweep (SC #1, #2, #3) + 100-async sweep (SC #4) | VERIFIED | File exists, 204 LOC. Contains 5 fixture modules using `use Parapet.Recovery`, `Parapet.RecoveryTest` (async: false, 7 sync tests), `Parapet.RecoveryAsyncSweepTest` (async: true, 100-test for loop). All 107 tests pass. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/parapet/recovery.ex (attach/1)` | `lib/parapet/capabilities.ex (register_recovery/2)` | Direct function call with `[name:, preview:, execute:]` keyword list | VERIFIED | `Parapet.Capabilities.register_recovery(id, name: label, preview: &module.preview/2, execute: &module.execute/2)` at lines 96-100. No `target_kind:` or `preview_only:` passed (grep count=0 for both). |
| `lib/parapet/recovery.ex (@moduledoc)` | `lib/mix/tasks/verify.public_api.ex` | Verbatim Experimental admonition string | VERIFIED | `> #### Experimental {: .warning}` present at line 16; `mix verify.public_api` output confirms `"module": "Parapet.Recovery", "tier": "experimental"`. |
| `test/parapet/recovery_test.exs (async sweep)` | `lib/parapet/capabilities.ex (supervised Agent)` | Direct calls to `Capabilities.register_recovery/2` + `Capabilities.get_recovery/1` | VERIFIED | Async sweep calls `Capabilities.register_recovery/2` then `Capabilities.get_recovery(id)` per test; no state reset between async tests; shared named Agent handles per-key concurrent writes. |
| `test/parapet/recovery_test.exs (sync sweep)` | `lib/parapet/recovery.ex (attach/1)` | Fixture modules using `use Parapet.Recovery` + `Recovery.attach/1` calls | VERIFIED | All 7 sync tests call `Recovery.attach([fixture_module])` through the full `attach/1` path. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `lib/parapet/capabilities.ex` | `state.recovery` map | `Agent.update` with `put_in(state, [:recovery, id], capability)` | Yes — Agent-persisted map keyed by capability id atom | FLOWING |
| `lib/parapet/recovery.ex` | `registered` list | `Enum.filter(&Code.ensure_loaded?/1) |> Enum.map(...)` over caller-supplied modules | Yes — built from real module calls at attach time | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 107 recovery tests (sync + 100 async) pass | `mix test test/parapet/recovery_test.exs --max-failures 1` | 107 tests, 0 failures, 0.4s | PASS |
| Existing capabilities tests still pass | `mix test test/parapet/capabilities_test.exs --max-failures 1` | 4 tests, 0 failures | PASS |
| `mix verify.public_api` classifies `Parapet.Recovery` as experimental | `mix verify.public_api` | JSON output includes `"module": "Parapet.Recovery", "tier": "experimental"` | PASS |
| `mix compile --warnings-as-errors` exits 0 | `mix compile --warnings-as-errors` | No output (exit 0) | PASS |

### Probe Execution

Step 7c: SKIPPED — no probe scripts declared in PLAN files and phase is a pure Elixir behaviour/API phase with no `scripts/*/tests/probe-*.sh` files. Behavioral spot-checks above serve the equivalent role.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| RCV-01 | 24-01, 24-03 | Host application can declare named recovery actions via `Parapet.Recovery` behaviour (callbacks: `id/0`, `label/0`, `preview/2`, `execute/2`) | SATISFIED | `lib/parapet/recovery.ex` declares 4 callbacks; `__using__/1` injects `@behaviour Parapet.Recovery`; fixture modules and sync tests exercise the full declaration path. |
| RCV-02 | 24-01, 24-03 | `Parapet.Recovery.attach/1` is uniform and crash-proof — silently skips unloaded host modules via `Code.ensure_loaded?/1` | SATISFIED | `Enum.filter(&Code.ensure_loaded?/1)` in `attach/1`; two tests verify silent skip for single unloaded module and mixed lists; no Logger call in skip path. |
| RCV-03 | 24-02, 24-03 | `Parapet.Capabilities` allowlist widened from 3 to 5 atoms; non-allowlist ids rejected with clear error | SATISFIED | 5-atom `@valid_capabilities` verified; ArgumentError message interpolates allowlist; tests verify `:revert_feature_flag` and `:disable_metric_label` acceptance and out-of-allowlist rejection. |

No orphaned requirements: REQUIREMENTS.md maps RCV-01, RCV-02, RCV-03 all to Phase 24. All three are accounted for and satisfied.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/parapet/recovery_test.exs` | 153 | `capabilities(:recovery)` appears in a comment (not in executable code) | Info | No impact — the grep check `grep -c "Capabilities.capabilities(:recovery)"` returns 0; the raw word match `grep -c "capabilities(:recovery)"` returns 1 but the match is inside a `#` comment. Confirmed non-executable. |

No `TBD`, `FIXME`, `XXX`, or `TODO` markers found in any phase-modified file. No stub patterns (`return null`, `return []`, placeholder strings) found in production code. No `Application.put_env` in test file.

The code review (24-REVIEW.md) identified four warnings (WR-01 through WR-04) about robustness gaps in `attach/1` (unrescued callback exceptions, missing `function_exported?` guard, no atom-element type validation, no `label/0` type validation) and five info-level notes. These are quality concerns for Phase 29 (STAB-07) graduation, not correctness defects. None constitute a phase-24 BLOCKER because: the success criteria do not require rescue of host-callback exceptions; the test suite exercises all allowlisted/rejection paths correctly; and the Experimental tier explicitly allows these kinds of robustness gaps before Stable graduation.

### Human Verification Required

None. All four success criteria are fully verifiable from the codebase and test execution. `mix verify.public_api` confirms the Experimental tier classification programmatically. The prebuilt `docs/stability.md` row and the test suite run cover all observable behaviors.

### Gaps Summary

No gaps. All four phase success criteria are verified by direct code inspection, pattern matching against the actual source files, and live test execution (107 tests, 0 failures). Requirements RCV-01, RCV-02, and RCV-03 are all satisfied. The four code-review warnings (WR-01 through WR-04) are quality notes for Phase 29 graduation hardening — they do not block the phase-24 goal.

---

_Verified: 2026-05-27T19:10:00Z_
_Verifier: Claude (gsd-verifier)_
