<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The project will be initialized as a supervised library (`mix new parapet --sup`). This establishes the explicit OTP application boundary required to manage telemetry lifecycle and cache states.
- **D-02:** The `files:` whitelist in `mix.exs` will strictly include only standard runtime and doc files, keeping the package free of planning and prompt artifacts.
- **D-03:** The full "Rulestead-style" CI pipeline (GitHub Actions, Release Please, Conventional Commits) is implemented immediately.
- **D-04:** Strict gates: `mix format`, `credo --strict`, `dialyzer`, and `mix verify.public_api` must pass from day 1 to enforce documentation and typing.
- **D-05:** The installer will use `Igniter` (if applicable/stable) or robust AST-aware patching to append `Parapet.Plug.Metrics` to the host app's Endpoint and configure `Parapet.Instrumenter`.
- **D-06:** The installer builds the complete scaffolding logic in Phase 1, even though the HTTP metrics telemetry implementations themselves ship in Phase 2. This de-risks DX up front.
- **D-07:** Label policy enforcement must occur as early as possible. We will design macros or compile-time checks to reject known high-cardinality labels (like `user_id` or `path`).
- **D-08:** Handlers must never crash the host process. We will wrap handler logic in resilient exception boundaries (`try/rescue` inside telemetry handlers) and log errors instead of bringing down the application.
- **D-09:** Optional dependencies (`:oban`, `:sigra`) will use `if Code.ensure_loaded?` checks.

### the agent's Discretion
- The exact internal module structure under `Parapet.Internal` is left to Claude's discretion.
- The use of `Igniter` vs regex/Sourceror for the installer is up to the planner based on what provides the most idiomatic and stable DX.

### Deferred Ideas (OUT OF SCOPE)
- HTTP, Ecto, Oban specific metric hookups (Phase 2).
- SLO definition and alerting rules (Phase 3).
- Grafana dashboard generation (Phase 4).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKG-01 | Single `parapet` hex package with strict `files:` whitelist | Implemented in `mix.exs` via project metadata configuration. |
| PKG-02 | Optional dependencies compile cleanly when absent | Addressed by `if Code.ensure_loaded?(Module)` checks for handler hooks. |
| PKG-03 | Clear public module surface with `Parapet.*` limits | Using `@moduledoc false` and `Parapet.Internal` namespace mapping. |
| PKG-04 | `mix verify.public_api` exits non-zero on undocumented modules | Achieved via custom Mix task evaluating `Code.fetch_docs/1`. |
| TELE-01 | All telemetry events documented in `docs/telemetry.md` | Standard markdown file creation; enforced as policy. |
| TELE-02 | Telemetry schema version declared, changes are semver breaking | Standard versioning strategy enforced via Release Please. |
| TELE-03 | No high-cardinality fields in metric labels | Handled by `Parapet.Internal.LabelPolicy` compile-time and runtime validation macros. |
| TELE-04 | Telemetry handlers use `Parapet.attach/1`, never crash | Implemented via a `try/rescue` wrapper pattern within handler callbacks. |
| INST-01 | `mix parapet.install` generates `Parapet.Instrumenter` | Implemented via `Igniter.Mix.Task` generating scaffolding. |
| INST-02 | Appends `Parapet.Plug.Metrics` to host Endpoint | Achieved via `Igniter` AST patching in the generator. |
| INST-03 | Adds `config/config.exs` with inline comments | Handled via `Igniter.Project.Config.configure/4` AST updates. |
| INST-04 | Installer is idempotent and respects already-configured state | Built-in property of `Igniter` file and code transformations. |
| INST-05 | `mix parapet.install --dry-run` available | Provided out-of-the-box by the `Igniter` framework. |
| DOCS-02 | `docs/telemetry.md` holds full telemetry contract | Simple markdown creation in repository skeleton. |
| DOCS-04 | `CHANGELOG.md` via Release Please/Conventional Commits | CI pipeline configuration with standard GitHub Action template. |
| ERR-01 | Handler exceptions logged, never crash host process | `try/rescue` wrapper logs via `Logger.error/2` holding exception data. |
| ERR-03 | Public functions return `{:ok, result}` / `{:error, reason}` | API signature standardization pattern. |
| ERR-04 | Log debug on attach, warning on skipped optional handlers | Straightforward runtime checks using `Logger.debug` and `Logger.warning`. |
| OSS-01 | CI runs format, credo, dialyzer, test | Provided by `.github/workflows/ci.yml`. |
| OSS-02 | `mix verify.public_api` CI step | Custom Mix task included in CI checks. |
| OSS-03 | Hex whitelist in `mix.exs` excludes planning files | Regex/String filters in `def project` `package:` block. |
| OSS-04 | Release Please GitHub Actions setup | Provided by `.github/workflows/release-please.yml`. |
</phase_requirements>

