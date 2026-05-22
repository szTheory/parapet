# Parapet JTBD Map

Last verified against repository state on 2026-05-21.
Current planning context: v0.9 Performance, Scale & DX.

## Purpose

This document tracks Parapet from the adopter's point of view:

- what jobs it already serves well
- what jobs are built but underexplained
- what meaningful jobs are still missing
- where adding more JTBD coverage starts to return less value

It is not a feature checklist. It is a decision aid for future milestone work.

## Current Coverage Map

### 1. Evaluation and Day-1 activation

**Status:** Shipped, improving, still slightly underexplained

Parapet already offers a coherent Day-1 paved road:

- single install entrypoint
- generated host-owned instrumentation
- generated Prometheus artifacts
- optional UI branch
- doctor verification

What is strong:

- Host ownership is clear.
- Optional extras remain explicit.
- The library does not pretend static checks are runtime proof.

What remains weaker:

- The public docs have historically explained features better than adopter flows.
- The distinction between core path and optional maturity surfaces needs continued reinforcement.

### 2. SLO modeling and telemetry shaping

**Status:** Shipped and coherent

Parapet has a strong opinion here:

- user-journey SLOs over generic subsystem dashboards
- provider-owned slice specs for built-ins
- low-cardinality public telemetry contracts
- exact identifiers demoted into refs or durable evidence

This is one of the clearest parts of the product.

### 3. Alerting and evidence ingestion

**Status:** Shipped and coherent

Parapet already closes a critical loop many libs stop short of:

- generate alerting artifacts
- ingest Alertmanager webhooks
- correlate updates into durable incidents
- preserve chronology over time

This is a core differentiator versus "metrics + dashboards only" libraries.

### 4. Incident investigation

**Status:** Shipped, coherent, still underdocumented for fresh adopters

The operator model is mature enough to describe as a real workflow:

- active queue
- incident detail
- summary-first evidence presentation
- canonical chronology
- external links outward

The product shape is good. The explanation burden was the gap.

### 5. Safe mitigation and escalation

**Status:** Partially complete but strategically important

Parapet has already built meaningful primitives:

- host-owned runbook DSL
- operator command seam with audit trail
- notification adapters
- escalation policy behavior
- system-executed bounded mitigation
- preview-first recovery direction

What is still incomplete is not the philosophy. It is depth and breadth of common recovery playbooks.

### 6. Async, delivery, and provider-mediated reliability

**Status:** Shipped and differentiated

This area is strong because it avoids the common observability trap of flattening all background work into one queue story.

Parapet already models meaningful fault planes:

- provider acceptance vs confirmed delivery
- backlog vs callback lag
- retries vs discard
- suppression drift vs generic failure

This gives Parapet a more realistic SaaS-operations story than generic request-only reliability tools.

### 7. Operational hygiene at scale

**Status:** Shipped or actively closing

The scale story is present:

- cardinality protection
- static doctor checks
- bounded queue paging
- archival path
- indexing and evidence-pruning story

This is necessary work, not glamour work, and it meaningfully increases trust for real adopters.

## Biggest Gaps

These are the largest remaining JTBD gaps, ordered by expected user value and leverage.

### 1. Common recovery depth

**Why it matters:**
Detection and investigation are strong. The biggest remaining step-up in user value is to make the next safe action more complete for common incident types.

**Current gap:**
The system has the recovery model, named capabilities, and preview-first boundary, but not yet a broad map of prebuilt common recoveries most SaaS teams will expect.

**Most likely next work:**

- richer exact-item recovery patterns
- clearer preconditions and warnings
- stronger built-in runbook templates for recurring async and delivery failures

**Priority:** Very high

### 2. Team workflow around incidents

**Why it matters:**
Parapet handles incident objects and operator action, but the team-coordination loop is thinner than the detection loop.

**Current gap:**
Ownership, handoff, responder coordination, and incident state conventions are not yet a first-class flow beyond the current evidence and notification surfaces.

**Most likely next work:**

