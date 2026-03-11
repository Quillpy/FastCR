#!/usr/bin/env bash
set -euo pipefail

# Ensure we run from the repo root
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
    (( PASS++ ))
  else
    echo "[FAIL] $name${msg:+ - $msg}"
    (( FAIL++ ))
  fi
  (( TOTAL++ ))
}

# Test: cr --help prints usage and exits 0
 test_cr_help() {
  set +e
  local out
  out="$(bash "$ROOT_DIR/linux/cr" --help 2>/dev/null)"
  local code=$?
  set -e
  if [[ $code -ne 0 ]]; then
    print_result "cr --help exits 0" fail "exit=$code"
    return 1
  fi
  echo "$out" | grep -q "FastCR" && echo "$out" | grep -q "Usage"
  if [[ $? -eq 0 ]]; then
    print_result "cr --help shows usage" ok
  else
    print_result "cr --help shows usage" fail "missing expected output"
    return 1
  fi
 }

# Test: cr --del in empty dir finds no binaries and exits 0
 test_cr_del_no_binaries() {
  local tmp="$ROOT_DIR/tests/.tmp_del"
  rm -rf "$tmp" && mkdir -p "$tmp"
  pushd "$tmp" >/dev/null
  set +e
  local out
  out="$(bash "$ROOT_DIR/linux/cr" --del 2>/dev/null)"
  local code=$?
  set -e
  popd >/dev/null
  if [[ $code -ne 0 ]]; then
    print_result "cr --del exits 0 in empty dir" fail "exit=$code"
    return 1
  fi
  echo "$out" | grep -qi "No compiled binaries" && print_result "cr --del reports none found" ok || print_result "cr --del reports none found" fail
 }

main() {
  echo "Running FastCR tests..."
  echo ""
  test_cr_help || true
  test_cr_del_no_binaries || true
  echo ""
  echo "Summary: $PASS passed, $FAIL failed, $TOTAL total"
  # Exit non-zero if any failures
  if [[ $FAIL -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
