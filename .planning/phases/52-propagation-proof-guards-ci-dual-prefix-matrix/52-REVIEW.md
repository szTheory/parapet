---
phase: 52-propagation-proof-guards-ci-dual-prefix-matrix
reviewed: 2026-07-01T01:22:56Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - .github/workflows/ci.yml
  - config/config.exs
  - lib/parapet/evidence.ex
  - lib/parapet/mcp/server.ex
  - lib/parapet/spine/schema.ex
  - priv/parapet/public_api_stable.json
  - test/parapet/evidence_test.exs
  - test/parapet/mcp/server_test.exs
  - test/parapet/schema_prefix_guard_test.exs
  - test/parapet/spine/compiled_prefix_leg_test.exs
  - test/parapet/spine/prefix_propagation_test.exs
  - test/parapet/spine/schema_test.exs
  - test/support/concurrency_bootstrap.ex
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 52: Code Review Report

**Reviewed:** 2026-07-01T01:22:56Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Phase 52 delivers dual-prefix CI matrix support (parapet / public schema legs), compile-time prefix propagation proofs (PROP-01/PROP-02/PROP-03), and the `schema_prefix/0` public API function. The architecture is sound — the single-normalization-source pattern, the PROP-02 static guard, and the `CompiledPrefixLegTest` tripwire are well-designed. However, two blockers were found that will cause the public CI leg to fail, and three warning-level issues weaken test isolation and maintainability.

---

## Critical Issues

### CR-01: `schema_test.exs` hardcodes `"parapet"` in eight assertions that run unconditionally on both CI legs

**File:** `test/parapet/spine/schema_test.exs:83-103, 126, 157`

**Issue:** Eight test assertions directly assert `== "parapet"` with no compile-time guard. These tests run on every matrix leg, including the `schema_prefix: 'public'` leg (OTP 28.x only). On that leg `PARAPET_SCHEMA_PREFIX=public` normalizes to `nil`, so `Incident.__schema__(:prefix)` is `nil`, `Schema.__prefix__()` is `nil`, and all eight assertions fail immediately with `assert nil == "parapet"`.

The affected assertions are:
- Lines 83, 87, 91, 95, 99, 103 — six individual `__schema__(:prefix) == "parapet"` tests in `"compiled prefix across six spine schemas"`
- Line 126 — `"__prefix__/0 returns \"parapet\" under the default config"` inside `"resolver legacy-nil cases"`
- Line 157 — `"unset env normalizes toward \"parapet\" default"` inside `"WR-02 normalization asymmetry"`

The cross-leg equality test at line 108 (`"all six schemas carry the same __schema__(:prefix)"`) is correctly written using `Schema.__prefix__()` as the expected value and will pass on both legs. The individually pinned tests are the defect.

**Fix:** Gate the parapet-specific assertions with a compile-time module attribute, matching the pattern already used correctly in `compiled_prefix_leg_test.exs` and `prefix_propagation_test.exs`:

```elixir
# At module top
@compiled_prefix Parapet.Spine.Schema.__prefix__()

# Replace all eight hardcoded assertions with:
test "Incident.__schema__(:prefix) matches compiled prefix" do
  assert Incident.__schema__(:prefix) == @compiled_prefix
end

# For the "absence = default" pinned contract test (line 157), add a guard:
if @compiled_prefix == "parapet" do
  test "unset env normalizes toward 'parapet' default" do
    assert Parapet.Spine.Schema.__prefix__() == "parapet"
  end
end
```

Alternatively, tag the six individual schema tests with `@tag :parapet_leg_only` and exclude them on the public leg via `ExUnit.configure(exclude: [:parapet_leg_only])` when `PARAPET_SCHEMA_PREFIX` normalizes to `nil`.

---

### CR-02: `server_test.exs` Test 3 leaks `:RunbookAlert` into global ETS — cleanup is a no-op

**File:** `test/parapet/mcp/server_test.exs:77-93`

**Issue:** Test 3 calls `apply(Parapet.SLO, :define, [:RunbookAlert, [...]])`, which writes to `Parapet.SLO.Registry` (an ETS-backed GenServer). The cleanup block at lines 91–93 does:

```elixir
Application.put_env(
  :parapet,
  :slos,
  Enum.reject(Parapet.SLO.all(), &(&1.name == :RunbookAlert))
)
```

This is a complete no-op: `Parapet.SLO.all/0` reads from ETS (via `Parapet.SLO.Registry.all/0`), not from `Application.get_env(:parapet, :slos)`. Writing to Application env has no effect on the ETS store.

