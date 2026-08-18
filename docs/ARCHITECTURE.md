# AnySSH architecture

One consolidated design derived from `docs/research/01` through `08`. It assumes
`docs/DECISIONS.md` is binding and does not revisit anything settled there.

Reading order for anyone implementing: sections 2 and 3 define the shape of the codebase,
sections 4 to 6 define the terminal, sections 7 to 11 define everything that runs a command
on the host, and section 15 records where two research documents disagreed and which one won.

Where a research document conflicts with `08-live-host-probe.md`, the probe wins. It was
measured against `dev@192.0.2.10` rather than argued.

## 1. Scope and standing constraints

MVP delivers: Remotes, SSH, Terminal, Sessions, Capability detection, Multiplexers, Git,
Files. Out of MVP: Android, Watch, Live Activities, Dynamic Island, push, any backend or
account, VPN, mosh, agent-state detection, repository mutation.

Five constraints shape every decision below.

| Constraint | Source | Consequence |
|---|---|---|
| No backend, no account, no host install | Decision 5, doc 07 | Every signal is derived from ordinary commands over SSH. The only thing we may ever ask a user to add to their host is a shell snippet they can read in a file they already own. |
| iOS suspends a backgrounded socket in roughly 30 seconds | Decision 9, doc 01 §5.1 | Persistence is a server-side concern. The UI states this instead of implying resume. |
| A bare SSH exec gets a four-entry `PATH` | Decision 14, doc 08 | Every probe and every remote command runs under `$SHELL -lc`. This is encapsulated in exactly one type. |
| Channel open costs round trips and `MaxSessions` defaults to 10 | Decision 11, doc 04 A.0 | One long-lived connection, one exec channel per batched group, roughly one batch per screen. |
| Many agents write code in parallel | Doc 05 §1 | Adding a source file must never touch `project.pbxproj` or `Package.swift`. Dependency-graph edits happen only in named sequential phases. |

Two facts about the machine itself, both already handled by `Scripts/doctor.sh`: Xcode 26.6
ships the iOS 26.5 SDK while only the iOS 26.2 runtime is installed, and the SDK-to-runtime
override must be re-applied after an Xcode upgrade.

## 2. Module map

The nine targets in `Packages/AnySSHKit/Package.swift` are already declared and the scaffolding
compiles. Two targets are added: `Highlighting`, and a resource-only `Fixtures` target that vends
recorded bytes to test targets, because SwiftPM cannot serve a bare `Tests/Fixtures/` directory
without a resource declaration. Those are the only structural changes to the package graph.
Everything else is a matter of which files land where.

```
AnySSHCore          ports + value types. Imports nothing from the project.
  |
  +-- SSHTransport      libssh2 session actor, auth, host keys, PTY, exec channels
  +-- TerminalEmulator  engine protocol, output pump, input encoding. No UIKit, no SwiftTerm.
  +-- Highlighting      tree-sitter parsers and per-line token slicing. NEW target.
  +-- GitClient         hardened invocation, -z parsers, unified diff parser
  +-- FileTransfer      blob fetch, size guards, temp-file streaming
  +-- Sessions          session registry, reconnect policy, scrollback budget
  +-- Multiplexers      tmux and herdr adapters
  +-- AnySSHMocks       conforms to every port in AnySSHCore
  |
  +-- AnySSHUI          SwiftUI + UIKit. The only target that imports SwiftTerm.
        |
        +-- AnySSH app  composition root: real wiring vs mock wiring
```

The declared edges in `Package.swift` stay as they are, with one exception. `AnySSHMocks` is
currently declared with a dependency on `SSHTransport`, which contradicts rule 3 below. Rule 3
wins and the edge is removed in the dependency phase, because keeping the mock environment
linkable without libssh2 is the whole reason the rule exists. Every other declared edge stays.

The rule that matters is narrower than the declared graph:

1. **`AnySSHCore` is the ports module.** Every protocol the mock environment must implement
   lives here, together with the `Sendable` value types in its signatures. Nothing else in the
   project may declare a port.
2. **Adapter modules never appear in another adapter's imports.** `GitClient` does not import
   `SSHTransport`; it takes a `RemoteCommandRunner` by injection. The declared edge exists
   because `Package.swift` is frozen, not because the code uses it. A lint rule enforces this.
3. **`AnySSHMocks` imports only `AnySSHCore`.** That is what keeps the mock environment
   linkable in every configuration without dragging libssh2 or SwiftTerm into it.
4. **`AnySSHUI` imports `AnySSHCore` for ports and the adapter modules only where a view type
   genuinely needs one.** The composition root in `AnySSH/Composition/` decides real vs mock.
5. **The SwiftTerm import is confined to `AnySSHUI/Terminal/SwiftTerm/`.** Files outside that
   directory see only `TerminalEngine`. A `grep` in `Scripts/lint.sh` enforces it, which is what
   makes "fork SwiftTerm" or "replace SwiftTerm" a bounded change rather than a rewrite.
6. **`TerminalEmulator` contains no emulator.** Doc 02 settles that writing one is a 36,000-line
   problem with a 14,558-line test suite behind it. The target holds the parts that are ours:
   the engine protocol, the output pump, the modifier latch, the key encoders, the scrollback
   budget policy, and the terminal-mode gesture policy. All of it is pure logic and runs in
   `swift test` on the host with no simulator.

Two scaffolding artifacts this document previously scheduled for removal are already gone from
the committed tree: `MultiplexerKind` is `.none`, `.tmux`, `.herdr` with no `.screen`, and
`GitRepositoryRef` has no `statusCommand`. Their phases assert the absence rather than repeat the
removal. Command strings are still never built by interpolating a path, which is the pattern doc
04 §A.10 forbids.

Two imports in the committed tree do violate rule 2 and are fixed when the lint rule is turned
on: `GitClient/GitRepositoryRef.swift` imports `SSHTransport` and
`Multiplexers/MultiplexerKind.swift` imports `Sessions`.

## 3. Ports: the protocols the mock environment depends on

Decision 3 makes the deterministic mock environment a first-class target. That is only
achievable if the seam between "what the app does" and "what the host does" is a small, closed
set of protocols. This is that set. All of it lives in `AnySSHCore/Ports/`, all of it is
`Sendable`, and `AnySSHMocks` supplies a working implementation of every entry.

| Port | Live implementation | Mock implementation | Used by |
|---|---|---|---|
| `RemoteStore` | `FileRemoteStore` (AnySSHCore) | `MockRemoteStore` (exists) | Remotes |
| `SecretStore` | `KeychainSecretStore` | `InMemorySecretStore` | Remotes, auth |
| `HostKeyStore` | `FileHostKeyStore` | `ScriptedHostKeyStore` | Auth, host key UX |
| `ReachabilityProbe` | `NWConnectionProbe` | `ScriptedReachability` | Remotes status |
| `TerminalTransport` + `TerminalTransportDelegate` | `SSHTerminalTransport` | `ScriptedTerminalTransport` | Terminal, Sessions |
| `RemoteCommandRunner` | `SSHCommandRunner` | `ScriptedCommandRunner` | Git, Files, Multiplexers, Capabilities |
| `CapabilityProbe` | `SSHCapabilityProbe` | `FixtureCapabilityProbe` | Capability detection |
| `GitService` | `RemoteGitService` (GitClient) | `FixtureGitService` | Changes, History |
| `BlobService` | `RemoteBlobService` (FileTransfer) | `FixtureBlobService` | Files, diff blobs |
| `MultiplexerAdapter` | `TmuxAdapter`, `HerdrAdapter` | `FixtureMultiplexerAdapter` | Multiplexers |
| `WorkspacePathResolver` | four chained resolvers, section 11 | `FixedWorkspaceResolver` | Git, Files |
| `SyntaxHighlighter` | `TreeSitterHighlighter` (Highlighting) | `PassthroughHighlighter` | Diff, Files |
| `Clock`, `IDProvider` | system | frozen | snapshot determinism |

