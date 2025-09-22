import SwiftUI

enum EntryAction {
    case edit
    case togglePin
    case duplicate
    case toggleArchive
    case delete
}

struct EntryListItemView: View {
    let entry: Entry
    var onAction: (Entry, EntryAction) -> Void

    var body: some View {
        EntryCardView(snapshot: EntrySnapshot(entry: entry))
            .contextMenu {
                Button(entry.isPinned ? "Unpin" : "Pin") {
                    onAction(entry, .togglePin)
                }
                Button(entry.isArchived ? "Unarchive" : "Archive") {
                    onAction(entry, .toggleArchive)
                }
                Button("Duplicate") {
                    onAction(entry, .duplicate)
                }
                Divider()
                Button("Edit") {
                    onAction(entry, .edit)
                }
                Button(role: .destructive) {
                    onAction(entry, .delete)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .onTapGesture {
                onAction(entry, .edit)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let days = DayCounter.days(for: entry)
        let formatter = DateFormatters.accessibilityFormatter
        let daysString = formatter.string(from: DateComponents(day: abs(days))) ?? "\(abs(days)) days"
        switch entry.entryType {
        case .countUp:
            if days >= 0 {
                return "\(entry.title), \(daysString) since start"
            } else {
                return "\(entry.title), starts in \(daysString)"
            }
        case .countDown:
            if days >= 0 {
                return "\(entry.title), \(daysString) remaining"
            } else {
                return "\(entry.title), target passed \(daysString) ago"
            }
        }
    }
}
