#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
cd "$ANYSSH_ROOT"

xcodebuild -project AnySSH.xcodeproj -scheme AnySSH -configuration "$CONFIG" \
    -destination "platform=iOS Simulator,name=$DEVICE" \
    -derivedDataPath "$DERIVED" SYMROOT="$SYM" \
    build | Scripts/format-log.sh

Scripts/app-path.sh