Three rules keep this honest.

**Mock fixtures are recorded, not written.** `Scripts/record-fixtures.sh` runs the real command
set against `~/Sites/anyssh-testbed` on the live host and writes raw bytes into
`Packages/AnySSHKit/Sources/Fixtures/Data/`, each with a sidecar recording the exact command and
the host git version. Doc 08 built that testbed to mirror the mock scenarios
deliberately, so recorded fixtures make mock and live agree byte for byte. A hand-written
fixture cannot reproduce the rename framing in section 8, which is the single most likely
silent parsing bug in the project.

**Scenario selection is a runtime decision.** `LaunchMode` already reads `-UITestMode` and
`ANYSSH_SCENARIO`, and `AnySSHMocks` links in every configuration. A sideloaded Release build
stays drivable by an agent.

**Every screen is reachable by deep link in mock mode.** `simctl` cannot tap, so
`xcrun simctl openurl` plus `anyssh://` routes is how visual QA reaches a screen without
walking the navigation stack. AXe covers the cases where a tap or a keystroke is the thing
under test, which is most of the hotkey bar.

## 4. `TerminalTransport`, and how mosh and Eternal Terminal slot in later

The abstraction sits at "a resizable, bidirectional byte stream with a lifecycle", exactly as
doc 01 §6 argued, and deliberately not at the SSH channel level. Mosh has no channels.

```swift
public protocol TerminalTransport: Actor {
    nonisolated var kind: TransportKind { get }              // .ssh, .mosh, .eternalTerminal
    nonisolated var capabilities: TransportCapabilities { get }
    var state: TransportState { get }

    func setDelegate(_ delegate: any TerminalTransportDelegate)
    func setSink(_ sink: any ByteSink)                       // see the deviation below
    func start(size: TerminalSize) async throws
    func send(_ bytes: ArraySlice<UInt8>) async throws
    func resize(to size: TerminalSize) async throws
    func close() async
}
```

Four properties carry the whole design.

**Auth is a delegate that awaits.** `keyboard-interactive` is a multi-round conversation with
an arbitrary number of prompts. A credentials struct cannot express it, which is why the
NIOSSH-shaped API is structurally unable to do 2FA. The delegate answers prompts and returns a
host key verdict, and the transport waits.

**`start(size:)` takes geometry up front** because mosh needs it at session establishment
rather than as a follow-up request, and `resize(to:)` is a method rather than an SSH window
change so the mosh implementation can update local state and let the next state-sync datagram
carry it.

**`roaming` and `serverSideResume` are capability bits, not assumptions.** The reconnect UI
reads them. With SSH it says the session will be lost; with mosh it resumes silently. This is
the seam that makes mosh worth adding later, and it must exist before there is a second
transport, because an abstraction designed after the fact is the classic way to get this wrong.

**Optional surfaces stay off the base protocol.** `FileTransferCapable` and
`MultiChannelCapable` are separate, so a mosh transport is never forced to fake them.

Phase 3 deliberately did not declare either one. Both would need an exec-channel type that the
SSH transport phase owns, and declaring them early would have meant inventing that type in
`AnySSHCore` before the phase that defines it. They are declared by whichever phase first needs
them, alongside the channel type, and they are the one sanctioned exception to the rule that all
ports live in `AnySSHCore/Ports/`.

Phase 3 also had to put `SessionRecord` and `MultiplexerKind` in `AnySSHCore/Model/`, because
`WorkspacePathResolver.resolve(_:)` takes a `SessionRecord` and `AnySSHCore` may not import
`Sessions`. `MultiplexerKind` therefore now shadows the one in `Multiplexers`. Harmless while
nothing imports both; the multiplexer adapter phase collapses them.

### Deviation from doc 01 §6: a sink, not an `AsyncThrowingStream`

Doc 01 sketched `outputStream() -> AsyncThrowingStream<Data, Error>`. Doc 05 §6 then established
that `AsyncStream` has no backpressure: `continuation.yield` never suspends, unbounded grows
without limit, and bounded drops silently. A terminal that drops bytes corrupts its own screen
state, because half an escape sequence is worse than none.

So the transport pushes into a sink whose `ingest` is `async` and returns only once the bytes
are accepted:

```swift
public protocol ByteSink: Sendable {
    func ingest(_ bytes: ArraySlice<UInt8>) async
}
```

When the sink is saturated, `ingest` suspends, the transport's read loop suspends with it, the
SSH channel window fills, and the remote process blocks on write. That is the mechanism the
protocol already provides for exactly this problem, and it is what a real tty does. Nothing is
dropped and memory stays bounded by the high-water mark rather than by luck.

### Two connections per remote

Every remote gets a **display transport** and a **control transport**, and they are separate
connections.

The display transport drives the visible terminal and may one day be mosh or ET. The control
transport is always plain SSH and carries every exec channel: git batches, blob fetches,
capability probes, multiplexer polling. Doc 07 §5 documents what happens when this rule is
missing. Moshi hangs its best features off an SSH local forward that mosh cannot carry, then
never reconciles it, so a user on mosh either loses those features or is silently running a
second SSH connection anyway.

Stating it as a rule: **no feature may depend on a channel the display transport cannot
provide.** The cost is one extra authenticated connection per remote. The benefit is that
adding mosh later changes one transport and no features.

Both transports are owned by one `RemoteConnection` actor per remote. Nothing outside it holds a
transport reference; sessions hold a connection id. The control transport is dialled lazily on
first control work and torn down after an idle TTL, and the two reconnect independently, so a
dead control transport does not kill a live terminal and a dead terminal does not abort a git
batch in flight.

`RemoteConnection` is also the cancellation boundary. `cancelAll(reason:)` cancels every
in-flight control task, closes its exec channel and drains it, so nothing leaks against the
four-channel cap or OpenSSH's `MaxSessions`. Every control task runs inside a
`withTaskCancellationHandler` that closes its channel, a cancelled task throws rather than
returning a partial result a caller could mistake for data, and cancellation is idempotent. This
is what makes switching sessions safe: the outgoing session's capability probe, git batch, blob
fetch and multiplexer poll all stop, while its display transport stays alive.

Mosh also depends on the SSH transport for its own bootstrap. It is not a drop-in replacement:
SSH in, run `mosh-server new -s -c 256`, parse `MOSH CONNECT <port> <key>`, then speak UDP. So
the SSH transport's exec path must be usable with no terminal UI attached, which the control
transport already requires.

## 5. The byte path: concurrency and state ownership

