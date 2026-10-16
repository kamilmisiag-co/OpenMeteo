cd "$(dirname "${BASH_SOURCE[0]}")/.."

WORKSPACE=OpenMeteo.xcworkspace
SCHEME=OpenMeteo

WORK_DIR="${RUNNER_TEMP:-$PWD/build}"
DERIVED_DATA="$WORK_DIR/DerivedData"
RESULTS_DIR="$WORK_DIR/TestResults"

require_simulator() {
  : "${SIMULATOR_UDID:?SIMULATOR_UDID is not set; run scripts/simulator.sh create first}"
  DESTINATION="platform=iOS Simulator,id=$SIMULATOR_UDID"
}

beautify() {
  if ! command -v xcbeautify > /dev/null; then
    cat
  elif [[ -n "$GITHUB_ACTIONS" ]]; then
    xcbeautify --renderer github-actions
  else
    xcbeautify
  fi
}
