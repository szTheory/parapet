#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEMO_DIR="$ROOT_DIR/examples/demo_app"
OUTPUT_DIR="${1:-$ROOT_DIR/.planning/phases/36-demo-state-coverage-browser-verification/screenshots}"
BASE_URL="${PARAPET_DEMO_URL:-http://127.0.0.1:4000}"
CHROME_BIN="${CHROME_BIN:-}"

MANIFEST_MODE=false
[[ "${1:-}" == "--manifest" ]] && MANIFEST_MODE=true

# Shared capture list — single source of truth for both capture mode and --manifest mode.
# Format: name|size|path|theme
# Detail routes use :detail_id as a DB-free placeholder; capture mode substitutes the
# resolved $DETAIL_ID at dispatch time.
CAPTURES=(
  "operator-response-desktop|1440,1100|/parapet|light"
  "operator-actions-desktop|1440,1100|/parapet/actions|light"
  "operator-history-desktop|1440,1100|/parapet/history|light"
  "operator-detail-desktop|1440,1100|/parapet/incidents/:detail_id|light"
  "operator-response-dark-desktop|1440,1100|/parapet|dark"
  "operator-detail-dark-desktop|1440,1100|/parapet/incidents/:detail_id|dark"
  "operator-response-mobile|390,844|/parapet|light"
  "operator-actions-mobile|390,844|/parapet/actions|light"
  "operator-history-mobile|390,844|/parapet/history|light"
  "operator-detail-mobile|390,844|/parapet/incidents/:detail_id|light"
  "operator-response-dark-mobile|390,844|/parapet|dark"
  "gallery-desktop-light|1440,5200|/parapet/_gallery|light"
  "gallery-desktop-dark|1440,5200|/parapet/_gallery|dark"
  "gallery-mobile-light|414,7600|/parapet/_gallery|light"
  "gallery-mobile-dark|414,7600|/parapet/_gallery|dark"
)

if $MANIFEST_MODE; then
  echo "| name | route | viewport | theme | scenario |"
  echo "|---|---|---|---|---|"
  for entry in "${CAPTURES[@]}"; do
    IFS='|' read -r name size path theme <<< "$entry"
    echo "| $name | $path | ${size/,/×} | $theme | stress |"
  done
  echo ""
  echo "Total: ${#CAPTURES[@]} captures"
  exit 0
fi

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
  local theme="${4:-system}"
  local themed_path="$path"
  if [[ "$path" == *"?"* ]]; then
    themed_path="${path}&parapet_theme=${theme}"
  else
    themed_path="${path}?parapet_theme=${theme}"
  fi
  "$CHROME_BIN" \
    --headless=new \
    --disable-gpu \
    --no-first-run \
    --no-default-browser-check \
    --hide-scrollbars \
    --window-size="$size" \
    --screenshot="$OUTPUT_DIR/$name.png" \
    "$BASE_URL$themed_path" >/dev/null
}

# Dispatch loop — iterates the shared CAPTURES array.
# Detail routes have :detail_id substituted with the resolved $DETAIL_ID.
for entry in "${CAPTURES[@]}"; do
  IFS='|' read -r name size path theme <<< "$entry"
  path="${path/:detail_id/$DETAIL_ID}"
  capture "$name" "$size" "$path" "$theme"
done

ls -1 "$OUTPUT_DIR"/*.png
