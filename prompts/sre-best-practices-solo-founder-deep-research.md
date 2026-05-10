SRE for a solo SaaS founder: a small, sharp reliability system

You do not need enterprise SRE theater.

You need a control loop:

flowchart LR
  U["Users / customers"] --> H["User harm signals"]
  H --> O["Observability<br/>metrics · traces · logs · events"]
  O --> D["Decision rules<br/>SLOs · alerts · anomaly checks"]
  D --> A["Action<br/>mitigate · rollback · fix · communicate"]
  A --> L["Learning<br/>postmortem · runbook · automation"]
  L --> O

Your job is not to collect every possible signal.

Your job is to make sure that when your SaaS is hurting users, you know quickly, you know what kind of hurt, and you have a calm path to mitigation.

The SRE doctrine I would use for your situation:

Page on user harm. Dashboard on system behavior. Log wide context. Automate boring diagnosis. Use AI as an investigation copilot, not an unbounded production actor.

⸻

The solo-founder version of SRE

Classic SRE was built for teams. You are one person, so you need the essence, not the ceremony.

Enterprise SRE concept	Solo SaaS translation
On-call rotation	“Only wake me for customer-impacting issues.”
Incident commander	A 5-minute decision mode: severity, mitigation, next action.
War room	One incident note, one dashboard, one deploy/change log.
Postmortem	20–40 minute blameless learning loop.
Error budget	Your permission system: ship faster when healthy, slow down when burning reliability.
Observability platform	Cheap, open, queryable context for metrics/logs/traces/business events.
Runbooks	Markdown procedures plus AI-readable context.
Shift-left reliability	Catch migration/deploy/config/perf/deliverability failures before prod users do.

Google’s SRE material is still the best timeless foundation here: monitoring should support trends, alerting, dashboards, debugging, and business/security analysis, but paging is expensive and noisy alerts actively damage response quality. Their guidance is very explicit: pages should represent urgent, actionable, user-visible problems, not “something seems a bit weird.”  ￼

For you, that means:

Wake me:
  users cannot pay
  users cannot log in
  API is broadly failing
  email delivery for transactional mail is broken
  DB is near hard failure
  deploy broke critical flows
Do not wake me:
  CPU is a little high
  p99 twitched once
  one log line says "error"
  business KPI looks weird for 10 minutes at 3am
  a background job retried successfully

⸻

1. The reliability hierarchy

For a solo founder, reliability work should be layered like this:

flowchart TD
  A["Business-critical user journeys"] --> B["SLIs / SLOs"]
  B --> C["Few high-quality alerts"]
  C --> D["Dashboards for investigation"]
  D --> E["Wide events, traces, logs"]
  E --> F["Runbooks"]
  F --> G["Automation / AI copilots"]

Do not start at the bottom with “collect all logs.” Start at the top:

What must keep working for the business to survive?

For a typical B2B/B2C SaaS, the critical journeys are probably:

1. signup
2. login/session
3. checkout/payment
4. core product action
5. background job processing
6. transactional email delivery
7. webhooks from payment/email providers
8. admin/customer support access

Each journey should have:

one or two SLIs
one SLO target
one dashboard section
one alert policy
one runbook

That is the lean version.

⸻

2. RED, USE, Golden Signals, and business KPIs

There are several overlapping models. Use each for the thing it is good at.

RED: best for request-serving systems

RED means:

Rate      how many requests/events per second?
Errors    how many failed?
Duration  how long did they take?

RED is especially good for HTTP endpoints, background jobs, webhooks, queues, and external dependency calls. Grafana describes RED as a simple, consistent method for service monitoring: rate, errors, and duration.  ￼

For Phoenix/SaaS:

HTTP requests:
  rate by route
  4xx/5xx error ratio by route
  p50/p95/p99 latency by route
Checkout:
  checkout started rate
  checkout failed ratio
  checkout duration
  payment provider errors
Email:
  send attempt rate
  provider accepted rate
  bounce/complaint rate
  delivery latency

USE: best for resources

USE means:

Utilization  how busy?
Saturation   how much waiting/backlog?
Errors       how much broken work?

Brendan Gregg’s USE method is intended for resources: CPUs, disks, networks, memory, queues, locks, thread pools, and similar bottlenecks. A key nuance: averages can hide short saturation spikes that cause latency.  ￼

For your stack:

DB pool:
  utilization = connections in use / pool size
  saturation  = checkout queue time
  errors      = timeout/disconnect/query errors
Oban queue:
  utilization = worker concurrency used
  saturation  = queue depth / job wait time
  errors      = retries/discards/failures
Host:
  utilization = CPU/memory/disk usage
  saturation  = load/run queue/iowait
  errors      = disk/network/kernel/service errors

Google’s Four Golden Signals

Google’s SRE book recommends four golden signals:

latency
traffic
errors
saturation

It also warns against relying on averages for latency; histograms and tail behavior matter because averages hide user pain.  ￼

This maps almost perfectly to your world:

