---
phase: 04-unified-install-path-dx
plan: 01
subsystem: dx
tags: [igniter, installer, phoenix, prometheus]
requires: []
provides:
  - Unified `mix parapet.install` paved-road orchestration
  - Explicit UI and delivery integration opt-in flags
  - End-of-run installer trust summary
affects: [doctor, docs, operator-ui]
tech-stack:
  added: []
  patterns: [generator-composition, host-owned-install]
key-files:
  created: []
  modified:
    - lib/mix/tasks/parapet.install.ex
    - test/mix/tasks/parapet.install_test.exs
    - test/parapet_test.exs
key-decisions:
  - "The installer now composes `parapet.gen.spine` before base wiring and `parapet.gen.prometheus` after it."
  - "Optional UI, Mailglass, and Chimeway paths stay explicit opt-ins behind flags."
patterns-established:
  - "Compose smaller generators instead of duplicating their internals."
  - "Installer-generated activation code stays host-owned and visible in config/instrumenter output."
requirements-completed: [DX-01]
duration: 20m
completed: 2026-05-20
---

# Phase 04: Unified Install Path Summary

**`mix parapet.install` is now the single Day-1 entrypoint, with ordered generator composition, explicit extras flags, and a trust-oriented completion notice.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-20T21:15:00Z
- **Completed:** 2026-05-20T21:45:17Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Turned `mix parapet.install` into a real orchestrator that composes the spine, base wiring, and Prometheus generators in the intended order.
- Added explicit `--with-ui`, `--skip-ui`, `--with-mailglass`, and `--with-chimeway` switches while keeping optional activation host-owned.
- Added regression coverage for composition order, explicit extras, provider wiring, and the end-of-run summary notice.

## Task Commits

Each task was completed in the working tree:

1. **Task 1: Expand the installer CLI contract and compose the core paved-road flow** - not committed in this run (dirty worktree preserved)
2. **Task 2: Gate UI and optional integrations explicitly, then emit the end-of-run trust summary** - not committed in this run (dirty worktree preserved)

**Plan metadata:** not committed in this run

## Files Created/Modified

- `lib/mix/tasks/parapet.install.ex` - unified installer orchestration, explicit extras, and summary notice
- `test/mix/tasks/parapet.install_test.exs` - contract tests for composition order, flags, and notices
- `test/parapet_test.exs` - compile-out cleanliness proof for explicit Mailglass/Chimeway activation

## Decisions Made

- Kept optional provider activation in generated host files instead of mutating `mix.exs`.
- Reused the UI generator and its auth-boundary notice instead of folding UI internals into the installer.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** None.

## Issues Encountered

- No plan-specific code issue remained after implementation. Phase commits were intentionally not created because the repo already contained unrelated in-progress changes and this run preserved that dirty worktree.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The installer contract is documented and verified, so doctor and docs can depend on a stable Day-1 command.
- README and operator UI docs can now describe the exact public flags and follow-up flow.

---
*Phase: 04-unified-install-path-dx*
*Completed: 2026-05-20*
