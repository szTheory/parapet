---
phase: 29-stability-adopter-onboarding
reviewed: 2026-05-28T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - lib/parapet/recovery.ex
  - lib/parapet/capabilities.ex
  - lib/mix/tasks/parapet.doctor.ex
  - lib/mix/tasks/parapet.gen.recovery.ex
  - priv/templates/parapet.gen.recovery/recovery.ex.eex
  - test/mix/tasks/parapet.doctor_test.exs
  - test/mix/tasks/parapet.gen.recovery_test.exs
  - test/mix/tasks/verify.public_api_test.exs
  - mix.exs
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
---

# Phase 29: Code Review Report

**Reviewed:** 2026-05-28
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 29 graduates `Parapet.Recovery` to the Stable tier, adds the `mix parapet.gen.recovery`
Igniter generator with its EEx template, and adds a `check_recovery` static check to
`mix parapet.doctor` (threading a new `module:` field through `Parapet.Capabilities`).

The `module:` field addition to `Capabilities` is backward-compatible: it defaults to `nil`
via `Keyword.get/2`, the only registration callers (`attach/1` and tests) supply or omit it
safely, and downstream consumers (`Parapet.Operator`) read capability maps by dot-access on
specific keys rather than strict map pattern matching, so a new key cannot break them. The
doctor's nil-guard for an unstarted Capabilities Agent (`Process.whereis/1 == nil → :skip`)
and its `nil` `module:` branch in the per-capability health loop are both correct and verified
against the SLO/Runbook schema shapes.

However, the review surfaces one **stability-contract BLOCKER** (the Stable admonition and
`@doc since:` tags claim v1.1.0 while `mix.exs` is pinned at v1.0.3 — shipping a Stable
guarantee against a version that does not exist breaks the very deprecation policy this phase
is establishing), plus several robustness and test-quality WARNINGs around `attach/1` runtime
crashes on malformed modules, generator namespace edge cases, and weak test assertions.

No structural pre-pass (`<structural_findings>`) was provided, so this report contains only
narrative findings.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Stable-tier version claim (v1.1.0) does not exist in mix.exs (pinned at 1.0.3)

**File:** `lib/parapet/recovery.ex:18`, `lib/parapet/recovery.ex:23`, `lib/parapet/recovery.ex:27,36,44,53`; `mix.exs:5`
**Issue:** `Parapet.Recovery` is declared **Stable as of v1.1.0** in the moduledoc admonition
(line 18: "stable as of v1.1.0"), the frozen-callback paragraph (line 23: "frozen for 1.x"),
and every callback carries `@doc since: "1.1.0"`. But `mix.exs` declares `@version "1.0.3"`,
and `docs:` uses `source_ref: "v#{@version}"` → `v1.0.3`. The companion stable module
`Parapet.Runbook` correctly says "stable as of v1.0.0", matching a released version.

