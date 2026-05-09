# Pitfalls Research

**Domain:** Phoenix SaaS reliability layer / SRE substrate library
**Researched:** 2026-05-09
**Confidence:** HIGH — grounded in extensive existing research in `prompts/`, Elixir ecosystem documentation, and Google SRE canonical sources

---

## Critical Pitfalls

### Pitfall 1: High-Cardinality Metric Labels

**What goes wrong:**
A metric label receives values that are unbounded or near-unbounded — `user_id`, `account_id`, `request_id`, `email`, raw URL path, `invoice_id`, `order_id`, `error_message`, SQL query text. Each unique label set creates a separate Prometheus time series. What looks like one metric becomes millions of series, scrape costs spike, retention fails, and backends fall over.

**Why it happens:**
Developers think in "I want to filter by X in my dashboard," and reach for X as a label without understanding the time-series explosion model. The Phoenix `:phoenix, :router_dispatch, :stop` event includes `conn.request_path` which is tempting to use directly — but any route with path params becomes an unbounded series.

**How to avoid:**
Use only low-cardinality, enumerable values as metric labels: `route` (Phoenix route pattern, not raw path), `method`, `status_class` (2xx/4xx/5xx, not raw status code), `queue`, `worker`, `provider`, `environment`. Put `user_id`, `request_id`, `trace_id` in wide events and structured logs, never in metric labels. The `mix parapet.doctor` check must detect high-cardinality labels and fail loudly.

**Warning signs:**
Prometheus TSDB size growing faster than traffic. Scrape duration increasing. Dashboard queries timing out. Alerts like `prometheus_tsdb_head_series > 100000` firing. Finding that you cannot query a metric by the label value you want because there are too many values.

**Phase to address:**
Phase 1 (Telemetry foundation). The `Parapet.Telemetry` layer must enforce low-cardinality labels by default. Doctor checks must flag violations. This cannot be retrofitted — cardinality decisions made in v0.1 become the semver contract.

---

### Pitfall 2: Blocking Inside Telemetry Handlers

**What goes wrong:**
A telemetry handler performs a synchronous HTTP call (notifying Slack, calling an alerting API), a slow database query, a serialization of a large payload, or any blocking operation. Because telemetry handlers run synchronously in the emitting process, they block the Phoenix request that triggered the event. A handler that takes 200ms blocks every request it observes for 200ms.

**Why it happens:**
Telemetry feels like an event bus ("emit and forget"), but the handler runs in the calling process synchronously. It is extremely easy to add a `Logger.info` call, a GenServer cast that turns into a call, or a metrics recording that touches a slow ETS table, without realizing the hot-path cost. Phoenix telemetry docs explicitly warn that metric tag value functions run on every event — any expensive function here is a hot-path cost.

**How to avoid:**
Telemetry handlers must: classify, normalize, enqueue/export, return. Never perform network calls, expensive DB queries, large payload serialization, or LLM calls inside a handler. Parapet's internal handlers must demonstrate this pattern and test it. Provide benchmarks showing handler overhead. The `mix parapet.doctor` check should detect common patterns of blocking work in handlers.

**Warning signs:**
Request latency increases after installing Parapet. Request latency correlates with metrics export errors. Handler errors showing up in telemetry handler crash logs. p99 latency spiking while p50 stays flat (inconsistent extra work).

**Phase to address:**
Phase 1 (Telemetry foundation). Every Parapet handler must be written to this discipline from day one. Document it as a constraint in the library's CONTRIBUTING guide and architecture docs.

---

### Pitfall 3: Telemetry Handler Crashes Silently Detach

**What goes wrong:**
When a telemetry handler crashes, `:telemetry` automatically detaches it. The handler stops receiving events with no warning, no error page, no alert. Metrics stop updating. SLO windows go stale. The problem may not be noticed until someone manually queries Prometheus and sees a metric with no new data points, or until an on-call alert fails to fire because the underlying recording rule has no data.

