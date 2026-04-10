#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CR_SRC="$SCRIPT_DIR/cr"

[[ -f "$CR_SRC" ]] || { echo "error: missing 'cr' script"; exit 1; }

if [[ -w "/usr/local/bin" ]]; then
    DEST="/usr/local/bin/cr"
    USE_SUDO=false
elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
    DEST="/usr/local/bin/cr"
    USE_SUDO=true
else
    DEST="$HOME/.local/bin/cr"
    mkdir -p "$HOME/.local/bin"
    USE_SUDO=false
fi

echo "Installing to $DEST"

if [[ "$USE_SUDO" == true ]]; then
    sudo cp "$CR_SRC" "$DEST"
    sudo chmod +x "$DEST"
else
    cp "$CR_SRC" "$DEST"
    chmod +x "$DEST"
fi

echo "Installed successfully"

if [[ "$DEST" == "$HOME/.local/bin/cr" ]]; then
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo "Add this to your shell config:"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
    fi
fi
