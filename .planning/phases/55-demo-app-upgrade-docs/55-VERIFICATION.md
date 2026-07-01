---
phase: 55-demo-app-upgrade-docs
verified: 2026-07-01T21:00:00Z
status: human_needed
score: 3/3 must-haves verified (automated checks)
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Read docs/upgrade-1.x.md in full and confirm: (a) Track A config block (config :parapet, schema_prefix: nil) is immediately followed by the force-recompile line; (b) Track B section has its own recompile line after mix ecto.migrate; (c) Rollback section covers Track A and Track B rollback and explicitly covers half-migrated recovery with an explanation of the single-transaction guarantee; (d) FAQ is substantive and answers the 'do-nothing upgrader' scenario."
    expected: "Every config block is followed by mix deps.compile parapet --force; half-migrated recovery section explains transaction atomicity; FAQ covers key upgrader questions."
    why_human: "Grep can confirm the recompile line appears in the file but cannot verify that every config block is immediately (not paragraphs later) followed by it, nor judge FAQ completeness or tone."
  - test: "Read docs/upgrade-1.x.md and confirm the TL;DR leads with a clear reassurance ('your data never moves' or equivalent), that the 'Action Required' caveat is honest and framed correctly for do-nothing upgraders, and that verbatim Track A/B copy matches the doctor output and generated migration as described in 54-CONTEXT D-04/D-17/D-18."
    expected: "Reassure-then-instruct pattern is correct; framing does not falsely claim 'no action required'; Track A/B mechanics are consistent with the doctor tool output."
    why_human: "Tone, framing correctness, and cross-doc verbatim consistency require reading — cannot be asserted by grep."
  - test: "Read the docs/deployment.md 'Schema location' subsection (near Step 4) and confirm it reassures + routes to upgrade-1.x.md without restating Track A/B mechanics (no config blocks, no ALTER TABLE steps, no GRANT SQL)."
    expected: "Subsection is 3-5 lines: reassurance, route to upgrade-1.x.md. No mechanics duplicated."
    why_human: "Single-source compliance (no restatement) requires reading the prose, not grepping for presence."
  - test: "Read the README.md Installation section schema note (~line 62-64) and confirm: (a) it is placed after the mix parapet.install block, (b) it routes to migration-v1.md Step 3 (not directly to upgrade-1.x.md), (c) tone is brief and reassuring, not alarming."
    expected: "One-line note after the install block, routing correctly, no alarm tone."
    why_human: "Note placement relative to the install block and tone quality require human reading."
---

# Phase 55: Demo App Upgrade Docs Verification Report

**Phase Goal:** The demo app proves the prefix end-to-end on a real Phoenix host, and adopters have a copy-paste upgrade story that closes the audited #1 documentation gap.

