# Phase 21: Runnable Demo App - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-25
**Phase:** 21-runnable-demo-app
**Mode:** assumptions
**Areas analyzed:** Demo App Structure, Seeding Strategy, CI Gate Design, Hex Exclusion & Docs Link, Demo App Auth

## Assumptions Presented

### Demo App Structure & Phoenix Setup (DEMO-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Standalone committed Phoenix app at `examples/demo_app/` with path dep on parapet; real app so `mix parapet.gen.ui` can introspect it | Confident | `mix.exs:42` files whitelist; `mix parapet.gen.ui` resolves `web_module`/`repo_module` from host app |
| `mix setup` runs deps.get → ecto.create → ecto.migrate → seeds.exs | Likely | ROADMAP success criterion 1; `Parapet.Evidence.repo/0` reads `Application.get_env(:parapet, :repo)` |
| Phoenix version `~> 1.7` | Likely | `mix parapet.gen.ui` templates use `use MyAppWeb, :live_view` + verified routes (Phoenix 1.7+ feature) |

### Seeding Strategy (DEMO-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Seeds use Stable `Parapet.Evidence.*` API (create_incident/1, append_timeline/2, log_tool_audit/1) — not direct Spine schema inserts | Likely | `Parapet.Evidence` is Stable; Spine schemas are Experimental/`@doc false`; phase goal = CI contract test of frozen surface |
| `warning:` step seeded as static JSON map in `incident.runbook_data` — not a live `use Parapet.Runbook` module invocation | Likely | `lib/parapet/spine/incident.ex:47` has `runbook_data: :map`; `Parapet.Runbook.__runbook_schema__/0` produces the map shape seeds must write |

### CI Gate Design (DEMO-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `demo` job added to existing `.github/workflows/ci.yml`; `release_gate` job with `needs: [test, demo]` | Likely | Existing `ci.yml` has only `test`; separate workflow wouldn't be a required branch-protection check on PRs without extra config |
| Smoke test uses `Phoenix.ConnTest` (no running server) — `mix test --only smoke` | Unclear → **User selected: Phoenix.ConnTest** | User confirmed this approach |

### Hex Exclusion & Docs Link (DEMO-04)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `examples/demo_app/` already excluded by `files:` allowlist — no `mix.exs` change needed | Confident | `mix.exs:42` allowlist doesn't include `examples/` |
| Getting-started guide link added to existing "Next steps" section | Confident | `docs/getting-started.md` already has a "Next steps" section with 3 bullets |

### Demo App Auth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Open routes (no auth) with `# WARNING: demo only` comment | Confident | `mix parapet.gen.ui` says "Parapet does not provide its own auth"; auth breaks DEMO-03 smoke test |

## Corrections Made

No corrections — all assumptions confirmed by user.

## External Research

Two topics flagged; one resolved by user selection:

- **Smoke test mechanism:** `Phoenix.ConnTest` — **User selected** (confirmed over `curl`/`phx.server` approach)
- **Phoenix version:** Left to Claude's discretion during planning research (`~> 1.7` defaulted; planner to confirm latest stable)
