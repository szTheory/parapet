# Phase 26: Audit Propagation - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make every operator Confirm leave a complete, durable evidence trail. On a successful recovery action (`{:won, claim}` → `{:ok, exec_result}`), write BOTH an enriched `TimelineEntry` (`recovery_confirmed`) AND a `ToolAudit` row capturing operator identity, action name, args, outcome, and timestamps. Add a NEW `recovery_failed` TimelineEntry (+ `ToolAudit` with `success: false`) on capability execution error — distinct from short-circuit/conflict states, which continue to write nothing because nothing executed. Ensure the retrospective generator surfaces these recovery entries inline in the canonical chronology.

Covers AUD-01, AUD-02, AUD-03 + ROADMAP success criterion #4. Scope is **enriching the existing audit writes in `Parapet.Operator.confirm_runbook_step/4` + one new failure-path write + a cosmetic retrospective rendering touch** — all ADDITIVE under the v1.0 freeze. Return shapes of `confirm_runbook_step/4` (`{:ok,_}` / `{:error,_}` / `{:short_circuited,_}` / `{:conflicted,_}`) do NOT change. NOT in scope: telemetry emit-site coverage, prebuilt playbooks (Phase 27), demo seed/CI (Phase 28), Stable-tier graduation / Igniter task / doctor signal / adopter guide (Phase 29), any change to the frozen `Parapet.Telemetry.RecoveryAction` vocab (Phase 23) or `Parapet.Recovery` callbacks (Phase 24).
</domain>

<decisions>
## Implementation Decisions

### Schema & Type Representation

- **D-01:** Keep `TimelineEntry.type` as a plain `:string`. Add the `recovery_failed` type by simply writing the string `"recovery_failed"` from the new error arm — **NO migration, NO `Ecto.Enum` conversion, NO inclusion-list edit.** Evidence: `lib/parapet/spine/timeline_entry.ex:33` is `field(:type, :string)`; `validate_typed_payload/1` (`:49-59`) only special-cases `"triage_snapshot"` and lets every other type fall through untouched. Snake-case string types are the established convention (`"mitigation_executed"`, `"recovery_confirmed"`, `"automation_short_circuited"`).
- **D-02:** Satisfy AUD-01's `:recovery_confirmed` atom-spelling via the **existing string write `"recovery_confirmed"` plus a documented atom↔string mapping** in the requirement/CHANGELOG note. Do NOT convert the field to atom. Converting would break string-asserting tests (`test/parapet/operator_test.exs:594`, `test/parapet/operator/preview_lifecycle_test.exs:262/286/410`) and the live step-done matcher `e.type in ["mitigation_executed", "recovery_confirmed"]` at `lib/parapet/operator/workbench_contract.ex:130` — a v1.0 additive-only freeze violation.
- **D-03:** **No new dedup mechanism** (no TimelineEntry idempotency key, no DB unique constraint). The claim gate IS the dedup boundary: `confirm_runbook_step/4` executes the capability exactly once (`operator.ex:737`) and writes exactly one entry per `{:won}+{:ok}` inside one transaction; repeat Confirms return `{:conflicted, _}` (`operator.ex:773`) keyed on `idempotency_key` and write nothing. Adding a unique constraint would make a legitimate post-`mark_failed` retry collide and surface an opaque error instead of `{:error, reason}`. This resolves the Phase 25-deferred "one-per-Confirm vs one-per-execute" dedup concern structurally.

### Evidence Field Set & Sources (AUD-01, AUD-02)

- **D-04:** Enrich BOTH the `recovery_confirmed` TimelineEntry payload AND the `ToolAudit` row with the full AUD-01/02 field set. All five fields are reachable in the current `confirm_runbook_step/4` scope — no new plumbing path:
  - **operator identity** = `payload.actor` (the canonical cross-surface identity string; `lib/parapet/operator/action_payload.ex:19`, required at `:37`). Automation uses `actor: "system:automation:executor"` (`lib/parapet/automation/executor.ex:56`); operator path carries the operator-supplied actor. This keeps AUD-02 consistent "regardless of which surface triggered it."
  - **action name** = `to_string(capability_id)` (in scope at `operator.ex:704`). (`tool_name` stays `"operator_confirm_recovery"`.)
  - **args** = `preview_entry.target_refs` (the actual targets acted on — `operator.ex:737`), NOT the `target_refs_hash`.
  - **outcome** = a structured map (e.g. `%{"status" => "succeeded"}`) plus `inspect(exec_result)` for the raw result.
  - **timestamps** = rely on the schema's auto `timestamps(type: :utc_datetime_usec)` (`timeline_entry.ex:38`).