Furthermore, because `server_test.exs` never calls `Parapet.SLO.Registry.checkout()`, the `store/1` call uses the `{:global, :slo, :RunbookAlert}` ETS key (not a per-test-pid scoped key). The `handle_info({:DOWN, ...})` handler in Registry only purges `{:test, pid, :_}` keys — it does not purge `:global` keys on process exit. So `:RunbookAlert` persists in the global ETS store for the remainder of the entire test run, polluting any test that queries `SLO.all()`.

**Fix:** Add `Parapet.SLO.Registry.checkout()` to the `setup` block and replace the broken Application.put_env cleanup with `Parapet.SLO.Registry.clear()`:

```elixir
setup do
  Parapet.SLO.Registry.checkout()  # scope all SLO mutations to this test process
  Application.put_env(:parapet, :repo, DummyRepo)
  Application.put_env(:parapet, :prometheus_client, DummyPrometheusClient)

  on_exit(fn ->
    Application.delete_env(:parapet, :repo)
    Application.delete_env(:parapet, :prometheus_client)
  end)

  :ok
end
```

When `checkout()` is active, `store/1` uses `{:test, pid, :slo, name}` keys that are automatically purged by the `{:DOWN, ...}` monitor when the test process exits. The explicit `Application.put_env` cleanup block at lines 91–93 should be removed entirely.

---

## Warnings

### WR-01: `audit_mode` application env not cleaned up after `:dual_write` tests — state bleeds between test cases

**File:** `test/parapet/evidence_test.exs:171, 239`

**Issue:** Two test cases set `Application.put_env(:parapet, :audit_mode, :dual_write)` without registering an `on_exit` callback to delete it:

- Line 171: `"logs a tool audit to DB and emits telemetry in :dual_write mode (default)"`
- Line 239: `"inserts TimelineEntry and ToolAudit, and emits telemetry in :dual_write mode"`

The `:threadline_deferred` tests immediately following each do register cleanup (lines 187, 268), but the `:dual_write` tests do not. If ExUnit's test randomization (`--seed`) reorders the `:dual_write` test to run last within the describe block, the next describe block inherits the `:dual_write` env value. Since the module uses `async: false` this is non-racy, but it is fragile on seed changes.

**Fix:** Add `on_exit` cleanup to both locations:

```elixir
# Line 171 (and 239 analogously)
Application.put_env(:parapet, :audit_mode, :dual_write)
on_exit(fn -> Application.delete_env(:parapet, :audit_mode) end)
```

---

### WR-02: `schema_prefix/0` annotated `@doc since: "1.7.0"` but ships in v1.0.3 and is declared stable in `public_api_stable.json`

**File:** `lib/parapet/evidence.ex:28`, `priv/parapet/public_api_stable.json:46`

**Issue:** `schema_prefix/0` carries `@doc since: "1.7.0"` (line 28) but the project is at version 1.0.3 (`mix.exs:5`). The same function is already listed in `public_api_stable.json` under `Parapet.Evidence` with `"tier": "stable"`. This creates a contractual conflict: the stable manifest says the function is part of the current public API, but the `@since` annotation implies it does not exist until v1.7.0. `ExDoc` renders the `@since` annotation visibly in generated documentation — adopters reading the docs for v1.0.3 will see "Available since 1.7.0" on a function they can already call, which is misleading and may cause adopters to believe the function is unavailable.

**Fix:** Correct the `@doc since:` annotation to reflect the version in which `schema_prefix/0` actually ships:

```elixir
@doc since: "1.0.3"   # or the exact patch that introduced it
```

If the intent was to forward-declare the function for a future 1.7.0 milestone, remove it from `public_api_stable.json` until 1.7.0 ships.

---

### WR-03: Lint job `_build` cache restore-key is a prefix of test-job keys — lint may inherit a schema-specific compiled artifact

**File:** `.github/workflows/ci.yml:35-36`

**Issue:** The lint job's `_build` cache restore-key is:
```
${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-
```

The test job's primary cache key is:
```
${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-${{ matrix.schema_prefix }}-${{ hashFiles('**/mix.lock') }}
```

GitHub Actions cache prefix-matches restore-keys. If the lint job's primary cache key misses (common on a new lock-file hash), its restore-key `Linux-build-1.19.0-28.x-` will match the test job's `Linux-build-1.19.0-28.x-parapet-<hash>` or `Linux-build-1.19.0-28.x-public-<hash>` cache entry — restoring a `_build` directory compiled with a specific `PARAPET_SCHEMA_PREFIX`. The lint job does not set `PARAPET_SCHEMA_PREFIX` and does not run `mix compile --force`, only `mix compile --warnings-as-errors` (incremental). Elixir's compile-env boot-check will detect the mismatch and force recompilation of affected modules, so this does not produce a silent false-positive, but it adds unexpected recompilation latency.

