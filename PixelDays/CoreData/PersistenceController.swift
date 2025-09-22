import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        context.performAndWait {
            let sample = Entry(context: context)
            sample.id = UUID()
            sample.title = "Sample Entry"
            sample.type = EntryType.countUp.rawValue
            sample.startDate = Date().addingTimeInterval(-3 * 86_400)
            sample.timezoneID = TimeZone.current.identifier
            sample.colorHex = "#6C8BD6"
            sample.createdAt = Date()
            sample.updatedAt = Date()
        }
        controller.save()
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PixelDays")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error: \(error), userInfo: \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.shouldDeleteInaccessibleFaults = true
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    func save(context: NSManagedObjectContext? = nil) {
        let context = context ?? container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            // During development we crash fast to highlight persistence issues
            let nserror = error as NSError
            fatalError("Unresolved Core Data save error: \(nserror), userInfo: \(nserror.userInfo)")
        }
    }
}
