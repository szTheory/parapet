---
phase: 24-recovery-behaviour-capability-allowlist
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/parapet/recovery.ex
  - lib/parapet/capabilities.ex
  - docs/stability.md
  - test/parapet/recovery_test.exs
findings:
  critical: 0
  warning: 4
  info: 5
  total: 9
status: issues_found
---

# Phase 24: Code Review Report

**Reviewed:** 2026-05-27
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Phase 24 ships `Parapet.Recovery` (host-app-facing behaviour with `id/0`, `label/0`,
`preview/2`, `execute/2` + `attach/1` activation function) and widens
`Parapet.Capabilities` allowlist from 3 atoms to 5. The implementation is small,
focused, well-tested, and structurally sound. The function-capture bridge to
`Parapet.Operator`'s `is_function/2` guards at `operator.ex:709,767` is preserved
exactly as required by the phase context.

The four warnings below concern a meaningful gap between the moduledoc's
**"crash-proof `attach/1`"** framing and the actual implementation: `attach/1`
defensively handles unloaded modules, but does **not** rescue or guard against
host-module callback failures, missing `function_exported?` checks, non-atom list
elements, or non-`String.t()` return values from `label/0`. None of these are
exploited by the current test suite, but each represents a foot-gun a host
adopter can trip on a Tuesday afternoon.

No security issues. No data-loss risk. No correctness defects in the
allowlist-widening or the 100-async sweep test (its race-avoidance argument
is sound). The findings are quality and robustness concerns that — given the
**Experimental** tier — are acceptable to land, but worth noting before any
graduation to **Stable** in Phase 29 (STAB-07).

## Warnings

### WR-01: `attach/1` is not "crash-proof" — host-module callback exceptions are unrescued

**File:** `lib/parapet/recovery.ex:87-106`
**Issue:** The moduledoc (line 13) and the phase prompt both describe
`attach/1` as **"crash-proof"**, but the implementation only defends against
the *module-not-loaded* case via `Code.ensure_loaded?/1`. Once a module passes
that gate, the calls `module.id()` (line 92) and `module.label()` (line 93)
run with no `try`/`rescue`. If a host module's `id/0` or `label/0` raises
(e.g., `id/0` is implemented in terms of `Application.fetch_env!/2` and the
env var is missing in some test environment), the entire `attach/1` call
crashes mid-list, leaving any modules earlier in the list registered and any
modules later in the list NOT registered — a half-applied state that is hard
to recover from at host-app boot. The same applies if `register_recovery/2`
raises `ArgumentError` for an out-of-allowlist id (line 96): the test at
`test/parapet/recovery_test.exs:127-131` asserts the raise propagates, but
the consequence is "one bad module aborts the whole activation list," which
contradicts the optional-dependency-skip pattern claimed in the moduledoc
(line 70-72: "no log, no warning, no error").
**Fix:** Either soften the moduledoc claim, OR wrap each per-module step in
a `try`/`rescue` that logs and skips on failure, matching the actual
optional-dependency-skip pattern of `Parapet.attach/1`:

```elixir
defp register_one(module) do
  try do
    id = module.id()
    label = module.label()

    :ok =
      Parapet.Capabilities.register_recovery(id,
        name: label,
        preview: &module.preview/2,
        execute: &module.execute/2
      )

    {:ok, id}
  rescue
    error ->
      Logger.warning("Parapet.Recovery.attach/1 skipped #{inspect(module)}: #{Exception.message(error)}")
      :skip
  end
end

def attach(modules) when is_list(modules) do
  registered =
    modules
    |> Enum.filter(&Code.ensure_loaded?/1)
    |> Enum.map(&register_one/1)
    |> Enum.flat_map(fn
      {:ok, id} -> [id]
      :skip -> []
    end)

  {:ok, registered}
end
```

If the per-module-rescue is intentionally NOT wanted (the phase plan deemed
it out of scope), update the moduledoc to drop the "crash-proof" framing and
add an explicit note: "If a registered module's `id/0`, `label/0`, or the
underlying `register_recovery/2` call raises, `attach/1` propagates the
exception and aborts; modules earlier in the list remain registered."

