# Phase 29: Stability + Adopter Onboarding - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-28
**Phase:** 29-stability-adopter-onboarding
**Mode:** assumptions
**Calibration:** minimal_decisive (USER-PROFILE vendor_philosophy: opinionated)
**Areas analyzed:** Stability Graduation + CHANGELOG (STAB-07), gen.recovery Igniter Task + Doctor Adoption Signal (ADOP-01 + ADOP-02), Adopter Guide + ExDoc Wiring (ADOP-03)

## Assumptions Presented

### Stability Graduation + CHANGELOG (STAB-07)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Graduate by flipping two anchors (moduledoc admonition + stability.md table row), freeze the 4 callbacks + `__using__/1` verbatim | Confident | `recovery.ex:16-20,30,38,47,56,59-63`; `verify.public_api.ex:104-114`; `stability.md:10-13,24-38,49` |
| CHANGELOG notes via Conventional-Commit body + `stability.md` compatibility register — NOT hand-edited CHANGELOG.md | Confident | `CHANGELOG.md:1-13,15-40`; `stability.md:144,190-198`; MEMORY (Release-Please ownership) |

### gen.recovery Igniter Task + Doctor Adoption Signal (ADOP-01 + ADOP-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `gen.recovery <NAME>` mirrors `gen.runbooks`; `positional: [:name]`, read `igniter.args.positional.name`, `copy_template/5` + `create_new_file/4` test stub | Confident (after research) | `gen.runbooks.ex:5-15,18-24,33-43`; vendored `deps/igniter/` `info.ex:68-74`, `task.ex:344-376`, `args.ex:14`, `igniter.ex:828-838,867`; `recovery_test.exs:5-11` |
| Doctor `check_recovery` static check; runbook→capability cross-check via SLO discovery (no runbook registry) | Confident | `doctor.ex:22,76-94,96-115,427-467`; `capabilities.ex:14-20,52-56,62-66`; `alert_processor.ex:116-128`; `runbook.ex:85-100` |

### Adopter Guide + ExDoc Wiring (ADOP-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `recovery-actions.md` mirrors `slo-authoring-guide.md`; ExDoc extras + groups_for_extras only (no `files:` edit); four worked examples = four capability-backed playbooks; cross-link getting-started + operator-ui | Confident | `mix.exs:43,59-80,84-92`; `slo-authoring-guide.md:1,9,39,57,137`; `operator-ui.md:179-208`; `getting-started.md:94-99`; `capabilities.ex:14-20` |

## Corrections Made

No corrections — user selected "Yes, proceed"; all assumptions confirmed as locked decisions.

## External Research

One topic flagged by the analyzer (Igniter 0.7.9 positional-arg + test-file API — no in-repo precedent, parse-time-failure risk) was resolved by a research agent reading the vendored `deps/igniter/` 0.7.9 source:
- **Required positional arg:** `positional: [:name]` in the `Info` struct (bare atom = required). Source: `deps/igniter/lib/igniter/mix/task/info.ex:68-74`; enforcement at `task.ex:344-376`.
- **Accessor:** `igniter.args.positional.name` inside `igniter/1` (args parsed into `Args` struct before `igniter/1`; `args.ex:14`). `igniter/2` is deprecated.
- **Test stub:** `Igniter.create_new_file/4` (`igniter.ex:867`, `on_exists: :skip`), or `copy_template/5` for an EEx stub.
- **Module → path:** `Igniter.Project.Module.proper_location/3` + `create_module/4` (`module.ex:25-43,144-174`), or reuse explicit lib_dir derivation from `gen.runbooks.ex`.

This bumped the gen.recovery assumption from Likely → Confident; no remaining open research topics for the planner.
