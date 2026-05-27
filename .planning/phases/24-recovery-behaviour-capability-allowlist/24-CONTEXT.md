# Phase 24: Recovery Behaviour + Capability Allowlist - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the host-app-facing capability-registration API — `Parapet.Recovery` behaviour with four callbacks (`id/0`, `label/0`, `preview/2`, `execute/2`) + a uniform crash-proof `attach/1` activation function — and widen the `Parapet.Capabilities` allowlist from 3 atoms to 5 (adds `:revert_feature_flag`, `:disable_metric_label`). Covers RCV-01, RCV-02, RCV-03. Scope is **new behaviour module + activation function + allowlist widening + tests + docs/stability tier row** — NOT operator-path wiring (Phase 25), NOT emit-site wiring (Phase 26), NOT prebuilt playbooks (Phase 27), NOT graduation to Stable (Phase 29 / STAB-07). Module ships under the **Experimental** tier per the v1.0 freeze contract.
</domain>

<decisions>
## Implementation Decisions

### Behaviour Module Shape (RCV-01)

- **D-01:** Create `lib/parapet/recovery.ex` defining the `Parapet.Recovery` behaviour with four `@callback`s:
  - `id() :: atom()`
  - `label() :: String.t()`
  - `preview(incident :: any(), step :: any()) :: {:ok, map()} | {:error, term()}`
  - `execute(incident :: any(), target_refs :: any()) :: {:ok, map()} | {:error, term()}`
  Arity-2 on `preview` and `execute` is locked by the existing consumer at `lib/parapet/operator.ex:711` (`capability.execute.(incident, preview_entry.target_refs)`) and `:767` (`capability.preview.(incident, step)`).
