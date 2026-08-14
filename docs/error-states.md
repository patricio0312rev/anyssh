# Error states

Every failure, refusal and dead end the app can put in front of a user, with a stable identifier,
the exact words it shows, and the deep link that reaches it. Written before the features that
produce them, so a feature phase consumes this registry instead of inventing copy.

`Packages/AnySSHKit/Sources/AnySSHCore/Diagnostics/` declares the same states in code.
`swift test --filter ErrorStateTests` parses this file and fails when the two disagree in either
direction: a case with no row, a row with no case, or one word out of place in any column. Change
the copy here and in the enum in the same commit, or the suite breaks.

## Reading a row

| Column | Meaning |
|---|---|
| stateID | API. `group.name`, matching `^[a-z]+\.[a-z][a-zA-Z]+$`, never derived from display text and never localised. Renaming one breaks its deep link, its identifier and its recorded screenshot at once. |
| identifier | The accessibility identifier on the view that presents the state, always `error.<stateID>`. AXe targets elements by selector, so flow tests assert on this rather than on words. |
| title | What happened, in a few words. No trailing period. |
| body | What to do about it. Active voice, no apology, no vagueness. |
| recovery | The label on the primary action. |
| phase | The phase of `docs/plan-anyssh-mvp.md` that builds the screen this state appears on. |
| artifact | Where the Phase 48 sweep writes this state's screenshot, relative to the repository root. |

Every state has a deep link, `anyssh://error/<stateID>`, resolved by `ErrorStateTrigger` in
`AnySSHMocks/Diagnostics/` in both directions: link for a state, state from an opened URL. The
route exists because `simctl` can open a URL but cannot tap, so this is how visual QA reaches a
state without walking the navigation stack.

The app does not open URLs yet. `ErrorStateTrigger` is the resolver, not the entry point: the
`anyssh://` scheme has to be declared in the app's `Info.plist` and the opened URL handed to
`ErrorStateTrigger.state(from:)` by the composition root before
`xcrun simctl openurl booted anyssh://error/trust.firstUse` shows anything. That wiring belongs
to the phase that builds the screen the state appears on, and each of those phases already has a
flow test that needs it.

## Copy rules

Say what went wrong and what to do about it. Active voice. No apologies, no exclamation marks, no
"something went wrong". Name the thing that failed and the thing the user can change. Where a
state is not a failure at all, an unborn branch or a host without tmux, the body explains the
consequence rather than implying something broke. `ErrorStateTests` enforces the mechanical part
of this: no exclamation marks, no apology words, titles without a trailing period, bodies with one.

## States

