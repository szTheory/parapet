# Phase 22 Release Verification Gate

This document is the canonical pre-cut truth surface for the Parapet `1.0.0` release.

It is intentionally proportionate. The goal is to prove the frozen `1.0` surface is credible without pretending this release includes a full hardening program.

## Current External Truths

- `release_gate` is already configured as the required GitHub branch-protection check on `main`.
- The CI release topology for this phase is `lint`, `test`, `demo`, then `release_gate`.
- The final graduation cut is still blocked on external truth:
  - the exact `v0.10.0` tag must exist before removing the current `release-as: "0.10.0"` pin
  - the remaining Phase 21 demo proof must be green before Phase 22 can honestly be called complete

## Automated Release Gate

Run these commands from the repository root on the commit you intend to release:

```bash
mix compile --warnings-as-errors
mix compile --no-optional-deps --warnings-as-errors
mix docs --warnings-as-errors
mix credo --strict
mix dialyzer
mix verify.public_api
mix test
```

Expected result:

- every command exits `0`
- no compile or docs warnings are emitted
- no public API drift is reported
- the full root test suite stays green

## Manual Cold-Start Walkthrough

This is the bounded human proof for the release. It is not a broad exploratory QA pass.

### 1. Getting-started path

Confirm the documented adopter path is still coherent:

```bash
mix deps.get
mix parapet.install --skip-ui
mix parapet.doctor
mix parapet.gen.prometheus
mix parapet.gen.grafana
```

Confirm the generated flow still matches the documented getting-started guidance and does not require undocumented release-time fixes.

### 2. Runnable demo path

Run the demo app cold-start flow:

```bash
cd examples/demo_app
mix setup
mix assets.build
mix phx.server
```

Then verify in a browser:

- `http://localhost:4000/parapet` loads successfully
- seeded open, investigating, and resolved incidents are visible
- incident detail, timeline, tool audit, and runbook content render
- basic operator interactions respond instead of silently failing

### 3. CI branch-protection truth

Confirm the branch-protection gate still points at `release_gate`:

```bash
gh api repos/szTheory/parapet/branches/main/protection/required_status_checks --jq '.checks'
```

Expected result: the returned checks include `release_gate`.

## Release-Publish Truth

The publish workflow is owned by Release Please and must only run when it reports `release_created == true`.

Before merging the `1.0.0` Release Please PR, confirm:

- `HEX_API_KEY` exists in GitHub repository secrets
- `.github/workflows/release-please.yml` still publishes in this exact order:
  1. `mix hex.publish --dry-run`
  2. `mix hex.publish --yes`
  3. `mix hex.info parapet VERSION`
  4. `mix hex.docs fetch parapet VERSION`
  5. `curl` against `https://hexdocs.pm/parapet/VERSION/`

After the release merges, confirm both post-publish checks:

```bash
mix hex.info parapet 1.0.0
mix hex.docs fetch parapet 1.0.0
curl --fail --silent --show-error --location https://hexdocs.pm/parapet/1.0.0/
```

Expected result:

- Hex resolves package metadata for `parapet 1.0.0`
- HexDocs for `1.0.0` resolves successfully

## Graduation Checkpoints

Do not claim Phase 22 complete until all of these are true:

1. The exact `v0.10.0` tag exists.
2. All Phase 22 prep work is merged and green.
3. The automated gate above is green on the intended release commit.
4. The manual cold-start walkthrough is green.
5. The `1.0.0` Release Please PR merges and publishes successfully.
6. Hex and HexDocs both resolve for `1.0.0`.
7. The immediate post-cut cleanup from the graduation sequence is merged.

## Explicitly Out Of Scope

This gate does not expand into:

- a fresh security audit
- a new performance benchmark pass
- a multi-version Elixir or OTP matrix
- SHA pinning all GitHub Actions
- demo Docker Compose work
- broader maturity or post-`1.0` housekeeping

If one of those becomes required, it is new scope and must be tracked separately rather than smuggled into the `1.0.0` cut.
