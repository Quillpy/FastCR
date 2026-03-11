#!/usr/bin/env bash

#  FastCR Installer  –  Because life's too short to type
#                        "gcc -o main main.c && ./main" again.
#  https://github.com/Quillpy/Fastcc


set -euo pipefail
export LC_ALL=C LANG=C

# Colours & styles
R='\033[0;31m';  G='\033[0;32m';  Y='\033[1;33m'
C='\033[0;36m';  B='\033[0;34m';  M='\033[0;35m'
BOLD='\033[1m';  DIM='\033[2m';   RESET='\033[0m'

# Helpers
println()  { echo -e "$*"; }
info()     { println "  ${C}❯${RESET}  $*"; }
success()  { println "  ${G}✔${RESET}  $*"; }
warn()     { println "  ${Y}⚠${RESET}  $*"; }
error()    { println "\n  ${R}✘  ERROR:${RESET}  $*\n" >&2; exit 1; }
step()     { println "\n  ${B}›${RESET}  ${BOLD}$*${RESET}"; }
dim()      { println "  ${DIM}$*${RESET}"; }
blank()    { println ""; }

# Progress bar
progress() {
  local label="$1" duration="${2:-1}"
  local width=32
  printf "  ${C}❯${RESET}  %-28s  [" "$label"
  for (( i=0; i<width; i++ )); do
    printf "${G}━${RESET}"
    sleep "$(echo "scale=4; $duration / $width" | bc 2>/dev/null || echo 0.03)"
  done
  printf "]  ${G}done${RESET}\n"
}

# Dividers
div()      { println "  ${DIM}────────────────────────────────────────────────${RESET}"; }
bigdiv()   { println "  ${B}════════════════════════════════════════════════${RESET}"; }


#  BANNER

clear
blank
println "  ${B}${BOLD}███████╗ █████╗ ███████╗████████╗ ██████╗██████╗ ${RESET}"
println "  ${B}${BOLD}██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗${RESET}"
println "  ${B}${BOLD}█████╗  ███████║███████╗   ██║   ██║     ██████╔╝${RESET}"
println "  ${B}${BOLD}██╔══╝  ██╔══██║╚════██║   ██║   ██║     ██╔══██╗${RESET}"
println "  ${B}${BOLD}██║     ██║  ██║███████║   ██║   ╚██████╗██║  ██║${RESET}"
println "  ${B}${BOLD}╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝${RESET}"
blank
println "  ${BOLD}${C}Compile & Run in one command.${RESET}"
dim    "  Because 'gcc -Wall -Wextra -O2 -o main main.c && ./main'"
dim    "  is a war crime against your keyboard."
blank
bigdiv
blank

sleep 0.4


#  LOCATE SCRIPT DIR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CR_SRC="$SCRIPT_DIR/cr"

[[ -f "$CR_SRC" ]] || error "Can't find the 'cr' script.\nMake sure install.sh and cr are in the same folder.\n  Expected: ${BOLD}${CR_SRC}${RESET}"


#  STEP 1 — DETECT INSTALL DESTINATION

step "Step 1 / 4  —  Choosing install location"
blank

DEST=""
NEEDS_PATH_PATCH=false

if [[ -w "/usr/local/bin" ]]; then
  DEST="/usr/local/bin/cr"
  info "Found writable ${BOLD}/usr/local/bin${RESET} — going system-wide. Very fancy."
elif sudo -n true 2>/dev/null; then
  DEST="/usr/local/bin/cr"
  info "No direct write to /usr/local/bin but sudo works — using it."
  USE_SUDO=true
else
  DEST="$HOME/.local/bin/cr"
  mkdir -p "$HOME/.local/bin"
  info "No root? No problem. Installing to ${BOLD}~/.local/bin${RESET} like a humble peasant."
  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    NEEDS_PATH_PATCH=true
  fi
fi

USE_SUDO="${USE_SUDO:-false}"

