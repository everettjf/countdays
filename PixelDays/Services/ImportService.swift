import Foundation

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

    private unowned let store: EntryStore

    init(store: EntryStore) {
        self.store = store
    }

    func importEntries(from url: URL) -> Summary {
        var rows: [RowStatus] = []
        var imported: [Entry] = []

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(ImportPayload.self, from: data)
            guard payload.version == 1 else {
                let reason = String(localized: "Unsupported import version") + " " + String(payload.version)
                rows.append(RowStatus(title: String(localized: "Invalid Version"), state: .skipped(reason)))
                return Summary(statuses: rows)
            }

            for dto in payload.entries {
                do {
                    let entry = try process(dto)
                    imported.append(entry)
                    rows.append(RowStatus(title: dto.title ?? String(localized: "Untitled"), state: .success))
                } catch {
                    let message = (error as? ImportError)?.message ?? error.localizedDescription
                    rows.append(RowStatus(title: dto.title ?? String(localized: "Untitled"), state: .skipped(message)))
                }
            }

            if !imported.isEmpty {
                store.importEntries(imported)
            }
        } catch {
            rows.append(RowStatus(title: String(localized: "Import Failed"), state: .skipped(error.localizedDescription)))
        }

        return Summary(statuses: rows)
    }
}

private extension ImportService {
    func process(_ dto: ImportEntryDTO) throws -> Entry {
        let title = (dto.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw ImportError.validation(String(localized: "Title is required")) }
        guard let type = dto.type.flatMap(EntryType.init(rawValue:)) else { throw ImportError.validation(String(localized: "Unsupported type")) }

        let timezoneID = dto.timezone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? TimeZone.current.identifier
        guard let _ = TimeZone(identifier: timezoneID) else { throw ImportError.validation(String(localized: "Invalid timezone identifier")) }

        let isPinned = dto.isPinned ?? false
        let isArchived = dto.isArchived ?? false

        let identifier = dto.id ?? UUID()
        let existing = store.entry(with: identifier)
        var entry = existing ?? Entry(id: identifier, title: title, entryType: type, timezoneID: timezoneID)

        entry.title = title
        entry.entryType = type
        entry.timezoneID = timezoneID
        entry.colorHex = sanitize(color: dto.color, current: existing?.colorHex ?? entry.colorHex)
        entry.iconEmoji = dto.iconEmoji?.isEmpty == true ? nil : dto.iconEmoji
        entry.notes = dto.notes
        entry.isArchived = isArchived
        entry.isPinned = isPinned && !isArchived

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

        entry.stampTimestamps(asNew: existing == nil)
        return entry
    }

    func sanitize(color: String?, current: String) -> String {
        guard let value = color, !value.isEmpty else { return current }
        var hex = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") { hex.removeFirst() }
        let valid = Set("0123456789ABCDEF")
        guard hex.count == 6, hex.allSatisfy({ valid.contains($0) }) else {
            return current
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