| stateID | identifier | title | body | recovery | phase | artifact |
|---|---|---|---|---|---|---|
| `transport.connectionRefused` | `error.transport.connectionRefused` | Connection refused | Nothing is listening on that port. Check the port and that sshd runs on the host. | Edit Host | 9 | `.build/artifacts/errors/transport.connectionRefused.png` |
| `transport.hostUnreachable` | `error.transport.hostUnreachable` | Host unreachable | No route to this host. Check that Tailscale is connected and the host is awake. | Try Again | 9 | `.build/artifacts/errors/transport.hostUnreachable.png` |
| `transport.dnsFallback` | `error.transport.dnsFallback` | Name lookup failed | The hostname did not resolve. This connection used the last known Tailscale address instead. | Edit Host | 9 | `.build/artifacts/errors/transport.dnsFallback.png` |
| `transport.tailscaleSSH` | `error.transport.tailscaleSSH` | Tailscale SSH host | This host authenticates through Tailscale rather than with a key or a password. Connect as a user your Tailscale policy allows. | Connect | 9 | `.build/artifacts/errors/transport.tailscaleSSH.png` |
| `transport.keepaliveTimeout` | `error.transport.keepaliveTimeout` | Connection timed out | The host stopped answering keepalives and the session ended. Reconnect to start a new one. | Reconnect | 9 | `.build/artifacts/errors/transport.keepaliveTimeout.png` |
| `transport.cancelledBySwitch` | `error.transport.cancelledBySwitch` | Request cancelled | Switching sessions cancelled this request. Nothing on the host changed. | Try Again | 13 | `.build/artifacts/errors/transport.cancelledBySwitch.png` |
| `auth.publicKeyRejected` | `error.auth.publicKeyRejected` | Key rejected | The host refused this key. Add its public half to authorized_keys on the host, or choose another key. | Choose Another Key | 11 | `.build/artifacts/errors/auth.publicKeyRejected.png` |
| `auth.passwordRejected` | `error.auth.passwordRejected` | Password rejected | The host refused this password. Check the username as well, since a wrong user fails the same way. | Try Again | 11 | `.build/artifacts/errors/auth.passwordRejected.png` |
| `auth.keyboardInteractiveCancelled` | `error.auth.keyboardInteractiveCancelled` | Verification cancelled | The host asked for a verification code and none was sent. Connect again when you have the code. | Connect | 11 | `.build/artifacts/errors/auth.keyboardInteractiveCancelled.png` |
| `auth.keyboardInteractiveTimedOut` | `error.auth.keyboardInteractiveTimedOut` | Verification timed out | The host closed the connection while waiting for the verification code. Connect again and enter it sooner. | Connect | 11 | `.build/artifacts/errors/auth.keyboardInteractiveTimedOut.png` |
| `auth.wrongPassphrase` | `error.auth.wrongPassphrase` | Wrong passphrase | That passphrase did not decrypt the private key. Enter it again. | Try Again | 11 | `.build/artifacts/errors/auth.wrongPassphrase.png` |
| `trust.firstUse` | `error.trust.firstUse` | Unknown host | This is the first connection to this host. Compare the fingerprint with the one on the host before you accept it. | Accept | 10 | `.build/artifacts/errors/trust.firstUse.png` |
| `trust.rejected` | `error.trust.rejected` | Host key rejected | The connection closed. Nothing about this host was saved, so the next attempt asks again. | Dismiss | 10 | `.build/artifacts/errors/trust.rejected.png` |
| `trust.hostKeyChanged` | `error.trust.hostKeyChanged` | Host key changed | This host offers a different key from the one recorded. Verify the new fingerprint on the host itself before trusting it. | Cancel | 10 | `.build/artifacts/errors/trust.hostKeyChanged.png` |
| `trust.cancelled` | `error.trust.cancelled` | Trust check cancelled | The connection closed without a decision. The next attempt asks again. | Try Again | 10 | `.build/artifacts/errors/trust.cancelled.png` |
| `secrets.keychainWriteDenied` | `error.secrets.keychainWriteDenied` | Keychain write denied | The system refused to save this secret. Unlock the device and try again. | Try Again | 15 | `.build/artifacts/errors/secrets.keychainWriteDenied.png` |
| `secrets.keychainReadDenied` | `error.secrets.keychainReadDenied` | Keychain read denied | The system refused to read this secret. Unlock the device and try again. | Try Again | 15 | `.build/artifacts/errors/secrets.keychainReadDenied.png` |
| `secrets.biometricCancelled` | `error.secrets.biometricCancelled` | Authentication cancelled | The key stays locked until you authenticate. Try again to unlock it. | Try Again | 15 | `.build/artifacts/errors/secrets.biometricCancelled.png` |
| `secrets.biometricUnavailable` | `error.secrets.biometricUnavailable` | Biometrics unavailable | Face ID or Touch ID changed on this device, so the stored key can no longer be read. Import the key again. | Import Key Again | 15 | `.build/artifacts/errors/secrets.biometricUnavailable.png` |
| `secrets.migrationFailed` | `error.secrets.migrationFailed` | Stored data not migrated | Saved hosts and secrets are in a format this version does not read. Nothing was changed. | Try Again | 15 | `.build/artifacts/errors/secrets.migrationFailed.png` |
| `secrets.publicKeyOffered` | `error.secrets.publicKeyOffered` | That is a public key | This is the public half, the part that belongs on the host. Import the private half, the file without the .pub extension. | Paste | 16 | `.build/artifacts/errors/secrets.publicKeyOffered.png` |
| `secrets.keyFormatUnrecognised` | `error.secrets.keyFormatUnrecognised` | Key format not recognised | A private key file opens with a BEGIN line naming OPENSSH or RSA. Nothing was read from what you pasted. | Paste | 16 | `.build/artifacts/errors/secrets.keyFormatUnrecognised.png` |
| `secrets.keyTruncated` | `error.secrets.keyTruncated` | Key is incomplete | This key stops before its end line, so part of it is missing. Copy the whole file and import it again. | Paste | 16 | `.build/artifacts/errors/secrets.keyTruncated.png` |
| `secrets.keyUnreadable` | `error.secrets.keyUnreadable` | Key could not be read | This key has an envelope but its body did not decode. Copy the whole file and import it again. | Paste | 16 | `.build/artifacts/errors/secrets.keyUnreadable.png` |
| `secrets.keyTooLarge` | `error.secrets.keyTooLarge` | File is too large for a key | A private key is a few kilobytes. Nothing was read from this file. Choose the key itself rather than an archive that holds it. | Choose File | 16 | `.build/artifacts/errors/secrets.keyTooLarge.png` |
| `secrets.keyMissing` | `error.secrets.keyMissing` | Nothing to import | No key text was found. Copy a private key and paste it, or choose the file it lives in. | Paste | 16 | `.build/artifacts/errors/secrets.keyMissing.png` |
| `git.missing` | `error.git.missing` | Git not found | The host has no git on its login shell PATH. Install it, or add it to that PATH. | Check Again | 28 | `.build/artifacts/errors/git.missing.png` |
| `git.notARepository` | `error.git.notARepository` | Not a git repository | The session's directory is not inside a git working tree. Move to one and check again. | Check Again | 33 | `.build/artifacts/errors/git.notARepository.png` |
| `git.unbornBranch` | `error.git.unbornBranch` | No commits yet | This repository has no commits, so there is nothing to compare against. Every file reads as new. | View Files | 33 | `.build/artifacts/errors/git.unbornBranch.png` |
| `git.detachedHead` | `error.git.detachedHead` | Detached HEAD | This repository sits on a commit rather than a branch, so there is no upstream to compare with. | View History | 33 | `.build/artifacts/errors/git.detachedHead.png` |
| `git.noUpstream` | `error.git.noUpstream` | No upstream branch | This branch tracks nothing, so ahead and behind counts are unavailable. Set an upstream on the host. | Dismiss | 33 | `.build/artifacts/errors/git.noUpstream.png` |
| `git.mergeInProgress` | `error.git.mergeInProgress` | Merge in progress | This repository is mid-merge. Conflicted files show both sides; finish or abort the merge on the host. | View Conflicts | 33 | `.build/artifacts/errors/git.mergeInProgress.png` |
| `git.renameLimit` | `error.git.renameLimit` | Renames not detected | The change set is past git's rename limit, so renames read as a delete and an add. Raise diff.renameLimit on the host. | Dismiss | 37 | `.build/artifacts/errors/git.renameLimit.png` |
| `git.diffTruncated` | `error.git.diffTruncated` | Diff truncated | This diff passed 256 KB and was cut off there. Open the file to read the rest. | Open File | 37 | `.build/artifacts/errors/git.diffTruncated.png` |
| `git.combinedDiffUnsupported` | `error.git.combinedDiffUnsupported` | Merge diff not shown | This commit has more than one parent, and combined diffs are not rendered. Open a parent to see its changes. | Choose Parent | 37 | `.build/artifacts/errors/git.combinedDiffUnsupported.png` |
| `git.submoduleEntry` | `error.git.submoduleEntry` | Submodule | This entry records a commit in another repository rather than file content. | Dismiss | 37 | `.build/artifacts/errors/git.submoduleEntry.png` |
| `git.binaryDiff` | `error.git.binaryDiff` | Binary file | Git can report that this file changed, but it cannot show its contents as text. | Dismiss | 37 | `.build/artifacts/errors/git.binaryDiff.png` |
| `git.modeOnlyChange` | `error.git.modeOnlyChange` | File mode changed | Only this file's executable permission changed. There is no text diff to show. | Dismiss | 37 | `.build/artifacts/errors/git.modeOnlyChange.png` |
| `files.blobTooLarge` | `error.files.blobTooLarge` | File too large to open | This file is over the limit for its type, so nothing was transferred. Open it anyway to load it in full. | Open Anyway | 41 | `.build/artifacts/errors/files.blobTooLarge.png` |
| `files.lfsPointer` | `error.files.lfsPointer` | Stored with Git LFS | The repository holds a pointer to this file rather than the file itself. Fetch it on the host to read it. | View Pointer | 41 | `.build/artifacts/errors/files.lfsPointer.png` |
| `files.jsonParseFailed` | `error.files.jsonParseFailed` | Not valid JSON | This file cannot be shown as a tree. Its text is shown instead. | Show Text | 42 | `.build/artifacts/errors/files.jsonParseFailed.png` |
| `files.fetchFailed` | `error.files.fetchFailed` | File could not be loaded | The transfer stopped before the file arrived. Nothing on the host changed. | Try Again | 42 | `.build/artifacts/errors/files.fetchFailed.png` |
| `files.uploadVerificationFailed` | `error.files.uploadVerificationFailed` | Upload could not be verified | The file on the host did not match the original, so it was removed. | Try Again | 59 | `.build/artifacts/errors/files.uploadVerificationFailed.png` |
| `files.binaryFile` | `error.files.binaryFile` | Not a text file | The start of this file is not text and no viewer here reads its type. Nothing beyond the first block was read. | Dismiss | 60 | `.build/artifacts/errors/files.binaryFile.png` |
| `files.unsupportedVideo` | `error.files.unsupportedVideo` | Unsupported video container | iOS plays neither MKV nor WebM, whatever codec is inside. Convert the file on the host to watch it here. | Dismiss | 44 | `.build/artifacts/errors/files.unsupportedVideo.png` |
| `files.svgParseFailed` | `error.files.svgParseFailed` | SVG could not be drawn | This file did not parse as a drawable SVG. Its source is shown instead. | View Source | 44 | `.build/artifacts/errors/files.svgParseFailed.png` |
| `files.svgTooLarge` | `error.files.svgTooLarge` | SVG too large to draw | This SVG is over 256 KB and was not parsed. Its source is shown instead. | View Source | 44 | `.build/artifacts/errors/files.svgTooLarge.png` |
| `files.imageDecodeFailed` | `error.files.imageDecodeFailed` | Image could not be decoded | The file has an image extension but no readable image data. It may be truncated. | Dismiss | 43 | `.build/artifacts/errors/files.imageDecodeFailed.png` |
| `mux.absent` | `error.mux.absent` | No multiplexer on this host | Neither tmux nor herdr is on the host's login shell PATH, so sessions end when the app suspends. Install tmux to keep work running. | Dismiss | 39 | `.build/artifacts/errors/mux.absent.png` |
| `mux.protocolMismatch` | `error.mux.protocolMismatch` | Herdr version not supported | The herdr on this host speaks a protocol this app does not read. Update herdr on the host, or use its tmux sessions. | Use tmux | 39 | `.build/artifacts/errors/mux.protocolMismatch.png` |
| `mux.attachTargetVanished` | `error.mux.attachTargetVanished` | Session no longer exists | The pane closed on the host before the app attached. Refresh to see what is still running. | Refresh | 40 | `.build/artifacts/errors/mux.attachTargetVanished.png` |
| `mux.detachFailed` | `error.mux.detachFailed` | Could not detach | The detach keys were not sent. Check the connection and try again. | Try Again | 52 | `.build/artifacts/errors/mux.detachFailed.png` |
| `app.noHostsYet` | `error.app.noHostsYet` | No hosts yet | Add the host you want to reach, with its address and the user you log in as. | Add Host | 17 | `.build/artifacts/errors/app.noHostsYet.png` |
| `app.clipboardDenied` | `error.app.clipboardDenied` | Clipboard access denied | iOS refused access to the clipboard. Set Paste from Other Apps to Allow in Settings. | Open Settings | 26 | `.build/artifacts/errors/app.clipboardDenied.png` |
| `app.pasteCancelled` | `error.app.pasteCancelled` | Paste cancelled | Nothing was pasted, and nothing was sent to the host. | Paste | 26 | `.build/artifacts/errors/app.pasteCancelled.png` |
| `command.responseUnreadable` | `error.command.responseUnreadable` | Reply could not be read | The host's answer arrived incomplete or out of order, so none of it was used. Run the request again. | Try Again | 28 | `.build/artifacts/errors/command.responseUnreadable.png` |
| `command.responseTooLarge` | `error.command.responseTooLarge` | Reply too large | The host sent more than one request may return, so it was stopped and none of it was used. Run the request again. | Try Again | 28 | `.build/artifacts/errors/command.responseTooLarge.png` |
| `command.programMissing` | `error.command.programMissing` | Program not found | This command is not on the host's login shell PATH. Install it, or add it to that PATH. | Check Again | 28 | `.build/artifacts/errors/command.programMissing.png` |
| `command.failed` | `error.command.failed` | Command failed | The command ran on the host and ended with an error. Its own output says why. | Dismiss | 28 | `.build/artifacts/errors/command.failed.png` |
| `command.signalled` | `error.command.signalled` | Command stopped | A signal ended this command on the host before it finished. Run it again. | Try Again | 28 | `.build/artifacts/errors/command.signalled.png` |
| `link.schemeRefused` | `error.link.schemeRefused` | Scheme refused | This address uses a scheme the app does not open. Copy the address and open it in another app. | Copy Address | 49 | `.build/artifacts/errors/link.schemeRefused.png` |
| `session.survivalSSH` | `error.session.survivalSSH` | Session ends on sleep | Backgrounding ends this session. Work continues on the host only if it is inside tmux or herdr. | Reconnect | 21 | `.build/artifacts/errors/session.survivalSSH.png` |
| `session.survivalMultiplexed` | `error.session.survivalMultiplexed` | Reattaches on return | Reattaches on return. Scrollback is preserved on the host. | Reattach | 21 | `.build/artifacts/errors/session.survivalMultiplexed.png` |
| `session.survivalRoaming` | `error.session.survivalRoaming` | Survives sleep and roam | Survives sleep and network change. Scrollback from before the drop is lost unless you are in a multiplexer. | Reconnect | 21 | `.build/artifacts/errors/session.survivalRoaming.png` |
| `session.reattached` | `error.session.reattached` | Reattached | The session is connected again. | Dismiss | 21 | `.build/artifacts/errors/session.reattached.png` |
| `session.reconnectExhausted` | `error.session.reconnectExhausted` | Could not reconnect | Every automatic attempt failed. Tap Reconnect to try once more. | Reconnect | 21 | `.build/artifacts/errors/session.reconnectExhausted.png` |
| `notifications.jobFailed` | `error.notifications.jobFailed` | Job failed | A command on the host ended with an error. Open the session to see its output. | Open Session | 60 | `.build/artifacts/errors/notifications.jobFailed.png` |
| `notifications.alertTooLarge` | `error.notifications.alertTooLarge` | Alert dropped | The host sent a job alert too large to show. Nothing on the host changed. | Dismiss | 60 | `.build/artifacts/errors/notifications.alertTooLarge.png` |
| `notifications.alertsSuspended` | `error.notifications.alertsSuspended` | Alerts end when suspended | Job alerts arrive while AnySSH is connected or briefly after backgrounding. iOS suspending the app ends them. | Got It | 60 | `.build/artifacts/errors/notifications.alertsSuspended.png` |

## Extending the registry

Later phases will need states this one did not scope. Add them the same way: a case in the group's
enum with its copy, a row here, and nothing else. The drift test is what makes the pair mandatory.

Four are already known to be missing, each named by the phase that will need it, so nobody invents
copy for them on the spot:

| Phase | What it needs |
|---|---|
| 26 | The tmux `set-clipboard` hint, which Phase 26 requires to be a distinct state from `app.clipboardDenied`. |
| 37 | Diff placeholders for a binary file and a mode-only change, alongside `files.lfsPointer` and `git.combinedDiffUnsupported`, which are already here. |
| 16 | The refusal for pasting a public key where a private key is expected. |

Two notes on placement, both deliberate:

`files.lfsPointer` sits in the files group although Phase 4 listed it under git, because Phase 41
asserts on the identifier `files.lfsPointer` by name. The identifier a later phase already spells
out wins over the grouping in the plan's prose.

The multiplexer group is `mux`, not `multiplexer`, matching `mux.protocolMismatch` in Phase 39 and
the `mux.*` accessibility identifiers in Phase 40.