success "Destination: ${BOLD}${DEST}${RESET}"
blank


#  STEP 2 — COPY & CHMOD

step "Step 2 / 4  —  Installing the 'cr' command"
blank

info "Copying script…"
sleep 0.3

if [[ "$USE_SUDO" == true ]]; then
  sudo cp "$CR_SRC" "$DEST" || error "sudo cp failed. That's suspicious. Try running the installer with sudo manually."
  sudo chmod +x "$DEST"     || error "chmod failed. Something is very wrong."
else
  cp "$CR_SRC" "$DEST"      || error "Copy failed. Check permissions on ${DEST}."
  chmod +x "$DEST"          || error "chmod failed. Please check your system."
fi

progress "Making it executable" 0.4
success  "Installed to ${BOLD}${DEST}${RESET}"
blank


#  STEP 3 — PATH SETUP (if needed)

step "Step 3 / 4  —  Checking PATH"
blank

if [[ "$NEEDS_PATH_PATCH" == true ]]; then
  warn "~/.local/bin is not in your PATH."
  info "I'll add it for you — you're welcome. 🎁"
  blank

  SHELL_RC=""
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
    SHELL_RC="$HOME/.zshrc"
  elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$SHELL" == */bash ]]; then
    SHELL_RC="$HOME/.bashrc"
  fi

  PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

  if [[ -n "$SHELL_RC" ]]; then
    if ! grep -qF "$PATH_LINE" "$SHELL_RC" 2>/dev/null; then
      {
        echo ""
        echo "# Added by FastCR installer"
        echo "$PATH_LINE"
      } >> "$SHELL_RC"
      success "Added to ${BOLD}${SHELL_RC}${RESET}"
      warn    "Run ${BOLD}source ${SHELL_RC}${RESET} or open a new terminal to activate."
    else
      success "PATH line already present in ${BOLD}${SHELL_RC}${RESET} — nothing to do."
    fi
  else
    warn "Couldn't detect your shell config. Add this manually:"
    blank
    println "    ${BOLD}export PATH=\"\$HOME/.local/bin:\$PATH\"${RESET}"
    blank
  fi
else
  success "PATH looks good — ${BOLD}${DEST%/cr}${RESET} is already in it. No homework for you."
fi
blank


#  STEP 4 — VERIFY INSTALLATION

step "Step 4 / 4  —  Verifying installation"
blank

progress "Running sanity check" 0.5

if [[ -x "$DEST" ]]; then
  success "Binary exists and is executable. ✓"
else
  error "Something went wrong — ${DEST} is not executable. Very spooky."
fi

# Quick smoke test: does cr respond to --help?
CR_HELP_OK=false
if "$DEST" --help &>/dev/null; then
  CR_HELP_OK=true
fi

if [[ "$CR_HELP_OK" == true ]]; then
  success "cr --help responds correctly. It's alive! 🧟"
else
  warn "cr --help didn't exit cleanly, but the file is in place. Might be fine."
fi
blank


#  DETECT AVAILABLE LANGUAGE RUNTIMES

bigdiv
blank
println "  ${BOLD}${M}Scanning for language runtimes on your system…${RESET}"
dim     "  (FastCR supports 11 languages — let's see how many you've got)"
blank

declare -A TOOLS=(
  ["gcc"]="C"
  ["g++"]="C++"
  ["javac"]="Java (compiler)"
  ["java"]="Java (runtime)"
  ["rustc"]="Rust"
  ["go"]="Go"
  ["python3"]="Python"
  ["node"]="JavaScript"
  ["ts-node"]="TypeScript"
  ["bash"]="Shell"
  ["ruby"]="Ruby"
  ["php"]="PHP"
)

FOUND=0
MISSING=0