- clearer ownership/claim semantics
- stronger acknowledgement and responder workflow
- better shift-aware escalation or handoff ergonomics

**Priority:** High

### 3. SLO authoring guidance for real adopters

**Why it matters:**
Many teams know they want SLOs but still struggle to choose the right slices, burn windows, and low-traffic-safe patterns.

**Current gap:**
The engine exists, but the guidance layer for choosing good first SLOs is thinner than it should be.

**Most likely next work:**

- opinionated starter packs by app type
- examples of good vs bad journey slicing
- low-traffic and low-volume alerting guidance

**Priority:** High

### 4. Cross-boundary journey support

**Why it matters:**
Real SaaS journeys often span multiple apps, providers, or asynchronous boundaries.

**Current gap:**
Parapet is strong inside one Phoenix app plus its integrations, but less explicit about multi-service or cross-application journey composition.

**Most likely next work:**

- better cross-system correlation guidance
- more explicit event and evidence seams for multi-app flows
- stronger deploy and change correlation across boundaries

**Priority:** Medium

### 5. Vertical depth beyond current sibling ecosystems

**Why it matters:**
Future value may come from deeper support in a few important domains, not broader genericity.

**Current gap:**
Parapet already supports several sibling ecosystems, but many possible business-critical flows remain outside first-party depth.

**Most likely next work:**

- deeper domain packs
- better first-party slice libraries for common SaaS jobs
- guidance on when to build custom provider modules

**Priority:** Medium

## What Should Inform Future Milestones

The milestone ordering should favor jobs that complete the operator loop for common adopters, not jobs that merely add more surfaces.

Recommended future ordering principle:

1. Complete common recovery loops before adding niche integrations.
2. Improve SLO authoring guidance before multiplying optional surfaces.
3. Strengthen team workflow before broadening into cross-language or hosted-product territory.
4. Prefer depth in common SaaS failure modes over breadth in exotic scenarios.

In practice, that means a future milestone should outrank another if it does one of these:

- shortens time from incident to safe action
- prevents a common user-harming ambiguity
- removes a trust blocker for operating Parapet in production
- converts a good primitive into a complete adopter workflow

## Diminishing Returns Threshold

Parapet is close to "functionally complete for core adopters" when a typical Phoenix SaaS team can do all of the following without inventing its own parallel system:

- install and verify the base path cleanly
- model the most important request, job, and provider-mediated journeys
- generate alerting and dashboard artifacts from those definitions
- ingest alerts into durable incidents
- investigate from summary to chronology to next step
- execute or escalate bounded mitigations safely
- preserve retrospectives, audits, and deploy/change correlation
- run the system at scale without TSDB or Postgres self-harm

Once that set is true, new JTBD work should be treated as diminishing-return unless it unlocks at least one of these:

- a very common SaaS incident class that still has no credible recovery story
- a large adopter segment currently blocked from success
- a major safety, scale, or trust gap
- a widely expected ecosystem workflow that adjacent tools already make routine

Signals that Parapet has crossed into diminishing returns:

- new features mostly help niche integration cases
- new flows duplicate work already better done by Grafana, Prometheus, or provider consoles
- complexity added to the operator surface is larger than clarity gained for common incidents
- the system starts behaving like a generic control plane instead of a reliability operating layer

## Out-Of-Scope Pressure To Resist

These are the expansions most likely to feel tempting and still be wrong:

- hosted observability platform behavior
- broad autonomous remediation
- provider-console replacement
- unbounded workflow orchestration
- collecting high-cardinality exact-object telemetry in metrics instead of evidence
- generic cross-language platform ambitions before Phoenix-native completeness

## Maintenance Protocol

When refreshing this document later:

1. Re-read the README, public docs, public modules, and current roadmap/requirements.
2. Diff newly shipped phases or milestones since the last verified date.
3. Re-score each coverage area as coherent, underexplained, partial, or intentionally out of scope.
4. Update the gap ordering only if the user value or dependency order changed.
5. Refresh the verified date and current planning context at the top.
