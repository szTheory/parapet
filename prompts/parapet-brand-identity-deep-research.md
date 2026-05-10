Below is a copy-paste-friendly Markdown brand book. One caveat: I found existing “Parapet” uses in software, including a Scala distributed-systems library, an integrated risk management platform, and an open-source prompt-injection research project. So the identity below deliberately makes this Parapet for Phoenix reliability, not generic risk/security/compliance software.  ￼

Parapet Brand Identity Book

Version: 0.1
Brand: Parapet
Product type: Open-source Elixir/Phoenix reliability, SRE, and observability substrate
Canonical phrase: Parapet for Phoenix reliability

⸻

1. LLM Context Capsule

Parapet is an open-source Elixir library for Phoenix teams that want a practical reliability layer: SLOs, burn-rate alerts, safe telemetry defaults, low-cardinality metrics, wide events, deploy correlation, runbooks, incident notes, doctor checks, and AI-readable operational context.

The name Parapet comes from the idea of a protective low wall or railing at the edge of a roof, platform, or bridge. The brand metaphor is not “fortress software.” It is a calm protective edge that gives operators sightlines, prevents silent harm, and helps teams act before they fall into chaos. A parapet protects without getting in the way.  ￼

The brand should feel:

* calm, precise, and protective;
* Phoenix-native and developer-respectful;
* evidence-first, not dashboard-first;
* operationally mature without enterprise bloat;
* open-source, practical, and humane.

The brand should not feel:

* militaristic;
* medieval/castle-themed;
* generic SaaS observability;
* noisy, neon, or “incident war room” theatrical;
* like an APM vendor;
* like a security/compliance/risk-management platform.

⸻

2. Brand Positioning

2.1 One-line positioning

Parapet is the Phoenix reliability layer that turns telemetry into SLOs, evidence, and calm operational action.

2.2 Short positioning

Parapet helps Phoenix apps notice user harm early, understand what changed, and respond with evidence-backed runbooks instead of noisy dashboards and improvised alerts.

2.3 Longer positioning

Parapet is an opinionated, open-source reliability substrate for Phoenix, Ecto, Plug, Oban, and adjacent Elixir systems. It does not try to replace telemetry, Prometheus, Grafana, OpenTelemetry, LiveDashboard, Sentry, or AppSignal. It composes the existing ecosystem into a practical SRE loop: safe metrics, user-journey SLOs, burn-rate alerts, wide events, deploy markers, incident timelines, runbooks, doctor checks, and AI-readable investigation bundles.

Phoenix already emits telemetry events, and Telemetry.Metrics defines metric specs while reporters handle aggregation, which means developers still have to decide what to measure, how to aggregate it, and what operational decisions it should support. Parapet’s job is to bridge that gap.  ￼

2.4 Brand thesis

A Phoenix SaaS can briefly hurt users, but not silently, not confusingly, and not without leaving evidence, a mitigation path, and a learning loop.

2.5 Category

Use:

* Phoenix reliability layer
* Phoenix SRE toolkit
* Reliability substrate for Elixir apps
* SLO and operational context library
* Open-source reliability system for Phoenix

Avoid leading with:

* observability backend
* monitoring tool
* APM
* security platform
* risk-management platform
* AI ops agent
* dashboard generator

Parapet is allowed to generate dashboards, alerts, and AI context, but those are outputs of the reliability layer, not the category itself.

⸻

3. Name System

3.1 Brand name

Use:

Parapet

Use lowercase only for package names, CLI commands, URLs, CSS classes, and code identifiers:

parapet
mix parapet.doctor
Parapet.SLO
Parapet.WideEvent

3.2 Pronunciation

Preferred:

PAIR-uh-pet

Do not over-explain pronunciation in the product UI. It can appear once in docs or the README if useful.

3.3 Product naming architecture

Recommended package/module shape:

{:parapet, "~> 0.1"}
Parapet
Parapet.SLO
Parapet.Doctor
Parapet.Runbook
Parapet.Incident
Parapet.Deploy
Parapet.WideEvent
Parapet.Email
Parapet.Webhook
Parapet.AI

Recommended Mix tasks:

mix parapet.install
mix parapet.doctor
mix parapet.slo.generate
mix parapet.dashboard.generate
mix parapet.runbook.new checkout
mix parapet.incident.new

If the Hex package name parapet is unavailable or you want stronger disambiguation, use one of these:

{:parapet_phoenix, "~> 0.1"}
{:parapet_sre, "~> 0.1"}

But the public brand should remain Parapet.

3.4 Canonical tagline options

Primary:

A protective edge for Phoenix reliability.

Best homepage hero:

See user harm before it becomes chaos.

Developer-facing:

SLOs, runbooks, and evidence for Phoenix apps.

More poetic:

The quiet edge between telemetry and action.

Practical:

Turn Phoenix telemetry into SLOs, alerts, runbooks, and incident evidence.

Do not use:

The ultimate observability platform.
AI-powered incident response.
Military-grade reliability.
Your command center for production.
Stop outages forever.

⸻

4. Brand Personality

4.1 Core personality

Parapet is:

* calm: it reduces panic instead of amplifying urgency;
* protective: it keeps teams and users away from edges;
* precise: it names the affected journey, budget, deploy, and evidence;
* teaching-oriented: it helps Phoenix developers learn reliability without feeling judged;
* quietly opinionated: it provides defaults, explains tradeoffs, and lets teams override them;
* practical: it generates useful artifacts instead of abstract theory.