**Why it happens:**
The `:telemetry` library is intentionally designed this way — a crashing handler should not take down the emitting process. The silent detach is the correct behavior for isolation, but it is a footgun for reliability. Developers assume "if the app is up, metrics are flowing."

**How to avoid:**
Every Parapet telemetry handler must be wrapped in a supervisor that re-attaches on crash. Emit a dedicated metric (`parapet_handler_attach_total`, `parapet_handler_detach_total`) so detachment is observable. Add a `mix parapet.doctor` check that verifies handlers are attached. Provide a `Parapet.Telemetry.health/0` function that reports handler attach status.

**Warning signs:**
Metric series showing gaps or stale last-value. SLO windows computing on zero denominator (no total events). `telemetry_metric_detach_count` metric increasing. Grafana panels showing "No data."

**Phase to address:**
Phase 1 (Telemetry foundation). This must be solved in the supervisor design before v0.1 ships.

---

### Pitfall 4: Plug.Telemetry Stop Event Treated as a Complete Span

**What goes wrong:**
`Plug.Telemetry` is used to measure full request duration, but the `:stop` event is not emitted in all error cases. If a connection is closed abnormally, the handler exits, or a plug raises without being caught, the stop event may not fire. Building SLO numerators and denominators on Plug.Telemetry stop counts produces wrong math — some requests go uncounted as "bad" because they are not counted at all.

**Why it happens:**
The Plug.Telemetry docs explicitly state the stop event is not guaranteed in all error cases and that it cannot be used as a Telemetry span. Developers either miss this note or assume it is rare enough to ignore. It is not rare in production — connection timeouts, upstream resets, and unhandled exceptions in plugs all trigger it.

**How to avoid:**
Use Phoenix router/endpoint telemetry events (`:phoenix, :router_dispatch, :stop` and `:phoenix, :endpoint, :stop`) as the primary SLO signal source — these are emitted more reliably by the Phoenix framework. Use Plug.Telemetry only for pipeline-specific timing where the stop guarantee is not load-bearing for SLO math. Document this decision explicitly in Parapet architecture docs.

**Warning signs:**
SLO error ratio unexpectedly low. Total event count lower than actual traffic under load. Grafana showing dropped request counts under error spikes. SLO "good rate" appearing above 100%.

**Phase to address:**
Phase 1 (Telemetry foundation). The event source selection is a correctness constraint, not an optimization.

---

### Pitfall 5: Oban Retry Treated as Immediate User Harm

**What goes wrong:**
An alert fires every time an Oban job enters `:failure` state. Because Oban retries jobs with backoff, a transient failure on attempt 1 of 20 fires the alert — even though the job completes successfully on attempt 2. Alert fatigue sets in. The on-call person starts ignoring Oban alerts. When a queue genuinely stalls, it goes unnoticed.

**Why it happens:**
The Oban telemetry `:exception` event fires on every failed attempt, not on job exhaustion. Developers map "job exception = job failure = page" without understanding retry semantics. This is the same class of mistake as alerting on a single 500 rather than a 5xx burn rate.

**How to avoid:**
Page on discard (exhausted retries, `:discard` state) for critical queues, not on `:failure`. Alert on queue latency (time from scheduled_at to execution_start exceeding threshold) for stuck-queue detection. Build SLOs on attempt-success-rate over a window, not per-attempt failure counts. Separate critical queues (login emails, payment hooks) from noncritical queues in SLO definitions — they deserve different objectives and alerting thresholds.

**Warning signs:**
High alert volume from Oban with low actual user impact. Alert-to-incident ratio < 0.1 for job alerts. On-call acknowledging Oban alerts without investigating.

**Phase to address:**
Phase 2 (Oban SLO slice). The SLO DSL must enforce retry-aware semantics. The install guide must explain the discard-vs-failure distinction explicitly.

---

### Pitfall 6: Telemetry Events Not Treated as a Public API

