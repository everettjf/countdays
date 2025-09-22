import Foundation

struct EntryDraft: Identifiable {
    var id: UUID
    var title: String
    var entryType: EntryType
    var startDate: Date?
    var targetDate: Date?
    var timezone: TimeZone
    var colorHex: String
    var iconEmoji: String?
    var notes: String?
    var isPinned: Bool
    var isArchived: Bool

    init(id: UUID = UUID(),
         title: String = "",
         entryType: EntryType = .countUp,
         startDate: Date? = nil,
         targetDate: Date? = nil,
         timezone: TimeZone = .current,
         colorHex: String = "#6C8BD6",
         iconEmoji: String? = nil,
         notes: String? = nil,
         isPinned: Bool = false,
         isArchived: Bool = false) {
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
        colorHex = entry.colorHex ?? "#6C8BD6"
        iconEmoji = entry.iconEmoji
        notes = entry.notes
        isPinned = entry.isPinned
        isArchived = entry.isArchived
    }

    var dateForDisplay: Date? {
        entryType == .countUp ? startDate : targetDate
    }
}
