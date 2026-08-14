#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
cd "$ANYSSH_ROOT"

NSUnbufferedIO=YES xcodebuild test -project AnySSH.xcodeproj -scheme AnySSH \
    -configuration "$CONFIG" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -derivedDataPath "$DERIVED" SYMROOT="$SYM" \
    -test-timeouts-enabled YES -default-test-execution-time-allowance 60 \
    -only-testing:AnySSHUITests 2>&1 | Scripts/format-log.sh
