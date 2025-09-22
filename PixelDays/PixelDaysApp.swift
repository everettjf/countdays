import SwiftUI

@main
struct PixelDaysApp: App {
    let persistence: PersistenceController
    @StateObject private var entryStore: EntryStore

    init() {
        let controller = PersistenceController.shared
        persistence = controller
        _entryStore = StateObject(wrappedValue: EntryStore(persistence: controller))
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(entryStore)
        }
    }
}
