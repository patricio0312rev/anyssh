#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
cd "$ANYSSH_ROOT/Packages/AnySSHKit"

NSUnbufferedIO=YES xcodebuild test -scheme AnySSHKit-Package \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -derivedDataPath "$DERIVED" 2>&1 | "$ANYSSH_ROOT/Scripts/format-log.sh"