**What goes wrong:**
A Parapet minor release renames a telemetry event, adds or removes a measurement, or changes a metadata key. Adopters who have built custom Grafana panels, Prometheus recording rules, or ExUnit tests against that event name experience silent breakage — their panels show "No data," their recording rules produce null, and their CI stays green because Parapet's own tests pass.

**Why it happens:**
Library authors treat internal module names and function signatures as the API surface and forget that telemetry events are also a public API. Semver semantics do not automatically protect against event renames in minor versions because the compiler cannot enforce event contracts.

**How to avoid:**
Document every Parapet telemetry event as part of the public API in the changelog and ExDoc. Treat event renames, measurement renames, or metadata key removals as breaking changes requiring a major version bump. Add a snapshot test suite for the telemetry event contract that fails if any event name, measurement name, or documented metadata key changes. Include the telemetry contract in the `files:` whitelist so it is visible in the published package.

**Warning signs:**
Adopter Grafana panels showing gaps after a Parapet upgrade. Adopter recording rules returning null after upgrade. Adopter custom alerting rules firing incorrectly.

**Phase to address:**
Phase 1 (Telemetry foundation). The contract must be explicit before the first stable release.

---

### Pitfall 7: SLO Math Errors — Averaging Ratios

**What goes wrong:**
An SLO is implemented by averaging error rates over time windows, or by computing `avg(rate(...))` in PromQL instead of `sum(rate(good[w])) / sum(rate(total[w]))`. The result is a statistically incorrect error ratio that underweights high-traffic intervals and overweights low-traffic intervals. A 1% error rate during 1 req/s and 0.01% during 1000 req/s should not average to 0.505%.

**Why it happens:**
Averaging feels intuitive. PromQL's `avg()` function is natural to reach for. The Prometheus recording rule best practices for ratio math are not widely known — they explicitly say to aggregate numerators and denominators separately, then divide.

**How to avoid:**
Parapet's SLO engine must always store and aggregate `good_events_total` and `total_events_total` as separate counters. Recording rules must compute `sum(rate(good[w])) / sum(rate(total[w]))`. Never compute `avg(error_rate)`. Burn-rate alerting must use the correctly-computed ratio. Add a test that validates generated PromQL against known correct values.

**Warning signs:**
SLO percentage fluctuating unexpectedly during traffic spikes. Error budget appearing to recover faster than expected. SLO appearing to hit 100.0% during low-traffic periods.

**Phase to address:**
Phase 2 (SLO engine). This is a correctness requirement for the SLO DSL. Generated PromQL must be tested with `promtool`.

---

### Pitfall 8: /metrics and LiveDashboard Exposed Without Authentication in Production

**What goes wrong:**
The Prometheus `/metrics` endpoint is mounted publicly (reachable from the internet), exposing internal application metrics — route names, queue names, worker names, error classes, version strings. LiveDashboard is mounted in production without an auth plug, exposing process lists, ETS tables, database pool state, and connected node information. Both are security incidents that could assist an attacker in mapping the application's internals.

**Why it happens:**
Both ship with working defaults that are fine for development. Developers copy the dev config to production without adding auth or network restrictions. `telemetry_metrics_prometheus` explicitly documents that its bundled server does not support HTTPS. LiveDashboard docs warn about production security but the warning is easy to miss.

**How to avoid:**
`mix parapet.doctor` must detect and hard-fail on a publicly accessible `/metrics` endpoint in production and a LiveDashboard mount without an auth plug. The install guide must document three safe patterns: (1) private metrics port scraped on an internal network, (2) Phoenix route protected by auth or IP allowlist, (3) sidecar/exporter mode in container deployments. The doctor check must exit nonzero (hard failure) so CI fails.

**Warning signs:**
`curl https://yourapp.com/metrics` returning Prometheus data. LiveDashboard accessible without login in production. Security scanner flagging internal endpoint exposure.

**Phase to address:**
Phase 1 (foundation). The generator must produce secure defaults. Doctor must hard-fail on insecure production exposure.

---

### Pitfall 9: Duplicate Telemetry Handler Attachment in Dev/Hot Reload

