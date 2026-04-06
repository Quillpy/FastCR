#!/usr/bin/env bash

cmd_new() {
    local file="$1"
    local ext="${file##*.}"

    [[ -f "$file" ]] && { echo "error: file already exists: $file"; exit 1; }

    case "$ext" in
        cpp|cc|cxx)
            cat > "$file" <<'EOF'
#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    return 0;
}
EOF
            ;;
        c)
            cat > "$file" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {

    return 0;
}
EOF
            ;;
        java)
            local classname="${file%.java}"
            classname="${classname##*/}"
            cat > "$file" <<EOF
import java.util.*;
import java.io.*;

public class $classname {
    public static void main(String[] args) throws IOException {
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));

    }
}
EOF
            ;;
        py)
            cat > "$file" <<'EOF'
import sys
input = sys.stdin.readline

def main():
    pass

main()
EOF
            ;;
        rs)
            cat > "$file" <<'EOF'
use std::io::{self, BufRead};

fn main() {
    let stdin = io::stdin();
    for line in stdin.lock().lines() {
        let _line = line.unwrap();
    }
}
EOF
            ;;
        go)
            cat > "$file" <<'EOF'
package main

import (
    "bufio"
    "fmt"
    "os"
)

var reader *bufio.Reader
var writer *bufio.Writer

func main() {
    reader = bufio.NewReader(os.Stdin)
    writer = bufio.NewWriter(os.Stdout)
    defer writer.Flush()

    _ = fmt.Fscan
}
EOF
            ;;
        kt)
            cat > "$file" <<'EOF'
import java.util.Scanner

fun main() {
    val sc = Scanner(System.`in`)
}
EOF
            ;;
        js)
            cat > "$file" <<'EOF'
const lines = require('fs').readFileSync('/dev/stdin', 'utf8').trim().split('\n');
let idx = 0;

function readline() { return lines[idx++]; }

EOF
            ;;
        rb)
            cat > "$file" <<'EOF'
EOF
            ;;
        hs)
            cat > "$file" <<'EOF'
import Data.List
import Data.Char

main :: IO ()
main = do
    contents <- getContents
    let ls = lines contents
    return ()
EOF
            ;;
        *)
            echo "error: no template for extension: .$ext"
            exit 1
            ;;
    esac

    echo "created: $file"
}

cmd_del() {
    local target="$1"

    if [[ "$target" == "*" ]]; then
        local count=0
        for bin in .fastcr_*; do
            [[ -f "$bin" ]] && rm -f "$bin" && (( count++ ))
        done
        echo "deleted $count binaries"
    else
        local base="${target%.*}"
        local dir
        dir="$(dirname "$target")"
        local bin="$dir/.fastcr_${base##*/}"
        if [[ -f "$bin" ]]; then
            rm -f "$bin"
            echo "deleted: $bin"
        else
            echo "no binary found for: $target"
        fi
    fi
}

cmd_copy() {
    local file="$1"
    if command -v xclip &>/dev/null; then
        xclip -selection clipboard < "$file"
    elif command -v xsel &>/dev/null; then
        xsel --clipboard --input < "$file"
    elif command -v wl-copy &>/dev/null; then
        wl-copy < "$file"
    else
        echo "error: no clipboard tool found (install xclip, xsel, or wl-clipboard)"
        exit 1
    fi
    echo "copied: $file"
}

cmd_watch() {
    if ! command -v inotifywait &>/dev/null; then
        echo "error: inotify-tools not installed"
        echo "  sudo apt install inotify-tools"
        exit 1
    fi

    echo "watching: $FILE"
    echo "press Ctrl+C to stop"
    echo ""

    run_file

    while inotifywait -e close_write "$FILE" -q; do
        echo ""
        echo "--- changed: $(date '+%H:%M:%S') ---"
        detect_lang "$FILE"
        compile_file && run_file
    done
}

cmd_show_stats() {
    if [[ ! -f "$STATS_FILE" ]]; then
        echo "no cached stats found"
        exit 1
    fi
    cat "$STATS_FILE"
}
