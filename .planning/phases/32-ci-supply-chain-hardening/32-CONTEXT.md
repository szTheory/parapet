# Phase 32: CI & Supply Chain Hardening - Context

**Gathered:** 2026-06-03 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Multi-version Elixir/OTP CI matrix & supply-chain hardening (Dependabot, SHA-pinned actions, branch protection)
</domain>

<decisions>
## Implementation Decisions

### CI Matrix Strategy
- **D-01:** The CI matrix will test Elixir 1.19.x against OTP 26, 27, and 28. (Confirmed via external research: Elixir 1.19 requires OTP 26 minimum).

### Action Pinning Strategy
- **D-02:** We will replace all floating version tags (`@v4`, `@v1`) with full commit SHAs in `.github/workflows/ci.yml` and `.github/workflows/release-please.yml`. (Exact SHAs resolved: actions/checkout@v4=34e114876b0b11c390a56381ad16ebd13914f8d5, erlef/setup-beam@v1=fc68ffb90438ef2936bbb3251622353b3dcb2f93, actions/cache@v4=0057852bfaa89a56745cba8c7296529d2fc39830, googleapis/release-please-action@v4=5c625bfb5d1ff62eadeeb3772007f7f66fdcf071).

### Dependabot Configuration
- **D-03:** A new `.github/dependabot.yml` file will be created to manage updates for `mix` and `github-actions`.

### Branch Protection Enforcement Mechanism
- **D-04:** Branch protection enforcement will require a documented manual UI or `gh api` action, as it cannot be codified purely within the repository files.

### Claude's Discretion
None

### Folded Todos
None
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- .github/workflows/ci.yml
- .github/workflows/release-please.yml
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ci.yml` jobs: lint, test, demo, release_gate
- `release-please.yml` release automation pipeline

### Established Patterns
- CI jobs use `actions/cache` and `erlef/setup-beam`
- Test dependencies rely on docker services (e.g. postgres)
- Single hardcoded combination (`1.19.0` / `27.2`) previously used.

### Integration Points
- GitHub Actions workflows
- GitHub Repository Settings (Branch Protection)
</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope
</deferred>