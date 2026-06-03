---
phase: 19-api-telemetry-freeze
fixed_at: 2026-05-25T09:30:00Z
review_path: .planning/phases/19-api-telemetry-freeze/19-REVIEW.md
iteration: 1
findings_in_scope: 10
fixed: 10
skipped: 0
status: all_fixed
---

# Phase 19: Code Review Fix Report

**Fixed at:** 2026-05-25T09:30:00Z
**Source review:** .planning/phases/19-api-telemetry-freeze/19-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 10 (WR-01..WR-06, IN-01..IN-04 — fix_scope was "all")
- Fixed: 10
- Skipped: 0

**Verification:** Full suite `mix test` passes (352 tests, 0 failures — one new
test added by IN-04) and `mix verify.public_api` exits 0 against the final tree.
Each fix was verified individually (targeted test run / compile / verify task)
before its atomic commit.

## Fixed Issues

### WR-01: Telemetry contract test does not enforce its central claim (no coupling to emit sites)

**Files modified:** `test/telemetry_contract_test.exs`
**Commit:** b47938e
**Applied fix:** Chose option (a) from the review — corrected the misleading
header comment to state the truth: the fixture is a MANUAL snapshot with no
coupling to the `:telemetry.execute/span/event_name` call sites in `lib/`, and
must be updated by hand when emit families change. Deliberately did NOT implement
option (b) (regex-scan-of-source drift detector): the reviewer themselves flagged
it as fragile and noted the durable fix is a shared source-of-truth registry,
which is a larger design change out of scope for a review-fix pass. The comment
now points future maintainers at that durable fix.

### WR-02: "measurement key contract" describe block is tautological

**Files modified:** `test/telemetry_contract_test.exs`
**Commit:** 2fe0a6d
**Applied fix:** Replaced the tautological `Map.has_key?(@documented_measurements,
@family)` assertion (which iterated the map and asserted membership in that same
map) with an exact-value comparison: `Enum.sort(@documented_measurements[@family])
== Enum.sort(@expected_keys)`, binding the fixture value per family in the `for`
comprehension. Now a renamed/removed measurement key in the fixture is caught.
Also rewrote the misleading inline comment.

### WR-03: `@moduledoc false` public-namespace modules misreported as missing docs and halt the build

**Files modified:** `lib/mix/tasks/verify.public_api.ex`
**Commit:** 50397de
**Applied fix:** Changed the `missing_docs` filter from `not m.has_docs` to
`not m.has_docs and m.tier != :internal`, so modules marked `@moduledoc false`
(mapped to the `:internal` tier by `check_module/1`) are treated as an intentional
exclusion rather than a documentation omission that halts the build. Confirmed
`:internal` is distinct from `:unclassified`, so the unclassified-tier halt is
unaffected.
**Note:** Logic change to the API-freeze gate; verified `mix verify.public_api`
still exits 0 and the task tests pass. No current public module uses
`@moduledoc false`, so behavior is unchanged for the current tree.

### WR-04: Tier detection by substring is brittle and can silently misclassify

**Files modified:** `lib/mix/tasks/verify.public_api.ex`
**Commit:** f6407cd
**Applied fix:** Replaced the two independent `String.contains?` checks in
`detect_tier_from_text/1` with anchored regexes
(`~r/####\s+Stable\s*\{:\s*\.info\}/` and
`~r/####\s+Experimental\s*\{:\s*\.warning\}/`) so the tier keyword and its
admonition class must co-occur in the same callout line. Verified the anchored
patterns match all real callout formats in `lib/` (including the indented
`> #### Experimental {: .warning}` in `automation/executor.ex`), that
`mix verify.public_api` still classifies every module correctly and exits 0, and
that the 7 existing `detect_tier_from_text/1` unit tests pass.
**Status: requires human verification** — this changes the classification logic of
an authoritative API-freeze gate. The fix is verified at the syntax/test level,
but a human should confirm the anchored-regex semantics match the intended
admonition grammar for any future moduledoc styles.

