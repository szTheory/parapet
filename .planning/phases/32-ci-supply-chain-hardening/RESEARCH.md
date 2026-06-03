# Phase 32: CI & Supply Chain Hardening - Research

**Researched:** 2026-06-03
**Domain:** Pipeline Security & Matrix Testing
**Confidence:** HIGH

## Summary

This phase focuses on hardening the CI pipeline and supply chain for the `parapet` project. We will transition the CI workflows from a static, single-version build to an Elixir/OTP compatibility matrix (Elixir 1.19.x with OTP 26, 27, 28) to ensure robustness and backwards compatibility. To mitigate supply chain risks, all GitHub Actions will be pinned to their exact commit SHAs rather than mutable tags (like `@v4`), preventing unexpected behavior from tag reassignment. Furthermore, we will configure Dependabot to monitor and bump dependencies for both `mix` and `github-actions`, and document the manual or CLI steps required to enforce branch protection on the `main` branch.

**Primary recommendation:** Utilize GitHub Actions `strategy.matrix` scoped cache keys, pin all actions using the provided exact SHAs, and manage automated dependency bumps via `.github/dependabot.yml`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The CI matrix will test Elixir 1.19.x against OTP 26, 27, and 28. (Confirmed via external research: Elixir 1.19 requires OTP 26 minimum).
- **D-02:** We will replace all floating version tags (`@v4`, `@v1`) with full commit SHAs in `.github/workflows/ci.yml` and `.github/workflows/release-please.yml`. (Exact SHAs resolved: actions/checkout@v4=34e114876b0b11c390a56381ad16ebd13914f8d5, erlef/setup-beam@v1=fc68ffb90438ef2936bbb3251622353b3dcb2f93, actions/cache@v4=0057852bfaa89a56745cba8c7296529d2fc39830, googleapis/release-please-action@v4=5c625bfb5d1ff62eadeeb3772007f7f66fdcf071).
- **D-03:** A new `.github/dependabot.yml` file will be created to manage updates for `mix` and `github-actions`.
- **D-04:** Branch protection enforcement will require a documented manual UI or `gh api` action, as it cannot be codified purely within the repository files.

### the agent's Discretion
None

### Deferred Ideas (OUT OF SCOPE)
None — analysis stayed within phase scope
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CI Orchestration | GitHub Actions | — | Standard pipeline execution and test runners |
| Matrix Testing | GitHub Actions | — | Native GitHub Action matrix logic (`strategy.matrix`) handles combinations efficiently |
| Dependency Updates | Dependabot | GitHub Actions | Automated PR generation for outdated packages or workflow actions |
| Branch Protection | GitHub Repo Settings| `gh` CLI | Requires API or UI configuration, cannot be codified directly in the repository via text files |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `actions/checkout` | 34e114876b0b11c390a56381ad16ebd13914f8d5 | Checkout code | Fundamental action for any CI pipeline |
| `erlef/setup-beam` | fc68ffb90438ef2936bbb3251622353b3dcb2f93 | Setup Erlang/Elixir | Official and canonical approach for BEAM environment provisioning |
| `actions/cache` | 0057852bfaa89a56745cba8c7296529d2fc39830 | Caching | Accelerates dependency fetching and compilation |
| `googleapis/release-please-action` | 5c625bfb5d1ff62eadeeb3772007f7f66fdcf071 | Release generation | Standardized semantic releases based on conventional commits |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Dependabot | v2 | Automated dependency management | For continuous updates to `mix` packages and `github-actions` references |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. 

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| actions/checkout | GitHub | N/A | N/A | actions/checkout | [OK] | Approved |
| erlef/setup-beam | GitHub | N/A | N/A | erlef/setup-beam | [OK] | Approved |
| actions/cache | GitHub | N/A | N/A | actions/cache | [OK] | Approved |
| googleapis/release-please-action | GitHub | N/A | N/A | googleapis/release-please-action | [OK] | Approved |

*Note: This phase strictly manages GitHub Actions metadata and does not pull unverified NPM, PyPI, or Cargo packages.*

## Architecture Patterns

### Pattern 1: CI Matrix for Elixir/OTP
**What:** Testing an Elixir application across multiple supported OTP versions automatically.
**When to use:** When building an Elixir library that must ensure backward compatibility across a spread of OTP versions.
**Example:**
```yaml
strategy:
  matrix:
    elixir: ['1.19.0']
    otp: ['26.x', '27.x', '28.x']
```

### Anti-Patterns to Avoid
- **Floating Version Tags in Actions:** Using `@v3` or `@v4` for GitHub Actions. It opens up supply chain attacks if the tag is modified, forced-pushed, or compromised. Use full 40-character commit SHAs.
- **Cache Key Matrix Blindness:** Failing to include the matrix parameters (`elixir` and `otp`) in the cache keys. This results in cache thrashing as concurrent jobs constantly overwrite each other's cache layers.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CI Pipeline Matrix | Custom bash scripts looping over versions | GitHub Actions `strategy.matrix` | Native parallel execution, robust UI reporting, isolated execution contexts |
| Dependency Updates | Custom scripts scraping Hex API | Dependabot | Native GitHub integration, automated PR creation, automatic security alerts integration |
| Branch Protection | Custom pre-receive hooks or CI rejection | GitHub Branch Protection API/UI | Integrated securely at the repository level, impossible to bypass via PR modifications |