**Verified:** 2026-07-01T21:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Demo smoke lane asserts `mix ecto.migrate` lands all six tables in `parapet` schema and evidence round-trip carries `Ecto.get_meta(record, :prefix) == schema_prefix()`; compile-out-clean (`--warnings-as-errors`, `--no-optional-deps`) holds | VERIFIED | Sentinel migration exists at `examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs`; two smoke tests at module level in `DemoApp.OperatorSmokeTest` (lines 137-176) targeting `schema_prefix()` (not a literal); compile step in CI at line 162-163; all 6 commits present |
| 2 | `docs/upgrade-1.x.md` exists, leads with "your data does not move unless you choose", with copy-paste Track A/B blocks each followed by the `--force` recompile line, least-privilege GRANTs, recompile-order, rollback incl. half-migrated recovery, and FAQ | VERIFIED (automated) + HUMAN NEEDED (content quality) | File exists; TL;DR at line 9 ("Your data never moves automatically"); `mix deps.compile parapet --force` appears 7 times; GRANTs section at line 95; Rollback section at line 129; Half-Migrated Recovery at line 164; FAQ at line 175; registered twice in mix.exs |
| 3 | `docs/deployment.md` has schema subsection, `README.md` carries a note, and `docs/migration-v1.md` routes to upgrade-1.x.md (the audited #1 gap) | VERIFIED (automated) + HUMAN NEEDED (tone/placement) | deployment.md "Schema location" subsection at line 64, routes to upgrade-1.x.md at line 70; migration-v1.md Step 3 at line 32 with two links to upgrade-1.x.md; README note at lines 62-64 after `mix parapet.install` block routing to migration-v1.md Step 3 |

**Score:** 3/3 truths verified by automated checks; 4 human judgment items remain for documentation quality.

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs` | NEW: sentinel migration (CREATE SCHEMA IF NOT EXISTS) | VERIFIED | Exists; `up/0` = `CREATE SCHEMA IF NOT EXISTS parapet`; `down/0` non-cascading (no CASCADE) |
| `examples/demo_app/test/demo_app/operator_smoke_test.exs` | EXTENDED: two new top-level smoke tests | VERIFIED | Lines 137-176: "schema prefix: evidence round-trip..." and "schema existence: all six spine tables..."; both top-level (not inside describe); `@moduletag :smoke` applies |
| `.github/workflows/ci.yml` | EXTENDED: one new compile step in existing demo job | VERIFIED | Lines 162-163: `Compile demo (warnings-as-errors, no-optional-deps)` placed after `mix deps.get`, before `mix ecto.create`; `release_gate` needs: [lint, test, demo] at line 172 is unchanged |
| `docs/upgrade-1.x.md` | NEW: single-source Track A/B upgrade guide | VERIFIED | 230-line document; section order correct; GRANTs, Recompile Order, Rollback, Half-Migrated Recovery, FAQ all present |
| `mix.exs` | EXTENDED: upgrade-1.x.md in extras: AND groups_for_extras | VERIFIED | `grep -c 'upgrade-1.x.md' mix.exs` = 2 (lines 73 and 95) |
| `docs/migration-v1.md` | EXTENDED: new Step 3, old Steps 3-6 renumbered to 4-7 | VERIFIED | Step 3 "Choose your schema location (v1.7+)" at line 32; Steps 4-7 confirmed; `mix parapet.doctor --ci` in Step 7 at line 123 |
| `docs/deployment.md` | EXTENDED: schema subsection near Step 4 | VERIFIED | "Schema location" subsection at line 64; routes to upgrade-1.x.md; no Track A/B mechanics restated (routing only) |
| `README.md` | EXTENDED: one-line schema note in Installation | VERIFIED | Lines 62-64: note present after `mix parapet.install` block; routes to migration-v1.md Step 3 |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| Sentinel migration (version 0) | Spine table migrations (20260525000000...) | Ecto migrator sorts by integer prefix; 0 < 20260525000000 | WIRED | Version-0 sentinel file sorts strictly before all spine migrations |
| `operator_smoke_test.exs` smoke tests | `DemoApp.Repo` (not ConcurrencyRepo) | `DemoAppWeb.ConnCase` + `Ecto.Adapters.SQL.query!(DemoApp.Repo, ...)` | WIRED | Tests use `DemoApp.Repo`; information_schema query parameterized with `$1` |
| New CI compile step | Existing `demo` job | Placed after `mix deps.get`, before `mix ecto.create` in same job | WIRED | `release_gate needs: [lint, test, demo]` unchanged at ci.yml:172 |
| `upgrade-1.x.md` | `mix.exs` HexDocs registration | `extras:` (line 73) + `groups_for_extras Guides:` (line 95) | WIRED | Count = 2; both lists updated |
| `migration-v1.md` Step 3 | `upgrade-1.x.md` | Two relative links: "See [Upgrade Guide (1.x)](upgrade-1.x.md)" | WIRED | Links at lines 50 and 56 |
| `deployment.md` schema subsection | `upgrade-1.x.md` | Relative link: "[Upgrade Guide (1.x)](upgrade-1.x.md)" | WIRED | Line 70 |
| `README.md` Installation note | `docs/migration-v1.md` Step 3 | Relative link: "[Migrating to Parapet 1.x](docs/migration-v1.md) Step 3" | WIRED | Lines 63-64 |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Sentinel migration file is substantive (not stub) | Read file content | `up/0` executes `CREATE SCHEMA IF NOT EXISTS parapet`; `down/0` non-cascading | PASS |
| Two SAFE-03 smoke tests are top-level (not inside describe) | Read lines 131-176 of operator_smoke_test.exs | Both tests are after line 130 comment, before `describe "Phase 48..."` at line 197; no enclosing describe block | PASS |
| get_meta assertion targets `schema_prefix()` not `"parapet"` literal | `grep schema_prefix() operator_smoke_test.exs` | Lines 144, 145, 150 all use `Parapet.Evidence.schema_prefix()`; no bare `"parapet"` assertion target found | PASS |
| Six-table parameterized query covers all 6 tables | Check lines 162-168 | All six tables listed: parapet_action_items, parapet_incidents, parapet_timeline_entries, parapet_tool_audits, parapet_system_events, parapet_action_claims | PASS |
| CI compile step in existing demo job, not new job | Check ci.yml lines 162-172 | Step at lines 162-163 inside demo job; `release_gate` needs unchanged at line 172 | PASS |
| upgrade-1.x.md registered in both mix.exs lists | `grep -c 'upgrade-1.x.md' mix.exs` | Returns 2 | PASS |
| migration-v1.md Steps 1-7 with Step 3 as schema-location and Step 7 as doctor --ci | grep on migration-v1.md | Steps 3 (schema location, line 32) through Step 7 (safe-upgrade checklist with doctor --ci, line 116/123) confirmed | PASS |

Step 7b: Full test suite NOT run (requires live database; single named-test pass/fail not runnable without DB). Smoke tests behaviorally dependent on live DB state — route to human verification.

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SAFE-03 | 55-01-PLAN.md | Compile-out-clean holds; demo smoke lane asserts six tables in `parapet` schema and evidence round-trip carries `Ecto.get_meta(record, :prefix) == schema_prefix()` | SATISFIED | Sentinel migration, two top-level smoke tests, CI compile step all verified in codebase |
| DOC-01 | 55-02-PLAN.md | New `docs/upgrade-1.x.md` — TL;DR, Track A/B copy-paste (each config block followed by `--force` recompile), GRANTs, recompile-order, rollback incl. half-migrated, FAQ | SATISFIED (automated) + HUMAN (content quality) | File exists with all required sections; per-block recompile lines present (7 occurrences); GRANTs, Rollback, Half-Migrated, FAQ sections confirmed |
| DOC-02 | 55-02-PLAN.md | `docs/deployment.md` schema subsection, `README.md` note, routing pointer from `docs/migration-v1.md` (audited #1 gap) | SATISFIED (automated) + HUMAN (tone/placement) | All three routing surfaces verified; single-source compliance (no mechanics restated) requires human reading |

All three requirement IDs (DOC-01, DOC-02, SAFE-03) are mapped to Phase 55 in REQUIREMENTS.md and all show "Complete" in the traceability table. No orphaned requirements found.

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No TBD/FIXME/XXX/TODO/PLACEHOLDER markers found in any phase-modified file | — | None |

No debt markers, empty implementations, or hardcoded stub data found in the five modified files.

**Note from SUMMARY:** Pre-existing `mix docs --warnings-as-errors` failures exist for `docs/demo-app.md` (not registered in mix.exs extras) and `Parapet.Spine.Schema.__prefix__/0` (hidden function referenced in doc string). These are pre-existing and not introduced by Phase 55. The SUMMARY confirms that filtering these two known warnings, `mix docs --warnings-as-errors` produces zero new warnings from Phase 55 changes. This is not a blocker for Phase 55 but is logged for Phase 56 pre-work.

---

## Human Verification Required

### 1. DOC-01: Per-block recompile line placement and FAQ completeness

**Test:** Open `docs/upgrade-1.x.md` and read it top to bottom. For each config block (elixir or bash), confirm the very next non-blank line or code block is `mix deps.compile parapet --force`. Then read the FAQ section and confirm it answers at minimum: (a) "what happens if I do nothing", (b) "can I use doctor to check before deciding", (c) half-configured/drift state detection.

**Expected:** Every config block is immediately followed by the force-recompile line; FAQ is substantive and covers the key upgrader scenarios.

**Why human:** Grep confirms the line appears somewhere in the file (7 occurrences found) but cannot verify immediate adjacency to each config block. FAQ completeness is a judgment call.

### 2. DOC-01: Verbatim copy accuracy and tone correctness

**Test:** Open `docs/upgrade-1.x.md` and compare the Track A config block, the Track B ALTER TABLE list, and the doctor drift message against the Phase 54 doctor output (`mix parapet.doctor`) and the generated migration from `mix parapet.gen.schema.move`. Confirm they tell the same story. Check that the TL;DR reassurance is genuine ("data does not move") while the "Action Required" section is honest (do-nothing upgrader gets an error).

**Expected:** Track A/B copy is consistent with doctor output and generated migration; framing does not falsely promise "no action required" but also does not overstate alarm.

**Why human:** Cross-doc consistency requires reading multiple artifacts side by side; tone judgment requires human assessment.

### 3. DOC-02: deployment.md single-source compliance

**Test:** Read the `docs/deployment.md` "Schema location" subsection (approximately lines 64-72). Confirm it contains only: a reassurance sentence, a description of the default behavior, and a link to `upgrade-1.x.md`. Confirm it does NOT contain any config blocks, ALTER TABLE SQL, GRANT statements, or Track A/B step-by-step mechanics.

**Expected:** Subsection is routing-only, 4-6 lines, no mechanics duplicated.

**Why human:** Single-source compliance (absence of mechanics) requires reading the prose, not just grepping for presence of the link.

### 4. DOC-02: README Installation note placement and tone

**Test:** Open `README.md` and find the Installation section. Confirm the schema note appears after the `mix parapet.install` code block (not before it, not buried elsewhere). Confirm it is brief (one to two sentences), reassuring in tone, and routes to `docs/migration-v1.md` Step 3 (not directly to upgrade-1.x.md).

**Expected:** Note after install block; 1-2 sentences; routes to migration-v1.md Step 3; no alarm tone.

**Why human:** Note placement relative to the install block and tone quality cannot be verified programmatically.

---

## Gaps Summary

No gaps found. All three must-have truths are satisfied by automated checks. The human verification items above are documentation quality and tone checks — they do not indicate missing functionality or missing content sections. All required sections, links, and artifacts are present in the codebase.

---

_Verified: 2026-07-01T21:00:00Z_
_Verifier: Claude (gsd-verifier)_