4.2 Brand archetype

Primary archetype: The Guardian
Secondary archetype: The Field Engineer

This is not a mystical guardian, a police guard, or a corporate risk officer. It is a field engineer standing at the edge of the roof with a clipboard, a level, and a calm voice.

4.3 Brand principles

1. Protect users, not graphs

The first question is always: Are users being hurt?

Prometheus and Google SRE guidance both emphasize symptom-oriented alerting: alerts should focus on user-visible problems and actionable issues, not every possible internal cause.  ￼

2. Evidence before explanation

Parapet should separate:

Facts
Hypotheses
Recommendations
Actions taken
Unknowns

Never let generated UI or AI context blur those categories.

3. Low-noise by default

Paging is expensive. Parapet should default to fewer, better alerts. Paging alerts should be actionable and aligned with SLO-threatening symptoms.  ￼

4. Metrics are bounded; events are rich

Metrics should stay low-cardinality. Prometheus warns against high-cardinality labels such as user IDs, email addresses, and other unbounded values. Wide events and traces are the right place for high-cardinality investigation fields, because those fields help narrow down what caused a specific request or customer journey to fail.  ￼

5. Generate the boring correct pieces

Parapet should feel like a paved road. It should generate SLO specs, alert rules, dashboard panels, runbook templates, incident notes, and AI-readable context from a small number of intentional definitions.

6. Keep operators inside the guardrail

The UI should never encourage unsafe production control. AI actions should be read-only by default, approval-gated when mutating, and auditable.

⸻

5. Brand Voice

5.1 Voice attributes

Parapet sounds:

* calm;
* direct;
* specific;
* technically literate;
* humane;
* lightly opinionated;
* evidence-backed.

Parapet does not sound:

* panicked;
* salesy;
* cute;
* macho;
* mystical;
* blameful;
* enterprise-generic.

5.2 Tone by context

Context	Tone	Example
Homepage	Clear, confident, restrained	“Parapet turns Phoenix telemetry into SLOs, runbooks, and evidence.”
Docs	Precise, helpful, practical	“Start with one user journey. You can add more once the first SLO is useful.”
Admin UI	Calm and operational	“Checkout completion is burning 4.2x faster than budget.”
Error messages	Specific and fix-oriented	“Parapet could not classify this route because no journey matched /checkout/:id.”
Incident view	Neutral, timestamped, factual	“Deploy 8f31c2a preceded the first error-budget spike by 6 minutes.”
AI summaries	Cited, bounded, careful	“Fact: webhook latency increased after the deploy. Hypothesis: provider retry behavior changed.”
Alerts	Short, actionable, user-harm-first	“Login success SLO fast-burn: users may be unable to sign in.”

5.3 Writing rules

Write like this:

Checkout completion is below target.
The error budget is burning 6.1x faster than planned.
The first correlated change is deploy 8f31c2a.
Suggested next step: disable `new_tax_flow` or roll back the deploy.

Do not write like this:

🔥 Checkout is totally broken!!!
Massive anomaly detected across multiple dimensions.
The system has entered a critical failure state.

Write like this:

This metric would create one series per user. Move `user_id` to a wide event field instead.

Do not write like this:

Invalid label. Bad cardinality.

Write like this:

No incidents yet. When an SLO burns fast enough to page, Parapet will create an evidence timeline here.

Do not write like this:

Nothing to show.

5.4 Vocabulary

Preferred words:

evidence
journey
guardrail
budget
burn rate
sightline
signal
calm
surface
correlate
classify
mitigate
learn
runbook
timeline
wide event
doctor check

Use carefully:

alert
incident
failure
critical
anomaly
AI
automation
security
risk

Avoid as brand flavor:

war room
battle-tested
mission control
panic
chaos monkey
magic
autopilot
black box
total visibility
single pane of glass
military-grade

5.5 Voice formula

For operational messages, use this structure:

[User-facing symptom]
[Measured evidence]
[Likely correlation]
[Safe next action]
[Where to inspect]

Example:

Checkout completion is below its SLO.
The 5-minute burn rate is 14.2x and the 1-hour burn rate is 6.3x.
The first correlated change is deploy 8f31c2a.
Start with the rollback runbook or disable `checkout_tax_v2`.
View evidence: Checkout → Incident timeline.

⸻

6. Visual Identity

6.1 Visual concept

Parapet’s visual system is built from four ideas:

edge
sightline
masonry
signal

The product should look like a calm architectural surface with measured signal overlays. Think:

* roofline at dawn;
* cut stone;
* measured diagrams;
* thin gridlines;
* annotated thresholds;
* amber beacons;
* quiet slate panels;
* runbook pages;
* incident timelines.

Do not make it look like:

* a castle game;
* a cybersecurity shield brand;
* a Grafana clone;
* a neon terminal;
* a dark-mode crypto dashboard;
* a medieval fantasy product.

6.2 Logo direction

The logo should be simple enough to work as:

* GitHub avatar;
* Hex package icon;
* favicon;
* docs header mark;
* LiveDashboard/admin page icon;
* monochrome stamp.

Strong symbol directions

1. Stepped parapet mark

A horizontal roofline with two or three rectangular rises. The negative space implies protected openings or signal windows.

