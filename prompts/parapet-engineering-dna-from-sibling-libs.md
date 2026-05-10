# Parapet engineering DNA — inherited from sibling Elixir/Phoenix OSS libs

> Purpose: seed `parapet` with the repeatable engineering choices, release discipline, product posture, and operator ergonomics already paid for across your recent OSS library family.

## Reader and intended use

Reader: the maintainer or planning agent initializing Parapet.

Post-read action: start the project without re-arguing the common OSS foundation, and know which patterns are default, which are optional, and which footguns are already known.

## 1. Convergent DNA — adopt unless Parapet has a concrete reason not to

### Package and repo hygiene

- Keep a single source of truth for version in `mix.exs` via `@version`, and align docs/release metadata to it.
- Explicitly whitelist Hex package files. Never ship `.planning/`, `prompts/`, example hosts, or stray repo artifacts.
- Treat the root package as a narrow public surface. Internal modules should be explicitly internal.
- Ship the standard OSS root set: `README`, `CHANGELOG`, `LICENSE`, `CONTRIBUTING`, `SECURITY`, `CODE_OF_CONDUCT`, and a maintainer runbook.

### CI / release discipline

- Use GitHub Actions, Release Please, and Conventional Commits by default.
- Keep workflow logic scripts-first and locally reproducible.
- Keep stable CI job ids because docs and branch protection depend on them.
- Run a hard lint lane: format, compile warnings-as-errors, credo, docs warnings-as-errors, hex audit.
- Run a test matrix across supported Elixir/OTP baselines, with Postgres service containers when the library touches Ecto.
- Add post-publish verification and parity checks once publishing begins.
- Prefer SHA-pinned actions, least-privilege workflow permissions, and dependency-review style supply-chain checks.

### API and implementation posture

- Favor explicit functions, data-first APIs, and stable return shapes.
- Offer non-bang and bang variants for expected failures where it improves ergonomics.
- Prefer runtime options and explicit adapter seams over hidden global config.
- Keep optional dependencies truly optional; they must compile out cleanly and fail with structured guidance only when the related feature is enabled.
- Build a clear error model early: root error struct, typed sub-errors, closed atom categories, stable pattern-matching surface.

### Telemetry and observability posture

- Treat telemetry as public API. Event names, measurements, and metadata contracts should be deliberate and documented.
- Use `:telemetry.span/3` conventions consistently for meaningful operations.
- Redact at emission time. Do not leak PII or raw payloads into telemetry, diagnostics, or operator surfaces.
- Separate telemetry from durable audit/evidence. They solve different problems and should not collapse into one abstraction.
- Make diagnostics explainable. A maintainer should be able to answer “what happened?” from rows, events, or docs rather than folklore.

### DX / adoption posture

- Prefer host-owned generated code or highly inspectable configuration to opaque magic.
- Make the happy path short and obvious.
- Use example hosts, golden installer tests, and doc-contract tests when the install surface stabilizes.
- Provide `mix *.doctor` / `mix verify.*` style commands once runtime fit becomes non-trivial.

## 2. Repeated product-shape lessons relevant to Parapet

### Batteries included is good, but only when the paved road is honest

Across `sigra`, `mailglass`, `chimeway`, `rulestead`, `rindle`, and `accrue`, the strongest pattern is not “ship everything.”

It is:

- define a narrow honest wedge;
- make the default path feel complete;
- keep advanced surfaces composable and optional;
- document exactly what is and is not first-class support.

Parapet should follow the same pattern. It should not claim to solve all observability. It should claim a smaller, valuable wedge and execute it hard.

### Operator UX is a product surface, not polish

The strongest sibling libs treat operator workflows as real product scope:

- admin or trace surfaces in `sigra`, `mailglass`, `rulestead`, `chimeway`;
- proof and maintenance lanes in `accrue`, `scrypath`, `rindle`;
- health and audit thinking in `threadline`.

For Parapet, this means:

- health/doctor/diagnostics are first-class;
- deploy markers, evidence bundles, and runbooks matter;
- investigation UX is part of the product, not a future afterthought.

### Embedded and host-owned beats remote magic

The family pattern is consistent:

- the host owns auth, tenancy, repo, runtime, and product policy;
- the library owns the durable spine, conventions, adapters, and paved road.

Parapet should stay embedded inside the host app’s world rather than behaving like a black-box control plane.

## 3. Parapet-specific defaults inferred from sibling DNA

- Start with a single `parapet` package unless the admin/UI surface immediately forces a sibling package split.
- Design the first API around explicit reliability concepts, not vendor concepts.
- Add doctor/diagnostic surfaces early; Parapet’s category demands them more than most libs.
- Keep the first milestone centered on one trustworthy end-to-end reliability loop, not a giant surface area.
- Treat runbooks, incident context, and redaction rules as core design work.
- Prefer adapters and behaviors for integrations with OpenTelemetry, Grafana artifacts, job systems, and sibling libs.

## 4. Tier-1 sibling patterns to inherit directly

### Sigra

- installer and host-owned code posture;
- doctor command and runtime-fit guidance;
- auth/admin/operator seam discipline;
- telemetry and audit dual-surface mindset.

### Chimeway

- explainable delivery mindset;
- host integration seam documentation;
- notification/operator trace IA patterns;
- safe telemetry metadata discipline.

### Mailglass

- polished “framework layer on top of primitives” product framing;
- release engineering and package hygiene rigor;
- deliverability and DNS/doctor mentality.

### Threadline

- durable evidence and operator confidence framing;
- strong distinction between capture, semantics, and exploration;
- health and investigation as product features.

### Rulestead

- telemetry contract explicitness;
- health/diagnostics/redaction posture;
- release engineering and CI sharpness.

### Accrue and Rindle

- merge-blocking proof posture;
- package-consumer verification discipline;
- runtime checks and ops-facing workflows.

## 5. Footguns already paid for elsewhere

- Shipping too much repo junk to Hex by default.
- Letting telemetry contracts drift without treating them as API.
- Hiding important tests in obscure lanes without a contributor-facing explanation.
- Depending on optional libraries in a way that breaks base installs.
- Conflating telemetry with durable audit/evidence.
- Building magical DSLs that obscure ownership and runtime behavior.
- Creating admin/operator features without clear scope boundaries or proof lanes.
- Claiming a broader support surface than the docs and CI can actually prove.

## 6. Parapet decisions this doc should lock by default

- GitHub Actions + Release Please + Conventional Commits.
- Explicit Hex file whitelist.
- Scripts-first CI and stable job ids.
- Telemetry as API.
- Redaction-at-emission.
- Optional dependencies behind explicit seams.
- Doctor/diagnostics as a first-class requirement.
- Host-owned reliability wiring, not remote black-box behavior.

## 7. What still needs product decisions

This DNA doc should not decide:

- the exact v0.1 feature list;
- whether durable evidence storage ships in v0.1;
- the exact package split;
- the first business-critical journeys to support;
- the initial sibling-lib integrations to ship vs defer.

Those belong in `PARAPET-GSD-IDEA.md` questioning and roadmap work.