# Phase 1: Telemetry Foundation & Safety Rails - Research

**Researched:** 2026-05-09
**Domain:** Elixir Library Architecture, Telemetry, Code Generation (Igniter)
**Confidence:** HIGH

## Summary

Phase 1 establishes the core telemetry mechanics, boundary guarantees, and developer experience for the Parapet library. Instead of building the actual metric surfaces (which comes in Phase 2), this phase lays the safety rails: exception-safe telemetry handlers, compile-time label policy enforcement, and a robust installation experience. 

By leveraging the `igniter` framework, `mix parapet.install` can idempotently modify the host application's files—such as injecting the required `Parapet.Plug.Metrics` into the Phoenix Endpoint and scaffolding out the `Parapet.Instrumenter` configuration file. Furthermore, we establish the CI constraints (credos, formatters, dialyxir) and the custom `verify.public_api` task to ensure that the internal/external documentation boundary remains pristine.

**Primary recommendation:** Use `igniter` for the installer mix task and employ `try/rescue` wrapper functions dynamically for all telemetry attachments to guarantee the host process never crashes.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dependency & Package Whitelisting | Build/Tooling | — | Handled strictly via Elixir's `mix.exs` configurations. |
| Installation / Code Generation | Build/Tooling | — | Handled by `igniter` to safely alter host apps at compile/dev time. |
| Label Safety & Cardinality Guard | Build/Tooling | API / Backend | Macros/compile-time logic validates static labels; runtime assertions capture dynamic exceptions. |
| Telemetry Event Hooks & Recovery | API / Backend | — | Uses standard `:telemetry.attach/4` and executes in host processes, necessitating hard `try/rescue` boundaries. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | ~> 1.15 | Core runtime | Standard platform target. |
| telemetry | ~> 1.2 | Event emitting/handling | The official Elixir instrumentation standard. |
| igniter | ~> 0.7.9 | Code generation | Modern AST-aware framework that enables idempotent generators, safe file patching, and automatic `--dry-run` functionality. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| credo | ~> 1.7 | Linter | Static analysis in CI for consistent coding standards. |
| dialyxir | ~> 1.4 | Type checker | Type checking in CI. |
| ex_doc | ~> 0.32 | Doc generator | Creating documentation and programmatically verifying public API boundaries. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `igniter` | Regex / Sourceror manually | Regex is brittle and fails on formatting changes; writing manual Sourceror logic is time-consuming and prone to edge-case errors. Igniter provides robust AST composition. |
| Custom AST parser | `ex_doc` JSON / Docs chunk | Using Elixir's native `Code.fetch_docs/1` provides a clean and guaranteed mechanism to list documented modules versus manually interpreting AST files. |

**Installation:**
```bash
mix deps.get
```

**Version verification:** 
```bash
mix hex.info igniter
```
*Igniter confirmed at v0.7.9 as of mid-2026. Telemetry is standard.*

## Architecture Patterns

### System Architecture Diagram
(Because this phase is building library infrastructure, the "system architecture" describes the integration hook points rather than data flow).

```text
Host Phoenix App (Process)             Parapet Internal Mechanics
+--------------------+                 +---------------------------+
| Endpoint / Logic   |  --[emits]-->   | telemetry event routing   |
+--------------------+                 +---------------------------+
                                                    |
                                                    v
                                       +---------------------------+
                                       | Parapet.SafeHandler       |
                                       | - Wraps in try/rescue     |
                                       | - Logs on failure         |
                                       +---------------------------+
                                                    |
                                                    v
                                       +---------------------------+
                                       | Parapet.Instrumenter      |
                                       | (Host-owned config logic) |
                                       +---------------------------+
```

### Recommended Project Structure
```text
lib/
├── parapet/
│   ├── internal/        # Private modules, strict separation (@moduledoc false)
│   │   ├── label_policy.ex  # Compile-time label safety macro
│   │   ├── safe_handler.ex  # Wraps telemetry attach/4 in try/rescue
│   ├── instrumenter.ex  # Template for the host app implementation
│   └── (others)         # Phase 2 surface definitions
├── mix/
│   └── tasks/
│       ├── parapet.install.ex   # Igniter installation script
│       └── verify.public_api.ex # Custom CI API verification task
```

