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
                rows.append(RowStatus(title: "Invalid Version", state: .skipped("Unsupported import version \(payload.version)")))
                return Summary(statuses: rows)
            }

            for dto in payload.entries {
                let displayTitle = (dto.title ?? "Untitled").trimmingCharacters(in: .whitespacesAndNewlines)
                do {
                    let entry = try process(dto)
                    imported.append(entry)
                    rows.append(RowStatus(title: displayTitle.isEmpty ? "Untitled" : displayTitle, state: .success))
                } catch let error as ImportError {
                    rows.append(RowStatus(title: displayTitle.isEmpty ? "Untitled" : displayTitle, state: .skipped(error.message)))
                } catch {
                    rows.append(RowStatus(title: displayTitle.isEmpty ? "Untitled" : displayTitle, state: .skipped(error.localizedDescription)))
                }
            }

            if !imported.isEmpty {
                store.importEntries(imported)
            }
        } catch {
            rows.append(RowStatus(title: "Import Failed", state: .skipped(error.localizedDescription)))
        }

        return Summary(statuses: rows)
    }
}

private extension ImportService {
    func process(_ dto: ImportEntryDTO) throws -> Entry {
        let title = (dto.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw ImportError.validation("Title is required") }
        guard let type = dto.type.flatMap(EntryType.init(rawValue:)) else { throw ImportError.validation("Unsupported type") }

        let timezoneID = dto.timezone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? TimeZone.current.identifier
        guard let timezone = TimeZone(identifier: timezoneID) else { throw ImportError.validation("Invalid timezone identifier") }

        let identifier = dto.id ?? UUID()
        if store.entry(with: identifier) != nil {
            throw ImportError.duplicate("Entry already exists – skipped")
        }

        var entry = Entry(id: identifier, title: title, entryType: type, timezoneID: timezoneID)
        entry.colorHex = sanitize(color: dto.color, current: entry.colorHex)
        entry.iconEmoji = dto.iconEmoji?.isEmpty == true ? nil : dto.iconEmoji
        entry.notes = dto.notes
        entry.isArchived = dto.isArchived ?? false
        entry.isPinned = (dto.isPinned ?? false) && !entry.isArchived

        switch type {
        case .countUp:
            guard let start = dto.startDate else { throw ImportError.validation("startDate is required for countUp") }
            entry.startDate = DayCounter.startOfDay(start, in: timezone)
            entry.targetDate = nil
        case .countDown:
            guard let target = dto.targetDate else { throw ImportError.validation("targetDate is required for countDown") }
            entry.targetDate = DayCounter.startOfDay(target, in: timezone)
            entry.startDate = nil
        }

        entry.stampTimestamps(asNew: true)
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
    case duplicate(String)

    var message: String {
        switch self {
        case .validation(let reason):
            return reason
        case .duplicate(let reason):
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
