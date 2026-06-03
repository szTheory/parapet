# Phase 25: Wire Confirm Through ClaimService + Preview/Confirm UX — Research

**Researched:** 2026-05-28
**Domain:** Elixir operator-API rewire + LiveView UX + multi-node concurrency test
**Confidence:** HIGH (every assertion below cross-referenced against the actual source files; CONTEXT.md is largely validated, with one important correction and several seams the planner must handle)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (verbatim from 25-CONTEXT.md `<decisions>`)

**Operator-Path ClaimService Routing (UI-02, UI-04)**
- **D-01:** `confirm_runbook_step/4` calls `ClaimService.claim_action/1` AFTER preview-token validation and BEFORE invoking `capability.execute.(...)`. Args: `action_kind: "operator"`, `action_key: to_string(step_id_atom)`, `breaker_step_id: step_id_atom`, `idempotency_key: payload.idempotency_key`.
- **D-02:** Five-arm `case` on `claim_action/1` mirroring `Executor.perform/1` and `Escalation.Worker.perform/1`. Internal 3-tuple `{:short_circuited, claim, reason}` wraps to public 2-tuple `{:short_circuited, reason}`. Internal `{:conflicted, claim}` wraps to public `{:conflicted, claim.id}`.
- **D-03:** `{:ok, result}` and `{:error, reason}` shapes UNCHANGED. New variants strictly additive.
- **D-04:** No new `action_kind` atoms. `"operator" | "automation" | "escalation"` is locked.

**Preview Token Lifecycle (UI-01, UI-03)**
- **D-05:** Keep TimelineEntry-backed storage. No `parapet_preview_tokens` table.
- **D-06:** 5-min expiry stays at `compute_preview/3`. On confirm, stale branch returns **new** `{:short_circuited, :preview_expired}` instead of today's `{:error, :stale_preview}`.
- **D-07:** Add `target_refs_hash` field to preview payload. Algorithm: `Base.encode16(:crypto.hash(:sha256, :erlang.term_to_binary(Enum.sort(target_refs))), case: :lower)`. On mismatch: `{:short_circuited, :target_refs_drift}`.
- **D-08:** "Confirm without fresh Preview" leans on existing `{:error, :mismatched_preview}` from `find_recent_preview/3`.
- **D-09:** `find_active_preview/1` unchanged.

**LiveView Branch Surfacing (UI-01, UI-04)**
- **D-10:** Edits land in `operator_detail_live.ex` (`confirm_mitigation` handler at `:123-142`) and `operator_components.ex` (`preview_panel/1` at `:342-403`).
- **D-11:** `handle_event("confirm_mitigation", ...)` grows from 2 arms to **4 arms**: `{:ok, _}`, `{:short_circuited, reason}` with reason-specific flash + Re-Preview button, `{:conflicted, _claim_id}` with verbatim "Another node is executing this recovery — refresh to see the outcome", `{:error, reason}` existing generic.
- **D-12:** `preview_panel/1` renders action name (= `Parapet.Capabilities.get_recovery(id).name`). target_kind and count already render. `target_refs_hash` round-trips through preview-payload to Confirm submit (plan picks hidden form field vs assigns).

