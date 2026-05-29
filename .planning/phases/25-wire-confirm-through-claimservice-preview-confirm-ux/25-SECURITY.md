---
phase: 25
slug: wire-confirm-through-claimservice-preview-confirm-ux
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-29
---

# Phase 25 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| LiveView socket → Operator API | Operator-confirmed `phx-click="confirm_mitigation"` events cross from a browser-controlled socket into server-side `Parapet.Operator.confirm_runbook_step/4`. | `step`, `incident_id`, `token` (hex). Payload, hash, capability resolution are server-side. |
| Operator API → ClaimService | Third caller of `ClaimService.claim_action/1` (after Executor and Escalation.Worker). Internal Elixir boundary; pre-validated by ActionPayload + `valid_payload?/1`. | ActionPayload struct (server-built). |
| Operator API → Adopter pattern matching | Return shape of `confirm_runbook_step/4` is part of the Stable public surface; adopters pattern-match the tuple. | `{:ok,_}` / `{:short_circuited, atom}` / `{:conflicted, claim_id}` / `{:error,_}`. Only frozen-vocab atoms may cross. |
| LiveView render → adopter UI | Flash strings are user-visible; the `{:conflicted,_}` string is contractually pinned by ROADMAP success criterion #2. | Operator-facing flash text. |
| Test harness → production code | Tests exercise `confirm_runbook_step/4` directly and simulate multi-node contention within one BEAM; production semantics rest on the Postgres unique constraint (FND-01). | Synthetic test fixtures only. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-25-01 | Tampering | Preview-token replay across stale incident state | mitigate | 5-min expiry gate `operator.ex:767` → `{:short_circuited, :preview_expired}`; ClaimService incident-state gate `claim_service.ex:200-204` → mapped to `:incident_resolved` at `operator.ex:996-1001` | closed |
| T-25-02 | Tampering | TimelineEntry payload rewrite between Preview and Confirm | mitigate | Hash-mismatch gate `operator.ex:771-775` → `{:short_circuited, :target_refs_drift}`; SHA-256 over canonicalized list `operator.ex:1043-1050` (`Enum.map(&to_string/1) \|> Enum.sort()`) | closed |
| T-25-03 | Information Disclosure | Internal ClaimService reason strings leaking into adopter `{:short_circuited,_}` 2-tuple | mitigate | `map_short_circuit_reason/1` (`defp`) closed clauses; fallback `_other -> :internal_error` at `operator.ex:996-1001` never returns raw string | closed |
| T-25-04 | Repudiation / Tampering | Two operators racing Confirm — both executing same recovery | mitigate | `claim_service.ex:108-112` `insert_all` `on_conflict: :nothing, conflict_target: [:incident_id, :action_kind, :action_key]`; loser wrapped to `{:conflicted, claim.id}` at `operator.ex:939-949` | closed |
| T-25-05 | DoS | Operator click flood from multi-node UI | accept | 5-min `lease_until` (`claim_service.ex:26`, Phase 23 FND-01) self-heals stuck claims; idempotency_key (`action_payload.ex:52-55`) coalesces retries. No new rate-limiting in scope. | closed |
| T-25-06 | Tampering / Spoofing | Adopter passes forged `target_refs_hash` via LiveView round-trip | mitigate | Server fetches hash from DB (`operator.ex:765`) and recomputes from `preview_entry.target_refs` (`operator.ex:771-773`); LiveView-supplied hash never trusted. Confirm button sends only step/incident_id/token (`operator_components.ex:391-394`) | closed |
| T-25-SC | Tampering | Supply chain — package installs | mitigate (N/A) | Phase 25 adds zero new packages; no `mix.exs`/`mix.lock` churn | closed |
| T-25-LV-01 | Information Disclosure | Unknown `:short_circuited` reason atom leaking via `inspect`/interpolation | mitigate | `operator_detail_live.ex:141` delegates to `Parapet.Operator.UI.short_circuit_flash/1` (`ui.ex:37-55`): known-atom clauses + forward-compat catch-all returning a static string; no atom interpolation, no `inspect/1` | closed |
| T-25-LV-02 | Tampering | Browser-supplied `target_refs_hash` round-trip via `phx-value-*` | mitigate | Hash not round-tripped; Confirm button sends only step/incident_id/token (`operator_components.ex:391-394`); server recomputes from canonical TimelineEntry storage | closed |
| T-25-LV-03 | Spoofing | LiveView event from unauthenticated session | accept | Adopter app owns operator authentication; ActionPayload `actor` is informational only. Phase 25 adds no access-control gates. | closed |
| T-25-LV-04 | Information Disclosure | Capability name leaking PII into the Action cell | accept | Capability names are adopter-controlled strings (`register_recovery/2 :name`); PII is an adopter-side concern. Documented in adopter docs (Phase 29 ADOP-03). | closed |
| T-25-LV-SC | Tampering | Supply chain — package installs | mitigate (N/A) | Demo app `mix.exs` unchanged in Phase 25 | closed |
| T-25-T-01 | Tampering | Test ordering causes `Parapet.Capabilities` Agent state leak across tests | mitigate | `confirm_concurrency_test.exs:62` resets Agent (`fn _ -> %{recovery: %{}} end`) inside `unboxed_run` before `register_recovery`; `on_exit` (`:48-51`) cleans Application env | closed |
| T-25-T-02 | Repudiation | Flaky concurrency test passes once but fails under load | mitigate | Deterministic Postgres unique-constraint arbitration; verified by 3 consecutive seed-varied runs (seeds 1, 2, 3) all passing | closed |
| T-25-T-03 | Information Disclosure | Test fixture `target_refs` containing PII | accept | Fixtures are synthetic (`item-1`, `tampered-ref`, etc.); no real-data exposure | closed |
| T-25-T-SC | Tampering | Supply chain — package installs | mitigate (N/A) | ExUnit is BEAM stdlib; no `mix.lock` churn | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-25-01 | T-25-05 | Operator click flood self-heals via 5-min `lease_until` (FND-01) + idempotency-key coalescing; per-operator rate-limiting deemed out of scope for the library. | szTheory | 2026-05-29 |
| AR-25-02 | T-25-LV-03 | Operator authentication is owned by the adopter application; `actor` is informational. Parapet intentionally adds no access-control gates. | szTheory | 2026-05-29 |
| AR-25-03 | T-25-LV-04 | Capability `:name` strings are adopter-authored; PII handling is an adopter responsibility, documented for adopters (Phase 29 ADOP-03). | szTheory | 2026-05-29 |
| AR-25-04 | T-25-T-03 | Test fixtures use only synthetic identifiers; no real data is present in the test tree. | szTheory | 2026-05-29 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-29 | 16 | 16 | 0 | gsd-security-auditor (sonnet) |

**Deviation note (2026-05-29):** T-25-LV-01's mitigation was implemented in plan 25-02 as a local 4-clause `short_circuit_flash/1` in `operator_detail_live.ex`, then later refactored (commit 7737945) to delegate to the shared `Parapet.Operator.UI.short_circuit_flash/1`, which adds a forward-compatible catch-all clause. Both forms are equally safe — no raw atom or internal string ever reaches flash output. Mitigation verified present at its current location.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-29
