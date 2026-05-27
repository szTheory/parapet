# Phase 22 Live Cut Checklist

Use this as the short operator run sheet for the real `0.10.0 -> 1.0.0` graduation. The canonical truth surface remains `22-VERIFICATION.md`.

## Current Block

Do not start the graduation sequence until the exact `v0.10.0` tag exists.

## Preconditions

- `git tag --list 'v0.10.0'` returns `v0.10.0`
- all Phase 22 prep work is merged on the release branch
- `release_gate` is green on the intended release commit
- `HEX_API_KEY` exists in GitHub repository secrets

## Run Sheet

1. Confirm the exact `v0.10.0` tag exists.
2. Remove `release-as: "0.10.0"` from `release-please-config.json`.
3. Reconfirm all Phase 22 prep work is merged and green.
4. Add one-time `release-as: "1.0.0"` to `release-please-config.json`.
5. Run the automated gate from `22-VERIFICATION.md`:
   - `mix compile --warnings-as-errors`
   - `mix compile --no-optional-deps --warnings-as-errors`
   - `mix docs --warnings-as-errors`
   - `mix credo --strict`
   - `mix dialyzer`
   - `mix verify.public_api`
   - `mix test`
6. Run the manual cold-start walkthrough from `22-VERIFICATION.md`.
7. Merge the `1.0.0` Release Please PR and let the publish workflow complete.
8. Verify post-publish truth:
   - `mix hex.info parapet 1.0.0`
   - `mix hex.docs fetch parapet 1.0.0`
   - `curl --fail --silent --show-error --location https://hexdocs.pm/parapet/1.0.0/`
9. Immediately remove from `release-please-config.json`:
   - `release-as: "1.0.0"`
   - `bump-minor-pre-major`
   - `bump-patch-for-minor-pre-major`
10. Do not hand-edit `.release-please-manifest.json` at any point.

## Done Means

- the exact `v1.0.0` tag exists
- Hex resolves `parapet 1.0.0`
- HexDocs resolves `https://hexdocs.pm/parapet/1.0.0/`
- the cleanup commit removing the one-time pin and pre-major flags is merged