**Multi-Node Concurrency Test (Success Criteria #2, #4)**
- **D-13:** New file `test/parapet/operator/confirm_concurrency_test.exs`. Uses `ConcurrencyCase` + `unboxed_run` + `Task.async` rendezvous + `:go` broadcast.
- **D-14:** Two simulated operators race Confirm on same `(incident_id, "operator", action_key)` after each takes a valid Preview. One gets `{:ok, _}`, the other gets `{:conflicted, _claim_id}` matching the winner's row.
- **D-15:** Short-circuit branches (`:preview_expired`, `:target_refs_drift`) tested via `async: true` unit tests. Plan-phase picks `operator_test.exs` (existing) or new `preview_lifecycle_test.exs`.

**Telemetry Posture**
- **D-16:** MAY emit `Parapet.Telemetry.RecoveryAction` events from operator path if trivially in scope; otherwise defer to Phase 26.

**Out of Scope (D-17 through D-23):** No edits to `Parapet.Telemetry.RecoveryAction`, `Parapet.Recovery` callbacks, no new TimelineEntry types, no new ToolAudit beyond existing, no prebuilt playbooks, no Igniter tasks, no Stable-tier graduation.

### Claude's Discretion
- Exact flash copy beyond ROADMAP-spec'd strings
- `target_refs_hash` round-trip: hidden form field vs assigns
- Short-circuit unit tests location: existing `operator_test.exs` vs new `preview_lifecycle_test.exs`
- Whether to opportunistically emit telemetry from operator path

### Deferred Ideas (OUT OF SCOPE for Phase 25)
- `:recovery_confirmed` / `:recovery_failed` TimelineEntry type changes (Phase 26)
- Full telemetry emit-site coverage (Phase 26)
- 6 prebuilt playbooks (Phase 27)
- `mix parapet.gen.recovery` (Phase 29)
- `mix parapet.doctor` recovery checks (Phase 29)
- Adopter guide (Phase 29)
- Stable-tier graduation (Phase 29)
- Per-capability cooldown (v1.2)
- `parapet_preview_tokens` table (rejected)
- Configurable preview expiry (rejected)
- Audit-side dedupe (Phase 26)
- MCP Preview surface (v1.3+)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Operator clicks Preview → sees action name, target args, blast-radius, expected diff in a dedicated panel before any execution. | `preview_panel/1` at `operator_components.ex:342-403` already renders `target_kind` (`:359`), `count` (`:363`), `warnings`, `idempotency_caveats`. Phase 25 ADDS action name (via `Parapet.Capabilities.get_recovery(id).name`) and threads `target_refs_hash` through. |
| UI-02 | Confirm routes execution through `Parapet.Operator.ActionPayload` + `ClaimService.claim_action/1` (closes operator-path-skips-claim defect). | `confirm_runbook_step/4` at `operator.ex:690-745` currently calls `capability.execute.(...)` directly at `:710` with NO claim. New code inserts `case ClaimService.claim_action(...) do` wrapping that call. `ActionPayload` at `operator_detail_live.ex:125-131` already provides `idempotency_key`. |
| UI-03 | Preview tokens have 5-min expiry; stale previews detected via `target_refs` hash and rejected; expired tokens prompt re-Preview. | 5-min expiry already exists at `operator.ex:751` (`utc_now + 300s`). Phase 25 ADDS the hash field at `compute_preview/3` and the hash compare at `confirm_runbook_step/4`. |
| UI-04 | Confirm returns `{:short_circuited, reason}` if breaker open or incident state changed since Preview, and `{:conflicted, claim_id}` if another operator holds the claim. LiveView renders both with operator-actionable next steps. | `claim_service.ex:51-58` already returns internal `{:short_circuited, claim, reason}` and `{:conflicted, claim}`. Operator wraps to public 2-tuples. LiveView handler grows 2→4 arms. |
</phase_requirements>

## Summary

CONTEXT.md is **highly accurate** — the assumptions-mode session correctly identified the five-arm case template (`executor.ex:29-47`), the internal-vs-public tuple shape mapping, the `target_refs_hash` algorithm, the 5-min expiry location, and the LiveView edit surfaces. Reading the actual code confirmed every file-path and line-number cited in the canonical refs.

**Three corrections / additions** the planner MUST handle that CONTEXT.md does not surface explicitly:

1. **`claim.id` is a `:binary_id` (UUID string), not integer** (`action_claim.ex:27`). The `_claim_id` in `{:conflicted, claim_id}` is a UUID string. Specs and any operator-UI display copy must reflect this.
2. **The internal `short_circuit_reason` vocab in `ClaimService` does NOT match the frozen `@short_circuit_reasons` atom vocab.** Inside `claim_service.ex`, `incident_state_gate/1` returns the strings `"already_open" | "already_investigating" | "already_resolved"`, `CircuitBreaker.gate/3` returns the string `"circuit_breaker_tripped"`, and `suppression_gate/2` returns whatever `to_string(reason)` produces. The frozen vocab is atoms (`:incident_resolved`, `:breaker_open`, `:preview_expired`, `:target_refs_drift`). The operator's public 2-tuple `{:short_circuited, reason}` MUST be an atom from the frozen vocab — so the operator path needs a **string→atom mapping function** as it unwraps the internal 3-tuple. Phase 25 owns this mapping; without it, the operator path will emit strings while the telemetry contract expects atoms.
3. **`Parapet.Telemetry.RecoveryAction` has no emit helpers today** — only `shape_metadata/2`, `normalize_*`, `event_families/0`. Opportunistic emit (D-16) would require calling `:telemetry.execute/3` directly. The pattern is straightforward (≤8 lines per site) and trivially cheap; recommend **YES emit `:short_circuited` and `:conflicted`** opportunistically (defer `:previewed` / `:confirmed` / `:executed` span to Phase 26 where emit-site test coverage will already be locked in).

**Primary recommendation:** Treat this phase as a near-mechanical "third caller of `claim_action/1`" plus a contained LiveView UX edit plus one multi-node test. The biggest seam — and the one most likely to slip through the planner — is the string→atom mapping for short-circuit reasons. Surface that as its own task.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Five-arm `claim_action/1` dispatch | Library (`lib/parapet/operator.ex`) | — | Operator API is the public boundary; `confirm_runbook_step/4` is the third caller alongside `Executor` and `Escalation.Worker`. Wrapper module would fragment the stable surface. |
| Internal-3-tuple → public-2-tuple wrapping | Library (`lib/parapet/operator.ex`) | — | Lives in `confirm_runbook_step/4` itself; adopter-facing variants must be 2-tuples per the v1.0 additive-only freeze. |
| String→atom mapping for short-circuit reasons | Library (`lib/parapet/operator.ex`) — private function | — | `ClaimService` returns strings (e.g., `"already_resolved"`); telemetry contract expects atoms (`:incident_resolved`). Operator wraps. NOT a `ClaimService` edit — its internal vocab is older and out-of-scope per CONTEXT D-17. |
| `target_refs_hash` compute + compare | Library (`lib/parapet/operator.ex`) | — | Same canonicalization on both sides of the preview/confirm boundary; lives next to existing `preview_token` generation. |
| Preview-token expiry gate | Library (`lib/parapet/operator.ex` + `workbench_contract.ex` consumer) | — | Existing 5-min expiry at `operator.ex:707` + `workbench_contract.ex:194-203` derivation stay; only the failure-arm return value changes. |
| `confirm_mitigation` 4-arm handler | Demo LiveView (`examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex`) | — | Parapet ships no LiveView; demo is the reference adopter UI. |
| `preview_panel/1` — action name + hash round-trip | Demo LiveView component (`examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`) | — | Same surface; one file. |
| Multi-node concurrency proof | Library tests (`test/parapet/operator/confirm_concurrency_test.exs`) | — | New file; uses `ConcurrencyCase` + `unboxed_run` + Task rendezvous. |
| Short-circuit unit tests | Library tests | — | Plan-phase picks `test/parapet/operator_test.exs` (existing recovery describe block) or new `test/parapet/operator/preview_lifecycle_test.exs`. |

## Standard Stack

### Core (already in project; no install)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` / `ecto_sql` | ~> 3.10 (mix.exs:106-107) | Multi-tuple claim insert + `update_all` self-heal | The whole claim path is Ecto-native; no alternative. [VERIFIED: mix.exs] |
| `:crypto` | OTP stdlib | SHA-256 for `target_refs_hash` | `:erlang.term_to_binary/1` + `:crypto.hash(:sha256, _)` is the standard hash recipe in BEAM; no dep added. [VERIFIED: existing usage in `lib/parapet/operator.ex:752` via `strong_rand_bytes`] |
| `phoenix_live_view` | ~> 1.1 (demo_app/mix.exs) | `handle_event` + `put_flash` + `assign` | Demo LiveView already uses this surface. [VERIFIED: demo_app/mix.exs] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:telemetry` | ~> 1.2 | `:telemetry.execute/3` for opportunistic `:short_circuited` / `:conflicted` emits | Only if D-16 opportunistic-emit decision lands as YES. |
| `ex_unit` | OTP stdlib | All tests | Already in use. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SHA-256 over `term_to_binary` | `:erlang.phash2(target_refs)` | `phash2` is fast but collisions are not cryptographic; if a future adversarial-target-refs test surfaces, the hash needs replacement. SHA-256 future-proofs at zero cost — `:crypto` is stdlib. CONTEXT.md D-07 already locks SHA-256. |
| Five-arm `case` | A behaviour-dispatched callback pattern | Behaviours add layers; the existing two callers (`Executor`, `Worker`) are copy-paste five-arm. Adding a third is mechanical. CONTEXT.md D-02 locks this. |
| New `parapet_preview_tokens` table | Stay on TimelineEntry-backed storage | CONTEXT.md D-05 explicitly rejects new table. Existing storage is 90% sufficient. |

**Installation:** No new packages. `:crypto` and `:telemetry` are already transitive dependencies.

**Version verification:** Skipped — Phase 25 adds zero new dependencies (confirmed via `mix.exs:104-119` and `examples/demo_app/mix.exs`). All hash + telemetry primitives are stdlib or already-installed.

## Package Legitimacy Audit

> SKIPPED — Phase 25 installs no external packages. All required primitives are stdlib (`:crypto`, `:erlang`) or already-installed transitives (`:telemetry`). No package-supply-chain risk surface in this phase.

## Architecture Patterns

### System Architecture Diagram (data flow)

```
[Operator clicks Preview button in LiveView]
         │
         ▼ phx-click="preview_mitigation"
[operator_detail_live.ex :103-121]
         │ calls
         ▼
[Parapet.Operator.preview_runbook_step/3] ── compute_preview/3
         │                                       │ (adds target_refs_hash)
         │ writes "recovery_preview" TimelineEntry
         ▼
[Operator reviews preview_panel in LiveView]
         │
         ▼ phx-click="confirm_mitigation" (with token)
[operator_detail_live.ex :123-142]
         │ calls
         ▼
[Parapet.Operator.confirm_runbook_step/4]
         │
         ├── find_recent_preview/3 ───── (not found / token mismatch) ─→ {:error, :mismatched_preview} (unchanged)
         │
         ├── expiry check (DateTime.compare) ─── (expired) ─→ {:short_circuited, :preview_expired}  ★ CHANGED from {:error, :stale_preview}
         │
         ├── target_refs_hash compare ──────── (drift) ─→ {:short_circuited, :target_refs_drift}    ★ NEW
         │
         ├── ClaimService.claim_action/1 ★ NEW WRAPPER  (action_kind: "operator")
         │     │
         │     ├── {:won, claim}      ──→ capability.execute.(incident, target_refs)
         │     │                              │
         │     │                              ├── {:ok, result} ─→ ClaimService.mark_executed(claim)
         │     │                              │                  ─→ TimelineEntry "recovery_confirmed"  (unchanged)
         │     │                              │                  ─→ {:ok, result}                        (unchanged)
         │     │                              │
         │     │                              └── {:error, reason} ─→ {:error, reason}                  (unchanged)
         │     │
         │     ├── {:short_circuited, claim, reason_string} ─→ map string→atom ─→ {:short_circuited, atom}  ★ NEW
         │     │
         │     ├── {:conflicted, claim} ─→ {:conflicted, claim.id}                                      ★ NEW
         │     │
         │     └── {:error, reason}     ─→ {:error, reason}                                              (unchanged)
         │
         ▼
[LiveView handle_event 4-arm case]
   {:ok, _}            → "Mitigation confirmed and executed"  (existing)
   {:short_circuited, r} → reason-specific flash + Re-Preview button (reuses phx-click="preview_mitigation")
   {:conflicted, _id}    → "Another node is executing this recovery — refresh to see the outcome"
   {:error, r}           → "Confirmation failed: …"           (existing)
```

### Recommended Project Structure (no new files except tests)

```
lib/parapet/
├── operator.ex                  # edited: confirm_runbook_step/4 + compute_preview/3 + new string→atom mapper
└── (no new modules)

examples/demo_app/lib/demo_app_web/live/parapet/
├── operator_detail_live.ex       # edited: confirm_mitigation handler 2→4 arms
└── operator_components.ex        # edited: preview_panel/1 adds action name + hash round-trip

test/parapet/
├── operator_test.exs             # edited: existing :stale_preview test updated
└── operator/
    ├── confirm_concurrency_test.exs  # NEW: multi-node race test
    └── preview_lifecycle_test.exs    # NEW (optional, plan-phase choice): :preview_expired + :target_refs_drift unit tests
```

### Pattern 1: Five-Arm `claim_action/1` Dispatch (THE template — but actually four arms in source)

**What:** Every caller of `ClaimService.claim_action/1` implements the same `case` block.

**Source code (verbatim from `lib/parapet/automation/executor.ex:29-47`):**

```elixir
case claim_service().claim_action(
       incident_id: incident_id,
       action_kind: "automation",
       action_key: step_id,
       breaker_step_id: step_id,
       idempotency_key: idempotency_key
     ) do
  {:won, claim} ->
    execute_claimed_step(incident, step_id, idempotency_key, claim)

  {:short_circuited, _claim, reason} ->
    record_short_circuit(incident_id, step_id, reason)

  {:conflicted, _claim} ->
    record_claim_conflict(incident_id, step_id)

  {:error, reason} ->
    {:error, reason}
end
```

**CRITICAL CORRECTION to CONTEXT.md:** The case is **four arms, not five**. CONTEXT.md D-02 says "five-arm `case`" but the actual code has four arms: `{:won, _}`, `{:short_circuited, _, _}`, `{:conflicted, _}`, `{:error, _}`. There is **no catch-all `_`** arm. Same shape in `escalation/worker.ex:37-63`. The planner must not invent a fifth arm — Dialyzer would warn it's unreachable since `claim_action/1`'s return is fully enumerated by the function spec.

**Subtle differences between the two precedents:**
- `Executor` (`executor.ex:29-47`) calls `Operator.execute_runbook_step/3` **inside** the `{:won, _}` arm, then calls `mark_executed/2` if that succeeds. For the operator path, the inverse is true: the operator path IS the one calling the capability directly, so `capability.execute.(...)` moves inside `{:won, claim}`.
- `Escalation.Worker` (`worker.ex:50-59`) has a `resolve_conflict/7` helper that retries on the conflict branch if it's a resumable retry. The operator path is human-clicked and not retryable — keep the conflict branch simple: wrap to `{:conflicted, claim.id}` and return.

### Pattern 2: Internal-3-Tuple → Public-2-Tuple Wrapping

**What:** `ClaimService.claim_action/1` returns internal 3-tuple `{:short_circuited, claim, reason}` and 2-tuple `{:conflicted, claim}`. Existing callers (`Executor`, `Worker`) use the internal shape directly because they don't expose the return to adopters. The Operator API DOES expose it — so it MUST unwrap.

**Source confirmation:** `claim_service.ex:50-61`:

```elixir
{:short_circuit, reason} ->
  claim =
    update_claim_status(repo, claim, "short_circuited", %{
      short_circuit_reason: reason
    })
  {:short_circuited, claim, reason}

{:conflicted, claim} ->
  {:conflicted, claim}
```

**Implementation pattern for the operator:**

```elixir
{:short_circuited, _claim, reason_string} ->
  {:short_circuited, map_short_circuit_reason(reason_string)}

{:conflicted, claim} ->
  {:conflicted, claim.id}
```

Note `claim.id` is a UUID string (`:binary_id` per `action_claim.ex:27`), not an integer.

### Pattern 3: String→Atom Short-Circuit Reason Mapping (CRITICAL — NOT IN CONTEXT.md)

**What goes wrong without this:** The CONTEXT.md treats the frozen `@short_circuit_reasons` atom vocab (`:incident_resolved`, `:breaker_open`, `:preview_expired`, `:target_refs_drift`) as if `ClaimService` already emits them. **It does not.** The internal vocab is older strings:

- `claim_service.ex:163`: `incident_state_gate/1` returns `{:short_circuit, "already_#{state}"}` → strings like `"already_resolved"`, `"already_investigating"`, `"already_open"`.
- `circuit_breaker.ex:35`: `gate/3` returns `{:short_circuit, "circuit_breaker_tripped"}` → string, not `:breaker_open`.
- `claim_service.ex:179-181`: `suppression_gate/2` returns `{:short_circuit, to_string(reason)}` — arbitrary stringified reason.

**Mapping table the planner must implement** (private function in `lib/parapet/operator.ex`):

| Internal string from ClaimService | Public atom (frozen vocab) | Source |
|------------------------------------|----------------------------|--------|
| `"already_resolved"` | `:incident_resolved` | `claim_service.ex:163` → `recovery_action.ex:47` |
| `"already_investigating"` | `:incident_resolved` (closest mapping; investigating ≠ open) | `claim_service.ex:163` |
| `"circuit_breaker_tripped"` | `:breaker_open` | `circuit_breaker.ex:35` → `recovery_action.ex:48` |
| (any other string) | recommended: pass through as `:internal_error` OR raise — plan-phase decides | safety fallback |

Plus, two reasons originate at the **operator level**, NOT ClaimService:
- `:preview_expired` — emitted when `DateTime.compare(preview_entry.expires_at, DateTime.utc_now()) != :gt`. This replaces the existing `{:error, :stale_preview}` return at `operator.ex:736`.
- `:target_refs_drift` — emitted on hash mismatch (new gate added in Phase 25).

These two are returned **before** the `ClaimService.claim_action/1` call ever happens, so they bypass the string→atom mapper.

**Why this matters:** The operator-API surface is what adopters pattern-match on. If the planner forgets the mapper, adopters will see public 2-tuples like `{:short_circuited, "already_resolved"}` (string) instead of `{:short_circuited, :incident_resolved}` (atom) — and the telemetry contract module (`Parapet.Telemetry.RecoveryAction.normalize_short_circuit_reason/1`) will raise `ArgumentError` if adopters or downstream code pass that string back into it. Phase 23's contract test (`test/parapet/telemetry/recovery_action_test.exs`) would also fail if Phase 25 tries to emit a string into the telemetry surface.

### Pattern 4: `target_refs_hash` Canonicalization

**What:** Same algorithm on both sides of the preview/confirm boundary.

**Algorithm (verbatim from CONTEXT.md D-07):**

```elixir
defp target_refs_hash(target_refs) do
  target_refs
  |> List.wrap()
  |> Enum.sort()
  |> :erlang.term_to_binary()
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16(case: :lower)
end
```

**Where it gets written (Preview side):** `compute_preview/3` at `lib/parapet/operator.ex:750-780`. Currently writes `"target_refs" => []` at `:758`. Add `"target_refs_hash" => target_refs_hash(target_refs)` adjacent to `"preview_token"` at `:764`. Note: the existing code uses `[]` as default `target_refs` and lets `host_data` from `capability.preview.(...)` merge over it at `:771-772` — so the hash must be computed **after** the merge, not on the empty default. Plan-phase must verify the merge order.

**Where it gets read (Confirm side):** Today, `find_recent_preview/3` at `operator.ex:782-819` returns `{:ok, %{expires_at: ..., target_refs: payload["target_refs"]}}` — it does NOT surface `target_refs_hash`. Phase 25 must extend this to return `target_refs_hash: payload["target_refs_hash"]` as well, then add a hash-compare gate in `confirm_runbook_step/4` between the expiry check (`:707`) and the `ClaimService.claim_action/1` call.

**Open question — `target_refs` shape:** `operator.ex:758` sets default to `[]`. `capability.preview.(...)` returns `host_data` (a map per the behaviour spec at `lib/parapet/recovery.ex:55`), which is merged into the preview payload. If `host_data` includes `"target_refs"`, it overrides `[]`. The shape is whatever the host capability returns — typically a list of strings (e.g., `["item-1", "item-2"]` from `recovery_test.exs:184`). `Enum.sort/1` on a homogeneous list of strings is safe; on a mixed-type list (e.g., `[1, "a"]`) it would still produce deterministic order but may be brittle. **Recommendation:** trust adopter-side homogeneity (the `Parapet.Recovery.execute(incident, target_refs)` callback has `any()` spec — no type enforcement), but document the canonicalization-stability assumption inline in the hash function's docstring.

**At Confirm time, where does the comparison `target_refs` come from?** From `preview_entry.target_refs` — the SAME data the hash was computed from at Preview time. **This means the hash compare is a CONSISTENCY check (preview payload not tampered with), NOT a "did the world change" check.** The "did the world change" detection is left to the host capability's `execute/2` callback if it re-validates. CONTEXT.md D-07 implies hash gating catches "target state changed since Preview" — strictly, what the implementation as specified catches is "TimelineEntry payload was rewritten between Preview and Confirm." That's a tighter scope. The planner should be explicit about this in tests + flash copy.

### Anti-Patterns to Avoid

- **Don't add a fifth catch-all `_` arm to the `case`** — Dialyzer will flag it as unreachable; the existing precedents are 4-arm.
- **Don't return strings in the public `{:short_circuited, _}` 2-tuple** — adopters and the telemetry contract module expect atoms from the frozen vocab.
- **Don't recompute the hash from the LiveView side** — the hash compare lives server-side in `confirm_runbook_step/4`. The LiveView passes only the token (already wired) and possibly the hash for round-trip integrity if D-12's hidden-form-field option is picked. The server fetches the canonical preview from TimelineEntry storage and recomputes — never trusts the LiveView-supplied hash for the gate decision.
- **Don't move the `capability.execute.(...)` call outside the `{:won, claim}` arm** — moving it before the claim defeats the claim-protection. Moving it after with no claim wraps in scope leaks execution into the conflict path.
- **Don't introduce a per-test sandbox process for `Parapet.Capabilities`** — the existing setup at `test/parapet/operator_test.exs:455` resets via `Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)`. The new concurrency test needs this same reset pattern (since `ConcurrencyCase` doesn't reset capabilities, only the DB).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-node claim arbitration | Custom `GenServer` lock or distributed registry | `ClaimService.claim_action/1` with Postgres unique constraint | Database-level atomic INSERT-on-conflict + 5-min lease is already battle-tested in `Executor` and `Worker`. Postgres MVCC + `UPDATE … RETURNING` is the proven pattern. |
| Preview token storage | New `parapet_preview_tokens` table | TimelineEntry `type: "recovery_preview"` | CONTEXT.md D-05. Spine handles preview lifecycle through audit surface. |
| Hash function | Custom hash | `:crypto.hash(:sha256, _)` over `:erlang.term_to_binary/1` | `:crypto` is BEAM stdlib; cryptographic strength; canonicalizable across BEAM nodes. |
| LiveView assigns lifecycle for preview | Reactive ETS table or PubSub broadcast | The existing `@detail.derived.active_preview` derivation from `incident_detail/1` | `WorkbenchContract.find_active_preview/1` already filters expired previews. Calling `incident_detail(id)` after Confirm re-derives the right state. |
| Multi-node test rendezvous | Custom `:gen_event` or message-bus harness | `Task.async` + `send(parent, {:ready, ...})` + `:go` broadcast | Verbatim from `executor_concurrency_test.exs:54-74`. Established harness. |

**Key insight:** Every primitive Phase 25 needs already exists in the codebase. The work is dispatch wiring, not invention.

## Common Pitfalls

### Pitfall 1: Forgetting the String→Atom Short-Circuit Reason Mapping

**What goes wrong:** `confirm_runbook_step/4` returns `{:short_circuited, "circuit_breaker_tripped"}` (string) and adopters' pattern matches on `:breaker_open` (atom) silently fail.

**Why it happens:** CONTEXT.md treats the frozen vocab as a property of `ClaimService` — it isn't; it's a property of `Parapet.Telemetry.RecoveryAction`. The two surfaces have different vocabularies today.

**How to avoid:** Implement a private `map_short_circuit_reason/1` function in `lib/parapet/operator.ex` (see Pattern 3 table). Cover at least `"already_resolved"`, `"already_investigating"`, `"already_open"`, `"circuit_breaker_tripped"`, `"suppressed"`. Plan-phase decides the fallback policy: pass-through-as-atom (risky), `:internal_error` sentinel, or `raise`.

**Warning signs:** Unit-test assertion `assert {:short_circuited, :incident_resolved} = ...` fails with a string in the second slot.

### Pitfall 2: Hash Computed Before `host_data` Merge

**What goes wrong:** Preview payload's `target_refs` defaults to `[]` at `operator.ex:758`. If the planner computes `target_refs_hash` against the default and THEN merges `host_data` over it at `:771-772`, the hash reflects `[]` while the stored `target_refs` reflects the host's actual list. Confirm-side recomputes against the stored `target_refs` and gets a different hash → permanent `:target_refs_drift` short-circuit, blocking every Confirm.

**Why it happens:** The merge order in `compute_preview/3` is non-obvious; the `host_data` merge is one line below the base_preview construction.

**How to avoid:** Compute the hash on the FINAL `target_refs` value, **after** `Map.merge(base_preview, host_data_str)` at `:772`. Either:
- (A) Move the `Map.merge` first, then build the hash, then `Map.put` it in, OR
- (B) Compute `final_target_refs = host_data["target_refs"] || []` first, build the base_preview with that and the hash already in, then merge non-target_refs host_data keys.

**Warning signs:** Confirm-time hash test fails for every Preview that includes non-empty host-data `target_refs`.

### Pitfall 3: Demo App Not in `mix test` Default Path

**What goes wrong:** Planner writes LiveView edits in `examples/demo_app/lib/...` but adds tests only in `test/parapet/...`. The library test suite passes; the demo's LiveView edits are unverified.

**Why it happens:** `mix.exs:37` sets `elixirc_paths(:test) = ["test/support", "lib"]` — the demo app is **not** compiled by the library's test command. It's a separate Mix project under `examples/demo_app/` with its own `mix.exs` and `deps: [{:parapet, path: "../.."}]`.

**How to avoid:** Plan-phase explicitly include either (a) a LiveView test under `examples/demo_app/test/` (running via `cd examples/demo_app && mix test`), or (b) make the operator-API tests cover the 4 return-tuple cases at the library level and treat the LiveView edits as compile-checked only. Recommendation: do (b) — the LiveView is reference adopter UI, not the contract surface; the contract is `Parapet.Operator.confirm_runbook_step/4`'s return shape.

**Warning signs:** Plan-phase has a task to edit `operator_detail_live.ex` but no corresponding test task.

### Pitfall 4: `Parapet.Capabilities` Agent Not Reset Between Concurrency Test and Other Tests

**What goes wrong:** The concurrency test registers a recovery capability, takes a Preview, races two Confirms. The Agent state persists across tests because `ConcurrencyCase` only resets DB tables, not the `Parapet.Capabilities` Agent. A later test inheriting state may produce flakes.

**Why it happens:** `concurrency_case.ex:23-29` calls `ConcurrencyBootstrap.reset!()` which TRUNCATEs the DB tables but does NOT touch `Parapet.Capabilities` (which lives in an Agent, not Postgres).

**How to avoid:** In the new `confirm_concurrency_test.exs`, add inside `unboxed_run`:
```elixir
Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)
```
before the `register_recovery(...)` call. This mirrors `test/parapet/operator_test.exs:455`. Add to `on_exit` as well.

**Warning signs:** Test ordering matters; suite passes solo but fails when run with `--seed 0` or in interleaved order.

### Pitfall 5: `target_refs_hash` Coercion of Atom vs String Keys

**What goes wrong:** `compute_preview/3` at `:771` stringifies the host_data keys (`for {k, v} <- host_data, into: %{}, do: {to_string(k), v}`) — but the VALUES inside `target_refs` are untouched. If the host capability returns `target_refs: [:atom1, :atom2]` (atoms) vs `target_refs: ["string1", "string2"]` (strings), the hash differs by representation. Round-tripping through JSON-storage (TimelineEntry payload is `jsonb` per the spine schema at `concurrency_bootstrap.ex:77`) would coerce atoms to strings, so the **store-then-rehydrate path silently changes the hash**.

**Why it happens:** Postgres `jsonb` doesn't preserve Elixir atom type — atoms serialize as strings. The Preview-side hash is over the in-memory term; the Confirm-side reads from DB and gets stringified values; `:erlang.term_to_binary([:foo])` ≠ `:erlang.term_to_binary(["foo"])`.

**How to avoid:** Canonicalize `target_refs` to all-strings BEFORE hashing, on both Preview and Confirm sides. Easiest: `Enum.map(target_refs, &to_string/1) |> Enum.sort()` before the `:erlang.term_to_binary` step. Document this in the hash function's docstring as the canonicalization invariant.

**Warning signs:** Unit test with atom `target_refs` like `[:item_a, :item_b]` passes; round-tripped-through-DB test with the same atoms fails on `:target_refs_drift`.

### Pitfall 6: `confirm_mitigation` Handler — `phx-value-token` Form Field Encoding

**What goes wrong:** The existing `confirm_mitigation` handler at `operator_components.ex:387-394` passes `phx-value-token={preview.preview_token}` — a single hex string. If the planner picks D-12's "hidden form field" option for `target_refs_hash`, the planner must add `phx-value-target-refs-hash={...}` to the same button. Phoenix LiveView's `phx-value-*` attributes normalize dashes to underscores in the `handle_event` params map (so `phx-value-target-refs-hash` arrives as `%{"target-refs-hash" => "..."}` — note the **dash**, not underscore).

**Why it happens:** Phoenix preserves the dash; only the `phx-value-` prefix is stripped.

**How to avoid:** Use a single-word param name: `phx-value-targethash={...}` (arrives as `%{"targethash" => "..."}`), OR pattern-match with the dash explicitly: `%{"step" => step, "incident_id" => id, "token" => token, "target-refs-hash" => hash}`. Recommend the LiveView-assigns option instead (D-12's other choice) — keep the round-trip server-side and avoid the params-key footgun.

**Warning signs:** LiveView crash on `function_clause` for the `handle_event` head, or the hash arriving as `nil` from `params["target_refs_hash"]`.

## Runtime State Inventory

> N/A — Phase 25 is greenfield wiring within an existing module. No rename, refactor of public identifiers, or migration involved. All edits are additive (new code paths in existing functions, new files for new tests). The only "old" thing being changed is the single return value `{:error, :stale_preview}` → `{:short_circuited, :preview_expired}` at `lib/parapet/operator.ex:736`.

**Existing references to `:stale_preview` that MUST be updated:**

| File | Line | Action |
|------|------|--------|
| `lib/parapet/operator.ex` | 736 | Replace return value: `{:error, :stale_preview}` → `{:short_circuited, :preview_expired}` |
| `test/parapet/operator_test.exs` | 524 | Update assertion to match new return: `assert {:short_circuited, :preview_expired} = Operator.confirm_runbook_step(...)` |

**Verified via grep** — only these two references exist in the live codebase. (A third hit in `.claude/worktrees/agent-acdda881769b94477/lib/parapet/operator.ex:736` is a worktree artifact and not part of the live tree.)

**Stored TimelineEntry payloads (existing previews):** The Phase 25 hash field is additive — `find_recent_preview/3` must handle missing `target_refs_hash` for previews written before the Phase 25 deploy. Plan-phase should treat absent `target_refs_hash` in a stored preview as "skip the hash gate" (backward-compatible), NOT as `:target_refs_drift`. This is a one-line `if hash != nil and hash != computed_hash do ...` guard.

## Code Examples

### Example 1: Operator confirm path with 4-arm wrapper (the central edit)

**Source: derived from `lib/parapet/automation/executor.ex:29-47` template + `lib/parapet/operator.ex:707-737` existing structure.**

```elixir
# lib/parapet/operator.ex — inside confirm_runbook_step/4, replacing :707-737
if DateTime.compare(preview_entry.expires_at, DateTime.utc_now()) == :gt do
  cond do
    target_refs_drifted?(preview_entry, capability, incident, step) ->
      {:short_circuited, :target_refs_drift}

    not is_function(capability.execute, 2) ->
      {:error, :capability_no_execute_callback}

    true ->
      case Parapet.Automation.ClaimService.claim_action(
             incident_id: incident.id,
             action_kind: "operator",
             action_key: to_string(step_id_atom),
             breaker_step_id: step_id_atom,
             idempotency_key: payload.idempotency_key
           ) do
        {:won, claim} ->
          case capability.execute.(incident, preview_entry.target_refs) do
            {:ok, exec_result} ->
              Parapet.Automation.ClaimService.mark_executed(claim)
              timeline_attrs = %{
                type: "recovery_confirmed",
                payload: %{
                  "step_id" => to_string(step_id_atom),
                  "capability" => to_string(capability_id),
                  "result" => inspect(exec_result)
                }
              }
              audit_attrs = build_audit("operator_confirm_recovery", payload)
              Evidence.run_operator_command(
                incident_changeset: Ecto.Changeset.change(incident, %{}),
                timeline_attrs: timeline_attrs,
                audit_attrs: audit_attrs
              )

            {:error, reason} ->
              {:error, reason}
          end

        {:short_circuited, _claim, reason_string} ->
          {:short_circuited, map_short_circuit_reason(reason_string)}

        {:conflicted, claim} ->
          {:conflicted, claim.id}

        {:error, reason} ->
          {:error, reason}
      end
  end
