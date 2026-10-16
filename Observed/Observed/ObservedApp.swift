import SwiftUI
import SwiftData

@main
struct ObservedApp: App {
    var body: some Scene {
        WindowGroup {
            HabitListView()
        }
        .modelContainer(for: [Habit.self, Occurrence.self])
    }
}
