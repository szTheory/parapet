# Phase 32: CI & Supply Chain Hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-03
**Phase:** 32-ci-supply-chain-hardening
**Mode:** assumptions
**Areas analyzed:** CI Matrix Strategy, Action Pinning Strategy, Dependabot Configuration, Branch Protection Enforcement Mechanism

## Assumptions Presented

### CI Matrix Strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The CI matrix will test Elixir 1.19.x against OTP 27.x. | Likely | `mix.exs` restricts the environment with `elixir: "~> 1.19"`. Currently, `.github/workflows/ci.yml` tests a single hardcoded combination (`1.19.0` / `27.2`). |

### Action Pinning Strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| We will replace all floating version tags (`@v4`, `@v1`) with full commit SHAs in `.github/workflows/ci.yml` and `.github/workflows/release-please.yml`. | Confident | Phase 32 goals specifically mandate "Actions are SHA-pinned" (MAT-02). |

### Dependabot Configuration
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| A new `.github/dependabot.yml` file will be created to manage updates for `mix` and `github-actions`. | Confident | MAT-03 requires Dependabot configuration for Hex and GitHub Actions. |

### Branch Protection Enforcement Mechanism
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Branch protection enforcement will require a documented manual UI or `gh api` action, as it cannot be codified purely within the repository files. | Likely | Branch protection settings cannot be automated via the workflow file. |

## Corrections Made

No corrections — all assumptions confirmed.

## External Research

- Action Pinning: Exact commit SHAs discovered for actions/checkout@v4, erlef/setup-beam@v1, actions/cache@v4, googleapis/release-please-action@v4. (Source: GitHub API tags)
- CI Matrix: Elixir 1.19 officially drops OTP 25 and earlier. Tests should include OTP 26 (minimum), OTP 27, and OTP 28 (newest). (Source: Official Elixir v1.19 documentation)