else
  {:short_circuited, :preview_expired}
end
```

### Example 2: String→Atom Mapper

```elixir
# lib/parapet/operator.ex — new private function
defp map_short_circuit_reason("already_resolved"), do: :incident_resolved
defp map_short_circuit_reason("already_investigating"), do: :incident_resolved
defp map_short_circuit_reason("already_open"), do: :incident_resolved  # safety; shouldn't occur
defp map_short_circuit_reason("circuit_breaker_tripped"), do: :breaker_open
defp map_short_circuit_reason("suppressed"), do: :incident_resolved  # operator path doesn't use suppression; defensive
defp map_short_circuit_reason(_other), do: :internal_error  # fallback — plan-phase decides
```

### Example 3: target_refs_hash function

```elixir
# lib/parapet/operator.ex — new private function
defp target_refs_hash(target_refs) do
  target_refs
  |> List.wrap()
  |> Enum.map(&to_string/1)  # canonicalize: jsonb store roundtrips atoms→strings (see Pitfall 5)
  |> Enum.sort()
  |> :erlang.term_to_binary()
  |> then(&:crypto.hash(:sha256, &1))
  |> Base.encode16(case: :lower)
end
```

### Example 4: New LiveView 4-arm handler

```elixir
# examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex — replacing :123-142
def handle_event("confirm_mitigation", %{"step" => step, "incident_id" => incident_id, "token" => token}, socket) do
  incident = DemoApp.Repo.get!(Parapet.Spine.Incident, incident_id)
  payload = %Parapet.Operator.ActionPayload{
    actor: "operator_ui",
    reason: "Confirmed mitigation from UI",
    correlation_id: Ecto.UUID.generate(),
    action_type: :execute_mitigation,
    idempotency_key: Ecto.UUID.generate()
  }

  case Parapet.Operator.confirm_runbook_step(incident, step, token, payload) do
    {:ok, _result} ->
      {:noreply,
       socket
       |> put_flash(:info, "Mitigation confirmed and executed")
       |> assign(incident: Parapet.Operator.incident_detail(incident_id))}

    {:short_circuited, reason} ->
      {:noreply,
       socket
       |> put_flash(:warning, short_circuit_flash(reason))
       |> assign(incident: Parapet.Operator.incident_detail(incident_id))}

    {:conflicted, _claim_id} ->
      {:noreply,
       socket
       |> put_flash(:warning, "Another node is executing this recovery — refresh to see the outcome")
       |> assign(incident: Parapet.Operator.incident_detail(incident_id))}

    {:error, reason} ->
      {:noreply, put_flash(socket, :error, "Confirmation failed: #{inspect(reason)}")}
  end
