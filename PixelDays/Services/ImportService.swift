import CoreData

final class ImportService {
    struct RowStatus: Identifiable {
        enum State { case success, skipped(String) }
        let id = UUID()
        let title: String
        let state: State
    }

    struct Summary {
        let statuses: [RowStatus]
        var importedCount: Int { statuses.filter { if case .success = $0.state { return true } else { return false } }.count }
        var skippedCount: Int { statuses.count - importedCount }
    }

    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func importEntries(from url: URL) -> Summary {
        var rows: [RowStatus] = []
        let context = persistence.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        context.performAndWait {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let payload = try decoder.decode(ImportPayload.self, from: data)
                guard payload.version == 1 else {
                    let reason = String(localized: "Unsupported import version") + " " + String(payload.version)
                    rows.append(RowStatus(title: String(localized: "Invalid Version"), state: .skipped(reason)))
                    return
                }

                for entry in payload.entries {
                    do {
                        try process(entry, in: context)
                        rows.append(RowStatus(title: entry.title ?? String(localized: "Untitled"), state: .success))
                    } catch {
                        let message = (error as? ImportError)?.message ?? error.localizedDescription
                        rows.append(RowStatus(title: entry.title ?? String(localized: "Untitled"), state: .skipped(message)))
                    }
                }

                if context.hasChanges {
                    try context.save()
                }
            } catch {
                rows.append(RowStatus(title: String(localized: "Import Failed"), state: .skipped(error.localizedDescription)))
            }
        }

        return Summary(statuses: rows)
    }
}

private extension ImportService {
    func process(_ dto: ImportEntryDTO, in context: NSManagedObjectContext) throws {
        let title = (dto.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw ImportError.validation(String(localized: "Title is required")) }
        guard let type = dto.type.flatMap(EntryType.init(rawValue:)) else { throw ImportError.validation(String(localized: "Unsupported type")) }

        let timezoneID = dto.timezone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? TimeZone.current.identifier
        guard let timezone = TimeZone(identifier: timezoneID) else { throw ImportError.validation(String(localized: "Invalid timezone identifier")) }

        let colorHex = sanitize(color: dto.color, current: entry.colorHex)
        let isPinned = dto.isPinned ?? false
        let isArchived = dto.isArchived ?? false

        let entry: Entry
        if let identifier = dto.id, let existing = fetchEntry(with: identifier, in: context) {
            entry = existing
        } else {
            entry = Entry(context: context)
            entry.id = dto.id ?? UUID()
        }

        entry.title = title
        entry.entryType = type
        switch type {
        case .countUp:
            guard let start = dto.startDate else { throw ImportError.validation(String(localized: "startDate is required for countUp")) }
            entry.startDate = start
            entry.targetDate = nil
        case .countDown:
            guard let target = dto.targetDate else { throw ImportError.validation(String(localized: "targetDate is required for countDown")) }
            entry.targetDate = target
            entry.startDate = nil
        }
        entry.timezone = timezone
        entry.colorHex = colorHex
        entry.iconEmoji = dto.iconEmoji
        entry.notes = dto.notes
        entry.isPinned = isPinned
        entry.isArchived = isArchived
        entry.prepareForSave()
    }

    func fetchEntry(with id: UUID, in context: NSManagedObjectContext) -> Entry? {
        let request = Entry.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try? context.fetch(request).first
    }

    func sanitize(color: String?, current: String?) -> String {
        guard let value = color, !value.isEmpty else { return current ?? "#6C8BD6" }
        var hex = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        let valid = Set("0123456789ABCDEF")
        guard hex.count == 6, hex.allSatisfy({ valid.contains($0) }) else {
            return current ?? "#6C8BD6"
        }
        return "#" + hex
    }
}

private enum ImportError: Error {
    case validation(String)

    var message: String {
        switch self {
        case .validation(let reason):
            return reason
        }
    }
}

private struct ImportPayload: Decodable {
    let version: Int
    let entries: [ImportEntryDTO]
}

private struct ImportEntryDTO: Decodable {
    let id: UUID?
    let title: String?
    let type: String?
    let startDate: Date?
    let targetDate: Date?
    let timezone: String?
    let color: String?
    let iconEmoji: String?
    let notes: String?
    let isPinned: Bool?
    let isArchived: Bool?
}
