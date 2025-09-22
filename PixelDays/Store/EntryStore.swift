import CoreData

final class EntryStore: NSObject, ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case pinned
        case archived

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return String(localized: "All")
            case .pinned: return String(localized: "Pinned")
            case .archived: return String(localized: "Archived")
            }
        }
    }

    @Published private(set) var entries: [Entry] = []

    private let persistence: PersistenceController
    private let context: NSManagedObjectContext
    private var controller: NSFetchedResultsController<Entry>?
    private var filter: Filter = .all
    private var searchText: String = ""

    init(persistence: PersistenceController) {
        self.persistence = persistence
        self.context = persistence.container.viewContext
        super.init()
        configureController()
    }

    func set(filter: Filter) {
        guard self.filter != filter else { return }
        self.filter = filter
        configureController()
    }

    func set(search text: String) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard searchText != normalized else { return }
        searchText = normalized
        configureController()
    }

    func entry(with id: UUID) -> Entry? {
        let request = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    @discardableResult
    func upsert(from draft: EntryDraft) throws -> Entry {
        let entry = entry(with: draft.id) ?? Entry(context: context)
        entry.id = draft.id
        entry.title = draft.title
        entry.entryType = draft.entryType
        entry.startDate = draft.entryType == .countUp ? draft.startDate : nil
        entry.targetDate = draft.entryType == .countDown ? draft.targetDate : nil
        entry.timezone = draft.timezone
        entry.colorHex = draft.colorHex
        entry.iconEmoji = draft.iconEmoji
        entry.notes = draft.notes
        entry.isPinned = draft.isPinned
        entry.isArchived = draft.isArchived
        entry.prepareForSave()
        try context.save()
        return entry
    }

    func delete(_ entry: Entry) throws {
        context.delete(entry)
        try context.save()
    }

    func togglePin(_ entry: Entry) {
        entry.isPinned.toggle()
        entry.prepareForSave()
        saveSilently()
    }

    func toggleArchive(_ entry: Entry) {
        entry.isArchived.toggle()
        if entry.isArchived {
            entry.isPinned = false
        }
        entry.prepareForSave()
        saveSilently()
    }

    func duplicate(_ entry: Entry) {
        let copy = Entry(context: context)
        copy.id = UUID()
        copy.title = entry.title + " " + String(localized: "(Copy)")
        copy.entryType = entry.entryType
        copy.startDate = entry.startDate
        copy.targetDate = entry.targetDate
        copy.timezone = entry.timezone
        copy.colorHex = entry.colorHex
        copy.iconEmoji = entry.iconEmoji
        copy.notes = entry.notes
        copy.isPinned = false
        copy.isArchived = false
        copy.prepareForSave()
        saveSilently()
    }

    private func saveSilently() {
        do {
            try context.save()
        } catch {
            assertionFailure("Core Data save failed: \(error)")
        }
    }

    private func configureController() {
        let request = Entry.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: #keyPath(Entry.isPinned), ascending: false),
            NSSortDescriptor(key: #keyPath(Entry.updatedAt), ascending: false)
        ]
        request.predicate = makePredicate()

        controller = NSFetchedResultsController(fetchRequest: request,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil)
        controller?.delegate = self

        do {
            try controller?.performFetch()
            entries = controller?.fetchedObjects ?? []
        } catch {
            entries = []
            assertionFailure("Failed to fetch entries: \(error)")
        }
    }

    private func makePredicate() -> NSPredicate? {
        var predicates: [NSPredicate] = []
        switch filter {
        case .all:
            predicates.append(NSPredicate(format: "isArchived == NO"))
        case .pinned:
            predicates.append(NSPredicate(format: "isPinned == YES"))
            predicates.append(NSPredicate(format: "isArchived == NO"))
        case .archived:
            predicates.append(NSPredicate(format: "isArchived == YES"))
        }

        if !searchText.isEmpty {
            let search = NSPredicate(format: "(title CONTAINS[cd] %@) OR (notes CONTAINS[cd] %@)", searchText, searchText)
            predicates.append(search)
        }

        guard !predicates.isEmpty else { return nil }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}

extension EntryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        entries = (controller.fetchedObjects as? [Entry]) ?? []
    }
}