**What goes wrong:**
In Phoenix dev mode, the application restarts on code changes (hot reload via `Code.purge`). If Parapet attaches telemetry handlers in `Application.start/2` without checking whether they are already attached, each hot reload duplicates all handlers. Events get processed N times. Metrics double-count (or triple, or more). Prometheus recording rules produce inflated values. The behavior is invisible until someone looks at raw metric rates.

**Why it happens:**
`:telemetry.attach/4` does not check for duplicates by default — it overwrites on the same handler ID but silently accepts reattachment under different IDs. Libraries that generate handler IDs dynamically or use anonymous function references create a new ID on every attach call.

**How to avoid:**
Use stable, deterministic handler IDs (e.g., `"parapet.phoenix.request"` as a string, not a dynamic reference). Use `:telemetry.attach/4`'s return value to detect existing handlers. Attach handlers in the Parapet supervisor child, not in `Application.start/2` directly, so the supervisor lifecycle owns reattachment correctly. Add a dev-mode test that verifies handler idempotency across simulated reloads.

**Warning signs:**
Metrics showing request counts higher than actual traffic in dev. Double-counting visible when comparing Phoenix access logs to Prometheus counters. Tests failing with "handler already exists" errors.

**Phase to address:**
Phase 1 (Telemetry foundation). Handler lifecycle design.

---

### Pitfall 10: Optional Dependencies That Don't Compile Out Cleanly

**What goes wrong:**
Parapet declares `oban`, `sigra`, or another integration dep as optional in `mix.exs`, but at runtime, a module or macro in the optional code path gets compiled unconditionally. When an adopter without Oban installed compiles their project, they get `UndefinedFunctionError` or a compile warning about missing module. The library fails to load. The adopter abandons the integration.

**Why it happens:**
Elixir's optional dependency system requires active discipline. `Code.ensure_loaded?/1` guards, `@optional_callbacks`, and conditional macro expansion must be applied consistently. It is easy to miss a reference in a shared module, a macro that generates code referencing an optional module, or a protocol implementation that conditionally compiles.

**How to avoid:**
Every integration module (Oban, Sigra, etc.) must live in a namespace isolated from the core. Use `Code.ensure_loaded?/1` guards at the module level. Test the package with and without each optional dep via a CI matrix that installs Parapet without optional deps and verifies compilation. Add a `mix verify.optional_deps` task that confirms clean compilation with each optional dep absent. This is in the engineering DNA as a hard constraint.

**Warning signs:**
Compilation warnings in adopter projects that do not use all integrations. `UndefinedFunctionError` at load time for adopters without optional deps. CI matrix only tests with all deps present.

