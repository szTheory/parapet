# SAFE-01 Evidence: Public API Manifest Zero-Drift Proof

**Date:** 2026-07-02
**Phase:** 56-contract-release-hardening
**Requirement:** SAFE-01
**Done-criterion:** D-10 (recorded in Plan 04)

---

## Command Run

```
mix verify.public_api
```

**Flag:** No `--write` flag — read-only verification mode only (D-06: drift = accidental expansion to wall off, not to bless).

**Exit status:** 0 (zero drift)

---

## Manifest Unchanged

```
git status --short priv/parapet/public_api_stable.json
```

Output: _(empty — no changes)_

The frozen manifest `priv/parapet/public_api_stable.json` was **not modified** by the run. The task exited 0 without needing to write anything, which is the correct zero-drift outcome.

---

## Prefix-Related Public Export: Pre-Existing Stable Entry

The sole prefix-related public export is **`Parapet.Evidence.schema_prefix/0`**:

- `@doc since: "1.0.3"` — pre-existing Stable helper, present since v1.0
- Listed at line 46 of `priv/parapet/public_api_stable.json` under `Parapet.Evidence` (`"tier": "stable"`)
- **Not added** by phases 53–55 (D-05 confirmed)

The compile-time `@schema_prefix`/`@prefix` module attribute and the `@raw_prefix`/`__prefix__/0` internal reader in `Parapet.Spine.Schema` are **not exports** — they are compile-time module attributes and an `@doc false` internal helper, respectively. It is structurally impossible for them to appear in the exported public API surface.

```
grep -c 'schema_prefix/0' priv/parapet/public_api_stable.json
```

Output: `1` (present and frozen — confirms the pre-existing entry)

---

## Conclusion

- `mix verify.public_api` (no `--write`) **exits 0** — the frozen public API manifest has zero drift despite the v1.7 schema-prefix change (D-05/D-06).
- `priv/parapet/public_api_stable.json` is **unchanged** — no manifest write occurred.
- `Parapet.Evidence.schema_prefix/0` is the sole prefix-related export, pre-existing Stable, already frozen in the manifest.
- Phases 53–55 added **zero new public exports** — the v1.7 compile-time prefix change left the public API contract intact.

**SAFE-01 satisfied.** Evidence feeds D-10 done-criterion record in Plan 04.
