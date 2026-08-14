#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
cd "$ANYSSH_ROOT"

xcodebuild -project AnySSH.xcodeproj -target AnySSH -configuration "$CONFIG" \
    -sdk iphonesimulator SYMROOT="$SYM" -showBuildSettings -json 2>/dev/null \
    | python3 -c '
import json, sys
settings = json.load(sys.stdin)[0]["buildSettings"]
print(settings["TARGET_BUILD_DIR"] + "/" + settings["FULL_PRODUCT_NAME"])
'
