#!/usr/bin/env bash
set -Eeuo pipefail

UI_ARCHIVE_URL="${CODEX_WEB_UI_ARCHIVE_URL:-https://github.com/philong91922/codex-web/releases/download/ui-latest/codex-web-ui.tar.gz}"
temporary_archive="$(mktemp)"

cleanup() {
  rm -f "$temporary_archive"
}
trap cleanup EXIT

rm -rf scratch/asar
curl --fail --location --retry 3 --output "$temporary_archive" "$UI_ARCHIVE_URL"
tar -xzf "$temporary_archive"

[[ -f scratch/asar/package.json ]] || {
  printf 'The downloaded UI archive does not contain scratch/asar/package.json.\n' >&2
  exit 1
}
