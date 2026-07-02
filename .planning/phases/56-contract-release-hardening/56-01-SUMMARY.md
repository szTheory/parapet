---
phase: 56-contract-release-hardening
plan: 01
subsystem: testing
tags: [telemetry, ecto, metrics, prometheus, postgres, schema-prefix]

requires:
  - phase: 52-propagation-proof-guards-ci-dual-prefix-matrix
    provides: "prefix propagation proof; __schema__(:prefix) equality assertions"
  - phase: 51-prefix-core-test-seam
    provides: "Parapet.Spine.Schema macro with @schema_prefix compile-time prefix"

provides:
  - "Behavioral ExUnit assertion: ConcurrencyRepo spine query emits metadata.source == 'parapet_incidents' (bare, no schema qualifier)"
  - "Cross-reference comment in telemetry_contract_test.exs pointing to new behavioral proof (D-08/D-09)"

affects: [56-02, 56-03, 56-04, verify-work, telemetry-contract]

tech-stack:
  added: []
  patterns:
    - "Raw Ecto telemetry event interception pattern: attach after sandbox checkout + reset! to avoid nil-source TRUNCATE events polluting the mailbox"
    - "Atom-form module reference (:'Elixir.Ecto.Adapters.SQL.Sandbox') to bypass alias shadowing in test modules"

key-files:
  created: []
  modified:
    - test/parapet/metrics/ecto_test.exs
    - test/telemetry_contract_test.exs

key-decisions:
  - "Attach telemetry handler AFTER Sandbox.checkout + ConcurrencyBootstrap.reset! to avoid receiving a nil-source TRUNCATE event before the spine query fires"
  - "Use Parapet.TestSupport.ConcurrencyRepo.all(Parapet.Spine.Incident) (schema module, not select fragment) to ensure Ecto populates put_source/2 from query_meta.sources with a non-nil value"
  - "Use atom form :'Elixir.Ecto.Adapters.SQL.Sandbox' to avoid alias collision with existing `alias Parapet.Metrics.Ecto` at module level"
  - "Documenting comment added in telemetry_contract_test.exs (not skipped) as it adds meaningful cross-reference with zero risk of churn"

patterns-established:
  - "Test 4 pattern: DB-scoped test within async: true module — checkout sandbox inline + on_exit detach; avoids converting whole module to async: false"

requirements-completed: [SAFE-02]

coverage:
  - id: D1
    description: "Behavioral assertion: real Incident query via ConcurrencyRepo emits Ecto query telemetry with metadata.source == 'parapet_incidents' (bare table name, no schema qualifier)"
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "test/parapet/metrics/ecto_test.exs#Test 4: real spine query emits bare :source == parapet_incidents (no schema qualifier)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Telemetry contract re-asserted frozen at 35 families with no [:parapet, :schema, ...] event introduced"
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "test/telemetry_contract_test.exs#all documented event families total 35"
        status: pass
    human_judgment: false
  - id: D3
    description: "Cross-reference comment added near [:parapet, :ecto, :query] fixture in telemetry_contract_test.exs pointing to behavioral D1 proof"
    verification:
      - kind: unit
        ref: "test/telemetry_contract_test.exs (comment-only; no fixture or count changed)"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-07-02
status: complete
---

# Phase 56 Plan 01: Contract & Release Hardening — Telemetry Source Invariant Summary

**Behavioral ExUnit assertion proving Ecto query telemetry :source stays bare 'parapet_incidents' under the parapet schema prefix, with telemetry contract re-asserted frozen at 35 families (no schema event)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-02T16:12:32Z
- **Completed:** 2026-07-02T16:15:30Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added Test 4 to `test/parapet/metrics/ecto_test.exs`: a live ConcurrencyRepo spine query proves `metadata.source == "parapet_incidents"` via the raw `[:parapet, :test_support, :concurrency_repo, :query]` Ecto event — the authoritative source of `:source` derived from `__schema__(:source)`, prefix-free (D-08/D-09 guard)
- Negative assertion: `source` carries no dotted schema-qualifier segment, guarding against `@schema_prefix` leaking into Prometheus label cardinality
- Telemetry contract test re-asserted green: 35 families, no `[:parapet, :schema, ...]` family (D-07 re-assert), no fixture or count changed
- Optional cross-reference comment added near `[:parapet, :ecto, :query]` fixture pointing to behavioral proof
- No production code modified (`git diff --name-only lib/` returns empty)

