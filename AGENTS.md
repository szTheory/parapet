# Agent Guidance

## Default Posture

- Use a recommendation-first, codebase-first planning and execution posture by default.
- Treat `.planning/config.json` `workflow.discuss_mode = "assumptions"` as the repo's default interactive posture.
- Auto-decide low-impact implementation details and state assumptions in the artifact instead of asking routine questions.

## Escalate Only For

- Changes to a public CLI/API contract.
- Changes to default install contents.
- Changes to auth ownership.
- Changes to the dependency/support surface.
- Changes to runtime behavior.
- Changes to safety guarantees.
- Changes to operator semantics.
- Changes to the durable evidence truth model.
- Irreversible schema or maintenance burden.
- Cases where two medium-impact concerns move at once.

## Boundaries

- Keep this guidance narrow: it centralizes planning posture and escalation thresholds only.
- Do not treat this file as authority to widen product scope, milestone status claims, or runtime guarantees.
