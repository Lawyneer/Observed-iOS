# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- **Sorting** Added sorting by date created, last occurrence date, or alphabetically.

### Changed

- **Renamed the project from MedTracker to Observed.** The app is no longer a
  medication tracker; it observes habits and behaviours generally.
- Renamed the core models: `Medication` → `Habit`, `Dose` → `Occurrence`,
  and the timestamp property `takenAt` → `observedAt`.
- Logging an occurrence moved from tapping the habit name to a swipe action on
  the row. Tapping the row now opens its history.

### Added

- Documentation: README, CONTRIBUTING, PRIVACY, SECURITY, CHANGELOG.
- GitHub Actions CI workflow running the test suite on every push and PR.

## [0.1.0] - 2026-10-16

### Added

- Initial pre-release of the habit observer.
- Add and delete habits by name.
- One-gesture occurrence logging with a 5-second undo toast.
- Last-observed display per habit.
- Per-habit occurrence history with swipe-to-delete and confirmation.
- Back-dating sheet for occurrences logged late.
- Cascade deletion of a habit's history.
- On-device SwiftData persistence; no network access.
- Dark mode support.
- Unit test suite covering the model layer and persistence behaviour.

[Unreleased]: https://github.com/Lawyneer/Observed-iOS/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Lawyneer/Observed-iOS/releases/tag/v0.1.0
