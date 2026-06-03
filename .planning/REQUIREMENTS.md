## Milestone v1.2 Requirements

### Authoring DX
- [x] **DX-01**: `mix parapet.gen.slo` task is rebuilt as a flag-based Igniter task.
- [ ] **DX-02**: `Parapet.SLO` registry state is moved off the `Application` env to fix test isolation issues.
- [x] **DX-03**: v0.x -> v1.0 migration guide is added to `docs/`.
- [x] **DX-04**: Deployment guide is added to `docs/`.

### Maturity & Supply Chain
- [x] **MAT-01**: Multi-version Elixir/OTP CI matrix is implemented in GitHub Actions.
- [x] **MAT-02**: GitHub Actions use SHA-pinned versions.
- [x] **MAT-03**: Dependabot configuration is added for Hex and GitHub Actions.
- [x] **MAT-04**: Branch protection rules strictly enforce the `release_gate` job.
- [x] **MAT-05**: `MAINTAINING.md` is added to document release procedures.
- [x] **MAT-06**: `CONTRIBUTING.md` includes the conventional commit taxonomy.
- [x] **MAT-07**: HexDocs includes a Parapet logo and favicon.
- [x] **MAT-08**: Provide a `docker-compose.yml` for the demo app.

### Traceability

This section is maintained by `gsd-roadmapper`.