**Phase to address:**
Phase 1 (foundation) for Oban. Phase 2+ for each new integration. Test it before each Hex publish.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use raw `conn.request_path` as a metric label | Easy to add, shows exact URLs in dashboards | Cardinality explosion; cannot be fixed without breaking the metric contract (series rename) | Never |
| Skip SLO volume gates for low-traffic routes | Simpler SLO definition | SLO fires on 1 error out of 2 requests; burn rate alerts are meaningless | Never for v0.1 defaults; gate volume explicitly |
| Hardcode metric names as strings | Fast to implement | Renaming requires adopters to update dashboards, Prometheus rules, and alert configs | Never — use module constants or DSL-generated names |
| Attach telemetry handlers in `Application.start/2` without supervisor supervision | Simple startup | Handlers lost on crash; no automatic re-attach | Only acceptable as a documented limitation with explicit caveat |
| Ship Grafana dashboards as non-parameterized JSON | Minimal tooling required | Adopters can't customize without forking; Parapet version upgrades don't update dashboards | Acceptable for v0.1 if documented; must be revisited in v0.2 |
| Use `:telemetry_metrics_prometheus` instead of a pluggable reporter interface | Faster to ship | Adopters who use PromEx, Peep, or StatsD need a fork; locks the library to one reporter | Never — design the adapter seam even if only one adapter ships in v0.1 |
| Average error rates instead of summing numerator/denominator | Simpler PromQL | Incorrect SLO math that over- or under-estimates error budget | Never |
| Skip promtool validation on generated Prometheus rules | Faster CI | Syntactically invalid rules silently fail to load; no alert fires | Never — run promtool in CI as a hard check |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Prometheus scraping | Scrape endpoint responds on the same port as the app HTTP traffic, mixing telemetry requests into request metrics | Use PromEx's plug ordering: `PromEx.Plug` before `Plug.Telemetry` to exclude scrape requests from request metrics |
| Oban telemetry | Subscribing to `:exception` events for failure alerting (fires on every retry) | Use `:discard` events for "job permanently failed" and queue latency for "queue stuck" |
| Phoenix route telemetry | Using `:phoenix, :endpoint, :stop` for route-level SLOs | Use `:phoenix, :router_dispatch, :stop` which includes route metadata; endpoint stop fires before routing |
| Ecto query telemetry | Using only `query_time` for DB health | Include `queue_time` — high queue_time with normal query_time means pool saturation, not slow queries |
| Grafana dashboard provisioning | Providing raw Grafana JSON without datasource variable parameterization | Use Grafana templating variables for datasource UID so dashboards work across different Grafana installs |
| Email webhook events | Accepting webhook events without verifying provider signatures | Verify HMAC/ECDSA/SNS signatures before processing; emit `parapet_webhook_verification_failed_total` metric for failed verifications |
| Sigra integration | Hard-coupling auth events to Parapet at compile time | Use telemetry event subscription from Sigra's documented events; Parapet attaches to public telemetry, does not import Sigra modules |
| Deploy correlation | Injecting `RELEASE_SHA` via app config at compile time | Read from environment at runtime via `System.get_env/1` in the Parapet supervisor start; compile-time values survive across releases |

---

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| 100% trace sampling forever | Trace storage costs explode; exporter queue backs up under load | Configure head-based sampling: 100% for errors/critical journeys, 5-10% for normal traffic | Around 100 req/s sustained in a small deployment |
| High-cardinality histogram dimensions | Prometheus TSDB grows unboundedly; scrape duration increases | Use bounded label sets; use `status_class` not `status_code` in histogram labels | At ~10k unique label combinations |
| Expensive tag value functions in telemetry tag config | p99 latency spike; telemetry handler overhead measured in milliseconds per request | Tag value functions must be pure, O(1), and non-allocating | Immediately at any production traffic |
| Synchronous export on every event | Request path blocked by network I/O to Prometheus push gateway | Buffer and batch exports via GenServer or ETS; never export synchronously in handler | Immediately in any push-based export model |
| No backpressure on the event export queue | Memory grows unboundedly under export failure; crash cascades | Implement bounded queue with shed policy: drop sampled successes first, always keep errors and SLO-relevant events | When export backend is temporarily unavailable |
| Keeping all Oban telemetry for all queues equally | High-volume queues (email sends) bury critical queue metrics | Define separate SLO targets per queue; use `queue` label to filter; consider sampling noncritical job events | At sustained Oban job rates above ~1000/min |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| PII in metric labels | Prometheus data becomes a PII store; may violate GDPR/CCPA; cannot be selectively deleted from TSDB | Never allow `email`, `user_id`, `ip_address`, `full_name` as metric labels; doctor check must hard-fail on detected PII labels |
| Email webhook without signature verification | Attackers can spoof provider events; fabricate "email delivered" events; trigger false SLO credit | Verify signatures for all providers (HMAC for Postmark, ECDSA for SendGrid, SNS signature for SES) before processing any event; reject unsigned requests in prod |
| /metrics endpoint serving internal metric names publicly | Aids attacker reconnaissance — reveals route patterns, worker names, queue names, error classes, version strings | Require explicit authorization; hard-fail in doctor if reachable from internet in production config |
| MCP tools without audit trail | Untracked production actions by AI agents; no forensic record; possible prompt injection via tool output | Require `audit_sink` configuration before enabling any approval-gated MCP tool; log every tool call with input hash, output hash, actor, and tool name |
| Redaction applied only to HTTP logs | PII leaking through telemetry events, wide events, or BEAM crash dumps | Apply Parapet's redaction policy at the telemetry emission layer, not just the logger layer; treat telemetry metadata as a separate PII boundary |
| LiveDashboard in production without authentication | Exposes process list, ETS data, connection pool, node names, and system metrics without authentication | Mount LiveDashboard behind an auth plug; doctor must hard-fail if mount detected without an authentication check plug in the pipeline |

