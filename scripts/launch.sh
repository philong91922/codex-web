#!/usr/bin/env bash
set -Eeuo pipefail

port=8214
arguments=("$@")
for ((index = 0; index < ${#arguments[@]}; index++)); do
  case "${arguments[index]}" in
    --port)
      port="${arguments[index + 1]:-}"
      index=$((index + 1))
      ;;
    --port=*) port="${arguments[index]#--port=}" ;;
  esac
done

[[ "$port" =~ ^[0-9]+$ ]] || {
  printf 'Invalid port: %s\n' "$port" >&2
  exit 1
}

url="http://127.0.0.1:$port"
bash scripts/run.sh "$@" &
server_pid=$!

cleanup() {
  kill "$server_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

open_browser() {
  case "$(uname -s)" in
    Darwin) open "$url" ;;
    MINGW*|MSYS*|CYGWIN*)
      CODEX_WEB_BROWSER_URL="$url" \
        powershell.exe -NoProfile -NonInteractive -Command 'Start-Process $env:CODEX_WEB_BROWSER_URL'
      ;;
    *) xdg-open "$url" >/dev/null 2>&1 ;;
  esac
}

for ((attempt = 0; attempt < 60; attempt++)); do
  if curl --silent --fail --output /dev/null "$url"; then
    open_browser
    break
  fi
  sleep 1
done

wait "$server_pid"
