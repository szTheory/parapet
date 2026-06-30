---
phase: 51-prefix-core-test-seam
reviewed: 2026-06-30T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - config/config.exs
  - lib/parapet/evidence.ex
  - lib/parapet/spine/action_claim.ex
  - lib/parapet/spine/action_item.ex
  - lib/parapet/spine/incident.ex
  - lib/parapet/spine/schema.ex
  - lib/parapet/spine/system_event.ex
  - lib/parapet/spine/timeline_entry.ex
  - lib/parapet/spine/tool_audit.ex
  - test/parapet/evidence_test.exs
  - test/parapet/spine/schema_test.exs
  - test/support/concurrency_bootstrap.ex
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 51: Code Review Report

**Reviewed:** 2026-06-30T00:00:00Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

This phase introduces a compile-time `@schema_prefix` seam via the `Parapet.Spine.Schema`
base macro, an env-driven `config/config.exs` normalizer, a runtime `Evidence.schema_prefix/0`
mirror, and prefix-qualified DDL in the concurrency test bootstrap. The schema refactor (six
modules switching from `use Ecto.Schema` to `use Parapet.Spine.Schema`) is clean and correct —
the macro faithfully reproduces the prior `@primary_key`/`@foreign_key_type`/`import Ecto.Changeset`
boilerplate it replaces.

No BLOCKER-tier defects were found. However, the central safety mechanism of this phase — the
"D-05 normalization agreement test" — does **not** exercise the production code it is meant to
guard, and the runtime/compile-time prefix split is genuinely two-sourced in a way that can
diverge silently in production while every test stays green. These are the highest-value findings
below. The raw-SQL identifier interpolation in the bootstrap and the atom-`:public` asymmetry are
secondary robustness concerns.

Note: per the phase brief, the *physical duplication* of the normalization rule between
`config/config.exs` and `Schema.__prefix__/0` is by design and is NOT flagged. The findings below
concern the *effectiveness of the guard* against that duplication and *other* defects, not the
duplication itself.

## Warnings

### WR-01: The D-05 "agreement test" validates test-local mirror copies, not the production normalizers

**File:** `test/parapet/spine/schema_test.exs:91-107` (with helpers at `116-128`)
**Issue:** The agreement test is described as "the only guard against silent drift" between the
two production normalization copies (`config/config.exs:20-26` and `Parapet.Spine.Schema` at
`schema.ex:40-44`). But the test does not call either production path. It compares two **private
helper functions defined inside the test module** — `normalize_prefix/1` (schema_test.exs:117-119)
and `config_normalize_prefix/1` (schema_test.exs:124-128) — which are hand-copied mirrors of the
production logic. If a future edit changes `config/config.exs` or `Schema.__prefix__/0` but does
not also change the corresponding test mirror, the production copies will drift while this test
stays green. The guard cannot detect the exact failure mode it claims to prevent.
**Fix:** Drive the test from the real code. `Schema.__prefix__/0` is already public; assert the
runtime mirror `Evidence.schema_prefix/0` against it for each input via `Application.put_env`, and
for the compile-time/config copy, extract the shared normalization into a single pure function
(e.g. `Parapet.Spine.Schema.normalize/1`) that both `config.exs` and the macro call — config can
`Code.require_file` or the function can live in a tiny module compiled before config runs. At
minimum, exercise `Evidence.schema_prefix/0` (the real runtime copy) in the agreement assertion
instead of the local `normalize_prefix/1` mirror:
```elixir
test "runtime mirror matches resolver for canonical inputs" do
  for {input, expected} <- Enum.zip(@input_set, @expected) do
    Application.put_env(:parapet, :schema_prefix, input)
    assert Parapet.Evidence.schema_prefix() == expected
  end
after
  Application.delete_env(:parapet, :schema_prefix)
end
```

### WR-02: `nil` input is normalized inconsistently across the three real copies, and the test mirror hides it

**File:** `config/config.exs:21-26`, `lib/parapet/spine/schema.ex:40-44`, `lib/parapet/evidence.ex:43-47`
**Issue:** The three production normalizers disagree on the meaning of `nil`:
- `config/config.exs` maps **unset env (`nil`) → `"parapet"`** (the default install lands in the
  parapet schema).
- `Schema.__prefix__/0` and `Evidence.schema_prefix/0` map **`nil` → `nil`** (unprefixed), because
  `nil` matches the `p in [nil, "", "public"]` clause.

So an explicit `config :parapet, schema_prefix: nil` in a host app produces an *unprefixed* schema,
while leaving `PARAPET_SCHEMA_PREFIX` unset produces the `"parapet"` schema. That asymmetry is
defensible, but it is exactly the kind of subtlety the agreement test should pin down — and it
does not, because the test mirror `config_normalize_prefix(nil)` returns `nil` (schema_test.exs:124),
modeling the *post-default* value rather than the raw config-input value. The canonical input set
`["parapet","","public",nil,"custom"]` therefore never tests the divergent `nil → "parapet"` vs
`nil → nil` behavior that actually exists between the config copy and the resolver copy.
**Fix:** Document the asymmetry explicitly at all three sites, and add a dedicated assertion that
nails it down end to end: unset env yields `"parapet"` from the resolved app env, while explicit
`nil` config yields `nil` from `Evidence.schema_prefix/0`. Treat "unset" and "explicit nil" as
distinct inputs in the agreement matrix rather than collapsing both to `nil` in the mirror.

### WR-03: Runtime `Evidence.schema_prefix/0` reads mutable app env while schemas are frozen at compile time — silent split-brain

