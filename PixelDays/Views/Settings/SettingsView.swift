import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let onImport: () -> Void
    let onImportText: () -> Void
    let onExport: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    
                    NavigationLink {
                        ImportExportGuideView(onImport: { dismissAnd(onImport) },
                                               onExport: { dismissAnd(onExport) })
                    } label: {
                        Label("Import & Export Guide", systemImage: "questionmark.circle")
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Import from a file or paste JSON directly. You'll review the summary before anything is saved.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button { dismissAnd(onImport) } label: {
                                Label("Import JSON", systemImage: "tray.and.arrow.down")
                            }
                            Divider()
                            Button { dismissAnd(onImportText) } label: {
                                Label("Paste JSON", systemImage: "doc.on.doc")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Create a portable snapshot using the same schema—great for backups or sharing.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button { dismissAnd(onExport) } label: {
                            Label("Export JSON", systemImage: "square.and.arrow.up")
                        }
                    }
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func dismissAnd(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.async { action() }
    }
}
