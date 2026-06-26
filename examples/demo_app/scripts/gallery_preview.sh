#!/usr/bin/env bash
#
# gallery_preview.sh — zero-infra preview of the operator-UI component gallery.
#
# Boots the demo app in gallery-only mode (PARAPET_DEMO_GALLERY_ONLY=true, no
# database) on a free loopback port, so /parapet/_gallery can be viewed or
# screenshotted without Postgres, Docker, or any clash with other local stacks.
#
#   scripts/gallery_preview.sh           # serve: print URL, stay up until Ctrl-C
#   scripts/gallery_preview.sh --shot    # capture light/dark desktop+mobile PNGs, then exit
#
# Env overrides:
#   PORT        — force a specific port (default: first free port in 4750-4799)
#   CHROME_BIN  — path to a Chromium/Chrome binary (default: auto-detected)
#   SHOT_DIR    — screenshot output dir (default: examples/demo_app/tmp/gallery-preview)
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEMO_DIR="$ROOT_DIR/examples/demo_app"
SHOT_DIR="${SHOT_DIR:-$DEMO_DIR/tmp/gallery-preview}"
GALLERY_PATH="/parapet/_gallery"

MODE="serve"
if [[ "${1:-}" == "--shot" ]]; then MODE="shot"; fi

# --- pick a free loopback port (honor PORT if set) -------------------------
find_free_port() {
  local port
  for port in $(seq 4750 4799); do
    if ! (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
      echo "$port"
      return 0
    fi
    exec 3>&- 2>/dev/null || true
  done
  return 1
}

PORT="${PORT:-$(find_free_port || true)}"
if [[ -z "${PORT}" ]]; then
  echo "No free port found in 4750-4799. Set PORT=<n> to choose one." >&2
  exit 1
fi

BASE_URL="http://127.0.0.1:${PORT}"
LOG="$(mktemp -t parapet-gallery-XXXXXX.log)"

# --- boot the gallery-only server in its own process group -----------------
set -m
( cd "$DEMO_DIR" && PARAPET_DEMO_GALLERY_ONLY=true PORT="$PORT" MIX_ENV=dev mix phx.server ) >"$LOG" 2>&1 &
SERVER_PID=$!

cleanup() {
  kill -TERM "-${SERVER_PID}" 2>/dev/null || kill -TERM "${SERVER_PID}" 2>/dev/null || true
  wait "${SERVER_PID}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# --- wait until the gallery route answers -----------------------------------
echo "→ Starting gallery-only demo server on ${BASE_URL} (no database)…"
ready=""
for _ in $(seq 1 90); do
  if curl -fsS -o /dev/null "${BASE_URL}${GALLERY_PATH}"; then ready=1; break; fi
  if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
    echo "✗ Server exited before becoming ready. Last log lines:" >&2
    tail -n 40 "$LOG" >&2
    exit 1
  fi
  sleep 1
done

if [[ -z "$ready" ]]; then
  echo "✗ Gallery did not become ready within 90s. Last log lines:" >&2
  tail -n 40 "$LOG" >&2
  exit 1
fi

if [[ "$MODE" == "serve" ]]; then
  cat <<EOF

✓ Gallery is up (Ctrl-C to stop):

  Light : ${BASE_URL}${GALLERY_PATH}
  Dark  : ${BASE_URL}${GALLERY_PATH}?parapet_theme=dark

Server log: ${LOG}
EOF
  wait "${SERVER_PID}"
  exit 0
fi

# --- --shot mode: headless Chromium captures --------------------------------
if [[ -z "${CHROME_BIN:-}" ]]; then
  for candidate in "$(command -v chromium || true)" "$(command -v google-chrome || true)" "$(command -v chromium-browser || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]] && "$candidate" --version >/dev/null 2>&1; then
      CHROME_BIN="$candidate"; break
    fi
  done
fi
if [[ -z "${CHROME_BIN:-}" && -d "/Applications/Google Chrome.app" ]]; then
  CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fi
if [[ -z "${CHROME_BIN:-}" ]]; then
  echo "No Chromium-compatible browser found. Set CHROME_BIN to enable capture." >&2
  exit 1
fi

mkdir -p "$SHOT_DIR"

capture() {
  local name="$1" size="$2" theme="$3"
  "$CHROME_BIN" \
    --headless=new \
    --disable-gpu \
    --no-first-run \
    --no-default-browser-check \
    --hide-scrollbars \
    --window-size="$size" \
    --screenshot="$SHOT_DIR/$name.png" \
    "${BASE_URL}${GALLERY_PATH}?parapet_theme=${theme}" >/dev/null 2>&1
}

# Tall windows so the full scrolling gallery is captured in one frame.
capture "gallery-desktop-light" "1440,5200" "light"
capture "gallery-desktop-dark"  "1440,5200" "dark"
capture "gallery-mobile-light"  "414,7600"  "light"
capture "gallery-mobile-dark"   "414,7600"  "dark"

echo "✓ Captured gallery screenshots to: $SHOT_DIR"
ls -1 "$SHOT_DIR"/gallery-*.png
