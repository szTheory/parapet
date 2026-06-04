defmodule Parapet.OperatorUIDemoContractTest do
  use ExUnit.Case, async: true

  @seed_path "examples/demo_app/priv/repo/seeds.exs"
  @seed_scenarios_path "examples/demo_app/priv/repo/demo_seed_scenarios.exs"
  @router_path "examples/demo_app/lib/demo_app_web/router.ex"
  @smoke_path "examples/demo_app/test/demo_app/operator_smoke_test.exs"
  @browser_script_path "examples/demo_app/scripts/capture_operator_ui_screenshots.sh"
  @entrypoint_path "examples/demo_app/entrypoint.sh"
  @compose_path "examples/demo_app/docker-compose.yml"
  @auto_compose_path "examples/demo_app/docker-compose.auto-port.yml"
  @env_example_path "examples/demo_app/.env.example"
  @auto_env_script_path "examples/demo_app/scripts/prepare_auto_env.sh"
  @url_script_path "examples/demo_app/scripts/print_docker_urls.sh"
  @prometheus_config_path "examples/demo_app/priv/observability/prometheus/prometheus.yml"
  @grafana_datasource_path "examples/demo_app/priv/observability/grafana/provisioning/datasources/prometheus.yml"
  @grafana_dashboard_path "examples/demo_app/priv/observability/grafana/dashboards/parapet_demo.json"

  test "demo seeds expose focused scenarios plus the full operator state matrix" do
    seed_entry = File.read!(@seed_path)
    scenarios = File.read!(@seed_scenarios_path)

    assert seed_entry =~ "PARAPET_DEMO_SCENARIO"
    assert seed_entry =~ ~S|System.get_env("PARAPET_DEMO_SCENARIO", "all")|

    for scenario <- ~w(response recovery escalation history all) do
      assert scenarios =~ ~s|seed("#{scenario}")|
    end

    for marker <- [
          "login_service_spike",
          "checkout_webhook_failures",
          "signup_email_resolved",
          "stalled_async_executor",
          "retry_storm",
          "external_link",
          "escalation_trigger_requested",
          "retrospective",
          "requires_preview",
          "escalation_suppressed",
          "Retry Storm Guidance",
          "Parapet.Spine.ActionItem",
          "Parapet.Evidence.log_tool_audit"
        ] do
      assert scenarios =~ marker
    end

    assert scenarios =~ ~S|raise ArgumentError|
    assert scenarios =~ "unknown PARAPET_DEMO_SCENARIO"
    assert scenarios =~ "grafana_dashboard_url()"
    assert scenarios =~ "PARAPET_DEMO_GRAFANA_URL"
    refute scenarios =~ "grafana.example.test"
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
    assert script =~ "operator-response-dark-desktop"
    assert script =~ "operator-detail-dark-desktop"
    assert script =~ "operator-response-dark-mobile"
    assert script =~ "parapet_theme"
    assert script =~ "chromium"
  end

  test "docker entrypoint builds assets before serving the operator UI" do
    entrypoint = File.read!(@entrypoint_path)

    assert entrypoint =~ "mix assets.build"

    assert :binary.match(entrypoint, "mix assets.build") <
             :binary.match(entrypoint, "exec mix phx.server")
  end

  test "demo compose starts local observability stack and prints credentials" do
    compose = File.read!(@compose_path)
    auto_compose = File.read!(@auto_compose_path)
    env_example = File.read!(@env_example_path)
    auto_env_script = File.read!(@auto_env_script_path)
    url_script = File.read!(@url_script_path)
    prometheus = File.read!(@prometheus_config_path)
    datasource = File.read!(@grafana_datasource_path)
    dashboard = File.read!(@grafana_dashboard_path)

    assert compose =~ "prom/prometheus"
    assert compose =~ "grafana/grafana"
    refute compose =~ "METRICS_PORT=9568"
    assert compose =~ "PARAPET_DEMO_GRAFANA_URL"
    assert compose =~ "GF_AUTH_ANONYMOUS_ENABLED=true"

    assert auto_compose =~ "services:"
    assert auto_compose =~ "web:"
    assert auto_compose =~ "prometheus:"
    assert auto_compose =~ "grafana:"
    assert auto_compose =~ ~S|127.0.0.1:${WEB_PORT}:4000|
    assert auto_compose =~ ~S|127.0.0.1:${PROMETHEUS_PORT}:9090|
    assert auto_compose =~ ~S|127.0.0.1:${GRAFANA_PORT}:3000|

    assert auto_env_script =~ ".docker/auto.env"
    assert auto_env_script =~ "PARAPET_DEMO_GRAFANA_URL=http://127.0.0.1:"
    assert auto_env_script =~ "choose_port 4100 4999"
    assert auto_env_script =~ "choose_port 5100 5999"
    assert auto_env_script =~ "choose_port 6100 6999"

    for env <- ~w(GRAFANA_PORT PROMETHEUS_PORT GRAFANA_ADMIN_USER GRAFANA_ADMIN_PASSWORD) do
      assert env_example =~ env
    end

    for env <- ~w(GRAFANA_ADMIN_USER GRAFANA_ADMIN_PASSWORD) do
      assert url_script =~ env
    end

    assert url_script =~ "port web 4000"
    assert url_script =~ "port grafana 3000"
    assert url_script =~ "port prometheus 9090"
    assert url_script =~ "not published"

    assert prometheus =~ "web:4000"
    assert prometheus =~ "/etc/prometheus/rules/parapet.yml"
    assert datasource =~ "url: http://prometheus:9090"
    assert datasource =~ "uid: Prometheus"
    assert dashboard =~ ~S|"uid": "parapet_demo"|
    assert dashboard =~ "parapet_http_request_count"
    assert dashboard =~ "parapet_http_request_duration_ms_bucket"
  end
end