2. P-as-parapet monogram

A geometric P where the bowl or stem contains a stepped edge. Good for package avatars.

3. Edge and sightline

A low wall at the bottom with a single line/horizon above it. This emphasizes seeing over the edge rather than hiding behind a fortress.

4. Signal slot

A rectangular cut or notch in a wall shape with a small signal line passing through it. This ties to telemetry and evidence.

Avoid logo directions

Avoid:

* full castles;
* turrets;
* swords;
* shields as the main symbol;
* eyes;
* radar circles;
* generic heartbeat lines;
* flame icons;
* skulls;
* sirens;
* mascots;
* medieval type.

A small stepped wall is good. A castle is too much.

6.3 Wordmark

Recommended wordmark style:

Parapet

Use Title Case in documentation and prose.

A lowercase logo can work visually:

parapet

But the written brand should be Parapet.

Wordmark qualities:

* sturdy;
* slightly condensed or neutral;
* not rounded-cute;
* not aggressively geometric;
* not serif-only;
* no faux-medieval letterforms.

⸻

7. Color System

7.1 Color mood

The palette should feel like:

warm stone + deep slate + measured signal colors

It should not feel like:

neon observability rainbow

Use warm neutrals for surfaces, deep slate for authority, blue/teal for calm insight, amber for warning, red for active burn, and moss for healthy budget.

Accessibility requirement: design for WCAG AA contrast. WCAG guidance aims for enough contrast for users with low vision; WebAIM summarizes AA contrast as 4.5:1 for normal text, 3:1 for large text, and 3:1 for UI components/graphics.  ￼

7.2 Core palette

Token	Hex	Role	Usage
Parapet Black	#101820	Primary dark	Headers, dark surfaces, primary text on light
Deep Slate	#18232B	Secondary dark	Admin shell, nav, dark cards
Wall Slate	#2E3A42	Structural neutral	Borders on dark, secondary panels
Stone	#D8D0C3	Warm neutral	Dividers, diagrams, disabled fills
Mortar	#EAE2D4	Soft surface	Cards, doc callouts, diagrams
Limestone	#F8F4EC	Main light background	Docs, marketing pages, empty states
Watch Blue	#256C82	Calm signal	Links, selected states, info panels
Beacon Amber	#B45309	Warning on light	Warning text, watch states, caution icons
Beacon Amber Light	#D97706	Warning on dark	Dark-mode warning accents
Budget Moss	#567236	Healthy	Healthy budget text, success badges
Incident Red	#B13A32	Burn / incident	Critical SLO burn, destructive states
Trace Violet	#6D5BD0	AI / correlation	AI evidence, traces, “assistive” layer

7.3 Color usage

Primary brand surfaces

Use:

--parapet-black: #101820;
--deep-slate: #18232B;
--wall-slate: #2E3A42;
--stone: #D8D0C3;
--mortar: #EAE2D4;
--limestone: #F8F4EC;

Signal colors

Use:

--watch-blue: #256C82;
--beacon-amber: #B45309;
--beacon-amber-light: #D97706;
--budget-moss: #567236;
--incident-red: #B13A32;
--trace-violet: #6D5BD0;

7.4 Status colors

Status	Meaning	Text	Background	Border
Healthy	Within budget	#3F5E28	#EFF6E8	#B6C99A
Watch	Needs attention, not paging	#92400E	#F8EFD7	#E3B66E
Burning	Error budget burning fast	#9F2D2D	#FCE8E2	#E3A19A
Exhausted	Budget depleted or user harm active	#7F1D1D	#F8D7D4	#C87670
Unknown	Missing data or unclassified	#2E3A42	#ECEFF1	#CBD2D8
AI Assist	AI-generated or AI-summarized	#4F46A5	#ECEBFF	#B9B5F6

7.5 Background rules

Marketing pages:

Primary background: Limestone
Hero contrast block: Parapet Black or Deep Slate
Section dividers: Mortar / Stone
Accent: Watch Blue or Beacon Amber

Docs:

Background: Limestone or white
Text: Parapet Black
Code blocks: Deep Slate background with Mortar text
Callouts: Mortar background with status-colored left border

Admin UI:

Shell: Deep Slate
Primary content: Limestone or white
Operational panels: white / Mortar
Critical evidence: restrained Incident Red accents, never full-page red

7.6 Color rules

Do:

* use red only for real user harm, destructive actions, or fast-burn states;
* use amber for watch states and caution;
* use blue for navigation, links, selected states, and calm insight;
* use violet only for AI-generated summaries, trace correlation, or assistant context;
* use moss for budget health and completed checks;
* use warm neutrals to make the product feel less clinical.

Do not:

* use red for ordinary errors like form validation unless the action is truly dangerous;
* make every chart multicolored;
* use rainbow dashboards;
* put amber text on a light background unless using the darker amber token;
* use violet for core product identity; it should remain an assistive layer.

⸻

8. Typography

8.1 Typeface recommendation

Primary family:

IBM Plex Sans

Technical/code family:

IBM Plex Mono

Optional editorial/display accent:

IBM Plex Serif

IBM Plex is an open-source typeface project, includes Sans/Serif/Mono families, and is designed to work across UI and other media.  ￼

Alternative primary family:

Inter