end

defp short_circuit_flash(:preview_expired), do: "Preview expired — please re-Preview before confirming"
defp short_circuit_flash(:incident_resolved), do: "Incident already resolved — no action needed"
defp short_circuit_flash(:breaker_open), do: "Circuit breaker open — recovery temporarily disabled"
defp short_circuit_flash(:target_refs_drift), do: "Target state changed since Preview — please re-Preview"
```

(Re-Preview button: the existing affordance at `operator_components.ex:319-321` (`phx-click="preview_mitigation" phx-value-step={step.id} phx-value-incident_id={...}`) is still rendered from the runbook card when the preview is gone — verified at `operator_detail_live.ex:187-189` (`@detail.derived.active_preview` gate). No new button needed; the existing Preview button reappears once `find_active_preview` returns nil. The flash message is the operator-actionable nudge.)

### Example 5: Multi-node Concurrency Test Skeleton (derived from `executor_concurrency_test.exs`)

```elixir
defmodule Parapet.Operator.ConfirmConcurrencyTest do
  use Parapet.TestSupport.ConcurrencyCase, async: false

  import Ecto.Query
  alias Parapet.Operator
  alias Parapet.Operator.ActionPayload
  alias Parapet.Spine.{ActionClaim, Incident, TimelineEntry}

  defmodule ConcurrencyRunbook do
    use Parapet.Runbook
    step(:op_step, type: :mitigation, capability: :retry_async_item, target_kind: "async_item")
  end

  @tag :unboxed
  test "two operators racing Confirm produce one execution and one conflict" do
    Application.put_env(:parapet, :automation, max_executions: 3, within: 3600)
    Application.put_env(:parapet, :operator_test_pid, self())

    on_exit(fn ->
      Application.delete_env(:parapet, :automation)
      Application.delete_env(:parapet, :operator_test_pid)
      Application.delete_env(:parapet, :repo)
    end)

    {incident, preview_token} =
      unboxed_run(fn ->
        ConcurrencyBootstrap.reset!()
        # CRITICAL: reset the Capabilities Agent — ConcurrencyCase does NOT do this
        Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)

        Parapet.Capabilities.register_recovery(:retry_async_item,
          name: "Retry Async Item",
          target_kind: "async_item",
          preview: fn _incident, _step -> {:ok, %{"target_refs" => ["item-1"]}} end,
          execute: fn _incident, _refs ->
            if pid = Application.get_env(:parapet, :operator_test_pid) do
              send(pid, {:executed, node()})
            end
            Process.sleep(75)
            {:ok, :executed}
          end
        )

        {:ok, incident} =
          %Incident{}
          |> Incident.changeset(%{
            title: "Operator-confirm race",
            correlation_key: "corr-operator-race",
            runbook_data: %{"module" => to_string(ConcurrencyRunbook)}
          })
          |> ConcurrencyRepo.insert()

        preview_payload = %ActionPayload{
          actor: "operator_ui",
          reason: "Preview",
          correlation_id: "corr-preview",
          action_type: :preview_mitigation
        }

        {:ok, %{preview: preview}} = Operator.preview_runbook_step(incident, :op_step, preview_payload)
        {incident, preview["preview_token"]}
      end)

    parent = self()

    contenders =
      for _ <- 1..2 do
        Task.async(fn ->
          unboxed_run(fn ->
            payload = %ActionPayload{
              actor: "operator_ui",
              reason: "Confirm",
              correlation_id: "corr-confirm-#{System.unique_integer([:positive])}",
              idempotency_key: "operator_confirm_#{incident.id}_op_step",
              action_type: :execute_mitigation
            }
            send(parent, {:ready, self()})
            receive do
              :go -> Operator.confirm_runbook_step(incident, :op_step, preview_token, payload)
            end
          end)
        end)
      end

    for _ <- 1..2, do: assert_receive {:ready, _pid}, 1_000
    Enum.each(contenders, fn task -> send(task.pid, :go) end)
    results = Enum.map(contenders, &Task.await(&1, 5_000))

    assert Enum.count(results, &match?({:ok, _}, &1)) == 1
    assert Enum.count(results, &match?({:conflicted, _}, &1)) == 1

    # Exactly one execution observed
    assert_receive {:executed, _node}, 1_000
    refute_receive {:executed, _node}, 200

    # The conflict's claim_id matches the winner's row
    [{:conflicted, conflicted_claim_id}] = Enum.filter(results, &match?({:conflicted, _}, &1))

    unboxed_run(fn ->
      claim = ConcurrencyRepo.get(ActionClaim, conflicted_claim_id)
      assert claim.status == "executed"
      assert claim.action_kind == "operator"
      assert claim.action_key == "op_step"
    end)
  end
