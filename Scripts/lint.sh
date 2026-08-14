#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

SOURCES=Packages/AnySSHKit/Sources
MANIFEST=Packages/AnySSHKit/Package.swift
ADAPTERS=(SSHTransport TerminalEmulator Highlighting GitClient FileTransfer Sessions Multiplexers)
LINKABLE=(AnySSHMocks AnySSHUI CSSH Fixtures SwiftTerm "${ADAPTERS[@]}")

TREES=()
for tree in AnySSH AnySSHUITests "$SOURCES" Packages/AnySSHKit/Tests; do
    [ -d "$tree" ] && TREES+=("$tree")
done

CODE=()
for tree in AnySSH "$SOURCES"; do
    [ -d "$tree" ] && CODE+=("$tree")
done

status=0

report() {
    echo "lint: $1" >&2
    printf '%s\n' "$2" | sed 's/^/  /' >&2
    status=1
}

scan() {
    grep -rnE --include='*.swift' "$@" || true
}

others() {
    local skip=$1 name out=
    shift
    for name in "$@"; do
        [ "$name" = "$skip" ] || out="$out|$name"
    done
    echo "${out#|}"
}

imports() {
    echo "^[[:space:]]*(@[A-Za-z_]+[[:space:]]+)*import[[:space:]]+([a-z]+[[:space:]]+)?($1)([.[:space:]]|$)"
}

