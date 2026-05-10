# Parapet SLO Reference

Service-Level Objectives (SLOs) are a core primitive in Parapet, allowing you to define the expected reliability of critical user journeys in your application.

## Defining an SLO

SLOs are defined using `Parapet.SLO.define/2`. The recommended place to define your application's SLOs is during your application startup (e.g., in `application.ex`) or in a dedicated module that is invoked at startup.

### Example: Login Journey

Here is a complete example of defining an SLO for a critical user journey: user logins.

```elixir
Parapet.SLO.define(:user_login_success,
  objective: 99.9,
  good_events: ~s{sum(rate(phoenix_controller_call_count{action="create", controller="MyAppWeb.UserSessionController", status=~"2.."}[$__rate_interval]))},
  total_events: ~s{sum(rate(phoenix_controller_call_count{action="create", controller="MyAppWeb.UserSessionController"}[$__rate_interval]))},
  runbook: "https://wiki.mycompany.com/runbooks/user_login_failures"
)
```

## Required Fields

Every SLO definition requires the following fields:

- **`name`** (`atom()`): A unique identifier for the SLO. This will be used in generated Prometheus recording rules and alerts.
- **`objective`** (`float()`): The target reliability percentage (e.g., `99.9` for "three nines").
- **`good_events`** (`String.t()`): A PromQL expression that returns the rate of successful events.
- **`total_events`** (`String.t()`): A PromQL expression that returns the rate of all events (successful + failed).
- **`runbook`** (`String.t()`): A required URL pointing to the remediation steps for this specific SLO.

## The Importance of Runbooks

In Parapet, **runbooks are mandatory**. The `mix parapet.doctor` task statically analyzes your SLO definitions to ensure every SLO has a valid runbook URL. 

This enforces the best practice that an alert should never fire without clear, actionable remediation steps for the operator. If a runbook is missing, the `parapet.doctor` task will exit with a failure code, preventing CI/CD pipelines from deploying the configuration.

## Multi-Window Burn-Rate Mechanics

Parapet utilizes the **multi-window, multi-burn-rate** alerting technique recommended by the Google SRE workbook.

Instead of alerting on simple error rate thresholds (which can be noisy or too slow to react), burn-rate alerting measures how quickly you are consuming your error budget.

Parapet automatically generates Prometheus alerting rules for each SLO that evaluate multiple time windows simultaneously:

1. **Short Window (Fast Burn):** Detects massive outages quickly (e.g., 14.4x burn rate over 1 hour). Pages the on-call engineer immediately.
2. **Long Window (Slow Burn):** Detects subtle, lingering degradation (e.g., 1.5x burn rate over 3 days). Creates a ticket rather than paging, preserving on-call sleep.

Because Parapet translates your `good_events`, `total_events`, and `objective` into these complex recording and alerting rules, you get best-in-class alerting out-of-the-box without having to write complex PromQL manually.
