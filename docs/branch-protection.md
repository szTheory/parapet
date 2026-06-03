# Branch Protection

Parapet's `main` branch should require the aggregate `release_gate` workflow job before a pull request can merge. The individual CI jobs may expand over an Elixir/OTP matrix, but `release_gate` remains the stable required check that confirms the full matrix and demo lane passed.

## Required Rules

- Require pull requests before merging.
- Require status checks before merging.
- Require the `release_gate` status check.
- Require branches to be up to date before merging.
- Do not allow bypasses unless the repository owner has a documented emergency reason.

## Apply with GitHub CLI

Run this from a checkout with `gh` authenticated for the repository:

```sh
OWNER_REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${OWNER_REPO}/branches/main/protection" \
  -f required_pull_request_reviews='{"required_approving_review_count":1}' \
  -f required_status_checks='{"strict":true,"contexts":["release_gate"]}' \
  -f enforce_admins=true \
  -f restrictions=null
```

After applying the rule, confirm that `release_gate` appears in the branch protection settings for `main`.

## Apply in the GitHub UI

1. Open repository settings.
2. Go to Branches.
3. Add or edit the rule for `main`.
4. Enable "Require a pull request before merging".
5. Enable "Require status checks to pass before merging".
6. Select `release_gate` as the required status check.
7. Enable "Require branches to be up to date before merging".
8. Save the rule.
