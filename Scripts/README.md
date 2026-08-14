# Scripts

Build, test and QA automation. Everything here runs through the `Makefile`; `make
help` lists the targets. Configuration comes from `.env`, loaded by `env.sh`.

## The scripts

| Script | Purpose |
|---|---|
| `env.sh` | Sourced by the rest. Parses `.env`, applies defaults, exports paths. |
| `doctor.sh` | Checks the toolchain and repairs the SDK to simulator-runtime mapping. |
| `build.sh` | Builds the app for the simulator and prints the `.app` path. |
| `run.sh` | Boots the simulator, installs and launches in mock mode. |
| `screenshot.sh` | Boots headlessly, launches a scenario, captures a PNG, terminates. |
| `test-sim.sh` | Package tests on the simulator, where UIKit rendering is available. |
| `ui-test.sh` | XCUITest flows. |
| `lint.sh` | Formatting, the 300-line budget, the comment ban, module rules. |
| `format.sh` | Rewrites Swift sources in place. |
| `format-log.sh` | Filters `xcodebuild` output through xcbeautify or grep. |
| `app-path.sh` | Asks the build system where the `.app` is instead of guessing. |
| `udid.sh` | Prints the UDID of an available simulator by name. |
| `vendor-libssh2.sh` | Builds the pinned `CSSH.xcframework`. |
| `vendor-slice.sh` | Builds one platform slice for the vendoring script. |

`env.sh` is sourced, never executed. It parses `.env` rather than sourcing it
because values carry unquoted spaces (`iPhone 17 Pro`) and `. .env` would try to
run `17 Pro` as a command. Values already in the environment win, so
`make screenshot DEVICE="iPad Pro 11-inch (M5)"` overrides a single run.

## Linting

`lint.sh` runs every rule on every invocation and exits once at the end, so one
run lists everything that is wrong. It enforces `swift format --strict`, the
300-line file budget with the same exemptions as the CI workflow, a ban on
comments in Swift sources, and the module boundaries from AGENTS.md.

The comment check classifies every character of a file before deciding, so a
`//` inside a string literal or a `/.../` regex is not a false positive. A file
it cannot scan is reported rather than passed.

Rules only run once their targets exist. During the rebuild the source trees
appear phase by phase, and a rule whose module is absent is skipped instead of
failing the run.

## Vendoring libssh2

`vendor-libssh2.sh` builds `Packages/AnySSHKit/Vendor/CSSH.xcframework` from
pinned sources. `vendor-slice.sh` builds one platform slice and is not useful on
its own. The output is gitignored: it is roughly 38 MB and every machine can
reproduce it from the pins, so it is built on demand rather than committed.

```
make vendor            # no-op when the pins already match what is built
make vendor ARGS=--force
```

Slices produced: `ios-arm64`, `ios-arm64_x86_64-simulator`, `macos-arm64`. The
macOS slice exists because `swift test` runs on the host, which is where the
live smoke test in `Tests/SSHTransportTests` lives.

The `sha256` the script prints covers the libraries and headers, and two clean
runs on the same toolchain produce the same value. Record it next to the pin when
you re-vendor: it is the only cheap way to tell whether a rebuild changed
anything. `Info.plist` is excluded because `xcodebuild` orders the
`AvailableLibraries` array at random, so it differs run to run while the shipped
bits do not.

### Why we track an unreleased branch

libssh2's newest tag, 1.11.1 (2024-10-16), carries CVE-2026-55200: a CVSS 9.2
out-of-bounds write in `ssh2_transport_read()` that lets a malicious server
execute code in the client. A malicious server is our threat model. The fix,
commit `97acf3df` (PR #2052), exists only on `master`, so we pin a `master`
commit and never a tarball. The script refuses to build a commit that is not a
descendant of the fix.

The cost of that choice is this routine. It is not optional maintenance.

### Moving the pin forward

1. Watch for reasons to move: the [libssh2 GHSA
   feed](https://github.com/libssh2/libssh2/security/advisories), oss-sec, and
   the `1.11.2_DEV` section of upstream `RELEASE-NOTES`. A tagged 1.11.2 that
   contains the fix is the point at which this whole routine can go back to
   tarballs, so check whether one exists before pinning another commit.
2. Resolve the new head and read what changed:
   `git ls-remote https://github.com/libssh2/libssh2 refs/heads/master`, then
   compare it against `LIBSSH2_COMMIT` in `vendor-libssh2.sh`.
3. Update `LIBSSH2_COMMIT`, and record the date and the reason in the commit
   message. Leave `LIBSSH2_CVE_FIX` alone; it is the ancestry assertion, not a
   pin to move.
4. `make vendor ARGS=--force`, then `make test` and `make build`.

### What to check on every re-vendor

- **The ancestry assertion passed.** The script fails if the new commit does not
  contain `97acf3df`. Never weaken that check to get a build out.
- **The crypto backend is still OpenSSL.** Each slice asserts that
  `ssh2_ed25519_sign` is defined. mbedTLS and wolfSSL hard-disable ed25519, and
  CMake will silently fall back to another backend if it cannot find OpenSSL.
- **Symbol names drift on `master`.** The ed25519 assertion had to change once
  already: the internal prefix is `ssh2_`, not the `libssh2_` the older
  documentation shows. If the assertion fails, check `nm` output before assuming
  the backend broke.
- **Deployment targets.** `otool -l` on each slice must report `minos 26.0`.
- **Algorithm removals.** `master` disables SHA-1 kex and host keys, DSA, MD5,
  3DES, RC4 and Blowfish by default and plans to delete them. Read
  `RELEASE-NOTES` for anything that changes which servers we can reach.
- **The live smoke test.** `swift test` skips it when the host is unreachable, so
  a green run proves nothing on its own. Confirm the two `LiveHostSmokeTests`
  cases actually ran.

### Bumping OpenSSL

Set `OPENSSL_VERSION` and `OPENSSL_SHA256` together. The checksum comes from the
`.sha256` asset on the GitHub release; the script refuses to build a tarball that
does not match. Stay on the 3.5 LTS line unless there is a reason to move: it is
the first line with ML-KEM, which libssh2 `master` needs for post-quantum key
exchange.
