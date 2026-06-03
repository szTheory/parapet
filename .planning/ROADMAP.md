# Roadmap

## Phase 30: Registry Decoupling
**Goal:** Move SLO state off the Application environment.
**Requirements:** DX-02
**Success Criteria:**
1. `Parapet.SLO` uses a dedicated Agent or ETS table.
2. `Application.put_env` is no longer used for SLO registry.
3. All tests pass without isolation issues.

**Plans:** 1 plans

Plans:
- [ ] 30-01-PLAN.md — Refactor Parapet.SLO.Registry and Parapet.Capabilities to use ETS test checkout pattern for isolation.

## Phase 31: Igniter SLO Task
**Goal:** Provide a seamless, flag-based generator for SLOs.
**Requirements:** DX-01
**Success Criteria:**
1. `mix parapet.gen.slo` executes via Igniter.
2. Supports passing flags for metric names and thresholds.

**Plans:** 1/1 plans complete

Plans:
- [x] 31-01-PLAN.md — Provide a seamless, flag-based generator for SLOs by creating an Igniter Mix task `mix parapet.gen.slo`.

## Phase 32: CI & Supply Chain Hardening
**Goal:** Lock down CI dependencies and enforce branch protection.
**Requirements:** MAT-01, MAT-02, MAT-03, MAT-04
**Success Criteria:**
1. Actions are SHA-pinned.
2. CI runs on a matrix of supported Elixir/OTP versions.
3. Dependabot is active.

**Plans:** 2 plans

Plans:
- [ ] 32-01-PLAN.md — Harden CI pipeline with Elixir/OTP matrix and SHA pinning.
- [ ] 32-02-PLAN.md — Configure Dependabot and document branch protection.

## Phase 33: Documentation & Polish
**Goal:** Complete the 1.0 maturity artifacts.
**Requirements:** DX-03, DX-04, MAT-05, MAT-06, MAT-07, MAT-08
**Success Criteria:**
1. Migration and Deployment guides are present.
2. Logo/Favicon added to docs.
3. Demo app docker-compose works.
