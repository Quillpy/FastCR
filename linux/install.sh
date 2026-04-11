#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TARGET_DIR=""
if [[ -w "/usr/local/bin" ]]; then
    TARGET_DIR="/usr/local/bin"
else
    TARGET_DIR="$HOME/.local/bin"
    mkdir -p "$TARGET_DIR"
fi

gcc -O2 -o "${SCRIPT_DIR}/src/meminfo" "${SCRIPT_DIR}/src/meminfo.c"

cp "${SCRIPT_DIR}/cr.sh" "${TARGET_DIR}/cr"
chmod +x "${TARGET_DIR}/cr"
cp "${SCRIPT_DIR}/src/meminfo" "${TARGET_DIR}/meminfo"
chmod +x "${TARGET_DIR}/meminfo"

if [[ -d "${SCRIPT_DIR}/Templates" ]]; then
    TEMPLATE_TARGET="${TARGET_DIR}/Templates"
    mkdir -p "$TEMPLATE_TARGET"
    cp "${SCRIPT_DIR}/Templates/"* "$TEMPLATE_TARGET/"
fi

if [[ "$TARGET_DIR" != "/usr/local/bin" ]]; then
    if ! echo "$PATH" | grep -q "$TARGET_DIR"; then
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$HOME/.bashrc"
        echo "Added $TARGET_DIR to PATH in ~/.bashrc"
    fi
fi

echo "FastCR installed to ${TARGET_DIR}/cr"
echo "Run: cr solution.cpp"