Latency     p95/p99 request and job duration
Traffic     requests, signups, checkouts, jobs, emails
Errors      5xx, failed jobs, provider errors, bounces
Saturation  DB queue, job backlog, CPU, disk, memory, rate limits

Business KPIs: useful, but dangerous as pages

Business KPIs are absolutely part of observability now. Grafana’s 2026 observability survey says half of respondents use observability tools to track business metrics. The same survey reports that open source/open standards matter to 77% of respondents, while complexity/overhead remains a major concern. It is a vendor survey, so treat the exact numbers as directional, but the trend matches what teams are doing: observability is expanding beyond pure infra.  ￼

Good business signals:

signup_started
signup_completed
checkout_started
checkout_completed
payment_failed
subscription_created
subscription_canceled
trial_activated
email_delivered
core_action_completed

But do not blindly page on:

sales per minute dropped
signups are lower than usual
traffic is weird

Those are investigation signals, not necessarily incidents.

Better:

Page:
  checkout_started is normal, but checkout_completed collapses
  payment webhooks fail for 15 minutes
  transactional email provider acceptance drops sharply
  login success ratio drops below SLO
Ticket/investigate:
  sales lower than seasonal baseline
  conversion rate down but no system errors
  trial starts low for the day

The difference is important:

Business KPI anomaly:
  "Something may be wrong."
Reliability SLI violation:
  "Users are being harmed by the system."

⸻

3. SLOs: the heart of modern SRE

An SLI is the measurement.

An SLO is the target.

An SLA is the promise, usually contractual.

Google’s SLO guidance frames a good SLI as:

good events / total events

For example:

good API requests / total API requests
successful checkouts / checkout attempts
emails accepted by provider / transactional emails attempted
jobs completed within 5 minutes / jobs enqueued

￼

That “good over total” shape is better than a pile of random charts because it forces a decision:

What does “good” mean for the user?

⸻

Percentiles: your p90/p99/p99.9 intuition is right, with nuance

You said p90 feels weak as an SLO. Correct.

p90 means 10% of interactions are worse than the threshold. In a modern app with many microinteractions, that can be awful.

Assume a user session has 50 interactions.

p90 per interaction:
  chance all 50 are good = 0.90^50 ≈ 0.5%
  almost every session gets at least one bad interaction
p99 per interaction:
  chance all 50 are good = 0.99^50 ≈ 60.5%
  about 39.5% of sessions get at least one bad interaction
p99.9 per interaction:
  chance all 50 are good = 0.999^50 ≈ 95.1%
  about 4.9% of sessions get at least one bad interaction

Real systems are correlated, not independent, but the intuition is valid:

A percentile that sounds strict at the request level may be loose at the user-journey level.

So use percentiles like this:

Percentile	Best use
p50	“Typical user” feel.
p90	Product polish, trend detection, broad regression.
p95	Useful default dashboard latency.
p99	Tail pain and SLO candidate for high-volume endpoints.
p99.9	Critical/high-volume systems, but can be noisy for low traffic.

The catch: for a low-traffic solo SaaS, p99.9 can be mathematically unstable. If an endpoint only gets 2,000 requests/day, p99.9 is about two requests. It may be more noise than signal.

So do not build SLOs as “p99.9 must be below X” everywhere.

Build them as event thresholds:

Good request:
  status is not 5xx
  AND duration_ms <= 750
  AND route is customer-facing

Then:

availability_latency_sli =
  good_requests / total_customer_facing_requests

This is often better than a percentile-only SLO.

⸻

Better SLO examples for your SaaS

API availability

SLI:
  non-5xx customer-facing HTTP requests / total customer-facing HTTP requests
SLO:
  99.9% over 30 days

API “fast enough” availability

SLI:
  customer-facing HTTP requests that are non-5xx and under 750ms
  /
  total customer-facing HTTP requests
SLO:
  99.5% over 30 days

Checkout

SLI:
  checkout sessions successfully created / checkout creation attempts
SLO:
  99.5% over 30 days

Webhook processing

SLI:
  payment webhooks processed successfully within 5 minutes
  /
  valid payment webhooks received
SLO:
  99.0% over 30 days

Transactional email

SLI:
  transactional emails accepted by provider within 60 seconds
  /
  transactional email send attempts
SLO:
  99.5% over 30 days

Background jobs

SLI:
  critical jobs completed successfully within target latency
  /
  critical jobs enqueued
SLO:
  99.0% over 7 or 30 days

The shape is what matters:

good / total

This gives you a clean way to reason about reliability.

⸻

4. Error budgets: the anti-alert-fatigue weapon

If your SLO is 99.9%, your error budget is 0.1%.

That means over a 30-day window, you are allowed to have some failure. Not infinite failure, not zero failure.

This is psychologically important for a solo founder.

Without error budgets, you oscillate between:

panic over every blip
ignore everything until users complain

With error budgets:

When budget is healthy:
  ship product
When budget is burning slowly:
  schedule reliability work
When budget is burning fast:
  mitigate now
When budget is exhausted:
  stop risky changes and stabilize

