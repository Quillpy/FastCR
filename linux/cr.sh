#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MEMINFO="${SCRIPT_DIR}/meminfo"
DEFAULT_TL=2000
DEFAULT_ML=256

FILE=""
USE_INPUT=0
INPUT_FILE=""
OUTPUT_FILE=""
EXPECTED_FILE=""
BATCH=0
DEBUG=0
TL=""
ML=""
VERBOSE=0
TM=0
NEW_FILE=""
WATCH=0
CLIPBOARD=0
DEL_TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --t)  USE_INPUT=1; INPUT_FILE="input.txt"; shift ;;
        --i)  USE_INPUT=1; INPUT_FILE="$2"; shift 2 ;;
        --o)  OUTPUT_FILE="$2"; shift 2 ;;
        --e)  EXPECTED_FILE="$2"; shift 2 ;;
        --b)  BATCH=1; shift ;;
        --d)  DEBUG=1; shift ;;
        --tl) TL="$2"; shift 2 ;;
        --ml) ML="$2"; shift 2 ;;
        --v)  VERBOSE=1; shift ;;
        --tm) TM=1; shift ;;
        --n)  NEW_FILE="$2"; shift 2 ;;
        --w)  WATCH=1; shift ;;
        --cp) CLIPBOARD=1; shift ;;
        --del) DEL_TARGET="${2:-}"; shift; [[ -n "$DEL_TARGET" ]] && shift ;;
        -*)   echo "Unknown flag: $1" >&2; exit 1 ;;
        *)    FILE="$1"; shift ;;
    esac
done

TL="${TL:-$DEFAULT_TL}"
ML="${ML:-$DEFAULT_ML}"

get_ext() {
    local f="$1"
    local base="${f##*/}"
    echo "${base##*.}"
}

get_bin_name() {
    local f="$1"
    local base="${f##*/}"
    local name="${base%.*}"
    echo "./${name}"
}

detect_and_compile() {
    local src="$1"
    local ext
    ext="$(get_ext "$src")"
    local bin
    bin="$(get_bin_name "$src")"

    local compile_cmd=""
    local run_cmd=""
    local is_compiled=0

    case "$ext" in
        c)
            compile_cmd="gcc -O2 -o $bin $src"
            if [[ $DEBUG -eq 1 ]]; then
                compile_cmd="gcc -O0 -g -fsanitize=address,undefined -Wall -Wextra -o $bin $src"
            fi
            run_cmd="$bin"
            is_compiled=1
            ;;
        cpp|cc|cxx)
            compile_cmd="g++ -O2 -std=c++17 -o $bin $src"
            if [[ $DEBUG -eq 1 ]]; then
                compile_cmd="g++ -O0 -g -std=c++17 -fsanitize=address,undefined -Wall -Wextra -o $bin $src"
            fi
            run_cmd="$bin"
            is_compiled=1
            ;;
        java)
            local cls="${src%.*}"
            compile_cmd="javac $src"
            run_cmd="java -cp . $cls"
            is_compiled=1
            ;;
        py)
            run_cmd="python3 $src"
            if command -v pypy3 &>/dev/null; then
                run_cmd="pypy3 $src"
            fi
            ;;
        rs)
            compile_cmd="rustc -C opt-level=2 -o $bin $src"
            run_cmd="$bin"
            is_compiled=1
            ;;
        go)
            compile_cmd="go build -o $bin $src"
            run_cmd="$bin"
            is_compiled=1
            ;;
        kt)
            local cls="${src%.*}"
            compile_cmd="kotlinc $src -include-runtime -d ${cls}.jar"
            run_cmd="java -jar ${cls}.jar"
            is_compiled=1
            bin="${cls}.jar"
            ;;
        js)
            run_cmd="node $src"
            ;;
        rb)
            run_cmd="ruby $src"
            ;;
        hs)
            compile_cmd="ghc -O2 -o $bin $src"
            run_cmd="$bin"
            is_compiled=1
            ;;
        *)
            echo "Unsupported extension: .$ext" >&2
            exit 1
            ;;
    esac

    if [[ -n "$compile_cmd" && $is_compiled -eq 1 ]]; then
        if [[ $VERBOSE -eq 1 ]]; then
            echo "Compile: $compile_cmd" >&2
        fi
        if ! $compile_cmd 2>compile_warn.tmp; then
            cat compile_warn.tmp >&2
            rm -f compile_warn.tmp
            exit 1
        fi
        if [[ $VERBOSE -eq 1 && -s compile_warn.tmp ]]; then
            cat compile_warn.tmp >&2
        fi
        rm -f compile_warn.tmp
    fi

    echo "$run_cmd|$is_compiled"
}

