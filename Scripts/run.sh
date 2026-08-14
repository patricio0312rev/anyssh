#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
cd "$ANYSSH_ROOT"

SCENARIO="${SCENARIO:-default}"
UDID="$(Scripts/udid.sh "$DEVICE")"
APP="$(Scripts/app-path.sh)"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "$APP"
SIMCTL_CHILD_ANYSSH_SCENARIO="$SCENARIO" \
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" -UITestMode YES "$@"
