---
phase: "03-slo-login-deploy"
plan: "03"
subsystem: "Deploy"
tags:
  - telemetry
  - deploy
  - generator
  - grafana
depends_on: ["02"]
requires:
  - telemetry
provides:
  - Parapet.Deploy.mark/1
affects:
  - rel/hooks/post_start.sh
tech_stack_added: []
tech_stack_patterns:
  - "Telemetry event execution"
  - "Igniter file creation"
key_files_created:
  - "lib/parapet/deploy.ex"
  - "test/parapet/deploy_test.exs"
key_files_modified:
  - "lib/mix/tasks/parapet.install.ex"
key_decisions:
  - "Deployment marker uses standard system_time rather than monotonic time to align easily with external systems (Grafana annotations) without clock offset math."
  - "Deploy hook assumes standard Phoenix releases structure (`rel/hooks/post_start.sh`)."
metrics:
  duration_minutes: 10
  completed_date: "2026-05-11"
---

# Phase 3 Plan 03: Deploy Markers API Summary

Implemented the Deploy Markers API and integrated its generation into the installer. Applications can now explicitly mark deployments via a simple Elixir API, providing temporal tracking for Grafana annotations.

## Work Completed

- **Deploy Marker API:** Added `Parapet.Deploy.mark/1` which emits a `[:parapet, :deploy, :mark]` telemetry event containing the system time (in milliseconds) and any supplied metadata.
- **TDD Enforcement:** Created `test/parapet/deploy_test.exs` prior to implementation. Verified successful capture of telemetry events and parameters.
- **Generator Updates:** Updated `Mix.Tasks.Parapet.Install` to generate or append to `rel/hooks/post_start.sh`. The hook uses Phoenix release RPC to call `Parapet.Deploy.mark/1` during post-start, enabling automatic Grafana annotation markers for application deployments.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

*(none)*

## Threat Flags

*(none)*

## Self-Check: PASSED
- `lib/parapet/deploy.ex` exists
- `test/parapet/deploy_test.exs` exists
- `Parapet.Deploy.mark/1` functionality tested
- Generator creates `rel/hooks/post_start.sh`