# Epic: Ecosystem Ubiquity & Operator Mastery (v0.6 - v1.0)

## The Arc

Parapet has successfully established its "Trustworthy Spine" (v0.1-v0.3) and proved its extensibility with advanced AI/Proactive observability (v0.4-v0.5). The system can ingest metrics, route alerts, present a durable UI, and act as an MCP server. 

To reach v1.0, Parapet must fulfill its promise of being the **"batteries-included reliability layer that makes the Elixir ecosystem cohere."** This epic focuses on deep, out-of-the-box integrations with the remaining Tier-1 ecosystem libraries, correlating metrics with traces/flags, and providing operator mastery over automated remediation.

## Roadmap Breakdown

### Milestone v0.6: Change Correlation & Audit Trailing
**Theme:** "Every alert is correlated to the change that caused it."
* **Rulestead Integration:** Native tracking of feature flag flips. When a `Parapet.SLO` burns down, the UI immediately surfaces any Rulestead flags toggled in the last 15 minutes.
* **Threadline Integration:** Seamless interop with Threadline for durable, tamper-evident operator audit trails. Parapet's `ToolAudit` can optionally dual-write or defer to Threadline for compliance-heavy environments.
* **OpenTelemetry Trace Linking:** Parapet metrics currently handle the "macro" view. v0.6 adds native examplar support and trace-ID extraction, allowing operators to click an incident and jump directly into a sampled OTel trace.

### Milestone v0.7: Async & Delivery Reliability
**Theme:** "Confidence in the background."
* **Chimeway & Mailglass Integration:** Concrete SLIs for email/notification deliverability. Out-of-the-box monitoring for provider drift, queue backlogs, and suppression rates.
* **Rindle Integration:** Observability for long-running media processing jobs, external webhook delays, and async funnel health.
* **Stalled Job Runbooks:** Built-in runbook templates for clearing Oban dead-letter queues or retrying failed deliveries.

### Milestone v0.8: Escalation & Auto-Remediation
**Theme:** "The system heals itself where safe."
* **Escalation Policies:** Simple, host-owned on-call routing. Not trying to replace PagerDuty, but providing a lightweight way to page a specific Slack user/channel based on time-of-day or severity.
* **Automated Runbooks (Auto-Remediation):** Extending the v0.3 `Parapet.Runbook` DSL to allow `auto_execute: true` for safe, reversible mitigations (e.g., reverting a specific Rulestead flag if the error rate spikes within 5 minutes of flipping it).

### Milestone v0.9 & v1.0: Polish, Conformance & Release
* **v0.9:** Performance auditing at high scale, TSDB load testing, and refining the generator DX.
* **v1.0:** API freeze, comprehensive guide updates, and stable release.

## Focus for Milestone v0.6

We will begin with **v0.6: Change Correlation & Audit Trailing**. This is the highest-value next step because finding the *cause* of an incident (often a deployment or flag toggle) is the most time-consuming part of triage. 

**v0.6 Key Requirements:**
1. Rulestead flag-toggle telemetry integration.
2. Operator UI timeline correlation with Rulestead changes.
3. OpenTelemetry Exemplar/Trace-ID extraction for deep-linking.
4. Threadline compliance mapping for Parapet's internal audit logs.
