# Interactive GSD new-project — Parapet

Use this path when you want **deep questioning** plus GSD’s research subagents, instead of the `--auto` path.

**Repo root:** `/Users/jon/projects/parapet`

**Preconditions:** run this from a clean context window. If `.planning/` already exists later, use `$gsd-progress` instead of re-initializing.

## First message to send

Paste this in a clean session from the Parapet repo root:

```text
/gsd-new-project

@prompts/PARAPET-GSD-IDEA.md
@prompts/parapet-engineering-dna-from-sibling-libs.md
@prompts/parapet-integration-opportunities.md
@prompts/sre-observability-elixir-lib-deep-reseach.md
```

Recommended optional attachments if the context window has room:

```text
@prompts/parapet-brand-identity-deep-research.md
@prompts/elixir-telemetry-space-deep-research.md
@prompts/sre-best-practices-solo-founder-deep-research.md
@prompts/prior-art/SOURCE-CANONICAL.md
```

## How to answer the early GSD questions

When GSD asks what you want to build, answer roughly like this:

> Use the attached Parapet prompts as the baseline product definition. Ask follow-ups focused on the unresolved decisions in `PARAPET-GSD-IDEA.md`, especially the v0.1 wedge, install story, durable-evidence posture, first user journeys, and which sibling-lib integrations belong in the initial roadmap.

## Recommended workflow preferences

- **Research:** Yes
- **Plan check:** Yes
- **Verifier:** Yes
- **Model quality:** Quality or Balanced, depending on how expensive you want the bootstrap to be

Parapet is a design-heavy OSS library with real operator and product tradeoffs. Skipping research is usually the wrong call.

## Recommended research framing

If GSD asks whether to research first, choose **Research first**.

The research should validate:

- the narrowest credible Parapet wedge;
- the best initial reliability journeys;
- how much of the product should be telemetry-first vs DB-backed evidence;
- whether the admin/operator surface belongs in v0.1 or later;
- which sibling integrations are first-class from the start.

## After `$gsd-new-project` completes

Run:

```text
/gsd-plan-phase 1
```

Likely first-phase direction:

- lock the telemetry and evidence contract;
- choose the first journey slices;
- define the install and integration posture.

## Terminal fallback

```bash
cd /Users/jon/projects/parapet
git init   # if needed
gsd-sdk init @prompts/PARAPET-GSD-IDEA.md
```

The interactive slash workflow is still the better path because it keeps the questioning and research loop intact.
