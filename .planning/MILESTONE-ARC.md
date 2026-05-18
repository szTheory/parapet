# Milestone Arc: Ecosystem Ubiquity & Operator Mastery

## Active Milestone

### v0.7 Async & Delivery Reliability

- status: active
- theme: Confidence in the background
- why_now: Extend Parapet from request-time reliability into async and provider-mediated pathways where issues surface later and with weaker default signals.
- goals:
  - Expand `Chimeway` and `Mailglass` into concrete deliverability SLI adapters
  - Expand `Rindle` into concrete async and media pipeline observability
  - Add built-in runbook support for stalled jobs, backlog recovery, and safe retries
- non_goals:
  - Full PagerDuty-style escalation management
  - Autonomous remediation that mutates production state without explicit operator intent
  - Rebuilding vendor dashboards or time-series storage inside Parapet

## Candidate Milestones

### v0.8 Escalation & Auto-Remediation

- status: candidate
- theme: The system heals itself where safe
- why_next: After async and delivery visibility exists, Parapet can layer safe host-owned escalation and selective automation on top of clearer evidence.
- goals:
  - Host-owned escalation policies for severity- and time-based routing
  - Safe reversible auto-executed runbooks for bounded mitigations

### v0.9 Performance, Scale & DX

- status: candidate
- theme: Confidence under load
- why_next: After core feature breadth is in place, validate TSDB safety, generator ergonomics, and large-installation behavior.
- goals:
  - High-scale performance audits and TSDB load testing
  - Generator and install-path refinement

### v1.0 Stable Release

- status: candidate
- theme: API freeze and release readiness
- why_next: Lock the public surface only after ecosystem coverage and operational sharp edges are proven.
- goals:
  - API and telemetry contract freeze
  - Comprehensive guides and stable release prep
