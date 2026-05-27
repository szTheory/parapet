---
phase: 19-api-telemetry-freeze
plan: "03"
subsystem: documentation
tags: [stability, exdoc, callouts, api-freeze]
dependency_graph:
  requires: [19-01]
  provides: [stable-module-annotations]
  affects: [mix-verify-public-api, hexdocs]
tech_stack:
  added: []
  patterns: [exdoc-callout-in-moduledoc, doc-since-badge]
key_files:
  created: []
  modified:
    - lib/parapet.ex
    - lib/parapet/integration.ex
    - lib/parapet/slo/provider.ex
    - lib/parapet/slo/slice_spec.ex
    - lib/parapet/runbook.ex
    - lib/parapet/escalation/policy.ex
    - lib/parapet/notifier.ex
    - lib/parapet/evidence.ex
    - lib/parapet/operator.ex
    - lib/parapet/deploy.ex
    - lib/parapet/slo/starter_pack/web_saas.ex
    - lib/parapet/slo/starter_pack/delivery_saas.ex
    - lib/parapet/telemetry/async_delivery.ex
decisions:
  - "Applied D-01 callout block (> #### Stable {: .info}) to all 13 Stable modules"
  - "Applied D-13 @doc since: \"1.0.0\" to every public def/defmacro/@callback in the 13 modules"
  - "Partial-state recovery: 7 files were already annotated by prior crashed run; 6 were completed"
metrics:
  duration: "~30 min"
  completed: "2026-05-25"
  tasks: 2
  files: 13
---

# Phase 19 Plan 03: Stable Module Annotations Summary

Annotated all 13 Stable-tier public modules with the `> #### Stable {: .info}` ExDoc callout and `@doc since: "1.0.0"` on every public function, callback, and macro. Documentation-only changes — no behavior change to any function body or signature.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Stable callouts + @doc since on core API and SLO/telemetry contracts | 4da025a | lib/parapet.ex, lib/parapet/integration.ex, lib/parapet/slo/provider.ex, lib/parapet/slo/slice_spec.ex, lib/parapet/slo/starter_pack/web_saas.ex, lib/parapet/slo/starter_pack/delivery_saas.ex, lib/parapet/telemetry/async_delivery.ex |
| 2 | Stable callouts + @doc since on operator/evidence/runbook/notifier/escalation/deploy surface | 4da025a | lib/parapet/runbook.ex, lib/parapet/escalation/policy.ex, lib/parapet/notifier.ex, lib/parapet/evidence.ex, lib/parapet/operator.ex, lib/parapet/deploy.ex |

Note: Tasks 1 and 2 share a single atomic commit due to partial-state recovery (prior crashed run had applied Task 1 files without committing).

## Key Decisions

- D-01 callout block placed immediately after the first sentence/paragraph of each `@moduledoc`, before any `## Options` or `## Examples` section.
- D-13 `@doc since: "1.0.0"` paired with the existing `@doc` string (never standalone, per Pitfall 6). Where a public function/callback/macro had no `@doc`, a brief descriptive `@doc` was added.
- `Parapet.Notifier.broadcast/1` and `dispatch/3` annotated; `deliver_and_audit/3` left as `@doc false` (intentionally hidden).
- `Parapet.SLO.StarterPack.DeliverySaaS.delivery_slices/2` left as `@doc false` (intentionally hidden).
- `Parapet.Runbook` macros (`step/2`, `title/1`, `description/1`) annotated; `__before_compile__/1` is a compile-time callback, not a public function.

## Verification

- `mix compile --warnings-as-errors` exits 0 (no standalone `@doc since:` warnings, valid moduledoc syntax)
- All 13 files contain `#### Stable {: .info}` (grep count == 13)
- All 13 files contain at least one `@doc since: "1.0.0"`
- No function body or signature changed

## Deviations from Plan

### Partial-State Recovery

**[No Rule violation — pre-run state]**

- **Context:** A prior execution attempt crashed (transient API error) mid-run with no commits, leaving 7 of 13 files modified but uncommitted in the working tree.
- **Recovery:** Verified the 7 pre-applied files were correct (callout + `@doc since:` present and well-formed). Applied the remaining 6 files. Committed all 13 together in a single atomic commit as instructed.
- **Impact:** Single commit instead of two task-level commits; functionally equivalent.

## Known Stubs

None — all 13 Stable modules carry the full callout block. No placeholder text introduced.

## Threat Flags

None — documentation/metadata edits only. No new network endpoints, auth paths, file access patterns, or schema changes. T-19-05 (callout integrity) is mitigated: the live gate from Plan 01 will resolve all 13 modules to `:stable` once Plan 04 also lands.

## Self-Check: PASSED

- All 13 modified files exist and were staged.
- Commit 4da025a confirmed in git log.
- `mix compile --warnings-as-errors` exited clean.
- grep count of 13 confirmed for `#### Stable {: .info}`.
