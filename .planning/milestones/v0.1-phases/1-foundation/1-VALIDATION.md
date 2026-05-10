# Phase 1: Nyquist Validation Map

## Requirements Coverage Map

| Req ID | Description | Test Strategy |
|--------|-------------|---------------|
| PKG-01 | Single parapet hex package with files whitelist | CI `mix hex.audit` and `verify.workspace_clean` |
| PKG-02 | Optional deps compile cleanly when absent | CI compile `--no-optional-deps` |
| PKG-03 | Clear public module surface limits | CI `mix verify.public_api` |
| PKG-04 | verify.public_api exits non-zero on undocumented | Integration test `verify_public_api_test.exs` |
| TELE-01 | All telemetry events documented | Doc tests / `verify.public_api` |
| TELE-02 | Telemetry schema changes are semver breaking | Release Please automation |
| TELE-03 | No high-cardinality fields in metric labels | Unit test `label_policy_test.exs` |
| TELE-04 | Telemetry handlers use `Parapet.attach/1`, never crash | Unit test `safe_handler_test.exs` |
| INST-01 | `mix parapet.install` generates `Parapet.Instrumenter` | E2E `parapet.install_test.exs` |
| INST-02 | Appends `Parapet.Plug.Metrics` to host Endpoint | E2E `parapet.install_test.exs` |
| INST-03 | Adds `config/config.exs` with inline comments | E2E `parapet.install_test.exs` |
| INST-04 | Installer is idempotent | E2E `parapet.install_test.exs` |
| INST-05 | `mix parapet.install --dry-run` available | E2E `parapet.install_test.exs` |
| DOCS-02 | `docs/telemetry.md` holds full contract | File existence check in CI |
| DOCS-04 | `CHANGELOG.md` via Release Please | File existence check in CI |
| ERR-01 | Handler exceptions logged, never crash host | Unit test `safe_handler_test.exs` (assert Logger capture) |
| ERR-03 | Public functions return `{:ok, result}` / `{:error, reason}` | Dialyzer / Unit tests |
| ERR-04 | Log debug on attach, warning on skipped | Unit tests capturing Logger output |
| OSS-01 | CI runs format, credo, dialyzer, test | CI workflow |
| OSS-02 | `mix verify.public_api` CI step | CI workflow |
| OSS-03 | Hex whitelist in `mix.exs` excludes planning files | Package verify workflow |
| OSS-04 | Release Please GitHub Actions setup | CI workflow |