### WR-05: STAB-06 deprecation test relies on compiler warning timing not guaranteed stable across runs

**Files modified:** `test/parapet/slo_test.exs`
**Commit:** 0408670
**Applied fix:** Both hardening steps from the review: (1) generate a unique probe
module name per run via `System.unique_integer([:positive])` to avoid
"redefining module" warnings polluting captured stderr; (2) assert on the stable
`@deprecated` message we control (`"Use a Parapet.SLO.Provider module instead"`)
instead of the compiler-generated "deprecated" prefix whose format varies across
Elixir versions. The single message assertion also covers the replacement-name
check, so the old two-assertion pair was consolidated.

### WR-06: `provider_catalog`/`all` test invokes real adapter side effects without isolating them

**Files modified:** `test/parapet/slo_test.exs`
**Commit:** 3e9ee7d
**Applied fix:** Added an `on_exit` that detaches the three concrete telemetry
handler ids the adapters register (`parapet-mailglass-delivery`,
`parapet-chimeway-delivery-events`, `parapet-rindle-async`, confirmed by reading
each adapter's `@handler_id`). Chose targeted detach by exact id over the
review's broader "any id starting with parapet" sweep, to avoid removing handlers
that other suites intentionally attach. The leaked global telemetry state is now
restored after the test.

### IN-01: Inconsistent invocation of deprecated `SLO.define/2` across tests

**Files modified:** `test/parapet/slo_test.exs`
**Commit:** d04428b
**Applied fix:** Converted the two direct `SLO.define(...)` call sites (the
"creates a valid SLO" and "merges legacy environment state" tests) to
`apply(SLO, :define, [...])`, matching the existing pattern in the
"raises ArgumentError" test, and added a describe-level comment documenting why.
Verified with `mix test --warnings-as-errors`: the file now compiles cleanly with
no deprecation warnings while still exercising the legacy path. The deprecation
warning itself remains asserted by the dedicated STAB-06 test.

### IN-02: Moduledoc and code disagree on the exclusion-substring semantics

**Files modified:** `lib/mix/tasks/verify.public_api.ex`
**Commit:** 3fefc1a
**Applied fix:** Updated the `@moduledoc` from "containing `.Resolvable.`" to
"containing `.Resolvable`" (matching the code at line 72), and added a note that
this also catches the terminal protocol module `Parapet.SLO.Resolvable` and its
`defimpl` dispatch modules.

### IN-03: Manifest output channel branching (Jason vs inspect) produces incomparable artifacts

**Files modified:** `lib/mix/tasks/verify.public_api.ex`
**Commit:** cbec746
**Applied fix:** Removed the `inspect/2` fallback. The task now always emits
canonical pretty JSON, and halts with an actionable error
("Add {:jason, ...} to your deps") when Jason is unavailable, instead of silently
degrading to a second non-interchangeable format. Verified Jason is resolvable in
this environment (transitively, via igniter/req/credo), so the verify task still
produces JSON and exits 0. Chose "fail loudly" (the review's recommendation) over
making Jason a hard dependency, since Jason is not a declared direct dep in
`mix.exs` and a hard requirement could regress minimal downstream installs — the
loud error keeps the canonical-format guarantee without that risk.

### IN-04: `event_name/1` clause-coverage not asserted in the contract test

**Files modified:** `test/telemetry_contract_test.exs`
**Commit:** c0d08f8
**Applied fix:** Added a round-trip test in the "event family contract" describe
block that iterates `AsyncDelivery.event_families/0`, destructures each entry as
`[_, _, family] = full`, and asserts `AsyncDelivery.event_name(family) == full`.
Confirmed the destructuring binds `family` to the family atom (e.g. `:outbound`),
which is exactly what `event_name/1`'s guards expect, so the round-trip is
correct. Catches drift between `event_families/0` and the `event_name/1` clauses.

## Skipped Issues

None — all 10 in-scope findings were fixed.

---

_Fixed: 2026-05-25T09:30:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
