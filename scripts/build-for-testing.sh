#!/bin/bash
set -eo pipefail
source "$(dirname "$0")/common.sh"
require_simulator

xcodebuild build-for-testing \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -enableCodeCoverage YES \
  | beautify
