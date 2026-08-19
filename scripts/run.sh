#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/.bootstrap-tools"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    CODEX_CLI_PATH="$(find "$TOOLS_DIR/node_modules/@openai" -path '*/vendor/*/bin/codex.exe' -type f -print -quit)"
    [[ -n "$CODEX_CLI_PATH" ]] || {
      printf 'Codex for Windows is not installed. Run bash scripts/bootstrap.sh again.\n' >&2
      exit 1
    }
    CODEX_CLI_PATH="$(cygpath -w "$CODEX_CLI_PATH")"
    ;;
  *)
    CODEX_CLI_PATH="$TOOLS_DIR/node_modules/.bin/codex"
    [[ -x "$CODEX_CLI_PATH" ]] || {
      printf 'Codex CLI is not installed. Run bash scripts/bootstrap.sh first.\n' >&2
      exit 1
    }
    ;;
esac

if [[ ! -d "$PROJECT_ROOT/scratch/asar" || ! -f "$PROJECT_ROOT/dist/server/main.js" ]]; then
  printf 'codex-web is not built. Run bash scripts/bootstrap.sh first.\n' >&2
  exit 1
fi

export PATH="$TOOLS_DIR/node_modules/.bin:$PATH"
export CODEX_CLI_PATH
export NODE_ENV="${NODE_ENV:-development}"

cd "$PROJECT_ROOT"
exec npm run server -- "$@"