Google’s alerting guidance recommends burn-rate alerting: alert based on how quickly you are consuming the error budget, not merely on raw error rate. It also recommends multi-window, multi-burn-rate alerts to reduce false positives while still catching fast-burning incidents.  ￼

A practical solo-founder version:

Alert type	Meaning	Delivery
Fast burn	“Users are being hurt now.”	Page/push/SMS
Slow burn	“Reliability is degrading.”	Ticket/email
Budget low	“Stop risky deploys.”	Dashboard + planning
Weird anomaly	“Maybe investigate.”	Slack/email, not page

⸻

Example burn-rate alert shape

For an SLO of 99.9%, the allowed error ratio is:

0.001

A fast-burn alert might say:

error_ratio_5m > 14.4 * 0.001
AND
error_ratio_1h > 14.4 * 0.001

That means:

The system is burning the monthly error budget much faster than acceptable.

A slow-burn ticket might say:

error_ratio_6h > 3 * 0.001
AND
error_ratio_1d > 3 * 0.001

Do not treat those exact multipliers as sacred. Treat the idea as sacred:

alert on sustained budget burn, not isolated twitchiness

⸻

5. Alerting: the pager contract

Your alerting policy should be brutally small.

A page must satisfy all four:

1. User-visible or imminent user-visible harm.
2. Urgent enough to interrupt you.
3. Actionable by you.
4. Not already handled by automation.

Google’s monitoring chapter gives essentially this checklist: is the alert urgent, user-visible, actionable, and deserving of human intelligence? It also says to delete or downgrade alerts that are not useful.  ￼

Use this taxonomy:

flowchart TD
  S["Signal"] --> Q{"User harm now<br/>or imminent?"}
  Q -->|Yes| A{"Actionable now?"}
  A -->|Yes| P["PAGE"]
  A -->|No| T["TICKET / investigate"]
  Q -->|No| W{"Useful trend?"}
  W -->|Yes| D["DASHBOARD"]
  W -->|No| X["DELETE / don't collect"]

The three alert severities I would actually use

SEV-1: wake me

Critical user journey is broken.
Revenue flow is broken.
Data safety is at risk.
System is likely to go down soon.

Examples:

checkout success ratio collapses
login success ratio collapses
API 5xx fast-burn
DB disk nearly full
payment webhook processing stopped
transactional email provider rejects most sends

SEV-2: interrupt work, not sleep

Important degradation, but not immediate existential harm.

Examples:

job queue latency rising
p95 latency degraded for 30–60 minutes
slow error-budget burn
email bounce/complaint rate elevated
one region/provider flaky with fallback working

SEV-3: ticket or dashboard

Interesting, worth fixing, not urgent.

Examples:

traffic anomaly
sales below baseline
p99 worse after deploy but SLO okay
CPU trending upward
noncritical background job retries

⸻

6. Logging: take “Logging Sucks” seriously

The page you linked makes a strong point: traditional logging is broken because it is often string search over scattered crumbs. It argues that OpenTelemetry will not magically fix logging, because OTel is a transport/protocol/tooling layer, not a decision system for what context to capture.  ￼

The important mental shift:

Bad:
  many tiny log lines scattered through code
Good:
  one context-rich wide event per request/job/unit of work

The linked logging best-practices repo says the same thing: emit one context-rich event per request per service, include business and environment context, use JSON, maintain consistent field names, and avoid unstructured strings.  ￼

That is exactly the right model for AI-assisted ops too. LLMs are much better when your events already contain the relevant context.

⸻

Log events should be wide, not chatty

Bad logging:

INFO loading user
INFO user loaded
INFO checking plan
INFO plan is pro
INFO calling stripe
ERROR stripe failed
INFO returning 500

Better wide event:

{
  "event_name": "request_completed",
  "request_id": "req_01HX...",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "service": "web",
  "service_version": "2026.05.09.3",
  "deployment_id": "deploy_abc123",
  "environment": "prod",
  "region": "us-east-1",
  "route": "POST /checkout",
  "controller": "CheckoutController",
  "action": "create",
  "status": 500,
  "duration_ms": 842,
  "db_query_count": 12,
  "db_duration_ms": 211,
  "external_calls": {
    "stripe_count": 1,
    "stripe_duration_ms": 488,
    "stripe_error": "rate_limited"
  },
  "user_id": "user_123",
  "account_id": "acct_456",
  "plan": "pro",
  "feature_flags": ["new_checkout"],
  "business_flow": "checkout",
  "outcome": "failed",
  "error_class": "StripeRateLimitError"
}

The logging best-practices repo explicitly recommends building the event throughout the request lifecycle and emitting it once in a finally/completion path; it also recommends middleware to initialize the event, capture timing, and guarantee emission.  ￼

Think of this as:

one request/job = one observability fact sheet

⸻

Wide events vs metrics: do not confuse them

This distinction is crucial:

High-cardinality fields are good in wide events:
  user_id
  account_id
  request_id
  trace_id
  order_id
  deployment_id
High-cardinality labels are dangerous in Prometheus metrics:
  user_id
  account_id
  request_id
  trace_id
  order_id

