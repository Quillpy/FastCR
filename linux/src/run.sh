#!/usr/bin/env bash

STATS_FILE="/tmp/fastcr_last_stats"
FASTCR_TMP=""

init_tmp() {
    FASTCR_TMP=$(mktemp /tmp/fastcr.XXXXXX)
}

cleanup_tmp() {
    rm -f "$FASTCR_TMP" 2>/dev/null
}

_ms_from_timelimit() {
    local tl="$OPT_TIMELIMIT"
    printf "%d.%03d" $(( tl / 1000 )) $(( tl % 1000 ))
}

_build_run_cmd() {
    local cmd="$RUN_CMD"
    if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
        cmd="$cmd"
        for arg in "${EXTRA_ARGS[@]}"; do
            cmd="$cmd \"$arg\""
        done
    fi
    echo "$cmd"
}

_run_once() {
    local input_file="$1"
    local capture_file="$2"
    local tl_sec
    tl_sec=$(_ms_from_timelimit)

    local exit_code elapsed_ms mem_mb
    mem_mb="?"

    local start_ns end_ns
    start_ns=$(date +%s%N)

    local run_cmd
    run_cmd=$(_build_run_cmd)

    if [[ -f /usr/bin/time ]]; then
        if [[ -n "$input_file" ]]; then
            /usr/bin/time -v timeout "$tl_sec" bash -c "$run_cmd" \
                < "$input_file" > "$capture_file" 2>"$FASTCR_TMP"
        else
            /usr/bin/time -v timeout "$tl_sec" bash -c "$run_cmd" \
                > "$capture_file" 2>"$FASTCR_TMP"
        fi
        exit_code=$?
        end_ns=$(date +%s%N)

        local raw_elapsed raw_mem
        raw_elapsed=$(grep "Elapsed (wall clock)" "$FASTCR_TMP" 2>/dev/null \
            | grep -oP '\d+:\d+\.\d+' | head -1)
        raw_mem=$(grep "Maximum resident" "$FASTCR_TMP" 2>/dev/null \
            | grep -oP '\d+' | tail -1)

        if [[ -n "$raw_elapsed" ]]; then
            local min sec_int sec_frac
            min=$(echo "$raw_elapsed" | cut -d: -f1)
            local sec_full
            sec_full=$(echo "$raw_elapsed" | cut -d: -f2)
            sec_int=${sec_full%.*}
            sec_frac=${sec_full#*.}
            sec_frac=${sec_frac:0:3}
            elapsed_ms=$(( (min * 60 + sec_int) * 1000 + 10#${sec_frac} ))
        else
            elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
        fi

        if [[ -n "$raw_mem" ]]; then
            mem_mb=$(( raw_mem / 1024 ))
        fi
    else
        if [[ -n "$input_file" ]]; then
            timeout "$tl_sec" bash -c "$run_cmd" < "$input_file" > "$capture_file"
        else
            timeout "$tl_sec" bash -c "$run_cmd" > "$capture_file"
        fi
        exit_code=$?
        end_ns=$(date +%s%N)
        elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
    fi

    echo "$exit_code $elapsed_ms $mem_mb"
}

run_file() {
    if [[ -n "$OPT_BATCH" ]]; then
        run_batch
        return
    fi

    local capture_file
    capture_file=$(mktemp)

    local result exit_code elapsed_ms mem_mb
    result=$(_run_once "$OPT_INPUT" "$capture_file")
    exit_code=$(echo "$result" | awk '{print $1}')
    elapsed_ms=$(echo "$result" | awk '{print $2}')
    mem_mb=$(echo "$result" | awk '{print $3}')

    if [[ $exit_code -eq 124 ]]; then
        echo ""
        echo "TLE  exceeded ${OPT_TIMELIMIT} ms"
        echo "${OPT_TIMELIMIT}+ ms  ? MB" > "$STATS_FILE"
        rm -f "$capture_file"
        cleanup_tmp
        return
    fi

    if [[ $exit_code -ne 0 ]]; then
        cat "$capture_file"
        echo ""
        echo "RTE  exit code $exit_code"
        echo "$elapsed_ms ms  $mem_mb MB" > "$STATS_FILE"
        rm -f "$capture_file"
        cleanup_tmp
        return
    fi

    if [[ -n "$OPT_OUTPUT" ]]; then
        cp "$capture_file" "$OPT_OUTPUT"
        echo "output saved to: $OPT_OUTPUT"
    else
        cat "$capture_file"
    fi

    if [[ -n "$OPT_EXPECTED" ]]; then
        if diff -q "$capture_file" "$OPT_EXPECTED" &>/dev/null; then
            echo ""
            echo "AC  ${elapsed_ms} ms  ${mem_mb} MB"
        else
            echo ""
            echo "--- diff (got vs expected) ---"
            diff "$capture_file" "$OPT_EXPECTED"
            echo ""
            echo "WA  ${elapsed_ms} ms  ${mem_mb} MB"
        fi
    else
        echo ""
        echo "${elapsed_ms} ms  ${mem_mb} MB"
    fi

    if [[ "$mem_mb" != "?" ]] && (( mem_mb > OPT_MEMLIMIT )); then
        echo "MLE  exceeded ${OPT_MEMLIMIT} MB"
    fi

    echo "${elapsed_ms} ms  ${mem_mb} MB" > "$STATS_FILE"
    rm -f "$capture_file"
    cleanup_tmp
}

run_batch() {
    local tests=()
    for f in test*.txt; do
        [[ -f "$f" ]] && tests+=("$f")
    done

    if [[ ${#tests[@]} -eq 0 ]]; then
        echo "no test files found (test*.txt)"
        return 1
    fi

    echo ""
    echo "Batch Tests"
    printf '%.0s-' {1..50}; echo

    local passed=0 failed=0

    for test_input in "${tests[@]}"; do
        local base="${test_input%.txt}"
        local expected=""
        [[ -f "${base}.out" ]] && expected="${base}.out"
        [[ -f "${base}.ans" ]] && expected="${base}.ans"

        local capture_file
        capture_file=$(mktemp)

        local result exit_code elapsed_ms mem_mb
        result=$(_run_once "$test_input" "$capture_file")
        exit_code=$(echo "$result" | awk '{print $1}')
        elapsed_ms=$(echo "$result" | awk '{print $2}')
        mem_mb=$(echo "$result" | awk '{print $3}')

        local verdict
        if [[ $exit_code -eq 124 ]]; then
            verdict="TLE"
            elapsed_ms="${OPT_TIMELIMIT}+"
            mem_mb="--"
            failed=$(( failed + 1 ))
        elif [[ $exit_code -ne 0 ]]; then
            verdict="RTE"
            failed=$(( failed + 1 ))
        elif [[ -n "$expected" ]]; then
            if diff -q "$capture_file" "$expected" &>/dev/null; then
                verdict="AC"
                passed=$(( passed + 1 ))
            else
                verdict="WA"
                failed=$(( failed + 1 ))
            fi
        else
            verdict="RAN"
            passed=$(( passed + 1 ))
        fi

        printf "  %-22s  %-4s  %6s ms  %s MB\n" \
            "$test_input" "$verdict" "$elapsed_ms" "$mem_mb"

        rm -f "$capture_file"
    done

    printf '%.0s-' {1..50}; echo
    echo "  Passed: $passed   Failed: $failed"
    echo ""

    cleanup_tmp
}
