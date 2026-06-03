# Parapet prior-art canonical index

This folder contains a **small deduped mirror** of the sibling-repo prompts that materially improve Parapet planning.

The point is not to copy every prior prompt folder. The point is to keep the few docs that change Parapet design decisions close at hand.

## Included copies

### `threadline-audit-lib-domain-model-reference.md`

- Source: `~/projects/threadline/prompts/audit-lib-domain-model-reference.md`
- Why it is here:
  - strongest reusable treatment of durable evidence, operator confidence, and the separation between capture, semantics, and exploration;
  - directly relevant if Parapet grows incident bundles, evidence spines, or health surfaces beyond raw telemetry.

### `rulestead-telemetry-observability-and-audit.md`

- Source: `~/projects/rulestead/prompts/rulestead-telemetry-observability-and-audit.md`
- Why it is here:
  - strongest reusable treatment of telemetry contracts as API;
  - explicit redaction, health, diagnostics, and audit separation patterns;
  - highly relevant to Parapet’s event model and operator surfaces.

### `chimeway-host-app-integration-seam.md`

- Source: `~/projects/chimeway/prompts/chimeway-host-app-integration-seam.md`
- Why it is here:
  - concise statement of the embedded-library boundary;
  - useful for keeping Parapet host-owned rather than sliding into control-plane behavior.

### `rulestead-release-engineering-and-ci.md`

- Source: `~/projects/rulestead/prompts/rulestead-release-engineering-and-ci.md`
- Why it is here:
  - strongest compact reference for your modern Elixir OSS release and CI posture;
  - the default release-engineering template Parapet should inherit.

## Not copied on purpose

- The shared generic Elixir/Phoenix best-practice research set exists in several sibling repos and is heavily duplicated.
- Large engineering-DNA docs from sibling libs are useful, but Parapet now has a dedicated synthesis in `prompts/parapet-engineering-dna-from-sibling-libs.md`.
- Brand books or deeply product-specific docs for other libs were excluded unless they materially change Parapet planning.

## How to use this folder with GSD

Usually you should attach:

- `prompts/PARAPET-GSD-IDEA.md`
- `prompts/parapet-engineering-dna-from-sibling-libs.md`
- `prompts/parapet-integration-opportunities.md`
- `prompts/sre-observability-elixir-lib-deep-reseach.md`

Then optionally attach this index so the agent can pull in the mirrored prior art when helpful without bloating the first prompt.