So:

Metrics:
  low-cardinality, cheap, alertable
Wide events/logs:
  high-cardinality, rich, explorable
Traces:
  causal path through one request/job
Business DB:
  source of truth for money/accounts/contracts

The Logging Sucks page also emphasizes that tracing and wide events are complementary: traces show causal paths, while wide events provide rich analytical context. It also argues for tail-aware sampling: keep errors, slow requests, VIP users, new feature flags, and rare cases; sample routine successes more aggressively.  ￼

For your cost-sensitive SaaS, that is a big deal:

Keep 100%:
  errors
  checkout failures
  payment webhooks
  admin actions
  security-sensitive events
  slow requests
  new deploy / new feature flag cohorts
Sample:
  boring successful GET requests
  health checks
  static-ish low-value traffic

⸻

7. The “three stores” model

Do not try to make one data store do everything.

flowchart LR
  App["App emits signals"]
  App --> M["Metrics<br/>Prometheus/Mimir"]
  App --> W["Wide events/logs<br/>Loki/OpenObserve/ClickHouse/etc."]
  App --> T["Traces<br/>Tempo/Jaeger/SigNoz/etc."]
  App --> B["Business facts<br/>Postgres/warehouse"]
  M --> A["Alerts/SLOs"]
  W --> I["Debugging/context"]
  T --> I
  B --> K["KPIs/accounting/product analytics"]
  A --> Human["You / AI copilot"]
  I --> Human
  K --> Human

Use each store according to its nature:

Store	Best for	Bad for
Metrics	SLOs, alerting, trends	Per-user debugging, high-cardinality facts
Wide events/logs	Rich context, investigations	Primary paging logic
Traces	Causal latency/debug path	Aggregate business truth
Business DB	Money, subscriptions, product facts	Low-latency alerting on everything

This keeps cost and complexity under control.

⸻

8. Shift-left reliability

“Shift left” for SRE means: detect reliability problems before production users become your monitoring system.

For your case, this should be lean and automated.

Pre-deploy reliability checks

Before deploy:

tests pass
migrations are reversible or safe
assets compile
release boots
health endpoint works
critical synthetic flows pass
observability config present
error tracking enabled
no dangerous metric labels
no secrets in logs

After deploy:

new version appears in metrics/logs/traces
smoke test passes
5xx rate normal
latency normal
checkout synthetic passes
email synthetic passes
background job synthetic passes

DORA’s software delivery metrics are still useful here: change lead time, deployment frequency, failed deployment recovery time, change fail rate, and deployment rework rate. Google’s DORA material also emphasizes that speed and stability are not fundamental tradeoffs for top performers, and the 2025 DORA report frames AI as an amplifier of the underlying engineering system rather than a cure for a bad one.  ￼

For a solo SaaS, the most important DORA-ish metrics are:

deploy frequency
change fail rate
mean time to detect
mean time to mitigate
rollback time

You do not need a huge process. You need to know:

Can I ship often without fear?
Can I recover fast when wrong?

⸻

Deployment guardrails

A good solo deployment flow:

flowchart TD
  C["Commit"] --> CI["CI tests + static checks"]
  CI --> B["Build release"]
  B --> S["Staging smoke tests"]
  S --> D["Deploy prod"]
  D --> H["Health checks"]
  H --> SYN["Synthetic critical flows"]
  SYN --> OBS["Observe 15-30 min burn/latency/errors"]
  OBS --> OK{"Healthy?"}
  OK -->|Yes| Done["Done"]
  OK -->|No| Roll["Rollback / disable flag"]

The automation should know:

current deploy SHA
previous deploy SHA
changed files
migration IDs
feature flags changed
error rate before/after
latency before/after
critical flow status

That context is gold for LLMs.

⸻

9. Incident response for one person

Classic incident response has roles:

incident commander
operations lead
communications lead
planning/documentation

Google’s incident management guidance emphasizes clear command, defined roles, a working record, and declaring incidents early. It also calls out common hazards: overly sharp focus, poor communication, and freelancing.  ￼

For one person, these become modes, not people.

Solo incident modes

Commander mode:
  What is the severity?
  What is the user impact?
  What is the safest mitigation?
  What is the next decision point?
Operator mode:
  Roll back.
  Disable flag.
  Scale resource.
  Restart worker.
  Pause queue.
  Fail over provider.
Comms mode:
  Update status page.
  Email affected customers if needed.
  Leave a note for future you.
Scribe mode:
  Record timeline.
  Record hypotheses.
  Record commands run.
  Record exact mitigation.

During an incident, do not let yourself become four people at once.

Use a simple loop:

1. State impact.
2. Pick mitigation.
3. Execute.
4. Observe.
5. Communicate.
6. Continue or close.

⸻

Solo incident note template