This is the performance-critical design in the app and the place where two research documents
disagreed. The resolution is in section 15; the result is here.

> **Corrections from building it.** Phase 6 implemented this section and measured it. Two claims
> below are wrong as written.
>
> - **Rule 3 is wrong that a yield between slices produces coalescing.** With a hot producer the
>   drain interleaves one-to-one and costs a main-actor hop per socket read, which is the exact
>   failure this section exists to prevent. Coalescing needs an explicit gate before each slice:
>   yield until the slice is full or two consecutive yields add nothing. The section's own
>   estimate of "roughly 16 hops for 700 reads" does hold once the gate exists — measured 17,
>   which is the arithmetic minimum.
> - **The memory bound is off by one read.** It is `highWaterMark + maximum socket read`, not the
>   high-water mark. Measured peak 294,267 B against a 512 KB bound.
>
> Measured on an M4 Max, debug build, machine loaded by six concurrent phases: 982 MB/s at 1 KB
> reads rising to 5.6 GB/s at 64 KB, echo latency p50 8.4 µs and p99 38.3 µs, 1020 suspensions
> across a lossless 64 MB run with an identical SHA256, stable over 38 repeats.
>
> One structural consequence: the drain seam is a closure, not a protocol, because the module
> lint rule confines protocol declarations to `AnySSHCore`.

```
  socket                    OutputPump                 SwiftTerm                SwiftUI
  ┌──────────────┐  await   ┌──────────────┐  bounded  ┌──────────────┐ metadata ┌─────────┐
  │ SSHSession   │ ingest() │ actor        │  slices   │ TerminalView │  only,   │ Session │
  │ actor        ├─────────►│ accumulate,  ├──────────►│ + Terminal   ├─────────►│ View    │
  │ libssh2 ptr  │          │ coalesce,    │ @MainActor│ @MainActor   │coalesced │ Model   │
  │ private      │◄─────────┤ backpressure │           └──────────────┘          └─────────┘
  └──────────────┘ suspends └──────────────┘                  │
        ▲                                                     │ keystrokes, resize
        └─────────────────────────────────────────────────────┘
```

### Who owns what

| State | Owner | Isolation | Notes |
|---|---|---|---|
| `LIBSSH2_SESSION*` | `SSHSession` | its own actor | Never escapes the actor. One session per actor. A libssh2 session is not thread-safe and getting this wrong produces heisenbugs that only appear under network jitter. |
| Pending output bytes | `OutputPump` | its own actor | Accumulates off-main, drains on-main in slices. |
| Screen buffer, scrollback, selection | `SwiftTerm.Terminal` | `@MainActor` | SwiftTerm's buffer has no internal synchronisation. There is no lock around `Buffer`, `BufferLine` or `CircularList`, and its types carry no isolation annotations, so Swift 6 will not catch a race here for us. |
| The `TerminalView` instance | `TerminalSurfaceStore` | `@MainActor`, outside the SwiftUI view tree | Section 6. |
| Session title, connection state, bell, capabilities | `SessionViewModel` | `@MainActor`, `@Observable` | The only thing SwiftUI observes. |
| Repo status, diffs, blobs, capabilities | per-remote `ControlSession` actor | its own actor | Runs on the control transport. |
| Parse trees and token caches | `Highlighter` | its own actor | `tree_sitter` `Parser` is not `Sendable`, so one per worker. |

### Rules

1. **Never send a single byte across an isolation boundary.** The unit of transfer is a chunk
   sized to whatever the socket read returned. Parsing 64 KB inside one hop costs one hop;
   parsing it byte by byte across a boundary costs 65,536.
2. **Terminal bytes never touch SwiftUI state.** Not `@State`, not `@Observable`, not a
   binding. The terminal is an opaque UIKit island that SwiftUI positions and never inspects.
   `updateUIViewController` is genuinely empty, which is what makes a parent re-render free.
3. **The pump drains in bounded slices with a yield between them.** 64 KB per turn is the
   starting point and must be measured on device. Too small and hop overhead dominates; too
   large and frames drop. Between slices, `await Task.yield()` lets the run loop draw and take
   touches, so a flood never blocks a tap.
4. **Coalescing is the point.** A megabyte arriving in 700 socket reads becomes roughly 16
   main-actor hops.
5. **Backpressure, never dropping.** Above the high-water mark `ingest` suspends. Writes stay
   available while reads are suspended, so `Ctrl-C` still interrupts a runaway process.
6. **Metadata is throttled.** Title changes arrive per shell prompt. A chatty `PS1` would
   re-render the whole chrome at shell speed, so title, bell and state are coalesced on the
   main actor before they reach the view model.
7. **Resize is debounced on a trailing 80 ms edge.** Rotation and the keyboard animation each
   produce a stream of intermediate sizes. `processSizeChange` already early-outs when the cell
   count is unchanged, but a rotation still crosses several column counts, and each one is a
   window-change on the wire and a full-screen repaint on the host.
8. **Never call `TerminalView.resize(cols:rows:)`.** The public method calls `softReset()`,
   which clobbers terminal modes out from under a running `vim` or `tmux`. Let layout drive
   resizes; that path does not soft-reset.
9. **`EAGAIN` is not an error.** Every libssh2 call in non-blocking mode can return
   `LIBSSH2_ERROR_EAGAIN`, meaning "call me again when the socket is ready". Treating it as
   failure is the classic libssh2 wrapper bug and the reason the NMSSH generation felt flaky.

### Renderer

SwiftTerm with Metal explicitly enabled. `setUseMetal(true)` must be called after the view is
in a window, it throws, and the CoreText path must stay working as a fallback. The `MTKView` is
created paused with `enableSetNeedsDisplay`, so an idle terminal costs nothing. DEC mode 2026
synchronized output is honoured by the display throttle, and there is a 150 ms window after
user input during which redraws bypass the 60 fps throttle so local echo feels immediate.

`metalBufferingMode` defaults to `.perRowPersistent`, which rebuilds only dirty rows. A
full-screen TUI repaints most of the screen every frame and may prefer `.perFrameAggregated`.
It is a one-line runtime switch and it needs a measurement, not an opinion.

### Scrollback budget

A materialised `BufferLine` costs `cols * 24` bytes plus object overhead and never trims, so a
line containing `ls` costs the same as a full-width line. Allocation is lazy, which saves the
eager case, but the risk is N sessions multiplied by scrollback: eight sessions at 10,000 lines
and 120 columns is roughly 230 MB of buffers alone.

Policy: default 5,000 lines, budget globally rather than per session, trim background sessions
to about 1,000 lines with `changeScrollback` on session switch, and trim every background
session to its floor on a memory warning. `CircularList.maxLength` reallocates and copies the
whole pointer array on change, so this is O(scrollback) and belongs on session switch, never
per frame.

## 6. Sessions and surface ownership

A session exists in two halves that live in different modules for a reason.

`Sessions.SessionRegistry` is the model. It holds `SessionRecord` values: id, remote id, title,
`TransportState`, transport capabilities, reconnect attempt count, created and last-active
timestamps, and the resolved workspace location. It is pure, `Sendable`, and fully testable in
`swift test` with no simulator and no UIKit.

