import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = false

    var body: some View {
        List {
            Section("Notifications") {
                Toggle(isOn: $notificationsEnabled) {
                    Text("Alert me when a countdown reaches zero")
                }
                .onChange(of: notificationsEnabled) { value in
                    if value {
                        NotificationService.shared.requestAuthorization()
                    }
                }
            }

            Section("Data") {
                NavigationLink(destination: ImportHelpView()) {
                    Label("How to import JSON", systemImage: "doc.badge.plus")
                }
                Label("Export (coming soon)", systemImage: "square.and.arrow.up")
                    .foregroundColor(.secondary)
            }

            Section("About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PixelDays")
                        .font(.headline)
                    Text("A pixel-styled day counter for the moments that matter.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

private struct ImportHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("JSON Import")
                    .font(.title2.weight(.bold))
                Text("Prepare a JSON file that matches the v1 schema and use the Import button on the home screen. Each row will be validated and reported in the import summary.")
                Text("Tip: You can start from the bundled sample file `sample_import.json` inside the app bundle.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Import Help")
    }
}
