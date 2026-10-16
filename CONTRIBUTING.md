# Contributing to Observed

Thanks for wanting to help. This is a small, opinionated project, so a few
things are worth knowing before you open a pull request.

## The one rule

**Observed observes; it does not evaluate.** Contributions that add reminders,
notifications, streaks, goals, targets, adherence scores, or any form of
"you should do this" prompting will be declined. This isn't a stylistic
preference — it's the entire reason the app exists. If you want those features,
fork it; the licence permits it.

## Getting set up

1. Fork and clone the repository.
2. Open `Observed.xcodeproj` in Xcode 16 or later.
3. Build with ⌘B, run the tests with ⌘U.

No package manager, no dependencies. Please keep it that way unless there's a
strong argument otherwise — discuss it in an issue first.

## Before you open a pull request

- **Run the test suite.** ⌘U must pass.
- **Add tests for model-layer changes.** New properties, relationships, or
  computed values should come with coverage in `ObservedTests/`. Follow the
  existing pattern: `ModelTestBase` gives you an isolated in-memory container,
  and the helpers `insertHabit(named:)` / `insertOccurrence(for:observedAt:)`
  keep tests short.
- **Match the existing style.** SwiftUI views in `*View.swift`, one primary type
  per file, `@Bindable` for injected models, `@Query` for list fetches.
- **Keep the diff focused.** One concern per pull request.

## Commit messages

Short imperative subject line, then a blank line and a body explaining *why*
if the change isn't obvious. Example:

Fix duplicate chevron in habit rows

The custom chevron sat inside the HStack alongside the system-provided disclosure indicator, so List rendered two. The row is now the NavigationLink itself.

## Reporting bugs

Include your iOS version, device or simulator, and exact steps to reproduce.
Screenshots help enormously for layout issues.

## Feature requests

Open an issue describing the problem you're trying to solve rather than the
solution you have in mind. Requests for reminders, notifications, or goal
tracking will be closed — see "The one rule" above.

## Android

An Android port is on the roadmap and is the single most valuable contribution
anyone could make. If you're interested, open an issue first so we can agree on
scope before you write code.

## Licence

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE), the same licence as the project.