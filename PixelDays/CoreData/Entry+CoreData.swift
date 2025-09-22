import Foundation
import CoreData

@objc(Entry)
public class Entry: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        NSFetchRequest<Entry>(entityName: "Entry")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var startDate: Date?
    @NSManaged public var targetDate: Date?
    @NSManaged public var timezoneID: String
    @NSManaged public var colorHex: String?
    @NSManaged public var iconEmoji: String?
    @NSManaged public var notes: String?
    @NSManaged public var isPinned: Bool
    @NSManaged public var isArchived: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension Entry {
    var entryType: EntryType {
        get { EntryType(rawValue: type) ?? .countUp }
        set { type = newValue.rawValue }
    }

    var timezone: TimeZone {
        get { TimeZone(identifier: timezoneID) ?? .current }
        set { timezoneID = newValue.identifier }
    }

    func prepareForSave() {
        let now = Date()
        if isInserted {
            createdAt = now
        }
        updatedAt = now
        if colorHex == nil || colorHex?.isEmpty == true {
            colorHex = "#6C8BD6"
        }
        if timezoneID.isEmpty {
            timezoneID = TimeZone.current.identifier
        }
    }
}


extension Entry: Identifiable {}
