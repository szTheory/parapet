# Contributing to Parapet

Thank you for your interest in contributing to Parapet. This guide covers what you need to know before opening a pull request.

## Local proof commands

Run this before pushing:

```bash
mix ci
```

`mix ci` runs the full portable gate fail-fast: format --check-formatted, compile --warnings-as-errors, compile without optional deps, credo --strict, hex.audit, dialyzer, tests, and public-API verification. CI's `lint-once` job runs the same `mix ci` alias, so a local green means the portable gate would pass.

## Local vs CI deltas

Three checks run in CI that do not run in `mix ci` locally. If `mix ci` is green locally but CI is red on one of these, it is an expected delta — not a regression:

(a) **Docs build** — CI runs `mix docs --warnings-as-errors` in the `lint-once` job. This step is CI-only and is not part of `mix ci`. A doc-comment or extras reference error can surface in CI but not locally.

(b) **Operator UI manifest drift** — CI runs a diff of the operator-UI screenshot manifest against a baseline. This step is CI-only and is not part of `mix ci`. Drift in the generated manifest will appear in CI but not locally.

(c) **Schema prefix matrix** — CI's `test` job runs an extra leg with `PARAPET_SCHEMA_PREFIX=public` in addition to the default `parapet` prefix. Locally, `mix ci` runs tests against only the `parapet` schema prefix. A prefix-specific failure (for example, an unscoped migration that only breaks under `public`) can appear in the CI test matrix but not locally.

(d) **PR vs main multi-OTP breadth** — PRs run a single trimmed cell (OTP 28 × `parapet`); the full matrix (OTP 27, 28, 29 × `parapet` plus OTP 28 × `public`) runs on merge to `main` and nightly. A green PR is not full-matrix proof — `release_gate` on `main` is the real multi-OTP gate.

## Commit conventions

Parapet uses [Conventional Commits](https://www.conventionalcommits.org/) because Release Please turns commit prefixes into release notes and version decisions. Choose the prefix that matches the work class you are actually shipping:

- `feat:` — deliberate additive behavior or a scoped feature-work slice, such as adding a new stable provider or operator capability.
- `fix:` — bug fixes and correctness repairs on the stable line.
- `docs:` — documentation-only changes, guide updates, examples, and release-policy wording.
- `refactor:` — behavior-preserving code movement, extraction, or cleanup.
- `test:` — proof-only changes, regression tests, or CI test coverage that does not change runtime behavior.
- `chore:` — maintenance, CI, packaging truth, dependency metadata, and repository operations.

Use `feat:` on the stable line only when the PR intentionally adds behavior and the additive surface is described in the PR's `Feature work` context. Routine stable-line maintenance should usually be `fix:`, `docs:`, `test:`, or `chore:`.

Breaking markers (`!` in the type or `BREAKING CHANGE:` in the footer) are not routine maintenance. They mean explicit major-version planning and should appear only when the PR is scoped as intentional major-version work.

Examples:

```
feat: add chimeway delivery SLO slice
fix: correct label cardinality check in doctor
docs: add rindle integration guide
refactor: extract common telemetry handler
test: add multi-node circuit breaker concurrency test
chore: update release gate workflow
```

Run `mix format` before committing — CI fails on unformatted code.

## Pull request flow

1. Fork the repository and create a branch from `main`.
2. Make your changes, following the commit conventions above.
3. Decide the work class before opening the PR:
   - stable-line work: fixes, docs, CI hygiene, packaging truth, or other release-train-safe maintenance,
   - feature work: additive or behavior-expanding work that should be scoped and reviewed as a deliberate train.
4. Open a PR against `main`. Include a one-sentence summary of what the PR does and link any related issue or milestone context.
5. Serious feature work is PR-only. Do not treat `main` as a place for ambient milestone churn or unscoped feature development.
6. All CI checks must be green. `release_gate` is the branch-level merge signal, backed by formatting, compile, docs, credo, dialyzer, tests, and the demo smoke test in CI.
7. A maintainer will review and may request changes before merging.

## Stable-main posture

Parapet is a released library. After `v1.0.0`, the default posture is quiet stable-line maintenance:

- if `release_gate` is green and release truth is coherent, assume there is nothing to do,
- use small releasable slices for routine maintenance,
- treat serious feature work as explicit PR-shaped trains rather than background milestone motion.

## Development setup

This is an Elixir library, not an application. You need:

- Elixir 1.19+
- Postgres 14+

Clone the repository, then:

```bash
mix deps.get
mix ci
```

If `mix ci` passes, your environment is ready. There is no interactive setup wizard — the library has no application scaffold of its own.
