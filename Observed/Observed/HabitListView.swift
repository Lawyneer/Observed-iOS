import SwiftUI
import SwiftData

/// The ways the habit list can be ordered.
enum HabitSort: String, CaseIterable, Identifiable {
    case newest
    case alphabetical
    case lastRecorded

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .newest: "Newest First"
        case .alphabetical: "Alphabetical"
        case .lastRecorded: "Last Recorded"
        }
    }
}

struct HabitListView: View {
    @Environment(\.modelContext) private var context

    // Sorting happens in `sortedHabits`, not in the query, because
    // @Query sort descriptors can only target persisted properties —
    // "date of last occurrence" is derived from a relationship.
    @Query private var habits: [Habit]

    @AppStorage("habitSort") private var sortOrder: HabitSort = .newest

    @State private var isAddingHabit = false
    @State private var newName = ""

    // Undo state for an accidentally logged occurrence.
    @State private var pendingUndoOccurrence: Occurrence?

    // The habit whose history should be pushed. Setting a value
    // slides the history screen in; setting nil pops it back.
    @State private var selectedHabit: Habit?

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "No habits yet",
                        systemImage: "eye",
                        description: Text("Tap + to add one.")
                    )
                } else {
                    List {
                        ForEach(sortedHabits) { habit in
                            HabitRow(
                                habit: habit,
                                onLogOccurrence: { logOccurrence(for: habit) },
                                onOpenHistory: { selectedHabit = habit }
                            )
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("My Habits")
            // State-driven navigation: when selectedHabit is set,
            // this pushes the history view for that habit. Replaces
            // the NavigationLink that used to live in the row.
            .navigationDestination(item: $selectedHabit) { habit in
                OccurrenceHistoryView(habit: habit)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $sortOrder) {
                            ForEach(HabitSort.allCases) { sort in
                                Text(sort.label).tag(sort)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newName = ""
                        isAddingHabit = true
                    } label: {
                        Label("Add habit", systemImage: "plus")
                    }
                }
            }
            .alert("Add Habit", isPresented: $isAddingHabit) {
                TextField("Habit name", text: $newName)
                    .textInputAutocapitalization(.words)
                Button("Cancel", role: .cancel) { }
                Button("Add") { addHabit() }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            } message: {
                Text("Enter the name of the habit to observe.")
            }
            // Undo toast for accidental occurrence logging.
            .overlay(alignment: .bottom) {
                if let occurrence = pendingUndoOccurrence {
                    undoToast(for: occurrence)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: pendingUndoOccurrence)
            .animation(.default, value: sortOrder)
        }
    }

    // MARK: - Sorting

    /// The habits in the currently selected order.
    /// The view reads this (NOT `habits`) so rows and swipe-to-delete
    /// stay consistent; `delete(at:)` must index into the same array.
    private var sortedHabits: [Habit] {
        switch sortOrder {
        case .newest:
            habits.sorted { $0.createdAt > $1.createdAt }
        case .alphabetical:
            habits.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        case .lastRecorded:
            // Habits never recorded sink to the bottom.
            habits.sorted {
                ($0.lastOccurrence?.observedAt ?? .distantPast)
                    > ($1.lastOccurrence?.observedAt ?? .distantPast)
            }
        }
    }

    // MARK: - Subviews

    private func undoToast(for occurrence: Occurrence) -> some View {
        HStack {
            Text("Observed")
                .font(.subheadline)
            Spacer()
            Button("Undo") {
                context.delete(occurrence)
                try? context.save()
                pendingUndoOccurrence = nil
            }
            .bold()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: .capsule)
        .shadow(radius: 4)
        .task {
            // Auto-dismiss after 5 seconds.
            try? await Task.sleep(for: .seconds(5))
            withAnimation { pendingUndoOccurrence = nil }
        }
    }

    // MARK: - Actions

    private func addHabit() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        context.insert(Habit(name: trimmed))
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sortedHabits[index])   // history deleted with it
        }
        try? context.save()
    }

    private func logOccurrence(for habit: Habit) {
        let occurrence = Occurrence(observedAt: .now, habit: habit)
        context.insert(occurrence)
        try? context.save()
        pendingUndoOccurrence = occurrence
    }
}