**File:** `lib/parapet/evidence.ex:42-48`
**Issue:** `Evidence.schema_prefix/0` reads `Application.get_env(:parapet, :schema_prefix, "parapet")`
at call time, whereas every spine schema bakes `@schema_prefix` at **compile time** via
`Application.compile_env`. If a host app (or a test) sets `config :parapet, schema_prefix: "x"` at
runtime *after* the library was compiled with a different value, `Evidence.schema_prefix/0` returns
`"x"` while the schemas still read/write to the compile-time schema. The module doc (lines 32-40)
asserts "Both must agree" and defers verification to a "Phase-54 doctor check," but nothing in this
phase prevents the divergence, and a generator or introspection caller trusting this helper would
emit DDL/queries for the wrong schema. The evidence_test.exs `schema_prefix/0` block
(lines 201-231) actively demonstrates the helper changing answer based on `Application.put_env`,
confirming the runtime mutability.
**Fix:** Make the runtime mirror authoritative against the compile-time value rather than re-reading
mutable env. Have `Evidence.schema_prefix/0` delegate to the frozen compile-time resolver
(`Parapet.Spine.Schema.__prefix__/0`) so it cannot diverge by construction:
```elixir
def schema_prefix, do: Parapet.Spine.Schema.__prefix__()
```
If a true runtime read is required for the generator use case, add an explicit guard that raises
(or logs) when the runtime value disagrees with `Parapet.Spine.Schema.__prefix__/0`, instead of
silently returning the mismatched runtime value.

### WR-04: Schema prefix is interpolated into raw DDL identifiers without quoting/validation

**File:** `test/support/concurrency_bootstrap.ex:28, 50-54`
**Issue:** `@prefix` is interpolated directly into SQL identifier positions:
`SQL.query!(ConcurrencyRepo, ~s(CREATE SCHEMA IF NOT EXISTS "#{@prefix}"), [])` (line 28) and
`~s("#{@prefix}"."#{table}")` (line 51). A prefix value containing a double-quote (e.g.
`pa"rapet`) breaks out of the quoted identifier and yields malformed or injectable DDL. The value
originates from `PARAPET_SCHEMA_PREFIX` at compile time, so the exposure is limited to
build-environment control rather than request-time input, and this is test-support code — hence
WARNING rather than BLOCKER. But the same interpolation pattern is the template the production
migration generator will likely follow, so the unsafe habit should be corrected at the source.
**Fix:** Validate the prefix against a strict identifier allowlist at resolution time (e.g.
`^[a-z_][a-z0-9_]*$`) and reject anything else with a clear compile-time error, or escape embedded
quotes by doubling them before interpolation. Centralize this so both the bootstrap and any future
generator share one safe quoting function:
```elixir
defp safe_ident!(name) do
  unless name =~ ~r/\A[a-z_][a-z0-9_]*\z/, do: raise ArgumentError, "unsafe schema prefix: #{inspect(name)}"
  name
end
```

## Info

### IN-01: Atom `:public` and string `"public"` normalize to different prefixes

**File:** `lib/parapet/spine/schema.ex:40-44`, `lib/parapet/evidence.ex:43-47`
**Issue:** The guard `p when p in [nil, "", "public"] -> nil` matches the *string* `"public"` but
not the *atom* `:public`. An atom `:public` falls through to the `is_atom` clause and becomes the
literal prefix `"public"` (not `nil`). So `config :parapet, schema_prefix: :public` would create a
`public`-named prefix rather than the intended unprefixed/legacy behavior — the opposite of what a
reader expects given that string `"public"` means "unprefixed." Both production copies agree with
each other here, so it is not a drift bug, but it is a latent footgun.
**Fix:** Normalize atoms to strings *before* the membership check so `:public` and `:""`-style
atoms collapse the same way, or document explicitly that only string/`nil` forms are supported and
atoms other than via `Atom.to_string` are unsupported.

### IN-02: `__prefix__/0` exposed as a "private" `@doc false` function but used as the public compile-time contract

**File:** `lib/parapet/spine/schema.ex:46-61`
**Issue:** `__prefix__/0` is marked `@doc false` (treated as internal), yet it is the single source
of truth invoked from the `__using__` macro (line 53) and is the function WR-01/WR-03 recommend the
tests and runtime mirror delegate to. Its `@doc false` status understates its role and discourages
the very cross-references that would make the agreement guard real.
**Fix:** Keep `@doc false` if it must stay out of published docs, but add an internal `@moduledoc`
note marking it as the canonical resolver other components must delegate to, and reference it from
`Evidence.schema_prefix/0`'s docstring rather than re-implementing the normalization.

### IN-03: Bootstrap `reset!/0` truncates only the six known tables but `bootstrap!/0` may create them in a non-default schema — TRUNCATE relies on search_path

**File:** `test/support/concurrency_bootstrap.ex:34-42`
**Issue:** `reset!/0` qualifies tables via `q/1`, so it is consistent with `bootstrap!/0`. That is
correct. The minor concern is robustness: `reset!/0` hard-codes the six table names in `@tables`
(lines 17-24) independently of the DDL list in `ddl_statements/0` (lines 63-194). If a seventh
spine table is added to the DDL but not to `@tables`, `reset!/0` will silently leave it untruncated
between concurrency tests, producing cross-test state bleed that is hard to diagnose.
**Fix:** Derive the truncate set from a single canonical table list shared with the DDL generation,
or add a compile-time assertion that every `CREATE TABLE` target in `ddl_statements/0` appears in
`@tables`.

---

_Reviewed: 2026-06-30T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
