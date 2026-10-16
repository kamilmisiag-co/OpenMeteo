#!/bin/bash
set -eo pipefail
source "$(dirname "$0")/common.sh"
require_simulator

xcodebuild build-for-testing \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA" \
  -enableCodeCoverage YES \
  | beautify
