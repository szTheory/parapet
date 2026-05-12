# Phase 1: Alert Routing & Reception Validation

## Goal
Working Alertmanager webhook receiver that automatically correlates alerts to incidents.

## Must-Haves Verification (Goal-Backward)

### 1. Webhook Reception
- [ ] **Truth**: Host applications can mount a Plug to receive webhooks
- [ ] **Verify**: Ensure `Parapet.Plug.Webhook` module exists and can be added to a Phoenix router pipeline.
- [ ] **Truth**: Valid JSON payload returns 202 Accepted
- [ ] **Verify**: Send a POST request with valid Prometheus Alertmanager payload to the mounted route and verify HTTP 202 response.
- [ ] **Truth**: Invalid HTTP methods return 405 Method Not Allowed
- [ ] **Verify**: Send a GET request to the webhook plug and verify HTTP 405 response.

### 2. Incident Correlation
- [ ] **Truth**: Firing alerts are converted into Incidents
- [ ] **Verify**: Inspect the `parapet_incidents` database table after receiving a "firing" alert to ensure a new record is created with the `open` state.
- [ ] **Truth**: Alerts with identical keys are correlated
- [ ] **Verify**: Send the exact same "firing" alert twice and verify only one incident exists in the DB, and no constraint violations occurred.
- [ ] **Truth**: Database prevents duplicate correlation keys for open incidents
- [ ] **Verify**: Check that the `correlation_key` field has a unique index constrained by `state = 'open'`.

### 3. Auto-Resolution
- [ ] **Truth**: Resolved alerts change incident state to "resolved"
- [ ] **Verify**: Send a "resolved" alert with the same labels/fingerprint as a previously firing alert. Verify the incident state changes to `resolved`.
- [ ] **Truth**: Resolved alerts insert a TimelineEntry audit record
- [ ] **Verify**: Query `parapet_timeline_entries` to confirm an `auto_resolved` entry exists for the newly resolved incident.
- [ ] **Truth**: Both state changes happen transactionally
- [ ] **Verify**: Examine the code in `Parapet.Spine.AlertProcessor` to confirm `Ecto.Multi` is used for incident and timeline entry operations.
