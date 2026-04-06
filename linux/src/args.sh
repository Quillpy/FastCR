#!/usr/bin/env bash

FILE=""
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

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
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
                OPT_DEL="${2:-*}"
                shift
                [[ "$OPT_DEL" != "*" ]] && shift
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
                FILE="$1"
                shift
                ;;
        esac
    done
}
