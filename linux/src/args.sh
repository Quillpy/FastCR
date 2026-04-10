#!/usr/bin/env bash

FILE=""
EXTRA_ARGS=()
OPT_INPUT=""
OPT_OUTPUT=""
OPT_EXPECTED=""
OPT_DEBUG=""
OPT_TIMELIMIT=2000
OPT_MEMLIMIT=256
OPT_VERBOSE=""
OPT_SHOW_STATS=""
OPT_NEW=""
OPT_WATCH=""
OPT_COPY=""
OPT_DEL=""
OPT_BATCH=""
OPT_HELP=""

print_usage() {
    cat <<'EOF'
FastCR — Compile & Run competitive programming solutions

Usage: cr [flags] <file>

Flags:
  --t             Feed input.txt as stdin
  --i <file>      Feed a custom file as stdin
  --o <file>      Write output to a file
  --e <file>      Compare output against expected, show diff
  --b             Batch test all test*.txt files
  --d             Debug build with sanitizers and warnings
  --tl <ms>       Time limit in milliseconds (default: 2000)
  --ml <MB>       Memory limit in MB (default: 256)
  --v             Verbose — print compile command and warnings
  --tm            Show cached stats from last run
  --n <file>      Create a new file with boilerplate
  --w             Watch mode — rerun on every file save
  --cp            Copy source file to clipboard
  --del <file>    Delete compiled binary for a file
  --del *         Delete all compiled binaries in current directory
  -h, --help      Show this help message

Supported languages: C, C++, Java, Python, Rust, Go, Kotlin, JavaScript, Ruby, Haskell, TypeScript, Shell, PHP

Examples:
  cr solution.cpp
  cr --t solution.cpp
  cr --i in.txt --e expected.txt solution.cpp
  cr --b --tl 1000 solution.cpp
  cr --d solution.cpp
  cr --n problem_b.cpp
  cr --w --t solution.py
  cr --del solution.cpp
  cr --del *
  cr --cp solution.cpp
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                OPT_HELP=1
                shift
                ;;
            --t)
                OPT_INPUT="input.txt"
                shift
                ;;
            --i)
                OPT_INPUT="$2"
                shift 2
                ;;
            --o)
                OPT_OUTPUT="$2"
                shift 2
                ;;
            --e)
                OPT_EXPECTED="$2"
                shift 2
                ;;
            --d)
                OPT_DEBUG=1
                shift
                ;;
            --tl)
                OPT_TIMELIMIT="$2"
                shift 2
                ;;
            --ml)
                OPT_MEMLIMIT="$2"
                shift 2
                ;;
            --v)
                OPT_VERBOSE=1
                shift
                ;;
            --tm)
                OPT_SHOW_STATS=1
                shift
                ;;
            --n)
                OPT_NEW="$2"
                shift 2
                ;;
            --w)
                OPT_WATCH=1
                shift
                ;;
            --cp)
                OPT_COPY=1
                shift
                ;;
            --del)
                shift
                if [[ $# -gt 0 && "$1" != -* ]]; then
                    OPT_DEL="$1"
                    shift
                else
                    OPT_DEL="*"
                fi
                ;;
            --b)
                OPT_BATCH=1
                shift
                ;;
            -*)
                echo "unknown flag: $1"
                exit 1
                ;;
            *)
                if [[ -z "$FILE" ]]; then
                    FILE="$1"
                else
                    EXTRA_ARGS+=("$1")
                fi
                shift
                ;;
        esac
    done
}
