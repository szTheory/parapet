# Parapet SLO Authoring Guide

Parapet is built around a simple conviction: an SLO should track whether users can do the things they came to your app to do, not whether the servers are breathing. A CPU gauge that stays under 80% tells you nothing about whether login is working. A journey SLO that burns at 2% tells you exactly what is wrong and who is affected.

This guide walks through how to decide what deserves a slice, how to use the built-in `Parapet.SLO.StarterPack.WebSaaS` slices as anchors for your own decisions, and how to handle the situations where low traffic or low volume makes naive alerting unreliable.

For the full provider and slice catalog - including built-in provider modules for Mailglass, Chimeway, Rindle, and the WebSaaS pack - see [Parapet SLO Reference](docs/slo-reference.md).

## How to decide what to slice

The decision is not about what you can measure. It is about what failing would cost a user.

Use this tree to decide whether a potential signal warrants its own journey SLO:

- **Does this failure directly prevent a user task?**
  - Yes -> this is a candidate for a journey SLO. Continue down.
    - **Is the failure observable through a metric Parapet already emits (or that your integration emits)?**
      - Yes -> define a slice against that metric.
      - No -> wire the metric first (or use a synthetic probe - see the low-traffic section below), then define the slice.
    - **Is the failure synchronous (request-time) or async (job, callback, provider-mediated)?**
      - Synchronous -> use an HTTP availability or login-journey style ratio slice.
      - Async -> use a job-success or delivery-confirmation style slice.
  - No (infrastructure-only signal, does not directly prevent a user task) -> this is not a journey SLO. Consider a system-health dashboard instead.

**Litmus:** "Does this failure directly prevent a user task?" is the one question you should always answer first.

**Good examples** from `Parapet.SLO.StarterPack.WebSaaS`:

- `web_saas_login_journey` - a failed login directly blocks the user from entering your app. Auth failures are low-volume, high-impact, and exactly what a journey SLO is for.
- `web_saas_http_availability` - request-level availability is the baseline user expectation. A user who cannot load a page is directly blocked.
- `web_saas_oban_job_success` - Oban job failures directly affect users when the job gates a user-visible outcome (order confirmation, email delivery, image processing, billing). Wire a job-success slice for each critical async path.

**Bad example:**

- A CPU utilization or memory gauge SLO. CPU at 95% does not directly prevent a user task. You might be processing batch work, running GC, or handling a spike with headroom to spare. Alerting on raw infrastructure metrics produces noise without actionable user-impact framing.

**Real anchor:** The three `web_saas_*` slice names in `Parapet.SLO.StarterPack.WebSaaS` are the reference implementation. Each is pinned to a real Prometheus series, has a documented default objective in human terms, and is overridable. Read the source or [Parapet SLO Reference](docs/slo-reference.md) to understand the defaults before changing them.

## Writing a custom slice

When the built-in packs do not cover your journey, you define a custom provider module that returns `Parapet.SLO.SliceSpec` structs. The `SliceSpec` struct drives all generator output - you never write raw PromQL.

The minimum fields are `name`, `integration`, `kind`, `alert_class`, `runbook`, a good metric + matchers, and a total metric + matchers. Set `objective` as a percentage (e.g., `99.5`) and the Generator derives the error-rate threshold for you.

Register your provider module the same way as the built-ins:

```elixir
config :parapet,
  providers: [
    Parapet.SLO.StarterPack.WebSaaS,
    MyApp.SLO.CheckoutJourney
  ]
```

Then run `mix parapet.gen.prometheus` to write the recording rules and alert expressions. You never hand-write PromQL.

## Provider-as-bundle pattern

A `Parapet.SLO.Provider` that returns slices from multiple sub-providers is the bundle abstraction. No separate macro or base module is required — the `slos/0` callback returns a flat list, and list concatenation (`++`) is the composition primitive.

The canonical example is `Parapet.SLO.StarterPack.DeliverySaaS`, which composes three providers into one registration: the three WebSaaS slices plus conditionally-guarded Mailglass and Chimeway delivery slices. Its `slos/0` calls `WebSaaS.slos() ++ delivery_slices(Mailglass, Chimeway)`, where each delivery slice set is included only when the corresponding host library is loaded.

```elixir
defmodule MyApp.SLO.FullStack do
  @behaviour Parapet.SLO.Provider

  @impl true
  def slos do
    Parapet.SLO.StarterPack.WebSaaS.slos() ++
      (if Code.ensure_loaded?(Mailglass), do: Parapet.SLO.MailglassDelivery.slos(), else: []) ++
      my_custom_slices()
  end

  defp my_custom_slices, do: [...]
end
```

Register the bundle provider the same way as any single provider:

