#!/bin/bash
set -eo pipefail
source "$(dirname "$0")/common.sh"
require_simulator

case "$1" in
  unit) TARGETS=(OpenMeteoTests UtilsTests NetworkingTests) ;;
  ui) TARGETS=(OpenMeteoUITests) ;;
  snapshot) TARGETS=(DesignSystemTests) ;;
  *)
    echo "Usage: $0 unit | ui | snapshot" >&2
    exit 64
    ;;
esac

RESULT_BUNDLE="$RESULTS_DIR/$1.xcresult"
LOG="$RESULTS_DIR/$1.log"
mkdir -p "$RESULTS_DIR"

ONLY_TESTING=()
for target in "${TARGETS[@]}"; do
  ONLY_TESTING+=(-only-testing:"$target")
done

run_tests() {
  rm -rf "$RESULT_BUNDLE"
  xcodebuild test-without-building \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA" \
    "${ONLY_TESTING[@]}" \
    -parallel-testing-enabled NO \
    -enableCodeCoverage YES \
    -resultBundlePath "$RESULT_BUNDLE" \
    2>&1 | tee "$LOG" | beautify
}

status=0
run_tests || status=$?
if (( status != 0 )) && grep -q "Failed to install or launch the test runner" "$LOG"; then
  echo "${GITHUB_ACTIONS:+::warning::}$1 tests: test runner failed to launch; retrying once."
  status=0
  run_tests || status=$?
fi
exit "$status"
