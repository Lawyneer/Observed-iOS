# Architecture

This document explains how the pieces of Observed fit together, for
someone reading the codebase for the first time. It assumes no prior
SwiftUI experience; the source files themselves carry line-level
comments, so this file stays at the level of *shape* and *flow*.

## Bird's-eye view

Observed is intentionally tiny. Five Swift files, two data types, one
screen-pushing flow. The whole app is one loop:

> **The user does something → a view mutates the database →
> the database notifies every watching view → the screens redraw.**

Understanding that loop is understanding the app. Everything below is
detail on its parts.

## The layers

The code separates into three layers, deliberately arranged so that
each layer only talks to the layer below it:

| Layer | File(s) | Responsibility |
|---|---|---|
| **App shell** | `ObservedApp.swift` | Boots the UI, creates the database |
| **Views** | `HabitListView.swift`, `HabitRow.swift`, `OccurrenceHistoryView.swift` | Screens and interaction |
| **Models** | `Models.swift` | The two things the app stores |

There is no view-model layer, no coordinators, no repositories. For
five files of code, that would be ceremony, not architecture. The
constraint to respect when extending: **models hold data; views hold
decisions about presentation and interaction; nothing else exists.**
The moment logic that isn't "draw pixels" starts accumulating in a
view (say, computing weekly statistics), it should move down into the
models as a computed property or method, where it becomes testable.

## The data model

Two classes, one relationship:

```
┌─────────┐  occurrences (cascade delete)  ┌────────────┐
│  Habit  │ ─────────────────────────────▶ │ Occurrence │
│         │ ◀───────────────────────────── │            │
└─────────┘        habit (inverse)         └────────────┘
```

- A **`Habit`** is the category: "Mind wandering", "Went for a walk".
- An **`Occurrence`** is one logged instance of it, at a point in time.
- The link is **bidirectional** and maintained automatically by
  SwiftData: assigning `occurrence.habit` also appends it to
  `habit.occurrences`. Both are views of one underlying edge; you
  never have to update both sides.
- The relationship carries `deleteRule: .cascade`: deleting a Habit
  deletes its Occurrences. This is why history removal "just works"
  everywhere in the UI — there is one deletion policy, expressed
  once, at the schema level.
- `Habit.lastOccurrence` is a computed property, not stored data —
  the database stores occurrences; "most recent" is a derived fact,
  always freshly computed, so it can never fall out of sync.

Naming note: the event type is `Occurrence`, not `Observation`,
because `Observation` is an Apple framework name that collides with
the `Observable` machinery during SwiftData macro expansion. If you
extend the models, avoid type names that shadow framework modules.

## The data flow, concretely

Here is the full lifecycle of one tap, end to end — follow it in the
code and you can see the loop in action:

1. **The user swipes a habit row left and taps "Observed"**
   (`HabitListView`).
2. `logOccurrence(for:)` runs, creating an `Occurrence`, calling
   `context.insert(_:)` and `context.save()`.
3. The insert modifies the database. SwiftData notices.
4. The `@Query` in `HabitListView` re-runs automatically — its
   results array updates.
5. SwiftUI diffs the new data against the old and redraws exactly the
   parts of the screen that changed: the row's "Last observed…"
   subtitle.
6. Separately, `logOccurrence` also sets a `@State` variable
   (`pendingUndoOccurrence`), which triggers the Undo toast's
   appearance through a normal SwiftUI state-driven animation.

No delegate callbacks, no notification center, no manual refresh
calls anywhere in the codebase. If you're hunting for "what updates
the list?" the answer is always the same: the `@Query` observes the
store, and SwiftUI redraws.

## The views and their contracts

```
ObservedApp
└─ HabitListView                 ← main screen
   ├─ HabitRow                   ← one list row
   │  └─ OccurrenceHistoryView   ← pushed screen, per-habit
   │     └─ AddOccurrenceSheet   ← modal sheet, back-dating
   └─ (toast, alerts, dialogs)   ← overlays owned by HabitListView
```

- **`HabitListView`** owns the `@Query`, all mutations (add, delete,
  log), and all transient screen state. Rows are dumb; they render
  and navigate.
- **`HabitRow`** is deliberately minimal — two text lines and a
  NavigationLink. It receives a `Habit` and renders it.
