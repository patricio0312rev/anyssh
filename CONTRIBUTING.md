# Contributing

AnySSH is a ground-up rebuild of a working legacy app, so most changes are ports, not inventions. Read [AGENTS.md](AGENTS.md) before writing code: it defines the module boundaries, the design system, and the review rules, and it is binding.

## Setup

Follow the [getting started](README.md#getting-started) steps in the README. `make run` boots the app in mock mode with no live host, which is enough for almost all work.

Before opening a PR, run:

```bash
make lint
make test
```

`make lint` runs swift-format, the 300-line file budget, and the module import rules. CI runs swift-format and the line budget on every push; run both commands locally before opening a PR.

## Branches and commits

- Branches: `type/short_descriptive_name` with underscores. Types: `feat`, `fix`, `docs`, `refactor`. Example: `fix/toolbar_double_glass`.
- Commits: `type: description`, lowercase except acronyms. Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`.
- One file per commit. The message describes the outcome the file delivers, never the filename.
- Single author. No `Co-Authored-By` lines.

## Ground rules

The short version of AGENTS.md:

- Max 300 lines per Swift file.
- Zero comments in code.
- Reuse components from `AnySSHUI/Components/` before writing new UI.
- Preserve legacy behavior. A behavior change is a bug unless a plan phase calls for one.
- Colors, fonts, and motion come from `Theme`, never hardcoded.

## Pull requests

Title format: `type: short descriptive name`, lowercase except acronyms. Fill in the PR template: say what changed and how to verify it. For UI changes, attach a simulator screenshot.

## Bugs and ideas

Open an issue with the matching template. For security problems, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.
