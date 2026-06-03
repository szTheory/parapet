defmodule Parapet.OperatorUIDemoContractTest do
  use ExUnit.Case, async: true

  @seed_path "examples/demo_app/priv/repo/seeds.exs"
  @router_path "examples/demo_app/lib/demo_app_web/router.ex"
  @smoke_path "examples/demo_app/test/demo_app/operator_smoke_test.exs"
  @browser_script_path "examples/demo_app/scripts/capture_operator_ui_screenshots.sh"

  test "demo seeds express the Phase 36 operator state matrix" do
    content = File.read!(@seed_path)

    for marker <- [
          "Incident 1: OPEN",
          "Incident 2: INVESTIGATING",
          "Incident 3: RESOLVED",
          "Incident 4: OPEN",
          "Incident 5: OPEN",
          "external_link",
          "escalation_trigger_requested",
          "retrospective",
          "requires_preview",
          "escalation_suppressed",
          "guidance-only retry storm",
          "Parapet.Spine.ActionItem",
          "Parapet.Evidence.log_tool_audit"
        ] do
      assert content =~ marker
    end

    assert content =~ "recovery-previewable"
    assert content =~ "guidance-only"
    assert content =~ "warning"
    assert content =~ "action-item"
    assert content =~ "escalation"
    assert content =~ "audit"
    assert content =~ "external-link"
    assert content =~ "retrospective"
  end

  test "demo routes mirror the generated operator UI route shape" do
    router = File.read!(@router_path)
    smoke = File.read!(@smoke_path)

    for route <- [
          ~S|live("/parapet", DemoAppWeb.Parapet.OperatorLive, :index)|,
          ~S|live("/parapet/actions", DemoAppWeb.Parapet.OperatorLive, :actions)|,
          ~S|live("/parapet/history", DemoAppWeb.Parapet.OperatorLive, :history)|,
          ~S|live("/parapet/incidents/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)|,
          ~S|live("/parapet/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show)|
        ] do
      assert router =~ route
    end

    for smoke_path <- [
          ~S|GET /parapet returns 200|,
          ~S|GET /parapet/actions returns 200|,
          ~S|GET /parapet/history returns 200|,
          ~S|preferred and compatibility incident detail routes render|
        ] do
      assert smoke =~ smoke_path
    end
  end

  test "browser screenshot verification captures desktop and mobile operator paths" do
    script = File.read!(@browser_script_path)

    for path <- [
          "/parapet",
          "/parapet/actions",
          "/parapet/history",
          "/parapet/incidents/"
        ] do
      assert script =~ path
    end

    assert script =~ "1440,1100"
    assert script =~ "390,844"
    assert script =~ "operator-response-desktop"
    assert script =~ "operator-detail-mobile"
    assert script =~ "chromium"
  end
end