`AnySSHUI.TerminalSurfaceStore` is the live half. It maps a session id to its
`{ RemoteConnection, OutputPump, TerminalEngine, UIView }` and it lives outside the SwiftUI
view tree.

> **Correction.** This originally said `TerminalTransport`. A surface holds the whole
> `RemoteConnection` — the display transport and the control transport as one lifetime — not a
> bare display transport. Holding only the display side would leave the control side owned by
> nobody, which is the gap that made the connection pair its own phase in the first place. This is not a style preference. If a `TerminalView` is created inside
`makeUIViewController`, then any change of SwiftUI identity, a different `.id()`, a `ForEach`
reorder, a navigation pop and push, destroys the view and kills the session. The host
controller borrows the view and re-parents it on appear, guarded against rehosting a
still-visible terminal on iPad, which crashes without it.

> **Correction.** This paragraph originally named a `disableFirstResponderDuringViewRehosting`
> API. No such thing exists, in the iOS 26.5 SDK or in SwiftTerm. Phase 7 implemented the guard
> by hand. Three other claims in this section did not survive either: SwiftTerm defers the title
> callback one main-queue turn on iOS where macOS delivers it inline; OSC 7 arrives as a full
> `file://` URI rather than a path; and macOS `TerminalView` exposes only `font`, whose setter
> calls `resetFont()` and triggers the soft-resetting resize this section warns about.

### Reconnect, stated honestly

The reconnect copy is a function of the transport's capability bits, and it is the same string
the session card shows.

| Transport | What the card says |
|---|---|
| SSH | Backgrounding ends this session. Work continues on the host only if it is inside tmux or herdr. |
| SSH attached to a multiplexer | Reattaches on return. Scrollback is preserved on the host. |
| Mosh (later) | Survives sleep and network change. Scrollback from before the drop is lost unless you are in a multiplexer. |

Doc 06 §8 ranks dishonest capability claims, especially around resume, as a recurring complaint
in this category. Being accurate here is cheap and is a real differentiator.

Behaviour: on foreground, if the transport is dead, reconnect immediately and silently, then
show a "Reattached to <session>" confirmation rather than pretending nothing happened. If the
remote has a startup command, run it. `NWPathMonitor` supplies the reconnect trigger for
Wi-Fi to cellular transitions; it is a standalone monitor and is never used to constrain the
connection itself, because tunnelled Tailscale traffic egresses on a `utun` that reports as
`.other` and any `requiredInterfaceType` silently breaks every 100.x connection.

Backgrounding is a `beginBackgroundTask` window that iOS estimates around 30 seconds. That
duration is not a contract and can end earlier. No audio
trick, no VoIP, and no background location mode in MVP. The location toggle is what the
incumbents ship and it does work, but it is a product decision with a battery cost and a review
conversation attached, so it is deliberately deferred rather than discovered late as the only
lever left.

## 7. Remote command execution

Everything that is not the interactive terminal goes through one layer, on the control
transport. Five types, each with one job, and two hazards that exist in exactly one place each.

```
GitCommand / ProbeCommand      value types: subcommand + [String] args. No interpolation.
        |
GitInvocation                  applies the hardened git prefix (section 8)
        |
RemoteBatch                    ordered [(label, command, byteCap?)]
        |
BatchScriptBuilder             renders one POSIX sh script, nonce sentinel, per-command 2>&1
        |                      and exit code capture
LoginShellWrapper              the ONLY place `-lc` appears
        |
RemoteCommandRunner            one exec channel, one round trip
        |
BatchResponseParser            splits on the nonce -> [label: (bytes, exitCode)]
```

**Hazard one: the login shell, and the double quoting it creates.** Decision 14 requires
`$SHELL -lc '<script>'`. The script already contains single quotes because every path inside it
was quoted with the POSIX rule (wrap in single quotes, replace each `'` with `'\''`). So the
wrapper applies the same rule a second time, to the whole script. Two levels of nested
single-quoting is precisely where this ships broken. It is confined to `LoginShellWrapper`,
callers never quote anything themselves, and the test suite round-trips doc 04's pathological
filename (`it's a "trap"; rm -rf tmp; $(whoami) \`id\` \ | & > < * ? ~ñ🎉.txt`) through both
levels and asserts byte equality.

Doc 08 records the trap in its own tooling: a script carrying a `#!/bin/zsh -l` shebang was
piped to `zsh -s` and failed on a missing binary, because the shebang is not consulted when the
script arrives on stdin. Wrapping is explicit or it does not happen.

**Hazard two: framing.** Sections are length-prefixed, and the length is produced by the shell
after the command has exited.

Each command's output goes to a file under one `mktemp -d`. Only once it has exited does the
script emit `\n--<tag>--R<index>:<wc -c>:<exit>\n` followed by the bytes, and the response closes
with `\n--<tag>--Z<count>\n`. The parser scans for a delimiter exactly once, to skip the login
shell's banner before the first record; from there it reads a header, hands over exactly the
counted bytes without looking at them, and demands the next header at the byte immediately after.

The property that matters is that a payload cannot influence a number computed after it is dead.
The tag therefore does not need to be secret, which is the whole point: it is visible in the exec
command, so a server sees it.

This replaces a scheme where a random 128-bit nonce delimited each section. An adversarial review
showed it was forgeable — the server reads the nonce out of the command we send it, so it can
print the exact terminator inside a command's output, truncate the section and report a success
that never happened. A random sentinel defends against accidental collision, not against someone
who knows it. Note what this means generally: secrecy is not available as a defence in anything
the script itself carries, which is also why a MAC cannot work here — any key the script holds is
readable by the process producing the data.

The costs, stated: each section is buffered to remote disk, the host needs `mktemp` and a
writable temp directory (a batch fails closed without them), and a section no longer streams
while its command runs. Round trips are unchanged, which is what decision 11 cares about;
measured against the live host, a five-command 58 KB batch went from 1.01-1.18s to 1.20-1.42s.

The earlier claim that length-prefix framing was unavailable because POSIX shell variables cannot
hold NUL is true only of `$(...)` capture. A file and `wc -c` sidestep it entirely.

Rules the layer enforces:

- One batch per screen. An unbatched command on a hot path is a defect, not a style issue.
- Every command redirects `2>&1` into its own section, so a stderr message lands where it
  belongs instead of interleaving.
- A section capped with `head -c N` exits 141 under `pipefail`. That is success with
  truncation, not failure, and the UI says "showing first N KB" rather than lying.
- Binary blobs never go in a batch. They run on their own dedicated exec channel and are read
  as raw `Data`. SSH channels are 8-bit clean, so base64 is a 33% tax for nothing, and a raw
  NUL stream inside a batch would corrupt the framing.
- Concurrent channels are capped at four. OpenSSH's `MaxSessions` default is 10 and the display
  transport is a separate connection, but leaving headroom costs nothing.

## 8. The git layer

Three concerns, three places, and the two hazards that make git parsing silently wrong are each
encapsulated rather than scattered.

### 8.1 Hardened invocation, in one type

The remote user's `~/.gitconfig` is not under our control and several innocuous settings destroy
machine parsing without any error. `GitInvocation` is the only place a git command line is
constructed, and it always emits:

