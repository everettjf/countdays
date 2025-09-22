import SwiftUI

@main
struct PixelDaysApp: App {
    @StateObject private var entryStore = EntryStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(entryStore)
        }
    }
}