run_program() {
    local run_cmd="$1"
    local stdin_file="${2:-}"
    local stdout_file="${3:-}"
    local stdout_dump="${4:-}"
    local stats_file="/tmp/fastcr_run_stats_$$.txt"
    local result_file="/tmp/fastcr_run_result_$$.txt"

    if [[ -n "$stdin_file" && -n "$stdout_file" ]]; then
        "$MEMINFO" "$TL" "$ML" $run_cmd <"$stdin_file" >"$stdout_file" 2>"$stats_file"
    elif [[ -n "$stdin_file" ]]; then
        "$MEMINFO" "$TL" "$ML" $run_cmd <"$stdin_file" >"$stdout_dump" 2>"$stats_file"
    elif [[ -n "$stdout_file" ]]; then
        "$MEMINFO" "$TL" "$ML" $run_cmd >"$stdout_file" 2>"$stats_file"
    else
        "$MEMINFO" "$TL" "$ML" $run_cmd >"$stdout_dump" 2>"$stats_file"
    fi

    local status="OK"
    local time_val="0"
    local mem_val="0"
    local exit_val="0"

    while IFS= read -r line; do
        case "$line" in
            STATUS:*)   status="${line#STATUS:}" ;;
            TIME:*)     time_val="${line#TIME:}" ;;
            MEM:*)      mem_val="${line#MEM:}" ;;
            EXIT:*)     exit_val="${line#EXIT:}" ;;
            SIGNAL:*)   status="RTE" ;;
        esac
    done < "$stats_file"

    rm -f "$stats_file"

    local verdict="RAN"
    if [[ "$status" == "TLE" ]]; then
        verdict="TLE"
    elif [[ "$status" == "RTE" ]]; then
        verdict="RTE"
    elif [[ "$exit_val" -ne 0 && "$exit_val" != "127" ]]; then
        verdict="RTE"
    fi

    local mem_mb="--"
    if [[ "$mem_val" != "0" ]]; then
        mem_mb="$(awk "BEGIN {printf \"%.1f\", $mem_val / 1024}")"
    fi

    echo "$verdict|$time_val|$mem_mb" > "$result_file"
}

show_tm() {
    if [[ -z "$FILE" ]]; then
        echo "No file specified for --tm"
        exit 1
    fi
    local stats_name=$(basename "$FILE" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/\..*//')
    local stats_file="/tmp/fastcr_stats_${stats_name}.txt"
    echo "Cached stats for $FILE:"
    cat "$stats_file" 2>/dev/null || echo "No cached data"
}

do_new_file() {
    local target="$NEW_FILE"
    if [[ -f "$target" ]]; then
        echo "File already exists: $target" >&2
        exit 1
    fi

    local ext
    ext="$(get_ext "$target")"
    local base="${target##*/}"
    local name="${base%.*}"

    case "$ext" in
        c)
            cat > "$target" << 'EOF'
#include <stdio.h>

int main() {
    return 0;
}
EOF
            ;;
        cpp|cc|cxx)
            cat > "$target" << 'EOF'
#include <bits/stdc++.h>
using namespace std;

void solve() {
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    solve();
    return 0;
}
EOF
            ;;
        py)
            cat > "$target" << 'EOF'
import sys
input = sys.stdin.readline

def solve():
    pass

if __name__ == "__main__":
    solve()
EOF
            ;;
        java)
            cat > "$target" << EOF
import java.util.*;
import java.io.*;

public class ${name} {
    public static void main(String[] args) {
        FastScanner sc = new FastScanner();
        solve(sc);
    }

    static void solve(FastScanner sc) {
    }

    static class FastScanner {
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        StringTokenizer st = new StringTokenizer("");

        String next() {
            while (!st.hasMoreTokens()) {
                try { st = new StringTokenizer(br.readLine()); }
                catch (IOException e) {}
            }
            return st.nextToken();
        }