```sh
git --no-pager -c core.quotePath=false -c color.ui=false -c diff.renames=true \
    -c log.showSignature=false <subcommand> --no-ext-diff --no-textconv \
    --src-prefix=a/ --dst-prefix=b/ ...
```

`--src-prefix` and `--dst-prefix` defeat both `diff.noprefix` and `diff.mnemonicPrefix`.
`--no-ext-diff` is the correct way to disable an external diff driver; writing
`-c diff.external=` does not disable it, it sets it to the empty command and git dies. Every
command that emits a path adds `-z`, which is the only option yielding raw bytes in all cases:
`core.quotePath=false` still quotes a path containing `"` or `\`.

`GitInvocation` also carries the minimum git version each command needs, so capability
detection (section 9) can degrade rather than fail. `cat-file --batch-check -Z` needs 2.36.
Doc 08 measured that a bare exec resolves `git` to Apple's 2.50.1 while the login shell resolves
Homebrew's 2.54.0, which is why the probe reports the resolved path and version rather
than only presence.

### 8.2 Rename framing, in one file

Both `status --porcelain=v2 -z` and `--numstat -z` change their framing for renames, in
different and incompatible ways, and **the path order is reversed between them**. Doc 08
measured both against the testbed's `R100` rename:

```
status v2:  2 R. N... 100644 100644 100644 92f0830 92f0830 R100 <new>NUL<old>NUL
numstat:    0 \t 0 \t NUL<old>NUL<new>NUL          (empty path field signals the rename)
```

Applying one parser's rules to the other's output swaps source and destination, renders the
rename backwards, and raises no error anywhere.

Containment: `GitClient/Parsing/RenameFraming.swift` holds both parsers and nothing else. Its
test is built from those exact bytes, recorded from the live host, not from a hand-written
fixture. Everything downstream consumes `[ChangedFile]`, where `oldPath` and `newPath` are
already correct, and no other file in the project reads a NUL-framed stream.

The rename hazard has a second face. Restricting a per-file diff with a pathspec that names
only the new path destroys rename detection, because git can no longer see the deletion to pair
with the addition, and the file silently reports as a large addition instead. That is contained
in one accessor:

```swift
extension ChangedFile {
    /// The ONLY way a path enters a per-file diff command.
    var pathspec: [String] { change.isRename ? [newPath, oldPath].compactMap { $0 } : [newPath ?? oldPath!] }
}
```

### 8.3 Diff parsing and highlighting

We write the unified diff parser. No mature Swift one exists: the two older packages are eight
years stale and the maintained pre-1.0 option documents only file headers, hunk headers and
add/delete/context, none of the cases our command catalog actually produces.

It is a line-oriented state machine over `[Substring]`. Points that matter: tolerate `\r\n`
framing but never strip `\r` from content, because a CRLF file legitimately contains it; decode
UTF-8 lossily and flag the file rather than dropping a whole diff; parse the hunk header by
locating the second ` @@` from the left, because the trailing section heading is free text and
may itself contain `@@`; accept files with no hunks at all (mode-only changes and binary stubs);
validate consumed line counts against the header and surface a mismatch as truncation rather
than rendering wrong line numbers.

**The patch text is content. The `-z` streams are the authority on paths.** The `+++ b/path`
line is absent for mode-only and binary changes and says `/dev/null` for adds and deletes, and
`rename from` / `rename to` lines are not NUL-framed. This is a significant simplification and
it is why section 8.2 exists.

Combined diffs are recognised and refused in v1. Merge commits are fetched with
`-m --first-parent`, which yields an ordinary two-way diff the standard parser handles, and is
also the more useful default: it answers "what did this merge bring in".

Highlighting follows the settled industry answer: **parse the full blob and slice the result
into hunks**, never lex a hunk in isolation. A hunk can inherit an open comment, an unterminated
template literal or an open tag from lines that are not in the payload. GitHub, GitHub Desktop
and GitLab all fetch the file; `delta` lexes per hunk and its bug about exactly this has been
open since 2020. We are a git client, so both blobs are one command away and fold into the same
batch.

Concretely, opening a file diff is one round trip:

```
emit PATCH;  git ... diff ... -- <new> [<old>]
emit BLOB_A; git ... cat-file blob <oldsha> | head -c 262144
emit BLOB_B; git ... cat-file blob <newsha> | head -c 262144
```

Skip the unused side for all-addition or all-deletion files. Cache tokens keyed by blob sha,
which is content-addressed and therefore never stale.

### 8.4 Size discipline

Three layers, in order. Never fetch a patch that has not been sized: `--numstat -z` is one short
line per file and is always safe. Size a blob before fetching it with `cat-file --batch-check -Z`,
which reports type and size without transferring content and batches many queries into one round
trip. Cap bytes on the remote side, because capping in Swift after reading is useless.

Caps: 256 KB per diff payload and per blob side, 2 MB for the source viewer, 25 MB for an image,
50 MB for a video. `cat-file blob` returns the raw object and bypasses smudge filters, so an LFS
repo yields the roughly 130-byte pointer text; detect that shape and say so.

### 8.5 Failure modes with a named UI state

Not a repo (non-zero exit from `rev-parse --show-toplevel`, never string-match the localised
message), unborn branch (`# branch.oid (initial)`), detached HEAD (`# branch.head (detached)`),
no upstream (`# branch.ab` absent entirely, which is a different state from zero ahead zero
behind), merge in progress (`u` records present), git missing (exit 127), rename limit exceeded,
LFS pointer, truncated diff, submodule entry.

## 9. Capability detection

One batched probe per connection, through `$SHELL -lc`, producing a `HostCapabilities` value
cached per remote and invalidated on reconnect.

The probe answers what is installed, **where**, and at what version. Doc 08 showed those are
three different questions with three different failure modes. Under a bare exec, `tmux`,
`claude` and `codex` all report missing although they are installed, and `git` silently resolves
to a binary four minor versions behind the one the user works with. The second failure produces
no error anywhere.

```
$SHELL, uname -sm, locale
command -v git tmux herdr        -> resolved absolute paths
git --version, tmux -V
herdr status client --json       -> version, protocol, binary, session
$HOME, and the login-shell PATH itself (recorded for diagnostics)
```

The probe result drives four things: which toolbar the terminal shows, whether the Changes tab
exists at all, which git commands are available, and the diagnostic text when something is
missing. Herdr additionally carries a protocol number, currently 19, and the adapter refuses to
speak to a protocol it does not know rather than guessing at field shapes.

A regression test asserts the difference: the same probe run as a bare exec and as a login shell
must disagree on this host, and the login-shell result must be the one used. That test is the
guard against someone "simplifying" the wrapper away later.

## 10. `MultiplexerAdapter`: tmux and herdr under one protocol

tmux has sessions, windows and panes. Herdr has workspaces, tabs and panes, plus a first-class
agent object, a JSON API and worktree metadata. The protocol is capability-based rather than
lowest-common-denominator, and it normalises the topology onto tmux's three levels because that
is the shape the UI renders.