Inter is free and open source and designed for computer screens, with readability-oriented features such as a tall x-height.  ￼

8.2 Recommended typography system

Use IBM Plex as the default because it gives Parapet a more distinctive field-manual/editorial feel than the more common Inter-based SaaS look.

--font-sans: "IBM Plex Sans", Inter, ui-sans-serif, system-ui, sans-serif;
--font-mono: "IBM Plex Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace;
--font-serif: "IBM Plex Serif", Georgia, serif;

8.3 Type scale

Token	Size	Line height	Weight	Usage
Display	56px	1.00	500	Homepage hero only
H1	40px	1.08	500	Page titles
H2	30px	1.16	500	Major sections
H3	22px	1.25	500	Cards, docs sections
Body	16px	1.60	400	Main reading
Body Small	14px	1.50	400	UI copy, table text
Caption	12px	1.40	500	Labels, metadata
Code	13px	1.55	400	Inline/log/code
Metric Large	36px	1.00	500	SLO card numbers
Metric Small	20px	1.10	500	Table metrics

8.4 Typography personality

Headlines should feel like engineering statements, not ads.

Good:

Reliability starts at the user journey.
The alert should know what changed.
Fewer pages. Better evidence.

Too salesy:

Unlock next-gen observability for your team.
Revolutionize your incident response.
Scale confidence with AI-powered insights.

8.5 Code and numeric typography

Use monospaced typography for:

* deploy SHAs;
* route names;
* metric names;
* labels;
* timestamps;
* incident IDs;
* CLI commands;
* SLO specs;
* generated rules.

Examples:

deploy_sha: 8f31c2a
route: GET /checkout/:id
slo: checkout_completion
burn_rate_5m: 14.2x

⸻

9. Layout and UI Design

9.1 Design philosophy

Parapet UI should feel like an annotated reliability field manual:

structured
quiet
scannable
evidence-rich
low-drama

9.2 Spatial system

Use an 8px grid.

Recommended spacing tokens:

--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 24px;
--space-6: 32px;
--space-7: 48px;
--space-8: 64px;

9.3 Shape system

Use sturdy, low-radius components.

--radius-xs: 4px;
--radius-sm: 6px;
--radius-md: 10px;
--radius-lg: 14px;
--radius-xl: 20px;

Rules:

* Cards: 10px radius.
* Buttons: 8px radius.
* Badges: 999px pill radius only for compact status labels.
* Modals: 14px radius.
* Avoid bubbly, playful 24px+ radii on core components.

9.4 Borders and shadows

Parapet should rely more on borders than heavy shadows.

Use:

--border-light: 1px solid rgba(16, 24, 32, 0.12);
--border-dark: 1px solid rgba(248, 244, 236, 0.16);

Shadows:

--shadow-card: 0 1px 2px rgba(16, 24, 32, 0.06);
--shadow-popover: 0 12px 32px rgba(16, 24, 32, 0.16);

Avoid glossy SaaS shadows and dramatic floating cards.

9.5 Admin UI navigation

Recommended admin sections:

Overview
SLOs
Journeys
Incidents
Deploys
Jobs
Email
Webhooks
Metrics
Wide Events
Runbooks
Doctor
AI Context
Settings

9.6 Dashboard hierarchy

The Parapet dashboard should always lead with user harm, not infrastructure trivia.

Recommended order:

1. User journeys / SLO health
2. Active burns and budget risk
3. Current incidents
4. Recent deploys and changes
5. Jobs, webhooks, email deliverability
6. Database and app saturation
7. Evidence timeline
8. Doctor checks

Infrastructure metrics are important, but they are supporting evidence, not the homepage headline.

9.7 Component principles

SLO Card

Must show:

Journey name
Current state
SLO target
Error budget remaining
Burn rate
Time window
Last deploy correlation
Primary next action

Example:

Checkout completion
Burning
Target: 99.5%
Budget remaining: 41%
5m burn: 14.2x
1h burn: 6.1x
First correlated change:
deploy 8f31c2a, 6 minutes before burn
Next:
Open rollback runbook

Incident Timeline

Must separate:

Observed
Correlated
Hypothesized
Action taken
Resolved
Learned

Do not merge guesses into facts.

Doctor Check

Doctor checks should be direct and educational.

Example:

High-cardinality metric label detected
Metric:
phoenix.endpoint.duration
Unsafe label:
user_id
Why this matters:
Prometheus creates a new time series for each unique label set.
Suggested fix:
Move user_id to a wide event field and keep metrics grouped by route, method, and status_class.

AI Evidence Panel

AI-generated content must be visibly labeled.

Required labels:

Generated summary
Sources
Facts
Hypotheses
Recommended next step
Blocked actions

AI text should never appear as if it were primary telemetry.

⸻

10. Data Visualization

10.1 Chart style

Charts should be:

* sparse;
* annotated;
* threshold-aware;
* low-color;
* directly labeled;
* readable in incident pressure.

Use:

* horizontal threshold lines;
* vertical deploy markers;
* shaded incident windows;
* burn-rate labels;
* inline annotations.

Avoid:

* rainbow lines;
* decorative gradients;
* 3D charts;
* unlabeled axes;
* charts that require hover to understand critical state;
* animated “live” drama.

10.2 SLO visualization

Preferred SLO visuals:

Error budget remaining bar
Burn rate over time
Good vs bad events
Request volume context
Deploy markers
Incident windows