end
```

## State of the Art

| Old Approach (today) | New Approach (Phase 25) | When Changed | Impact |
|----------------------|-------------------------|--------------|--------|
| `confirm_runbook_step/4` calls `capability.execute.(...)` directly with no claim | Wraps `capability.execute.(...)` inside `ClaimService.claim_action/1` `{:won, claim}` arm | Phase 25 | Operator path now multi-node-safe; matches Oban auto-execution path |
| `{:error, :stale_preview}` on expired preview | `{:short_circuited, :preview_expired}` on expired preview | Phase 25 | Additive variant; existing `{:error, _}` pattern matches still work for other errors |
| No drift detection between Preview and Confirm | `target_refs_hash` consistency check | Phase 25 | Catches preview-payload tampering / rewrite races |
| LiveView 2-arm `case` (`{:ok, _}` / `{:error, _}`) | LiveView 4-arm `case` (+ `:short_circuited` and `:conflicted`) | Phase 25 | UX renders operator-actionable next steps for both new branches |

**Deprecated / outdated:**
- The internal short-circuit reason strings in `ClaimService` (`"already_resolved"`, `"circuit_breaker_tripped"`, `"suppressed"`) are NOT deprecated — they remain internal to `ClaimService` and continue serving the `Executor` / `Worker` callers unchanged. Phase 25 adds a string→atom mapper at the Operator boundary; the underlying vocab stays as-is per CONTEXT D-17.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The "five-arm case" referred to in CONTEXT.md D-02 is actually **four arms** in the existing precedents (`executor.ex:29-47` and `worker.ex:37-63`). Plan-phase should use four arms; adding a fifth catch-all `_` would trigger a Dialyzer "pattern can never match" warning. | Pattern 1 | Plan produces dead code; lint warnings; minor rework. [VERIFIED: read both files] |
| A2 | `ClaimService` emits internal short-circuit reasons as STRINGS, not atoms. The operator path needs a private string→atom mapper. | Pattern 3 / Pitfall 1 | Public 2-tuple variants ship with strings instead of frozen-vocab atoms; downstream telemetry contract test would fail. [VERIFIED: read `claim_service.ex:163`, `circuit_breaker.ex:35`] |
| A3 | `claim.id` is `:binary_id` (UUID string), not integer. CONTEXT.md's "integer/UUID" notation is correctly noncommittal but the planner should lock the spec at `String.t()` or similar. | Pattern 2 / Summary | Wrong spec; mostly cosmetic. [VERIFIED: `action_claim.ex:27`] |
| A4 | `target_refs` shape is assumed homogeneous (list of strings or list of atoms after stringification). Mixed types untested. | Pitfall 5 / Example 3 | If a host capability emits mixed-type `target_refs`, hashing may surprise. Mitigation: canonicalize to strings before hashing. |
| A5 | The hash gate is a "payload tamper detection," NOT a "world state changed" detection. The CONTEXT.md flash copy `"Target state changed since Preview"` is slightly misleading — what's actually detected is preview-payload rewrite between Preview and Confirm. | Pattern 4 | Adopter expectation mismatch. Plan-phase may want to tighten flash copy ("Preview data integrity check failed — please re-Preview") or accept the looser semantic. |
| A6 | Demo app is NOT in `mix test` default path; planner must explicitly decide whether LiveView edits get a test under `examples/demo_app/test/` or are compile-checked only. Recommended: library-level operator-API tests cover the contract; LiveView edits are compile-checked. | Pitfall 3 | LiveView regressions silently slip past CI. |
| A7 | The Re-Preview affordance reuses the existing `preview_mitigation` button on the runbook card (visible when `active_preview` is nil). No new button needed. The flash is the operator-actionable nudge. | Example 4 | If the planner adds a Re-Preview button inside the `preview_panel` itself, it would render while a preview IS still active and confuse the UX. |
| A8 | Opportunistic telemetry emit (D-16) for `:short_circuited` and `:conflicted` is trivially cheap (≤8 lines per site, calling `:telemetry.execute/3` directly). RECOMMENDED to emit in Phase 25. Defer `:previewed` / `:confirmed` / `:executed` span (which needs `:telemetry.span/3` wiring + duration capture) to Phase 26. | Summary / D-16 | Phase 26 inherits less work; Phase 25 emit-sites get exercised by the four-arm test cases for free. |

**Note for discuss-phase / planner:** A1, A2, A5 are MEDIUM-IMPACT corrections to the CONTEXT.md narrative. A3, A4, A6, A7 are LOW-IMPACT clarifications. A8 is a discretionary recommendation.

## Open Questions

1. **Should `:already_investigating` map to `:incident_resolved` or a new vocab atom?**
   - What we know: `claim_service.ex:163` returns `"already_investigating"` for incidents in `"investigating"` state. The frozen `@short_circuit_reasons` vocab has no `:incident_investigating` atom — only `:incident_resolved`, `:breaker_open`, `:preview_expired`, `:target_refs_drift`.
   - What's unclear: In the operator's hands, an incident in "investigating" state is STILL actionable (the operator-claim is being made). The state gate at `claim_service.ex:162-163` may be wrong for the operator path — investigating may need to be a `:ok` state, not a short-circuit. The Operator's own `mark_investigating` (`operator.ex:316`) moves incidents to "investigating" — so `confirm_runbook_step` on an investigating incident is the standard flow.
   - Recommendation: Plan-phase explicitly decide. Options: (A) map `"already_investigating"` to `:incident_resolved` and accept the semantic stretch; (B) propose a vocab amendment to Phase 23 (out-of-scope per D-17); (C) gate the state check to only short-circuit on `"resolved"`, not `"investigating"` — but this is a `ClaimService` edit (out-of-scope per CONTEXT). Cleanest in-scope answer: option (A); flag for Phase 26 follow-up to refine the vocab.

2. **Backward compatibility for previews written before Phase 25 deploy.**
   - What we know: `target_refs_hash` is a new payload field. Existing TimelineEntry rows under `type: "recovery_preview"` have no `target_refs_hash`.
   - What's unclear: After deploy, existing previews would fail the new hash gate if it's strict.
   - Recommendation: Treat missing `target_refs_hash` as "skip the hash gate" (one-line nil-guard). Adopters get a one-window grace period for in-flight previews; after 5 minutes (the existing expiry), all previews have rotated through the new compute path. Document this in the implementation.

3. **`incident.id` lock-step with `claim.incident_id`.**
   - What we know: `Incident` uses `:binary_id` (UUID); `ActionClaim` has `belongs_to(:incident, Incident, type: :binary_id)` at `action_claim.ex:43`. So both are UUIDs.
   - What's unclear: When the operator calls `claim_action(incident_id: incident.id, ...)`, is `incident.id` already a UUID string at that callsite? The incident comes via `DemoApp.Repo.get!(Parapet.Spine.Incident, incident_id)` in the LiveView (`operator_detail_live.ex:124`).
   - Recommendation: Trust the existing path; the same pattern works in `Executor.perform/1` (`executor.ex:25-29`) and uses raw `incident_id` from the Oban job. No change needed.

## Environment Availability

> N/A — Phase 25 adds no external dependencies, no CLI tools, no new runtime requirements. All edits stay inside Elixir + Ecto + Phoenix LiveView + `:crypto` stdlib. The existing `mix test` + Postgres test DB already cover the new concurrency test (`ConcurrencyCase` infrastructure is already in place; same harness `executor_concurrency_test.exs` uses today).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) + Ecto SQL Sandbox |
| Config file | `test/test_helper.exs` (existing) |
| Quick run command | `mix test test/parapet/operator_test.exs` (~5 sec) |
| Full suite command | `mix test` (excludes `:unboxed` by default; include via `mix test --include unboxed`) |
| Concurrency test command | `mix test test/parapet/operator/confirm_concurrency_test.exs --include unboxed` |

**Critical detail:** The multi-node concurrency test uses `@tag :unboxed`, which `mix test` excludes by default. Plan-phase MUST include either `--include unboxed` in the CI invocation OR an alias in `mix.exs` that runs the concurrency suite. **Check `mix.exs:122-124`: `defp aliases, do: []` — empty.** Phase 25 may need a small alias addition (e.g., `mix test.concurrency`) but this is optional / Claude's discretion.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| UI-01 | Preview panel shows action name, target_kind, count, warnings before execution | unit (component compile-check + library-level preview test asserting `name` field) | `mix test test/parapet/operator_test.exs:484` | ✅ (test exists at `:484-493`; extend to assert action name field) |
| UI-02 | Confirm routes through `ClaimService.claim_action/1` with `action_kind: "operator"` | integration (multi-node concurrency test asserts claim row exists with `action_kind == "operator"`) | `mix test test/parapet/operator/confirm_concurrency_test.exs --include unboxed` | ❌ Wave 0 — new test file |
| UI-03 | 5-min expiry → `:preview_expired`; target_refs drift → `:target_refs_drift` | unit (synthetic time / payload mutation) | `mix test test/parapet/operator_test.exs` (extend existing :stale_preview test or new `preview_lifecycle_test.exs`) | ⚠️ partial — existing :stale_preview test must update return assertion; drift test is new |
| UI-04 | Confirm returns `{:short_circuited, reason}` or `{:conflicted, claim_id}` with LiveView renders | unit (operator-API return shape) + integration (concurrency test asserts conflicted shape) | `mix test test/parapet/operator_test.exs` + concurrency test above | ❌ Wave 0 — new tests for both return shapes |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/operator_test.exs test/parapet/operator/` (~10 sec; excludes unboxed)
- **Per wave merge:** `mix test --include unboxed` (full suite incl. concurrency; ~60-90 sec given existing concurrency tests)
- **Phase gate:** Full suite green + `mix verify.public_api` clean (proves `Parapet.Operator` stability tier holds + no new public API surface beyond additive return variants)