        int nextInt() { return Integer.parseInt(next()); }
        long nextLong() { return Long.parseLong(next()); }
    }
}
EOF
            ;;
        rs)
            cat > "$target" << 'EOF'
use std::io;

fn main() {
    let mut input = String::new();
    io::stdin().read_line(&mut input).ok();
}
EOF
            ;;
        go)
            cat > "$target" << 'EOF'
package main

import (
    "bufio"
    "fmt"
    "os"
)

func main() {
    sc := bufio.NewScanner(os.Stdin)
    for sc.Scan() {
        fmt.Println(sc.Text())
    }
}
EOF
            ;;
        js)
            cat > "$target" << 'EOF'
const readline = require('readline');
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

rl.on('line', (line) => {
    console.log(line);
});
EOF
            ;;
        kt)
            cat > "$target" << 'EOF'
import java.util.*

fun main() {
    val sc = Scanner(System.`in`)
}
EOF
            ;;
        rb)
            cat > "$target" << 'EOF'
def solve
end

solve
EOF
            ;;
        hs)
            cat > "$target" << 'EOF'
main :: IO ()
main = do
    return ()
EOF
            ;;
        *)
            touch "$target"
            ;;
    esac

    echo "Created: $target"
}

do_clipboard() {
    local src="$1"
    if command -v xclip &>/dev/null; then
        xclip -selection clipboard < "$src"
    elif command -v xsel &>/dev/null; then
        xsel --clipboard --input < "$src"
    else
        echo "No clipboard tool found. Install xclip or xsel" >&2
        exit 1
    fi
    echo "Copied to clipboard: $src"
}

do_del() {
    local target="$1"
    if [[ "$target" == "*" ]]; then
        local count=0
        for f in ./*; do
            if [[ -f "$f" && -x "$f" && ! "$f" == *.sh && ! "$f" == *.py && ! "$f" == *.txt && ! "$f" == *.out ]]; then
                rm -f "$f"
                ((count++)) || true
            fi
        done
        rm -f ./*.class ./*.jar 2>/dev/null || true
        echo "Deleted $count compiled binaries"
    else
        local ext
        ext="$(get_ext "$target")"
        local bin
        bin="$(get_bin_name "$target")"

        local deleted=0
        if [[ -f "$bin" ]]; then
            rm -f "$bin"
            deleted=1
        fi

        local base="${target%.*}"
        if [[ "$ext" == "java" && -f "${base}.class" ]]; then
            rm -f "${base}".class 2>/dev/null
            deleted=1
        fi
        if [[ "$ext" == "kt" && -f "${base}.jar" ]]; then
            rm -f "${base}.jar" 2>/dev/null
            deleted=1
        fi

        if [[ $deleted -eq 1 ]]; then
            echo "Deleted: $bin"
        else
            echo "Nothing to delete for: $target"
        fi
    fi
}

do_watch() {
    local src="$1"
    if ! command -v inotifywait &>/dev/null; then
        echo "inotify-tools required. Install: sudo apt install inotify-tools" >&2
        exit 1
    fi

    echo "Watch mode on: $src (Ctrl+C to stop)"
    run_with_flags "$src"
    echo "---"

    while inotifywait -q -e modify,close_write,create "$src" &>/dev/null; do
        run_with_flags "$src"
        echo "---"
    done
}

run_with_flags() {
    local src="$1"
    local result
    result="$(detect_and_compile "$src")"
    local run_cmd="${result%%|*}"

    local stdin_file=""
    if [[ $USE_INPUT -eq 1 && -n "$INPUT_FILE" ]]; then
        if [[ ! -f "$INPUT_FILE" ]]; then
            echo "Input file not found: $INPUT_FILE" >&2
            return 1
        fi
        stdin_file="$INPUT_FILE"
    fi

    local stdout_file=""
    local tmp_output=""
    if [[ -n "$OUTPUT_FILE" ]]; then
        stdout_file="$OUTPUT_FILE"
    elif [[ -n "$EXPECTED_FILE" ]]; then
        tmp_output="/tmp/fastcr_out_$$.txt"
        stdout_file="$tmp_output"
    fi

    if [[ $BATCH -eq 1 ]]; then
        do_batch "$src" "$run_cmd"
        return
    fi

    local run_stdout="/tmp/fastcr_stdout_$$.txt"
    run_program "$run_cmd" "$stdin_file" "$stdout_file" "$run_stdout" >/dev/null
    local run_result=$?

    if [[ -s "$run_stdout" ]]; then
        cat "$run_stdout"
    fi
    rm -f "$run_stdout"

    local stats_result
    stats_result="$(cat /tmp/fastcr_run_result_$$.txt 2>/dev/null || echo "RAN|0|--")"
    rm -f /tmp/fastcr_run_result_$$.txt

    local verdict="${stats_result%%|*}"
    local rest="${stats_result#*|}"
    local time_val="${rest%%|*}"
    local mem_mb="${rest##*|}"

    if [[ -n "$EXPECTED_FILE" && -f "$EXPECTED_FILE" && -f "$tmp_output" ]]; then
        if diff -q "$EXPECTED_FILE" "$tmp_output" &>/dev/null; then
            verdict="AC"
        else
            verdict="WA"
            echo "Diff:"
            diff "$EXPECTED_FILE" "$tmp_output" || true
        fi
        printf "%-7s %s ms  %s MB\n" "$verdict" "$time_val" "$mem_mb"
        rm -f "$tmp_output"
    else
        printf "%-7s %s ms  %s MB\n" "$verdict" "$time_val" "$mem_mb"
    fi

    local stats_name=$(basename "$1" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/\..*//')
    echo "$verdict|$time_val|$mem_mb" > "/tmp/fastcr_stats_${stats_name}.txt"

    if [[ $WATCH -eq 1 ]]; then
        echo "---"
    fi
}