- **D-05:** Populate `ToolAudit`'s currently-unset `output` field (cast but never set by `build_audit/2`) with the outcome map. Evidence: `build_audit/2` (`operator.ex:990-1002`) today sets only `tool_name`, `success: true`, and `input`; `ToolAudit` has `output`/`success`/`duration_ms` available (`lib/parapet/spine/tool_audit.ex:19-23`). Set `success: false` on the failure path (D-06).
- **D-06:** **AUD-03 failure write lives at the single site `operator.ex:763`** (the `{:error, reason}` arm after a won claim). The rescued `{:capability_raised, msg}` (from `operator.ex:738-740`) flows into this same arm and DOES count as `recovery_failed`. The arm MUST still call `ClaimService.mark_failed(claim, reason)` (`operator.ex:766`) AND still return `{:error, reason}` — the `recovery_failed` write is purely additive; release-the-claim + return shape are unchanged. Normalize the error reason into the payload via `inspect(reason)` (matching the `inspect(exec_result)` convention at `operator.ex:751`) — NOT a structured failure_class (that would pull in the frozen `@failure_classes` telemetry vocab, out of scope).

### Retrospective Surfacing (Success Criterion #4)

- **D-07:** Criterion #4 is **already structurally satisfied** — once the entries are written they appear inline automatically. `Parapet.Evidence.Retrospective.generate_markdown/1` selects ALL entries `where t.incident_id == ^incident.id` ordered `asc: inserted_at` with NO type whitelist (`lib/parapet/evidence/retrospective.ex:24-25`), and `format_entries/1` maps over every entry (`:117-119`). The ONLY change is cosmetic: add `format_payload/1` clauses for human-readable `recovery_confirmed` / `recovery_failed` rendering, with **distinct wording for failures** (e.g. "Recovery failed: …") so the generic `inspect(payload)` fallback (`:140-148`) doesn't dump a raw map. `format_type/1` (`:136`) already humanizes the type string. Do NOT add any filtering/whitelist logic — none exists, and adding one would risk excluding recovery entries.

### Telemetry Emit-Site Scope

- **D-08:** **Telemetry emit-sites are OUT of scope for Phase 26.** AUD-01/02/03 and criterion #4 reference only `TimelineEntry`, `ToolAudit`, operator identity, and the retrospective — zero telemetry vocabulary. The frozen `Parapet.Telemetry.RecoveryAction` moduledoc itself frames `:telemetry.span/3` emit-sites as FUTURE wiring (`lib/parapet/telemetry/recovery_action.ex:14-15`). The existing audit path already fires `[:parapet, :audit, :created]` (`lib/parapet/operator/evidence.ex:156`), so audit observability is non-zero. Bundling the 8-event emit-coverage would balloon scope and risk regressions against the Phase 23 frozen vocab. (If a later phase wants emit-coverage, it is its own slice.)

### Out of Scope for Phase 26

- **D-09:** No change to `Parapet.Telemetry.RecoveryAction` event family / vocab / `shape_metadata/2` (Phase 23 froze it).
- **D-10:** No change to `Parapet.Recovery` behaviour callbacks (Phase 24 locked the 4-callback shape).
- **D-11:** No change to the `confirm_runbook_step/4` return contract or the claim/preview/short-circuit logic delivered in Phase 25 — Phase 26 only enriches the audit writes inside the existing arms.
- **D-12:** No prebuilt playbooks (Phase 27), no demo seed / CI lane (Phase 28), no Stable-tier graduation / `mix parapet.gen.recovery` / `mix parapet.doctor` adoption signal / `docs/recovery-actions.md` (Phase 29).

### Claude's Discretion

- Exact key names and shape of the structured outcome map (`%{"status" => "succeeded"}` vs richer) — plan-phase picks, as long as AUD-01/02 fields are present and JSON-safe.
- Whether the enriched TimelineEntry payload and ToolAudit `output` reuse one shared builder helper or stay inline — both fine.
- Exact human-readable copy in the new `format_payload/1` retrospective clauses.
- Whether `recovery_failed` ToolAudit also sets `duration_ms` (nice-to-have; not required by AUD-03).

### Folded Todos

