---
phase: 3
plan: 3
subsystem: mcp
tags: [http, plug, sse, json-rpc]

requires:
  - phase: 3
    provides: ["Parapet.MCP.Server for tool execution routing"]
provides:
  - "Parapet.Plug.MCP for handling JSON-RPC requests over HTTP and returning Server-Sent Events (SSE) chunks"
affects: ["host-application-integration", "ai-agents"]

tech-stack:
  added: []
  patterns: ["Plug with Chunked responses for SSE", "JSON-RPC error codes (-32601 for Method Not Found)"]

key-files:
  created: ["lib/parapet/plug/mcp.ex", "test/parapet/plug/mcp_test.exs"]
  modified: []

key-decisions:
  - "Configured DummyRepo in the test setup for `Parapet.Plug.MCPTest` to satisfy isolation during executing database-dependent MCP tools."
  - "Explicitly documented that authentication for `Parapet.Plug.MCP` is the responsibility of the host application's router pipeline."

patterns-established:
  - "Pattern 1: Plug returning SSE using `Plug.Conn.send_chunked/2` and `Plug.Conn.chunk/2` format `event: message\ndata: <json>\n\n`"

requirements-completed: ["MCP-01"]

duration: 15min
completed: 2026-05-16
---

# Phase 3: 03-03-PLAN Summary

**HTTP Plug implementing JSON-RPC via Server-Sent Events (SSE) for MCP tool execution**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-16T22:15:00Z
- **Completed:** 2026-05-16T22:30:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Implemented `Parapet.Plug.MCP` for handling POST requests with JSON-RPC.
- Supported seamless delegation to `Parapet.MCP.Server` for extracting JSON-RPC tools and arguments.
- Streamed responses as Server-Sent Events using Plug `chunk`.
- Verified 405 Method Not Allowed fallback for non-POST methods.

## Task Commits

Each task was committed atomically:

1. **Task 0: Create test scaffolding** - `f37035a` (test)
2. **Task 1: Implement Parapet.Plug.MCP** - `056732c` (feat)

## Files Created/Modified
- `lib/parapet/plug/mcp.ex` - Plug implementation for the HTTP MCP Transport
- `test/parapet/plug/mcp_test.exs` - Test coverage using `Plug.Test` for SSE and JSON-RPC compliance.

## Decisions Made
- Used the `chunk/2` return value to continuously update `conn` to align with Plug behavior instead of ignoring the response tuple.
- Relied on a locally-defined `DummyRepo` configured in `setup` in `mcp_test.exs` to avoid relying on database fixtures while still satisfying tools that query `repo`.
- Documented in `@moduledoc` that the host application handles user authentication per the Threat Model assumptions.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Returned connection properly from `Plug.Conn.chunk/2`**
- **Found during:** Task 1 (Plug implementation verification)
- **Issue:** The response `conn` wasn't matched properly in the helper `send_sse_response/2`, leading to assertions against empty response bodies in ExUnit's `Plug.Test`.
- **Fix:** Assigned `{:ok, conn} = chunk(conn, ...)` and returned the updated `conn`.
- **Files modified:** `lib/parapet/plug/mcp.ex`
- **Verification:** Ran `mix test test/parapet/plug/mcp_test.exs` returning appropriate response payloads in ExUnit.
- **Committed in:** `056732c` (part of Task 1 commit)

**2. [Rule 3 - Blocking] Configured `DummyRepo` for isolated tests**
- **Found during:** Task 1 (Plug testing)
- **Issue:** Test simulating `"list_incidents"` was blocked because `Parapet.MCP.Server` requires a configured repo `Parapet.Evidence.repo()`, crashing the test runner.
- **Fix:** Implemented and injected an inline `DummyRepo` in `mcp_test.exs` setup block.
- **Files modified:** `test/parapet/plug/mcp_test.exs`
- **Verification:** Ran test suite, failure turned to pass.
- **Committed in:** `056732c` (part of Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Improved test resiliency and correctly handled connection lifecycle for streaming.

## Issues Encountered
None - plug behaviors and ExUnit macros aligned well.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
The `Parapet.Plug.MCP` is ready to be embedded within a host application's Router to provide the agent endpoint.

## Self-Check: PASSED