Publishing a Stable contract against a version number that has not been released is a
contract defect, not cosmetic: per the project's own Stability & Deprecation Policy, the
Stable promise ("API will not change without a major-version bump and a full deprecation
cycle") is anchored to the version in which the guarantee took effect. If the package is cut
as 1.0.x, HexDocs will render `@doc since: "1.1.0"` and an "as of v1.1.0" admonition for a
module that shipped in 1.0.x — adopters cannot determine which release actually carries the
frozen contract, and the `since:` metadata is wrong. If instead the intent is to ship as
1.1.0, then `mix.exs` was never bumped and the release will go out mislabeled.

This is the phase whose entire purpose is the stability guarantee; the version anchor must be
internally consistent before it ships.
**Fix:** Reconcile the version. Either bump `mix.exs` to the release that actually carries the
frozen contract:
```elixir
# mix.exs
@version "1.1.0"
```
or, if this work ships in the 1.0.x line, correct every `since:`/admonition to the real
version:
```elixir
# lib/parapet/recovery.ex
> This module is **stable** as of v1.0.4. ...
@doc since: "1.0.4"
```
Whichever is chosen, `mix.exs @version`, the moduledoc admonition, the "frozen for 1.x"
paragraph, the four `@doc since:` tags, and CHANGELOG must all agree.

## Warnings

### WR-01: `attach/1` crashes (UndefinedFunctionError) on a loaded-but-incomplete module instead of skipping

**File:** `lib/parapet/recovery.ex:91-111` (specifically lines 96-97)
**Issue:** `attach/1` filters modules by `Code.ensure_loaded?/1`, then unconditionally calls
`module.id()` and `module.label()` (lines 96-97). If a module loads but does not export
`id/0` or `label/0` (e.g., a partially-authored recovery module, or a stale module that still
loads), `attach/1` raises `UndefinedFunctionError` and aborts the entire activation list — any
modules earlier in the list are registered, later ones are not, and the host app's
`Application.start` callback crashes. The moduledoc (lines 9-10) frames missing callbacks as
"compile-time warnings via Dialyzer," but Dialyzer warnings are not enforcement: a host that
ignores them, or that defines `id/0` with the wrong arity, hits a hard runtime crash at boot.
The `check_recovery` doctor check cannot mitigate this because registration must succeed before
the doctor can inspect it. The contract promises silent-skip semantics for the
`ensure_loaded?` case but offers no protection for the loaded-but-malformed case.
**Fix:** Guard the callback calls so a malformed module is skipped (consistent with the
documented optional-dependency skip pattern) rather than crashing activation. For example,
filter on `function_exported?/3` for all four callbacks before invoking, or wrap the per-module
body in a rescue that drops the offending module:
```elixir
|> Enum.filter(&Code.ensure_loaded?/1)
|> Enum.filter(fn m ->
  function_exported?(m, :id, 0) and function_exported?(m, :label, 0) and
    function_exported?(m, :preview, 2) and function_exported?(m, :execute, 2)
end)
```
If a crash is the intended behavior for a malformed-but-required module, document that
explicitly in the moduledoc so the silent-skip language does not mislead.

### WR-02: Generator strips trailing "Web" greedily, producing wrong module namespace for Web-suffixed apps

**File:** `lib/mix/tasks/parapet.gen.recovery.ex:30`
**Issue:** `base_name = web_module |> inspect() |> String.trim_trailing("Web")`. `String.trim_trailing/2`
removes **all** repeated trailing occurrences of the suffix, not just one (verified:
`String.trim_trailing("MyAppWebWeb", "Web") == "MyApp"`). Two failure modes:
(1) Igniter's `web_module/1` appends "Web" only if the prefix does not already end in "Web", so
for an app whose module namespace legitimately ends in "Web" (e.g., a crawler app `SpiderWeb`,
prefix already `SpiderWeb`), `web_module/1` returns `SpiderWeb`, and `trim_trailing("Web")`
yields `Spider` — the generated module lands under `Spider.Parapet.Recovery` while the app's
real namespace is `SpiderWeb`. (2) Any double-"Web" inspect string collapses both. The result
is a recovery module generated into the wrong namespace, which will not compile/resolve under
the host's expected module tree.
**Fix:** Strip exactly one trailing "Web" via a pattern match or `String.replace_suffix/3`:
```elixir
base_name =
  case web_module |> inspect() do
    s -> String.replace_suffix(s, "Web", "")
  end
```
or derive the base from the app module prefix directly rather than from the Web module.

### WR-03: `check_recovery` Signal-2 only inspects legacy + provider SLOs that resolve to module runbooks; URL/atom runbook resolution is brittle

**File:** `lib/mix/tasks/parapet.doctor.ex:432-440`
**Issue:** `recovery_runbook_module/1`'s `is_binary` clause calls `String.to_existing_atom/1`
and rescues `ArgumentError → nil`. This is mostly fine, but it has a latent false-positive
path: if a runbook string coincides with an already-interned non-module atom (short words like
`"ok"`, `"error"`, or any atom previously created in the BEAM), `String.to_existing_atom/1`
returns that atom **without raising** (verified: `String.to_existing_atom("ok") == :ok`). The
function then returns a non-module atom as `module`. The downstream guard
`Code.ensure_loaded?(module)` (line 373) returns `false` for a non-module atom (verified), so
the check degrades to "skip this SLO" rather than crashing — acceptable today, but the logic
relies on `ensure_loaded?` as an implicit type filter rather than an explicit "is this a
module" check, which is fragile if the guard ever changes.
**Fix:** Make the module-ness check explicit so intent is clear and resilient:
```elixir
defp recovery_runbook_module(runbook) when is_binary(runbook) do
  case String.to_existing_atom(runbook) do
    atom when is_atom(atom) ->
      if function_exported?(atom, :__runbook_schema__, 0), do: atom, else: nil
  end
rescue
  ArgumentError -> nil
end
```

### WR-04: Weak test assertion — `String.contains?(messages, "1")` for the healthy-capability count

**File:** `test/mix/tasks/parapet.doctor_test.exs:281`
**Issue:** The "N healthy capabilities registered → :info with count" test asserts only
`String.contains?(messages, "1")`. The character `"1"` appears in virtually any non-trivial
output (timestamps, atom suffixes, other counts), so this assertion does not actually prove the
count "1" was reported for the recovery check. A regression that printed "0 recovery
capabilities" or omitted the count entirely while still printing any `1` anywhere would pass.
**Fix:** Assert against the full, specific message the code emits (line 424:
`"#{count} recovery #{noun} registered and healthy."`):
```elixir
assert String.contains?(messages, "1 recovery capability registered and healthy")
```
This also pins the singular/plural noun logic (line 423), which is currently untested.

### WR-05: `check_recovery` Signal-3 silently skips capabilities registered without a `module:` field, masking unhealthy hosts

**File:** `lib/mix/tasks/parapet.doctor.ex:396-419` (the `nil -> acc` branch at lines 399-400)
**Issue:** The per-capability health loop does `case Map.get(cap, :module) do nil -> acc`. Any
capability registered without a `module:` (which is the default for every code path other than
`Parapet.Recovery.attach/1`, since `register_recovery/2` defaults `module:` to `nil`) is
silently treated as healthy and skipped — no callback-presence check, no warning. Because
`module:` is brand-new in this phase, **all** capabilities registered by anything that has not
yet been updated to pass `module:` (direct `register_recovery/2` callers, older adapters) will
bypass Signal-3 entirely, so the "registered and healthy" `:info` can be reported for
capabilities whose host modules are missing or broken. The doctor presents a green health
status it did not actually verify. This is acceptable as a transitional default only if it is
intentional and documented; as written, it silently under-reports.
**Fix:** Distinguish "no module supplied" from "module healthy." At minimum emit an
informational/`:skip`-style note that the capability could not be health-checked because no host
module was recorded, e.g.:
```elixir
nil ->
  ["Recovery capability #{inspect(cap.id)} has no host module recorded; callback health could not be verified" | acc]
```
or document explicitly that module-less registrations are exempt from health checks and ensure
the `:info` "healthy" wording is not emitted when any capability was skipped.

## Info

### IN-01: Generator never threads `target_kind`, so attached capabilities always fall back at the Operator layer

**File:** `lib/mix/tasks/parapet.gen.recovery.ex` (whole `igniter/1`), `priv/templates/parapet.gen.recovery/recovery.ex.eex`, `lib/parapet/recovery.ex:99-105`
**Issue:** `Parapet.Capabilities.register_recovery/2` supports a `:target_kind` key
(`capabilities.ex:35`), and `Parapet.Operator` reads it (`operator.ex:1010:
capability.target_kind || step.target_kind`). But `attach/1` never sets `target_kind`, and the
generated module/template offers no way to declare one, so every generated+attached capability
has `target_kind: nil` and relies on the step-level fallback. This is internally consistent
(the fallback exists), but it means a generated recovery action cannot influence
target-kind resolution at the capability level. Worth a note for adopter ergonomics.
**Fix:** Consider documenting that target_kind is step-driven for generated modules, or extend
the behaviour/generator if capability-level target_kind is intended to be authorable.

### IN-02: `parse_threshold/2` has no clause for a non-CI invalid value other than via the catch-all

**File:** `lib/mix/tasks/parapet.doctor.ex:54-61`
**Issue:** Minor readability/robustness note: `parse_threshold/2` matches `nil` (CI/non-CI),
`"warn"`, `"error"`, then a catch-all that raises. This is correct, but the catch-all
`parse_threshold(other, _is_ci)` also catches non-string non-nil inputs; since `--threshold`
is parsed as `:string`, that cannot occur today, so this is informational only. No action
required unless the switch type changes.
**Fix:** None required; flagged for awareness.

### IN-03: Generated test stub asserts `execute(%{}, [])` while behaviour/template default returns `{:ok, %{}}` for any input — stub never exercises real logic

**File:** `lib/mix/tasks/parapet.gen.recovery.ex:45-69`, `priv/templates/parapet.gen.recovery/recovery.ex.eex:55,66`
**Issue:** The scaffolded test asserts `{:ok, _} = preview(%{}, %{})` and
`{:ok, _} = execute(%{}, [])`, but the template's default `preview/2` and `execute/2` both
return `{:ok, %{}}` unconditionally. The generated tests therefore pass trivially before the
adopter writes any logic, which is the intended scaffold behavior — but there is no `# TODO`
marker in the test stub steering the adopter to replace the assertions once real logic lands.
Low risk; a comment would improve the onboarding signal.
**Fix:** Add a `# TODO: replace with assertions for your real preview/execute behavior` line in
the generated `test_stub_content`.

### IN-04: `Parapet.Capabilities` moduledoc still labeled Experimental while it now carries a Stable module's `module:` contract field

**File:** `lib/parapet/capabilities.ex:6-10`
**Issue:** `Capabilities` remains Experimental (correctly, per the phase scope), but it is now
the registry backing the newly-Stable `Parapet.Recovery`. The new `module:` field is read by
the Stable behaviour's `attach/1` and by the doctor. This is a deliberate layering choice (the
Stable surface is `Parapet.Recovery`, not the registry), but it is worth confirming that no
part of the Stable contract leaks the Experimental `Capabilities` map shape to adopters such
that a future Experimental change to that map silently breaks a Stable guarantee.
**Fix:** None required if `Capabilities` is confirmed internal-only to the Stable surface;
flagged for the stability-boundary audit.

---

_Reviewed: 2026-05-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
