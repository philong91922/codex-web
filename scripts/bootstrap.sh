#!/usr/bin/env bash
# Bootstrap codex-web on macOS or Windows (run from Git Bash).
set -Eeuo pipefail

REPOSITORY_URL="${CODEX_WEB_REPOSITORY_URL:-https://github.com/philong91922/codex-web.git}"
INSTALL_DIR="${CODEX_WEB_INSTALL_DIR:-$HOME/codex-web}"
PORT="${CODEX_WEB_PORT:-8214}"
TOOLS_DIR_NAME=".bootstrap-tools"

usage() {
  cat <<'EOF'
Usage: bash bootstrap.sh [--dir DIRECTORY] [--port PORT] [--no-login] [--help]

Environment variables:
  CODEX_WEB_REPOSITORY_URL  Repository to clone or update.
  CODEX_WEB_INSTALL_DIR     Installation directory (default: ~/codex-web).
  CODEX_WEB_PORT            HTTP port (default: 8214).

On Windows, run this script from Git Bash. PowerShell and cmd.exe cannot run
POSIX shell scripts directly.
EOF
}

SKIP_LOGIN=false
while (($#)); do
  case "$1" in
    --dir) INSTALL_DIR="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    --no-login) SKIP_LOGIN=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
done

log() { printf '\n==> %s\n' "$*"; }
die() { printf '\nError: %s\n' "$*" >&2; exit 1; }
has_command() { command -v "$1" >/dev/null 2>&1; }

create_windows_shortcut() {
  local git_bash_path
  git_bash_path="$(cygpath -w "$(command -v bash)")"

  log "Creating Windows Desktop shortcut"
  CODEX_WEB_SHORTCUT_TARGET="$git_bash_path" \
    CODEX_WEB_SHORTCUT_ARGUMENTS='-lc "./scripts/run.sh"' \
    CODEX_WEB_SHORTCUT_WORKDIR="$(cygpath -w "$INSTALL_DIR")" \
    powershell.exe -NoProfile -NonInteractive -Command '
      $desktop = [Environment]::GetFolderPath("Desktop")
      $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $desktop "Codex Web.lnk"))
      $shortcut.TargetPath = $env:CODEX_WEB_SHORTCUT_TARGET
      $shortcut.Arguments = $env:CODEX_WEB_SHORTCUT_ARGUMENTS
      $shortcut.WorkingDirectory = $env:CODEX_WEB_SHORTCUT_WORKDIR
      $shortcut.IconLocation = $env:CODEX_WEB_SHORTCUT_TARGET
      $shortcut.Save()
    '
}

OS="$(uname -s)"
case "$OS" in
  Darwin) PLATFORM="macos" ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
  *) die "Unsupported platform '$OS'. Use macOS or Windows with Git Bash." ;;
esac

install_macos_prerequisites() {
  if ! has_command brew; then
    log "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi

  if ! has_command git; then
    log "Installing Git"
    brew install git
  fi

  if ! has_command node || [[ "$(node -p 'process.versions.node.split(".")[0]')" -lt 22 ]]; then
    log "Installing Node.js 22"
    brew install node@22
    if [[ -d "$(brew --prefix node@22)/bin" ]]; then
      export PATH="$(brew --prefix node@22)/bin:$PATH"
    fi
  fi
}

install_windows_prerequisites() {
  has_command git || die "Git Bash is required. Install Git for Windows, then re-run this script in Git Bash."

  if ! has_command node || [[ "$(node -p 'process.versions.node.split(".")[0]')" -lt 22 ]]; then
    has_command winget || die "Node.js 22+ is required. Install it with winget, then re-run this script."
    log "Installing Node.js LTS with winget"
    winget install --id OpenJS.NodeJS.LTS --exact --accept-package-agreements --accept-source-agreements
    export PATH="/c/Program Files/nodejs:$PATH"
    has_command node || die "Node.js was installed. Close and reopen Git Bash, then run this script again."
  fi
}

if [[ "$PLATFORM" == "macos" ]]; then
  install_macos_prerequisites
else
  install_windows_prerequisites
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
(( NODE_MAJOR >= 22 )) || die "Node.js 22 or newer is required; found $(node --version)."

if [[ -d "$INSTALL_DIR/.git" ]]; then
  log "Updating source code in $INSTALL_DIR"
  git -C "$INSTALL_DIR" diff --quiet || die "Installation directory has uncommitted changes: $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only
elif [[ -e "$INSTALL_DIR" ]]; then
  die "Installation directory exists but is not a Git checkout: $INSTALL_DIR"
else
  log "Cloning source code"
  git clone "$REPOSITORY_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"
TOOLS_DIR="$INSTALL_DIR/$TOOLS_DIR_NAME"
export PATH="$TOOLS_DIR/node_modules/.bin:$PATH"

log "Installing Codex CLI locally"
npm install --prefix "$TOOLS_DIR" --no-audit --no-fund --no-save @openai/codex@latest
CODEX_CLI_PATH="$(command -v codex)"

log "Installing dependencies and building codex-web"
# `npm ci` runs the project's prepare lifecycle, which downloads the matching
# Codex desktop assets and builds both the browser and server bundles.
npm ci --no-audit --no-fund

chmod +x scripts/run.sh

if [[ "$PLATFORM" == "windows" ]]; then
  create_windows_shortcut
fi

if [[ "$SKIP_LOGIN" != true ]]; then
  log "Signing in to Codex"
  "$CODEX_CLI_PATH" login --device-auth
fi

log "Starting codex-web at http://127.0.0.1:$PORT"
exec bash scripts/run.sh --host 127.0.0.1 --port "$PORT"