do_batch() {
    local src="$1"
    local run_cmd="$2"

    local test_files=()
    for f in test*.txt; do
        [[ -f "$f" ]] && test_files+=("$f")
    done

    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo "No test*.txt files found"
        return 1
    fi

    echo "Batch Tests"
    echo "--------------------------------------------------"

    local passed=0
    local failed=0

    for tf in "${test_files[@]}"; do
        local base="${tf%.txt}"
        local out_file="/tmp/fastcr_batch_${base}.txt"
        local expected="${base}.out"

        run_program "$run_cmd" "$tf" "$out_file" ""
        local run_result="$(cat /tmp/fastcr_run_result_$$.txt 2>/dev/null || echo "RAN|0|--")"
        rm -f /tmp/fastcr_run_result_$$.txt

        local verdict="${run_result%%|*}"
        local rest="${run_result#*|}"
        local time_val="${rest%%|*}"
        local mem_mb="${rest##*|}"

        if [[ "$verdict" == "OK" || "$verdict" == "RAN" ]]; then
            if [[ -f "$expected" ]]; then
                if diff -q "$expected" "$out_file" &>/dev/null; then
                    verdict="AC"
                    ((passed++)) || true
                else
                    verdict="WA"
                    ((failed++)) || true
                fi
            else
                verdict="RAN"
                ((passed++)) || true
            fi
        elif [[ "$verdict" == "TLE" ]]; then
            ((failed++)) || true
        elif [[ "$verdict" == "RTE" ]]; then
            ((failed++)) || true
        fi

        printf "  %-23s %-7s %s ms  %s MB\n" "$tf" "$verdict" "$time_val" "$mem_mb"
        rm -f "$out_file"
    done

    echo "--------------------------------------------------"
    echo "  Passed: $passed   Failed: $failed"
}

# Main logic
if [[ -n "$NEW_FILE" ]]; then
    do_new_file
    exit 0
fi

if [[ $CLIPBOARD -eq 1 && -n "$FILE" ]]; then
    do_clipboard "$FILE"
    exit 0
fi

if [[ -n "$DEL_TARGET" ]]; then
    do_del "$DEL_TARGET"
    exit 0
fi

if [[ $TM -eq 1 ]]; then
    show_tm
    exit 0
fi

if [[ -z "$FILE" ]]; then
    echo "Usage: cr [flags] <file>" >&2
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "File not found: $FILE" >&2
    exit 1
fi

if [[ $WATCH -eq 1 ]]; then
    do_watch "$FILE"
else
    run_with_flags "$FILE"
fi