None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — AUD-01 (`:39`), AUD-02 (`:40`), AUD-03 (`:41`); Phase 26 traceability rows (`:121-123`).
- `.planning/ROADMAP.md` — `### Phase 26: Audit Propagation` (goal + 4 success criteria; depends on Phase 25; Complexity M notes "dedup rules to keep timeline readable" — see D-03).
- `.planning/phases/25-wire-confirm-through-claimservice-preview-confirm-ux/25-CONTEXT.md` — Phase 25 D-19/D-20 deferred the audit shape + ToolAudit writes to Phase 26; deferred "audit-side dedupe" to Phase 26 (see D-03); documents the existing `type: "recovery_confirmed"` string write.
- `.planning/phases/23-foundations-telemetry-contract-lease-until-migration/23-CONTEXT.md` — frozen `Parapet.Telemetry.RecoveryAction` vocab (`@short_circuit_reasons`, `@action_kinds`, `@failure_classes`) — DO NOT touch.
- `.planning/phases/24-recovery-behaviour-capability-allowlist/24-CONTEXT.md` — `Parapet.Recovery` arity-2 `preview`/`execute` callbacks; the capability struct the operator confirms against.
- `lib/parapet/operator.ex` — **central edit target.** `confirm_runbook_step/4` (`:695-787`); `{:won}→{:ok}` success arm with the existing thin `recovery_confirmed` write (`:743-761`); `{:error, reason}` execute-failure arm = AUD-03 write site (`:763-768`); rescue wrapping exceptions to `{:error, {:capability_raised, _}}` (`:738-740`); `build_audit/2` (`:990-1002`, sets only `tool_name`/`success`/`input` today); `target_refs_hash/1`, `find_recent_preview/3`; `capability_id` in scope at `:704`.
- `lib/parapet/operator/evidence.ex` — `run_operator_command/1` (Ecto.Multi transaction writing incident changeset + TimelineEntry + ToolAudit, ~`:131-161`); fires `[:parapet, :audit, :created]` (`:156`); its return becomes the function's success return.
- `lib/parapet/operator/action_payload.ex` — `actor` field (`:19`), required + non-blank (`:37-38`) = the operator-identity source for AUD-01/02.
- `lib/parapet/spine/timeline_entry.ex` — `field(:type, :string)` (`:33`), `field(:payload, :map)` (`:34`), auto `timestamps(:utc_datetime_usec)` (`:38`); `validate_typed_payload/1` only constrains `"triage_snapshot"` (`:49-59`).
- `lib/parapet/spine/tool_audit.ex` — fields `tool_name`/`input`/`output`/`success`/`duration_ms` (`:19-23`); `output` is available but unset today.
- `lib/parapet/evidence/retrospective.ex` — `generate_markdown/1` selects all incident entries, no whitelist (`:21-27`, `:24-25`); `format_entries/1` (`:117-119`); `format_type/1` (`:136`); `format_payload/1` fallback to add clauses to (`:140-148`).
- `lib/parapet/operator/workbench_contract.ex` — step-done matcher `e.type in ["mitigation_executed", "recovery_confirmed"]` (`:130`) — proves `type` must stay a string.
- `lib/parapet/automation/executor.ex` — `actor: "system:automation:executor"` identity convention (`:56`); audit-write precedent to keep operator audit shape consistent (AUD-02 cross-surface).
- `lib/parapet/escalation/worker.ex` — second audit-write precedent; `inspect/1` outcome normalization (`~:100`).
- `lib/parapet/telemetry/recovery_action.ex` — frozen contract module; moduledoc frames emit-sites as future wiring (`:14-15`) — DO NOT edit (supports D-08).
- `test/parapet/operator_test.exs` — `:594` asserts the STRING `"recovery_confirmed"` (regression guard for D-01/D-02).
- `test/parapet/operator/preview_lifecycle_test.exs` — `:262`, `:286`, `:410` assert string types; new audit-enrichment assertions extend these.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Parapet.Operator.confirm_runbook_step/4` (`operator.ex:695-787`) already has the four-arm claim dispatch from Phase 25; Phase 26 only enriches the writes inside the `{:ok}` arm and adds a write to the `{:error}` arm.
- `Parapet.Operator.Evidence.run_operator_command/1` already writes incident changeset + TimelineEntry + ToolAudit atomically in one `Ecto.Multi` — reuse it for both the enriched success write and the new failure write.
- `build_audit/2` (`operator.ex:990-1002`) is the single audit-attrs builder — extend it (or its call sites) to add action name / args / outcome and to set `output` + `success: false` on failures.
- `payload.actor` (`ActionPayload`) is the ready operator-identity field; no new identity plumbing needed.
- `Parapet.Evidence.Retrospective` already renders every incident entry inline, chronologically — only `format_payload/1` clauses are new.

### Established Patterns

- **Snake-case string TimelineEntry types**, validated only for `"triage_snapshot"`; new types need zero schema work.
- **`inspect/1` for opaque-result normalization** in audit payloads (`operator.ex:751`, escalation worker) — reuse for the failed-reason payload.
- **`payload.actor` as the cross-surface URN** (`"system:automation:executor"` for the Oban path) — operator path mirrors this convention so AUD-02 records "who" uniformly.
- **`Ecto.Multi`-wrapped audit writes** via `run_operator_command/1` — one transaction per audited action; the claim gate (not a DB constraint) enforces single-write.

### Integration Points

- The enriched `recovery_confirmed` write stays inside the `{:won}→{:ok}` arm (`operator.ex:743-761`); the new `recovery_failed` write goes in the `{:error, reason}` arm (`operator.ex:763`) BEFORE the existing `mark_failed` + `{:error, reason}` return (which both stay).
- `workbench_contract.ex:130` consumes `"recovery_confirmed"` to mark a step done — keep the exact string.
- `retrospective.ex` consumes whatever entries exist — recovery entries flow in for free once written; add display clauses only.
- ToolAudit `output`/`success` fields are the AUD-02 sink for outcome + pass/fail.

### Concurrency / Single-Write Constraints

- The claim (`(incident_id, action_kind: "operator", action_key)` unique, Phase 23/25) guarantees one winner → one execute → one audit write. No additional dedup needed (D-03).
- A failure path calls `mark_failed` to release the claim so the operator can retry immediately; a TimelineEntry/ToolAudit unique constraint would break that retry — avoid it.
</code_context>

<specifics>
## Specific Ideas

- **`recovery_confirmed` stays the string `"recovery_confirmed"`** (not the atom `:recovery_confirmed`). AUD-01's atom spelling is satisfied by string + documented mapping; the spine field is `:string` and a live matcher + tests depend on the string.
- **`recovery_failed` is the new string `"recovery_failed"`**, written only in the post-won `{:error, reason}` arm. Short-circuit and conflict arms keep writing nothing.
- **Operator identity = `payload.actor`**, the same field the Oban automation path sets to `"system:automation:executor"` — uniform "who" across surfaces.
- **Args in the audit = `preview_entry.target_refs`**, never the hash. The hash is integrity-gating (Phase 25); the audit needs the actual targets.
- **Failed-reason normalization = `inspect(reason)`**, including the `{:capability_raised, msg}` rescue case — no structured failure_class (that's frozen telemetry vocab).
- **Phase 26 is one coherent PR** (it's the audit half of the Confirm path Phase 25 built): enriched success write + new failure write + retrospective display clauses + test assertions land together.
- **No `mix.exs` / dependency changes**; no migrations.

[No external specs beyond the canonical refs above.]
</specifics>

<deferred>
## Deferred Ideas

- **Telemetry emit-site coverage** for `Parapet.Telemetry.RecoveryAction` (`:executed` span triplet, `:confirmed`, `:preview_failed`, `:previewed`, etc.) — its own future slice; AUD success criteria don't require it (D-08).
- **Structured failure-class taxonomy** for `recovery_failed` payloads (vs `inspect(reason)`) — would couple to the frozen `@failure_classes` telemetry vocab; defer unless a consumer needs it.
- **Converting `TimelineEntry.type` to an `Ecto.Enum`** for compile-time type safety — explicitly rejected for v1.1 (breaking under the v1.0 freeze); revisit only at a major version with a backfill migration.
- **Prebuilt playbooks (PB-01..PB-06)** — Phase 27.
- **Demo seed + CI lane (DEMO-05/06)** — Phase 28.
- **Stable graduation, `mix parapet.gen.recovery`, `mix parapet.doctor` adoption signal, `docs/recovery-actions.md` (STAB-07, ADOP-01..03)** — Phase 29.
- **Per-capability cooldown / breaker scope** — v1.2.

### Reviewed Todos (not folded)

None — no pending todos matched this phase.
</deferred>