### Wave 0 Gaps

- [ ] `test/parapet/operator/confirm_concurrency_test.exs` — covers UI-02, UI-04 (multi-node + return shape)
- [ ] Either:
  - [ ] Extend `test/parapet/operator_test.exs` recovery describe (currently :466-541) with new tests for `:preview_expired`, `:target_refs_drift`, `{:conflicted, _}` shape, `{:short_circuited, :incident_resolved}` shape — covers UI-03, UI-04
  - [ ] OR create `test/parapet/operator/preview_lifecycle_test.exs` with the same coverage (CONTEXT D-15 — plan-phase picks)
- [ ] Update existing test at `test/parapet/operator_test.exs:524` — assertion changes from `{:error, :stale_preview}` → `{:short_circuited, :preview_expired}`
- [ ] Compile-check the LiveView edits via `mix compile --warnings-as-errors` in `examples/demo_app/` (since the demo isn't in library test paths). Recommend adding to the phase verification checklist.
- [ ] Optional: add `:short_circuited` / `:conflicted` telemetry emit assertions if D-16 lands as YES (use `:telemetry_test.attach_event_handlers/2`)

*Framework already installed; no `mix.exs` deps change needed.*

## Security Domain

> Required because `security_enforcement` is not explicitly disabled in `.planning/config.json`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | Phase 25 has no auth surface — adopter app owns operator authentication; ActionPayload `actor` field is informational |
| V3 Session Management | no | Same as V2 — LiveView session is adopter-owned |
| V4 Access Control | partial | The `ActionPayload` `actor` field carries operator identity for audit. Phase 25 doesn't add new access-control gates; relies on existing `valid_payload?/1` at `operator.ex:857-873` |
| V5 Input Validation | yes | The new `target_refs_hash` round-trip from LiveView (if D-12 chooses hidden form field option) accepts untrusted hex string; validate format (`Base.decode16/1`, length check) before comparing. If D-12 uses LiveView assigns, no untrusted-input surface added |
| V6 Cryptography | yes | SHA-256 via `:crypto.hash/2` — stdlib, never hand-rolled. Algorithm choice locked by CONTEXT D-07 |
| V7 Error Handling | yes | The string→atom mapper's fallback policy (Pattern 3) — `_other -> :internal_error` vs `_other -> raise` affects information leakage. Recommend `:internal_error` (no leak) over passing through the raw string |
| V11 Business Logic | yes | The multi-node claim race is the core business-logic safety: exactly-one execution semantics under contention. Test coverage at `test/parapet/operator/confirm_concurrency_test.exs` addresses this directly |

### Known Threat Patterns for Operator-Confirm Path

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replay of stale preview token | Tampering / Repudiation | 5-min expiry (already in place) + `target_refs_hash` consistency check (new in Phase 25) + claim service `(incident_id, action_kind, action_key)` unique constraint (already in place) |
| Concurrent operator click flood (multi-node race) | DoS / Tampering | DB-level claim via `INSERT … ON CONFLICT DO NOTHING` + 5-min lease (FND-01 from Phase 23) — exactly-one winner |
| Hash collision / forgery of `target_refs_hash` | Tampering | SHA-256 is collision-resistant for any plausible adversarial `target_refs` size; the hash is informational (consistency check), not an auth token — even if forged, the underlying claim arbitration still gates execution |
| LiveView socket replay of `confirm_mitigation` event | Tampering | Idempotency key in `ActionPayload` ensures retried events with same key are coalesced at the claim layer; LiveView itself doesn't preserve idempotency keys (each click generates a fresh UUID at `operator_detail_live.ex:130`) — accepted residual risk since CSRF is Phoenix-default-mitigated |
| Information disclosure via short-circuit reason | Information Disclosure | Frozen atom vocab + closed `short_circuit_flash/1` mapping in LiveView — no untrusted string is interpolated into user-facing copy. The fallback `:internal_error` masks unexpected internal states |

### Project Constraints (from CLAUDE.md)

No `CLAUDE.md` exists at the project root. Project-specific guidelines come from:
- `.planning/PROJECT.md` (project decisions)
- `docs/stability.md` (Stable / Experimental tier policy — Phase 25 ships under existing Experimental tier of `ClaimService` + Stable tier of `Parapet.Operator` with additive variants)
- `lib/mix/tasks/verify.public_api.ex` (public-API gate — must continue to pass; no new public API surface in Phase 25 beyond additive return tuples)

## Sources

### Primary (HIGH confidence — read directly from source)
- `lib/parapet/operator.ex` (full file) — confirm_runbook_step/4, compute_preview/3, find_recent_preview/3, all edit targets verified
- `lib/parapet/automation/claim_service.ex` (full file) — claim_action/1 return shapes, internal short-circuit reason strings (`:163`, `:170`, `:179-181`)
- `lib/parapet/automation/executor.ex` (full file) — five-arm (actually four-arm) case template
- `lib/parapet/escalation/worker.ex` (full file) — second four-arm precedent
- `lib/parapet/automation/circuit_breaker.ex` (partial) — confirmed `"circuit_breaker_tripped"` string return at `:35`
- `lib/parapet/operator/action_payload.ex` (full file) — confirmed `:execute_mitigation` requires `idempotency_key` at `:44-50`
- `lib/parapet/operator/workbench_contract.ex` (full file) — `find_active_preview/1` at `:167-206`
- `lib/parapet/telemetry/recovery_action.ex` (full file) — frozen vocabularies; no emit helpers present
- `lib/parapet/capabilities.ex` (full file) — `:binary_id` confirmed for ActionClaim; recovery struct shape
- `lib/parapet/spine/action_claim.ex` (full file) — confirmed `:binary_id` PK at `:27`
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` (full file) — 2-arm handler at `:123-142`
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` (full file) — preview_panel at `:342-403`
- `test/parapet/automation/executor_concurrency_test.exs` (full file) — concurrency harness template
- `test/parapet/automation/claim_service_test.exs` (partial) — second concurrency precedent
- `test/parapet/operator_test.exs` (partial: `:1-80`, `:410-541`) — DummyRepo + recovery describe + existing :stale_preview assertion at `:524`
- `test/support/concurrency_case.ex` (full file) — ConcurrencyCase, unboxed_run, capabilities-reset gap
- `test/support/concurrency_bootstrap.ex` (full file) — schema DDL, tables list
- `mix.exs` (full file) — confirmed deps + elixirc_paths (test excludes demo_app)
- `.planning/REQUIREMENTS.md` (UI-01..UI-04 mapping)
- `.planning/ROADMAP.md` (Phase 25 entry at `:136-149`)
- `.planning/phases/23-foundations-telemetry-contract-lease-until-migration/23-CONTEXT.md` (frozen vocabularies)
- `.planning/phases/24-recovery-behaviour-capability-allowlist/24-CONTEXT.md` (arity-2 callbacks confirmed)
- `.planning/phases/25-wire-confirm-through-claimservice-preview-confirm-ux/25-CONTEXT.md` (the spec under validation)
- Grep across `lib/`, `test/`, `examples/demo_app/` for `:stale_preview`, `target_refs`, `action_kind`, `preview_token`

### Secondary (MEDIUM confidence — single-source observation)
- `lib/parapet/operator_patch.exs` — appears to be a stray patch file with an alternate operator API shape (uses `target_refs` as a parameter to `preview_runbook_step/4` instead of the current `/3` signature). Not part of any `lib/` compilation tree (`.exs` not `.ex`). Plan-phase should ignore but be aware it exists and may confuse code-search. Recommend deleting in a separate cleanup task — out of Phase 25 scope.

### Tertiary (LOW confidence — none required)
- All claims are sourced from direct file reads. No WebSearch / WebFetch / Context7 lookups were needed; the phase is entirely internal-codebase wiring.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies in `mix.exs` directly verified; no new deps.
- Architecture: HIGH — all file paths and line numbers in CONTEXT.md verified against source.
- Pitfalls: HIGH for Pitfalls 1, 2, 4, 5; MEDIUM for Pitfall 3 (demo app test boundary — depends on planner's choice) and Pitfall 6 (depends on D-12 decision).
- String→atom mapping (Pitfall 1 / Pattern 3): HIGH — confirmed against `claim_service.ex:163`, `circuit_breaker.ex:35`. This is the most important finding the CONTEXT.md doesn't surface.
- Test infrastructure: HIGH — verified `ConcurrencyCase` only resets DB, not Capabilities Agent.

**Research date:** 2026-05-28
**Valid until:** 2026-06-27 (30 days — codebase patterns are stable; v1.0 freeze means no breaking changes upstream during this window)
