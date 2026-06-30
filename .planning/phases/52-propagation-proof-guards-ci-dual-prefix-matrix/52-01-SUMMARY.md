---
phase: 52-propagation-proof-guards-ci-dual-prefix-matrix
plan: "01"
subsystem: prefix-normalization
tags:
  - schema-prefix
  - normalization
  - tdd
  - security
  - WR-01
  - WR-02
  - WR-03
  - WR-04
dependency_graph:
  requires:
    - "51-03 (Parapet.Spine.Schema macro + six spine schemas using it)"
  provides:
    - "Parapet.Spine.Schema.normalize/1 — canonical single-source normalization"
    - "Parapet.Spine.Schema.safe_ident!/1 — allowlist SQL identifier validator"
    - "Evidence.schema_prefix/0 delegation — frozen compile-time value"
    - "ConcurrencyBootstrap routes through normalize/1"
    - "Agreement test drives production code (mirrors deleted)"
  affects:
    - "52-02 (propagation test can call Schema.normalize/1)"
    - "52-03 (guard references clean normalize/1 seam)"
    - "52-04 (CI matrix tests both legs with sealed normalization)"
    - "Phase 53 generators (inherit safe_ident!/1 via __prefix__()/normalize/1)"
tech_stack:
  added:
    - "Parapet.Spine.Schema.Normalizer (private submodule in schema.ex, compile-time helper)"
  patterns:
    - "Private compile-time submodule: defined before main module in same file so module attributes can call it"
    - "defdelegate to expose submodule functions on the main module's public namespace"
    - "TDD RED/GREEN cycle: test commits first, then implementation commits"
key_files:
  created: []
  modified:
    - lib/parapet/spine/schema.ex
    - lib/parapet/evidence.ex
    - test/parapet/spine/schema_test.exs
    - test/parapet/evidence_test.exs
    - test/support/concurrency_bootstrap.ex
    - config/config.exs
    - priv/parapet/public_api_stable.json
decisions:
  - "Parapet.Spine.Schema.Normalizer private submodule: Elixir cannot call same-module functions from module attributes at compile time — defining normalize/1 and safe_ident!/1 in a submodule compiled first in the same file is the idiomatic solution (no __before_compile__ complexity, no separate file)"
  - "defdelegate normalize/1 and safe_ident!/1 onto Parapet.Spine.Schema: clean public API without duplication"
  - "Experimental tier for Parapet.Spine.Schema: module was added in Phase 51 without stability tier (pre-existing verify.public_api failure); fixed inline per Rule 1"
  - "schema_prefix/0 added to Evidence stable manifest: was already a public @doc since 1.7.0 function but missing from the stable JSON (pre-existing omission)"
metrics:
  duration: "12 minutes"
  completed: "2026-06-30"
  tasks_completed: 3
  files_modified: 7
status: complete
---

# Phase 52 Plan 01: Seal WR-01..04 — Single Trustworthy Prefix Source Summary

Single-source normalization for the Postgres schema prefix, folding identifier-safety in, freezing Evidence.schema_prefix/0 to the compiled value, and rewriting agreement tests to drive production code.

## What Was Built

Four Phase-51 code-review warnings (WR-01..04) sealed into one fix ("exactly one trustworthy prefix source") across four sites, in D-19 order.

### Task 1: normalize/1 + safe_ident!/1 on Parapet.Spine.Schema (WR-01 + WR-04)

- Extracted `Parapet.Spine.Schema.Normalizer` (private compile-time submodule in same file) implementing `normalize/1` and `safe_ident!/1`
- `normalize/1`: maps `nil`/`""`/`"public"`/:public → nil; atoms via `Atom.to_string/1` (IN-01: `:public` collapses); binaries through `safe_ident!/1`
- `safe_ident!/1`: allowlist `^[a-z_][a-z0-9_]*$` + 63-byte limit; raises `ArgumentError` for violations
- `defdelegate normalize/1` and `safe_ident!/1` onto `Parapet.Spine.Schema` (public `@doc false` API)
- `@prefix` module attribute now calls `Parapet.Spine.Schema.Normalizer.normalize(@raw_prefix)` — inline case block removed
- Closed Triplex/apartment CVE-class: prefix interpolated into raw DDL without allowlist

### Task 2: Evidence.schema_prefix/0 delegation + ConcurrencyBootstrap normalize/1 (WR-03)

- `Evidence.schema_prefix/0` body replaced with `Parapet.Spine.Schema.__prefix__()` delegation
- Eliminates `Application.get_env` runtime read — split-brain sealed by construction
- `ConcurrencyBootstrap` `@prefix` attribute now calls `Parapet.Spine.Schema.normalize(@raw_prefix)` (inline case removed)
- Leg-aware `q/1` DDL emission unchanged (prefixed vs bare identifiers preserved)

### Task 3: Agreement test rewrite, evidence test inversion, WR-02 asymmetry + docs

