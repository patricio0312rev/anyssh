# Contributing

Thanks for wanting to help. This file is the short version; [AGENTS.md](AGENTS.md) is the binding rulebook for anything that touches code, and it wins over habit, preference, and this summary.

## Getting set up

```bash
cp .env.example .env
make vendor
make run
```

`make vendor` builds the pinned libssh2 + OpenSSL xcframework once. `make run` boots the app in mock mode, where every port is mocked and no live host is needed. Every screen is reachable headlessly with `ANYSSH_SCENARIO=<name>`, which is also how the UI tests and screenshots get to a state.

## Before you open a PR

- `make lint` must pass: swift-format, the 300-line file budget, the comment ban, and the module import rules.
- `make test` (host), `make test-sim` (simulator), and `make ui-test` (XCUITest) must be green.
- UI work follows the design system in AGENTS.md: compose from `AnySSHUI/Components/`, colors and spacing come from `Theme`, and every new screen needs a launch scenario so it can be reached without tapping.
- Screenshot what you changed and look at it before claiming it works.

## Ground rules worth knowing early

- Zero comments in Swift sources. Names carry the meaning; AGENTS.md explains the one exception.
- Max 300 lines per file. Tests, docs, and asset-like files are exempt.
- One file per commit, conventional commit messages, outcome-focused: `fix: collapse the diff gutter when no line has a number`, never `update DiffGutter.swift`.
- Behavior is sacred: gestures, the toolbar, and the keyboard accessory were paid for in bugs. Restyle appearance, never reflow logic, unless the change is the point of your PR.
- Dead code does not land. If nothing reaches it, delete it.

## Security

The SSH transport vendors libssh2 + OpenSSL from a pinned commit; the vendoring script refuses commits that do not descend from the fix for CVE-2026-55200. Do not weaken that check. Report security issues privately through the contact on [getanyssh.com](https://www.getanyssh.com) rather than a public issue.
