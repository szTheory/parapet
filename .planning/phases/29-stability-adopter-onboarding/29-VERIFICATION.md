---
phase: 29-stability-adopter-onboarding
verified: 2026-05-28T22:00:00Z
status: passed
score: 4/4
overrides_applied: 0
---

# Phase 29: Stability + Adopter Onboarding — Verification Report

**Phase Goal:** Declare `Parapet.Recovery` Stable in `docs/stability.md`; ship CHANGELOG migration notes for adopters who pattern-match `confirm_runbook_step/4` return values; ship `mix parapet.gen.recovery` Igniter task that scaffolds a custom capability module; add `mix parapet.doctor` recovery-action adoption signal; write `docs/recovery-actions.md` adopter guide. Closes the "shipped != adopted" gap.

**Verified:** 2026-05-28T22:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `docs/stability.md` lists `Parapet.Recovery` under Stable tier; 4 callbacks named; Deprecation/Compatibility Register names additive `confirm_runbook_step/4` variants as not-removed-in-1.x; CHANGELOG migration note delivered via commit footer | VERIFIED | `docs/stability.md` line 35: Recovery row in Stable table with all 4 callbacks named. Line 198: compat note for `{:short_circuited, reason}` and `{:conflicted, claim_id}`. Commit `4ff05f8` footer contains verbatim MIGRATION NOTE per D-05. Recovery is absent from Experimental table. |
| 2 | Running `mix parapet.gen.recovery RetryDLQ` scaffolds `lib/<host>/recovery/retry_dlq.ex` with `use Parapet.Recovery` + 4 callbacks + docstring template + unit-test stub; flag-based, non-interactive; omitting NAME raises ArgumentError; re-running does not overwrite | VERIFIED | `lib/mix/tasks/parapet.gen.recovery.ex` exists with `positional: [:name]` (bare atom, required), `def igniter(igniter)` (not deprecated igniter/2), `igniter.args.positional.name`, `Igniter.copy_template/5`, `Igniter.create_new_file/4` both with `on_exists: :skip`. EEx template at `priv/templates/parapet.gen.recovery/recovery.ex.eex` contains `use Parapet.Recovery` and all 4 frozen callbacks. Tests: 3 passing (scaffold-content, missing-arg-raises, on_exists-skip). |
| 3 | `mix parapet.doctor` reports a `recovery` check: attached-capability count, unregistered-capability-in-runbook warnings, per-capability host-module/callback health; zero capabilities → :skip (not :warn); `--ci` green on fresh install | VERIFIED | `lib/mix/tasks/parapet.doctor.ex` line 22: "recovery" in `@static_checks`. Line 95: dispatch clause. Lines 354-429: full `check_recovery/0` implementing all 3 signals (COUNT → :skip on empty, UNREGISTERED-IN-RUNBOOK → :warn, PER-CAPABILITY HEALTH → :warn). Agent-not-running guard at line 357. Tests: 16 passing covering all 6 signal conditions including A1 :skip-on-zero and URL-runbook SKIP. |
| 4 | `docs/recovery-actions.md` exists (372 lines), explains capability authoring + Preview/Confirm UX (by reference) + 3 error semantics + 4 worked examples; cross-linked from `docs/operator-ui.md` and `docs/getting-started.md`; registered in ExDoc `extras` AND `groups_for_extras: Guides` | VERIFIED | File exists at 372 lines. Contains `mix parapet.gen.recovery`, all 4 capability atoms (`:retry_async_item`, `:requeue_dead_letter`, `:revert_feature_flag`, `:disable_metric_label`), all 3 error semantics (`short_circuited`, `conflicted`, `recovery_failed`). Cross-links: `docs/getting-started.md` line 100 (Next steps bullet); `docs/operator-ui.md` line 210 (forward-reference). `mix.exs` shows exactly 2 occurrences of `docs/recovery-actions.md` — one in `extras` (line 71) and one in `groups_for_extras: Guides` (line 89). |