```swift
public protocol MultiplexerAdapter: Sendable {
    nonisolated var kind: MultiplexerKind { get }               // .tmux, .herdr
    nonisolated var capabilities: MultiplexerCapabilities { get }

    func detect() async throws -> MultiplexerInfo               // version, protocol, binary path
    func listSessions() async throws -> [MuxSession]
    func snapshot(_ session: MuxSession.ID) async throws -> MuxSnapshot   // groups + panes + cwd
    func readPane(_ pane: MuxPane.ID, lines: Int) async throws -> String
    func keyBindings() async throws -> MuxKeyBindings           // discovered, never assumed
    func attachCommand(_ target: MuxTarget) -> String           // written into the display transport
}
```

| Capability | tmux | herdr |
|---|---|---|
| `structuredOutput` | no, format strings | yes, JSON envelopes |
| `agentStatus` | no | yes, `agent_status` on `PaneInfo` |
| `worktreeMetadata` | no | yes, `WorkspaceInfo.worktree.repo_root` |
| `paneRead` | `capture-pane -p` | `pane read --source recent-unwrapped` |
| `eventStream` | no | **no over exec.** `events.subscribe` exists in the socket schema, but the installed CLI exposes no `events` command. A direct Unix-socket client could subscribe; SSH exec cannot. Both adapters poll. |
| `detachSurvival` | yes | **partly proven.** Doc 08 measured a named session surviving an abrupt SSH disconnect. A server herdr starts as part of our own connection, and behaviour on any other host or version, remain unverified. |

Four design consequences.

**Attach is bytes, not a channel.** The adapter returns a command string that the session writes
into the display transport, so attaching is the same mechanism as typing it. Nothing about attach
needs a second connection or a second code path.

**Key bindings are discovered.** Both tools let the user rebind the prefix, and doc 03 found this
is not hypothetical: the research machine's herdr config has `new_tab=prefix+t`, not the
documented `prefix+c`. The context-aware toolbar emits chords from `keyBindings()`
(`tmux show-options -gv prefix` for tmux, the parsed config for herdr), never from a hardcoded
table. A toolbar that sends the wrong chord into a live agent pane is worse than no toolbar.

**Detach survival is three values, not one, and each is stated at the confidence it has.** Doc 08
verified rather than assumed the first: a named session was created over a PTY, the SSH
connection was killed abruptly at ten seconds (`timeout 10`, exit 124, no clean shutdown), and a
fresh connection still reported the session running with its own socket under
`~/.config/herdr/sessions/<name>/`. So:

| Value | Status | What the card may say |
|---|---|---|
| `localSessionSurvival` | proven on herdr 0.8.0, protocol 19 | Reattaches on return, like tmux |
| `remoteBootstrapSurvival` | unverified | A server AnySSH started may not survive; the binary warns about this itself |
| `crossHostSurvival` | unverified | One host, one version measured |

The correctness statement stands where it applies: the reconnect copy must not imply survival for
the two unverified cases. It must no longer deny it for the measured one.

**The no-multiplexer path is the default and is built first.** Doc 08's open items record herdr
absent from the live host while its measured section records herdr 0.8.0 installed and running
there mid-session, so the host's multiplexer inventory is not a stable fact to build on. The
zero-multiplexer path is exercised before either adapter regardless, which is the useful part;
tests assert parser correctness against recorded fixtures and record rather than assert what the
live host currently has.

Polling cadence: 1 s while the multiplexer screen is visible, 5 s in the background of a live
session, never while suspended. Moshi polls pane text at 250 ms; that is aggressive for a phone
on cellular and buys nothing for a topology list.

## 11. The `WorkspacePathResolver` family

"Which repository am I looking at" is the question the Changes screen and the file browser both
depend on, and getting it silently wrong is worse than failing. Four sources answer it with
different confidence, so the resolver is a chain with recorded provenance.

```swift
public protocol WorkspacePathResolver: Sendable {
    func resolve(_ session: SessionRecord) async -> WorkspaceLocation?
}

public struct WorkspaceLocation: Sendable, Equatable {
    public let path: String
    public let provenance: Provenance     // .multiplexer, .shellIntegration, .process, .default, .userOverride
}
```

| Resolver | Source | Confidence |
|---|---|---|
| `MultiplexerPathResolver` | herdr `foreground_cwd ?? cwd`, and `workspace.worktree.repo_root` when present; tmux `#{pane_current_path}` | highest when a multiplexer is attached |
| `ShellIntegrationPathResolver` | OSC 7 from the terminal stream | free and live, but only if the user's shell emits it |
| `ProcessPathResolver` | resolve the session shell pid, then `lsof -d cwd` on macOS or `/proc/<pid>/cwd` on Linux | costs a round trip, always available |
| `DefaultPathResolver` | the remote's configured start path, else `$HOME` | last resort |

`ChainedWorkspacePathResolver` takes the first non-nil answer and records which resolver
produced it. `GitRootResolver` then turns a location into a `RepositoryRef` with
`rev-parse --show-toplevel` and `--git-dir`, folded into whatever batch is already going out,
and caches per (remote, path).

Two properties this buys. The UI can show the resolved path and where it came from, so a user
who is looking at the wrong repo can see why in one tap and override it. And adding a resolver
later, for example when herdr support lands after the git screens, is a new file conforming to
the same protocol, with no change to any consumer.

Doc 03 flags an unknown: the herdr schema does not define whether `cwd` means the shell's
startup directory and `foreground_cwd` the current foreground process directory. The fallback
`foreground_cwd ?? cwd` is correct under either reading, and `worktree.repo_root` outranks both
when present.

## 12. Highlighting

`Highlighting` is a new target wrapping `tree-sitter/swift-tree-sitter`. It implements one port:

Neon was dropped in Phase 2 and is not a dependency. It still depends on
`ChimeHQ/SwiftTreeSitter` by branch; that URL redirects to `tree-sitter/swift-tree-sitter` but
keeps a separate SwiftPM identity, so resolving both fails with duplicate `SwiftTreeSitter` and
`SwiftTreeSitterLayer` targets. Neon contributed incremental invalidation and a highlight-query
cache, both of which this target now owns directly. That is acceptable because our workload is
one-shot highlighting of an immutable blob rather than an editor's per-keystroke reparse.

```swift
public protocol SyntaxHighlighter: Sendable {
    /// GitHub's compact wire format: per-line token ranges, not attributed text.
    func tokens(for blob: String, language: LanguageID) async -> [LineTokens]
}
```

`LineTokens` is `[(range: Range<Int>, scope: TokenScope)]` per line. It decouples highlighting
from rendering and maps directly onto `AttributedString` ranges, a diff row's two gutters, and
the file viewer, without any of them knowing what a parse tree is.

Three tiers, and the middle one is the default:

- **Tier 0**, instant: `+` and `-` row tinting with no token colouring. Line-level colouring
  carries most of the perceived value. GitHub ships exactly this first, then swaps colour in.
- **Tier 1**, correct: both blobs, capped at 256 KB per side, parsed off-main, sliced by line
  range into hunks, cached by blob sha. Measured at roughly 3 ms for 1,185 lines and 22 ms for
  12,447, so it is cheap enough to be the default whenever blobs are reachable, which for a git
  client is always.
- **Tier 2**, fallback: hunk text alone when a blob exceeds the cap or is unreachable, marked
  internally so a mis-colour is a known bounded condition. tree-sitter's error recovery keeps
  ERROR nodes local, which is why this tier is viable at all and why a stateful line lexer would
  be worse here, not better.