- `schema_test.exs`: agreement describe now maps `@input_set` through `Schema.normalize/1` directly — no test-local mirrors
- `schema_test.exs`: test-local `normalize_prefix/1` and `config_normalize_prefix/1` private helpers deleted
- `schema_test.exs`: cross-leg six-schema equality test added (all `__schema__(:prefix)` == `Schema.__prefix__()`)
- `schema_test.exs`: WR-02 asymmetry pinned with two explicit tests (unset→"parapet", explicit nil→nil)
- `evidence_test.exs`: schema_prefix/0 describe inverted — asserts frozen to compiled value and ignores `Application.put_env`
- Doc sentence at three sites: `config/config.exs`, `Schema` moduledoc, `Evidence.schema_prefix/0` docstring

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Pre-existing verify.public_api failure: Parapet.Spine.Schema missing stability tier**
- **Found during:** Task 1 (acceptance criteria check)
- **Issue:** `Parapet.Spine.Schema` was added in Phase 51 without an ExDoc stability-tier admonition in its `@moduledoc`, causing `mix verify.public_api` to fail with "missing stability-tier declaration"
- **Fix:** Added `> #### Experimental {: .warning}` admonition to `Parapet.Spine.Schema` moduledoc
- **Files modified:** `lib/parapet/spine/schema.ex`, `priv/parapet/public_api_stable.json`
- **Commit:** 8bc5df1

**2. [Rule 1 - Architectural constraint] `@prefix __MODULE__.normalize(@raw_prefix)` cannot call same-module functions**
- **Found during:** Task 1 implementation
- **Issue:** RESEARCH Open Question 1 assumed `@prefix __MODULE__.normalize(@raw_prefix)` would work with functions defined earlier in the same module. Elixir compile-time constraint: module attributes cannot call functions from the module currently being compiled, even via `__MODULE__`-qualified form.
- **Fix:** Extracted `Parapet.Spine.Schema.Normalizer` as a private submodule defined BEFORE `Parapet.Spine.Schema` in the same file. Submodule is compiled first, so its functions are available when `@prefix` module attribute fires. `defdelegate` exposes the functions on the public namespace. This satisfies the "single normalization source" requirement.
- **Files modified:** `lib/parapet/spine/schema.ex`
- **Commit:** 8bc5df1

### Pre-existing Failures (Out of Scope)

**`DocsPhase33Test` — `make up-auto` missing from demo README:** Pre-existing failure confirmed present before Phase 52 changes. Logged to `deferred-items.md` for tracking. Out of scope for this plan.

## TDD Gate Compliance

- RED commit (schema_test): `8e51f91 test(52-01): add failing tests for normalize/1 and safe_ident!/1 (TDD RED)`
- GREEN commit (schema.ex): `8bc5df1 feat(52-01): add normalize/1 + safe_ident!/1 to Schema...`
- RED commit (evidence_test): `43ff336 test(52-01): add failing frozen-value tests for Evidence.schema_prefix/0 (TDD RED)`
- GREEN commit (evidence.ex + bootstrap): `31d2859 feat(52-01): delegate Evidence.schema_prefix/0...`

Both RED/GREEN gate sequences are present in git log.

## Threat Mitigations Applied

Per `<threat_model>` in PLAN.md:

- **T-52-01 (Tampering — DDL injection):** `safe_ident!/1` allowlist (`^[a-z_][a-z0-9_]*$` + 63-byte limit) folded into `normalize/1`. Every resolution path (Schema `@prefix`, Evidence `schema_prefix/0`, ConcurrencyBootstrap `@prefix`) now routes through `safe_ident!/1` before any identifier reaches DDL. Verified by safe_ident! reject tests in Task 1.
- **T-52-02 (Elevation of Privilege — split-brain):** `Evidence.schema_prefix/0` delegates to compile-time `Schema.__prefix__()`. Runtime `put_env` can no longer redirect writes to a different schema. Verified by the inverted frozen-value test in Task 3.

## Known Stubs

None. All normalization paths are wired to production code.

## Self-Check: PASSED

Verified files exist:
- FOUND: lib/parapet/spine/schema.ex
- FOUND: lib/parapet/evidence.ex
- FOUND: test/parapet/spine/schema_test.exs
- FOUND: test/parapet/evidence_test.exs
- FOUND: test/support/concurrency_bootstrap.ex
- FOUND: config/config.exs
- FOUND: priv/parapet/public_api_stable.json

Verified commits exist:
- FOUND: 8e51f91 (TDD RED - schema normalize/safe_ident tests)
- FOUND: 8bc5df1 (feat - normalize/1 + safe_ident!/1 implementation)
- FOUND: 43ff336 (TDD RED - evidence frozen tests)
- FOUND: 31d2859 (feat - Evidence delegation + bootstrap)
- FOUND: fc75a68 (feat - agreement test rewrite + WR-02 docs)
