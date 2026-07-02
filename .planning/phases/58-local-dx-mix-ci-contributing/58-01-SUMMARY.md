---
phase: 58-local-dx-mix-ci-contributing
plan: 01
subsystem: infra
tags: [mix-alias, ci, dialyzer, contributing, github-actions]

# Dependency graph
requires: []
provides:
  - "mix ci alias with 8 portable fail-fast steps mirroring CI lint gate"
  - "dialyzer plt_file config for Phase 59 PLT caching"
  - "/priv/plts/*.plt* gitignore entry"
  - "lint-once single-run CI job replacing matrixed lint job"
  - "CONTRIBUTING.md single mix ci instruction + three local-vs-CI deltas documented"
affects: [59-dialyzer-plt-cache, ci-yml, mix-exs, contributing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "mix alias as single source of truth for portable gate steps — local alias and CI call same entrypoint"
    - "lint-once non-matrixed CI job pattern — dialyzer runs once, not 3x across OTP versions"
    - "Local vs CI deltas documented in CONTRIBUTING — expected-delta framing prevents false regression reports"

key-files:
  created: []
  modified:
    - mix.exs
    - .gitignore
    - .github/workflows/ci.yml
    - CONTRIBUTING.md

key-decisions:
  - "8-step alias uses flat list (no sub-grouping, no wrapper script) — mix aliases are inherently sequential and fail-fast on first non-zero exit"
  - "credo --strict flag kept (not bare credo) — .credo.exs sets strict: false so omitting it weakens local gate below CI"
  - "format --check-formatted kept (not bare format) — bare format silently reformats instead of failing"
  - "lint-once uses single elixir 1.19.0 / otp 28.x — running dialyzer 3x across OTP matrix is waste with no signal benefit"
  - "Two CI-only steps stay inline in lint-once (not a separate job) — cleaner diff, no extra job overhead"
  - "plt_file uses {:no_warn, ...} tuple — suppresses first-run PLT-does-not-exist warning"

patterns-established:
  - "mix ci is the canonical local proof command — dev setup verification and pre-push both use it"
  - "Three expected deltas (docs build, operator-UI diff, public schema prefix) framed as not-regressions in CONTRIBUTING"

requirements-completed: [DX-01, DX-02, DX-03]

coverage:
  - id: D1
    description: "mix ci alias exists with 8 portable steps in exact order with exact flags"
    requirement: DX-01
    verification:
      - kind: other
        ref: "mix help ci — shows alias with all 8 steps; mix format --check-formatted mix.exs passes"
        status: pass
    human_judgment: false
  - id: D2
    description: "dialyzer config has plt_file and plt_add_apps keys; /priv/plts/*.plt* in .gitignore"
    requirement: DX-01
    verification:
      - kind: other
        ref: "grep checks: plt_file, plt_add_apps in mix.exs; /priv/plts/*.plt* in .gitignore"
        status: pass
    human_judgment: false
  - id: D3
    description: "lint-once CI job replaces matrixed lint; mix ci gate step present; both CI-only deltas retained; needs lists updated"
    requirement: DX-02
    verification:
      - kind: other
        ref: "python3 yaml.safe_load structural assertion: lint-once present, lint absent, mix ci step present, docs+diff steps present, needs lists correct"
        status: pass
    human_judgment: false
  - id: D4
    description: "CONTRIBUTING.md instructs mix ci before pushing and documents all three local-vs-CI deltas"
    requirement: DX-03
    verification:
      - kind: other
        ref: "grep checks: mix ci, mix docs, operator-UI/manifest, PARAPET_SCHEMA_PREFIX/schema prefix all present; bare mix credo removed"
        status: pass
    human_judgment: false

# Metrics
duration: 3min
completed: 2026-07-02
status: complete
---

# Phase 58 Plan 01: Local DX mix ci + CONTRIBUTING Summary

**`mix ci` alias wires 8 portable fail-fast steps as single source of truth shared by local dev and CI lint-once job, with CONTRIBUTING documenting the three expected local-vs-CI deltas**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-02T22:10:18Z
- **Completed:** 2026-07-02T22:12:56Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Populated `aliases/0` in mix.exs with `ci: [...]` 8-step fail-fast list mirroring exact invocation strings from ci.yml lint job (format --check-formatted, compile --warnings-as-errors, compile --no-optional-deps --warnings-as-errors, credo --strict, hex.audit, dialyzer, test, verify.public_api)
- Added dialyzer `plt_file: {:no_warn, "priv/plts/project.plt"}` alongside existing `plt_add_apps` (Phase 59 PLT cache seam) and `/priv/plts/*.plt*` to .gitignore
- Replaced 3x-OTP-matrixed `lint` CI job with single-run `lint-once` that calls `mix ci` for the portable set, retaining both CI-only deltas (mix docs --warnings-as-errors, operator-UI manifest diff) inline; updated `demo.needs` and `release_gate.needs` to `lint-once`
- Rewrote CONTRIBUTING.md to single `mix ci` proof command, added "Local vs CI deltas" section naming all three expected deltas, updated dev-setup verification to `mix ci`

## Task Commits

Each task was committed atomically:

1. **Task 1: Populate ci mix alias + dialyzer PLT prerequisites** - `0d4fd56` (feat)
2. **Task 2: Replace matrixed lint job with lint-once** - `cdc220d` (chore)
3. **Task 3: Rewrite CONTRIBUTING.md** - `794041a` (docs)

## Files Created/Modified

- `/Users/jon/projects/parapet/mix.exs` - Added `ci:` alias with 8 steps; expanded `dialyzer:` config to two keys; fixed pre-existing format violation in `package/0`
- `/Users/jon/projects/parapet/.gitignore` - Added `/priv/plts/*.plt*` near mix artifact ignores with explanatory comment
- `/Users/jon/projects/parapet/.github/workflows/ci.yml` - lint → lint-once, OTP matrix dropped, 8 portable steps → single `mix ci` gate, two CI-only deltas retained, both needs lists updated
- `/Users/jon/projects/parapet/CONTRIBUTING.md` - "Local proof commands" section rewritten to `mix ci`; "Local vs CI deltas" section added; dev-setup trailing command updated to `mix ci`

## Decisions Made

- Kept `--strict` on credo step (not bare `credo`): .credo.exs has `strict: false`, so omitting it makes the local gate weaker than CI
- Kept `--check-formatted` on format step (not bare `format`): bare format silently reformats instead of failing
- lint-once uses a single OTP version (28.x): running dialyzer 3x across the matrix provides no signal benefit and wastes CI time; Phase 59 PLT cache also targets a single build
- Two CI-only delta steps stay inline in lint-once (not a separate job): cleaner diff, simpler DAG

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed pre-existing mix format violation in mix.exs**
- **Found during:** Task 1 verification (`mix format --check-formatted mix.exs`)
- **Issue:** The `files:` key in `defp package/0` had a multi-line split (`files:\n ~w(...)`) that mix formatter collapses to one line (`files: ~w(...)`). This pre-existed before Task 1.
- **Fix:** Ran `mix format mix.exs` to correct the pre-existing violation so the format check passes
- **Files modified:** mix.exs
- **Verification:** `mix format --check-formatted mix.exs` now passes
- **Committed in:** `0d4fd56` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - pre-existing format violation)
**Impact on plan:** Minor cosmetic fix required for the plan's own acceptance criterion (`mix format --check-formatted mix.exs` passes). No scope creep.

## Issues Encountered

None beyond the pre-existing format violation documented above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 59 (dialyzer PLT cache) prerequisites are now in place: `plt_file: {:no_warn, "priv/plts/project.plt"}` in mix.exs and `/priv/plts/*.plt*` in .gitignore
- The `mix ci` alias is live and runnable; contributors can immediately use it as the local proof command
- CI DAG is correct: lint-once → demo → release_gate, lint-once → test → release_gate

## Threat Mitigations Applied

| Threat ID | Mitigation Confirmed |
|-----------|----------------------|
| T-58-01 | Exact flags (`--check-formatted`, `--strict`, `--warnings-as-errors`) pinned in alias; acceptance criteria + automated grep assert them |
| T-58-02 | Both `release_gate.needs` and `demo.needs` updated to `lint-once`; YAML assertion confirms no `needs:` references bare `lint` |
| T-58-03 | All three deltas named in CONTRIBUTING.md; grep check asserts all three are present |

---
*Phase: 58-local-dx-mix-ci-contributing*
*Completed: 2026-07-02*