Always show budget context. A 2% failure rate means different things depending on the SLO, volume, and window.

10.3 Incident colors

Use one primary incident color at a time.

Example:

Burning: Incident Red
Watch state: Beacon Amber
Healthy baseline: Budget Moss
Context lines: Stone / Wall Slate

10.4 Metrics vs wide events visual language

Metrics:

aggregated
low-cardinality
stable
trend-oriented

Wide events:

specific
high-context
investigatory
timeline-oriented

Visual distinction:

* Metrics use charts and grouped tables.
* Wide events use timelines, field inspectors, and evidence cards.

⸻

11. Imagery and Illustration

11.1 Acceptable imagery

Use imagery inspired by:

* rooflines;
* low protective walls;
* architectural sections;
* masonry diagrams;
* survey marks;
* annotated plans;
* dawn/dusk skylines;
* calm field notebooks;
* measured thresholds;
* signal lights;
* human-scale operations.

11.2 Illustration style

Preferred:

thin-line architectural drawings
simple block forms
cutaway diagrams
warm paper backgrounds
subtle grid overlays
minimal color accents

Illustrations should feel like engineering documentation with taste, not startup cartoons.

11.3 Photography direction

If photography is used:

* use quiet architectural details;
* show edges, railings, rooftops, walls, stairs, bridges;
* prefer natural light;
* avoid dramatic disaster imagery;
* avoid people panicking;
* avoid generic server racks;
* avoid stock “team in war room” scenes.

11.4 Iconography

Use:

* line icons;
* 1.5px or 2px stroke;
* squared-off but not harsh corners;
* simple silhouettes;
* no filled emoji-style icons.

Icon concepts:

SLO: target line / gauge
Incident: timeline marker
Deploy: vertical marker / flag
Runbook: document with folded corner
Doctor: checklist / stethoscope abstracted
Wide Event: event card / expanding fields
AI Context: small sparkle? Prefer labeled document + violet accent
Email: envelope + status dot
Webhook: branching arrow

Avoid:

* sirens as default;
* skulls;
* flames;
* shields everywhere;
* medieval weapons;
* castle towers;
* eyeballs;
* robot mascots.

⸻

12. Documentation Style

12.1 Documentation promise

Parapet docs should make the developer feel:

I can install this safely.
I understand what it will generate.
I know where the data goes.
I can inspect and override the defaults.

12.2 Documentation structure

Every major guide should follow:

1. What this does
2. When to use it
3. Install / configure
4. Minimal example
5. Generated output
6. Operational behavior
7. Safety and privacy notes
8. Common mistakes
9. Customization
10. Related modules

12.3 Documentation tone

Good:

Start with one journey. A useful checkout SLO is better than ten vague service metrics.

Good:

This label is safe because it has a bounded set of values: success, failure, timeout.

Good:

This generated alert pages only when the burn rate suggests user-visible harm.

Avoid:

Just plug this in and get instant observability.

Avoid:

Parapet magically understands your whole app.

Avoid:

This is the only correct way to monitor Phoenix.

12.4 README opening

Recommended README opening:

# Parapet
Parapet is an open-source reliability layer for Phoenix apps.
It turns Phoenix, Ecto, Plug, Oban, and application telemetry into SLOs, burn-rate alerts, dashboards, runbooks, incident timelines, and AI-readable evidence bundles.
Parapet is not an observability backend. It is the protective edge between raw telemetry and operational action.

12.5 Docs examples

Use realistic SaaS journeys:

login
checkout
payment_webhook
invoice_email
password_reset
api_request
critical_job
customer_import

Avoid abstract examples like:

foo
bar
baz
thing
my_metric

12.6 Tutorial principle

Teach the reliability idea while showing code.

Example:

## Define a checkout journey
A journey is a user-visible path that Parapet can protect with an SLO. This example tracks whether users who start checkout are able to complete it.
```elixir
journey :checkout do
  good_event [:my_app, :checkout, :completed]
  total_event [:my_app, :checkout, :started]
  objective 99.5
  window :days, 30
end

This creates:

* a metric definition;
* an SLO spec;
* recording rules;
* burn-rate alerts;
* dashboard panels;
* a runbook stub.

---
## 13. UX Microcopy
### 13.1 Empty states
SLOs empty state:
```text
No journeys protected yet.
Define one user journey to create its SLO, dashboard panel, and runbook.

Incidents empty state:

No incidents recorded.
When an SLO burns fast enough to page, Parapet will start an evidence timeline here.

Runbooks empty state:

No runbook linked.
Add the first safe mitigation step so future-you has a place to start.

Doctor empty state:

No doctor checks have run yet.
Run `mix parapet.doctor` to find telemetry, alerting, privacy, and cardinality issues.

13.2 Alert text

Good alert:

Checkout completion SLO is fast-burning.
Users may be unable to complete checkout.
5m burn: 14.2x
1h burn: 6.1x
Budget remaining: 41%
First correlated change: deploy 8f31c2a
Runbook: Roll back checkout deploy

Bad alert:

Critical anomaly detected in checkout metrics.

13.3 Button labels

Use:

Open runbook
View evidence
Mark as investigating
Attach deploy
Generate rules
Run doctor
Classify route
Export context

Avoid:

Fix it
Resolve everything
Autopilot
Magic analyze
Panic
Kill process

