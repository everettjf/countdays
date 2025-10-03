import SwiftUI

@main
struct CountMyDaysApp: App {
    @StateObject private var entryStore = EntryStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environmentObject(entryStore)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                AppReviewManager.registerAppLaunch()
            }
        }
    }
}
