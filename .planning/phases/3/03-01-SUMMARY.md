---
phase: "3"
plan: 1
subsystem: api
tags: [prometheus, mcp, req]

# Dependency graph
requires: []
provides:
  - "Read-only Prometheus API proxy using Req via Parapet.MCP.PrometheusClient"
affects: [mcp-agent]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hardcoded PromQL queries parameterized safely to prevent injection"
    - "Req plug option overriding for HTTP client testing"

key-files:
  created:
    - "lib/parapet/mcp/prometheus_client.ex"
    - "test/parapet/mcp/prometheus_client_test.exs"
  modified: []

key-decisions:
  - "Used Req.request options to inject dummy plugs for testing the HTTP requests instead of introducing Bypass or explicit mocks."
  - "Parameterization of metric names strips all non-alphanumeric/underscore/colon characters to sanitize input safely."

patterns-established:
  - "Prometheus HTTP API interaction: Use Req to query Prometheus via `/api/v1/query` with pre-defined templates."

requirements-completed: ["MCP-03"]

# Metrics
duration: 5min
completed: 2026-05-14
---

# Phase 3 Plan 1: Parapet.MCP.PrometheusClient Summary

**Read-only Prometheus API proxy using Req with sanitized metric names for safe Copilot access**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-14T00:00:00Z
- **Completed:** 2026-05-14T00:05:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Implemented `Parapet.MCP.PrometheusClient.get_slo_burn_rate/2` to query predefined time-series metrics.
- Added strict metric name sanitization to prevent PromQL injection attacks.
- Configured Req request options support to easily inject test plugs for robust ExUnit tests.

## Task Commits

Each task was committed atomically:

1. **Task 0: Create the test scaffolding for Parapet.MCP.PrometheusClient** - `166adaa` (test)
2. **Task 1: Implement Parapet.MCP.PrometheusClient** - `b3d0cd1` (feat)

_Note: TDD tasks may have multiple commits (test → feat → refactor)_

## Files Created/Modified
- `lib/parapet/mcp/prometheus_client.ex` - The Prometheus API client proxy.
- `test/parapet/mcp/prometheus_client_test.exs` - Unit tests for configuration and HTTP fetching logic.

## Decisions Made
- Used Req.request options to inject dummy plugs for testing the HTTP requests instead of introducing Bypass or explicit mocks.
- Parameterization of metric names strips all non-alphanumeric/underscore/colon characters to sanitize input safely.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Test dummy plug response lacked `content-type: application/json` which caused Req not to parse the response body; added `Plug.Conn.put_resp_content_type/2` to the dummy plug to resolve.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Ready for MCP integration to hook up specific agents or tools to the Prometheus client.

---
*Phase: 3*
*Completed: 2026-05-14*