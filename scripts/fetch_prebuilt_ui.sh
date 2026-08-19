#!/usr/bin/env bash
set -Eeuo pipefail

UI_ARCHIVE_URL="${CODEX_WEB_UI_ARCHIVE_URL:-https://github.com/philong91922/codex-web/releases/download/ui-latest/codex-web-ui.tar.gz}"
temporary_archive="$(mktemp)"

cleanup() {
  rm -f "$temporary_archive"
}
trap cleanup EXIT

if ! curl --fail --location --retry 3 --output "$temporary_archive" "$UI_ARCHIVE_URL"; then
  printf 'The prebuilt UI archive is unavailable; building it from the Codex Desktop archive instead.\n' >&2
  CODEX_WEB_PREPARE_FROM_DESKTOP=1 bash scripts/prepare
  exit 0
fi

tar -tzf "$temporary_archive" scratch/asar/package.json >/dev/null 2>&1 || {
  printf 'The downloaded UI archive does not contain scratch/asar/package.json.\n' >&2
  exit 1
}

rm -rf scratch/asar
tar -xzf "$temporary_archive"
