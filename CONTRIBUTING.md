# Contributing to Parapet

Thank you for your interest in contributing to Parapet. This guide covers what you need to know before opening a pull request.

## Local proof commands

Run all three before pushing:

```bash
mix test
mix credo
mix dialyzer
```

All three must pass with no errors. CI runs the same checks and will fail the PR if any of them are red.

## Commit conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/): use one of `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, or `chore:` as your commit prefix.

Examples:

```
feat: add chimeway delivery SLO slice
fix: correct label cardinality check in doctor
docs: add rindle integration guide
refactor: extract common telemetry handler
test: add multi-node circuit breaker concurrency test
chore: update credo to 1.8
```

Run `mix format` before committing — CI fails on unformatted code.

## Pull request flow

1. Fork the repository and create a branch from `main`.
2. Make your changes, following the commit conventions above.
3. Open a PR against `main`. Include a one-sentence summary of what the PR does and link any related issue.
4. All CI checks must be green: `test`, `credo`, `dialyzer`, and `format`.
5. A maintainer will review and may request changes before merging.

## Development setup

This is an Elixir library, not an application. You need:

- Elixir 1.19+
- Postgres 14+

Clone the repository, then:

```bash
mix deps.get
mix test
```

If all tests pass, your environment is ready. There is no interactive setup wizard — the library has no application scaffold of its own.
