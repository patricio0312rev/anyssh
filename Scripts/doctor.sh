#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() {
    echo "doctor: $*" >&2
    exit 1
}

command -v xcodebuild >/dev/null || fail "xcodebuild not found"
echo "doctor: $(xcodebuild -version | head -1)"

command -v swift >/dev/null || fail "swift not found"
swift format --version >/dev/null 2>&1 || fail "bundled 'swift format' not available"

[ -d Packages/AnySSHKit/Vendor/CSSH.xcframework ] \
    || fail "libssh2 xcframework missing. Run: make vendor"

[ -f Config/Local.xcconfig ] \
    || echo "doctor: Config/Local.xcconfig absent. Simulator builds are unaffected; device builds need it."

xcrun -f metal >/dev/null 2>&1 \
    || fail "Metal Toolchain missing, and the terminal renderer needs it. Run: xcodebuild -downloadComponent MetalToolchain"

sdk=$(xcodebuild -showsdks 2>/dev/null | sed -n 's/.*-sdk \(iphoneos[0-9.]*\).*/\1/p' | head -1)
[ -n "$sdk" ] || fail "no iOS SDK found"

chosen=$(xcrun simctl runtime match list -j 2>/dev/null | python3 -c '
import json, sys
sdk = sys.argv[1]
data = json.load(sys.stdin)
entry = data.get("defaultResults", data).get(sdk) or data.get(sdk) or {}
print(entry.get("chosenRuntimeBuild", ""))
' "$sdk")

installed=$(xcrun simctl runtime list -j 2>/dev/null | python3 -c '
import json, sys
for runtime in json.load(sys.stdin).values():
    if "iphonesimulator" in runtime.get("platformIdentifier", ""):
        print(runtime["build"])
')

[ -n "$installed" ] || fail "no iOS simulator runtime installed. Run: xcodebuild -downloadPlatform iOS"

if ! grep -qx -- "$chosen" <<<"$installed"; then
    newest=$(tail -1 <<<"$installed")
    echo "doctor: $sdk wants runtime '${chosen:-none}', which is not installed."
    echo "doctor: remapping $sdk -> $newest"
    xcrun simctl runtime match set "$sdk" "$newest"
fi

xcodebuild -project AnySSH.xcodeproj -scheme AnySSH -showdestinations 2>/dev/null \
    | grep -q 'platform:iOS Simulator' \
    || fail "no iOS Simulator destination resolved. Try: xcodebuild -downloadPlatform iOS"

echo "doctor: ok"
