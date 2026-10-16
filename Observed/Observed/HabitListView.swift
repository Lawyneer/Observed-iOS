import SwiftUI
import SwiftData

struct HabitListView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Habit.createdAt, order: .reverse)
    private var habits: [Habit]

    @State private var isAddingHabit = false
    @State private var newName = ""

    // Undo state for an accidentally logged occurrence.
    @State private var pendingUndoOccurrence: Occurrence?

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
                        ForEach(habits) { habit in
                            HabitRow(habit: habit)
                                .swipeActions {
                                    Button {
                                        logOccurrence(for: habit)
                                    } label: {
                                        Label("Observed", systemImage: "eye")
                                    }
                                    .tint(.indigo)
                                }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("My Habits")
            .toolbar {
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
        }
    }

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

    private func addHabit() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        context.insert(Habit(name: trimmed))
        try? context.save()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(habits[index])   // history deleted with it
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