# Incident: <short name>
## Status
open | mitigated | resolved
## Severity
SEV-1 | SEV-2 | SEV-3
## User impact
Who is affected?
What cannot they do?
When did it start?
## Current hypothesis
Most likely cause:
Confidence:
## Timeline
- 14:03 alert fired: checkout success ratio dropped
- 14:07 confirmed Stripe webhook failures
- 14:10 disabled new_checkout flag
- 14:13 checkout recovered
## Mitigation
What changed?
## Evidence
Dashboards:
Log queries:
Trace IDs:
Deploy SHA:
## Follow-ups
- [ ] action item
- [ ] test/runbook/alert/dashboard improvement

This document is not bureaucracy. It is a scratchpad that prevents panic.

⸻

10. Postmortems without theater

Google’s postmortem culture guidance says incidents are inevitable, and a postmortem should document impact, root causes, actions taken, and follow-up actions. It also emphasizes blamelessness: focus on systems and processes, not punishment.  ￼

For you, a postmortem should answer:

What happened?
How did users experience it?
Why did detection work or fail?
Why did mitigation work or fail?
What one thing would have made this easier?
What action prevents recurrence or reduces blast radius?

Keep it small:

SEV-1:
  full postmortem
SEV-2:
  lightweight postmortem
SEV-3:
  maybe just action item + note

AI-generated postmortem draft prompt

You are helping write a blameless SRE postmortem for a solo SaaS.
Inputs:
- incident timeline
- alert that fired
- deploy/change history
- relevant metrics
- relevant log/wide-event examples
- trace examples
- customer impact notes
- mitigation steps
Produce:
1. concise summary
2. customer impact
3. detection timeline
4. mitigation timeline
5. contributing factors
6. what went well
7. what went poorly
8. follow-up actions
Rules:
- blameless language only
- distinguish facts from hypotheses
- cite every metric/log/trace used
- propose no more than 5 action items
- each action item must have owner, priority, and verification method

That is a very good use of AI.

Not “AI, fix prod.”

Rather:

AI, organize the evidence and make the learning loop cheap.

⸻

11. AI and MCP: powerful, but put it behind rails

This is going to matter a lot.

Datadog now has an MCP server that connects AI agents to observability data such as logs, metrics, traces, and incidents. Their docs describe it as a bridge between Datadog and tools like Cursor, Codex, Claude Code, and custom agents.  ￼

You cannot afford Datadog, but the idea is not Datadog-specific.

Grafana has an open-source MCP server that can access dashboards, data sources, Prometheus queries, Loki queries, alerting, incidents, and related Grafana ecosystem resources.  ￼

So the open-source version looks like:

flowchart LR
  LLM["LLM / coding agent"] --> MCP["MCP server<br/>read-only by default"]
  MCP --> G["Grafana"]
  MCP --> P["Prometheus"]
  MCP --> L["Loki / logs"]
  MCP --> T["Tempo / traces"]
  MCP --> GH["GitHub"]
  MCP --> C["Cloud provider"]
  MCP --> D["Deploy system"]
  C -. "write actions require approval" .-> MCP
  D -. "write actions require approval" .-> MCP

The Model Context Protocol itself is a standard way for applications to expose context and tools to LLMs through JSON-RPC-style clients and servers.  ￼

But MCP is also a new attack surface. The official MCP docs have a security best-practices section covering risks and threat models, and recent research has identified MCP-specific risks such as tool poisoning, implicit trust propagation, and weak capability attestation in some deployments.  ￼

So the rule is:

AI may investigate freely. AI may recommend actions. AI may only execute production-changing actions through narrow, audited, human-approved tools.

⸻

The AI/SRE workflow I would build

Level 1: read-only investigation

Safe and valuable.

AI can:
  query dashboards
  inspect metrics
  summarize logs
  inspect traces
  compare before/after deploys
  identify likely culprit
  draft incident notes
  draft postmortems
  suggest next queries

Level 2: pre-approved safe actions

Useful with guardrails.

AI can propose:
  rollback to previous release
  disable feature flag
  scale worker count
  pause noncritical queue
  create GitHub issue
  open status-page draft

Human confirms.

Level 3: autonomous mitigation

Be very conservative.

Only allow for actions that are:

low blast radius
fully reversible
well-tested
audited
rate-limited
bounded by policy

Examples that might be okay later:

restart a crashed noncritical worker
pause a spammy noncritical job queue
open an incident doc
create a draft customer update

Examples I would not automate blindly:

delete data
run arbitrary SQL
change IAM
rotate secrets
modify billing
disable auth
send mass emails

Grafana’s 2026 survey data suggests teams are very interested in AI for anomaly detection, dashboards, root-cause analysis, and query generation, but less trusting of autonomous action. That matches the practical stance above: use AI heavily for investigation, cautiously for action.  ￼

⸻

AI incident investigation prompt

You are an SRE copilot for a solo SaaS founder.
Incident:
- alert_name:
- severity:
- service:
- start_time:
- current_time:
- deploy_sha:
- recent_changes:
Available tools:
- Prometheus metrics
- logs/wide events
- traces
- deploy history
- feature flags
- provider status pages
Task:
1. State the likely user impact.
2. Check whether this correlates with a deploy.
3. Compare error rate, latency, saturation, and traffic before/after.
4. Identify top 3 hypotheses.
5. For each hypothesis, provide the exact query/evidence.
6. Recommend the safest mitigation.
7. Do not recommend destructive actions.
8. Separate facts from guesses.

