#!/usr/bin/env bash

set -euo pipefail

API_URL="https://api.nightlight.gg/v1/upload"
AUTH_TOKEN="DON'T EVEN TRY KIDDO"

SCREENSHOT_DIR="${HOME}/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

FMT="%Y%m%d%H%M%S"

TS=$(date +"$FMT")
FILE="${SCREENSHOT_DIR}/${TS}.png"

if command -v grimblast &>/dev/null; then
    # Активное окно
    grimblast save active "$FILE"
elif command -v grim &>/dev/null; then
    # Полный экран (Fullscreen)
    grim "$FILE"
else
    notify-send "❌ Screenshot" "grimblast/grim not found"
    exit 1
fi

resp=$(curl -s -w "\n%{http_code}" \
    -X POST "$API_URL" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -F "file=@${FILE}")

code=$(echo "$resp" | tail -1)
body=$(echo "$resp" | sed '$d')

if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
    url=$(echo "$body" | python3 -c "import sys,json;print(json.load(sys.stdin).get('data',{}).get('url',''))" 2>/dev/null || echo "")
    if [[ -n "$url" ]]; then
        echo "$url" | wl-copy 2>/dev/null || true
        notify-send "☁️ Uploaded!" "$url"
    else
        notify-send "☁️ Uploaded (no url field)" "$body"
    fi
else
    notify-send "❌ Upload failed" "HTTP $code"
    echo "Error: $body" >&2
    exit 1
fi
