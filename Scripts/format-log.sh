#!/usr/bin/env bash
set -uo pipefail

if command -v xcbeautify >/dev/null 2>&1; then
    exec xcbeautify --quiet --is-ci
fi

grep -E '^(\*\* .*(SUCCEEDED|FAILED)|.*(error|warning):|.*(Test Suite|Test Case).*)' || true
