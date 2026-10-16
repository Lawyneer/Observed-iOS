# Security Policy

## Supported versions

Observed is pre-1.0. Only the latest commit on `main` is supported.

## Reporting a vulnerability

Please **do not** open a public issue for security problems. Instead, use
GitHub's private vulnerability reporting: go to the repository's **Security**
tab and click **Report a vulnerability**. If that's unavailable, open a minimal
issue asking for a private contact channel, without disclosing details.

Please include:

- A description of the issue and its impact
- Steps to reproduce
- Affected iOS version and device
- Any suggested mitigation

You can expect an acknowledgement within a few days. As this is a
volunteer-maintained project, please allow reasonable time for a fix before
public disclosure.

## Scope

The app has no network access, no accounts, and no server component, so the
attack surface is small. Relevant areas include local data storage, the
SwiftData container, and anything that could cause logged data to leave the
device.

## Out of scope

- Issues requiring a jailbroken device or physical access to an unlocked phone
- Vulnerabilities in iOS, Xcode, or Apple's frameworks themselves — report
  those to Apple