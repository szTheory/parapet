#!/usr/bin/env bash
set -euo pipefail

compose_cmd="${DOCKER_COMPOSE:-}"

if [[ -z "$compose_cmd" ]]; then
  if docker compose version >/dev/null 2>&1; then
    compose_cmd="docker compose"
  else
    compose_cmd="docker-compose"
  fi
fi

web_port_output="$($compose_cmd port web 4000 2>/dev/null || true)"

if [[ -z "$web_port_output" ]]; then
  echo "Demo URLs are not available yet. Start the stack with: make up" >&2
  exit 1
fi

web_host_port="${web_port_output##*:}"
base_url="http://127.0.0.1:${web_host_port}"
grafana_port_output="$($compose_cmd port grafana 3000 2>/dev/null || true)"
prometheus_port_output="$($compose_cmd port prometheus 9090 2>/dev/null || true)"
grafana_url=""
prometheus_url=""
grafana_dashboard_url=""

if [[ -n "$grafana_port_output" ]]; then
  grafana_host_port="${grafana_port_output##*:}"
  grafana_url="http://127.0.0.1:${grafana_host_port}"
  grafana_dashboard_url="${grafana_url}/d/parapet_demo/parapet-demo-operator-evidence?orgId=1&from=now-15m&to=now"
fi

if [[ -n "$prometheus_port_output" ]]; then
  prometheus_host_port="${prometheus_port_output##*:}"
  prometheus_url="http://127.0.0.1:${prometheus_host_port}"
fi
project_name="$($compose_cmd config --format json 2>/dev/null | sed -n 's/^[[:space:]]*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
grafana_user="$($compose_cmd config --format json 2>/dev/null | sed -n 's/.*"GF_SECURITY_ADMIN_USER=\([^"]*\)".*/\1/p' | head -n 1)"
grafana_password="$($compose_cmd config --format json 2>/dev/null | sed -n 's/.*"GF_SECURITY_ADMIN_PASSWORD=\([^"]*\)".*/\1/p' | head -n 1)"

if [[ -z "$project_name" ]]; then
  project_name="${COMPOSE_PROJECT_NAME:-unknown}"
fi

if [[ -z "$grafana_user" ]]; then
  grafana_user="${GRAFANA_ADMIN_USER:-admin}"
fi

if [[ -z "$grafana_password" ]]; then
  grafana_password="${GRAFANA_ADMIN_PASSWORD:-parapet}"
fi

ready_url="${base_url}/parapet"
ready="false"

for _ in $(seq 1 60); do
  if curl -fsS -o /dev/null "$ready_url" 2>/dev/null; then
    ready="true"
    break
  fi

  sleep 1
done

if [[ "$ready" != "true" ]]; then
  echo "Demo web port is mapped, but the Operator UI is not ready yet: ${ready_url}" >&2
  echo "Check logs with: COMPOSE_PROJECT_NAME=${project_name} ${compose_cmd} logs web" >&2
  exit 1
fi

if [[ -n "$grafana_port_output" ]]; then
  for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null "${grafana_url}/api/health" 2>/dev/null; then
      break
    fi

    sleep 1
  done
fi

if [[ -n "$prometheus_port_output" ]]; then
  for _ in $(seq 1 60); do
    if curl -fsS -o /dev/null "${prometheus_url}/-/ready" 2>/dev/null; then
      break
    fi

    sleep 1
  done
fi

cat <<EOF
Parapet demo is available:
  Operator UI: ${base_url}/parapet
  Actions:     ${base_url}/parapet/actions
  History:     ${base_url}/parapet/history
  Grafana:     ${grafana_dashboard_url:-not published}
  Prometheus:  ${prometheus_url:-not published}

Grafana login:
  ${grafana_user} / ${grafana_password}
  Anonymous viewer access is enabled for the local demo.

Smoke check:
  curl -f ${base_url}/parapet
EOF

if [[ -n "$grafana_url" ]]; then
  echo "  curl -f ${grafana_url}/api/health"
fi

if [[ -n "$prometheus_url" ]]; then
  echo "  curl -f ${prometheus_url}/-/ready"
fi

cat <<EOF

Compose project:
  ${project_name}

Stop:
  COMPOSE_PROJECT_NAME=${project_name} make down

Reset volumes:
  COMPOSE_PROJECT_NAME=${project_name} make reset
EOF
