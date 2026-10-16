import SwiftUI
import SwiftData

struct HabitRow: View {
    @Bindable var habit: Habit

    var body: some View {
        NavigationLink {
            OccurrenceHistoryView(habit: habit)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(lastObservedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var lastObservedDescription: String {
        guard let last = habit.lastOccurrence else { return "Never observed" }
        return "Last observed \(last.observedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}
