---
phase: 16-slo-starter-packs-low-traffic-guardrails
reviewed: 2026-05-24T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - lib/parapet/slo/starter_pack/web_saas.ex
  - lib/parapet/slo/starter_pack/delivery_saas.ex
  - test/parapet/slo/starter_pack/web_saas_test.exs
  - test/parapet/slo/starter_pack/delivery_saas_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2026-05-24
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four files reviewed: two new `Parapet.SLO.Provider` behaviour modules (`WebSaaS`, `DeliverySaaS`) and their ExUnit test suites. The implementation is largely sound. Metric names (`parapet_http_request_count`, `parapet_journey_login_count`, `parapet_oban_jobs_total`) are verified against their emitting modules. Label keys (`status_class`, `outcome`, `state`, `queue`, `integration`, `method`) are all low-cardinality and pass `LabelPolicy.assert_safe!/1`. All three `WebSaaS` slices have non-zero `min_total_rate` (the default `0.01`). The `Code.ensure_loaded?/1` runtime guard in `DeliverySaaS` is correctly placed at the function body level, satisfying the no-compile-guard requirement. The `selector/3` rendering path in `Parapet.Metrics.AsyncDelivery` handles both string metric names and Keyword matcher lists correctly.

Two warnings and two info items follow.

## Warnings

### WR-01: Absent-branch coverage is on the test seam, not on `slos/0` itself

**File:** `test/parapet/slo/starter_pack/delivery_saas_test.exs:64-72`

**Issue:** Every absent-branch test calls the `@doc false` helper `delivery_slices/2` with guaranteed-absent atoms, not the public `slos/0`. The public `slos/0` hardcodes `delivery_slices(Mailglass, Chimeway)` (line 51 of `delivery_saas.ex`). If `slos/0` were ever refactored to stop delegating to `delivery_slices/2` — or if it were accidentally changed to call the delivery libraries directly without the `Code.ensure_loaded?` guard — all absent-branch tests would still pass while the production path silently broke.

There is no test that calls `slos/0` and asserts it produces exactly 3 slices (WebSaaS only) when the host libraries are absent. The existing "all 10 slices" test proves the present-branch of `slos/0`, but the absent-branch of `slos/0` is unobserved.

**Fix:** Add a test that patches the module atom arguments from outside to verify `slos/0` itself behaves correctly under absence. One approach is a narrow integration assertion: because `slos/0` is inlined and cannot be easily injected, the simplest safe guard is a compile-time assertion that `slos/0` calls `delivery_slices/2`:

```elixir
# In delivery_saas_test.exs — add to the existing test module
test "slos/0 delegates to delivery_slices/2 (refactor guard)" do
  # Verify the public slos/0 result equals what delivery_slices would produce
  # when both Mailglass and Chimeway are loaded (test env).
  expected =
    WebSaaS.slos() ++
      DeliverySaaS.delivery_slices(Mailglass, Chimeway)

  assert DeliverySaaS.slos() == expected
end
```

This test breaks the moment `slos/0` stops delegating to `delivery_slices/2`, making future refactors safe.

---

### WR-02: Registration test silently clobbers the pre-existing `:providers` value instead of restoring it

**File:** `test/parapet/slo/starter_pack/web_saas_test.exs:88-101`

**Issue:** `WebSaaSRegistrationTest` mutates the global application environment with `Application.put_env(:parapet, :providers, [WebSaaS])` (line 89) but the `on_exit/1` callback unconditionally resets `:providers` to `[]` (line 93) rather than restoring the value that was present before the test ran. If any prior `async: false` test left `:providers` in a non-empty state (for example due to a missing `on_exit` in that other test), this test will appear to pass but will permanently reset state that another test may have relied on, causing ordering-dependent failures.

Additionally, the `on_exit` clears `:slos` (line 92) even though this test never writes to `:slos`. The `Generator.provider_artifacts()` call goes through `SLO.provider_catalog/0` which reads `:providers`, not `:slos`. The `:slos` reset is harmless but cargo-culted from the `slo_test.exs` pattern, and silently resets legacy SLO state that no test in this file created.

**Fix:** Capture the original values before mutation and restore them precisely:

```elixir
test "registering WebSaaS as provider generates alerts with denominator guard and recording rules" do
  original_providers = Application.get_env(:parapet, :providers, [])
  Application.put_env(:parapet, :providers, [WebSaaS])

  on_exit(fn ->
    Application.put_env(:parapet, :providers, original_providers)
  end)

  artifacts = Generator.provider_artifacts()

  assert artifacts.alerts =~ "> 0.01"
  assert artifacts.recording_rules =~ "web_saas_http_availability"
end
```

## Info

### IN-01: `delivery_slices/2` is a public function marked `@doc false` — leaks into public API

**File:** `lib/parapet/slo/starter_pack/delivery_saas.ex:54-71`

**Issue:** `delivery_slices/2` is intentionally exposed as a public function (no `defp`) to serve as a test seam for injecting absent module atoms. It is marked `@doc false` to suppress HexDocs output, but it remains callable by any user of the library and will appear in `__info__(:functions)`. This is a deliberate design choice to enable testability without module unloading, but it expands the public API surface of a module that is intended to be a simple `slos/0` provider.

**Fix:** Document the intent explicitly, or consider an alternative test strategy that does not require exposing the helper. If the seam must remain public, add a `@moduledoc` note or inline comment explaining the stability guarantee (or lack thereof):

```elixir
# Public only to enable absent-host-library testing via delivery_slices/2.
# Not part of the stable public API; may be removed in a future major version.
@doc false
def delivery_slices(mailglass_mod, chimeway_mod) do
```

---

### IN-02: Oban `total_matchers` silently excludes the `"unknown"` state, potentially undercounting the denominator

**File:** `lib/parapet/slo/starter_pack/web_saas.ex:102`

**Issue:** `total_matchers: [state: ["success", "failure", "cancelled", "discarded"]]` generates a Prometheus selector `state=~"success|failure|cancelled|discarded"`. The `Parapet.Metrics.Oban` handler (line 71 of `metrics/oban.ex`) emits `state: to_string(Map.get(metadata, :state, "unknown"))`. If Oban emits a job event with an unexpected state atom (e.g., `:retried`, `:scheduled`, or any future Oban state), the handler maps it to `"unknown"` and it falls outside the total matcher. The SLO denominator is then undercounted, causing the error ratio to be artificially inflated, which can produce false-positive alerts.

This is a bounded risk given Oban's well-known state machine, but the documented states (`"success"`, `"failure"`, `"cancelled"`, `"discarded"`) may not cover all states Oban actually emits at the `[:oban, :job, :stop]` and `[:oban, :job, :exception]` events in all Oban versions.

**Fix:** Either widen the total_matchers to be unconditional (no state filter on the denominator), or add a note in the `@moduledoc` that users should verify the Oban state set matches their Oban version:

```elixir
# Option A: remove state filter from total to count all jobs
total_matchers: [],

# Option B: document the assumption
# NOTE: "success", "failure", "cancelled", "discarded" are the terminal states
# emitted by Parapet's Oban handler. Verify against your Oban version.
total_matchers: [state: ["success", "failure", "cancelled", "discarded"]],
```

---

_Reviewed: 2026-05-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