Implementation constraints, each verified in doc 04 §C: require tree-sitter 0.25 or newer so ABI
15 grammars load; pin Swift to `alex-pinkus/tree-sitter-swift` tag `0.7.3-with-generated-files`
because upstream's repo is archived and the live one commits `parser.c` only on that branch;
drop SQL or source it pre-generated, because `DerekStride/tree-sitter-sql` never commits
`parser.c` and SwiftPM cannot run the tree-sitter CLI; strip the `+`, `-` and space marker column
before feeding any text to a grammar; confine `Parser` to an actor since it is not `Sendable`.

Ship eight grammars first: Swift, TypeScript, JavaScript, Python, Go, JSON, YAML, Markdown.
That is roughly 6.6 MB installed and 0.7 MB downloaded. Swift alone is a third of the full
13-grammar bundle. Quote the download figure or the installed figure deliberately; they differ
by 9x because parse tables are about 92% compressible.

Highlightr and every other highlight.js wrapper are out. Highlightr formally deprecated itself
in 2026, third-party iOS apps get no JIT for in-process JavaScriptCore, and each
`JSVirtualMachine` costs roughly 12 MB and serialises across threads.

## 13. File viewers

All of them share one shape: fetch the blob on the control transport with a size guard, decode
off-main, render natively. None of them is a web view.

| Type | Renderer | The thing that will bite |
|---|---|---|
| Source | `SyntaxHighlighter` + a plain text view | Nothing beyond the caps. |
| Image | ImageIO thumbnail decode, never `UIImage(data:)` | `UIImage(data:)` decompresses at full native resolution when rendered, so an 8000x6000 PNG costs 192 MB to show in a thumbnail. `kCGImageSourceThumbnailMaxPixelSize` must be set in **pixels**, and omitting it while `...FromImageAlways` is true produces a full-size thumbnail, defeating the point. |
| Image diff | 2-up, swipe, onion skin | Different dimensions is the commonly botched case. Compute the union bounding box and letterbox both anchored top-left. Never scale one image to match the other, which fabricates a difference that is not in the data. `.blendMode(.difference)` needs an explicit backdrop and `.compositingGroup()`, and `.mask(alignment: .leading)` is required or the reveal grows from the middle. |
| SVG | SwiftDraw | There is no runtime SVG support on iOS 26. Asset-catalog SVG is a build-time conversion and is categorically inapplicable to bytes arriving from a git object. CoreSVG is private and is not an option. SwiftDraw is immune by construction to script, `foreignObject`, remote refs and external entities, because it has no JS engine and no network stack; guard resource exhaustion with a 256 KB cap and an off-main parse with a timeout, and fall back to raw source, which is useful anyway. |
| Video | Download to a temp file, then play | Streaming is not available to us. `git cat-file blob` is a sequential stream from offset 0 with no byte ranges, and a non-faststart MP4 puts `moov` at the end, so AVFoundation's first request is for the tail. Gate on extension before downloading (`.mkv` and `.webm` are unplayable containers regardless of codec), size-gate at 25 MB auto and 100 MB refuse, stream straight to disk with the correct extension, delete on dismissal. |
| Markdown | `LiYanan2004/MarkdownView` 3.x | There is no native block-markdown renderer on iOS 26: `.full` parsing produces correct `presentationIntent`, and SwiftUI's `Text` ignores it entirely. MarkdownView's image loader dispatches by URL scheme, so relative image links are rewritten to `anyssh://` and route into an SSH fetch while `https://` links keep the default renderer. It pulls Highlightr, so its code-block renderer is overridden with ours and the dependency exclusion is an open task. |
| JSON | Highlighted text by default | Never `OutlineGroup`. It is not lazy about children: it recurses the entire structure at construction, including collapsed and off-screen nodes, so a large file materialises every node on first display. Maintain a flattened `[FlatRow]` array where expanding splices children in, so row count equals visible nodes. `.sortedKeys` is destructive to author intent and belongs behind an explicit Format action. |

Markdown, JSON and image viewers sit behind small protocols in `AnySSHUI` so a renderer swap is
contained. That matters most for MarkdownView, which is a single-maintainer package that shipped
a hard breaking 3.0 in July 2026.

## 14. Determinism

Snapshot references are only stable if everything that can vary is frozen: the injected `Clock`,
a fixed `IDProvider`, fixed locale and time zone, `.animation(nil)`, an explicit `colorScheme`,
and a bundled font rather than a system font that can be re-hinted between OS releases. A
terminal view is almost entirely text, so font rendering is the dominant snapshot risk in this
app specifically.

Record on one device and OS and assert on the same one. The SDK-to-runtime override that
`make doctor` owns turns out to be an asset here: the runtime cannot silently move under us.
Set both `precision` and `perceptualPrecision`, because setting only the second leaves the first
at 1.0 and the assertion still fails. Snapshot components in fixed states, never a whole screen,
so a navigation-bar change does not invalidate hundreds of images. Keep `record: .never` for
normal runs so a missing snapshot is a failure.

Accessibility identifiers are API. Every interactive view has one, following the existing
`remote.*`, `session.*`, `terminal.*`, `git.*` convention in `UIIdentifier`, never derived from
display text and never localised. This is what lets AXe target an element by selector instead of
by coordinate, which is the only way the hotkey bar's modifier states can be exercised at all.

## 15. Where the research disagrees, and what wins

Eight conflicts, each resolved above. They are collected here so nobody re-opens one.

**1. Who writes the terminal emulator.** Doc 05 §2 specifies a `TerminalEmulator` target
containing a VT parser and screen buffer with "hundreds of tests". Doc 02 measures the same
thing at 36,100 production lines plus 14,558 test lines and recommends SwiftTerm.
**Doc 02 wins.** The line count is not the hard part; the decade of xterm edge cases encoded in
those tests is. Doc 05's module boundary survives with a different payload: the target keeps the
engine protocol, output pump, input encoders and budget policy, and remains UIKit-free and Tier
1 testable, which was the actual point of the boundary.

**2. Where terminal bytes are parsed.** Doc 05 §6 puts the parser in its own actor off the main
thread, with the UI pulling a coalesced snapshot at 60 Hz. Doc 02 §10 establishes that
SwiftTerm's buffer has no internal synchronisation and that feeding it off-main while the main
thread draws is a data race Swift 6 cannot catch, because the types carry no isolation
annotations. **Doc 02 wins, because we adopted its emulator.** Parsing runs on the main actor in
bounded slices. Doc 05's snapshot-pull model does not apply, because SwiftTerm renders itself
through Metal or CoreText and there is no screen state for us to publish. Only metadata crosses
into SwiftUI, which preserves doc 05's real requirement: main-actor cost per frame, not per byte.

**3. What to do when output outruns the renderer.** Doc 02's pump drops the oldest bytes past a
4 MB high-water mark to avoid an out-of-memory kill. Doc 05 §6 states that a terminal which drops
bytes corrupts its own screen state and that backpressure belongs in the SSH channel window.
**Doc 05 wins.** Suspending the read loop bounds memory just as effectively as dropping does, and
loses nothing, because the remote process blocks on write exactly as it would against a real tty.
The high-water mark stays; its effect changes from discard to suspend.

