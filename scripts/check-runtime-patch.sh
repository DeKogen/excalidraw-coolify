#!/usr/bin/env bash

set -u

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

if ! command -v docker >/dev/null 2>&1; then
  fail "docker is required but was not found."
fi

if ! docker info >/dev/null 2>&1; then
  fail "Docker daemon is unavailable or access is denied. Run this script where Docker access is available."
fi

if ! docker compose version >/dev/null 2>&1; then
  fail "Docker Compose v2 is required."
fi

if [[ -z "$(docker compose ps -q excalidraw 2>/dev/null)" ]]; then
  fail "Compose service 'excalidraw' is not running in the current project."
fi

printf 'Checking compiled JavaScript in the running excalidraw container...\n'

docker compose exec -T excalidraw sh -c '
  set -eu

  html_dir=/usr/share/nginx/html
  official_url=https://oss-collab.excalidraw.com
  target_url=${VITE_APP_WS_SERVER_URL:-}

  if [ -z "$target_url" ]; then
    printf "FAIL: VITE_APP_WS_SERVER_URL is empty in the container.\n" >&2
    exit 1
  fi

  if find "$html_dir" -type f -name "*.js" -exec grep -F -l "$official_url" {} \; | grep -q .; then
    printf "FAIL: compiled JavaScript still contains %s.\n" "$official_url" >&2
    exit 1
  fi

  if ! find "$html_dir" -type f -name "*.js" -exec grep -F -l "$target_url" {} \; | grep -q .; then
    printf "FAIL: compiled JavaScript does not contain VITE_APP_WS_SERVER_URL value: %s\n" "$target_url" >&2
    exit 1
  fi

  printf "OK: official collaboration URL is absent from compiled JavaScript.\n"
  printf "OK: compiled JavaScript contains VITE_APP_WS_SERVER_URL value: %s\n" "$target_url"
' || fail "runtime patch verification failed."

printf 'OK: runtime patch verification passed.\n'