This is where structured logs and wide events pay off.

Garbage logs produce garbage AI.

Wide events produce useful AI.

⸻

12. Email deliverability is SRE

Your instinct here is exactly right.

For SaaS, email is infrastructure.

If users cannot receive:

signup verification
magic login links
password reset
invoices
receipts
team invites
security alerts
product notifications

then your app is broken, even if your HTTP API is healthy.

Google’s sender guidelines recommend monitoring domain spam rate in Postmaster Tools, keeping spam rates below 0.10%, and avoiding 0.30% or higher. Google’s FAQ also says user-reported spam above 0.1% negatively affects delivery and that bulk senders above 0.3% can lose mitigation eligibility.  ￼

So instrument email as a first-class reliability surface.

Email SLIs

provider_acceptance_sli =
  emails accepted by provider / email send attempts
transactional_delivery_latency_sli =
  emails accepted within 60s / email send attempts
bounce_sli =
  non-bounced transactional emails / transactional email attempts
complaint_sli =
  emails not marked spam / delivered emails

Email dashboard

send attempts by type
provider accepted/rejected
bounces by category
complaints/spam reports
delivery latency
suppression list additions
domain reputation indicators
SPF/DKIM/DMARC failures
provider API latency/errors

Email alerts

Page or interrupt:

password reset emails not being accepted
login magic links failing
invoice/receipt sending broken
provider reject rate spikes
domain spam complaint rate near dangerous threshold

Ticket:

marketing deliverability degrading
open/click metrics lower than usual
one campaign has elevated bounces

This is a great example of SRE meeting business reality.

⸻

13. The SRE/business KPI overlap

You mentioned “sales per minute” dipping. That is a useful signal, but it needs context.

Business KPIs are often laggy, seasonal, and affected by nontechnical causes.

Better than “sales per minute” alone:

checkout_started
checkout_completed
checkout_completion_ratio
payment_provider_error_ratio
payment_webhook_lag
invoice_email_acceptance

That lets you tell the difference:

Sales are down because fewer people visited.
Sales are down because checkout broke.
Sales are down because Stripe is rejecting calls.
Sales are down because confirmation emails are not arriving.
Sales are down because a feature flag changed conversion.

Use business KPIs as symptom detectors and correlation context.

Use SLIs as alerting contracts.

⸻

14. A practical SRE dashboard set

Do not build 40 dashboards.

Build 6.

1. Executive health

This is your home screen.

current deploy
uptime
API availability SLO
API latency SLO
checkout SLO
email SLO
job SLO
open incidents
error-budget remaining

2. RED service dashboard

request rate
5xx ratio
p50/p95/p99 latency
slowest routes
top erroring routes
route-level deploy comparison

3. Saturation dashboard

DB pool saturation
DB queue time
CPU/memory/disk
job queue depth
job wait time
external provider rate limits

4. Critical journeys

signup funnel
login funnel
checkout funnel
webhook processing
transactional email
core product action

5. Deploy/change dashboard

deploy markers
current SHA
recent migrations
feature flag changes
error rate before/after
latency before/after
new exception classes

6. Business pulse

signups
activations
checkout starts/completions
subscription created/canceled
MRR-ish directional pulse
support/contact spikes
email deliverability

The 2026 observability trend is clearly toward unifying infra/app/business signals and using AI for query generation, anomaly detection, incident triage, and noise reduction. Grafana’s survey reports high perceived value for AI surfacing issues before downtime, while also noting complexity and trust concerns.  ￼

⸻

15. What to measure first

Start with this inventory.

User-facing HTTP

http_requests_total{route, method, status_class}
http_request_duration_seconds_bucket{route, method}

Avoid labeling by raw path:

Bad:
  /accounts/123/projects/456
Good:
  /accounts/:account_id/projects/:project_id

Critical flows

signup_started_total
signup_completed_total
login_succeeded_total
login_failed_total
checkout_started_total
checkout_completed_total
checkout_failed_total
core_action_completed_total

Jobs

job_enqueued_total{queue, worker}
job_completed_total{queue, worker}
job_failed_total{queue, worker}
job_duration_seconds_bucket{queue, worker}
job_wait_seconds_bucket{queue, worker}

Database

db_query_duration_seconds_bucket
db_queue_duration_seconds_bucket
db_connection_errors_total
db_pool_in_use
db_pool_available

External dependencies

external_request_total{provider, operation, status_class}
external_request_duration_seconds_bucket{provider, operation}
external_request_errors_total{provider, operation, error_class}

Email

email_send_attempt_total{provider, type}
email_provider_accepted_total{provider, type}
email_provider_rejected_total{provider, type, reason_class}
email_bounced_total{provider, type, bounce_class}
email_complained_total{provider, type}
email_delivery_duration_seconds_bucket{provider, type}

Business

