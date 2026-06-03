#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEMO_DIR="$ROOT_DIR/examples/demo_app"
OUTPUT_DIR="${1:-$ROOT_DIR/.planning/phases/36-demo-state-coverage-browser-verification/screenshots}"
BASE_URL="${PARAPET_DEMO_URL:-http://127.0.0.1:4000}"
CHROME_BIN="${CHROME_BIN:-}"

if [[ -z "$CHROME_BIN" ]]; then
  for candidate in "$(command -v chromium || true)" "$(command -v google-chrome || true)" "$(command -v chromium-browser || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then
      CHROME_BIN="$candidate"
      break
    fi
  done
fi

if [[ -z "$CHROME_BIN" && -d "/Applications/Google Chrome.app" ]]; then
  CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fi

if [[ -z "$CHROME_BIN" ]]; then
  echo "No Chromium-compatible browser found. Set CHROME_BIN to enable screenshot capture." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

if ! curl -fsS "$BASE_URL/parapet" >/dev/null; then
  echo "Demo app is not reachable at $BASE_URL. Start it with: cd $DEMO_DIR && mix phx.server" >&2
  exit 1
fi

DETAIL_ID="$(
  cd "$DEMO_DIR"
  mix run -e 'alias DemoApp.Repo; alias Parapet.Spine.Incident; import Ecto.Query; query = from i in Incident, where: i.state in ["open", "investigating"], order_by: [desc: i.updated_at], limit: 1, select: i.id; IO.puts(Repo.one!(query))' 2>/dev/null \
    | grep -Eo '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
    | tail -n 1
)"

if [[ -z "$DETAIL_ID" ]]; then
  echo "Unable to select a demo incident id for detail screenshots." >&2
  exit 1
fi

capture() {
  local name="$1"
  local size="$2"
  local path="$3"
  "$CHROME_BIN" \
    --headless=new \
    --disable-gpu \
    --no-first-run \
    --no-default-browser-check \
    --hide-scrollbars \
    --window-size="$size" \
    --screenshot="$OUTPUT_DIR/$name.png" \
    "$BASE_URL$path" >/dev/null
}

capture "operator-response-desktop" "1440,1100" "/parapet"
capture "operator-actions-desktop" "1440,1100" "/parapet/actions"
capture "operator-history-desktop" "1440,1100" "/parapet/history"
capture "operator-detail-desktop" "1440,1100" "/parapet/incidents/$DETAIL_ID"

capture "operator-response-mobile" "390,844" "/parapet"
capture "operator-actions-mobile" "390,844" "/parapet/actions"
capture "operator-history-mobile" "390,844" "/parapet/history"
capture "operator-detail-mobile" "390,844" "/parapet/incidents/$DETAIL_ID"

ls -1 "$OUTPUT_DIR"/*.png
