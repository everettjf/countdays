import SwiftUI

@main
struct CountMyDaysApp: App {
    @StateObject private var entryStore = EntryStore()

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(entryStore)
        }
    }
}