subscription_created_total{plan}
subscription_canceled_total{plan, reason_class}
invoice_paid_total{plan, currency}
invoice_payment_failed_total{plan, currency, reason_class}

Again:

plan, route, provider, status_class = good metric labels
user_id, email, request_id, invoice_id = bad metric labels

⸻

16. The low-friction SRE operating cadence

You do not need meetings. You need rhythms.

Daily, mostly automated

Check:
  open alerts
  error-budget status
  deploy health
  new top exceptions
  checkout/email/login health

This can be a generated morning digest.

Weekly, 20 minutes

Review:
  pages fired
  noisy alerts
  slow-burn SLOs
  top latency regressions
  top customer-impacting bugs
  reliability action items

Delete or downgrade at least one useless signal if possible.

Monthly, 30–60 minutes

Review:
  SLO targets
  error-budget burn
  deploy failure rate
  recovery time
  cost of observability
  biggest reliability risk
  one automation to add

This is enough.

⸻

17. Runbooks: the automation substrate

A runbook is not just for humans.

It is also context for AI.

Good runbook format:

# Runbook: Checkout failure spike
## Symptoms
- checkout_completed / checkout_started drops below 95%
- payment provider errors elevated
- checkout route 5xx fast-burn alert
## First checks
1. Check current deploy SHA.
2. Check Stripe/provider status.
3. Check checkout traces for top error class.
4. Check recent feature flag changes.
5. Check DB errors and queue time.
## Queries
Prometheus:
  <query>
Logs:
  <query>
Traces:
  <query>
## Mitigations
- disable new_checkout feature flag
- rollback latest deploy
- switch provider mode if configured
- pause noncritical billing jobs
## Customer communication
Use status page template:
  "We are investigating an issue affecting checkout..."
## Escalation
For solo:
  SEV-1 if checkout unavailable for > 5 minutes

That gives you and your AI agent the same map.

⸻

18. The “do not page me” list

This list is as important as the page list.

Do not page on:

single failed background job
single 500
one slow request
CPU > 80% without saturation/user impact
memory high but stable
traffic anomaly without failure
business KPI anomaly without correlated system/user-flow failure
log line containing "error"
p99 blip with low request count
third-party provider warning with no app impact

Instead:

route to dashboard
create ticket
include in daily digest
sample into investigation queue

Alert fatigue is not a nuisance. It is a reliability risk.

A noisy pager teaches you to distrust the only system that is supposed to wake you.

⸻

19. The “page me” list

For your SaaS, this is the starter set.

API fast-burn availability SLO
API fast-burn latency SLO
login success ratio collapse
checkout success ratio collapse
payment webhook processing stopped or delayed
transactional email acceptance failure
DB unavailable or disk nearly full
critical job queue stuck
deploy health failed after release
security-critical anomaly

Keep it under 10 paging alerts.

Everything else should earn the right to wake you.

⸻

20. Low-traffic SaaS problem: when SLO math gets weird

Low traffic makes some alerting harder.

Problems:

p99/p99.9 unstable
error ratios explode on tiny denominators
business KPI anomalies are noisy
night/weekend traffic seasonality matters

Solutions:

minimum volume gates
synthetic probes
critical journey canaries
longer windows for low-traffic endpoints
separate high-traffic and low-traffic SLOs
manual review for business anomalies

Example:

(
  error_ratio_5m > 0.05
)
AND
(
  request_count_5m > 100
)

For critical but low-volume flows, use synthetics:

Every 5 minutes:
  load homepage
  login test account
  perform non-destructive core action
  request magic link or test email
  create test checkout session in sandbox if safe

That gives you signal even when real traffic is quiet.

⸻

21. AI-generated daily reliability digest

This is a high-leverage automation for you.

Daily Reliability Digest
Window:
  last 24 hours
Summarize:
1. SLO status and error-budget changes
2. paging alerts and whether they were valid
3. top 5 new exception classes
4. top 5 latency regressions
5. deploys and health after deploy
6. checkout/login/email anomalies
7. business KPI anomalies with correlated system evidence
8. recommended actions, max 5
Rules:
- distinguish facts from hypotheses
- cite dashboard/log/trace/query source for every claim
- do not invent causes
- downgrade non-actionable items
- identify noisy alerts

This is the kind of AI usage that compounds.

⸻

22. AI-generated “should this alert exist?” review

Use this monthly.

Review these alerts from the last 30 days.
For each alert:
- number of times fired
- number of times action was taken
- number of times it woke me
- user impact yes/no
- was it duplicate?
- was it too late?
- was it too early?
- should it be page/ticket/dashboard/delete?
Return:
- alerts to delete
- alerts to downgrade
- alerts to tune
- missing alerts

This fights alert bloat.

⸻

23. The SaaS-in-a-box reliability layer

Given your broader “composable packages / SaaS in a box” direction, the SRE layer should be another composable layer.

Not a Datadog clone.

A reliability substrate.

