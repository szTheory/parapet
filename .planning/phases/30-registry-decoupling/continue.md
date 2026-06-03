# Continue — Phase 30: Registry Decoupling

## Last action
We completed a massive ad-hoc UI iteration for the Operator UI (Industrial Zen design system, Tailwind shadows, tabular-nums, active:scale-[0.96]). We also completely finalized the Docker DX for local development (parameterized ports, named volumes for _build/deps, Makefile) in the demo app. We officially started the **v1.2 Authoring DX & Maturity** milestone and updated `PROJECT.md` and `STATE.md`.

## Next action
The next step is to begin **Phase 30: Registry Decoupling**.
You need to refactor `Parapet.SLO` to move its state off the `Application.put_env` / `Application.get_env` environment and into a dedicated Agent or ETS table (similar to how `Parapet.Capabilities` works).
1. Review `.planning/threads/slo-state-off-application-env.md` if it exists.
2. Implement the dedicated registry.
3. Ensure all tests in `test/parapet/` pass without isolation issues.

## Why
This was flagged as technical debt in v1.0.1. Storing dynamic registry state in `Application.put_env` causes test isolation bleeding and is not idiomatic. It must be decoupled before we build the Igniter SLO generator in Phase 31.

## Open threads
- The demo app is configured and ready. We added a `Makefile` and `docker-compose.yml`.

## Do not
- Do NOT focus on Team Workflow or PagerDuty integration—the user explicitly set that as "Out of Scope" (Solo Entrepreneur target audience).
- Do NOT rebuild the UI—that is fully polished and done.