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

IO.puts("Seeds complete: 3 incidents (open/investigating/resolved), 6 timeline entries, 1 tool audit")
