import XCTest
import SwiftData
@testable import Observed

/// End-to-end persistence behavior through a real (in-memory) SwiftData
/// container: saving, refetching, and cascade deletion.
final class PersistenceTests: ModelTestBase {

    func testSavedHabitIsRefetchableFromFreshContext() throws {
        let habit = try insertHabit(named: "Going for a walk")
        try context.save()

        // A brand-new context on the same container simulates a relaunch.
        let freshContext = ModelContext(container)
        let fetched = try freshContext.fetch(
            FetchDescriptor<Habit>(predicate: #Predicate { $0.name == "Going for a walk" })
        )
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Going for a walk")
        _ = habit // silence unused variable in release builds
    }

    func testSavedOccurrencesPersistWithHabit() throws {
        let habit = try insertHabit(named: "Mind wandering")
        try insertOccurrence(for: habit, observedAt: epochBase)
        try insertOccurrence(for: habit, observedAt: epochBase.addingTimeInterval(86_400))
        try context.save()

        let freshContext = ModelContext(container)
        let fetched = try freshContext.fetch(FetchDescriptor<Habit>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.occurrences.count, 2)
    }

    // MARK: - Cascade deletion (user requirement #1)

    func testDeletingHabitDeletesAllItsOccurrences() throws {
        let habit = try insertHabit(named: "Going for a walk")
        try insertOccurrence(for: habit, observedAt: epochBase)
        try insertOccurrence(for: habit, observedAt: epochBase.addingTimeInterval(3_600))
        try insertOccurrence(for: habit, observedAt: epochBase.addingTimeInterval(7_200))
        try context.save()

        XCTAssertEqual(try fetchAllOccurrences().count, 3)

        context.delete(habit)
        try context.save()

        XCTAssertEqual(try fetchAllOccurrences().count, 0,
                       "Deleting a habit must cascade-delete its entire history.")
    }

    func testCascadeDeleteLeavesOtherHabitsUntouched() throws {
        let walking = try insertHabit(named: "Going for a walk")
        let coffee = try insertHabit(named: "Drinking coffee")
        try insertOccurrence(for: walking, observedAt: epochBase)
        let survivingOccurrence = try insertOccurrence(for: coffee, observedAt: epochBase)
        try context.save()

        context.delete(walking)
        try context.save()

        let remaining = try fetchAllOccurrences()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first, survivingOccurrence)
        XCTAssertEqual(coffee.occurrences.count, 1)
    }

    // MARK: - Undo path (main-list accidental logging)

    func testDeletingOccurrenceDoesNotDeleteHabit() throws {
        let habit = try insertHabit(named: "Going for a walk")
        let occurrence = try insertOccurrence(for: habit, observedAt: epochBase)
        try context.save()

        // Simulates the Undo toast's action: delete the just-logged occurrence.
        context.delete(occurrence)
        try context.save()

        XCTAssertEqual(try fetchAllOccurrences().count, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Habit>()).count, 1,
                       "Undoing an occurrence must not remove the habit itself.")
        XCTAssertNil(habit.lastOccurrence)
    }
}
