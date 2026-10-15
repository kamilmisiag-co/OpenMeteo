#!/bin/bash
set -eo pipefail

DEVICE_TYPE="${SIMULATOR_DEVICE_TYPE:-iPhone 17 Pro}"

case "$1" in
  create)
    NAME="OpenMeteo-CI-${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}"
    UDID=$(xcrun simctl create "$NAME" "$DEVICE_TYPE")
    if ! xcrun simctl bootstatus "$UDID" -b >&2; then
      xcrun simctl delete "$UDID"
      exit 1
    fi
    echo "$UDID"
    ;;
  delete)
    : "${2:?Usage: $0 delete <udid>}"
    xcrun simctl shutdown "$2" 2> /dev/null || true
    xcrun simctl delete "$2"
    ;;
  *)
    echo "Usage: $0 create | delete <udid>" >&2
    exit 64
    ;;
esac
