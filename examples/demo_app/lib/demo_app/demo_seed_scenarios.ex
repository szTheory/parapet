defmodule DemoApp.DemoSeedScenarios do
  @moduledoc false

  @scenarios ~w(response recovery escalation history all long_string empty max_items mixed_status stress)

  def scenarios, do: @scenarios

  def seed("response") do
    login_service_spike()
    checkout_webhook_failures()
    tool_audit()
  end

  def seed("recovery") do
    stalled_async_executor()
    tool_audit()
  end

  def seed("escalation") do
    checkout_webhook_failures()
    retry_storm()
    tool_audit()
  end

  def seed("history") do
    signup_email_resolved()
    tool_audit()
  end

  def seed("all") do
    login_service_spike()
    checkout_webhook_failures()
    signup_email_resolved()
    stalled_async_executor()
    retry_storm()
    tool_audit()
  end

  def seed("empty"), do: :ok

  def seed("long_string") do
    long_string_incident()
  end

  def seed("max_items") do
    max_items_dense()
  end

  def seed("mixed_status") do
    mixed_status_spread()
  end

  def seed("stress") do
    long_string_incident()
    max_items_dense()
    mixed_status_spread()
  end

  def seed(scenario) do
    raise ArgumentError,
          "unknown PARAPET_DEMO_SCENARIO=#{inspect(scenario)}; expected one of: #{Enum.join(@scenarios, ", ")}"
  end

  # ---------------------------------------------------------------------------
  # Existing scenario helpers (untouched)
  # ---------------------------------------------------------------------------

  defp login_service_spike do
    {:ok, incident} =
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
                "High cardinality risk - check for label explosion before querying Prometheus",
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

    append(incident, "note", %{
      "text" => "Alert triggered - investigating DB connection pool saturation"
    })

    append(incident, "status_change", %{"new_state" => "open", "actor" => "alert_system"})

    append(incident, "external_link", %{
      "label" => "Grafana login burn-rate panel",
      "url" => grafana_dashboard_url()
    })
  end

  defp grafana_dashboard_url do
    base_url =
      System.get_env("PARAPET_DEMO_GRAFANA_URL") ||
        "http://127.0.0.1:#{System.get_env("GRAFANA_PORT", "3000")}"

    "#{base_url}/d/parapet_demo/parapet-demo-operator-evidence?orgId=1&from=now-15m&to=now"
  end

  defp checkout_webhook_failures do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "Checkout webhook delivery failures",
        description: "Payment webhook callbacks timing out after 5 seconds",
        state: "investigating",
        correlation_key: "checkout-webhook-timeout",
        runbook_data: %{
          "escalation" => %{
            "pending_trigger" => true,
            "trigger_requested_at" =>
              DateTime.utc_now() |> DateTime.add(-300, :second) |> DateTime.to_iso8601(),
            "next_escalation_at" =>
              DateTime.utc_now() |> DateTime.add(900, :second) |> DateTime.to_iso8601(),
            "current_step_id" => "provider-owner",
            "chain" => [
              %{
                "id" => "primary",
                "label" => "Primary operator",
                "delay" => "now",
                "status" => "completed"
              },
              %{
                "id" => "provider-owner",
                "label" => "Provider owner",
                "delay" => "15m",
                "status" => "current"
              },
              %{
                "id" => "billing-owner",
                "label" => "Billing owner",
                "delay" => "30m",
                "status" => "pending"
              }
            ]
          }
        }
      })

    append(incident, "note", %{
      "text" => "Traced to upstream provider rate limiting - monitoring for recovery"
    })

    append(incident, "status_change", %{"new_state" => "investigating", "actor" => "operator_ui"})

    append(incident, "escalation_trigger_requested", %{
      "actor" => "operator_ui",
      "reason" => "Checkout owner should review provider timeout pattern"
    })
  end

  defp signup_email_resolved do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "Signup email delivery degraded",
        description: "Transactional email provider returning 429s; new user signups delayed",
        state: "resolved",
        correlation_key: "signup-email-429",
        runbook_data: %{
          "retrospective" => """
          # Signup email delivery degraded

          Impact stopped after provider rate limits cleared. Timeline shows alert, provider confirmation, and operator resolution. Follow-up: keep delivery-provider SLO thresholds unchanged; this was external throttling, not internal backlog drift.
          """
        }
      })

    append(incident, "note", %{"text" => "Provider confirmed rate limit lifted at 14:32 UTC"})
    append(incident, "note", %{"text" => "All metrics nominal - marking resolved"})

    append(incident, "escalation_executed", %{
      "mode" => "scheduled",
      "policy" => "delivery-provider-owner"
    })
  end

  defp stalled_async_executor do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "Stalled async executor",
        description: "Background job stuck in executing state for > 10 minutes",
        state: "open",
        correlation_key: "stalled-async-executor",
        runbook_data: %{
          "title" => "Stalled Executor Recovery",
          "description" =>
            "Guidance and recovery actions for background jobs stuck in an executing state.",
          "module" => to_string(DemoApp.Runbooks.StalledExecutor),
          "escalation" => %{
            "suppressed_until" =>
              DateTime.utc_now() |> DateTime.add(1_800, :second) |> DateTime.to_iso8601(),
            "suppressed_by" => "operator_ui",
            "suppression_reason" =>
              "Recovery preview is active; avoid paging while operator validates target state",
            "chain" => [
              %{
                "id" => "operator",
                "label" => "Primary operator",
                "delay" => "now",
                "status" => "current"
              },
              %{
                "id" => "backend-owner",
                "label" => "Backend owner",
                "delay" => "30m",
                "status" => "pending"
              }
            ]
          },
          "steps" => stalled_executor_steps()
        }
      })

    append(incident, "note", %{
      "text" => "Job ID 8821 last heartbeat at 09:14 UTC - executor did not report completion"
    })

    append(incident, "escalation_suppressed", %{
      "actor" => "operator_ui",
      "suppressed_until" =>
        DateTime.utc_now() |> DateTime.add(1_800, :second) |> DateTime.to_iso8601(),
      "reason" => "Operator is validating preview target refs"
    })

    {:ok, _action_item} =
      %Parapet.Spine.ActionItem{}
      |> Parapet.Spine.ActionItem.changeset(%{
        title: "async_job_8821",
        integration: "demo",
        external_id: "ext-8821",
        kind: "stalled_workflow",
        state: "open",
        incident_id: incident.id
      })
      |> DemoApp.Repo.insert()
  end

  defp retry_storm do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "Retry storm detected on delivery workers",
        description: "Delivery workers retrying too aggressively after provider outage",
        state: "open",
        correlation_key: "delivery-retry-storm",
        runbook_data: %{
          "title" => "Retry Storm Guidance",
          "description" =>
            "Do not retry blindly. Reduce pressure and verify provider recovery first.",
          "escalation" => %{
            "current_step_id" => "operator",
            "chain" => [
              %{
                "id" => "operator",
                "label" => "Primary operator",
                "delay" => "now",
                "status" => "current"
              },
              %{
                "id" => "infra-owner",
                "label" => "Infrastructure owner",
                "delay" => "20m",
                "status" => "pending"
              }
            ]
          },
          "steps" => [
            %{
              "id" => "stop_retry_pressure",
              "label" => "Stop retry pressure",
              "description" =>
                "Pause new retries until provider health and backlog shape are clear.",
              "type" => "manual",
              "kind" => "guidance",
              "guidance" =>
                "Check provider status and backlog age before changing retry configuration.",
              "warning" =>
                "Retrying a storm usually worsens user impact and provider throttling.",
              "preview_only" => true
            }
          ]
        }
      })

    append(incident, "escalation_short_circuited", %{
      "reason" => "circuit breaker open after repeated retry attempts"
    })

    append(incident, "note", %{
      "text" => "Circuit breaker prevented a third retry wave; monitor backlog drain."
    })
  end

  defp tool_audit do
    {:ok, _} =
      Parapet.Evidence.log_tool_audit(%{
        tool_name: "parapet_doctor",
        input: %{"env" => "demo", "check" => "operator_ui_accessible"},
        output: %{"status" => "ok", "route" => "/parapet", "http_status" => 200},
        success: true,
        duration_ms: 23
      })
  end

  defp stalled_executor_steps do
    [
      %{
        "id" => "investigate_logs",
        "label" => "Check Worker Logs",
        "description" =>
          "Verify if the worker process crashed without reporting, or if it is currently deadlocked.",
        "type" => "manual",
        "kind" => "guidance",
        "preview_only" => true,
        "guidance" =>
          "Search your APM for the worker executing this item. Look for crash reports, timeout events, or lock-acquisition failures around the item's last-attempt timestamp.",
        "warning" =>
          "If logs show the item is still actively executing, do not retry - a concurrent retry will cause a duplicate execution race."
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
        "warning" =>
          "Retrying without identifying the root cause may reproduce the deadlock. Confirm the underlying resource or lock contention is resolved before proceeding."
      },
      %{
        "id" => "verify_recovery",
        "label" => "Verify Recovery",
        "description" => "Confirm the item completed successfully after the retry.",
        "type" => "manual",
        "kind" => "guidance",
        "preview_only" => true,
        "guidance" =>
          "Check the item's status in the job backend - it should transition from executing or scheduled to completed."
      }
    ]
  end

  defp append(incident, type, payload) do
    {:ok, _} = Parapet.Evidence.append_timeline(incident.id, %{type: type, payload: payload})
  end

  # ---------------------------------------------------------------------------
  # New scenario helpers (Tasks 1-3)
  # ---------------------------------------------------------------------------

  # FIXTURE-01: long_string — machine-shaped unbroken long strings in all fields
  defp long_string_incident do
    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title:
          "SVC0042InternalAuthorizationTokenValidationFailureHighFrequencyDetectedOnPrimaryIngestionPipelineNode",
        description:
          "BackgroundWorkerProcessPoolExhaustedDuringPeakThroughputWindowCausedByUnboundedRetryLoopInDistributedMessageConsumerSubsystemv2ComponentRegistrationAndDispatchLayer",
        state: "open",
        correlation_key:
          "SVC0042AUTHZFAILURE3f8a2d1c9e4b7a0f6e2c8d5b1a9f3e7c2d0b4a8f1e5c9d3b7a0f4e8c2d6b0a",
        runbook_data: %{
          "title" =>
            "LongStringOverflowHardeningValidationRunbook_SVC0042_InternalAuthorizationTokenValidation",
          "description" =>
            "RunbookForValidatingThatAllOperatorUIComponentsCorrectlyHandleLongUnbrokenMachineShapedStringsWithoutOverflowOrTruncationLossOfInformation",
          "steps" => [
            %{
              "id" => "step_01_validate_tokenstore_replication_lag_threshold_breach_indicator",
              "label" =>
                "ValidateTokenStoreReplicationLagThresholdBreachIndicatorAndCrossReferenceWithSecondaryIndexConsistencyCheck",
              "description" =>
                "VerifyThatTheTokenStoreReplicationLagHasNotExceededTheConfiguredThresholdOf500msAcrossAllThreeAvailabilityZonesAndThatTheSecondaryIndexConsistencyCheckReportsNoPartialWriteStateForTheAffectedPartitionKeys",
              "type" => "manual",
              "kind" => "guidance",
              "preview_only" => true,
              "guidance" =>
                "RunTheFollowingQueryAgainstYourPrimaryInternalMonitoringSystemAndCompareOutputAgainstTheBaselineSnapshotGeneratedAtLastSuccessfulDeploymentOfTheAuthorizationSubsystem"
            }
          ]
        }
      })

    append(incident, "external_link", %{
      "label" =>
        "InternalObservabilityDashboard_SVC0042_AuthzTokenValidationFailureRateByPartitionKey",
      "url" =>
        "https://internal.monitoring.example.com/dashboards/uid/SVC0042AUTHZFAILURE?orgId=1&from=now-6h&to=now&var-service=auth-ingestion-primary&var-component=token-validation&var-partition=all&var-threshold=p99&var-aggregation=rate5m&var-breakdown=by_partition_key&refresh=30s&theme=light"
    })

    {:ok, _action_item} =
      %Parapet.Spine.ActionItem{}
      |> Parapet.Spine.ActionItem.changeset(%{
        title:
          "SVC0042AuthzTokenValidationFailureRequiresImmediatePartitionKeyInvalidationAndCacheFlushAcrossAllIngestionNodes",
        integration: "demo",
        external_id:
          "EXTID_SVC0042_3f8a2d1c9e4b7a0f6e2c8d5b1a9f3e7c2d0b4a8f1e5c9d3b7a0f4e8c2d6b0a_PARTITIONKEYINVALIDATION",
        kind: "exact_follow_up",
        state: "open",
        incident_id: incident.id
      })
      |> DemoApp.Repo.insert()
  end

  # FIXTURE-03: max_items — 35 active incidents to cross page-size-30 boundary
  defp max_items_dense do
    # Create 35 active incidents (crosses @default_queue_page_size 30 with margin)
    Enum.each(1..35, fn n ->
      {:ok, incident} =
        Parapet.Evidence.create_incident(%{
          title: "Dense load incident #{n}: background queue processor lag",
          description: "Queue consumer backlog growing; incident #{n} of 35 in dense load batch",
          state: if(rem(n, 3) == 0, do: "investigating", else: "open"),
          correlation_key: "dense-load-batch-#{n}-queue-processor-lag-#{:rand.uniform(999_999)}"
        })

      # Add action items to a subset of incidents to exercise the actions view density
      if rem(n, 5) == 0 do
        {:ok, _} =
          %Parapet.Spine.ActionItem{}
          |> Parapet.Spine.ActionItem.changeset(%{
            title: "dense_action_item_incident_#{n}",
            integration: "demo",
            external_id: "ext-dense-#{n}",
            kind: "dead_letter",
            state: "open",
            incident_id: incident.id
          })
          |> DemoApp.Repo.insert()
      end

      # Add a longer timeline to the first incident to exercise dense-list rendering
      if n == 1 do
        Enum.each(1..5, fn e ->
          append(incident, "note", %{
            "text" => "Dense load timeline entry #{e}: queue backlog at #{e * 200} messages"
          })
        end)
      end
    end)
  end

  # FIXTURE-04: mixed_status — all three incident states + escalation diversity + one open action item per kind
  defp mixed_status_spread do
    # Reuse existing escalation helpers to produce all four derived escalation states
    # checkout_webhook_failures → :manual_trigger_requested (investigating state)
    checkout_webhook_failures()
    # stalled_async_executor → :suppressed (open state, with action item)
    stalled_async_executor()
    # signup_email_resolved → :recently_executed (resolved state)
    signup_email_resolved()
    # retry_storm → :recently_short_circuited (open state)
    retry_storm()

    # Add one bare open incident for :idle escalation status (no escalation key in runbook_data)
    {:ok, idle_incident} =
      Parapet.Evidence.create_incident(%{
        title: "Mixed status idle escalation: no escalation configured",
        description: "Open incident with no escalation policy — renders idle escalation status",
        state: "open",
        correlation_key: "mixed-status-idle-escalation-baseline"
      })

    # Create one open ActionItem per kind (5 total) to populate all kinds on the Actions page
    action_item_kinds = [
      "exact_follow_up",
      "suppressed_delivery",
      "stalled_workflow",
      "orphaned_callback",
      "dead_letter"
    ]

    Enum.each(action_item_kinds, fn kind ->
      {:ok, _} =
        %Parapet.Spine.ActionItem{}
        |> Parapet.Spine.ActionItem.changeset(%{
          title: "mixed_status_#{kind}_open_action_item",
          integration: "demo",
          external_id: "ext-mixed-#{kind}",
          kind: kind,
          state: "open",
          incident_id: idle_incident.id
        })
        |> DemoApp.Repo.insert()
    end)
  end
end