13.4 Confirmation dialogs

Destructive or mutating actions:

Confirm rollback marker
Parapet will record this rollback marker in the incident timeline.
It will not deploy code or change production state.
Continue?

AI-assisted action:

Approval required
The assistant recommends disabling `checkout_tax_v2`.
Parapet will not perform this action automatically.
Review the evidence and choose an action.

13.5 Error messages

Pattern:

[What happened]
[Why it matters]
[How to fix it]

Example:

Parapet could not generate the checkout SLO.
The journey uses `account_id` as a metric label, which can create unbounded Prometheus series.
Move `account_id` to a wide event field, or replace it with a bounded label such as `account_tier`.

⸻

14. Brand Voice for AI Context

14.1 AI assistant behavior

Parapet’s AI-facing material should require the assistant to:

* cite source telemetry, config, runbooks, or incident notes;
* label facts vs hypotheses;
* avoid confident claims without evidence;
* prefer read-only investigation;
* require approval for mutating actions;
* preserve privacy and redaction policies;
* show what it does not know.

14.2 AI summary format

Canonical format:

## Summary
Checkout completion is below its SLO and the error budget is burning quickly.
## Facts
- The 5-minute burn rate is 14.2x.
- The 1-hour burn rate is 6.1x.
- Deploy `8f31c2a` happened 6 minutes before the first burn spike.
- `checkout_started` volume is normal.
- `checkout_completed` volume is down 38%.
## Hypotheses
1. The latest deploy changed checkout completion behavior.
2. The payment provider path may be timing out.
3. The new tax calculation feature flag may be involved.
## Recommended next step
Open the rollback runbook or disable `checkout_tax_v2`.
## Blocked actions
- Do not roll back automatically.
- Do not disable feature flags without approval.
- Do not expose user IDs or email addresses in metric labels.

14.3 AI tone

AI summaries must sound like:

careful incident scribe

Not:

autonomous operator
fortune teller
sales demo
security cop

⸻

15. Homepage Direction

15.1 Homepage concept

The homepage should feel like arriving at a calm reliability surface.

Visual structure:

Hero: deep slate background, warm text, restrained stepped parapet mark
Below hero: product promise in three cards
Middle: journey-to-SLO workflow
Proof: generated artifacts
Final: install command + docs links

15.2 Hero copy options

Option A:

A protective edge for Phoenix reliability.
Parapet turns Phoenix telemetry into SLOs, burn-rate alerts, runbooks, dashboards, incident timelines, and AI-readable evidence.

Option B:

See user harm before it becomes chaos.
Parapet gives Phoenix apps a calm reliability layer: SLOs, alerts, deploy correlation, runbooks, and evidence.

Option C:

From telemetry to operational action.
Parapet helps Phoenix teams define user journeys, protect them with SLOs, and respond with evidence when budgets burn.

15.3 Homepage sections

Recommended sections:

1. Hero
2. What Parapet protects
3. Define journeys once
4. Generate the reliability loop
5. Built for Phoenix and Elixir
6. Safe by default
7. AI-readable, approval-gated
8. Install
9. Community / contribution

15.4 Homepage visual motifs

Use:

* stepped horizontal divider;
* narrow “sightline” rules;
* deploy markers as vertical lines;
* route names in mono;
* runbook cards;
* SLO cards;
* warm paper-like docs panels.

Avoid:

* giant product dashboard screenshot as the entire hero;
* abstract blobs;
* cyber shields;
* fantasy castles;
* AI sparkle overload.

⸻

16. Admin UI Direction

16.1 Admin UI emotional goal

The admin UI should make a tired founder or on-call engineer feel:

I know what is happening.
I know whether users are hurt.
I know what changed.
I know the safest next step.

16.2 Admin UI shell

Recommended structure:

Left nav: dark slate
Top bar: current environment, deploy SHA, data freshness
Main area: light limestone/white
Right rail: evidence/runbook/context when needed

Top bar should include:

Environment: prod
Current deploy: 8f31c2a
Data freshness: 22s ago
Active incidents: 1

16.3 Primary overview

Overview page modules:

SLO Health
Active Burns
Recent Deploys
Critical Journeys
Incident Timeline
Doctor Warnings
Runbook Coverage
AI Evidence Readiness

16.4 SLO page

Each SLO should show:

Objective
Window
SLI definition
Good events
Total events
Budget remaining
Burn rates
Alert rules
Generated PromQL
Runbook
Recent related deploys
Recent related wide events

16.5 Incident page

Incident page should show:

Impact summary
Timeline
Evidence
Correlations
Actions
Runbook
Customer-safe update
Postmortem notes

Timeline event labels:

Observed
Alerted
Acknowledged
Correlated
Mitigated
Resolved
Learned

16.6 Doctor page

Doctor categories:

Telemetry
SLO definitions
Cardinality
Privacy/redaction
Prometheus/Grafana
OpenTelemetry
LiveDashboard/admin security
Email deliverability
Webhook authenticity
AI/MCP safety

Severity labels:

Info
Watch
Action needed
Unsafe

Do not use “critical” unless immediate user harm or security exposure exists.

⸻

17. Open Source Identity

17.1 OSS values

Parapet should feel:

* transparent;
* inspectable;
* composable;
* vendor-neutral;
* respectful of the host app;
* practical for solo developers;
* credible for consultants and SREs.

