#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/env.sh"
cd "$ANYSSH_ROOT"

LIBSSH2_COMMIT=8358f2f567e8f4b88a6f66bfe9226265170d4942
LIBSSH2_CVE_FIX=97acf3dfda80c91c3a8c9f2372546301d4a1a7a8

OPENSSL_VERSION=3.5.7
OPENSSL_SHA256=a8c0d28a529ca480f9f36cf5792e2cd21984552a3c8e4aa11a24aa31aeac98e8

export DEPLOY_IOS=26.0
export DEPLOY_MACOS=26.0

export SOURCE_DATE_EPOCH=1786406400

export WORK="$ANYSSH_ROOT/.build/vendor"
OUT="$ANYSSH_ROOT/Packages/AnySSHKit/Vendor/CSSH.xcframework"
STAGE="$WORK/stage"
PINS="libssh2=$LIBSSH2_COMMIT openssl=$OPENSSL_VERSION ios=$DEPLOY_IOS macos=$DEPLOY_MACOS"

SLICES=(
    "ios-arm64 iphoneos arm64 ios64-xcrun asm"
    "ios-sim-arm64 iphonesimulator arm64 iossimulator-xcrun no-asm"
    "ios-sim-x86_64 iphonesimulator x86_64 iossimulator-xcrun no-asm"
    "macos-arm64 macosx arm64 darwin64-arm64-cc asm"
)

say() { echo "vendor: $*"; }
fail() {
    echo "vendor: $*" >&2
    exit 1
}

if [ "${1:-}" = "--force" ]; then
    rm -rf "$OUT" "$WORK/build" "$WORK/prefix"
elif [ -f "$OUT/PINS" ] && [ "$(cat "$OUT/PINS")" = "$PINS" ]; then
    say "up to date: $PINS"
    exit 0
fi

command -v cmake >/dev/null || fail "cmake not found. brew install cmake"
command -v perl >/dev/null || fail "perl not found"

mkdir -p "$WORK/src"

fetch_openssl() {
    local tar="$WORK/src/openssl-$OPENSSL_VERSION.tar.gz"
    local url="https://github.com/openssl/openssl/releases/download"
    if [ ! -f "$tar" ]; then
        say "fetching openssl $OPENSSL_VERSION"
        curl -fsSL -o "$tar" "$url/openssl-$OPENSSL_VERSION/openssl-$OPENSSL_VERSION.tar.gz"
    fi
    local actual
    actual=$(shasum -a 256 "$tar" | cut -d' ' -f1)
    [ "$actual" = "$OPENSSL_SHA256" ] || fail "openssl sha256 mismatch: $actual"
    say "openssl sha256 verified"
    rm -rf "$WORK/src/openssl"
    mkdir -p "$WORK/src/openssl"
    tar -xzf "$tar" -C "$WORK/src/openssl" --strip-components=1
}

fetch_libssh2() {
    local repo="$WORK/src/libssh2"
    if [ ! -d "$repo/.git" ]; then
        say "cloning libssh2"
        git clone --quiet https://github.com/libssh2/libssh2.git "$repo"
    fi
    git -C "$repo" fetch --quiet origin "$LIBSSH2_COMMIT" 2>/dev/null || git -C "$repo" fetch --quiet origin
    git -C "$repo" checkout --quiet --detach "$LIBSSH2_COMMIT"
    git -C "$repo" merge-base --is-ancestor "$LIBSSH2_CVE_FIX" "$LIBSSH2_COMMIT" \
        || fail "pinned commit does not contain the CVE-2026-55200 fix $LIBSSH2_CVE_FIX"
    say "libssh2 $LIBSSH2_COMMIT contains CVE-2026-55200 fix ${LIBSSH2_CVE_FIX:0:8}"
}

fetch_openssl
fetch_libssh2

for slice in "${SLICES[@]}"; do
    Scripts/vendor-slice.sh $slice
done

rm -rf "$STAGE"
mkdir -p "$STAGE/include" "$STAGE/lib"
cp "$WORK/prefix/ios-arm64/include/libssh2"*.h "$STAGE/include/"
cp Packages/AnySSHKit/Vendor/module.modulemap "$STAGE/include/module.modulemap"

for slice in ios-arm64 macos-arm64; do
    mkdir -p "$STAGE/lib/$slice"
    cp "$WORK/prefix/$slice/lib/libcssh.a" "$STAGE/lib/$slice/libcssh.a"
done
mkdir -p "$STAGE/lib/ios-simulator"
lipo -create -output "$STAGE/lib/ios-simulator/libcssh.a" \
    "$WORK/prefix/ios-sim-arm64/lib/libcssh.a" \
    "$WORK/prefix/ios-sim-x86_64/lib/libcssh.a"

rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
xcodebuild -create-xcframework -output "$OUT" \
    -library "$STAGE/lib/ios-arm64/libcssh.a" -headers "$STAGE/include" \
    -library "$STAGE/lib/ios-simulator/libcssh.a" -headers "$STAGE/include" \
    -library "$STAGE/lib/macos-arm64/libcssh.a" -headers "$STAGE/include" >/dev/null

echo "$PINS" >"$OUT/PINS"

say "libssh2   $LIBSSH2_COMMIT"
say "openssl   $OPENSSL_VERSION ($OPENSSL_SHA256)"
say "slices    $(find "$OUT" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | tr '\n' ' ')"
say "output    ${OUT#"$ANYSSH_ROOT"/} ($(du -sh "$OUT" | cut -f1 | tr -d ' '))"
say "sha256    $(find "$OUT" -type f \( -name '*.a' -o -name '*.h' -o -name '*.modulemap' \) \
    -exec shasum -a 256 {} \; | cut -d' ' -f1 | sort | shasum -a 256 | cut -d' ' -f1)"
