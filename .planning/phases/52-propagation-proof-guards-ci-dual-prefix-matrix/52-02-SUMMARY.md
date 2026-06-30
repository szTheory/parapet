---
phase: 52-propagation-proof-guards-ci-dual-prefix-matrix
plan: "02"
subsystem: prefix-guard
tags:
  - schema-prefix
  - fitness-function
  - guard
  - PROP-02
  - security
dependency_graph:
  requires:
    - "52-01 (Parapet.Spine.Schema.normalize/1 + safe_ident!/1 — canonical normalization seam)"
  provides:
    - "PROP-02 static guard — CI build fails if runtime prefix: options, string-table writes, search_path, or raw parapet_ SQL appear in lib/parapet/"
  affects:
    - "52-03 (propagation tests inherit clean lib/parapet/ — guard is already green)"
    - "52-04 (CI matrix: guard runs free on every matrix cell via mix test lane)"
tech_stack:
  added: []
  patterns:
    - "ExUnit fitness function guard: async: true, no DB, Path.wildcard module attribute, per-line iteration with comment stripping"
    - "Negative lookbehind regex excluding schema_prefix:, module_prefix, _prefix:, and backtick doc mentions"
    - "Teaching failure message with read/write split-brain explanation + per-offender file:line/pattern/code/fix block"
key_files:
  created:
    - test/parapet/schema_prefix_guard_test.exs
  modified: []
decisions:
  - "Per-line iteration chosen over per-file Regex.scan: enables file:line tuple collection for teaching failure messages"
  - "Added backtick lookbehind (?<!`) to prefix: fingerprint: Plan 01 added doc sentences mentioning `prefix:` (e.g. 'Runtime `prefix:` is BANNED') — these are legitimate; the lookbehind prevents false positives without weakening the guard"
  - "strip_trailing_comment/1 uses regex to strip from first # outside quotes — sufficient for the four fingerprints; no full parser needed"
metrics:
  duration: "2 minutes"
  completed: "2026-06-30"
  tasks_completed: 1
  files_modified: 1
status: complete
---

# Phase 52 Plan 02: PROP-02 Static Prefix Guard Summary

PROP-02 line-filtered regex ExUnit fitness function scanning lib/parapet/**/*.ex for four forbidden runtime-prefix shapes, green from day one with a teaching split-brain failure message.

## What Was Built

### Task 1: PROP-02 static guard fitness function (D-01..D-05)

Created `test/parapet/schema_prefix_guard_test.exs` — an `async: true` (no DB) ExUnit guard that scans `lib/parapet/**/*.ex` at test compile time using a `@lib_files` module attribute.

**Scope (D-02):** `Path.wildcard("lib/parapet/**/*.ex")` — this glob does NOT match `lib/mix/tasks/`, where generators legitimately emit `create table(:parapet_*)` and `references(:parapet_*, on_delete: :delete_all)`. The exclusion is achieved by the glob alone; no explicit filter is needed.

**Four forbidden fingerprints (D-03):**

- **(a)** `~r/(insert_all|update_all|delete_all)\s*\(\s*["~]/` — string/sigil literal immediately after the verb's opening paren. Fires on `insert_all("parapet_claims", ...)`. Does NOT fire on `insert_all(ActionClaim, ...)` (module ref, no quote) or `on_delete: :delete_all` (no paren-open-quote sequence).
- **(b)** `~r/(?<!schema_)(?<!module_)(?<!_)(?<!`)prefix:\s/` — bare repo prefix: option with four negative lookbehinds excluding `schema_prefix:`, `module_prefix`, `_prefix:`, and backtick-wrapped doc mentions (`` `prefix:` ``).
- **(c)** `~r/search_path/` — any Postgres search_path usage.
- **(d)** `~r/fragment\(.*parapet_/` — raw `parapet_` SQL table name inside a `fragment(` call.

**Per-line iteration with comment stripping:** Each line is processed individually, trailing `#` inline comments are stripped via `strip_trailing_comment/1`, and lines containing `schema_prefix:` or `_prefix:` are skipped. Offenders are collected as `%{file, line, pattern, code, fix}` maps.

**Teaching failure message (D-05):** The assertion failure explains:
1. How Ecto resolves prefixes (FROM/JOIN > @schema_prefix > prefix: option > Repo config)
2. Why a runtime `prefix:` creates a read/write split-brain (reads use compile-time @schema_prefix, writes may land in a different schema)
3. Per-offender block with file:line, pattern label, offending code, and specific fix
4. A four-point HOW TO FIX section

**Green from day one (D-04):** Verified zero offenders in current `lib/parapet/` tree. Negative scratch test confirmed fingerprint (b) fires on `[prefix: "public"]` with the full teaching message.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing false-positive guard] Added backtick lookbehind to prefix: fingerprint**
- **Found during:** Task 1 — verification grep against lib/parapet/
- **Issue:** Plan 01 added doc sentences mentioning `` `prefix:` `` in the ban context (e.g., `Runtime \`prefix:\` is BANNED` in `evidence.ex:37` and `schema.ex:46`). These are legitimate documentation and would trigger fingerprint (b) without the backtick exclusion. The RESEARCH "Verified: Zero guard offenders" check was written before Plan 01 added these doc sentences.
- **Fix:** Added `(?<!`)` as a fourth negative lookbehind to the prefix: regex. Doc-string mentions of `` `prefix:` `` are now excluded; production code `prefix: "value"` (preceded by whitespace/comma) still fires.
- **Files modified:** `test/parapet/schema_prefix_guard_test.exs`
- **Commit:** 168517f (folded into the main task commit)

## Threat Mitigations Applied

Per `<threat_model>` in PLAN.md:

- **T-52-03 (Tampering — runtime prefix: reintroduced):** Fingerprint (b) fails the build the moment a bare `prefix:` repo option appears in `lib/parapet/**/*.ex`. Verified by the scratch-edit reject check: `[prefix: "public"]` triggered the failure with the teaching message. Reverted after confirmation.
- **T-52-04 (Tampering — search_path / string-table / raw SQL):** Fingerprints (a)/(c)/(d) cover all three remaining forbidden shapes. Green-from-day-one baseline makes any future introduction a hard build failure.
- **T-52-SC:** No package installs — no new hex dependencies (pure ExUnit regex guard).

## Known Stubs

None. The guard scans production code and is fully wired.

## Self-Check: PASSED

Verified files exist:
- FOUND: test/parapet/schema_prefix_guard_test.exs

Verified commits exist:
- FOUND: 168517f (feat(52-02): add PROP-02 static prefix guard fitness function)