## Task Commits

1. **Task 1: Add behavioral bare-name :source assertion** - `cb474a7` (test)
2. **Task 2: Re-assert frozen 35-family contract + documenting comment** - `c70bf9d` (docs)

## Files Created/Modified

- `test/parapet/metrics/ecto_test.exs` — Added Test 4: DB-scoped behavioral assertion (55 lines); existing Tests 1-3 unchanged
- `test/telemetry_contract_test.exs` — Added 2-line documenting comment near `:ecto :query` fixture; no assertion logic changed

## Decisions Made

- Attach telemetry handler AFTER `Sandbox.checkout` + `ConcurrencyBootstrap.reset!()` to prevent the TRUNCATE (nil-source) telemetry event from arriving in the mailbox before the spine query fires — ordering discipline is the key correctness insight
- Use `ConcurrencyRepo.all(Parapet.Spine.Incident)` (schema module, not a `select` fragment) so Ecto's `put_source/2` populates `:source` from `query_meta.sources`; a `select: i.id` fragment yields nil source
- Use atom form `:'Elixir.Ecto.Adapters.SQL.Sandbox'` to bypass `alias Parapet.Metrics.Ecto` shadowing the `Ecto` name at module level
- Documenting comment chosen (not skipped): adds meaningful cross-reference with no churn risk

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Alias shadowing: Ecto.Adapters.SQL.Sandbox resolved to wrong module**
- **Found during:** Task 1 (initial test execution)
- **Issue:** `alias Parapet.Metrics.Ecto` at module level shadowed `Ecto`, so `Ecto.Adapters.SQL.Sandbox.checkout/1` expanded to `Parapet.Metrics.Ecto.Adapters.SQL.Sandbox` (undefined module)
- **Fix:** Used atom literal `:"Elixir.Ecto.Adapters.SQL.Sandbox"` in the test body to bypass the alias
- **Files modified:** test/parapet/metrics/ecto_test.exs
- **Verification:** Compilation succeeded; test ran
- **Committed in:** cb474a7

**2. [Rule 1 - Bug] nil :source received before spine query fires**
- **Found during:** Task 1 (first test run)
- **Issue:** `ConcurrencyBootstrap.reset!()` emits a TRUNCATE query event (nil source) before the handler was attached, or the `select: i.id` fragment returned nil source from `put_source/2`
- **Fix (ordering):** Moved handler attachment to AFTER `reset!()` completion; also switched query to `ConcurrencyRepo.all(Incident)` so source is always populated
- **Files modified:** test/parapet/metrics/ecto_test.exs
- **Verification:** `mix test test/parapet/metrics/ecto_test.exs` — 4 tests, 0 failures
- **Committed in:** cb474a7

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes necessary for test correctness; no production scope change.

## Issues Encountered

- `import Ecto.Query` initially included for `from/2` macro; removed after switching to `ConcurrencyRepo.all(Incident)` — no churn, clean final state

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. This plan is test-only. T-56-01 (Prometheus label cardinality guard) and T-56-02 (telemetry contract tampering) from the plan's threat register are both mitigated: behavioral assertion pins source, contract assertion re-greens at 35.

## Next Phase Readiness

- SAFE-02 fully proven: `:source` bare-name invariant guarded by behavioral test; contract frozen at 35 families with no schema event
- Ready for 56-02 (next plan in contract-release-hardening phase)

---
*Phase: 56-contract-release-hardening*
*Completed: 2026-07-02*