for tool in "gcc" "g++" "javac" "java" "rustc" "go" "python3" "node" "ts-node" "bash" "ruby" "php"; do
  lang="${TOOLS[$tool]}"
  if command -v "$tool" &>/dev/null; then
    ver=$(${tool} --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "?")
    printf "  ${G}✔${RESET}  %-12s  ${DIM}%-22s${RESET}  ${DIM}v%s${RESET}\n" "$tool" "($lang)" "$ver"
    (( FOUND++ ))
  else
    printf "  ${Y}–${RESET}  %-12s  ${DIM}%-22s${RESET}  ${DIM}not installed${RESET}\n" "$tool" "($lang)"
    (( MISSING++ ))
  fi
  sleep 0.04
done

blank
if [[ $MISSING -eq 0 ]]; then
  success "You have ${BOLD}ALL 12${RESET} tools installed. You absolute legend. 🏆"
elif [[ $FOUND -ge 8 ]]; then
  success "Found ${BOLD}${FOUND}/12${RESET} tools. Pretty solid setup. The missing ones won't hurt unless you need them."
elif [[ $FOUND -ge 4 ]]; then
  info "Found ${BOLD}${FOUND}/12${RESET} tools. Respectable. Install more whenever you need them."
else
  warn "Found ${BOLD}${FOUND}/12${RESET} tools. Minimalist lifestyle — respect. Install tools as needed."
fi
blank


#  SUCCESS SUMMARY

bigdiv
blank
println "  ${G}${BOLD}🎉  FastCR is installed and ready to go!${RESET}"
blank
dim     "  Try these to get started:"
blank
println "  ${BOLD}  cr main.c${RESET}              ${DIM}# C${RESET}"
println "  ${BOLD}  cr app.cpp${RESET}             ${DIM}# C++${RESET}"
println "  ${BOLD}  cr script.py arg1${RESET}      ${DIM}# Python with arguments${RESET}"
println "  ${BOLD}  cr --keep server.rs${RESET}    ${DIM}# Rust, keep the binary${RESET}"
println "  ${BOLD}  cr --del${RESET}               ${DIM}# clean up all binaries${RESET}"
println "  ${BOLD}  cr --help${RESET}              ${DIM}# full reference + opens docs${RESET}"
blank
dim     "  Full documentation:  https://github.com/Quillpy/Fastcc"
blank
bigdiv
blank


#  OPTIONAL: DELETE CLONED REPO

# Offer cleanup of the cloned repo
println "  ${Y}${BOLD}One last thing…${RESET}"
blank
dim     "  The cloned repo is still sitting at:"
println "  ${BOLD}  ${SCRIPT_DIR}${RESET}"
blank
dim     "  FastCR is fully installed — you don't need this folder anymore."
dim     "  It's basically that Amazon box you've been stepping over for three weeks."
blank

read -rp "$(println "  ${Y}Throw it in the bin? [y/N]${RESET} ")" CLEANUP_ANS
blank

case "$CLEANUP_ANS" in
  y|Y|yes|YES)
    info "Alright, tidying up…"
    sleep 0.3

    # Prevent deleting dangerous paths
    if [[ "$SCRIPT_DIR" == "/" || "$SCRIPT_DIR" == "$HOME" ]]; then
      warn "Refusing to delete a critical directory: ${BOLD}${SCRIPT_DIR}${RESET}"
    elif [[ -x "$DEST" ]]; then
      rm -rf "$SCRIPT_DIR"
      success "Repo deleted. ${BOLD}${SCRIPT_DIR}${RESET} is gone. Clean desk, clean mind. 🧹"
    else
      warn "Hmm — can't confirm the install succeeded, so I'm NOT deleting the repo."
      warn "Check that ${BOLD}${DEST}${RESET} exists, then delete the folder manually if you want."
    fi
    ;;
  *)
    info "Fair enough. The repo stays. Marie Kondo would be disappointed, but we won't tell her."
    ;;
esac

blank
bigdiv
blank
println "  ${DIM}FastCR  •  https://github.com/Quillpy/Fastcc${RESET}"
blank