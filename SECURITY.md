# Security Policy

## Reporting a Vulnerability

Report security vulnerabilities via **GitHub Private Vulnerability Reporting**:

<https://github.com/szTheory/parapet/security/advisories/new>

**Do not open a public GitHub issue for security vulnerabilities.** Public issues expose the vulnerability before a fix is available, putting adopters at risk.

## Disclosure Timeline

- **Acknowledgement:** within 3 business days of report receipt.
- **Initial assessment:** within 7 business days — we will confirm whether the report is a valid vulnerability and communicate our initial findings.
- **Fix or mitigation:** coordinated with the reporter; we target 90 days for critical issues and will communicate progress throughout.
- **Public disclosure:** after a fix is available, coordinated with the reporter. We follow responsible disclosure — we will not publish details before a patch is ready.

## Supported Versions

The latest released minor is the supported line. Security fixes are applied to the current release only; older minor versions do not receive backports.

| Version | Supported |
|---------|-----------|
| 1.x (latest) | Yes |
| < 1.0 | No |

---

## Phase 25 Audit — wire-confirm-through-claimservice-preview-confirm-ux

**Audit Date:** 2026-05-29
**ASVS Level:** L1
**Block On:** high
**Threats Closed:** 16/16

### Threat Verification

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-25-01 | Tampering | mitigate | CLOSED | `operator.ex:767` — expiry gate `DateTime.compare != :gt` → `{:short_circuited, :preview_expired}`; `claim_service.ex:200-204` — `incident_state_gate/2` emits `"already_#{state}"` mapped to `:incident_resolved` at `operator.ex:996-1001`. |
| T-25-02 | Tampering | mitigate | CLOSED | `operator.ex:771-775` — hash mismatch gate → `{:short_circuited, :target_refs_drift}`; `operator.ex:1043-1050` — `target_refs_hash/1` canonicalizes via `Enum.map(&to_string/1) |> Enum.sort()` before SHA-256. |
| T-25-03 | Information Disclosure | mitigate | CLOSED | `operator.ex:996-1001` — `map_short_circuit_reason/1` is `defp`; fallback `_other -> :internal_error` never returns raw string. No public function exposes internal ClaimService reason strings. |
| T-25-04 | Repudiation/Tampering | mitigate | CLOSED | `claim_service.ex:108-112` — `insert_all` with `on_conflict: :nothing, conflict_target: [:incident_id, :action_kind, :action_key]`; `operator.ex:939-949` wraps loser to `{:conflicted, claim.id}`. |
| T-25-05 | DoS | accept | CLOSED | Rationale plausible: 5-min `lease_until` (`claim_service.ex:26`) self-heals floods; `ActionPayload.idempotency_key` (`action_payload.ex:52-55`) coalesces retries. |
| T-25-06 | Tampering/Spoofing | mitigate | CLOSED | `operator.ex:765` — `find_recent_preview/3` fetches hash from DB; `operator.ex:771-773` recomputes from `preview_entry.target_refs`. `operator_detail_live.ex:123` accepts only `step/incident_id/token`. `operator_components.ex:391-394` — Confirm button sends only `phx-value-step`, `phx-value-incident_id`, `phx-value-token`; no hash param. |
| T-25-SC | Tampering | mitigate (N/A) | CLOSED | `mix.exs` deps and `mix.lock` unchanged across phase 25 commits (`c325d63`, `4444d52`, `5712754`, `a7558f3`, `88ea82a`). |
| T-25-LV-01 | Information Disclosure | mitigate | CLOSED | `operator_detail_live.ex:141` — delegates to `Parapet.Operator.UI.short_circuit_flash/1`. `operator/ui.ex:37-55` — 5 known-atom clauses plus catch-all at line 54 returns static string with no atom interpolation or `inspect/1`. Unknown atoms do not surface in flash output. |
| T-25-LV-02 | Tampering | mitigate | CLOSED | `operator_components.ex:391-394` — Confirm button sends only `phx-value-step`, `phx-value-incident_id`, `phx-value-token`. No hash or target_refs param. Server recomputes from DB-sourced preview entry. |
| T-25-LV-03 | Spoofing | accept | CLOSED | Rationale plausible: operator auth is adopter-owned; `actor` is informational only; no access-control gate was in scope. |
| T-25-LV-04 | Information Disclosure | accept | CLOSED | Rationale plausible: capability names are adopter-controlled strings; PII exposure is adopter-side concern (ADOP-03, Phase 29). |
| T-25-LV-SC | Tampering | mitigate (N/A) | CLOSED | Demo app `mix.exs` not modified in phase 25 commits. No new packages. |
| T-25-T-01 | Tampering | mitigate | CLOSED | `confirm_concurrency_test.exs:62` — `Agent.update(Parapet.Capabilities, fn _ -> %{recovery: %{}} end)` inside `unboxed_run` before `register_recovery`; `on_exit` at line 48-51 cleans Application env. `operator_test.exs:527` — same reset in recovery execution `setup`. |
| T-25-T-02 | Repudiation | mitigate | CLOSED | Deterministic Postgres unique-constraint arbitration (`claim_service.ex:108-112`). Phase 25-03 SUMMARY verification table confirms 3 consecutive seed-varied runs (seeds 1, 2, 3) all exited 0. |
| T-25-T-03 | Information Disclosure | accept | CLOSED | Rationale plausible: fixtures use synthetic strings only (`"item-1"`, etc.). No PII in test code. |
| T-25-T-SC | Tampering | mitigate (N/A) | CLOSED | No new packages; ExUnit is BEAM stdlib. No `mix.lock` churn in phase 25 commits. |

### Unregistered Flags

None.

### Accepted Risks Log

| ID | Disposition | Rationale |
|----|-------------|-----------|
| T-25-05 | accept | 5-min lease self-heals click floods; idempotency_key coalesces retries; no rate-limiting in scope. |
| T-25-LV-03 | accept | Operator auth is adopter-owned; `actor` is informational; no access-control gate in scope. |
| T-25-LV-04 | accept | Capability names are adopter-controlled; PII in names is adopter-side concern (ADOP-03 / Phase 29). |
| T-25-T-03 | accept | Test fixtures are synthetic strings only. |

### Notes

T-25-LV-01 design evolution: The phase 25-02 implementation delivered a local private `short_circuit_flash/1` with 4 closed clauses and no catch-all as declared. A subsequent milestone-audit fix (commit 7737945) refactored the LiveView to delegate to `Parapet.Operator.UI.short_circuit_flash/1`, which adds a forward-compat catch-all returning a safe static string. This does not weaken the non-leakage invariant — the unknown atom is never interpolated or passed to `inspect/1`.
