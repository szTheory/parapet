---
phase: 26
slug: audit-propagation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-28
---

# Phase 26 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| host capability → operator audit payload | The adopter-supplied `execute/2` closure returns `exec_result` (success) or `reason` (error). | Untrusted opaque terms serialized into the `output`/payload maps (`output: :map`, `payload: :map` JSONB). |
| operator-supplied input → audit identity | `payload.actor` (operator URN) crosses into the durable TimelineEntry/ToolAudit rows. | Operator identity URN; `validate_required` + `validate_not_blank` upstream in `ActionPayload.changeset/2`. |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-26-01 | Tampering | `exec_result` / `reason` injected into audit `output`/payload maps | mitigate | `inspect/1` term-normalization before storage; values land in `:map`/JSONB fields (DB-layer escaping, no SQL interpolation). Verified `operator.ex:753,759,784,791`; `tool_audit.ex:21`, `timeline_entry.ex:34`. | closed |
| T-26-02 | Information Disclosure | Stack trace leaking into `recovery_failed` payload via `inspect(reason)` | mitigate | Rescue normalizes exceptions to `{:capability_raised, Exception.message(e)}` — message string only, no `__STACKTRACE__`. Verified `operator.ex:738-739`. | closed |
| T-26-03 | Repudiation | Operator denies having confirmed a recovery action | mitigate | `payload.actor` (operator URN) written into BOTH TimelineEntry payload and ToolAudit `input`, in success AND failure arms. Verified `operator.ex:750,780`; `build_audit/2` at `operator.ex:1045`. | closed |
| T-26-04 | Tampering (audit suppression) | Failure-path audit write silently dropped if DB write fails | accept | Best-effort write: result discarded via `_ =` (`operator.ex:803`) with a `rescue _ -> :ok` guard (`operator.ex:810-812`) so `{:error, reason}` return contract is preserved (`operator.ex:816-817`). See Accepted Risks Log. | closed |
| T-26-SC | Tampering (supply chain) | hex/npm/pip/cargo package installs | n/a | Phase 26 adds NO dependencies and NO `mix.lock` churn (confirmed: no `mix.lock` change in phase commits). No supply-chain checkpoint required. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

No HIGH-severity unmitigated threats. ASVS L1 relevant category is V5 (Input Validation), satisfied by `validate_required`/`validate_not_blank` on `payload.actor` and `inspect/1` term-serialization on opaque results.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-26-01 | T-26-04 | The failure-arm `run_operator_command/1` result is intentionally discarded (best-effort) so the original `{:error, reason}` return contract is preserved (D-06/D-11). A lost failure-audit row during a DB outage is accepted: the capability error still surfaces to the operator, and the success path propagates DB errors normally. Low value / low likelihood; no PII beyond the operator URN already in scope. Implementation is in fact stronger than planned — a `rescue _ -> :ok` also swallows DB-connection exceptions. | szTheory (solo maintainer) | 2026-05-28 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-28 | 5 | 5 | 0 | gsd-security-auditor (verify mitigations; plan-time register) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-28