### WR-02: `attach/1` does not verify required callbacks are exported before calling

**File:** `lib/parapet/recovery.ex:91-100`
**Issue:** `Code.ensure_loaded?/1` returns `true` if the module loads — but a
module that does `use Parapet.Recovery` and forgets to implement, say,
`label/0` only produces a **compile-time warning** ("function label/0
required by behaviour Parapet.Recovery is not implemented"), not a
compile-time error. At runtime, `attach/1` calls `module.label()` and crashes
with `UndefinedFunctionError`. Combined with WR-01, this means a host
developer who ignores compiler warnings (or whose CI does not enforce
`--warnings-as-errors`) will get a runtime crash at host-app boot rather
than a friendly skip-and-log.
**Fix:** Add a `function_exported?/3` check for each of the four behaviour
callbacks before invoking them. A module that loads but is missing any
callback should be skipped (with a `Logger.warning`) the same way an unloaded
module is skipped, OR the moduledoc should explicitly document that
`--warnings-as-errors` is required for host CI:

```elixir
|> Enum.filter(&Code.ensure_loaded?/1)
|> Enum.filter(fn module ->
  function_exported?(module, :id, 0) and
    function_exported?(module, :label, 0) and
    function_exported?(module, :preview, 2) and
    function_exported?(module, :execute, 2)
end)
```

### WR-03: `attach/1` element-type guard is missing — non-atom list elements raise `FunctionClauseError`

**File:** `lib/parapet/recovery.ex:87`
**Issue:** The guard `when is_list(modules)` accepts any list, including
`[nil]`, `[123]`, `["MyApp.Recovery"]`. The first non-atom element flows into
`Code.ensure_loaded?/1` (line 90) which has its own atom-only guard and will
raise `FunctionClauseError`, NOT the friendlier `ArgumentError` a host
adopter would expect from a public attach API. This is a likely typo trap:
`Parapet.Recovery.attach(["MyApp.Recovery.RetryAsyncItem"])` (string instead
of module atom) crashes with a stack-trace that points into `Code`, not into
`Parapet.Recovery`.
**Fix:** Either tighten the guard or do an upfront validation pass with a
clear error message:

```elixir
def attach(modules) when is_list(modules) do
  case Enum.find(modules, fn m -> not is_atom(m) end) do
    nil -> :ok
    bad -> raise ArgumentError, "Parapet.Recovery.attach/1 expects a list of module atoms; got #{inspect(bad)}"
  end
  # ... rest unchanged
end
```

### WR-04: `label/0` return value is not validated to be a `String.t()`

**File:** `lib/parapet/recovery.ex:93,97` and `lib/parapet/capabilities.ex:33`
**Issue:** The `@callback label/0 :: String.t()` spec is documentation only —
not enforced at runtime. If a host module's `label/0` returns `nil` (e.g.,
the dev forgot to add the label string and the function defaults to `nil`),
`attach/1` passes `name: nil` to `register_recovery/2`, where
`Keyword.fetch!(attrs, :name)` happily accepts `nil` (because the key IS
present), and `nil` is stored as `cap.name`. Downstream, the Operator UI
will render "nil" as the action's display label — confusing but
non-failing. Worse: any code path that does `<>`/string interpolation on
`cap.name` will crash with `ArgumentError`. Since `name` is documented as
the display string for the Operator UI, validating it at the registration
boundary is cheaper than debugging an Operator UI failure in production.
**Fix:** Add an `is_binary/1` guard in `attach/1` (preferred — the
behaviour-facing boundary) or in `register_recovery/2` (defends all entry
points):

```elixir
# In attach/1:
label = module.label()
unless is_binary(label) do
  raise ArgumentError, "#{inspect(module)}.label/0 must return a String.t(); got #{inspect(label)}"
end
```

## Info

### IN-01: Moduledoc misattributes missing-callback warnings to Dialyzer

