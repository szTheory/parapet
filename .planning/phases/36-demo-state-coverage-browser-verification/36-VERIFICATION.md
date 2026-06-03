---
phase: 36
status: passed
verification_mode: automated
manual_uat: not_required
updated: 2026-06-03T23:04:57Z
---

# Phase 36 Verification

Phase 36 uses automated source-contract, smoke, and browser screenshot evidence.

## Evidence Matrix

| Requirement | Evidence | Status |
|-------------|----------|--------|
| UI-DEMO-01 | `test/parapet/operator_ui_demo_contract_test.exs` seed matrix assertions; demo seeds include the full state set | pass |
| UI-DEMO-02 | Demo router and generated route guidance contract assertions | pass |
| UI-VERIFY-01 | Root generated UI tests plus demo smoke route tests | pass |
| UI-VERIFY-02 | Chromium screenshots for response, actions, history, and detail on desktop/mobile | pass |

## Screenshot Targets

- `screenshots/operator-response-desktop.png`
- `screenshots/operator-actions-desktop.png`
- `screenshots/operator-history-desktop.png`
- `screenshots/operator-detail-desktop.png`
- `screenshots/operator-response-mobile.png`
- `screenshots/operator-actions-mobile.png`
- `screenshots/operator-history-mobile.png`
- `screenshots/operator-detail-mobile.png`

## Commands

```bash
mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_demo_contract_test.exs
cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs
cd examples/demo_app && mix demo.reset
cd examples/demo_app && mix assets.build
cd examples/demo_app && mix phx.server
examples/demo_app/scripts/capture_operator_ui_screenshots.sh
mix format --check-formatted <touched files>
```

## Results

- `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs test/parapet/operator_ui_demo_contract_test.exs` - 25 tests, 0 failures.
- `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` - 5 tests, 0 failures.
- `cd examples/demo_app && mix demo.reset` - passed; demo seeds inserted the full Phase 36 state matrix.
- `cd examples/demo_app && mix assets.build` - passed.
- `examples/demo_app/scripts/capture_operator_ui_screenshots.sh` - passed; produced all eight PNGs listed above.
- Touched-file `mix format --check-formatted ...` - passed.

## Residuals

- Demo compile still emits the pre-existing `Parapet.Escalation.Worker.new/1` warning from `lib/parapet/evidence.ex`; tests pass.
- Chromium prints local macOS/Chrome profile warnings during headless capture, but exits 0 and writes all expected PNG files.
