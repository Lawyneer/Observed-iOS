import SwiftUI
import SwiftData

struct HabitRow: View {
    @Bindable var habit: Habit

    /// Fired when the habit name is tapped: the parent logs an
    /// occurrence right now and shows the undo toast.
    var onLogOccurrence: () -> Void

    /// Fired when the chevron is tapped: the parent pushes the
    /// history screen for this habit.
    var onOpenHistory: () -> Void

    var body: some View {
        HStack(spacing: 12) {

            // Tap target 1: log an occurrence now. This is the
            // majority action, so it gets the whole row minus the
            // trailing chevron.
            Button {
                onLogOccurrence()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(lastObservedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())   // tappable area = full block
            }
            .buttonStyle(.plain)

            // Tap target 2: open history. Drawn as our own chevron
            // because there's no NavigationLink in the row anymore —
            // SwiftUI therefore draws no chevron of its own, and
            // this is the only one on screen.
            Button {
                onOpenHistory()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            // .borderless keeps this button's tap area to the icon
            // itself, so the two targets can't interfere.
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    private var lastObservedDescription: String {
        guard let last = habit.lastOccurrence else { return "Never observed" }
        return "Last observed \(last.observedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}