**4. Whether the transport vends a stream.** Doc 01 §6 sketches
`outputStream() -> AsyncThrowingStream<Data, Error>`. Doc 05 §6 shows `AsyncStream` has no
backpressure in either configuration. **Doc 05 wins**, and the protocol takes a `ByteSink` whose
`ingest` is `async`. Everything doc 01 wanted from the abstraction, in particular surviving a
mosh swap, is unaffected.

**5. How long a backgrounded session lives.** Doc 06 §4 quotes the Blink developer at about three
minutes. Doc 01 §5.1 puts it at roughly 30 seconds, citing Apple DTS, and corroborates with
La Terminal's and Termius's own documentation. **Doc 01 wins.** The three-minute figure comes
from a 2016 forum thread and the old three-minute and ten-minute allowances are gone. Decision 9
already encodes that estimate; the UI copy in section 6 follows it.

**6. Round-trip latency, and therefore the value of batching.** Doc 04 §A.0 justifies batching
with 200 to 900 ms DERP-relayed round trips. Doc 08 measured 149 ms on a first ICMP packet over a
direct same-LAN Tailscale path and explicitly flags that number as unmeasured under load.
**Doc 08 wins on the fact**, and decision 11 is binding regardless, so batching stays. But the
justification is currently unmeasured on this link, so the plan carries an explicit task to
measure batched versus unbatched round trips against the real host and record the result.

**7. Rename framing.** Doc 04 §A.4 and §A.5 derive the two framings from a test repo on git
2.50.1. Doc 08 confirms both against git 2.54.0 on the live host and emphasises that the path
order is reversed, not merely formatted differently. **They agree, and doc 08 supplies the
bytes.** The test fixture is doc 08's recorded output, because that is what the parser will
actually see.

**8. Herdr's readiness to be validated.** Doc 03 researched herdr 0.8.0 on the development Mac
and produced a full adapter surface. Doc 08 found herdr absent from the live test host in its
open items, then installed it mid-session and measured it: `api snapshot` as the single
structured call, `foreground_cwd` per pane, and a named session surviving an abrupt SSH
disconnect. **Doc 08 wins on sequencing and on the survival fact.** The no-multiplexer path is
built first, tmux 3.6a is the first adapter validated live, the herdr adapter is developed
against recorded fixtures, and its detach survival is modelled as the three values in section 10
rather than as a single unknown.

One more, not a conflict but a correction inside a single line of work: doc 06 §7 records that
Moshi has no git history view; doc 07 §8.1 corrects that to "no log or graph, but a Browse tab
that can address a past commit". Doc 07 wins. It narrows our differentiation claim slightly and
changes nothing in the design.

## 16. Proposed additions to `docs/DECISIONS.md`

Not applied here. These are proposed rows for that file, continuing its numbering and format.

| # | Decision | Status | Rationale | Date |
|---|----------|--------|-----------|------|
| 15 | The terminal emulator is SwiftTerm with the Metal renderer explicitly enabled, consumed through a `TerminalEngine` protocol, with the SwiftTerm import confined to `AnySSHUI/Terminal/SwiftTerm/` | decided | Writing one is 36,100 production lines against a 14,558-line xterm conformance suite. SwiftTerm is MIT, shipped eleven releases in 2026, and is already in commercial App Store SSH clients. Confining the import is what makes a fork or a replacement a bounded change | 2026-08-11 |
| 16 | Terminal bytes are parsed on the main actor, in bounded slices, with a yield between them | decided | SwiftTerm's `Buffer`, `BufferLine` and `CircularList` have no internal synchronisation and carry no isolation annotations, so feeding off-main while drawing on-main is a race Swift 6 cannot catch. Slicing plus yielding keeps the main thread available for touches during a flood | 2026-08-11 |
| 17 | The byte path applies backpressure and never drops bytes. Above the high-water mark the sink suspends and the read loop suspends with it | decided | Dropping corrupts emulator state, because half an escape sequence is worse than none. Suspending lets the SSH channel window fill so the remote process blocks on write, which is what a real tty does, and bounds memory just as well | 2026-08-11 |
| 18 | The transport pushes into an `async` `ByteSink` rather than vending an `AsyncStream` | decided | `AsyncStream` has no backpressure in either configuration: `yield` never suspends, unbounded grows without limit, bounded drops silently | 2026-08-11 |
| 19 | Every remote gets two connections: a display transport for the terminal and a control transport, always plain SSH, for every exec channel | decided | No feature may depend on a channel the display transport cannot provide. Mosh cannot carry a local forward or an exec channel, and Moshi's failure to separate these is why its best features are undefined on its own recommended transport | 2026-08-11 |
| 20 | `AnySSHCore` is the ports module. Every protocol the mock environment implements lives there with its `Sendable` value types; every other module is an adapter and never appears in another adapter's imports | decided | It is what lets `AnySSHMocks` depend on `AnySSHCore` alone, stay linked in every configuration, and keep `Package.swift` frozen after the dependency phase | 2026-08-11 |
| 21 | Mock fixtures are recorded from `~/Sites/anyssh-testbed` on the live host, not hand-written | decided | The rename framing and the NUL streams cannot be reproduced by hand with confidence, and the testbed was built to mirror the mock scenarios so live and mock runs stay comparable | 2026-08-11 |
| 22 | `-lc` appears in exactly one type, POSIX single-quoting in exactly one function, and the two rename parsers in exactly one file | decided | Each of the three is silent when wrong. The login shell wrapper nests two levels of single-quoting, and the status and numstat rename records order their paths oppositely, so a copy-pasted parser renders a rename backwards with no error | 2026-08-11 |
| 23 | tmux and herdr sit behind one capability-based `MultiplexerAdapter`; prefix key bindings are discovered at runtime, never assumed; herdr's detach survival is modelled as three values, of which only local named-session survival is proven | decided | Both tools let the user rebind the prefix and the research machine already had a non-default herdr binding. Sending a wrong chord into a live agent pane is worse than offering no toolbar. Doc 08 measured a named session surviving an abrupt disconnect, so a blanket "unknown" is wrong; a server herdr starts on our behalf is still unverified, and its own binary warns about that case | 2026-08-11 |
| 24 | Diffs and file views are native SwiftUI, never a web view on a loopback port | decided | It is what unlocks word-level intra-line highlighting, per-view font size, Nerd Font coverage, Dynamic Type and native gestures, and it removes the WebKit content-process jettison failure that blanks a terminal while the session underneath is still alive | 2026-08-11 |
| 25 | MVP ships no background location mode. The backgrounding promise is the honest 30-second window plus fast silent reconnect | provisional | The location toggle is what every incumbent ships and it does pass review, but it costs battery, shows the indicator, and is a product decision. Deferring it deliberately beats discovering it late as the only remaining lever | 2026-08-11 |
| 26 | The libssh2 xcframework is produced by a script in `Vendor/`, from a pinned `master` commit at or after `97acf3df`, with a recorded checksum, and re-vendoring is a rehearsed drill | decided | Decision 8 already commits us to `master`. This makes the standing obligation concrete: without a reproducible build and a practised drill, the next CVE lands on an unowned pipeline | 2026-08-11 |

