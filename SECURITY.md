# Security

AnySSH connects over SSH to machines you own. The threat model is a malicious or compromised server: the transport is libssh2 with OpenSSL, vendored from a pinned commit, and the vendoring script refuses to build any commit that does not descend from the fix for CVE-2026-55200.

## Reporting a vulnerability

Do not open a public issue for a security problem. Use GitHub's private vulnerability reporting on this repository: Security tab, then "Report a vulnerability". Include the iOS version, the app version or commit, and steps to reproduce.

A maintainer will acknowledge reports within a few days. Wait to disclose publicly until a fix ships.

## Scope

Keys and passphrases live in the iOS Keychain and never leave the device. There is no backend and no account system, so there is no AnySSH server to attack. Reports should target the app itself, the vendored libssh2 and OpenSSL build, or how the app handles hostile server output.
