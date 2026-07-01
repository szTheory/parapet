---
phase: 53
slug: generators-library-migrations
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-01
---

# Phase 53 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) + Igniter.Test |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/mix/tasks/parapet.gen.spine_test.exs test/mix/tasks/parapet.gen.archive_indexes_test.exs test/parapet/spine/schema_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds (targeted files) / full suite per project norm |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (targeted generator + schema tests)
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite must be green under **both** CI legs (`PARAPET_SCHEMA_PREFIX=parapet mix test` and the nil/public leg)
- **Max feedback latency:** ~15 seconds (targeted), full suite per project norm

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | File | Automated Command | File Exists | Status |
|--------|----------|-----------|------|-------------------|-------------|--------|
| GEN-01 | Sentinel `00000000000000_create_parapet_schema.exs` created | unit (Igniter.Test) | `parapet.gen.spine_test.exs` | quick run | ❌ W0 | ⬜ pending |
| GEN-01 | `--no-create-schema` omits sentinel (`refute_creates`) | unit | `parapet.gen.spine_test.exs` | quick run | ❌ W0 | ⬜ pending |
| GEN-01 | Non-cascading `DROP SCHEMA IF EXISTS` in down (no CASCADE) | unit (`assert_creates/3` golden) | `parapet.gen.spine_test.exs` | quick run | ❌ W0 | ⬜ pending |
| GEN-02 | `prefix:` count-guard on gen.spine + archive_indexes output | unit (`Regex.scan`) | both gen test files | quick run | ❌ W0 | ⬜ pending |
| GEN-02 | FK constraint name byte-identical — parapet leg | unit (`contains_snippet?`) | both gen test files | quick run | ❌ W0 | ⬜ pending |
| GEN-02 | FK constraint name byte-identical — nil/public leg | unit (`contains_snippet?`) | both gen test files | quick run | ❌ W0 | ⬜ pending |
| GEN-02 | Nil leg → byte-identical to current unprefixed output | unit (`assert_creates/3` golden) | `parapet.gen.spine_test.exs` | quick run | ❌ W0 | ⬜ pending |
| GEN-03 | `configure_new/6` writes `:schema_prefix` (no-clobber) | unit (Igniter.Test) | `parapet.gen.spine_test.exs` | quick run | ❌ W0 | ⬜ pending |
| GEN-03 | `--schema` vs existing-config conflict warns, does not crash | unit (`resolve_prefix/2` pure core) | `test/parapet/spine/schema_test.exs` | quick run | ❌ W0 | ⬜ pending |
| GEN-04 | `--no-create-schema` prints DBA `CREATE SCHEMA` + `GRANT` remediation notice | unit (Igniter notices) | `parapet.gen.spine_test.exs` | quick run | ❌ W0 | ⬜ pending |
| GEN-05 | One shared resolver drives spine / archive_indexes / install | unit (pure core, precedence `flag > config > default`) | `test/parapet/spine/schema_test.exs` | quick run | ❌ W0 | ⬜ pending |
| GEN-06 | 5 lib + 3 demo committed migrations create tables under schema | integration (dual-prefix CI matrix) | CI matrix | `PARAPET_SCHEMA_PREFIX=parapet mix test` | ❌ (CI) | ⬜ pending |
| GEN-07 | All generator-output assertions above present + green | unit | see above | quick run | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/parapet.gen.spine_test.exs` — extend with sentinel/golden/count-guard/refute-omission/FK-name/nil-leg tests (GEN-01/02/03/04/07)
- [ ] `test/mix/tasks/parapet.gen.archive_indexes_test.exs` — extend with `prefix:` count-guard + FK/index-name-unchanged under both legs (GEN-02/07)
- [ ] `test/parapet/spine/schema_test.exs` — add `resolve_prefix/2` pure-core cases: precedence, conflict-warns-not-crashes, `safe_ident!` rejection (GEN-05, GEN-03)
- [ ] Golden captures for `assert_creates/3`: run live once to capture Igniter's exact formatting, then pin (schema-migration golden + nil-leg golden)

*These are net-new assertions extending existing test files; no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| One-time contributor stale-DB reset (`mix demo.reset` + drop `parapet_concurrency_test`) after committed-migration edits | GEN-06 (D-12) | Local dev DBs already migrated won't pick up in-place edits; not a CI concern | Document in CHANGELOG/PR body + Phase-55 upgrade doc; contributor runs once |

*All generator-output behaviors have automated verification; only the one-time dev-DB reset is manual.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s (targeted)
- [ ] Dual-leg green: both `parapet` and nil/public legs pass before verify
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
