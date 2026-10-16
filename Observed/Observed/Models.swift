import Foundation
import SwiftData

@Model
final class Habit {
    var name: String
    var createdAt: Date

    /// Cascade: deleting a habit removes its entire occurrence history.
    @Relationship(deleteRule: .cascade, inverse: \Occurrence.habit)
    var occurrences: [Occurrence] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }

    var lastOccurrence: Occurrence? {
        occurrences.max(by: { $0.observedAt < $1.observedAt })
    }
}

@Model
final class Occurrence {
    /// Stored in UTC; rendered in the device's local timezone.
    var observedAt: Date
    var habit: Habit?

    init(observedAt: Date = .now, habit: Habit? = nil) {
        self.observedAt = observedAt
        self.habit = habit
    }
}
