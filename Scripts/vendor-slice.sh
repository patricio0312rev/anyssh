#!/usr/bin/env bash
set -euo pipefail

NAME="${1:?slice name}"
SDK="${2:?sdk}"
ARCH="${3:?arch}"
OPENSSL_TARGET="${4:?openssl target}"
OPENSSL_ASM="${5:?asm|no-asm}"

if [ "$OPENSSL_ASM" = "no-asm" ]; then
    OPENSSL_OPTS=(no-asm)
else
    OPENSSL_OPTS=(threads)
fi

PREFIX="$WORK/prefix/$NAME"
BUILD="$WORK/build/$NAME"
JOBS=$(sysctl -n hw.ncpu)
LOG="$WORK/build/$NAME.log"

quietly() {
    "$@" >>"$LOG" 2>&1 || {
        echo "vendor-slice: $NAME failed. Tail of $LOG:" >&2
        tail -40 "$LOG" >&2
        exit 1
    }
}

case "$SDK" in
    iphoneos)
        MIN_FLAG="-mios-version-min=$DEPLOY_IOS"
        CMAKE_SYSTEM=(-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOY_IOS")
        ;;
    iphonesimulator)
        MIN_FLAG="-mios-simulator-version-min=$DEPLOY_IOS"
        CMAKE_SYSTEM=(-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOY_IOS")
        ;;
    macosx)
        MIN_FLAG="-mmacosx-version-min=$DEPLOY_MACOS"
        CMAKE_SYSTEM=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOY_MACOS")
        ;;
    *)
        echo "vendor-slice: unknown sdk $SDK" >&2
        exit 1
        ;;
esac

echo "vendor-slice: $NAME ($SDK/$ARCH)"
mkdir -p "$BUILD"
: >"$LOG"

if [ ! -f "$PREFIX/lib/libcrypto.a" ]; then
    rm -rf "$BUILD/openssl"
    mkdir -p "$BUILD/openssl"
    cp -R "$WORK/src/openssl/." "$BUILD/openssl/"
    cd "$BUILD/openssl"
    quietly ./Configure "$OPENSSL_TARGET" no-shared no-tests no-docs no-apps "${OPENSSL_OPTS[@]}" \
        --prefix="$PREFIX" --openssldir="$PREFIX/ssl" \
        "-arch%20$ARCH" "$MIN_FLAG"
    quietly make -j"$JOBS" build_libs
    quietly make install_dev
    cd - >/dev/null
fi

rm -rf "$BUILD/libssh2"
quietly cmake -S "$WORK/src/libssh2" -B "$BUILD/libssh2" \
    -DCMAKE_BUILD_TYPE=Release \
    "${CMAKE_SYSTEM[@]}" \
    -DCMAKE_OSX_SYSROOT="$SDK" \
    -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_TESTING=OFF \
    -DENABLE_ZLIB_COMPRESSION=OFF \
    -DCRYPTO_BACKEND=OpenSSL \
    -DOPENSSL_ROOT_DIR="$PREFIX" \
    -DOPENSSL_USE_STATIC_LIBS=ON \
    -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH
quietly cmake --build "$BUILD/libssh2" --target install --parallel "$JOBS"

nm -g "$PREFIX/lib/libssh2.a" 2>/dev/null | grep -q 'T _ssh2_ed25519_sign' \
    || {
        echo "vendor-slice: $NAME has no ed25519. Crypto backend is not OpenSSL." >&2
        exit 1
    }

rm -f "$PREFIX/lib/libcssh.a"
libtool -static -D -o "$PREFIX/lib/libcssh.a" \
    "$PREFIX/lib/libssh2.a" "$PREFIX/lib/libssl.a" "$PREFIX/lib/libcrypto.a" 2>/dev/null