**File:** `lib/parapet/recovery.ex:10`
**Issue:** "surface any missing or mis-named callbacks as compile-time
warnings via Dialyzer" — missing `@behaviour` callbacks are surfaced by the
**Elixir compiler itself** (a "function X required by behaviour Y is not
implemented" warning emitted at compile time), not by Dialyzer. Dialyzer
adds *spec*-conformance checking, but the callback-presence check is
compiler-native.
**Fix:** Replace "via Dialyzer" with "at compile time":

```
surface any missing or mis-named callbacks as compile-time warnings.
```

### IN-02: `attach/1` uses `:ok = ...` pattern match instead of explicit return-shape handling

**File:** `lib/parapet/recovery.ex:95-100`
**Issue:** The `:ok = Parapet.Capabilities.register_recovery(...)` line
silently assumes `register_recovery/2` always returns `:ok` for valid ids
(true today — `Agent.update/2` returns `:ok`). If that contract ever
changes (e.g., `register_recovery/2` is updated to return `{:ok,
capability}` or `{:error, :duplicate}` in a future phase), this match will
crash with a confusing `MatchError` rather than a clean error path. Given
`Parapet.Capabilities` is Experimental and may evolve, the brittle match is
worth a comment or an explicit `case`.
**Fix:** Either add a `# Agent.update/2 always returns :ok` comment, or
switch to a `case` that explicitly handles a future `{:error, _}` branch.

### IN-03: Comment references D-14 for fixture-inlining decision, but D-14 covers state isolation

**File:** `test/parapet/recovery_test.exs:1-2`
**Issue:** "inline in the test file per D-14 (no test/support/)" — D-14 in
`24-CONTEXT.md` describes the new async test pattern and migration scope; it
does not directly dictate fixture placement. The decision to inline
fixtures (vs. placing them in `test/support/`) appears to be Claude's
discretion (mentioned as "Pattern 6" in the same comment), not a numbered
decision. Either D-14 should be re-cited correctly or the comment should
say "per Pattern 6" without the D-14 attribution.
**Fix:** Update the comment to `# Pattern 6: inline fixtures (no
test/support/ — see 24-PATTERNS.md)` or similar.

### IN-04: `__using__/1` macro silently ignores options

**File:** `lib/parapet/recovery.ex:59-63`
**Issue:** `defmacro __using__(_opts)` accepts any options keyword list but
does nothing with it. A host that writes
`use Parapet.Recovery, target_kind: :async_item` will compile cleanly with
zero indication that the opts are discarded. Mirrors common Elixir patterns,
but a future v1.2 may want to actually consume options here (per D-07: "If
a future capability needs to opt into `preview_only` or specialize
`target_kind`, that's a v1.2 addition (a new optional `@callback` or a
`__using__/1` option)"). For now, an explicit reject of unknown opts would
prevent silent-discard footguns.
**Fix:** Either accept no opts at all (`defmacro __using__([])`) — which
would surface a `FunctionClauseError` at compile time for any opts — or
guard explicitly:

```elixir
defmacro __using__(opts) do
  unless opts == [] do
    IO.warn("Parapet.Recovery does not accept options in v1.1; got #{inspect(opts)}")
  end

  quote do
    @behaviour Parapet.Recovery
  end
end
```

### IN-05: Async sweep test rebinds outer loop variable inside test body

**File:** `test/parapet/recovery_test.exs:177-181`
**Issue:** The outer `for n <- 1..100 do test "async write #{n} ..."` binds
`n` for the test name interpolation, then inside the test body `n =
unquote(n)` rebinds `n` to the literal value. The rebind is necessary
because outer `n` is no longer in scope inside the generated test function,
but the same identifier reused is mildly confusing for readers. A different
variable name (e.g., `i = unquote(n)`) or a comment would aid future
readers.
**Fix:** Rename the inner binding for clarity:

```elixir
for n <- 1..100 do
  test "async write #{n} is isolated per key" do
    i = unquote(n)
    id = Enum.at(@allowlisted_ids, rem(i, 5))
    name = "async-fixture-#{i}"
    # ...
  end
end
```

---

_Reviewed: 2026-05-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
