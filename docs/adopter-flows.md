# Parapet Adopter Flows

Parapet is easiest to understand if you stop thinking of it as a metrics library and start thinking of it as a reliability operating loop for a Phoenix SaaS.

The promise is simple:

You should be able to install Parapet, point it at the journeys that matter, and answer three uncomfortable questions quickly:

- Are users succeeding right now?
- If not, where is the damage happening?
- Is there a safe next move besides staring at Grafana?

This guide explains the user flows and jobs-to-be-done Parapet is built around today.

## Who This Is For

This guide is for the engineer who might say:

"I know Phoenix, Ecto, Oban, Telemetry, and Prometheus well enough. I do not want another observability science project. I want a paved road from request or job behavior to operator action."

If that is you, Parapet is aiming at your exact problem.

## The Mental Model

Parapet has one core idea:

Raw telemetry is too low-level to run a SaaS from, and dashboards alone are too ambiguous when something important is on fire.

So Parapet turns the world into a tighter loop:

1. Your app emits normal Phoenix, Ecto, Oban, and integration telemetry.
2. Parapet turns that into bounded, low-cardinality reliability signals.
3. You define SLOs for critical user journeys, not just subsystem health.
4. Parapet generates Prometheus and Grafana artifacts from those definitions.
5. Alerts become durable incidents with chronology, runbooks, and audit history.
6. Operators investigate and take bounded action inside the host app.

The important part is the seam between "signal" and "action."

Parapet is trying to make that seam short, explicit, and safe.

## The Canonical Jobs

Parapet currently clusters around eight adopter jobs.

### 1. Know if a critical user journey is healthy

**Trigger:** You have a SaaS and want to know whether login, checkout, onboarding, job completion, or provider-mediated delivery is actually working for users.

**What you are trying to do:** Replace vague system health with user-visible reliability.

**Parapet path:** Install the library, define SLOs, generate Prometheus rules, and watch burn-rate style signals for the journey you care about.

**What "done" looks like:** You can say "checkout success is healthy" or "login is burning error budget" instead of "CPU looks fine but support is yelling."

**Concrete example:** Your homepage is up, database is fine, and workers are alive. But a broken auth callback causes login to fail for 4% of real users. Parapet wants that to show up as a journey problem, not as a scavenger hunt across five dashboards.

### 2. Turn existing telemetry into safe reliability signals

**Trigger:** You already have Phoenix, Ecto, Oban, or sibling-library telemetry, but it is too raw, noisy, or risky to expose directly.

**What you are trying to do:** Capture useful signals without blowing up Prometheus cardinality or leaking exact identifiers into labels.

**Parapet path:** Use the built-in metrics and adapter surfaces, keep exact refs in durable evidence, and let Parapet generate the PromQL-facing shape.

**What "done" looks like:** You get metrics that are operable in production and still safe at scale.

**Concrete example:** A delivery provider gives you message IDs, recipient IDs, callbacks, and suppressions. Parapet wants the metric label story to stay bounded while exact objects live in evidence or action items, where operators can still follow up safely.

### 3. Get from install to first alert without inventing the system

**Trigger:** You are adopting Parapet in a real app and do not want a three-day observability integration project.

**What you are trying to do:** Get to a working Day-1 setup with a host-owned install surface.

**Parapet path:** Run `mix parapet.install`, review the generated instrumenter and config, run `mix parapet.doctor`, then generate Prometheus and Grafana artifacts.

**What "done" looks like:** The app has a reliability spine, metrics plug, generated artifacts, and a doctor pass that catches obvious contradictions.

**Concrete example:** A solo founder with a Phoenix SaaS wants a paved road. Parapet's install path is trying to be the "I can use this tonight" moment, not a wiki page full of TODOs.

### 4. Get from alert to evidence fast

**Trigger:** Alertmanager says an SLO is burning.

**What you are trying to do:** Turn an alert into something durable and inspectable, not an ephemeral Slack panic.

**Parapet path:** Webhook ingest creates or updates an incident, attaches timeline entries, and preserves incident state across open, investigating, and resolved.

**What "done" looks like:** The alert has become an object with history, not just a notification.

**Concrete example:** A checkout alert fires at 2:13 PM, resolves at 2:21 PM, and re-fires at 2:34 PM after a deploy rollback. Parapet wants a coherent chronology with deploy markers, notifications, and operator actions, so you are not reconstructing the story from memory.

### 5. Investigate incidents inside the app, not across ten tabs

**Trigger:** An operator needs current truth and the shortest path to the next sensible question.

**What you are trying to do:** See incident state, relevant chronology, runbook context, and external links in one workbench.

**Parapet path:** Use the optional operator UI, which stays host-owned and sits behind your own authentication and authorization.

**What "done" looks like:** The workbench shows summary first, chronology next, and controls only after context is visible.

**Concrete example:** A notification delivery incident could be provider drift, callback lag, or your own queue backlog. Parapet wants the UI to help you distinguish those stories before you press anything.

### 6. Trigger safe, bounded mitigation when the next step is obvious

**Trigger:** The incident has an evidence-backed next move: acknowledge, escalate, preview recovery, confirm recovery, or trigger a runbook step.

**What you are trying to do:** Act without turning the reliability layer into a free-form admin console.

**Parapet path:** Define runbooks, wire named capabilities, keep previews explicit, and record mutations through audited operator seams.

**What "done" looks like:** An action is idempotent, attributable, bounded in scope, and visible in the timeline.

