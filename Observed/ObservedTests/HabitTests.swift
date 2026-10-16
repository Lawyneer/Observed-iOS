import XCTest
@testable import Observed

/// Tests for the Habit model — primarily the lastOccurrence computation
/// that drives the main list's "Last observed ..." subtitle.
final class HabitTests: ModelTestBase {

    // MARK: - Initialization

    func testInitStoresName() throws {
        let habit = try insertHabit(named: "Going for a walk")
        XCTAssertEqual(habit.name, "Going for a walk")
    }

    func testInitSetsCreationDateCloseToNow() throws {
        let habit = try insertHabit(named: "Mind wandering")
        XCTAssertEqual(habit.createdAt.timeIntervalSinceNow, 0, accuracy: 5)
    }

    // MARK: - lastOccurrence

    func testLastOccurrenceIsNilWithNoOccurrences() throws {
        let habit = try insertHabit(named: "Going for a walk")
        XCTAssertNil(habit.lastOccurrence, "A habit with no occurrences should report nil.")
    }

    func testLastOccurrenceReturnsSingleOccurrence() throws {
        let habit = try insertHabit(named: "Going for a walk")
        let occurrence = try insertOccurrence(for: habit, observedAt: epochBase)
        XCTAssertEqual(habit.lastOccurrence, occurrence)
    }

    func testLastOccurrencePicksMostRecentRegardlessOfInsertOrder() throws {
        let habit = try insertHabit(named: "Going for a walk")

        // Insert oldest first, then newest, then middle — insertion order
        // must not matter; the timestamp must.
        let oldest  = try insertOccurrence(for: habit, observedAt: epochBase)
        let newest  = try insertOccurrence(for: habit, observedAt: epochBase.addingTimeInterval(86_400))
        let middle  = try insertOccurrence(for: habit, observedAt: epochBase.addingTimeInterval(43_200))

        XCTAssertEqual(habit.lastOccurrence, newest)
        XCTAssertNotEqual(habit.lastOccurrence, oldest)
        XCTAssertNotEqual(habit.lastOccurrence, middle)
    }

    func testLastOccurrenceIdenticalTimestampsReturnsOneOfThem() throws {
        // Occurrences logged in the same instant (possible via rapid taps).
        let habit = try insertHabit(named: "Mind wandering")
        try insertOccurrence(for: habit, observedAt: epochBase)
        try insertOccurrence(for: habit, observedAt: epochBase)
        XCTAssertNotNil(habit.lastOccurrence, "Tied timestamps must still yield an occurrence, not crash.")
    }

    // MARK: - Isolation between habits

    func testOccurrencesDoNotLeakAcrossHabits() throws {
        let walking = try insertHabit(named: "Going for a walk")
        let coffee = try insertHabit(named: "Drinking coffee")

        try insertOccurrence(for: walking, observedAt: epochBase)
        XCTAssertEqual(walking.occurrences.count, 1)
        XCTAssertEqual(coffee.occurrences.count, 0,
                       "Occurrences logged for walking must not appear on coffee.")
    }
}