**Score:** 4/4 truths verified

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/parapet/recovery.ex` | Stable-tier moduledoc admonition + callback-freeze prose | VERIFIED | Line 16: verbatim `> #### Stable {: .info}` string. Lines 22-25: callback-freeze prose naming all 4 callbacks. 4 @callbacks present (id/0, label/0, preview/2, execute/2 at lines 34, 42, 51, 60). No Experimental admonition. |
| `docs/stability.md` | Parapet.Recovery in Stable table + Deprecation Register additive-variant note | VERIFIED | Single occurrence at line 35 (Stable table). No occurrence in Experimental section. Compat note at line 198 names both additive variants and "not removed in 1.x". |
| `test/mix/tasks/verify.public_api_test.exs` | Wave-0 regression case asserting Stable classification | VERIFIED | `describe "Parapet.Recovery stable reclassification"` block with 2 cases: live `Code.fetch_docs/1` asserting `:stable`; companion asserting old Experimental string returns `:experimental`. 9 tests total, 0 failures. |
| `lib/mix/tasks/parapet.gen.recovery.ex` | Flag-based Igniter generator with positional: [:name] | VERIFIED | `positional: [:name]` (bare atom), `def igniter(igniter)`, `igniter.args.positional.name`, `Igniter.copy_template` — all present. |
| `priv/templates/parapet.gen.recovery/recovery.ex.eex` | EEx template with use Parapet.Recovery + 4 callbacks + docstrings | VERIFIED | Contains `use Parapet.Recovery`, `def id`, `def label`, `def preview`, `def execute`. All 5 allowlist atoms listed in `id/0` doc comment. |
| `test/mix/tasks/parapet.gen.recovery_test.exs` | Wave-0 Igniter.Test assertions for scaffold, required-arg, on_exists:skip | VERIFIED | 3 tests using `configure_and_run/3` pattern. All pass. |
| `lib/mix/tasks/parapet.doctor.ex` | check_recovery + @static_checks registration + dispatch | VERIFIED | "recovery" in @static_checks line 22; dispatch at line 95; `defp check_recovery` at line 354 with all 3 signals. |
| `test/mix/tasks/parapet.doctor_test.exs` | Wave-0 cases for 6 check_recovery signal conditions | VERIFIED | `describe "check_recovery"` at line 245 with 6 cases covering all signal conditions. 16 tests total, 0 failures. |
| `docs/recovery-actions.md` | Adopter guide >= 120 lines | VERIFIED | 372 lines. Contains all required sections: authoring, Preview/Confirm (by reference), error semantics, 4 worked examples, what-not-to-do. |
| `mix.exs` | recovery-actions.md in extras + Guides group | VERIFIED | Exactly 2 occurrences confirmed. Line 71 (extras), line 89 (groups_for_extras: Guides). |
| `docs/getting-started.md` | Next-steps cross-link to recovery-actions.md | VERIFIED | Line 100: `- [Recovery Actions Guide](docs/recovery-actions.md)` bullet. |
| `docs/operator-ui.md` | Forward-reference to recovery-actions.md | VERIFIED | Line 210: forward-reference sentence after Named Capabilities section. |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `recovery.ex` moduledoc admonition | `mix verify.public_api` classify | `> #### Stable {: .info}` regex match | WIRED | Live `Code.fetch_docs(Parapet.Recovery)` in test asserts `:stable` — 9 tests pass. |
| `docs/stability.md` Stable table | machine classification | human mirror must move together | WIRED | Single occurrence in Stable table; absent from Experimental table. |
| `parapet.gen.recovery.ex` | `recovery.ex.eex` template | `Igniter.copy_template/5` | WIRED | `Igniter.copy_template` call present pointing to `priv/templates/parapet.gen.recovery/recovery.ex.eex`. |
| `gen.recovery info/2` | `igniter.args.positional.name` | `positional: [:name]` required-arg declaration | WIRED | Both `positional: [:name]` and `igniter.args.positional.name` present. |
| `check_recovery` (count signal) | `Parapet.Capabilities.capabilities(:recovery)` | Agent read; length == 0 → :skip | WIRED | Line 360: `caps = Parapet.Capabilities.capabilities(:recovery)`. Empty → `:skip`. |
| `check_recovery` (unregistered signal) | `Parapet.SLO.all()` → runbook module → `__runbook_schema__/0` | `recovery_runbook_module/1` guard pattern | WIRED | Lines 370-391: full signal-2 logic with URL-null guard. |
| `check_recovery` (health signal) | `Code.ensure_loaded?/1` + `function_exported?/2` on 4 callbacks | read-only introspection | WIRED | Lines 394-419: signal-3 iterates caps, checks each of 4 callbacks. |
| `mix.exs extras` | `mix.exs groups_for_extras: Guides` | both must list recovery-actions.md | WIRED | 2 occurrences confirmed in mix.exs. |
| `docs/recovery-actions.md` | `docs/operator-ui.md` Preview-First Recovery | `operator-ui.html#phase-7-preview-first-recovery` link | WIRED | Line 9 and line 155 reference `operator-ui.html#phase-7-preview-first-recovery`. |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `check_recovery` in doctor.ex | `caps` | `Parapet.Capabilities.capabilities(:recovery)` → Capabilities Agent | Real Agent read (GenServer state) | FLOWING |
| `check_recovery` signal-2 | `warnings` list | `Parapet.SLO.all()` → runbook module introspection → `get_recovery/1` cross-check | Real runtime data | FLOWING |
| `check_recovery` signal-3 | `warnings` list | `Code.ensure_loaded?/1` + `function_exported?/2` on registered modules | Real BEAM introspection | FLOWING |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| gen.recovery scaffolds correct paths and content | `mix test test/mix/tasks/parapet.gen.recovery_test.exs` | 3 tests, 0 failures | PASS |
| verify.public_api classifies Recovery as :stable | `mix test test/mix/tasks/verify.public_api_test.exs` | 9 tests, 0 failures | PASS |
| check_recovery all 6 signal conditions | `mix test test/mix/tasks/parapet.doctor_test.exs` | 16 tests, 0 failures | PASS |
| Compile clean | `mix compile --warnings-as-errors` | Exit 0, no output | PASS |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| STAB-07 | 29-01 | `Parapet.Recovery` behaviour and 4 callbacks declared Stable; CHANGELOG migration note for additive error tuple variants | SATISFIED | Moduledoc flipped to Stable; stability.md row moved; Deprecation Register updated; commit 4ff05f8 footer contains MIGRATION NOTE per D-05 (release-please-managed delivery). |
| ADOP-01 | 29-02 | `mix parapet.gen.recovery <NAME>` Igniter task; flag-based; not interactive | SATISFIED | Task exists, required positional arg enforced by Igniter, `on_exists: :skip`, 3 passing tests. |
| ADOP-02 | 29-03 | `mix parapet.doctor` recovery-action adoption signal: count, unregistered-capability warnings, per-capability callback health | SATISFIED | `check_recovery` registered in @static_checks and implemented with all 3 signals; 6 passing signal-condition tests. |
| ADOP-03 | 29-04 | `docs/recovery-actions.md` adopter guide with capability authoring, Preview/Confirm UX, error semantics, 4 worked examples; cross-linked from operator-ui.md and getting-started.md; ExDoc wired | SATISFIED | 372-line guide exists; all 4 capability atoms present; all 3 error semantics present; both cross-links present; 2 ExDoc registrations in mix.exs. |

