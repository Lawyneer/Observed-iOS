import SwiftUI
import SwiftData

struct OccurrenceHistoryView: View {
    @Environment(\.modelContext) private var context
    @Bindable var habit: Habit

    @State private var occurrencePendingDeletion: Occurrence?
    @State private var isAddingPastOccurrence = false
    @State private var pastOccurrenceDate = Date.now

    private var sortedOccurrences: [Occurrence] {
        habit.occurrences.sorted { $0.observedAt > $1.observedAt }
    }

    var body: some View {
        List {
            if sortedOccurrences.isEmpty {
                Text("No occurrences recorded yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedOccurrences) { occurrence in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(occurrence.observedAt.formatted(date: .complete, time: .omitted))
                            .font(.body)
                        Text(occurrence.observedAt.formatted(date: .omitted, time: .standard))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            // Require confirmation: fixing a mistake
                            // shouldn't be one itself.
                            occurrencePendingDeletion = occurrence
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    pastOccurrenceDate = .now
                    isAddingPastOccurrence = true
                } label: {
                    Label("Log past occurrence", systemImage: "clock.badge.plus")
                }
            }
        }
        .confirmationDialog(
            "Delete this occurrence?",
            isPresented: Binding(
                get: { occurrencePendingDeletion != nil },
                set: { if !$0 { occurrencePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete occurrence", role: .destructive) {
                if let occurrence = occurrencePendingDeletion {
                    context.delete(occurrence)
                    try? context.save()
                }
                occurrencePendingDeletion = nil
            }
            Button("Cancel", role: .cancel) { occurrencePendingDeletion = nil }
        } message: {
            if let occurrence = occurrencePendingDeletion {
                Text("This will permanently remove the record from "
                     + "\(occurrence.observedAt.formatted(date: .abbreviated, time: .shortened)).")
            }
        }
        .sheet(isPresented: $isAddingPastOccurrence) {
            AddOccurrenceSheet(initialDate: pastOccurrenceDate) { chosenDate in
                context.insert(Occurrence(observedAt: chosenDate, habit: habit))
                try? context.save()
            }
        }
    }
}

/// Back-dating sheet: for occurrences the user forgot to log in real time.
/// Remove this file and the toolbar button if back-dating isn't wanted.
struct AddOccurrenceSheet: View {
    let initialDate: Date
    let onAdd: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    init(initialDate: Date, onAdd: @escaping (Date) -> Void) {
        self.initialDate = initialDate
        self.onAdd = onAdd
        _selectedDate = State(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "Date & time observed",
                    selection: $selectedDate,
                    in: ...Date.now,          // no future occurrences
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
            .navigationTitle("Log Past Occurrence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(selectedDate)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
