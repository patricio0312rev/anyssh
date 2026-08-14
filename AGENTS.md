# AGENTS.md

Rules for every agent and contributor working in this repository. They are binding. When a rule here conflicts with a default behavior or a global instruction, this file wins.

## Project

AnySSH is an iOS 26 SSH client: a real terminal, remote git, remote files, and tmux/herdr multiplexer support. No backend, no account, nothing installed on the host. Keys and passphrases live in the iOS Keychain on device.

This repository is a ground-up rebuild of a working legacy codebase. Functionality is ported, not reinvented: the legacy app behaves correctly, and the goal of the rebuild is visual consistency and code quality. Treat behavior changes as bugs unless a plan phase explicitly calls for one.

## Golden Rules

- **Max 300 lines per Swift file.** Split along an existing seam (what a screen draws vs what it does, a parser's grammar vs its decoding) before the count forces an arbitrary cut. Exempt: test files, documentation, README, and asset-like files (SVG path data, generated icons, images, fixtures).
- **Zero comments.** No exceptions for explaining code. The only tolerated occurrence is a tooling directive that cannot be avoided (`swift-format-ignore`, `#warning` required by a build rule), and it must state its reason on the same line. Do not carry comments over from legacy sources when porting.
- **Single responsibility.** Every file, type, and function does one thing. If describing it needs "and", split it.
- **SOLID by default.** Protocols (ports) declare seams, adapters implement them, the composition root wires them. Depend on abstractions, inject at the root.
- **Reuse before creating.** Before writing any UI element, check `AnySSHUI/Components/`. If a variation seems better than the existing component, improve the shared component for every call site instead of forking a local copy.
- **No dead code.** A view, component, or symbol nothing reaches does not land. During the rebuild, unreachable legacy code is deleted rather than ported and logged in `docs/dead-code-report.md`.
- **Name what repeats.** A literal that appears more than twice (string, number, duration, key, layout value) becomes a named constant owned by one module: UI values in `Theme.Space`/`Theme.Motion`, accessibility ids in `UIIdentifier`, everything else in a constants enum next to its owner. Two files declaring the same magic value is a bug.
- **Match the codebase.** Follow existing naming, structure, and idiom before introducing new ones.
- **Preserve behavior.** Gestures, toolbar wiring, and the keyboard accessory are fragile and were paid for in bugs. Port their logic exactly; restyle only their appearance.
- **One view at a time.** UI work lands view by view: build the view, screenshot it, review it against this file, then start the next. Parallel work is fine inside a single view (model, subviews, tests) or while the previous view sits in review, never as a broad sweep across many screens at once.

## Repository Layout

```
AnySSH/                 app target: composition root, wiring, launch scenarios
AnySSHWidgets/          widget and Live Activity extension
AnySSHUITests/          XCUITest flows
Packages/AnySSHKit/     all modules, tests, and fixtures
Config/                 xcconfig build settings
Scripts/                build and vendoring automation (minimal set only)
docs/                   plans and working notes, untracked
```

Module map inside `Packages/AnySSHKit/Sources/`:

```
AnySSHCore          ports + Sendable value types, imports nothing from the project
SSHTransport        libssh2 session actor, auth, host keys, PTY, exec channels
TerminalEmulator    engine protocol, output pump, input encoding
Highlighting        tree-sitter parsers, per-line token slicing
GitClient           hardened invocation and parsers
FileTransfer        blob fetch, size guards
Sessions            session registry, reconnect policy, scrollback budget
Multiplexers        tmux and herdr adapters
AnySSHMocks         conforms to every port in AnySSHCore, imports only AnySSHCore
AnySSHUI            SwiftUI + UIKit, the only target that imports SwiftTerm
```

Rules the structure enforces:

- Protocols live in `AnySSHCore`, except view-local ones under `AnySSHUI`.
- An adapter never imports another adapter. `GitClient` takes a `RemoteCommandRunner` by injection rather than importing `SSHTransport`.
- SwiftTerm may only be imported under `AnySSHUI/Terminal/SwiftTerm/`.
- Inside `AnySSHUI`: `Components/` holds every reusable control; feature folders (`Remotes/`, `Terminal/`, `Git/`, `Files/`, `Sessions/`, `Settings/`) hold implementations that compose those components. New files go where the structure says they belong, never at a root "for now".

## Component Reuse

The component catalog is the single source of visual truth. A screen is composition, not invention.

- Icon-only button: `IconButton`. Closing a screen: `CloseButton`. Screen title with actions: `ScreenHeader`. List row: `CatalogRow`. Copyable value: `CopyableRow`. Settings entry: `SettingsRow`. The only spinner: `LoadingView`. Passive feedback: `StatusToast`.
- `LoadingView` has exactly two variants and no call site invents a third: `.inline` (small, unlabeled, sits where content will appear) and `.screen` (centered, standard size, with a required short label saying what is loading). Both monochrome `text.secondary`, never accent-tinted, sizes fixed by the component. A raw `ProgressView` outside `LoadingView` fails review.
- Copy affordances go through `CopyableRow` and nothing else: the whole row is the hit target, not just the icon, and feedback is always the same icon swap to a checkmark for a fixed dwell. No labeled copy buttons, no oversized copy icons, no copy control that gives no feedback.
- `CloseButton` has one size, period. The close control on a sheet, the keyboard-hide control, and every dismiss affordance share the same hit target and glyph scale; a bigger close button on one screen is a bug.
- Code and diff rendering already exist under `AnySSHUI/Files/` and `AnySSHUI/Git/DiffRenderer/`. Never add a second viewer for a format that has one. A missing capability goes into the existing viewer so every caller gains it.
- Writing `Button { Image(systemName:) }` by hand instead of using `IconButton` is how the legacy toolbar ended up with a button inside a button.

## Swift Practices

- Swift 6 language mode, strict concurrency. Value types are `Sendable`; shared mutable state lives in an actor; UI state is `@MainActor`.
- Models are `@Observable` classes or plain value types. No Combine where structured concurrency does the job.
- No force unwraps, no force try, no implicitly unwrapped optionals. `swift-format` enforces all three.
- Never `try?` on a path a person is waiting on. A swallowed error looks like a rendering bug for days.
- `guard` for early exit. Functions stay short enough to read without scrolling.
- One primary type per file, file named after the type.
- Dependencies flow through initializers from the composition root. Anything reached through the SwiftUI environment must be injected at the root; a default that quietly answers nothing is worse than a crash.

```swift
struct RemoteRowModel: Sendable, Equatable {
    let id: Remote.ID
    let name: String
    let status: RemoteStatus
}

@MainActor @Observable final class RemotesListModel {
    private let store: RemoteStore
    private(set) var rows: [RemoteRowModel] = []

    init(store: RemoteStore) {
        self.store = store
    }

    func refresh() async throws {
        rows = try await store.remotes().map(RemoteRowModel.init)
    }
}
```

## SwiftUI Practices

- A view struct stays small: extract subviews as named types or computed properties the moment a body needs a scroll to read.
- State a view reads must be state the view can rebuild from. A model built once in `init` from values that later change is a photograph, not a model.
- Stable identity in every `ForEach`. No index-based identity for mutable lists.
- No `GeometryReader` where alignment, `containerRelativeFrame`, or layout priorities do the job.
- Every reusable component ships with a `#Preview` covering its variants.
- An accessibility identifier is API: declare it in `UIIdentifier` and apply it in the same change, following the `remote.*` / `session.*` / `terminal.*` / `git.*` convention. Never derive one from display text.

```swift
struct RemotesListView: View {
    let model: RemotesListModel

    var body: some View {
        List(model.rows) { row in
            CatalogRow(title: row.name, status: row.status)
        }
        .background(Theme.surface.base)
        .accessibilityIdentifier(UIIdentifier.remoteList)
    }
}
```

## Design System

Two visual worlds, one hard border between them:

- **Chrome is native iOS.** System dark backgrounds, Liquid Glass controls, SF typography, system motion, system semantic colors. The app forces dark appearance and never follows the system setting.
- **Code is Monokai Pro.** Terminal, diffs, source and JSON viewers, and snippets render on the Monokai canvas with JetBrains Mono. Monokai colors never leak into chrome, and chrome colors never leak into code surfaces.

### Chrome colors

Chrome never declares a hex value. Views use `Theme` tokens that wrap system semantics:

| Token | Wraps | Use |
|---|---|---|
| `surface.base` | `systemBackground` | screen background |
| `surface.raised` | `secondarySystemBackground` | cards, grouped rows, sheets |
| `surface.overlay` | `tertiarySystemBackground` | menus, accessory chrome |
| `text.primary` | `label` | titles, body |
| `text.secondary` | `secondaryLabel` | subtitles, metadata |
| `text.tertiary` | `tertiaryLabel` | non-essential labels only |
| `separator` | `separator` | hairlines |
| `accent` | `#ab9df2` sRGB | selection, focus, at most one primary action per screen |
| `destructive` | `systemRed` | remove, delete, disconnect-and-lose-state |
| `status.*` | system green/yellow/orange/red/gray | online, busy, attention, error, offline dots and badges |

The accent is the one branded color in chrome and it is scarce on purpose: selected rows, focus rings, one primary action. An accent-colored icon row, spinner, or decorative tint fails review. Elevation comes from glass and the three surfaces, never from a fourth background color.

### Code colors

Monokai Pro, declared once in `Theme.Code`, always sRGB (`Color(.sRGB, ...)`), never `.displayP3`: canvas `#2d2a2e`, the ANSI table, the syntax role mapping, and the diff tints (`#a9dc76` at 13% added, `#ff6188` at 13% removed). Terminal content reproduces the palette exactly. No chrome token appears inside a code surface and no `Theme.Code` token appears outside one.

### Typography

Two typefaces exist in the entire app:

- **System (SF) with Dynamic Type** for all chrome: titles, body, labels, buttons. Roles come from `Theme.Text` (`screenTitle`, `sectionHeader`, `body`, `caption`) which wrap the standard text styles. No custom sizes, no one-off weights.
- **JetBrains Mono** for terminal content, code, diffs, paths, hashes, and anything monospaced, always through `Theme.code(size:)`. The terminal size is user-selectable and independent of Dynamic Type because column count is functional.

A third typeface, or a raw `.font(.system(size:))` outside `Theme`, fails review.

### Buttons and Liquid Glass

One hierarchy, applied everywhere:

- **Primary action** (at most one per screen): `.buttonStyle(.glassProminent)` tinted with `accent`.
- **Standard chrome buttons** (toolbars excluded): `.buttonStyle(.glass)`, untinted, one glass depth for the whole app. Glass only where the control floats over content it can refract: a scrolling list, terminal output, an image. A button resting on an empty stretch of `surface.base` has nothing to refract and disappears; it uses a raised capsule on `surface.raised` instead, or a solid accent capsule (opaque fill, white label, no glass) if it is the screen's primary action — `.glassProminent` over pure black reads washed out, so it belongs only over scrims and dimmed content. One glass depth per view: when a screen earns `.glassProminent`, that is the only glass on it, so nothing sits half-shiny next to it.
- **Toolbar buttons**: plain content only, always monochrome. The toolbar draws its own glass; adding `.glass` inside it nests capsules, and the accent never tints a toolbar glyph.
- **Inside forms, lists, and cards**: no glass. Confirm/cancel pairs are plain text toolbar buttons without icons; a row-level action (test connection, import) is a bordered or plain row button that belongs to the form's surface. Glass is for controls floating over content, not for controls sitting in it.
- **Row actions inside cards** (import, paste, choose, test): monochrome `text.primary` with a leading icon or trailing chevron so they read as interactive, exactly like Edit Host's Import Key row. Accent text is reserved for the screen's single confirming action (Save, Continue); two purple rows on one card means neither is primary.
- **Destructive** (remove, delete, reset to defaults, disconnect-and-lose-state): same shape as its context with the `destructive` red role, always behind a confirmation.
- **Over a scrim or dark overlay** (reconnect, error covers, full-screen states): plain `.glass` disappears against the darkness. Every button there is `.glassProminent`, accent for the single continue action and monochrome for the rest. If a screenshot cannot distinguish a control from its background, the style is wrong regardless of what this table says.

All buttons of the same role share the same size: `IconButton` defines the icon hit target, `Theme.Buttons` defines heights. A button visually smaller, darker, or shinier than its siblings is a bug.

A row that navigates ends in a chevron. Status is a `StatusDot` beside the row's metadata, never the trailing accessory pretending to be navigation.

### Presentation

Choose by rule, not by mood:

| Pattern | When |
|---|---|
| Pushed view | navigation into content that has its own screen worth of hierarchy |
| Sheet, `.medium` detent | a quick task or picker where the context behind must stay visible |
| Sheet, `.large` | a self-contained flow with a Done/Cancel pair (forms, key import) |
| Full-screen cover | immersive surfaces only: the terminal workspace |
| Alert | a decision that blocks, or a destructive confirmation, two buttons max |
| Confirmation dialog | choosing between actions on a just-tapped object |
| `StatusToast` | passive outcome feedback, never requires a tap |

Every sheet gets a visible drag indicator and a `ScreenHeader`, except blocking modals (`interactiveDismissDisabled`): a drag indicator there advertises a dismissal that does not exist, so they show none and present their copy through `ErrorStateView`-style hierarchy. Mixing patterns for the same job across screens fails review.

Forms follow one hierarchy, and the legacy Edit Host form is the reference for it: plain text Cancel/Save in the toolbar, sections introduced by a `SectionLabel`, controls grouped in raised cards, and every explanation as a `caption` in `text.secondary` sitting directly under the card it explains. A description never gets its own box, never sits above its control, and is never larger than the section label; if a text's role (title, label, or description) is not obvious at a glance, the hierarchy is wrong.

Transient feedback is one family, not three. Everything passive flows through the single `StatusToastCenter`: one host, one position (bottom), one card treatment, one set of status colors and symbols. No ad-hoc top banners, no second smaller toast, no floating one-off alert card. The Live Activity and widget reuse the same status colors and iconography so an alert looks like a sibling of the in-app toast, not a stranger.

### Spacing

Margins and padding come from `Theme.Space`, a 4pt grid: 4, 8, 12, 16, 24, 32. Screen edge margin is 16, card padding is 12, row gaps are 8. Lists keep system default insets. One corner radius per shape class (`card`, `control`) defined in `Theme.Space`, matched to the concentric radius of its container. A raw number inside `padding()`, `spacing:`, `cornerRadius`, or `frame` that exists in `Theme.Space` fails review; a value the scale lacks is a design-system change, not a local liberty.

### Motion

- System curves and durations. Transitions come from navigation and presentation defaults.
- Custom animation only where state changes would otherwise be ambiguous (status dot changes, reconnect progress), implemented with `withAnimation(.default)` or a spring preset from `Theme.Motion`, nowhere else.
- Every custom animation respects Reduce Motion.

## Commits and Branches

- Conventional commits: `type: description`, lowercase except acronyms. Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`.
- **One file per commit.** Every commit touches exactly one file, and its message describes the outcome that file delivers, never the filename. `update X.swift` is banned.
- Single author. No `Co-Authored-By` lines, no co-authors on PRs.
- Branches: `type/short_descriptive_name` with underscores (`feat/add_key_import`, `fix/toolbar_double_glass`).
- Never commit `docs/`: plans and working notes stay untracked.

## Documentation

- Repository artifacts are English only: code, identifiers, commits, docs, UI copy.
- Markdown uses at most three heading levels; a deeper outline means the section needs restructuring.
- No AI-sounding writing: no em dashes, no rule-of-three filler, no inflated adjectives, no "not just X, but Y".
- Plans live in `docs/plan-*.md`, follow phases with goals and exit criteria, and are updated as phases complete.

## Verification

- Mock mode runs the whole app with no live host; every screen is reachable via `ANYSSH_SCENARIO=<name>`. Build and look before claiming anything works: `make run`, then a simulator screenshot, then read the image. Reasoning about a layout is not evidence about a layout.
- `make lint` runs swift-format, the 300-line budget, and the module import rules. Run it with the tests, not after them.
- Tests are ported with their module and must pass before the module's port is complete.
