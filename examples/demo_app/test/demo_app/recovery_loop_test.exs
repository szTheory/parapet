defmodule DemoApp.RecoveryLoopTest do
  use DemoAppWeb.ConnCase

  @moduletag :smoke

  setup do
    # Ensure the runbook module is loaded so function_exported?/3 and
    # String.to_existing_atom/1 work correctly for :retry_item step lookup.
    Code.ensure_loaded!(DemoApp.Runbooks.StalledExecutor)

    {:ok, incident} =
      Parapet.Evidence.create_incident(%{
        title: "Stalled executor demo",
        state: "open",
        correlation_key: "stalled-executor-ci-#{System.unique_integer([:positive])}",
        runbook_data: %{
          "title" => "Stalled Executor Recovery",
          "module" => to_string(DemoApp.Runbooks.StalledExecutor),
          # Inline "steps" drive the operator UI render (WorkbenchContract.derive/3);
          # "module" drives Preview/Confirm execution. Step ids must match the module.
          "steps" => [
            %{
              "id" => "investigate_logs",
              "label" => "Check Worker Logs",
              "description" => "Verify if the worker crashed or is deadlocked.",
              "type" => "manual",
              "kind" => "guidance",
              "preview_only" => true
            },
            %{
              "id" => "retry_item",
              "label" => "Retry Item",
              "description" => "Force the async item to be retried.",
              "type" => "mitigation",
              "kind" => "capability",
              "capability" => "retry_async_item",
              "target_kind" => "async_item",
              "requires_preview" => true
            },
            %{
              "id" => "verify_recovery",
              "label" => "Verify Recovery",
              "description" => "Confirm the item completed after the retry.",
              "type" => "manual",
              "kind" => "guidance",
              "preview_only" => true
            }
          ]
        }
      })

    {:ok, _action_item} =
      DemoApp.Repo.insert(%Parapet.Spine.ActionItem{
        id: Ecto.UUID.generate(),
        title: "async_job_#{System.unique_integer([:positive])}",
        integration: "demo",
        external_id: "ext-#{System.unique_integer([:positive])}",
        kind: "stalled_workflow",
        state: "open",
        incident_id: incident.id
      })

    %{incident: incident}
  end

  # --- Scenario 1: Happy path ---
  test "confirm executes capability and writes TimelineEntry + ToolAudit", %{incident: incident} do
    preview_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI happy-path preview",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    {:ok, preview_result} =
      Parapet.Operator.preview_runbook_step(incident, :retry_item, preview_payload)

    token = preview_result.preview["preview_token"]

    confirm_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI happy-path confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    assert {:ok, _} =
             Parapet.Operator.confirm_runbook_step(incident, :retry_item, token, confirm_payload)

    import Ecto.Query

    assert DemoApp.Repo.exists?(
             from t in Parapet.Spine.TimelineEntry,
               where: t.incident_id == ^incident.id and t.type == "recovery_confirmed"
           )

    assert DemoApp.Repo.exists?(
             from a in Parapet.Spine.ToolAudit,
               where: a.tool_name == "operator_confirm_recovery"
           )
  end

  # --- Scenario 2: Expired preview ---
  test "expired preview returns {:short_circuited, :preview_expired}", %{incident: incident} do
    preview_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI expiry preview",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    {:ok, preview_result} =
      Parapet.Operator.preview_runbook_step(incident, :retry_item, preview_payload)

    token = preview_result.preview["preview_token"]

    # Age the preview entry's expires_at to 10 minutes in the past
    import Ecto.Query

    past_dt = DateTime.utc_now() |> DateTime.add(-600, :second) |> DateTime.to_iso8601()
    past_json = %{"expires_at" => past_dt}

    {1, _} =
      DemoApp.Repo.update_all(
        from(t in Parapet.Spine.TimelineEntry,
          where: t.incident_id == ^incident.id and t.type == "recovery_preview",
          update: [set: [payload: fragment("payload || ?::jsonb", ^past_json)]]
        ),
        []
      )

    confirm_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI expiry confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    assert {:short_circuited, :preview_expired} =
             Parapet.Operator.confirm_runbook_step(incident, :retry_item, token, confirm_payload)
  end

  # --- Scenario 3: Resolved mid-flow ---
  test "resolved incident returns {:short_circuited, :incident_resolved}", %{incident: incident} do
    preview_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI resolved preview",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    {:ok, preview_result} =
      Parapet.Operator.preview_runbook_step(incident, :retry_item, preview_payload)

    token = preview_result.preview["preview_token"]

    import Ecto.Query

    DemoApp.Repo.update_all(
      from(i in Parapet.Spine.Incident, where: i.id == ^incident.id),
      set: [state: "resolved"]
    )

    confirm_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI resolved confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    assert {:short_circuited, :incident_resolved} =
             Parapet.Operator.confirm_runbook_step(incident, :retry_item, token, confirm_payload)
  end

  # --- Scenario 4: Claim conflict (sequential) ---
  test "sequential second confirm returns {:conflicted, _}", %{incident: incident} do
    preview_payload = %Parapet.Operator.ActionPayload{
      actor: "ci_operator",
      reason: "CI conflict preview",
      correlation_id: Ecto.UUID.generate(),
      action_type: :preview_mitigation
    }

    {:ok, preview_result} =
      Parapet.Operator.preview_runbook_step(incident, :retry_item, preview_payload)

    token = preview_result.preview["preview_token"]

    confirm_payload_1 = %Parapet.Operator.ActionPayload{
      actor: "operator_a",
      reason: "First confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    confirm_payload_2 = %Parapet.Operator.ActionPayload{
      actor: "operator_b",
      reason: "Second confirm",
      correlation_id: Ecto.UUID.generate(),
      action_type: :execute_mitigation,
      idempotency_key: Ecto.UUID.generate()
    }

    result_1 =
      Parapet.Operator.confirm_runbook_step(incident, :retry_item, token, confirm_payload_1)

    result_2 =
      Parapet.Operator.confirm_runbook_step(incident, :retry_item, token, confirm_payload_2)

    assert {:ok, _} = result_1
    assert {:conflicted, _claim_id} = result_2
  end

  # --- Scenario 5: Browser Preview -> Confirm through the operator LiveView ---
  # Drives the real LiveView (mount + handle_event + rendered DOM) headlessly,
  # so the operator click-through is contract-tested in CI rather than left as a
  # manual UAT item. No browser/Wallaby — Phoenix.LiveViewTest renders and clicks
  # the same buttons an operator would.
  test "operator drives Preview -> Confirm through the LiveView and the capability executes",
       %{conn: conn, incident: incident} do
    {:ok, view, _html} = live(conn, "/parapet/#{incident.id}")

    # The runbook card renders a Preview button for the capability mitigate step.
    preview_button = ~s{button[phx-click="preview_mitigation"][phx-value-step="retry_item"]}
    assert has_element?(view, preview_button)

    # Click Preview -> the preview panel renders with the capability's preview map.
    preview_html = view |> element(preview_button) |> render_click()
    assert preview_html =~ "Recovery Preview"
    assert preview_html =~ "Retrying without root cause analysis"
    assert has_element?(view, ~s{button[phx-click="confirm_mitigation"]})

    # Click Confirm -> LiveViewTest sends the rendered phx-value-token; the
    # capability executes against demo DB state.
    confirm_html = view |> element(~s{button[phx-click="confirm_mitigation"]}) |> render_click()

    # UI: the new recovery_confirmed entry renders in the incident timeline.
    assert confirm_html =~ "Recovery confirmed"

    # DB: the capability ran — TimelineEntry + ToolAudit written, ActionItem resolved.
    import Ecto.Query

    assert DemoApp.Repo.exists?(
             from t in Parapet.Spine.TimelineEntry,
               where: t.incident_id == ^incident.id and t.type == "recovery_confirmed"
           )

    assert DemoApp.Repo.exists?(
             from a in Parapet.Spine.ToolAudit,
               where: a.tool_name == "operator_confirm_recovery"
           )

    assert DemoApp.Repo.get_by(Parapet.Spine.ActionItem, incident_id: incident.id).state ==
             "resolved"
  end
end
