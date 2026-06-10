#!/usr/bin/env bash

set -u

EXCALIDRAW_URL="${EXCALIDRAW_URL:-https://draw.deservin8.com}"
EXCALIDRAW_ROOM_URL="${EXCALIDRAW_ROOM_URL:-https://draw-room.deservin8.com}"
failures=0

ok() {
  printf 'OK: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

check_http() {
  local name="$1"
  local url="$2"
  local allow_client_error="$3"
  local code

  code="$(curl -sS -I -L -o /dev/null -w '%{http_code}' \
    --connect-timeout 10 --max-time 20 "$url")" || {
    fail "$name is unreachable: $url"
    return
  }

  if [[ "$code" -ge 200 && "$code" -lt 400 ]]; then
    ok "$name responded with HTTP $code: $url"
  elif [[ "$allow_client_error" == "yes" && "$code" -ge 400 && "$code" -lt 500 ]]; then
    ok "$name is reachable and responded with HTTP $code (acceptable for a backend root): $url"
  else
    fail "$name responded with HTTP $code: $url"
  fi
}

check_polling_handshake() {
  local url="${EXCALIDRAW_ROOM_URL%/}/socket.io/?EIO=4&transport=polling"
  local response

  response="$(curl -fsS --connect-timeout 10 --max-time 20 "$url")" || {
    fail "Socket.IO polling endpoint is unreachable: $url"
    return
  }

  if [[ "$response" == 0\{* && "$response" == *'"sid"'* ]]; then
    ok "Socket.IO polling endpoint returned a handshake: $url"
  else
    fail "Socket.IO polling endpoint did not return the expected handshake: $url"
  fi
}

if ! command -v curl >/dev/null 2>&1; then
  printf 'FAIL: curl is required but was not found.\n' >&2
  exit 1
fi

printf 'Checking Excalidraw deployment\n'
printf 'Frontend: %s\n' "$EXCALIDRAW_URL"
printf 'Room backend: %s\n\n' "$EXCALIDRAW_ROOM_URL"

check_http "Frontend" "$EXCALIDRAW_URL" "no"
check_http "Room backend" "$EXCALIDRAW_ROOM_URL" "yes"
check_polling_handshake

printf '\n'
if [[ "$failures" -gt 0 ]]; then
  printf 'FAIL: %d critical check(s) failed.\n' "$failures" >&2
  printf 'Manual two-browser live collaboration testing is still required.\n' >&2
  exit 1
fi

printf 'OK: all command-line deployment checks passed.\n'
printf 'Manual two-browser live collaboration testing is still required.\n'