```elixir
config :parapet, providers: [MyApp.SLO.FullStack]
```

**Conditional registration:** Use `Code.ensure_loaded?/1` to guard slices for optional host libraries. The bundle module itself is always loadable (passes `mix verify.public_api`) regardless of whether the guarded library is present. This is the pattern used by `Parapet.SLO.StarterPack.DeliverySaaS` — see its moduledoc for the reference implementation.

For the full built-in provider catalog and starter packs, see [Parapet SLO Reference](docs/slo-reference.md#starter-packs).

## Low-traffic and low-volume services

Low-traffic services introduce a specific failure mode: the SLO burns when there is not enough data to know. A single failed login attempt out of five total produces a 20% error rate - which would fire a page alert - even though five requests is not a meaningful signal. The naive solution is to lower the objective to stop the noise. That is the wrong move.

### The denominator guard the generator renders

Every alert expression the Generator produces includes a denominator guard. For a slice named `web_saas_login_journey` with a `:page` alert class (14.4x multiplier, 5m window) and a 99.9% objective:

```
parapet:web_saas_login_journey:error_ratio:5m > 0.0144 and parapet:web_saas_login_journey:total_rate:5m > 0.01
```

The guard shape is:

```
parapet:<slice_name>:error_ratio:<window> > <threshold> and parapet:<slice_name>:total_rate:<window> > <min_total_rate>
```

The second condition - `total_rate > min_total_rate` - is the denominator guard. The alert fires only when there is enough traffic to make the error ratio meaningful. Without that guard, a single failure in a quiet window would trigger a page.

The 0.0144 threshold comes from the objective: 99.9% -> 0.001 error budget x 14.4 multiplier = 0.0144.

### The min_total_rate default and the six windows

The default `min_total_rate` is `0.01` - defined in `Parapet.SLO.SliceSpec` as the struct default and applied to every slice unless you override it. You can override it per-slice by passing `min_total_rate: <value>` when constructing a `SliceSpec`.

The Generator emits alert expressions for one window per alert class. The full set of recording rule windows is `["5m", "30m", "1h", "2h", "6h", "3d"]`. The alert window and multiplier by class are:

- `:page` - 5m window, 14.4x multiplier
- `:ticket` - 30m window, 6.0x multiplier
- `:warning` - 6h window, 1.0x multiplier

Recording rules are generated for all six windows (`"5m"`, `"30m"`, `"1h"`, `"2h"`, `"6h"`, `"3d"`), so you have history for retrospectives and trend analysis at every granularity.

### The extended-window approach

The 6h and 3d windows the Generator already emits are naturally more tolerant of low-traffic variance - a service that handles 10 requests per day accumulates enough denominator data over six hours to produce a reliable ratio. If you are seeing false-positive `:warning` alerts on a low-volume slice, the first question is not "should I lower the objective?" It is "is the denominator guard firing correctly, and am I looking at the right window?"

### Synthetic probes

When traffic is genuinely too low to produce a reliable signal even at the 6h window - for example, an internal-only workflow that runs once a week - the right tool is a synthetic probe.

`Parapet.Metrics.Probe` is a real, implemented fallback. It emits two metrics:

- `parapet.probe.run.total` - a counter tagged with `probe` and `status`
- `parapet.probe.run.duration.ms` - a distribution for latency tracking

A synthetic probe continuously exercises the journey at a known rate, giving the SLO a stable denominator even on services with negligible organic traffic. The probe outcome then feeds into a slice the same way real traffic does - you define the slice against `parapet.probe.run.total` and the denominator guard works as intended.

## What not to do

These are the failure modes that produce noise instead of signal.

- **Lower the objective to silence noise.** This is the wrong move. Dropping a login-journey SLO from 99.9% to 90% because it was firing on low traffic means you will not page when 10% of your users cannot log in. The denominator guard, extended windows, and synthetic probes exist precisely so you do not have to choose between accuracy and quiet alerts.
- **Alert on infrastructure metrics as if they were journey SLOs.** CPU, memory, and disk are system-health signals. They are useful for capacity planning. They are not journey SLOs, and wiring them as SLOs produces alerts that are both noisy and unactionable.
- **Emit a new journey SLO without wiring a denominator guard.** The Generator handles this for you via the `min_total_rate` field on `SliceSpec` - but if you bypass the Generator and write raw PromQL, you need to add the guard yourself.
- **Assume "no data" means "green."** If a slice has no traffic - for example, the `web_saas_login_journey` slice before you wire the Sigra integration or another login-count emitter - the denominator guard prevents the alert from firing. That is correct behavior. But silence is not a health signal. Use `mix parapet.doctor` and check that the expected metrics are present before treating a quiet slice as a passing one.
