# Belt-and-suspenders: config/config.exs already sets this, but explicit here
# so `mix run priv/repo/seeds.exs` works standalone without full config load.
Application.put_env(:parapet, :repo, DemoApp.Repo)

# ---------------------------------------------------------------------------
# Incident 1: OPEN — login service spike with runbook + warning step
# ---------------------------------------------------------------------------
{:ok, incident_open} =
  Parapet.Evidence.create_incident(%{
    title: "Login service elevated error rate",
    description: "Auth endpoint returning 5xx > 2% for 10 consecutive minutes",
    state: "open",
    correlation_key: "login-error-rate-spike",
    runbook_data: %{
      "title" => "Login Failure Runbook",
      "description" => "Steps to diagnose and mitigate login service failures",
      "steps" => [
        %{
          "id" => "check_metrics",
          "label" => "Check metrics dashboard",
          "description" =>
            "Verify DB connection pool saturation and error distribution in Prometheus",
          "type" => "manual",
          "kind" => "guidance",
          "warning" =>
            "High cardinality risk — check for label explosion before querying Prometheus",
          "guidance" => nil,
          "requires_preview" => false,
          "preview_only" => false,
          "auto_execute" => false
        },
        %{
          "id" => "acknowledge",
          "label" => "Acknowledge and notify team",
          "description" => "Post update to #incidents Slack channel",
          "type" => "manual",
          "kind" => "guidance",
          "warning" => nil,
          "guidance" => nil,
          "requires_preview" => false,
          "preview_only" => false,
          "auto_execute" => false
        }
      ]
    }
  })

{:ok, _} =
  Parapet.Evidence.append_timeline(incident_open.id, %{
    type: "note",
    payload: %{"text" => "Alert triggered — investigating DB connection pool saturation"}
  })

{:ok, _} =
  Parapet.Evidence.append_timeline(incident_open.id, %{
    type: "status_change",
    payload: %{"new_state" => "open", "actor" => "alert_system"}
  })

# ---------------------------------------------------------------------------
# Incident 2: INVESTIGATING — checkout webhook failures
# ---------------------------------------------------------------------------
{:ok, incident_inv} =
  Parapet.Evidence.create_incident(%{
    title: "Checkout webhook delivery failures",
    description: "Payment webhook callbacks timing out after 5 seconds",
    state: "investigating",
    correlation_key: "checkout-webhook-timeout"
  })

{:ok, _} =
  Parapet.Evidence.append_timeline(incident_inv.id, %{
    type: "note",
    payload: %{"text" => "Traced to upstream provider rate limiting — monitoring for recovery"}
  })

{:ok, _} =
  Parapet.Evidence.append_timeline(incident_inv.id, %{
    type: "status_change",
    payload: %{"new_state" => "investigating", "actor" => "operator_ui"}
  })

# ---------------------------------------------------------------------------
# Incident 3: RESOLVED — signup email delivery degraded
# ---------------------------------------------------------------------------
{:ok, incident_resolved} =
  Parapet.Evidence.create_incident(%{
    title: "Signup email delivery degraded",
    description: "Transactional email provider returning 429s; new user signups delayed",
    state: "resolved",
    correlation_key: "signup-email-429"
  })

{:ok, _} =
  Parapet.Evidence.append_timeline(incident_resolved.id, %{
    type: "note",
    payload: %{"text" => "Provider confirmed rate limit lifted at 14:32 UTC"}
  })

{:ok, _} =
  Parapet.Evidence.append_timeline(incident_resolved.id, %{
    type: "note",
    payload: %{"text" => "All metrics nominal — marking resolved"}
  })

# ---------------------------------------------------------------------------
# Incident 4: OPEN — stalled async executor (capability-backed, Preview/Confirm)
# ---------------------------------------------------------------------------
# The capability-backed runbook needs BOTH keys: "module" resolves the compiled
# runbook for Preview/Confirm execution (extract_module/1), and "steps" drives the
# operator UI render (WorkbenchContract.derive/3 reads inline "steps" to render the
# Preview button). The inline steps mirror DemoApp.Runbooks.StalledExecutor — the
# step ids MUST match so the rendered Preview button resolves to the module step.
stalled_executor_steps = [
  %{
    "id" => "investigate_logs",
    "label" => "Check Worker Logs",
    "description" => "Verify if the worker process crashed without reporting, or if it is currently deadlocked.",
    "type" => "manual",
    "kind" => "guidance",
    "preview_only" => true,
    "guidance" => "Search your APM for the worker executing this item. Look for crash reports, timeout events, or lock-acquisition failures around the item's last-attempt timestamp.",
    "warning" => "If logs show the item is still actively executing, do not retry — a concurrent retry will cause a duplicate execution race."
  },
  %{
    "id" => "retry_item",
    "label" => "Retry Item",
    "description" => "Force the async item to be retried.",
    "type" => "mitigation",
    "kind" => "capability",
    "capability" => "retry_async_item",
    "target_kind" => "async_item",
    "requires_preview" => true,
    "warning" => "Retrying without identifying the root cause may reproduce the deadlock. Confirm the underlying resource or lock contention is resolved before proceeding."
  },
  %{
    "id" => "verify_recovery",
    "label" => "Verify Recovery",
    "description" => "Confirm the item completed successfully after the retry.",
    "type" => "manual",
    "kind" => "guidance",
    "preview_only" => true,
    "guidance" => "Check the item's status in the job backend — it should transition from executing or scheduled to completed."
  }
]

{:ok, incident_stalled} =
  Parapet.Evidence.create_incident(%{
    title: "Stalled async executor",
    description: "Background job stuck in executing state for > 10 minutes",
    state: "open",
    correlation_key: "stalled-async-executor",
    runbook_data: %{
      "title" => "Stalled Executor Recovery",
      "description" => "Guidance and recovery actions for background jobs stuck in an executing state.",
      "module" => to_string(DemoApp.Runbooks.StalledExecutor),
      "steps" => stalled_executor_steps
    }
  })

{:ok, _} =
  Parapet.Evidence.append_timeline(incident_stalled.id, %{
    type: "note",
    payload: %{"text" => "Job ID 8821 last heartbeat at 09:14 UTC — executor did not report completion"}
  })

# Open action item linked to the stalled-executor incident, so the
# Preview → Confirm flow has a real DB row to operate on: confirming the
# capability flips this item's state (open → resolved).
{:ok, _action_item} =
  %Parapet.Spine.ActionItem{}
  |> Parapet.Spine.ActionItem.changeset(%{
    title: "async_job_8821",
    integration: "demo",
    external_id: "ext-8821",
    kind: "stalled_workflow",
    state: "open",
    incident_id: incident_stalled.id
  })
  |> DemoApp.Repo.insert()

# ---------------------------------------------------------------------------
# Tool audit — records a doctor check against the demo environment
# ---------------------------------------------------------------------------
{:ok, _} =
  Parapet.Evidence.log_tool_audit(%{
    tool_name: "parapet_doctor",
    input: %{"env" => "demo", "check" => "operator_ui_accessible"},
    output: %{"status" => "ok", "route" => "/parapet", "http_status" => 200},
    success: true,
    duration_ms: 23
  })

IO.puts("Seeds complete: 4 incidents (open x2/investigating/resolved), 7 timeline entries, 1 action item, 1 tool audit")
