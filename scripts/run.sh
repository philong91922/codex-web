#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/.bootstrap-tools"

if [[ ! -x "$TOOLS_DIR/node_modules/.bin/codex" ]]; then
  printf 'Codex CLI is not installed. Run bash scripts/bootstrap.sh first.\n' >&2
  exit 1
fi

if [[ ! -d "$PROJECT_ROOT/scratch/asar" || ! -f "$PROJECT_ROOT/dist/server/main.js" ]]; then
  printf 'codex-web is not built. Run bash scripts/bootstrap.sh first.\n' >&2
  exit 1
fi

export PATH="$TOOLS_DIR/node_modules/.bin:$PATH"
export CODEX_CLI_PATH="$TOOLS_DIR/node_modules/.bin/codex"
export NODE_ENV="${NODE_ENV:-development}"

cd "$PROJECT_ROOT"
exec npm run server -- "$@"
