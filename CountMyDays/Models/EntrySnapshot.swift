import Foundation

struct EntrySnapshot: Identifiable {
    let id: UUID
    let title: String
    let entryType: EntryType
    let startDate: Date?
    let targetDate: Date?
    let timezone: TimeZone
    let colorHex: String
    let iconEmoji: String?
    let notes: String?
    let isPinned: Bool
    let isArchived: Bool

    init(id: UUID,
         title: String,
         entryType: EntryType,
         startDate: Date?,
         targetDate: Date?,
         timezone: TimeZone,
         colorHex: String,
         iconEmoji: String?,
         notes: String?,
         isPinned: Bool,
         isArchived: Bool) {
        self.id = id
        self.title = title
        self.entryType = entryType
        self.startDate = startDate
        self.targetDate = targetDate
        self.timezone = timezone
        self.colorHex = colorHex
        self.iconEmoji = iconEmoji
        self.notes = notes
        self.isPinned = isPinned
        self.isArchived = isArchived
    }

    init(entry: Entry) {
        id = entry.id
        title = entry.title
        entryType = entry.entryType
        startDate = entry.startDate
        targetDate = entry.targetDate
        timezone = entry.timezone
        colorHex = entry.colorHex
        iconEmoji = entry.iconEmoji
        notes = entry.notes
        isPinned = entry.isPinned
        isArchived = entry.isArchived
    }

    init(draft: EntryDraft) {
        id = draft.id
        title = draft.title
        entryType = draft.entryType
        startDate = draft.startDate
        targetDate = draft.targetDate
        timezone = draft.timezone
        colorHex = draft.colorHex
        iconEmoji = draft.iconEmoji
        notes = draft.notes
        isPinned = draft.isPinned
        isArchived = draft.isArchived
    }
}
