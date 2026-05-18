# Research & Architectural Decisions: Parapet Escalation Engine (Oban)

Based on the SRE philosophy for solo founders, the Parapet brand identity ("calm, precise, protective, evidence-first"), and the convergent engineering DNA of your sibling Elixir libraries, here is the comprehensive analysis and final recommendation for the Escalation Engine's Oban architecture.

---

## 1. Oban Backoff & Retry Strategies for External API Failures

### The Gray Area
When an escalation job attempts to ping an external API (e.g., Twilio for SMS, PagerDuty, Resend for Email) and receives a failure (5xx, 429, or network timeout), how should the Oban job behave? Should it retry indefinitely, fail quickly, or trigger a secondary action?

### Tradeoffs
*   **Approach A: Default Oban Exponential Backoff (20 retries over ~3 weeks)**
    *   *Pros:* Zero configuration. Maximizes eventual delivery.
    *   *Cons:* Catastrophic for an SRE alerting context. An alert arriving 12 hours after the incident is either useless noise or actively harmful (waking someone up for a resolved issue). It violates the "calm, precise" Parapet brand by creating phantom pager fatigue.
*   **Approach B: Capped Linear/Fast-Exponential Backoff**
    *   *Pros:* Caps the lifetime of an alert to a relevant window (e.g., 5-10 minutes). Prevents stale notifications.
    *   *Cons:* If the provider is experiencing a hard 15-minute outage, the alert is lost entirely unless there is a failover mechanism.
*   **Approach C: Strict Failover/Escalation Chaining**
    *   *Pros:* Highly reliable. Mirrors enterprise tools like PagerDuty. 
    *   *Cons:* Harder to model in standard Oban without building a complex state machine.

### Ecosystem Idioms & Prior Art
Idiomatic Elixir/Oban embraces "let it crash" for transient errors, but limits retries based on the business domain. For time-sensitive domains (like live notifications or OTP tokens), the idiomatic pattern is overriding `max_attempts` and providing a custom `backoff/1` callback. 

In successful SRE platforms (Opsgenie, PagerDuty), alerts have a strict "Time To Live" (TTL). If an SMS fails to deliver within a few minutes, the system considers the delivery channel *dead* and immediately escalates to the next channel (e.g., a voice call) or a fallback user. "Page me on user harm" means the page must happen *during* the harm, not hours later.

### Cohesive Recommendation
**Implement a "Tight, Capped Backoff with a Discard Hook for Failover."**

1.  **Fast, Bounded Retries:** Configure external notification jobs (e.g., `Parapet.Workers.NotifyWorker`) with a low `max_attempts` (e.g., `3` to `5`). Implement a custom `backoff/1` callback that retries quickly—for instance, 10s, 30s, 60s. The entire lifecycle of the job must not exceed 5 minutes.
2.  **Telemetry on Discard:** When an Oban job exhausts its attempts, it moves to the `discarded` state. Parapet should utilize Oban's telemetry (`[:oban, :job, :discard]`) or use the `discard/1` callback on the worker to catch this.
3.  **Trigger Fallback:** When a job is discarded due to API failure, the discard handler should act as a signal to the Escalation Engine to move to the next fallback step (e.g., "SMS to Primary failed -> Enqueue Email to Fallback Admin").
4.  **Why:** This aligns perfectly with the SRE doctrine and Parapet's brand. A page delayed by hours is not actionable. By failing fast and loudly within the system, Parapet can intelligently route around broken providers instead of blindly hammering them while the operator sleeps through an outage.

---

## 2. Job Cancellation vs. Graceful Exit on State Change

### The Gray Area
When an incident transitions to `acknowledged` or `resolved`, there are often pending Oban jobs scheduled in the future (e.g., "Escalate to Tier 2 in 15 minutes"). Should Parapet actively hunt down and `cancel`/`delete` these pending jobs from the database, or let them execute and gracefully exit?

### Tradeoffs
*   **Approach A: Active Cancellation (`Oban.cancel_all_jobs/1`)**
    *   *Pros:* Keeps the `oban_jobs` table pristine. Prevents the worker from booting up unnecessarily.
    *   *Cons:* To cancel effectively, you must either track `oban_job_ids` on the incident record (brittle, complex) or query the JSONB `args` column, which requires a full table scan in Postgres and is severely unperformant at scale. Furthermore, active cancellation suffers from race conditions: the cancellation signal might arrive milliseconds after the job has already started processing, resulting in a phantom page.
*   **Approach B: Idempotent Graceful Exit**
    *   *Pros:* Immune to race conditions. Zero overhead during the critical path of "acknowledging" an incident. Decentralized, robust logic.
    *   *Cons:* Leaves "dead" jobs in the scheduled queue until their time arrives. Minor DB/CPU overhead when they finally boot up just to exit.

### Ecosystem Idioms & Prior Art
The universally recommended pattern in the Oban ecosystem (and background processing in general like Sidekiq or Exq) is **Idempotency and Graceful Exit**. 

Relying on database-level job cancellation is considered an anti-pattern unless using specialized tools like Oban Pro's Workflows. Sibling libraries like `threadline` and `rulestead` rely on the host's source of truth (the DB) at the exact moment of execution, rather than attempting complex distributed state synchronization. Stripe's webhook delivery and enterprise alerting systems all evaluate the "current truth" immediately before firing the payload.

### Cohesive Recommendation
**Adopt "Idempotent Graceful Exit" as the exclusive state-management strategy.**

1.  **Never actively cancel jobs:** Do not attempt to query or delete `oban_jobs` when an incident state changes. The "Acknowledge" action in the UI/API should simply update the `incidents` table and return immediately.
2.  **Evaluate Reality on Boot:** Every escalation worker must fetch the *freshest* state of the incident/alert from the database as its very first operational step.
3.  **Return `{:cancel, reason}`:** If the incident is no longer actionable (e.g., `status in [:acknowledged, :resolved]`), the job should return `{:cancel, "Incident already acknowledged"}`.
4.  **Why:** This utilizes Oban's semantic states beautifully. Returning `{:cancel, reason}` moves the job to the `cancelled` state in Oban, rather than `completed`. This provides incredible DX and observability: an operator looking at Oban Web, Parapet Admin, or logs will see exactly *why* a page didn't fire ("Cancelled: Incident already acknowledged"), leaving a perfect, calm evidence trail without polluting error logs. It guarantees no race conditions, requires zero complex state tracking, and follows the Principle of Least Surprise.