---

## DX / Adopter Experience Pitfalls

Common mistakes that create a poor adoption experience.

| Pitfall | Adopter Impact | Better Approach |
|---------|----------------|-----------------|
| Generator produces files the adopter cannot understand | Adopter fears modifying generated code; treats Parapet like a black box; abandons customization | Generated code must be idiomatic Phoenix; every generated file needs a header comment explaining its purpose and how to customize it |
| Default SLO targets that don't match the adopter's traffic | SLO fires immediately on a low-traffic staging environment; adopter disables SLOs | Ship volume gates as defaults; make SLOs self-silencing below a minimum traffic threshold |
| Doctor command that warns on everything | Adopter ignores all warnings; critical issues hidden in noise | Distinguish hard failures (exit 2) from actionable warnings (exit 1) from informational notes (exit 0); keep hard failures to < 5 checks |
| Missing Day-1 "First Alert" narrative | Adopter installs Parapet, sees dashboards, but doesn't know if an alert will fire when something breaks | The install guide must walk through a complete scenario: install → deploy → SLO fires → alert routes to Alertmanager → runbook link in annotation |
| Telemetry event names that conflict with the host app | Silent event shadowing; adopter's existing telemetry handlers receive wrong events | Use the `parapet.*` namespace exclusively for all library-internal events; document the namespace separation |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **SLO configured:** Does it have a volume gate? Without one, 1 error out of 2 requests burns the full 30-day budget in seconds — verify `volume_gate min:` is set
- [ ] **Prometheus rules generated:** Has promtool validated the YAML? — run `promtool check rules priv/parapet/prometheus/*.yml`
- [ ] **Grafana dashboard deployed:** Is the datasource variable parameterized? — open the dashboard in a fresh Grafana without hardcoded datasource UID
- [ ] **Telemetry handlers attached:** Are handlers re-attached after crash? — check supervisor tree includes a handler watchdog
- [ ] **Deploy marker configured:** Is `RELEASE_SHA` or equivalent wired into the Parapet config? — check doctor output for "deployment_id not configured" warning
- [ ] **/metrics secured:** Is the endpoint blocked from public internet in production? — run doctor with `--env prod` flag
- [ ] **Optional deps verified absent:** Has the package compiled cleanly without Oban and Sigra? — CI must test with `mix deps.get` excluding optional deps
- [ ] **Telemetry event contract documented:** Are all emitted event names listed in the changelog as public API? — check hexdocs for the telemetry contract section
- [ ] **Email webhook verification enabled:** Is signature checking active for every provider? — check doctor for "email webhook lacks signature verification" warning
- [ ] **SLO burn rate rules generated:** Are recording rules present alongside alert rules? — burn-rate alerts require recording rules to be loaded first

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| High-cardinality label discovered after release | HIGH | Create new metric with correct labels; run both old and new metrics in parallel for one release; deprecate old metric in changelog with major version bump; update all dashboard/alert references |
| Telemetry handler silently detached in production | LOW | Add supervisor re-attach logic; deploy; verify handler attachment via doctor or health check endpoint; add `parapet_handler_attach_total` metric as a monitoring signal |
| SLO math computed via averaging (wrong) | MEDIUM | Correct the recording rule; re-run Prometheus backfill if supported; document the window of incorrect data; notify adopters via changelog |
| Generated Prometheus rules fail promtool validation | LOW | Fix the rule template; add promtool to CI; redeploy; rules are stateless so no data migration required |
| PII discovered in metric labels | HIGH | Prometheus TSDB cannot selectively delete series — must rotate to new metric names; notify adopters; possible regulatory disclosure obligation; add doctor check that would have caught it |
| Optional dep coupling breaks compilation | MEDIUM | Release a patch that fixes the guard; document in CHANGELOG; check all integration modules for similar patterns in same release |
| /metrics exposed publicly discovered in security audit | HIGH | Immediately restrict with network firewall rules or reverse proxy; add auth plug; do not wait for the next Parapet release — this is an emergency mitigation |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| High-cardinality labels | Phase 1 — Telemetry foundation | Doctor check detects and hard-fails on known PII labels; CI includes cardinality lint |
| Blocking telemetry handlers | Phase 1 — Telemetry foundation | Benchmark suite shows handler overhead < 1ms p99; handler tests validate no blocking calls |
| Handler crash/detach | Phase 1 — Telemetry foundation | Integration test simulates handler crash and verifies re-attach; `parapet_handler_attach_total` metric emitted |
| Plug.Telemetry stop event gap | Phase 1 — Telemetry foundation | Documentation and code comments explain event source selection; integration test validates event counts match traffic |
| Oban retry treated as user harm | Phase 2 — Oban SLO slice | SLO DSL only exposes discard/stuck-queue signals for alerting; single-retry failures do not appear in SLO bad event count |
| Telemetry events as public API | Phase 1 — Telemetry foundation | Snapshot test verifies event contract; CHANGELOG template includes "telemetry contract changes" section |
| SLO math / ratio averaging | Phase 2 — SLO engine | Generated PromQL validated against known correct values; promtool run in CI |
| /metrics and dashboard auth | Phase 1 — Telemetry foundation | Doctor hard-fails on insecure production exposure; install guide documents auth patterns |
| Duplicate handler attachment | Phase 1 — Telemetry foundation | Dev-mode test verifies idempotent attach under simulated hot reload |
| Optional dep compilation | Phase 1 — Telemetry foundation, per integration | CI matrix without each optional dep; `mix verify.optional_deps` task |
| Telemetry event not API | Phase 1 — Telemetry foundation | ExDoc telemetry contract section; snapshot tests; CHANGELOG discipline |
| PII in metrics | Phase 1 — Telemetry foundation | Doctor check; redaction applied at handler emission, not only at logger |
| Email webhook security | Phase 3+ (email SLO) | Signature verification required before event processing; doctor check |
| Deploy correlation | Phase 2 — SLO engine | Doctor warns on missing `deployment_id`; install guide includes `RELEASE_SHA` wiring |

