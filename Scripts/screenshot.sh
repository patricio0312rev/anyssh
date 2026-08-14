#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
cd "$ANYSSH_ROOT"

SCENARIO="${SCENARIO:-default}"
SLUG="$(printf '%s' "$DEVICE" | tr ' ()' '-')"
OUT="${OUT:-$ARTIFACTS/$SLUG-$SCENARIO.png}"

UDID="$(Scripts/udid.sh "$DEVICE")"
APP="$(Scripts/app-path.sh)"
mkdir -p "$(dirname "$OUT")"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null

xcrun simctl status_bar "$UDID" override \
    --time "09:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 \
    --batteryState charged --batteryLevel 100

xcrun simctl install "$UDID" "$APP"
SIMCTL_CHILD_ANYSSH_SCENARIO="$SCENARIO" xcrun simctl launch --terminate-running-process \
    "$UDID" "$BUNDLE_ID" -UITestMode YES >/dev/null
sleep 2
xcrun simctl io "$UDID" screenshot --type=png "$OUT"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true

echo "$OUT"
