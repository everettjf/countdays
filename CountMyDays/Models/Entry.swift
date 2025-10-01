import Foundation

struct Entry: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var entryType: EntryType
    var startDate: Date?
    var targetDate: Date?
    var timezoneID: String
    var colorHex: String
    var iconEmoji: String?
    var notes: String?
    var isPinned: Bool
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(),
         title: String,
         entryType: EntryType,
         startDate: Date? = nil,
         targetDate: Date? = nil,
         timezoneID: String = TimeZone.current.identifier,
         colorHex: String = TrendingCardPalettes.defaultHex,
         iconEmoji: String? = nil,
         notes: String? = nil,
         isPinned: Bool = false,
         isArchived: Bool = false,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.entryType = entryType
        self.startDate = startDate
        self.targetDate = targetDate
        self.timezoneID = timezoneID
        self.colorHex = colorHex
        self.iconEmoji = iconEmoji
        self.notes = notes
        self.isPinned = isPinned
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var timezone: TimeZone {
        TimeZone(identifier: timezoneID) ?? .current
    }

    func updating(_ block: (inout Entry) -> Void) -> Entry {
        var copy = self
        block(&copy)
        return copy
    }

    mutating func stampTimestamps(asNew: Bool) {
        let now = Date()
        if asNew {
            createdAt = now
        }
        updatedAt = now
        if colorHex.isEmpty { colorHex = TrendingCardPalettes.defaultHex }
        if timezoneID.isEmpty { timezoneID = TimeZone.current.identifier }
    }
}
