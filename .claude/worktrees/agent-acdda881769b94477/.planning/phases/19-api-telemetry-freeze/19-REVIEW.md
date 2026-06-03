---
phase: 19-api-telemetry-freeze
reviewed: 2026-05-25T09:10:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/mix/tasks/verify.public_api.ex
  - test/telemetry_contract_test.exs
  - test/parapet/slo_test.exs
  - test/mix/tasks/verify.public_api_test.exs
findings:
  critical: 0
  warning: 6
  info: 4
  total: 10
status: issues_found
---

# Phase 19: Code Review Report

**Reviewed:** 2026-05-25T09:10:00Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Reviewed the four in-scope logic files for Phase 19 (API & Telemetry Freeze):
the `verify.public_api` Mix task, the telemetry contract test, the SLO test, and
the public-API task test. All 46 tests pass and `mix verify.public_api` exits 0
against the current tree.

The most consequential findings are in the **telemetry contract test**, whose
header comments make a strong claim ("adding a new emit call that is NOT listed
here causes the length assertion to fail in CI") that the test does not actually
enforce. The contract is a hand-curated snapshot with **no coupling to the
emit sites in `lib/`**, so it cannot detect the drift it advertises. One whole
`describe` block ("measurement key contract") is tautological — it asserts a map
contains a key drawn by iterating that same map. These are correctness defects in
the *guarantee the test claims to provide*, not in production behavior, so they
are graded WARNING rather than BLOCKER.

The `verify.public_api` task has two latent correctness gaps: `@moduledoc false`
modules in the public namespace are misreported as "missing documentation" (and
halt the build), and the tier detection relies on naive substring matching that
will misfire if a future moduledoc legitimately contains both callout markers.
Neither triggers today because no current module hits those paths.

No security vulnerabilities, injection vectors, hardcoded secrets, or data-loss
risks were found. The `Resolvable` exclusion change (`.Resolvable.` →
`.Resolvable`) does not over-exclude: the only module in the tree whose name
contains "Resolvable" is the protocol `Parapet.SLO.Resolvable` and its
auto-generated `defimpl` dispatch modules — all correctly excluded.

## Warnings

### WR-01: Telemetry contract test does not enforce its central claim (no coupling to emit sites)

**File:** `test/telemetry_contract_test.exs:14-16, 190-194`
**Issue:** The module comment asserts: "Adding a new emit call that is NOT listed
here causes the length assertion to fail in CI." This is false. The
`length(@all_documented_families) == 27` assertion only fails if a developer edits
the `@other_documented_families` / `@async_delivery_families` literals inside this
file. There is no comparison against the actual `:telemetry.execute(...)` /
`:telemetry.span(...)` / `event_name:` call sites in `lib/`. I verified the tree
emits families through `lib/parapet/integrations/*.ex`, `lib/parapet/metrics/*.ex`,
`lib/parapet/operator.ex`, `lib/parapet/evidence.ex`, `lib/parapet/deploy.ex`,
etc. A developer who adds `:telemetry.execute([:parapet, :new, :event], ...)` in
`lib/` will see **zero** test failures, directly contradicting the documented
contract. The test is a manual snapshot dressed as an automated drift detector.
**Fix:** Either (a) downgrade the comment to state the truth ("this is a manual
fixture; update it alongside emit changes"), or (b) make it real by scanning emit
sites at test time and diffing against the fixture, e.g.:
```elixir
# Build the actual set from source and assert equality with the fixture.
emitted =
  Path.wildcard("lib/**/*.ex")
  |> Enum.flat_map(fn f ->
    File.read!(f)
    |> then(&Regex.scan(~r/\[:parapet(?:,\s*:\w+)+\]/, &1))
    |> Enum.map(fn [m] -> Code.eval_string(m) |> elem(0) end)
  end)
  |> MapSet.new()

assert MapSet.subset?(emitted, MapSet.new(@all_documented_families)),
       "Undocumented [:parapet, …] families emitted in lib/: " <>
         inspect(MapSet.difference(emitted, MapSet.new(@all_documented_families)))
```
(Regex-from-source is fragile; the durable fix is a single source-of-truth
registry the emit sites and the test both read from.)

### WR-02: "measurement key contract" describe block is tautological

**File:** `test/telemetry_contract_test.exs:209-222`
**Issue:** The generated tests iterate `for {family, _keys} <- @documented_measurements`
and then assert `Map.has_key?(@documented_measurements, @family)`. Since `@family`
is, by construction, a key of `@documented_measurements`, this assertion can never
fail. It is pure tautology — it provides no protection against renamed or removed
measurement keys at emit sites, despite the inline comment claiming it guards
exactly that. Note this is structurally different from the metadata contract
block (lines 224-240), which does compare against the real module
(`AsyncDelivery.allowed_public_keys/1`) and is genuinely non-tautological.
**Fix:** Compare against the real measurement keys, or delete the block. If a
runtime source of truth does not exist for these measurements, the honest
intermediate is to assert the exact value rather than mere presence:
```elixir
test "#{inspect(@family)} measurement keys match fixture" do
  assert Enum.sort(@documented_measurements[@family]) == Enum.sort(@expected_keys),
         "Measurement keys drifted for #{inspect(@family)}."
end
```
At minimum, fix the misleading comment that says this catches emit-site renames.

### WR-03: `@moduledoc false` public-namespace modules misreported as missing docs and halt the build

**File:** `lib/mix/tasks/verify.public_api.ex:75-85, 43-49`
**Issue:** `check_module/1` maps `Code.fetch_docs/1` returning `:hidden` (i.e.
`@moduledoc false`) to `{false, :internal}`. The `missing_docs` filter at line 43
is `not m.has_docs`, which is true for `:internal`. So any `Parapet.*` module
deliberately marked `@moduledoc false` (a standard, legitimate way to mark a
module internal without moving it into the `Parapet.Internal.*` namespace) is
reported as "missing documentation" and triggers `System.halt(1)`. The `:internal`
tier atom is computed but then never distinguished from a genuine
documentation omission, making it dead/misleading. This does not fire today
(no current public-namespace module uses `@moduledoc false`), but it is a
correctness trap that will reject a valid future state.
**Fix:** Treat `:hidden`/`:internal` as an intentional exclusion, not a failure:
```elixir
missing_docs =
  Enum.filter(manifest, fn m -> not m.has_docs and m.tier != :internal end)
```
or filter `:internal`-tier modules out of the manifest in `public_api_module?`
/ before the docs check entirely.

### WR-04: Tier detection by substring is brittle and can silently misclassify

**File:** `lib/mix/tasks/verify.public_api.ex:88-99`
**Issue:** `detect_tier_from_text/1` checks `String.contains?(text, "{: .info}")
and String.contains?(text, "Stable")` anywhere in the entire moduledoc, not within
the same callout block. A future moduledoc that documents an unrelated `{: .info}`
callout *and* mentions the word "Stable" anywhere in prose/examples would be
classified `:stable` even if its real tier callout is `Experimental`. Because the
`cond` checks `:stable` first, a module with both `{: .info}`+"Stable" and
`{: .warning}`+"Experimental" present (e.g., a module whose doc shows examples of
both admonitions) is silently classified as `:stable`. I confirmed no current
`Parapet.*` module trips this (only `verify.public_api.ex` itself contains both
keywords, and it is outside the `Parapet.` namespace), but the matching is a
latent correctness hazard for an API-freeze gate that is supposed to be
authoritative.
**Fix:** Anchor the match to the callout line so the class and the keyword must
co-occur in the same admonition, e.g.:
```elixir
cond do
  Regex.match?(~r/####\s+Stable\s*\{:\s*\.info\}/, text) -> :stable
  Regex.match?(~r/####\s+Experimental\s*\{:\s*\.warning\}/, text) -> :experimental
  true -> :unclassified
end
```

### WR-05: STAB-06 deprecation test relies on compiler warning timing not guaranteed stable across runs

**File:** `test/parapet/slo_test.exs:101-125`
**Issue:** The test wraps `Code.compile_string` in `capture_io(:stderr, ...)` and
asserts the `@deprecated` warning text appears. The `@deprecated` attribute warning
is emitted by the compiler when the *call site* is compiled. The defined probe
module `Parapet.SLOTest.DeprecationProbe` is compiled fresh each run, so the call
site is recompiled and the warning fires — this passes today. However: (a) the
test depends on the compiler emitting deprecation warnings to `:stderr` rather
than via the diagnostics/IO-less path, which is a compiler behavior, not a
contract; (b) defining a fixed module name inside `Code.compile_string` produces a
"redefining module" warning if the same probe name is ever compiled twice in one
VM, polluting the captured stderr; (c) the assertion is a loose substring match on
"deprecated" / "Parapet.SLO.Provider" — if Elixir changes the deprecation message
format (it has changed across versions), the test breaks despite the deprecation
still working. This is fragile-by-coincidence rather than flaky-today.
**Fix:** Harden by (1) using a unique module name per run
(`Module.concat(__MODULE__, "DeprecationProbe#{System.unique_integer([:positive])}")`
built into the source string) to avoid redefinition warnings, and (2) asserting on
the stable part of the message (the `@deprecated` string you control,
`"Use a Parapet.SLO.Provider module instead"`) rather than the compiler-generated
"deprecated" prefix:
```elixir
assert output =~ "Use a Parapet.SLO.Provider module instead"
```

### WR-06: `provider_catalog`/`all` test invokes real adapter side effects without isolating them

**File:** `test/parapet/slo_test.exs:90-94`
**Issue:** `test "attach does not silently activate providers"` calls
`Parapet.attach(adapters: [:mailglass, :chimeway, :rindle])`, which (per
`lib/parapet.ex:30-47`) resolves `Parapet.Integrations.<Adapter>` and invokes
`setup/0` on each loaded module. `setup/0` for these adapters attaches real
`:telemetry` handlers (global, process-independent state). The test runs with
`async: false` and a `setup` block that resets only `:slos`/`:providers` app env,
not attached telemetry handlers. Attached handlers leak across tests in the same
VM and are never detached in `on_exit`, which can interfere with other suites that
assert on handler attachment/emission. The assertion itself
(`provider_catalog() == [] and all() == []`) is fine, but the means of getting
there has uncontrolled global side effects.
**Fix:** Either stub/mock the adapter resolution, or detach handlers in `on_exit`:
```elixir
on_exit(fn ->
  for {id, _} <- :telemetry.list_handlers([]) do
    if is_binary(id) and String.starts_with?(id, "parapet"), do: :telemetry.detach(id)
  end
end)
```
Best is to assert the behavior without invoking `setup/0` side effects at all.

## Info

### IN-01: Inconsistent invocation of deprecated `SLO.define/2` across tests

**File:** `test/parapet/slo_test.exs:22-38, 40-51, 73-78`
**Issue:** `test "creates a valid SLO and stores it"` (line 24) and
`test "merges legacy environment state…"` (line 73) call `SLO.define(...)`
directly, which emits the `@deprecated` compile warning during test compilation
(observed in the test run output). `test "raises ArgumentError…"` (line 42)
deliberately uses `apply(SLO, :define, [...])` to *dodge* that warning. The
inconsistency is confusing and means the test file cannot compile under
`--warnings-as-errors`. (No `--warnings-as-errors` flag is currently set for test
compilation, so this does not break CI today.)
**Fix:** Pick one approach. If exercising the deprecated path is intentional,
suppress consistently (e.g. via `apply/3` everywhere, or
`@compile {:no_warn_undefined, ...}` is not applicable — use a module attribute
note). Document why the direct calls are acceptable.

### IN-02: Moduledoc and code disagree on the exclusion-substring semantics

**File:** `lib/mix/tasks/verify.public_api.ex:12-13, 72`
**Issue:** The `@moduledoc` (line 13) states modules "containing `.Resolvable.`
in their name are excluded," but the code (line 72) excludes on `.Resolvable`
(no trailing dot) — the recent fix that catches the terminal protocol module
`Parapet.SLO.Resolvable`. The documentation is now stale and understates the
filter. (Verified the broader `.Resolvable` match does not over-exclude: the only
matching module names in the tree are the protocol and its `defimpl` dispatch
modules.)
**Fix:** Update the moduledoc to `containing ".Resolvable" in their name`.

### IN-03: Manifest output channel branching (Jason vs inspect) produces incomparable artifacts

**File:** `lib/mix/tasks/verify.public_api.ex:34-41`
**Issue:** When `Jason` is loaded the manifest is emitted as pretty JSON; otherwise
as Elixir `inspect/2` output. A downstream consumer that diffs the manifest across
environments (CI with Jason vs. a minimal env without it) gets two
non-interchangeable formats for the same logical manifest, undermining the
"generates a manifest" purpose. This is a robustness/maintainability concern, not
a bug.
**Fix:** Pick one canonical format (JSON), and fail loudly if Jason is unavailable
when the task is meant to produce a machine-readable manifest, rather than
silently degrading to `inspect`.

### IN-04: `event_name/1` clause-coverage not asserted in the contract test

**File:** `test/telemetry_contract_test.exs:11, 224-240`
**Issue:** The test derives families from `AsyncDelivery.event_families/0` and
checks `allowed_public_keys/1`, but never asserts that
`AsyncDelivery.event_name/1` round-trips each family atom back to the same tuple
that appears in `@event_families`. A drift between `event_families/0`
(line 56-63 of the module) and the `event_name/1` clauses (line 145-149) would go
undetected by this "freeze" test.
**Fix:** Add a round-trip assertion:
```elixir
for [_, _, family] = full <- AsyncDelivery.event_families() do
  assert AsyncDelivery.event_name(family) == full
end
```

---

_Reviewed: 2026-05-25T09:10:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
