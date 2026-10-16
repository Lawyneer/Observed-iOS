import XCTest
import SwiftData
@testable import Observed

/// Shared base class providing an isolated, in-memory SwiftData store
/// for every test. Nothing touches disk; each test gets a fresh container.
class ModelTestBase: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    /// Fixed reference dates used across tests so timing and timezone
    /// differences can never make a test flaky.
    let epochBase = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14T22:13:20Z

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: Habit.self, Occurrence.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
    }

    // MARK: - Helpers

    @discardableResult
    func insertHabit(named name: String) throws -> Habit {
        let habit = Habit(name: name)
        context.insert(habit)
        return habit
    }

    @discardableResult
    func insertOccurrence(for habit: Habit, observedAt date: Date) throws -> Occurrence {
        let occurrence = Occurrence(observedAt: date, habit: habit)
        context.insert(occurrence)
        return occurrence
    }

    func fetchAllOccurrences() throws -> [Occurrence] {
        try context.fetch(FetchDescriptor<Occurrence>())
    }
}