- **D-02:** Provide a minimal `__using__/1` macro that injects **only** `@behaviour Parapet.Recovery`. Nothing else — no default implementations, no helper functions, no aliases. Mirrors the host-facing ergonomics of `Parapet.Integration` (`lib/parapet/integration.ex:1-27`) and avoids leaking surface that would freeze into v1.x. Host modules write `use Parapet.Recovery` (per Phase 24 success criterion #1) and Dialyzer surfaces missing callbacks at compile time via the standard `@behaviour` mechanism.
- **D-03:** `@moduledoc` carries the verbatim Experimental admonition shape:
  ```
  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release with a
  > single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  ```
  Mirrors `lib/parapet/capabilities.ex:6-10` and `lib/parapet/integrations/sigra.ex:2-11`. The `mix verify.public_api` admonition-regex classifier (`lib/mix/tasks/verify.public_api.ex:7-15`) auto-classifies the module from this moduledoc shape — no edits to the verify task needed. Phase 29 (STAB-07) graduates this admonition to Stable.

### Activation Function: `Parapet.Recovery.attach/1` (RCV-02)

- **D-04:** Signature is `attach([module()])` — a flat list of host-module atoms (NOT a keyword list, NOT a single module). Locked by Phase 24 success criterion #2: `Parapet.Recovery.attach([SomeMissingModule, RealModule])`.
- **D-05:** Per-module flow:
  1. `Code.ensure_loaded?(module)` — if `false`, skip silently (no log, no warn).
  2. If `true`, call `module.id()` and `module.label()` once at attach time.
  3. Capture `&module.preview/2` and `&module.execute/2` as anonymous-function captures.
  4. Delegate to `Parapet.Capabilities.register_recovery(module.id(), name: module.label(), preview: &module.preview/2, execute: &module.execute/2)`.

  Pattern precedent: `Parapet.attach/1` at `lib/parapet.ex:41-44` (uses `Code.ensure_loaded?` then `apply/3`); optional-dep skip pattern at `lib/parapet/integrations/scoria.ex:194` and `threadline.ex:81`.
- **D-06:** The function-capture bridge is **non-negotiable**. `Parapet.Capabilities` stores `preview`/`execute` as anonymous functions (`capabilities.ex:33-34`) and `lib/parapet/operator.ex:711,767` guards with `is_function(capability.preview, 2)` / `is_function(capability.execute, 2)`. Passing module references directly would fail the `is_function/2` guard and the operator would silently fall back to `base_preview` — invisible to tests.
- **D-07:** `target_kind` and `preview_only` (existing optional keys in the `Parapet.Capabilities` struct at `capabilities.ex:32,35`) are NOT in the v1.1 behaviour callback set. They keep their existing defaults (`nil` and `false`) — `attach/1` does not pass them through. If a future capability needs to opt into `preview_only` or specialize `target_kind`, that's a v1.2 addition (a new optional `@callback` or a `__using__/1` option), not a v1.1 surface.
- **D-08:** Return value: `{:ok, registered_ids}` where `registered_ids` is the list of `id()` atoms actually registered (omits silently-skipped modules). Shape symmetric with `Parapet.attach/1`'s return at `lib/parapet.ex:46`. Lets Phase 29's `mix parapet.doctor` adoption-signal check (ADOP-02) count attached capabilities uniformly.

### Allowlist Widening (RCV-03)

- **D-09:** Edit `@valid_capabilities` in `lib/parapet/capabilities.ex:14-18` from 3 atoms to 5: append `:revert_feature_flag` and `:disable_metric_label`. Final list (order matches the error message):
  ```elixir
  @valid_capabilities [
    :retry_async_item,
    :requeue_dead_letter,
    :request_manual_provider_check,
    :revert_feature_flag,
    :disable_metric_label
  ]
  ```
- **D-10:** **No edit** to the `register_recovery/2` `ArgumentError` raise branch at `capabilities.ex:42-45`. It already interpolates `inspect(@valid_capabilities)`, so the widened list flows through automatically and satisfies success criterion #3's "clear message naming the valid ids" verbatim. The existing test regex `~r/Invalid recovery capability id/` (`test/parapet/capabilities_test.exs:32-36`) still matches unchanged.
- **D-11:** **No edit** to `lib/parapet/telemetry/recovery_action.ex`. Its `allowed_public_keys/1` enumerates metadata key NAMES (`recovery_action.ex:85-92`) — `capability_id` is listed as a key but its atom-value vocabulary is **not** enumerated in the telemetry module. Atom-vocab agreement is enforced solely by the `id in @valid_capabilities` guard in `Parapet.Capabilities`. Single source of truth; no drift risk when Phase 26 wires emit-sites.

### State Isolation Across 100 Async Tests (Success Criterion #4)

- **D-12:** Keep `Parapet.Capabilities` as the single supervised named Agent (started at `lib/parapet/internal/application.ex:11`). Do NOT introduce a per-test sandbox process, do NOT introduce an `Application.put_env` indirection, do NOT introduce a per-test ETS table. The v0.10 SLO Application-env mistake (Pitfall 13) mutated shared atomic flags across tests — that failure mode does NOT apply to a per-key map indexed by `id`, where last-writer-wins per cell is acceptable.
- **D-13:** Write the 100-async test using `async: true` and assert via per-key reads only:
  - Each test registers its own host module and asserts via `Parapet.Capabilities.get_recovery(id)` on the row it just wrote.
  - Each test cleans up its own id in `on_exit` (write `nil` or remove the key).
  - **Never** assert on `Parapet.Capabilities.capabilities(:recovery)` list cardinality — that's the assertion that would race.
  - Distinct test modules can either (a) use the same allowlisted atom id with distinct `name: "test-#{n}"` payloads (last-writer-wins is fine because each test reads what it just wrote), or (b) parameterize over the 5 allowlisted atoms cyclically. Plan-phase picks one.
- **D-14:** This is a **new** test pattern — the existing `test/parapet/capabilities_test.exs:2,12` uses `async: false` and resets state with `Agent.update(Capabilities, fn _ -> %{recovery: %{}} end)`. That pattern cannot scale (every test would race the reset). The new async tests live alongside the existing sync tests; the existing tests are NOT migrated to async in Phase 24 (out of scope; not blocking RCV-03).

### Public-API & Stability Tier

- **D-15:** Add ONE new row to the Experimental Modules table in `docs/stability.md` (lines `:45-58`). Insert alphabetically — between `Parapet.MCP.PrometheusClient` and `Parapet.Telemetry.RecoveryAction`. New row names `Parapet.Recovery` with a short tier description matching the format of adjacent rows.
- **D-16:** **No code change** to `lib/mix/tasks/verify.public_api.ex`. The admonition-regex classifier (`:7-15`) auto-classifies the new module from its moduledoc admonition (per D-03). Missing admonition would halt the task at `:64-79` — covered.

### Out of Scope for Phase 24

- **D-17:** **No** changes to `Parapet.Operator.confirm_runbook_step/4`. Operator-path-skips-ClaimService closure is Phase 25 (UI-02). Phase 24 lands the behaviour + activation surface; Phase 25 wires the operator path through it.
- **D-18:** **No** emit-site wiring of `Parapet.Telemetry.RecoveryAction` events from the new behaviour or registry. Emit sites land in Phase 26 (Audit Propagation, AUD-01/02/03). Phase 24's contract test is module-introspection only — it does NOT assert that `attach/1` emits any telemetry.
- **D-19:** **No** prebuilt playbooks shipping in Phase 24. The 6 templates (PB-01..PB-06) land in Phase 27 — including the `:revert_feature_flag` and `:disable_metric_label` templates that consume the newly widened allowlist.
- **D-20:** **No** `mix parapet.gen.recovery <NAME>` Igniter task. ADOP-01 is Phase 29.
- **D-21:** **No** doctor adoption-signal check (capability count, missing-callback warnings). ADOP-02 is Phase 29.

### Claude's Discretion

- Exact `@moduledoc` body prose (must carry the Experimental admonition verbatim per D-03; rest of the prose can mirror `Parapet.Integration`'s style).
- Exact wording of the new `docs/stability.md` row's tier-description column (must match the format of adjacent rows).
- Whether the 100-async test parameterizes over all 5 allowlisted atoms or uses a single atom with varied payloads (D-13 option a vs b) — plan-phase picks one; both satisfy the success criterion.
- Exact spec lines on the `@callback` declarations — must produce arity-2 on `preview`/`execute` and arity-0 on `id`/`label` (D-01), but concrete `t()` types can use idiomatic Elixir shape rather than rigid types.

### Folded Todos

None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — RCV-01 (`:22`), RCV-02 (`:23`), RCV-03 (`:24`); Phase 24 traceability (`:114-116`).
- `.planning/ROADMAP.md` — Phase 24 entry at `:117`; out-of-scope dependencies on Phases 25/26/27/29.
- `.planning/phases/23-foundations-telemetry-contract-lease-until-migration/23-CONTEXT.md` — D-12 (`capability_id` vocab anchor: "5 atoms after Phase 24"); reminder that the `Parapet.Recovery` registry uses the existing supervised Agent (Pitfall 13 avoidance); Phase 23 telemetry contract shape that Phase 26 will emit against.
- `.planning/research/SUMMARY.md` — v1.1 research synthesis (capability-registration design via behaviour module).
- `.planning/research/PITFALLS.md` — Pitfall 13 (Application-env mistake — why we keep using the supervised Agent for per-key state).
- `.planning/threads/actionable-recovery-design.md` — v1.1 seed thread.
- `lib/parapet/integration.ex` (27 LOC) — **template** for the new behaviour module shape (single `@callback`, Stable-tier admonition). Recovery mirrors this with 4 callbacks under Experimental.
- `lib/parapet/capabilities.ex` — `:14-18` (`@valid_capabilities` widens here); `:20-22` (single supervised Agent — keep as-is); `:27-40` (`register_recovery/2` struct shape + per-key `put_in`); `:42-45` (existing `ArgumentError` raise — do NOT touch); the registry that `attach/1` delegates into.
- `lib/parapet.ex` — `:30-47` (`attach(opts)` precedent for list-of-atoms + `Code.ensure_loaded?` + skip; return shape `{:ok, adapters}`).
- `lib/parapet/operator.ex` — `:711` (`capability.execute.(incident, preview_entry.target_refs)`); `:767` (`capability.preview.(incident, step)`); `:657` (calls `Parapet.Capabilities.get_recovery/1` against the unscoped named process). These call sites lock arity-2 and the function-capture bridge. **Do NOT touch** — Phase 25 territory.
- `lib/parapet/integrations/sigra.ex` — `:2-11` Experimental admonition template; `@behaviour Parapet.Integration` style template.
- `lib/parapet/integrations/scoria.ex` — `:194` optional-dep `Code.ensure_loaded?` pattern reference.
- `lib/parapet/integrations/threadline.ex` — `:81` optional-dep `Code.ensure_loaded?` pattern reference.
- `lib/parapet/telemetry/recovery_action.ex` — `:85-92` (`@recovery_action_family_keys` — confirms `capability_id` is a metadata KEY but its atom-value vocab is NOT enumerated; vocab agreement is enforced via `@valid_capabilities` only).
- `lib/parapet/internal/application.ex` — `:11` (where the `Parapet.Capabilities` Agent is supervised; confirms it's a single process registered by name).
- `test/parapet/capabilities_test.exs` — `:2` (`async: false` baseline); `:12` (state reset via `Agent.update`); `:32-36` (existing `assert_raise ArgumentError` regex — still matches unchanged after widening).
- `lib/mix/tasks/verify.public_api.ex` — `:7-15` (admonition-regex classifier); `:64-79` (halt path on missing admonition). **Do NOT touch.**
- `docs/stability.md` — `:45-58` Experimental Modules table (new row for `Parapet.Recovery` inserts between `Parapet.MCP.PrometheusClient` and `Parapet.Telemetry.RecoveryAction`); `:141` outcome-atom freeze rule (vocabulary doctrine).
- `mix.exs` — `files:` whitelist (no changes expected; `lib/parapet/**/*.ex` already included).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Parapet.Integration` (`lib/parapet/integration.ex`, 27 LOC) is the minimal-`@behaviour` template — single `@callback`, Stable-tier admonition, no helper code. `Parapet.Recovery` mirrors the shape with 4 callbacks instead of 1 and the Experimental admonition instead of Stable.
- `Parapet.attach/1` at `lib/parapet.ex:30-47` is the precedent for the activation pattern: list-of-atoms → `Code.ensure_loaded?` → apply/skip → `{:ok, list}` return.
- `Parapet.Capabilities.register_recovery/2` at `lib/parapet/capabilities.ex:27-40` already accepts the exact keyword shape the new `attach/1` will pass: `[name:, preview:, execute:]`. Zero changes needed to the registry write path beyond widening `@valid_capabilities`.
- `Parapet.Capabilities` is a single supervised named `Agent` (`capabilities.ex:20-22`; supervised at `lib/parapet/internal/application.ex:11`). Per-key `put_in` semantics at `:27-40` mean concurrent writes on distinct ids do not corrupt each other — the architectural foundation for the 100-async test.

### Established Patterns

- **Behaviour + `__using__` ergonomics**: `Parapet.Integration` defines a `@behaviour` and lets adapters declare `@behaviour Parapet.Integration` directly. `Parapet.Recovery` adds a minimal `__using__/1` (per D-02) only because RCV-01 spells out `use Parapet.Recovery` — but the macro injects nothing more than `@behaviour`.
- **Optional-dependency activation via `Code.ensure_loaded?`**: established at `lib/parapet.ex:41`, `lib/parapet/integrations/scoria.ex:194`, `lib/parapet/integrations/threadline.ex:81`. Silently skipping unloaded modules is the contract — no warn, no log, no error.
- **Function-capture bridge between behaviour callbacks and the capabilities struct**: the registry struct stores `preview`/`execute` as anonymous funs (`capabilities.ex:33-34`); consumers gate with `is_function(., 2)` (`operator.ex:711,767`). New `attach/1` must capture (`&Module.preview/2`, `&Module.execute/2`) not pass module atoms.
- **Stability admonition as the public-API gate**: `mix verify.public_api` (`:7-15`) regex-classifies every `Parapet.*` module by scanning its `@moduledoc` for one of the documented tier admonitions. New module needs the Experimental admonition verbatim — and a mirror row in `docs/stability.md`.
- **Per-key Agent state for concurrent writes**: `Parapet.Capabilities`'s `:recovery` map is keyed by capability id; `Agent.update/2` serializes the `put_in` call. Concurrent writers on distinct keys do not race; concurrent writers on the same key get last-writer-wins (acceptable for the 100-async test as each test reads only what it just wrote).

### Integration Points

- `Parapet.Recovery.attach/1` → `Parapet.Capabilities.register_recovery/2` is the one-way dispatch; `attach` is the only caller of `register_recovery` for the host-app path. Direct `register_recovery` calls by user code remain supported but unblessed (the documented activation idiom is `attach/1`).
- `Parapet.Capabilities.get_recovery/1` ← `Parapet.Operator.confirm_runbook_step/4` (`operator.ex:657,711,767`) is the read path the operator UI consumes — UNTOUCHED by Phase 24. Phase 25 wires the operator's existing Confirm path through `Parapet.Operator.ActionPayload` + `ClaimService.claim_action/1` so the operator and Oban paths converge.
- `Parapet.Telemetry.RecoveryAction` ↔ `@valid_capabilities`: the two surfaces share only the `capability_id` atom symbol but NOT a single shared enumeration — `RecoveryAction` only lists keys, not values. The vocab is enforced at `Parapet.Capabilities`. Phase 26 emit sites will read the id from the runtime call payload, not from a static enumeration.
- `Parapet.Recovery` module → `mix verify.public_api` classifier (`verify.public_api.ex:7-15,64-79`) auto-picks-up via the moduledoc admonition; no manifest edits.
- `docs/stability.md` table row → human-readable mirror of the verify-task's machine classification; one new row.

### Concurrency / Multi-Node Constraints

- `Parapet.Capabilities` is a **single supervised process registered by name** — not per-node. In a multi-node deployment, every node has its own `Parapet.Capabilities` Agent; capabilities registered on one node are NOT visible on another. This is BY DESIGN: capabilities are declared by the host application's code (statically attached at boot), not by runtime registration, so every node attaches the same set during its own boot. Phase 24 does NOT introduce cross-node sync; if a future need surfaces (multi-tenant capability scoping), it's a v1.4+ multi-tenancy thread, not a v1.1 surface.
- `Agent.update/2` serializes writes through the Agent's mailbox. Concurrent `register_recovery` calls do not corrupt the `:recovery` map; per-id `put_in` makes per-key writes independent.
- The function captures stored in the struct (`&Module.preview/2`, `&Module.execute/2`) are MFA captures — they survive code reloads if `Module` is reloaded with the same name, and serialize cleanly across the BEAM. No closure-over-bindings concerns at attach time.
</code_context>

<specifics>
## Specific Ideas

- **The `Parapet.Recovery` module file path is `lib/parapet/recovery.ex`** (NOT `lib/parapet/recovery/recovery.ex`, NOT under `lib/parapet/automation/`). Mirrors `lib/parapet/integration.ex` placement.
- **`use Parapet.Recovery` injects only `@behaviour Parapet.Recovery`** — nothing else. No alias, no import, no default callback implementations. Adopters write all four callbacks explicitly. This is the most conservative ergonomic surface and matches what Phase 29 (STAB-07) will freeze.
- **`attach/1` returns `{:ok, registered_ids}`** — a 2-tuple, NOT `:ok`. The list of ids is the diagnostic surface ADOP-02 will read in Phase 29. If zero modules registered (e.g., all were `Code.ensure_loaded?/1 == false`), the return is `{:ok, []}` — not an error.
- **The new test file is `test/parapet/recovery_test.exs`** (mirroring `test/parapet/capabilities_test.exs`). The existing `capabilities_test.exs` is NOT renamed or refactored in Phase 24.
- **The Phase 24 PR is a single coherent commit set**: behaviour module + activation function + allowlist atoms + tests + docs/stability row. Same one-PR posture as Phase 23.
- **The two new allowlist atoms are added in the SAME order as ROADMAP.md success criterion #3 enumerates**: `:revert_feature_flag`, then `:disable_metric_label`. This is the order the error message displays them.
- **No dependency changes** in `mix.exs`. Phase 24 is pure-Elixir behaviour code; nothing new gets added to `deps/0`.
</specifics>

<deferred>
## Deferred Ideas

- **Operator path wiring through ClaimService** (`Parapet.Operator.confirm_runbook_step/4` closing UI-02 defect) — Phase 25.
- **Emit-site wiring of `Parapet.Telemetry.RecoveryAction` events** from `Parapet.Recovery.attach/1` and the operator Confirm path — Phase 26 (AUD-01/02/03).
- **TimelineEntry + ToolAudit propagation** for recovery actions — Phase 26.
- **6 prebuilt playbooks** (retry storm, suppression drift, stalled async, dead-letter drain, deploy-tied incident, cardinality blowout) — Phase 27 (PB-01..PB-06). Two of these depend on the newly widened allowlist atoms.
- **`mix parapet.gen.recovery <NAME>` Igniter scaffolder** — Phase 29 (ADOP-01).
- **`mix parapet.doctor` adoption-signal check** (capability count, missing-callback warnings, runbook-references-unknown-capability flagging) — Phase 29 (ADOP-02).
- **`docs/recovery-actions.md` adopter guide** — Phase 29 (ADOP-03).
- **`Parapet.Recovery` graduates Experimental → Stable** with the four callbacks frozen — Phase 29 (STAB-07).
- **Per-capability cooldown / breaker scope** (vs the system-scoped breaker today) — v1.2 (`.planning/REQUIREMENTS.md:85`).
- **`target_kind` / `preview_only` callback-driven semantics** — not in the v1.1 callback set; if a real use case surfaces, add as an OPTIONAL callback in v1.2.
- **Migrating the existing `capabilities_test.exs` to `async: true`** — out of scope; the existing sync tests stay. Only the new 100-test sweep ships under async.
- **Cross-node capability sync** (multi-tenancy, per-org scoping) — explicitly out of scope; v1.4+ multi-tenancy thread.
- **MCP Preview surface (read-only) for recovery actions** — v1.3+ (`.planning/REQUIREMENTS.md:84`).

### Reviewed Todos (not folded)

None — no pending todos matched this phase.
</deferred>
