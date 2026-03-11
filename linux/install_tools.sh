#!/bin/bash

echo "🚀 Installing common programming languages..."

# Detect package manager
if command -v apt >/dev/null 2>&1; then
    PKG="apt"
    UPDATE="sudo apt update"
    INSTALL="sudo apt install -y"
elif command -v dnf >/dev/null 2>&1; then
    PKG="dnf"
    UPDATE="sudo dnf check-update"
    INSTALL="sudo dnf install -y"
elif command -v pacman >/dev/null 2>&1; then
    PKG="pacman"
    UPDATE="sudo pacman -Sy"
    INSTALL="sudo pacman -S --noconfirm"
elif command -v brew >/dev/null 2>&1; then
    PKG="brew"
    UPDATE="brew update"
    INSTALL="brew install"
else
    echo "❌ Unsupported package manager."
    exit 1
fi

echo "📦 Using package manager: $PKG"
$UPDATE

echo "⚙️ Installing languages..."

$INSTALL gcc
$INSTALL g++
$INSTALL default-jdk
$INSTALL rustc
$INSTALL golang
$INSTALL python3
$INSTALL nodejs
$INSTALL npm
$INSTALL ruby
$INSTALL php
$INSTALL bash

echo "📦 Installing TypeScript runtime..."
sudo npm install -g ts-node typescript

echo ""
echo "✅ Installation complete!"
echo "Installed tools:"
echo "gcc, g++, javac, java, rustc, go, python3, node, ts-node, bash, ruby, php"