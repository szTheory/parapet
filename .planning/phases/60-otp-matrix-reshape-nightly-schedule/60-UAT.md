---
status: complete
phase: 60-otp-matrix-reshape-nightly-schedule
source: [60-01-SUMMARY.md, 60-02-SUMMARY.md]
started: 2026-07-03T01:16:03Z
updated: 2026-07-03T01:16:40Z
---

## Current Test

[testing complete]

## Tests

### 1. matrix-config resolver emits 1-cell (PR) / 4-cell (push,schedule) JSON
expected: matrix-config resolver PR branch emits 1 object; push/schedule emits 4 objects; all carry elixir/otp/schema_prefix keys
result: pass
source: automated
coverage_id: 60-01/D1

### 2. Nightly schedule trigger cron '17 3 * * *'
expected: `cron: '17 3 * * *'` present exactly once in ci.yml
result: pass
source: automated
coverage_id: 60-01/D2

### 3. OTP 26 / Elixir 1.19 retired; toolchain Elixir 1.20.2 x OTP {27,28,29}
expected: zero `1.19.0` and zero `'26.x'` tokens in ci.yml
result: pass
source: automated
coverage_id: 60-01/D3

### 4. demo is plain OTP-28 job skipped on pull_request
expected: `if: github.event_name != 'pull_request'` present; no strategy/matrix in demo job
result: pass
source: automated
coverage_id: 60-01/D4

### 5. release_gate hardened truth table (strict lint/test, case success|skipped demo)
expected: `if: always()`; strict success for lint-once + test; `case success|skipped` for demo; matrix-config in needs
result: pass
source: automated
coverage_id: 60-01/D5

### 6. actionlint reports no errors on reshaped ci.yml
expected: `actionlint .github/workflows/ci.yml` exits 0
result: pass
source: automated
coverage_id: 60-01/D6

### 7. release-please.yml publish-hex on Elixir 1.20.2 / OTP 28.x; SHA unchanged
expected: zero `1.19.0` in release-please.yml; setup-beam SHA `fc68ffb9` unchanged
result: pass
source: automated
coverage_id: 60-02/D1

### 8. README factual CI sentence names Elixir 1.20.2 x OTP 27,28,29; support matrix intact
expected: old "Elixir 1.19 across OTP 26,27,28" sentence gone; adopter `| Elixir | 1.19+ |` row intact
result: pass
source: automated
coverage_id: 60-02/D2

### 9. CONTRIBUTING.md (d) Local-vs-CI-deltas bullet present
expected: (d) bullet explains PR trimmed cell vs main+nightly full gate; names release_gate as real multi-OTP gate
result: pass
source: automated
coverage_id: 60-02/D3

### 10. PROJECT.md single canonical D-11 resolution row
expected: exactly one `RESOLVED 2026-07-02 (Phase 60 / MATRIX-02)` row; v1.7-debt Revisit resolved to Good
result: pass
source: automated
coverage_id: 60-02/D4

### 11. v1.7-MILESTONE-AUDIT.md register row 3 dated pointer; frozen body untouched
expected: `RESOLVED 2026-07-02 (Phase 60)` pointer on register row 3; frozen frontmatter + Seam-7 prose byte-untouched
result: pass
source: automated
coverage_id: 60-02/D5

### 12. MILESTONES.md D-11 row dated pointer; STATE.md concurrency line untouched
expected: `RESOLVED 2026-07-02 (Phase 60)` pointer on D-11 row; STATE.md @concurrency_hold_ms D-11 untouched
result: pass
source: automated
coverage_id: 60-02/D6

## Summary

total: 12
passed: 12
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none yet]