**Fix:** Add `schema_prefix` (or a fixed placeholder) to the lint job's `_build` cache key to prevent cross-restoration:

```yaml
# In the lint job's Cache _build step:
key: ${{ runner.os }}-build-lint-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
restore-keys: ${{ runner.os }}-build-lint-${{ matrix.elixir }}-${{ matrix.otp }}-
```

The `lint` infix in the key isolates it from test-leg caches entirely.

---

### WR-04: `strip_trailing_comment` regex produces false negatives for PROP-02 pattern (d)

**File:** `test/parapet/schema_prefix_guard_test.exs:73-77`

**Issue:** The comment-stripping regex is `~r/^([^#"]*)/` — it stops at the first `"` OR `#` character. For pattern (d), the guard looks for `fragment(.*parapet_`. A line of the form:

```elixir
fragment("parapet_incidents.id = ?", incident.id)
```

is stripped to `fragment(` before the pattern check fires (the `"` before `parapet_` terminates the match). Pattern (d) therefore can never detect a `fragment(` violation when the raw SQL string is quoted with double-quotes (the overwhelming common case). The guard will silently pass on exactly the violations it was designed to catch.

**Fix:** The comment-stripper should strip only `#` comments, not string content. The simplest safe fix is to remove the `"` from the character class, accepting that a comment inside a string literal might not be stripped (a non-issue for the four specific patterns being guarded):

```elixir
defp strip_trailing_comment(line) do
  case Regex.run(~r/^([^#]*)/, line) do
    [_, before_hash] -> before_hash
    _ -> line
  end
end
```

Alternatively, restrict the strip to only handle the `# comment` case at end-of-line where the hash follows a space:

```elixir
defp strip_trailing_comment(line) do
  String.replace(line, ~r/\s+#.*$/, "")
end
```

Either fix allows pattern (d) to see the full content of string literals before the `#` stripping occurs.

---

## Info

### IN-01: Redundant inner `if @prefix` guard is unreachable dead code

**File:** `test/parapet/spine/prefix_propagation_test.exs:35-37`

**Issue:** The `refute sql =~ ...` check on line 36 is nested inside `if @prefix do` at line 35, which is itself nested inside `if @prefix do` at line 26. Since both guards check the same compile-time module attribute, the inner guard is always `true` when reached and contributes no additional safety. It is dead code that adds noise.

**Fix:** Remove the redundant inner guard — the `refute` can be placed directly in the outer `if @prefix do` block:

```elixir
if @prefix do
  assert sql =~ ~s("#{@prefix}"."parapet_timeline_entries"), ...
  assert sql =~ ~s("#{@prefix}"."parapet_incidents"), ...
  refute sql =~ ~r/(?<!"parapet")\.parapet_incidents/, ...
else
  refute sql =~ ~s("parapet"."parapet_), ...
end
```

---

### IN-02: `resolve_action_item/1` (stable public API) has no test coverage in `evidence_test.exs`

**File:** `test/parapet/evidence_test.exs`, `priv/parapet/public_api_stable.json:43`

**Issue:** `resolve_action_item/1` is listed in `public_api_stable.json` and is a stable API function. It is not tested anywhere in `evidence_test.exs`. `DummyRepo` has no `update_all/2` implementation, so any future test that calls this path would crash immediately with an `UndefinedFunctionError`. The function's two-clause design (keyword list vs direct ID) is also untested.

**Fix:** Add `DummyRepo.update_all/2` and tests covering both call shapes:

```elixir
# In DummyRepo
def update_all(query, updates) do
  send(self(), {:dummy_repo_update_all, updates})
  {1, nil}
end

# Tests
describe "resolve_action_item/1" do
  test "resolves by id" do
    id = Ecto.UUID.generate()
    assert {1, nil} = Parapet.Evidence.resolve_action_item(id)
    assert_receive {:dummy_repo_update_all, [set: [state: "resolved"]]}
  end

  test "resolves by criteria list" do
    assert {1, nil} = Parapet.Evidence.resolve_action_item([external_id: "ext-1"])
    assert_receive {:dummy_repo_update_all, [set: [state: "resolved"]]}
  end
end
```

---

_Reviewed: 2026-07-01T01:22:56Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
