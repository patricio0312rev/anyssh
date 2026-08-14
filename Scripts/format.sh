#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

TARGETS=(Packages/AnySSHKit/Package.swift)
for tree in AnySSH AnySSHUITests Packages/AnySSHKit/Sources Packages/AnySSHKit/Tests; do
    [ -d "$tree" ] && TARGETS+=("$tree")
done

swift format --recursive --in-place "${TARGETS[@]}"

echo "format: ok"
