# Phase 2 Recommendations: Operator UI & Telemetry Signatures

## Executive Summary

To fulfill Parapet's vision as the ultimate "solo founder SRE" library, Phase 2 must deliver low noise, high signal, and out-of-the-box value. The solo founder does not want a generic observability sandbox; they want a calm system that points directly from user harm to the likely cause. 

Based on a deep analysis of the ecosystem and modern SRE best practices, we have formulated a one-shot perfect set of recommendations for the two Phase 2 gray areas: Operator UI Correlation and Telemetry Signatures.

---

## 1. Operator UI Correlation (JTBD-03)

**The Goal:** Surface correlations between Auth (Sigra) and Billing (Accrue) regressions and recent deploy/config changes in the Parapet Operator UI (Phoenix LiveView) using the principle of least surprise.

### Evaluated Approaches

**Approach A: Generic Metrics & Traces Dashboard (Datadog/Grafana clone)**
*   **Pros:** Highly flexible; supports arbitrary slicing and dicing. Familiar to enterprise SREs.
*   **Cons:** High cognitive load. Forces the solo founder to mentally translate "this line on this graph went down" into "my users are hurt" and "it was caused by the deploy 5 minutes ago." Does not fit the "SaaS in a box" mandate.
*   **Verdict:** Reject for the LiveView UI. Leave raw metrics to PromEx/Grafana.

**Approach B: Critical Journeys & Contextual Incident Timeline**
*   **Pros:** Directly maps user harm (SLO fast-burn) to system changes (deploys, feature flags). Dramatically reduces mean time to mitigate (MTTM). Extremely high signal-to-noise ratio.
*   **Cons:** Requires strict adherence to telemetry contracts and deploy markers from the host application.
*   **Verdict:** **Recommended.** This provides exactly what the solo founder needs.

### The Recommendation: The Contextual Incident Timeline

The Parapet Operator UI should eschew generic graphs in favor of a **Critical Journeys** view that seamlessly pivots into a **Contextual Incident Timeline** when an SLO is burning.

**Exact UI Additions:**
1.  **Critical Journeys Dashboard:** A top-level view showing the health of critical flows (Auth, Billing) based strictly on good/total SLIs (e.g., `checkout_completion = 99.5%`). 
2.  **Contextual Incident Timeline (The Mitigation View):** When an alert fires (e.g., Checkout Success SLO fast burn), the UI presents a consolidated timeline:
    *   **T-minus 10 mins:** Show deploy markers (e.g., `Deploy SHA: abc123`) and feature flag toggles.
    *   **T-zero:** Show the drop in the good/total ratio.
    *   **T-plus 1 min:** Surface aggregated high-cardinality context from wide events (e.g., `error_class: StripeInvalidRequestError`, `feature_flags: ["new_checkout"]`).
    *   **Actionable Runbook:** Surface a one-click recommendation (e.g., "Roll back to previous SHA" or "Disable 'new_checkout' flag").

**Why this works:** It answers the operator's three panicked questions immediately: *Are users hurt? What changed recently? What is the safest mitigation?*

---

## 2. Telemetry Signatures (JTBD-01 & 02)

**The Goal:** Define the exact standard telemetry events Parapet expects from Auth (`signup`) and Billing (`checkout`, `webhook`) libraries to fuel the Critical Journeys UI and SLO engine.

### The Core Principle: Metrics vs. Wide Events
*   **Prometheus Metrics (Low Cardinality):** Used for SLO math and alerting. Allowed labels: `:plan`, `:currency`, `:provider`, `:status_class`.
*   **Wide Events (High Cardinality):** Used for incident context in the UI. Allowed fields: `:user_id`, `:account_id`, `:request_id`, `:deployment_id`, `:checkout_session_id`, `:error_class`.

### The Recommendation: Standardized Domain Events

Parapet must establish a strict telemetry contract that sibling libs (Sigra, Accrue) bind to.

#### 1. Auth / Sigra (Signup Journey)
The signup journey must emit a start event, and either a completed or failed event.

*   **Events:**
    *   `[:sigra, :auth, :signup, :started]`
    *   `[:sigra, :auth, :signup, :completed]`
    *   `[:sigra, :auth, :signup, :failed]`
*   **Metric Labels (Low Cardinality):** `[:provider]` (e.g., `:magic_link`, `:password`)
*   **Wide Event Fields (High Cardinality):** `[:account_id, :user_id, :deployment_id, :feature_flags, :error_class]`
*   **SLO Mapping:** `good` = `:completed`, `total` = `:started`

#### 2. Billing / Accrue (Checkout Journey)
Checkout flows are highly susceptible to provider errors and config regressions.

*   **Events:**
    *   `[:accrue, :billing, :checkout, :started]`
    *   `[:accrue, :billing, :checkout, :completed]`
    *   `[:accrue, :billing, :checkout, :failed]`
*   **Metric Labels (Low Cardinality):** `[:plan, :currency, :provider]`
*   **Wide Event Fields (High Cardinality):** `[:account_id, :user_id, :checkout_session_id, :deployment_id, :feature_flags, :error_class]`
*   **SLO Mapping:** `good` = `:completed`, `total` = `:started`

#### 3. Billing / Accrue (Webhook Processing)
Webhooks are async and can silently fail, causing devastating data drift.

*   **Events:**
    *   `[:accrue, :billing, :webhook, :received]`
    *   `[:accrue, :billing, :webhook, :processed]`
    *   `[:accrue, :billing, :webhook, :failed]`
*   **Metric Labels (Low Cardinality):** `[:provider, :event_type]` (e.g., `:stripe`, `:invoice_paid`)
*   **Wide Event Fields (High Cardinality):** `[:provider_message_id, :account_id, :deployment_id, :error_class]`
*   **SLO Mapping:** `good` = `:processed`, `total` = `:received` within an acceptable time window (e.g., 5 mins).

### Summary for Implementation
By standardizing on `[:app, :domain, :action, :status]` and rigorously splitting low-cardinality tags from high-cardinality wide event context, Parapet can automatically generate PromEx/Prometheus rules for burn-rate alerts while feeding the LiveView Contextual Incident Timeline with exact, actionable evidence.