17.2 OSS promise

Parapet should generate artifacts you can read, own, and modify.

This is a core differentiator. Do not hide generated rules, dashboards, or runbooks behind a black box.

17.3 Community tone

Use:

Clear issue templates
Practical examples
No blame
No gatekeeping
Respect for maintainers’ time

Avoid:

“RTFM”
“Works for me”
“Just use Kubernetes”
“Your app is wrong”

17.4 Contribution copy

Parapet is built for Phoenix teams who want reliability without vendor lock-in or dashboard sprawl. Contributions are welcome when they preserve the project’s core bias: protect user journeys, keep alerts actionable, and make evidence easy to inspect.

⸻

18. Brand Differentiation

18.1 What Parapet is

A Phoenix-first reliability layer.
A generator of SLOs, alerts, dashboards, runbooks, and evidence.
A safe bridge from telemetry to action.
A way to make operational context readable by humans and AI assistants.

18.2 What Parapet is not

Not an observability backend.
Not an APM vendor.
Not a metrics reporter.
Not a Prometheus clone.
Not a Grafana replacement.
Not an AI incident commander.
Not a security compliance platform.

18.3 Competitive posture

Parapet should not position itself as replacing:

Prometheus
Grafana
LiveDashboard
OpenTelemetry
Sentry
AppSignal
Honeycomb
Datadog
PromEx

Instead:

Parapet composes the tools Phoenix teams already use into a coherent reliability loop.

18.4 Differentiating phrase

Parapet is not where telemetry goes to be stored. It is where telemetry becomes operational evidence.

⸻

19. Product Semantics

19.1 Core nouns

Use these product nouns consistently:

Journey
SLO
Budget
Burn
Signal
Evidence
Runbook
Incident
Doctor Check
Wide Event
Deploy Marker
Context Bundle

19.2 Avoid noun sprawl

Avoid introducing too many clever branded nouns.

Do not rename common SRE concepts just to sound proprietary.

Bad:

Ramparts
Stones
Watchmen
Battlements
Moats
Sentinels

Good:

SLOs
Runbooks
Incidents
Evidence
Doctor checks

The brand metaphor should shape the feeling, not the entire vocabulary.

19.3 Good branded feature names

Acceptable:

Parapet Doctor
Parapet Context
Parapet Runbooks
Parapet SLOs
Parapet Evidence Bundle

Avoid:

Parapet Fortress
Parapet War Room
Parapet Shield
Parapet Castle
Parapet Commander

⸻

20. Privacy and Safety Tone

20.1 Privacy stance

Parapet should be strict but helpful about data safety.

Preferred wording:

Metrics are for bounded aggregates. Wide events are for investigation. Keep personal identifiers out of metric labels.

Prometheus’s label guidance makes this split especially important because each unique label set creates a separate time series, and unbounded values can explode cardinality.  ￼

20.2 Redaction language

Use:

redacted
classified
safe field
unsafe metric label
bounded label
high-cardinality field
personal identifier

Avoid:

dirty data
bad user field
forbidden forever

20.3 AI safety language

Use:

read-only by default
approval-gated action
audited action
evidence source
blocked action

Avoid:

autonomous remediation
self-healing production
AI takes over
hands-free operations

⸻

21. Motion and Interaction

21.1 Motion principles

Motion should:

* orient;
* confirm;
* reveal;
* reduce cognitive load.

Motion should not:

* dramatize incidents;
* pulse constantly;
* create alert fatigue;
* imply panic.

21.2 Recommended motion

Use:

subtle fade for timeline entries
gentle slide for right-side evidence panel
small progress transition for budget bars
brief highlight for newly correlated deploy marker

Avoid:

flashing red panels
infinite pulsing alert dots
spinning sirens
full-screen incident animations

Respect reduced-motion preferences.

⸻

22. Accessibility

22.1 Accessibility rules

* Never rely on color alone for status.
* Pair status colors with labels and icons.
* Maintain AA contrast for text.
* Use keyboard-accessible controls.
* Preserve visible focus states.
* Make incident and alert screens usable without hover.
* Ensure charts have text summaries.
* Use plain-language labels for major states.

22.2 Focus style

Recommended:

:focus-visible {
  outline: 2px solid #256C82;
  outline-offset: 2px;
}

22.3 Status labels

Use:

Healthy
Watch
Burning
Exhausted
Unknown

Not just:

green
yellow
red
gray

⸻

23. Example Design Tokens

:root {
  /* Brand neutrals */
  --parapet-black: #101820;
  --deep-slate: #18232B;
  --wall-slate: #2E3A42;
  --stone: #D8D0C3;
  --mortar: #EAE2D4;
  --limestone: #F8F4EC;
  /* Signals */
  --watch-blue: #256C82;
  --beacon-amber: #B45309;
  --beacon-amber-light: #D97706;
  --budget-moss: #567236;
  --incident-red: #B13A32;
  --trace-violet: #6D5BD0;
  /* Status backgrounds */
  --healthy-bg: #EFF6E8;
  --healthy-text: #3F5E28;
  --healthy-border: #B6C99A;
  --watch-bg: #F8EFD7;
  --watch-text: #92400E;
  --watch-border: #E3B66E;
  --burning-bg: #FCE8E2;
  --burning-text: #9F2D2D;
  --burning-border: #E3A19A;
  --unknown-bg: #ECEFF1;
  --unknown-text: #2E3A42;
  --unknown-border: #CBD2D8;
  /* Typography */
  --font-sans: "IBM Plex Sans", Inter, ui-sans-serif, system-ui, sans-serif;
  --font-mono: "IBM Plex Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace;
  --font-serif: "IBM Plex Serif", Georgia, serif;
  /* Layout */
  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 14px;
  --shadow-card: 0 1px 2px rgba(16, 24, 32, 0.06);
  --shadow-popover: 0 12px 32px rgba(16, 24, 32, 0.16);
}

