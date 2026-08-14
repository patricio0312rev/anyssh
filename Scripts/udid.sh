#!/usr/bin/env bash
set -euo pipefail

NAME="${1:?usage: udid.sh <simulator name>}"

xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
matches = [d["udid"] for runtime in devices for d in devices[runtime] if d["name"] == name]
if not matches:
    sys.exit(f"no available simulator named {name!r}")
print(matches[0])
' "$NAME"