---

## Anti-Patterns Found

No debt markers (TBD, FIXME, XXX) or stub patterns found in any phase 29 implementation files.

The `def preview(_incident, _step), do: {:ok, %{}}` and `def execute(_incident, _target_refs), do: {:ok, %{}}` in the EEx template are intentional adopter-facing placeholders (documented as starting points), not library stubs — the template ships with `@doc` placeholders explaining what the adopter must implement. This is correct by design.

---

## Human Verification Required

None. All success criteria are mechanically verifiable and have been verified against the codebase.

---

## Gaps Summary

No gaps. All 4 success criteria are fully satisfied in the codebase:

1. **Criterion 1 (STAB-07):** `Parapet.Recovery` is in the Stable table in `docs/stability.md` (single occurrence, Stable section only), the moduledoc carries the verbatim `> #### Stable {: .info}` admonition, all 4 callbacks are named in the Deprecation Register row, and the MIGRATION NOTE for additive `confirm_runbook_step/4` variants is delivered in commit `4ff05f8`'s footer per the release-please-managed conventional commit body approach (D-05). The human-readable mirror is also in the Deprecation/Compatibility Register.

2. **Criterion 2 (ADOP-01):** `mix parapet.gen.recovery RetryDLQ` scaffolds the correct paths (`lib/<app>/parapet/recovery/retry_dlq.ex` + `test/<app>/parapet/recovery/retry_dlq_test.exs`) with `use Parapet.Recovery` and all 4 frozen callbacks. Required positional arg enforced. `on_exists: :skip` prevents overwrites. 3 Igniter.Test cases pass.

3. **Criterion 3 (ADOP-02):** `mix parapet.doctor recovery` is selectable, reports all 3 D-12 signals, maps zero capabilities to `:skip` (A1 invariant — `--ci` green on fresh install), maps unregistered-capability-in-runbook and missing-callback to `:warn`. URL-valued runbooks are silently skipped. `check_runbooks` is untouched (D-13). 16 doctor tests pass.

4. **Criterion 4 (ADOP-03):** `docs/recovery-actions.md` (372 lines) explains all required topics and contains all 4 worked examples (capability-backed only). Cross-linked from `docs/operator-ui.md` and `docs/getting-started.md`. Registered in both `extras` and `groups_for_extras: Guides` in `mix.exs`.

---

_Verified: 2026-05-28T22:00:00Z_
_Verifier: Claude (gsd-verifier)_
