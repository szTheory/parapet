---
phase: 03-notifications
plan: 01
subsystem: notifications
tags: [elixir, oban, req, asynchronous, audit]

# Dependency graph
requires:
  - phase: 02-runbooks
    provides: [incident state management, database schema]
provides:
  - Notifier behaviour for dispatching alerts
  - Oban worker for durable, asynchronous notification delivery
  - Integration with AlertProcessor for incident lifecycle triggers
affects: [03-notifications]

# Tech tracking
tech-stack:
  added: [req (optional)]
  patterns: [behaviour-based adapters, durable async jobs with Oban, timeline auditing]

key-files:
  created: []
  modified:
    - lib/parapet/notifier.ex
    - lib/parapet/notifier/oban_worker.ex
    - lib/parapet/spine/alert_processor.ex
    - mix.exs

key-decisions:
  - "Used Oban for reliable asynchronous notification delivery, with a fallback to Task when Oban is absent."
  - "Stripped sensitive webhook URLs/data before saving the notification audit to TimelineEntry to prevent leaking secrets."

patterns-established:
  - "Pattern 1: Asynchronous delivery via dynamic behaviour module configuration."

requirements-completed: ["NOTIFY-01", "NOTIFY-04"]

# Metrics
duration: 20min
completed: 2026-05-12
---

# Phase 03: Notifications Plan 01 Summary

**Notifier behaviour implementation, Oban worker for asynchronous durable delivery, and automatic lifecycle triggers**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-12T12:00:00Z
- **Completed:** 2026-05-12T12:20:00Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Introduced `Parapet.Notifier` behaviour for robust alert delivery
- Added durable asynchronous dispatch using Oban with a Task fallback
- Added event triggers in `AlertProcessor` to automatically broadcast incident creation and resolution
- Audited all dispatch attempts in the incident timeline without exposing secrets

## Task Commits

Each task was committed atomically:

1. **Task 1: Add req dependency and Notifier behaviour** - `01b2976` (feat)
2. **Task 2: Implement Oban Worker and Timeline Audit** - `7a38015` (feat)
3. **Task 3: Integrate broadcast into alert processor** - `f79b662` (feat)

## Files Created/Modified
- `mix.exs` - Added `req` optional dependency
- `lib/parapet/notifier.ex` - Defined behaviour and dispatch logic
- `lib/parapet/notifier/oban_worker.ex` - Oban background worker
- `lib/parapet/spine/alert_processor.ex` - Triggered broadcast/1 in incident loops

## Decisions Made
- Chose to use an optional dependency for `req` to avoid bloating host apps that do not need certain integrations
- Ensured sensitive configuration details are explicitly filtered out before appending them to the timeline entry

## Deviations from Plan

None - plan executed exactly as written

## Issues Encountered
None

## Next Phase Readiness
- Foundations for notifications are in place. Ready to implement specific adapters.