---

## Sources

- `prompts/sre-observability-elixir-lib-deep-reseach.md` — Section 43 "Deep footgun list" (cardinality, alerting, Phoenix/Ecto/Oban, email, AI footguns) — HIGH confidence
- `prompts/elixir-telemetry-space-deep-research.md` — PromEx plug ordering, Peep performance, handler lifecycle, Plug.Telemetry stop event caveat — HIGH confidence
- `prompts/sre-best-practices-solo-founder-deep-research.md` — SLO alerting, burn rate math, alert fatigue — HIGH confidence
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — Optional dep contract, telemetry as public API, host-owned generated code — HIGH confidence
- Prometheus documentation on cardinality, recording rules, and ratio math — HIGH confidence (cited in research docs)
- Google SRE Workbook on burn-rate alerting and multi-window alert design — HIGH confidence (cited in research docs)
- Plug.Telemetry official docs — stop event not guaranteed (cited in research docs) — HIGH confidence
- Oban.Telemetry official docs — `:exception` vs `:discard` event semantics — HIGH confidence (cited in research docs)
- Phoenix.Logger official docs — parameter filtering as one layer, not complete PII policy — HIGH confidence (cited in research docs)

---

*Pitfalls research for: Phoenix SaaS reliability layer (Parapet)*
*Researched: 2026-05-09*
