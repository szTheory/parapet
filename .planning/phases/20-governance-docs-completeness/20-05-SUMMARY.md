---
phase: 20-governance-docs-completeness
plan: 05
subsystem: mix-configuration
tags: [mix.exs, hex-packaging, hexdocs, governance, docs-navigation]

requires:
  - 20-01 (CONTRIBUTING.md + SECURITY.md created at repo root)
  - 20-03 (four integration guide .md files created in docs/integrations/)
  - 20-04 (slo-reference anchor for slo-authoring cross-link resolves)
provides:
  - mix.exs package/0 files: whitelist ships CONTRIBUTING.md and SECURITY.md
  - mix.exs docs/0 main: "getting-started" — getting-started is hexdocs landing page
  - mix.exs docs/0 extras: includes all 8 integration guides (4 existing + 4 new)
  - mix.exs docs/0 groups_for_extras: four-group structure (Getting Started / Guides / Integration Guides / Reference)
affects:
  - mix.exs
  - Hex package file manifest (mix hex.build)
  - hexdocs navigation and landing page

tech-stack:
  added: []
  patterns:
    - "Explicit file lists for 3 groups + single regex only for Integration Guides (avoids capture overlap Pitfall 6)"
    - "Governance doc globs in Hex files: whitelist (CONTRIBUTING*, SECURITY*, CODE_OF_CONDUCT*)"
    - "ExDoc main: bare stem without path/extension (D-04)"

key-files:
  created: []
  modified:
    - mix.exs (package/0 files:, docs/0 main:, docs/0 extras:, docs/0 groups_for_extras:)

key-decisions:
  - "CODE_OF_CONDUCT* glob added to files: whitelist even though CODE_OF_CONDUCT.md was dropped in 20-01 (user decision) — glob is harmless when file absent; consistent with D-07"
  - "Explicit file lists used for Getting Started, Guides, Reference groups; regex only for Integration Guides — prevents Pitfall 6 regex capture overlap"
  - "pre-existing mix test --warnings-as-errors failures (unused var, deprecated SLO.define/2, deprecated EEx <%#) are out-of-scope — existed before this plan"

patterns-established:
  - "groups_for_extras: four-group structure is the canonical nav for hexdocs extras"

requirements-completed: [GOV-05, DOCS-06]

duration: ~9min
completed: 2026-05-25
---

# Phase 20-05: mix.exs Wiring (GOV-05 + DOCS-06) Summary

**Hex package ships governance docs via files: whitelist; hexdocs serves four grouped extras with getting-started as the landing page**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-05-25T14:27:01Z
- **Completed:** 2026-05-25T14:36:00Z
- **Tasks:** 3/3
- **Files modified:** 1 (mix.exs)

## Accomplishments

1. **Task 1 (GOV-05):** Added `CONTRIBUTING*`, `SECURITY*`, `CODE_OF_CONDUCT*` globs to `package/0` `files:` sigil list. `mix hex.build` confirms `CONTRIBUTING.md` and `SECURITY.md` ship with the package.
2. **Task 2 (DOCS-06 part 1):** Changed `main: "readme"` to `main: "getting-started"` (bare stem, D-04). Added all four new integration guide paths to `extras:` — chimeway.md, mailglass.md, rindle.md, scoria.md.
3. **Task 3 (DOCS-06 part 2):** Replaced single `[Guides: ~r/docs\//]` with four-group structure: Getting Started, Guides, Integration Guides (regex), Reference. `mix docs --warnings-as-errors` builds clean.

## Task Commits

1. **Task 1: Hex files: whitelist** - `26a258a` (feat)
2. **Task 2: main: + extras additions** - `a8d89fd` (feat)
3. **Task 3: groups_for_extras restructure** - `a137733` (feat)

## Files Created/Modified

- `mix.exs` — four targeted edits: `files:` sigil, `main:`, `extras:` list (+4 entries), `groups_for_extras:` (replaced entirely)

## Verification Results

| Check | Result |
|-------|--------|
| `grep "CONTRIBUTING\* SECURITY\* CODE_OF_CONDUCT\*" mix.exs` | PASS |
| `mix hex.build` lists CONTRIBUTING.md + SECURITY.md | PASS |
| `grep 'main: "getting-started"' mix.exs` | PASS |
| All 4 new integration guides in extras: | PASS |
| `grep '"Integration Guides": ~r|docs/integrations/|' mix.exs` | PASS |
| `grep '"Getting Started":' mix.exs` | PASS |
| `grep 'Reference:' mix.exs` | PASS |
| `mix docs --warnings-as-errors` | PASS (0 warnings) |
| `mix test` | PASS (352 tests, 0 failures) |

## Deviations from Plan

### Pre-existing Issues (Out of Scope)

**1. [Out of Scope] `mix test --warnings-as-errors` fails due to pre-existing warnings**
- **Found during:** Task 3 verification
- **Issue:** Three pre-existing warning classes cause `mix test --warnings-as-errors` to abort: unused variable `pid` in `native_scheduler_test.exs:22`, unreachable clause in `probe_test.exs:14`, deprecated `Parapet.SLO.define/2` in `parapet.doctor_test.exs:145`, deprecated EEx `<%#` syntax in a template
- **Confirmed pre-existing:** Verified by stashing Task 3 changes and running `mix test --warnings-as-errors` — same failure occurred before this plan's edits
- **Fix:** Out of scope for this plan. Tracked in deferred-items.
- **Impact on plan:** None — all three plan requirements (GOV-05, DOCS-06) are verified; `mix docs --warnings-as-errors` and functional test suite (`mix test`) both pass

**2. [Known from 20-01] `CODE_OF_CONDUCT.md` not present**
- **Found during:** Task 1 verification (`mix hex.build` shows `Missing files: CODE_OF_CONDUCT*`)
- **Issue:** `CODE_OF_CONDUCT.md` was dropped in plan 20-01 per user decision (content filter issue). The `CODE_OF_CONDUCT*` glob is correctly in `files:` per D-07, but the file is absent.
- **Fix:** Not a fix — intentional per prior plan decision. GOV-03 requirement was dropped. The glob is harmless when no matching file exists.
- **Impact:** CONTRIBUTING.md and SECURITY.md ship correctly; CODE_OF_CONDUCT.md does not exist to ship (accepted).

## Known Stubs

None — all changes are configuration wiring, not data stubs.

## Threat Flags

No new security-relevant surface introduced. The `files:` whitelist change only adds named governance doc globs (T-20-05 mitigated — no broadening beyond the three named globs). No new network endpoints, auth paths, or schema changes.

---

## Self-Check: PASSED

- `mix.exs` modified: FOUND
- Commit `26a258a`: FOUND
- Commit `a8d89fd`: FOUND
- Commit `a137733`: FOUND
- `mix docs --warnings-as-errors`: EXIT 0 (verified above)

---

*Phase: 20-governance-docs-completeness*
*Completed: 2026-05-25*
