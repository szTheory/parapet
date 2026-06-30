---
phase: 51
slug: prefix-core-test-seam
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-29
---

# Phase 51 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`test/test_helper.exs` → `ExUnit.start()`) |
| **Config file** | none today — D-06 adds `config/config.exs` as a compile seam (not test config) |
| **Quick run command** | `mix test test/parapet/spine/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~suite-dependent (Postgres-backed; test DB `parapet_concurrency_test`) |
| **Test DB bootstrap** | `Parapet.TestSupport.ConcurrencyBootstrap.bootstrap!/0` (hand-written DDL, no migrations) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/parapet/spine/`
- **After every plan wave:** Run `mix test` (full suite — the suite-green gate is the phase done-criterion, D-10)
- **Before `/gsd-verify-work`:** Full suite must be green under `schema_prefix: parapet`
- **Max feedback latency:** scoped run seconds; full suite per existing CI runtime

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| PREFIX-01 | All six schemas `use Parapet.Spine.Schema` and compile | unit | `mix test test/parapet/spine/schema_test.exs` | ❌ W0 | ⬜ pending |
| PREFIX-01/02 | `__schema__(:prefix) == "parapet"` for all six under default config | unit | `mix test test/parapet/spine/schema_test.exs` (assert across `[Incident, ActionItem, SystemEvent, ToolAudit, TimelineEntry, ActionClaim]`) | ❌ W0 | ⬜ pending |
| PREFIX-03 | Normalization agreement: `__prefix__/0` and `config.exs` copy map `["parapet","","public",nil,"custom"]` identically → `["parapet", nil, nil, nil, "custom"]` | unit | `mix test test/parapet/spine/schema_test.exs` (agreement test) | ❌ W0 | ⬜ pending |
| PREFIX-03 | `nil`/`""`/`"public"` ⇒ byte-identical legacy SQL — resolver returns `nil` for each | unit | assert `__prefix__/0` returns `nil` per input (assert the resolver fn, not the baked attr) | ❌ W0 | ⬜ pending |
| PREFIX-04 | `Evidence.schema_prefix/0` returns `"parapet"` (default) and normalizes runtime config | unit | `mix test test/parapet/evidence_test.exs` (extend if present, else add) | ❌ W0 | ⬜ pending |
| TEST-01 | `config/config.exs` reads `PARAPET_SCHEMA_PREFIX`; absent ⇒ `"parapet"` | unit (indirect) | covered by the agreement test asserting the config copy's mapping | ❌ W0 | ⬜ pending |
| TEST-01 | `config` excluded from Hex package whitelist | unit (optional) | assert `Mix.Project.config()[:package][:files]` excludes `"config"` | ⚠ optional | ⬜ pending |
| TEST-02 | Full suite green under `schema_prefix: parapet` (bootstrap qualifies all DDL) | suite-green | `mix test` (entire suite; bootstrap creates `parapet` schema + qualified tables) | ✅ existing suite | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Specific observable checks (verbatim)

1. **Agreement unit test** — `["parapet","","public",nil,"custom"]` mapped identically by `Parapet.Spine.Schema.__prefix__/0` (via a swappable/pure resolver) and the `config.exs` normalization. Expected `["parapet", nil, nil, nil, "custom"]` from both. **Directly testable now.**
2. **`__schema__(:prefix) == "parapet"`** for all six spine modules under default config. **Directly testable now.**
3. **Byte-identical legacy SQL** for `nil`/`""`/`"public"` — assert `__prefix__/0` (and `schema_prefix/0`) return `nil` for each input. The compiled `@schema_prefix` cannot be flipped in-suite — assert the *resolver*, not the compiled attribute. **Resolver testable now; compiled-leg backstop → Phase 52.**
4. **Full suite green under `schema_prefix: parapet`** — `mix test` passes end-to-end with the qualified bootstrap creating `"parapet"."parapet_*"` and `CREATE SCHEMA IF NOT EXISTS "parapet"`. **Directly testable now (D-10 done-criterion).**
5. **Bootstrap qualifies 6 tables / 4 references / 12 index `ON` targets / TRUNCATE list** — structurally verified by the suite running green (any missed qualification → `relation does not exist`). **Directly testable now.** *(Note: research corrected D-09's count from 11 → **12** index targets; lines 46,51,56,84,88,105,109,122,146,150,154,159.)*

---

## Wave 0 Requirements

- [ ] `test/parapet/spine/schema_test.exs` — stubs for PREFIX-01/02/03 (`__schema__(:prefix)` across six + normalization agreement + `__prefix__/0` legacy-nil cases)
- [ ] Runtime `schema_prefix/0` assertion — extend `test/parapet/evidence_test.exs` if it exists, else add (PREFIX-04)
- [ ] No new conftest/fixtures — `ConcurrencyCase`/`ConcurrencyBootstrap` already provide the DB harness
- [ ] No framework install — ExUnit already present

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | — | All Phase 51 behaviors have automated verification (unit + suite-green) |

*The compiled **unprefixed** leg (recompiling matrix) is the one deferred proof — it is a Phase 52 backstop, NOT a Phase 51 manual gate.*

---

## Deferred to Phase 52 (backstops, NOT Phase 51 gates)

- Compiled **unprefixed** leg green (recompiling CI matrix `schema_prefix: ['parapet','public']` + prefix-namespaced `_build` cache + `mix compile --force`).
- `to_sql`/`Ecto.get_meta` per-leg propagation assertions on selects/joins/insert_all/Multi.
- Static runtime-`prefix:` ban guard over `lib/`.
- Negative "no bare `parapet_incidents`" assertion under the prefixed leg.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (`schema_test.exs`, `evidence_test.exs` extension)
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (scoped run for quick loop, full suite per wave)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
