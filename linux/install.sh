#!/usr/bin/env bash

# FastCR Installer

set -euo pipefail
export LC_ALL=C LANG=C

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[0;34m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

println()  { echo -e "$*"; }
info()     { println "  ${C}❯${RESET}  $*"; }
success()  { println "  ${G}✔${RESET}  $*"; }
warn()     { println "  ${Y}⚠${RESET}  $*"; }
error()    { println "\n  ${R}✘ ERROR:${RESET} $*\n" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CR_SRC="$SCRIPT_DIR/cr"

[[ -f "$CR_SRC" ]] || error "Missing 'cr' script"

# Choose install location
if [[ -w "/usr/local/bin" ]]; then
  DEST="/usr/local/bin/cr"
elif sudo -n true 2>/dev/null; then
  DEST="/usr/local/bin/cr"
  USE_SUDO=true
else
  DEST="$HOME/.local/bin/cr"
  mkdir -p "$HOME/.local/bin"
fi

USE_SUDO="${USE_SUDO:-false}"

info "Installing to $DEST"

# Copy
if [[ "$USE_SUDO" == true ]]; then
  sudo cp "$CR_SRC" "$DEST"
  sudo chmod +x "$DEST"
else
  cp "$CR_SRC" "$DEST"
  chmod +x "$DEST"
fi

success "Installed successfully"

# PATH check
if [[ "$DEST" == "$HOME/.local/bin/cr" ]]; then
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "Add this to your shell config:"
    println 'export PATH="$HOME/.local/bin:$PATH"'
  fi
fi

success "Done. Try: cr --help"