FORMAT=("$MANIFEST")
if [ ${#TREES[@]} -gt 0 ]; then
    FORMAT+=("${TREES[@]}")
fi
if ! swift format lint --recursive --strict "${FORMAT[@]}"; then
    status=1
fi

budgeted=$(find . -name '*.swift' \
    -not -path './.git/*' \
    -not -path '*/.build/*' \
    -not -path '*/Tests/*' \
    -not -path './AnySSHUITests/*' \
    -not -path '*/Fixtures/*' \
    -not -path '*/Icons/*' \
    -not -name '*.generated.swift')

if [ -n "$budgeted" ]; then
    offenders=$(printf '%s\n' "$budgeted" | while IFS= read -r file; do
        awk 'END { if (NR > 300) print FILENAME": "NR" lines" }' "$file"
    done)
    [ -z "$offenders" ] || report "files over 300 lines:" "$offenders"
fi

commentable=$(find . -name '*.swift' \
    -not -path './.git/*' \
    -not -path '*/.build/*' \
    -not -path '*/Icons/*' \
    -not -path '*/Fixtures/Data/*' \
    -not -name '*.generated.swift')

CHECKER="$(mktemp)"
trap 'rm -f "$CHECKER"' EXIT
cat >"$CHECKER" <<'PY'
import sys

IDENT = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
POSTFIX = IDENT | set(")]}\"'`.$")
KEYWORDS = {"return", "case", "where", "in", "try", "await", "throw",
            "yield", "if", "guard", "while", "else", "and", "or", "default"}
WS = " \t\r\n"

def follows_value(text, i):
    j = i - 1
    while j >= 0 and text[j] in WS:
        j -= 1
    if j < 0 or text[j] not in POSTFIX:
        return False
    if text[j] not in IDENT:
        return True
    k = j
    while k >= 0 and text[k] in IDENT:
        k -= 1
    return text[k + 1:j + 1] not in KEYWORDS

def closes_on_line(text, i):
    n = len(text)
    j = i + 1
    while j < n and text[j] != "\n":
        if text[j] == "\\":
            j += 2
            continue
        if text[j] == "/":
            return text[j - 1] not in WS
        j += 1
    return False

def is_regex(text, i):
    if i + 1 >= len(text) or text[i + 1] in WS or text[i + 1] in "/*=":
        return False
    if follows_value(text, i):
        return False
    return closes_on_line(text, i)

def skip_regex(text, i, pounds):
    n = len(text)
    close = "/" + "#" * pounds
    j = i + pounds + 1
    while j < n:
        if text[j] == "\\":
            j += 2
            continue
        if not pounds and text[j] == "\n":
            raise ValueError("unterminated regex literal")
        if text.startswith(close, j):
            return j + len(close)
        j += 1
    raise ValueError("unterminated regex literal")

def block_end(text, i):
    n = len(text)
    depth = 0
    while i < n:
        if text.startswith("/*", i):
            depth += 1
            i += 2
        elif text.startswith("*/", i):
            depth -= 1
            i += 2
            if depth == 0:
                return i
        else:
            i += 1
    raise ValueError("unterminated block comment")

def blank_to_eol(text, i):
    n = len(text)
    while i < n and text[i] in " \t\r":
        i += 1
    return i >= n or text[i] == "\n"

def comment_lines(text):
    n = len(text)
    i = 0
    stack = [{"quoted": False, "depth": 0, "interp": False}]
    found = []
    while i < n:
        top = stack[-1]
        if top["quoted"]:
            pounds = top["pounds"]
            marker = "#" * pounds
            char = text[i]
            if char == "\\" and text[i + 1:i + 1 + pounds] == marker:
                j = i + 1 + pounds
                if j < n and text[j] == "(":
                    stack.append({"quoted": False, "depth": 0, "interp": True})
                    i = j + 1
                    continue
                i = j + 1
                continue
            if char == '"':
                close = ('"""' if top["multi"] else '"') + marker
                if text.startswith(close, i):
                    stack.pop()
                    i += len(close)
                    continue
            if char == "\n" and not top["multi"]:
                raise ValueError("unterminated string literal")
            i += 1
            continue
        char = text[i]
        if char == "/" and text.startswith("//", i):
            found.append(text.count("\n", 0, i) + 1)
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif char == "/" and text.startswith("/*", i):
            found.append(text.count("\n", 0, i) + 1)
            i = block_end(text, i)
        elif char == '"':
            multi = text.startswith('"""', i) and blank_to_eol(text, i + 3)
            stack.append({"quoted": True, "multi": multi, "pounds": 0})
            i += 3 if multi else 1
        elif char == "#":
            j = i
            while j < n and text[j] == "#":
                j += 1
            pounds = j - i
            following = text[j:j + 1]
            if following == '"':
                multi = text.startswith('"""', j) and blank_to_eol(text, j + 3)
                stack.append({"quoted": True, "multi": multi, "pounds": pounds})
                i = j + (3 if multi else 1)
            elif following == "/":
                i = skip_regex(text, i, pounds)
            else:
                i = j
        elif char == "/" and is_regex(text, i):
            i = skip_regex(text, i, 0)
        elif char == "(":
            top["depth"] += 1
            i += 1
        elif char == ")":
            if top["interp"] and top["depth"] == 0:
                stack.pop()
            else:
                top["depth"] -= 1
            i += 1
        else:
            i += 1
    if len(stack) != 1:
        raise ValueError("unterminated string literal or interpolation")
    return found

TOOLS_VERSION = "// swift-tools-version"

for path in sys.argv[1:]:
    try:
        with open(path, encoding="utf-8") as handle:
            source = handle.read()
        allowed = 1 if source.startswith(TOOLS_VERSION) else 0
        for line in comment_lines(source):
            if line == allowed:
                continue
            print(path + ":" + str(line))
    except Exception as error:
        print(path + ": unscannable (" + str(error) + ")")
PY

if [ -n "$commentable" ]; then
    comments=$(printf '%s\n' "$commentable" | tr '\n' '\0' | xargs -0 python3 "$CHECKER")
    [ -z "$comments" ] || report \
        "comments are not allowed in Swift sources (AGENTS.md, Golden Rules):" "$comments"
fi

if [ ${#TREES[@]} -gt 0 ] && [ -d "$SOURCES/AnySSHUI" ]; then
    hits=$(scan "$(imports SwiftTerm)" "${TREES[@]}" | grep -v "^$SOURCES/AnySSHUI/Terminal/SwiftTerm/" || true)
    [ -z "$hits" ] || report \
        "SwiftTerm may only be imported under $SOURCES/AnySSHUI/Terminal/SwiftTerm/ (AGENTS.md, Repository Layout):" \
        "$hits"
fi

for adapter in "${ADAPTERS[@]}"; do
    [ -d "$SOURCES/$adapter" ] || continue
    hits=$(scan "$(imports "$(others "$adapter" "${ADAPTERS[@]}")")" "$SOURCES/$adapter")
    [ -z "$hits" ] || report \
        "adapter target $adapter imports another adapter (AGENTS.md, Repository Layout):" \
        "$hits"
done

if [ -d "$SOURCES/AnySSHMocks" ]; then
    hits=$(scan "$(imports "$(others AnySSHMocks "${LINKABLE[@]}")")" "$SOURCES/AnySSHMocks")
    [ -z "$hits" ] || report \
        "AnySSHMocks may import only AnySSHCore (AGENTS.md, Repository Layout):" "$hits"
fi

if [ ${#CODE[@]} -gt 0 ]; then
    hits=$(scan '^[[:space:]]*(public |package |internal |fileprivate |private |final |@[A-Za-z_]+ )*protocol[[:space:]]' \
        "${CODE[@]}" | grep -v "^$SOURCES/AnySSHCore/" | grep -v "^$SOURCES/AnySSHUI/" || true)
    [ -z "$hits" ] || report \
        "protocols belong in $SOURCES/AnySSHCore/, or under $SOURCES/AnySSHUI/ when a view owns one (AGENTS.md, Repository Layout):" \
        "$hits"

    confined() {
        local files
        files=$(grep -rlE --include='*.swift' -e "$2" "${CODE[@]}" || true)
        if [ "$(printf '%s' "$files" | grep -c .)" -gt 1 ]; then
            report "$1 belongs in exactly one file:" "$files"
        fi
    }

    confined "the login-shell flag -lc" '-lc'
    confined "the POSIX single-quote escape" "'\\\\{1,2}''"

    clipboard=$(scan 'UIPasteboard\.general\.string[[:space:]]*=' "${CODE[@]}" \
        | grep -v "^$SOURCES/AnySSHUI/Terminal/Clipboard/SystemClipboardPasteboard.swift:" || true)
    [ -z "$clipboard" ] || report \
        "UIPasteboard.general.string may only be assigned in SystemClipboardPasteboard.swift; route copies through SystemClipboardPasteboard.write:" \
        "$clipboard"
fi

[ "$status" -eq 0 ] || exit 1

echo "lint: ok"
