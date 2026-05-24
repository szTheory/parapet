# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog tracks **published Hex releases** using Semantic Versioning headings like `## 0.10.0`.
Separately, maintainers track development tranches as planning milestones in [`.planning/MILESTONES.md`](.planning/MILESTONES.md).
For v0.1–v0.9 milestone history, see [`docs/HISTORY.md`](docs/HISTORY.md).

## 0.10.0

### Added

- `Parapet.Integration` behaviour (`@callback setup/0`) declared on all eight ecosystem integration
  adapters (Sigra, Accrue, Threadline, Chimeway, Mailglass, Rindle, Scoria, Rulestead). A missing
  or mis-named `setup/0` on any adapter is now a compile-time warning instead of a runtime
  `UndefinedFunctionError`.

### Fixed

- `Parapet.attach(adapters: [:rulestead])` no longer raises `UndefinedFunctionError`. The Rulestead
  adapter now exposes `setup/0` (delegating to `attach/0`), so all built-in integrations activate
  via the same `Parapet.attach/1` line.