flowchart TD
  P["SaaS packages"] --> E["Domain events"]
  E --> T["Telemetry"]
  T --> M["Metrics"]
  T --> W["Wide events"]
  T --> R["Runbooks"]
  T --> S["SLO templates"]
  T --> D["Dashboards"]
  T --> A["AI/MCP context"]
  M --> Alerts["Alerts"]
  W --> Debug["Debugging"]
  S --> Alerts
  D --> Human["Founder"]
  A --> Human

The OSS opportunity is:

generate the boring correct stuff

Examples:

standard business event names
standard SLO templates
wide-event middleware
safe logging schema
metric label linter
Grafana dashboards
Prometheus alert rules
incident templates
postmortem templates
MCP read-only investigation server
email deliverability monitors

This is the Unix-ish philosophy you described:

small sharp packages
composable signals
host-owned generated code
AI-readable context

⸻

24. What “good” looks like in practice

Imagine your checkout breaks.

Bad world:

User emails you.
You grep logs.
You find scattered messages.
You wonder if it was deploy, Stripe, DB, or code.
You stare at dashboards.
You panic.

Good world:

Alert:
  Checkout success SLO fast burn
Dashboard says:
  checkout_started normal
  checkout_completed near zero
  payment provider errors elevated
  only new_checkout=true affected
  started 7 minutes after deploy abc123
Wide events show:
  route=POST /checkout
  plan=pro
  feature_flags=["new_checkout"]
  provider=stripe
  error_class=StripeInvalidRequestError
  deployment_id=abc123
Trace shows:
  time spent in Stripe API call
  failure at create checkout session
Runbook says:
  disable new_checkout flag
  rollback if not recovered in 5 minutes
AI says:
  likely feature flag/deploy regression
  recommended mitigation: disable new_checkout
  confidence: high

That is the target.

Not more data.

Better-shaped data.

⸻

25. The 30/60/90-day solo SRE plan

First 30 days: observe and page sanely

Build:

RED dashboards
critical journey metrics
wide request/job events
basic traces
error tracking
email provider metrics
deploy markers
5–8 paging alerts max

Create SLOs for:

API availability
checkout
login
transactional email
critical jobs

Days 31–60: automate investigation

Build:

runbooks
daily reliability digest
post-deploy health report
AI incident investigation prompt
AI postmortem draft prompt
alert quality review

Add:

synthetic critical flows
business KPI correlation
email deliverability dashboard
feature flag/deploy correlation

Days 61–90: productize the repeatable parts

Extract:

wide event schema
metric naming conventions
dashboard templates
SLO templates
alert templates
runbook templates
MCP/Grafana integration
doctor command
label cardinality linter

This is where your OSS packages can become a serious advantage.

⸻

26. LLM context block for future agents

You can paste something like this into future AI/SRE contexts:

We operate a bootstrapped solo-founder SaaS.
Reliability philosophy:
- Page only on urgent, actionable, user-visible or imminent user-visible harm.
- Use SLOs and error-budget burn, not raw twitchy metrics.
- Use RED for services and USE for resources.
- Treat email deliverability, checkout, login, webhooks, and critical jobs as first-class reliability surfaces.
- Metrics are low-cardinality and alertable.
- Wide events/logs are high-cardinality and used for investigation.
- Traces show causal paths.
- Business DB is source of truth for money and subscriptions.
- Avoid alert fatigue aggressively.
AI rules:
- AI may investigate, summarize, compare, and draft.
- AI must cite metrics/logs/traces/changes for factual claims.
- AI must distinguish facts from hypotheses.
- AI must recommend safe reversible mitigations first.
- AI may not run destructive production actions without explicit human approval.
- Prefer rollback/feature-flag disable over deep debugging during active incidents.
Incident priorities:
1. Mitigate user harm.
2. Communicate if customers are affected.
3. Preserve timeline and evidence.
4. Learn and automate after resolution.
Critical journeys:
- signup
- login/session
- checkout/payment
- payment webhooks
- transactional email
- core product action
- critical background jobs

⸻

27. The compact doctrine

Here is the whole thing compressed.

1. Start from user journeys, not infrastructure.
2. Define good/total SLIs.
3. Use SLOs to decide when to act.
4. Alert on error-budget burn, not random weirdness.
5. Keep paging alerts under 10.
6. RED for services, USE for resources.
7. p90 is a product signal, not a reliability promise.
8. p99/p99.9 are useful, but low-traffic systems need volume gates and synthetics.
9. Logs should be wide events, not scattered diary entries.
10. High-cardinality context belongs in logs/traces, not metric labels.
11. Email deliverability is production reliability.
12. Business KPIs are symptom detectors; SLOs are action contracts.
13. Incidents need mitigation first, explanation second.
14. Postmortems are for learning, not blame.
15. AI is best used for context, triage, summaries, and drafts.
16. AI production actions must be narrow, reversible, audited, and approved.
17. Delete noisy alerts ruthlessly.
18. Automate the boring diagnosis.
19. Build runbooks that both humans and LLMs can use.
20. Productize the paved road, not the observability backend.

The north star:

A calm system where your SaaS can hurt users only briefly, visibly, and learnably — without turning your life into an on-call nightmare.