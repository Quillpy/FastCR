#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$ROOT_DIR"

PASS=0
FAIL=0
TOTAL=0

print_result() {
    local name="$1" status="$2" msg="${3:-}"
    if [[ "$status" == "ok" ]]; then
        echo "[PASS] $name"
        PASS=$(( PASS + 1 ))
    else
        echo "[FAIL] $name${msg:+ - $msg}"
        FAIL=$(( FAIL + 1 ))
    fi
    TOTAL=$(( TOTAL + 1 ))
}

test_cr_help() {
    set +e
    local out
    out="$(bash "$ROOT_DIR/linux/cr" --help 2>&1)"
    local code=$?
    set -e
    if [[ $code -ne 0 ]]; then
        print_result "cr --help exits 0" fail "exit=$code"
        return
    fi
    if echo "$out" | grep -q "FastCR" && echo "$out" | grep -q "Usage"; then
        print_result "cr --help shows usage" ok
    else
        print_result "cr --help shows usage" fail "missing expected output"
    fi
}

test_cr_del_no_binaries() {
    local tmp
    tmp=$(mktemp -d)
    pushd "$tmp" >/dev/null
    set +e
    local out
    out="$(bash "$ROOT_DIR/linux/cr" --del 2>&1)"
    local code=$?
    set -e
    popd >/dev/null
    rm -rf "$tmp"
    if [[ $code -ne 0 ]]; then
        print_result "cr --del exits 0 in empty dir" fail "exit=$code"
        return
    fi
    if echo "$out" | grep -qi "deleted 0 binaries"; then
        print_result "cr --del reports none found" ok
    else
        print_result "cr --del reports none found" fail "got: $out"
    fi
}

test_cr_new_file() {
    local tmp
    tmp=$(mktemp -d)
    local file="$tmp/test.cpp"
    set +e
    local out
    out="$(bash "$ROOT_DIR/linux/cr" --n "$file" 2>&1)"
    local code=$?
    local exists=0
    [[ -f "$file" ]] && exists=1
    set -e
    rm -rf "$tmp"
    if [[ $code -eq 0 ]] && [[ $exists -eq 1 ]]; then
        print_result "cr --n creates file" ok
    else
        print_result "cr --n creates file" fail
    fi
}

test_cr_unknown_flag() {
    set +e
    local out
    out="$(bash "$ROOT_DIR/linux/cr" --unknown 2>&1)"
    local code=$?
    set -e
    if [[ $code -ne 0 ]] && echo "$out" | grep -q "unknown flag"; then
        print_result "cr rejects unknown flags" ok
    else
        print_result "cr rejects unknown flags" fail
    fi
}

test_cr_missing_file() {
    set +e
    local out
    out="$(bash "$ROOT_DIR/linux/cr" nonexistent.cpp 2>&1)"
    local code=$?
    set -e
    if [[ $code -ne 0 ]] && echo "$out" | grep -q "file not found"; then
        print_result "cr reports missing file" ok
    else
        print_result "cr reports missing file" fail
    fi
}

test_cr_no_args() {
    set +e
    local out
    out="$(bash "$ROOT_DIR/linux/cr" 2>&1)"
    local code=$?
    set -e
    if [[ $code -ne 0 ]] && echo "$out" | grep -q "usage:"; then
        print_result "cr shows usage with no args" ok
    else
        print_result "cr shows usage with no args" fail
    fi
}

main() {
    echo "Running FastCR tests..."
    echo ""
    test_cr_help || true
    test_cr_del_no_binaries || true
    test_cr_new_file || true
    test_cr_unknown_flag || true
    test_cr_missing_file || true
    test_cr_no_args || true
    echo ""
    echo "Summary: $PASS passed, $FAIL failed, $TOTAL total"
    if [[ $FAIL -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