**Concrete example:** A dead-lettered async item needs a scoped retry. The right outcome is not "someone ssh'd into prod and did a thing." The right outcome is "the operator previewed the effect, confirmed it, and the evidence spine records exactly what happened."

### 7. Keep async and provider-mediated journeys trustworthy

**Trigger:** User success depends on work that happens after the request returns: emails, notifications, callbacks, media jobs, billing workflows, or AI workflows.

**What you are trying to do:** Avoid collapsing all delayed or third-party failures into one vague "background jobs are sad" bucket.

**Parapet path:** Use the async and delivery integrations, provider-owned SLO slices, triage summaries, and fault-plane-aware incident enrichment.

**What "done" looks like:** Operators can tell the difference between internal backlog, worker failure, provider degradation, webhook delay, suppression drift, and stale callbacks.

**Concrete example:** "Provider accepted the email" is not the same as "the customer received the email." Parapet treats those as different operational truths on purpose.

### 8. Learn over time without drowning in history

**Trigger:** Reliability work compounds. Incidents, notifications, audits, deploy markers, and retrospectives accumulate.

**What you are trying to do:** Keep evidence durable enough to learn from, but cheap enough to keep running.

**Parapet path:** Preserve low-volume operational evidence, generate retrospectives, archive old data, and protect both Prometheus and Postgres from unbounded growth.

**What "done" looks like:** You can look backward when needed without turning your primary database or TSDB into the casualty.

**Concrete example:** Six months later, you want to answer "Have suppressed deliveries become more common after each pricing-email launch?" That only works if the system preserved the right evidence and discarded the wrong volume.

## The Main Flows In Order

If you are adopting Parapet for your own SaaS, the practical flow usually looks like this.

### Flow 1: Day 1 activation

You install Parapet, let it scaffold the host-owned starting points, and run the doctor. The job here is not "observe everything." The job is "establish a trustworthy reliability spine with the smallest acceptable blast radius."

This is why Parapet leans toward generated code, explicit opt-ins, and doctor checks. In Elixir/Phoenix terms, this is idiomatic: use telemetry that already exists, keep ownership in the host app, and make the paved road inspectable rather than magical.

### Flow 2: Choose the journeys that deserve SLOs

You decide which failures are truly user-harming and model those as SLOs or provider-owned slices.

This is the point where Parapet becomes more opinionated than a generic metrics stack. It pushes you toward questions like:

- Can users log in?
- Can users complete checkout?
- Do async workflows reach a good terminal state?
- Do provider-mediated messages get confirmed, not just attempted?

That is a better starting point than "collect all metrics and hope meaning emerges."

### Flow 3: Generate operational artifacts

You generate Prometheus rules and Grafana dashboards from the same reliability definitions.

The job-to-be-done here is consistency. You should not have one version of reliability in Elixir, a second version in Prometheus YAML, and a third version in a half-updated dashboard folder.

### Flow 4: Convert burn into incidents

When the alert fires, Parapet wants to preserve the event as durable evidence. That is where the evidence spine matters.

Many teams have the opposite problem: they have rich telemetry but poor operational memory. Parapet is explicitly built to make the incident itself a first-class object.

### Flow 5: Investigate and respond

At this point, the operator UI, runbooks, notifications, escalation, and recovery surfaces come into play.

The sequence matters:

1. Current truth
2. Chronology
3. Safe external links
4. Bounded controls

Parapet is intentionally suspicious of UIs that put a scary button before they put the facts.

### Flow 6: Close the loop

Resolved incidents should leave useful residue:

- timeline evidence
- notifications
- audits
- deploy correlation
- retrospective material

The point is not paperwork. The point is reducing future ambiguity.

## Choosing Your Adoption Depth

Not every team needs every Parapet surface on day one.

### Day 1

Use Parapet if you want:

- install and doctor flow
- safe request and job telemetry foundations
- a small set of meaningful SLOs
- generated Prometheus and Grafana artifacts

### Week 1

Add:

- provider-owned SLOs for async or delivery paths
- webhook ingest and durable incidents
- notifications and runbooks
- optional operator UI

### Maturity path

Adopt later if the problem exists:

- escalation policy
- system-executed bounded mitigation
- preview-first recovery capabilities
- synthetic probes
- deploy markers
- evidence archival

## What Parapet Is Not

Parapet is deliberately not trying to be several other products.

- It is not an APM backend, log store, or trace store.
- It is not hosted observability SaaS.
- It is not a replacement for Phoenix Telemetry, Oban, Prometheus, or Grafana.
- It is not an excuse to skip runbooks or incident ownership.
- It is not an autonomous incident-response agent that should improvise inside production.

Those boundaries are part of the design, not missing features.

## Where The Library Feels Most Native In Elixir/Phoenix

Parapet feels most idiomatic when you view it as a composition layer over existing ecosystem seams:

- Phoenix and Plug already emit telemetry.
- Oban already exposes job lifecycle facts.
- LiveView already inherits your app's authentication model.
- `Telemetry.Metrics` already makes tags powerful and dangerous.
- Prometheus and Grafana already speak the language of SLOs and burn rates.

Parapet's job is not to outsmart those tools. Its job is to connect them into a sharper operational story.

## If You Only Remember Three Things

- Parapet is about user-journey reliability, not generic dashboarding.
- The evidence spine is as important as the metrics layer.
- Safe operator action is the destination; metrics are how you arrive there.