- **`OccurrenceHistoryView`** receives a `Habit` from the navigation
  push and owns deletion-confirm-and-execute, plus back-dating. Its
  list is *derived* from the habit (`sortedOccurrences`), so it needs
  no `@Query` of its own.
- **`AddOccurrenceSheet`** is the most decoupled view in the app: it
  touches no database at all. It collects a date and reports it via
  an `onAdd` closure. The parent decides what the date means and
  performs the insert. This is the pattern to copy when a new view
  is "a tool" rather than "a screen with data".

## Conventions worth respecting when extending

These aren't rules enforced by the compiler; they're the ones that
keep the app coherent:

1. **Mutations happen through `context`, reads happen through
   `@Query` or the model graph.** Every write in the codebase follows
   insert/delete → `context.save()`. There are no batch imports or
   background writes.
2. **One screen, one owner.** Each screen's transient state lives in
   the smallest view that displays it. Nothing global.
3. **Derived facts are computed properties on the model.**
   `lastOccurrence` is the template: if the UI needs a fact, compute
   it where the data lives so the views stay thin and the logic gets
   covered by the model tests.
4. **Destructive actions confirm first.** Deletion of an occurrence
   asks; deletion of a habit (which cascades its whole history)
   relies on swipe intent plus the model-layer cascade. An undone
   mistake is preferable to a confirmed mistake.
5. **The UI enforces constraints that the model layer permits.** The
   DatePicker caps at "now" — but `Occurrence.init` accepts any
   timestamp, and a test pins that contract. UI rules are conveniences
   pinned in tests; schema rules are laws.

## Persistence and platform floors

The app persists via **SwiftData** in an on-device store created by
`.modelContainer(for:)` in `ObservedApp`. SwiftData requires **iOS
17.0**; the deployment target is pinned to 17.0 on every target in
the project (this is pinned deliberately — see the deployment-target
section of the project's history — and a CI test guards the build).

> **Adding a stored property changes the schema.** Adding a field to
> `Habit` or `Occurrence` changes the store's shape; existing user
> data will need a migration plan (SwiftData lightweight migration
> handles simple additions automatically, but verify with a test
> that opens an old store). There is currently no cloud sync and no
> export feature; the local store is the only copy of the data.

## Testing strategy

The test target mirrors the architecture's emphasis: model and
persistence behavior, not pixels.

- `ModelTestBase` (in `TestSupport.swift`) gives every test an
  **isolated, in-memory SwiftData container** — nothing touches disk,
  tests can't pollute each other, and no test cleanup is needed.
- `HabitTests` / `OccurrenceTests` cover initialization, relationship
  integrity, and the `lastOccurrence` ordering logic.
- `PersistenceTests` covers round-tripping through a fresh context
  (simulating app relaunch) and the cascade-deletion guarantee.
- Fixed reference dates (`epochBase`) and tolerance-based comparisons
  keep the suite deterministic across timezones and machine clocks.

The UI layer is untested by design at this stage — the deliberate bet
is that model correctness plus SwiftUI's declarative rendering covers
most regressions, and the highest-value addition to the suite would
be more model-layer tests (statistics, aggregations) as those
features are built.

## Known simplifications (as of v0.1.0)

An honest list of corners cut, for future maintainers:

- No widget, no share-sheet import, no export. Logging requires
  opening the app (the swipe is the fastest path).
- The back-dating sheet allows *past* dates only, enforced at the
  UI layer; the model accepts any date and a test documents this.
- The undo affordance exists only on the main list (swipe-to-log),
  not on back-dated entries added via the sheet.
- The icon pipeline was assembled before publication; treat the
  AppIcon asset as provisional (see CHANGELOG).
- The README's roadmap (frequency summaries, widget, Android port)
  describes additions, not commitments.

## Point of departure: how to add a feature

To add a typical feature — say, a per-habit frequency summary — the
path that fits this architecture is:

1. Add a computed property to `Habit` (e.g. `var occurrencesPerDay:
   Double`) in `Models.swift`.
2. Add model tests for it in `ObservedTests/` using the existing
   `ModelTestBase` helpers.
3. Render it in the view that needs it — a header in
   `OccurrenceHistoryView`, driven by the same `sortedOccurrences`
   derivation already present.

No new layer, no plumbing, no coordination. That's the payoff of
the small-model/big-view split this codebase maintains.