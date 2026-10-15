#!/bin/bash
set -eo pipefail
source "$(dirname "$0")/common.sh"
require_simulator

case "$1" in
  unit) TARGET=OpenMeteoTests ;;
  ui) TARGET=OpenMeteoUITests ;;
  *)
    echo "Usage: $0 unit | ui" >&2
    exit 64
    ;;
esac

RESULT_BUNDLE="$RESULTS_DIR/$1.xcresult"
LOG="$RESULTS_DIR/$1.log"
mkdir -p "$RESULTS_DIR"

run_tests() {
  rm -rf "$RESULT_BUNDLE"
  xcodebuild test-without-building \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:"$TARGET" \
    -parallel-testing-enabled NO \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_BUNDLE" \
    2>&1 | tee "$LOG" | beautify
}

status=0
run_tests || status=$?
if (( status != 0 )) && grep -q "Failed to install or launch the test runner" "$LOG"; then
  echo "${GITHUB_ACTIONS:+::warning::}$TARGET: test runner failed to launch; retrying once."
  status=0
  run_tests || status=$?
fi
exit "$status"
