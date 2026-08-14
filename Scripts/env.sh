#!/usr/bin/env bash

ANYSSH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANYSSH_ROOT

if [ -f "$ANYSSH_ROOT/.env" ]; then
    while IFS='=' read -r key value; do
        value="${value%\"}"
        value="${value#\"}"
        if [ -z "${!key:-}" ]; then
            export "$key=$value"
        fi
    done < <(grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "$ANYSSH_ROOT/.env")
fi

: "${BUNDLE_ID:=com.patricio0312rev.anyssh}"
: "${SIMULATOR_NAME:=iPhone 17 Pro}"
: "${SIMULATOR_COMPACT:=iPhone 16e}"
: "${SIMULATOR_IPAD:=iPad Pro 11-inch (M5)}"
: "${DEVICE_UDID:=}"
: "${APPLE_TEAM_ID:=}"
: "${CONFIG:=Debug}"
: "${DERIVED:=$ANYSSH_ROOT/.build/derived}"
: "${SYM:=$ANYSSH_ROOT/.build/sym}"
: "${ARTIFACTS:=$ANYSSH_ROOT/.build/artifacts}"
: "${DEVICE:=$SIMULATOR_NAME}"

export BUNDLE_ID SIMULATOR_NAME SIMULATOR_COMPACT SIMULATOR_IPAD DEVICE_UDID APPLE_TEAM_ID
export CONFIG DERIVED SYM ARTIFACTS DEVICE