⸻

24. Example Brand Applications

24.1 GitHub repo description

A Phoenix reliability layer for SLOs, burn-rate alerts, runbooks, incident evidence, and safe telemetry defaults.

24.2 Hex package description

Parapet turns Phoenix telemetry into SLOs, alerts, dashboards, runbooks, and AI-readable operational evidence.

24.3 README badge area

Use restrained badges:

Hex
Docs
CI
License

Avoid excessive badge walls.

24.4 CLI output

Good:

Parapet Doctor
✓ Phoenix endpoint telemetry found
✓ Ecto repo telemetry found
✓ Oban telemetry found
! High-cardinality label detected
  metric: phoenix.endpoint.duration
  label: user_id
  Move user_id to a wide event field.

Avoid:

🚨🚨🚨 CRITICAL OBSERVABILITY FAILURE 🚨🚨🚨

24.5 Docs callout

> **Parapet principle**
> Page on symptoms. Investigate causes.
>
> A checkout SLO burn deserves attention because users may be unable to buy. CPU saturation may explain the burn, but it should not be the first thing the app tells you.

24.6 Homepage install block

mix archive.install hex igniter_new
mix igniter.install parapet
mix parapet.doctor

Tone under install block:

Parapet generates readable artifacts. You can inspect, edit, and own what it creates.

⸻

25. Brand Guardrails

25.1 Always do

* Lead with user journeys.
* Prefer SLOs over raw alert piles.
* Show evidence before recommendations.
* Keep AI clearly labeled.
* Use low-cardinality metrics.
* Use wide events for investigation.
* Generate inspectable artifacts.
* Keep the interface calm.
* Make docs copy-pasteable.
* Explain operational tradeoffs.

25.2 Never do

* Claim to prevent all incidents.
* Replace evidence with AI guesses.
* Hide generated rules.
* Encourage unsafe production automation.
* Page on every internal cause.
* Use medieval/fantasy theming.
* Use red as decoration.
* Shame developers for missing instrumentation.
* Use “single pane of glass.”
* Sound like enterprise compliance software.

25.3 Brand test

Before shipping copy, UI, or docs, ask:

Does this help a Phoenix developer protect a user journey?
Does this reduce panic?
Does this separate fact from hypothesis?
Does this make the next safe action clearer?
Does this respect open-source ownership?
Does this feel like Parapet, not a generic observability vendor?

⸻

26. Compact Prompt for Future LLM Use

Use this when asking an LLM to write Parapet copy, UI, docs, or design specs:

You are working on Parapet, an open-source Elixir/Phoenix reliability layer.
Parapet turns Phoenix/Ecto/Plug/Oban telemetry into user-journey SLOs, burn-rate alerts, low-cardinality metrics, wide events, deploy correlation, runbooks, incident timelines, doctor checks, and AI-readable evidence bundles.
Brand metaphor:
A parapet is a protective low wall at an edge. Parapet is the calm protective edge between raw telemetry and operational action. It gives Phoenix teams sightlines, guardrails, and evidence before user harm becomes chaos.
Brand personality:
Calm, precise, protective, evidence-first, Phoenix-native, open-source, practical, quietly opinionated.
Voice:
Write like a careful SRE helping a tired Phoenix developer. Be direct, specific, and humane. Separate facts, hypotheses, recommendations, and actions. Avoid hype, panic, militaristic language, castle/fantasy metaphors, and generic SaaS buzzwords.
Visual direction:
Warm stone neutrals, deep slate, measured signal colors. Architectural diagrams, sightlines, threshold lines, runbook cards, incident timelines. Avoid neon dashboards, war rooms, shields, sirens, castles, and AI sparkle overload.
Color tokens:
Parapet Black #101820
Deep Slate #18232B
Wall Slate #2E3A42
Stone #D8D0C3
Mortar #EAE2D4
Limestone #F8F4EC
Watch Blue #256C82
Beacon Amber #B45309
Budget Moss #567236
Incident Red #B13A32
Trace Violet #6D5BD0
Typography:
IBM Plex Sans for UI/docs, IBM Plex Mono for code/metrics/IDs, optional IBM Plex Serif for restrained editorial accents.
UX principle:
Lead with user harm, budget, burn rate, deploy correlation, evidence, and next safe action. Infrastructure metrics are supporting evidence, not the headline.
Never claim Parapet is an observability backend, APM vendor, security platform, or AI incident commander. Parapet composes the existing ecosystem into a coherent reliability loop.

⸻

27. Final Brand Essence

Parapet is the calm edge of a Phoenix system.
It does not shout.
It does not guess.
It does not bury the operator in graphs.
It shows what users feel,
what changed,
what evidence exists,
and what safe action comes next.