### Pattern 1: Exception-Safe Handlers
**What:** Wrapping telemetry hooks so metric collection bugs never cascade into application crashes.
**When to use:** Whenever passing a callback function to `:telemetry.attach/4`.
**Example:**
```elixir
defmodule Parapet.Internal.SafeHandler do
  require Logger

  def attach(handler_id, event_name, handler_module, function_name, config \\ %{}) do
    :telemetry.attach(
      handler_id,
      event_name,
      fn event, measurements, metadata, handler_config ->
        try do
          apply(handler_module, function_name, [event, measurements, metadata, handler_config])
        rescue
          e ->
            Logger.error(
              "Parapet telemetry handler exception in #{inspect(handler_module)}.#{function_name}/4",
              event: event,
              exception: Exception.message(e)
            )
        end
      end,
      config
    )
  end
end
```

### Pattern 2: Igniter Task Composition
**What:** Designing `mix parapet.install` as a pipeline of predictable, AST-driven transformations.
**When to use:** Adding dependencies, editing Phoenix `endpoint.ex`, or dropping boilerplate config into `config.exs`.
**Example:**
```elixir
defmodule Mix.Tasks.Parapet.Install do
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app_name = Igniter.Project.Application.app_name(igniter)

    igniter
    # 1. Scaffolds lib/my_app/parapet_instrumenter.ex
    |> scaffold_instrumenter(app_name)
    # 2. Injects plug into Endpoint using Igniter.Project.Module
    |> append_to_endpoint(app_name)
    # 3. Drops telemetry configurations into config.exs
    |> update_config(app_name)
  end
end
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Checking dependencies globally via `Application.ensure_started(:oban)`. This crashes the caller if it's missing. What to do instead: Rely on AST/compile-time macro paths or use `if Code.ensure_loaded?(Oban)` in logic where behavior is optionally invoked.
- **Anti-pattern:** Using raw Regex to inject `plug Parapet.Plug.Metrics`. This breaks easily if a developer format their endpoint unexpectedly. What to do instead: Use `Igniter` AST patching helpers.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Idempotent Code Patching | Complex Regex/Sed Scripts | `igniter` | Regex fails catastrophically on Elixir formatting changes; Igniter parses AST and ensures idempotency without breaking format. |
| Global Registry/Cache | Custom ETS table/GenServer | `:telemetry` | Standard `:telemetry` is written in highly concurrent Erlang for the sole purpose of fast function routing and event distribution. |
| Public API Guard Check | Custom Regex file parser | `Code.fetch_docs/1` | Native capability precisely captures `@moduledoc false` versus actual public documents. |

**Key insight:** Developer experience tooling (CLI generators, patching) in Elixir has evolved significantly with `igniter`. Using it directly means adopters get robust `--dry-run` and clean rollbacks for free.

## Common Pitfalls

### Pitfall 1: Telemetry Handler Process Crashes
**What goes wrong:** A telemetry callback executes synchronously in the process that emitted the event (e.g., a Phoenix web request process). If the callback raises an exception, the web request crashes.
**Why it happens:** Missing `try/rescue` isolation in library code.
**How to avoid:** Never use raw `:telemetry.attach/4` directly in the metrics surface; always pipe through `Parapet.Internal.SafeHandler.attach/5`.

### Pitfall 2: Metric Cardinality Explosions
**What goes wrong:** Adopters map high-cardinality metadata (e.g. `user_id` or `/api/users/8372`) to Prometheus metric labels, blowing up Prometheus memory usage.
**Why it happens:** Lack of compiler-level or instantiation-level guardrails.
**How to avoid:** Implement a strict whitelist or regex blacklist in `Parapet.Internal.LabelPolicy` that rejects labels matching `~r/id$/` or `~r/path/` at registration time.

### Pitfall 3: Failing CI from Optional Dependencies
**What goes wrong:** Dialyzer or compile phases fail because code references `Oban` or `Sigra` when it hasn't been added to the project.
**Why it happens:** Standard code paths attempting to invoke missing library interfaces.
**How to avoid:** Keep integration bindings contained, and wrap them with `if Code.ensure_loaded?(Module)` guards so the compiler eliminates the unreachable code gracefully.

## Code Examples

### Compile-Time Label Safety Checks
```elixir
defmodule Parapet.Internal.LabelPolicy do
  @unsafe_patterns [~r/id$/, ~r/^raw_/, ~r/token/, ~r/path/]

  @doc """
  Evaluates a list of labels against a blacklist of high-cardinality names.
  Raises an ArgumentError if validation fails, ideal for macro/compile-time validation.
  """
  def assert_safe!(labels) when is_list(labels) do
    Enum.each(labels, fn label ->
      label_str = to_string(label)
      if Enum.any?(@unsafe_patterns, &Regex.match?(&1, label_str)) do
        raise ArgumentError, "High cardinality label rejected by Parapet safety policy: #{label}"
      end
    end)
    :ok
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom Mix task generators (Regex) | `Igniter` composable AST generators | ~2024 (Ash ecosystem popularized) | Safer, idempotent, composable host project modifications. |
| Undocumented public modules | `mix verify.public_api` validation | - | CI physically prevents the library from hiding internal logic or shipping un-documented functions. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Code.fetch_docs/1` can reliably identify undocumented public modules. | Architecture Patterns | If incorrect, `mix verify.public_api` will have to use a heavier AST parser or be less strict. |
| A2 | Igniter's patching mechanisms for Phoenix Endpoints (`Igniter.Code.Function`) are robust enough for complex, custom host apps. | Installation | The installer might abort or generate bad code on deeply modified host endpoints. |

## Open Questions (RESOLVED)

1. **Igniter Endpoint Injection Anchor**
   - What we know: Igniter injects code, but we need to inject `plug Parapet.Plug.Metrics` specifically before the Router or after Logger.
   - What's unclear: Does `igniter` have built-in Phoenix Endpoint injection anchor knowledge out-of-the-box, or do we need to provide a custom Sourceror zipper search?
   - Resolution: `igniter` has `Igniter.Libs.Phoenix.endpoints_for/2` and `Igniter.Project.Module.find_and_update_module/3`. While it has built-in Phoenix support, inserting a plug at a specific point (e.g., before `Plug.Telemetry`) requires a custom `Sourceror` traversal using `Igniter.Code.Common.move_to/2` or `Igniter.Code.Function.move_to_function_call/3` within the module updater. We will use Igniter's code traversal functions to locate `Plug.Telemetry` and insert our plug immediately before it.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` and `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TELE-04 | Exception-safe telemetry handlers do not crash | unit | `mix test test/parapet/internal/safe_handler_test.exs` | ❌ Wave 0 |
| TELE-03 | High-cardinality label keys are rejected | unit | `mix test test/parapet/internal/label_policy_test.exs` | ❌ Wave 0 |
| INST-04 | Installer task runs idempotently via Igniter | e2e | `mix test test/mix/tasks/parapet.install_test.exs` | ❌ Wave 0 |
| PKG-04 | `mix verify.public_api` detects missing docs | integration | `mix test test/mix/tasks/verify_public_api_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] Base project generated via `mix new parapet --sup`
- [ ] `test/test_helper.exs` setup for Igniter task assertions

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | Label Policy Whitelist/Regex |
| V7 Error Handling | yes | `try/rescue` wrapper bounds in all handler callbacks |

### Known Threat Patterns for Elixir/Telemetry

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Telemetry Handler Crash Cascades | Denial of Service | Isolate metric functions using a uniform `try/rescue` handler wrapper; emit error logs. |
| Prometheus OOM (Label Cardinality) | Denial of Service | Ensure that raw IDs/paths are blocked at module definition time. |

## Sources

### Primary (HIGH confidence)
- [Context7 library ID: /ash-project/igniter] - Verified Igniter `Igniter.Mix.Task` logic and composability rules.
- [Official docs URL: https://hexdocs.pm/telemetry/readme.html] - Telemetry standard mechanics.
- [Official docs URL: https://hexdocs.pm/elixir/Code.html#ensure_loaded?/1] - Safe dynamic code execution checks.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `igniter` and `telemetry` are industry standard in Elixir.
- Architecture: HIGH - Telemetry wrappers and Igniter scaffolding are robust.
- Pitfalls: HIGH - Documented issues common to Phoenix telemetry instrumentations.

**Research date:** 2026-05-09
**Valid until:** 2026-12-31