## Common Pitfalls

### Pitfall 1: Cache Thrashing in Matrix Builds
**What goes wrong:** Multiple matrix jobs overwrite each other's dependency or build caches, leading to no actual cache hits and degraded CI performance.
**Why it happens:** The `key` and `restore-keys` in `actions/cache` do not dynamically incorporate the matrix variables.
**How to avoid:** Always include `${{ matrix.otp }}` and `${{ matrix.elixir }}` in the cache key.
**Warning signs:** CI logs showing zero cache hits or excessively long build times after implementing a matrix.

### Pitfall 2: Dependabot Noise
**What goes wrong:** Dependabot creates too many PRs simultaneously, causing notification fatigue and pipeline congestion.
**Why it happens:** Setting the `schedule.interval` to `daily` without commit message prefixing or auto-merge strategies.
**How to avoid:** Set the `schedule.interval` to `weekly` and assign appropriate labels to group them easily.

## Code Examples

### SHA Pinned Action (Supply Chain Hardened)
```yaml
# Source: Official GitHub Actions Security Hardening Guide
- uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4
```

### Elixir/OTP Matrix Strategy with Scoped Caching
```yaml
strategy:
  matrix:
    elixir: ['1.19.0']
    otp: ['26.x', '27.x', '28.x']
steps:
  - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5 # v4
  - name: Setup Elixir
    uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1
    with:
      elixir-version: ${{ matrix.elixir }}
      otp-version: ${{ matrix.otp }}
  - name: Cache deps
    uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830 # v4
    with:
      path: deps
      key: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
      restore-keys: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Action Tags (`@v4`) | Commit SHAs (`@34e11...`) | Standardized ~2021 | Eliminates supply chain risks related to tag reassignment |
| Single Version CI | Matrix-driven CI | N/A | Ensures library compatibility across broader ecosystem configurations |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Matrix notation using `.x` (`26.x`, `27.x`, `28.x`) is fully supported by `erlef/setup-beam` | Code Examples | CI jobs fail to resolve valid OTP versions during runner setup |

## Open Questions

1. **Specific GH CLI payload for Branch Protection**
   - What we know: D-04 requires a documented `gh api` command or manual step to enforce branch protection on `main`.
   - What's unclear: Should the branch protection rules require *all* matrix jobs to pass individually, or rely solely on the aggregated `release_gate` job?
   - Recommendation: The `gh api` documentation should explicitly enforce the `release_gate` job. Since `release_gate` requires `[lint, test, demo]`, and those jobs run as a matrix, the `release_gate` acts as a solid aggregate checkpoint.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` CLI | Branch protection configuration | ✓ | 2.93.0 | Manual GitHub UI |
| GitHub Actions | CI pipeline execution | ✓ | Cloud | — |
| Dependabot | Dependency updates | ✓ | Cloud | — |

**Missing dependencies with no fallback:**
- None

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GitHub Actions (CI YAML) |
| Config file | `.github/workflows/ci.yml` |
| Quick run command | `gh workflow run ci.yml --ref $(git branch --show-current)` |
| Full suite command | GitHub PR Checks / CI Pipeline |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CI-01 | Matrix builds on PR | integration | Push to PR and verify GitHub UI | ✅ Wave 0 |
| CI-02 | SHA-pinned actions | lint | `grep -q '@[0-9a-f]\{40\}' .github/workflows/ci.yml` | ✅ Wave 0 |
| CI-03 | Dependabot configs | unit | `cat .github/dependabot.yml` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** Local inspection and file parsing.
- **Per wave merge:** Full execution of matrix pipeline on GitHub.
- **Phase gate:** Branch protection enabled, Dependabot PRs verified (if applicable).

### Wave 0 Gaps
- [ ] `.github/dependabot.yml` — missing, needed for dependency management
- [ ] Documentation file for Branch Protection (e.g., `docs/branch-protection.md`)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | GitHub Branch Protection / Require PR Reviews |
| V5 Input Validation | no | — |
| V6 Cryptography | no | — |

### Known Threat Patterns for GitHub Actions

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mutable Tag Exploitation | Tampering | Pin actions to full commit SHAs (`@34e11...`) |
| Unapproved Actions | Spoofing | Dependabot config to auto-monitor actions, repo-level action restrictions |
| Untested Dependencies | Tampering | Branch protection requiring PRs and CI checks to pass prior to merge |

## Sources

### Primary (HIGH confidence)
- Official GitHub Actions Documentation - Security Hardening
- `.planning/phases/32-ci-supply-chain-hardening/32-CONTEXT.md` - Exact SHAs verified

### Secondary (MEDIUM confidence)
- `erlef/setup-beam` official repository documentation for `strategy.matrix` definitions

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly synthesized from context D-01/D-02.
- Architecture: HIGH - GitHub Actions matrix and Dependabot are native canonical solutions.
- Pitfalls: HIGH - Cache key matrix isolation is a universally documented issue.

**Research date:** 2026-06-03
**Valid until:** 2026-07-03
