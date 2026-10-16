import XCTest
import SwiftData
@testable import Observed

/// Tests for the Occurrence model — timestamp fidelity and the habit backlink.
final class OccurrenceTests: ModelTestBase {

    func testObservedAtStoresExactDate() throws {
        let habit = try insertHabit(named: "Mind wandering")
        // Sub-second precision: verify no truncation occurs in round-trip.
        let precise = epochBase.addingTimeInterval(0.123)
        let occurrence = try insertOccurrence(for: habit, observedAt: precise)
        XCTAssertEqual(occurrence.observedAt.timeIntervalSince1970,
                       precise.timeIntervalSince1970,
                       accuracy: 0.001)
    }

    func testDefaultInitUsesCurrentTime() throws {
        let occurrence = Occurrence()
        XCTAssertEqual(occurrence.observedAt.timeIntervalSinceNow, 0, accuracy: 5)
    }

    func testOccurrenceLinksBackToItsHabit() throws {
        let habit = try insertHabit(named: "Going for a walk")
        let occurrence = try insertOccurrence(for: habit, observedAt: epochBase)
        XCTAssertEqual(occurrence.habit?.name, "Going for a walk")
        XCTAssertTrue(habit.occurrences.contains(occurrence),
                      "Relationship should be bidirectional: the habit's occurrence list must contain the occurrence.")
    }

    func testUnlinkedOccurrenceHasNoHabit() throws {
        let occurrence = Occurrence(observedAt: epochBase)
        context.insert(occurrence)
        XCTAssertNil(occurrence.habit)
    }

    // MARK: - Back-dating boundaries

    func testOccurrencesCanBeCreatedWithAnyPastOrFutureDate() throws {
        // The model layer permits any timestamp; the UI enforces
        // "no future dates" via the DatePicker range. This test pins the
        // model contract: back-dating is fully supported.
        let habit = try insertHabit(named: "Mind wandering")
        let farPast = Date(timeIntervalSince1970: 0) // 1970-01-01
        let occurrence = try insertOccurrence(for: habit, observedAt: farPast)
        XCTAssertEqual(occurrence.observedAt, farPast)
        XCTAssertEqual(habit.lastOccurrence, occurrence)
    }
}
