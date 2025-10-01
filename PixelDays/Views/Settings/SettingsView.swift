import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onImport: () -> Void
    let onImportText: () -> Void
    let onExport: () -> Void

    private var layout: SettingsLayout {
        SettingsLayout(horizontalSizeClass: horizontalSizeClass, dynamicTypeSize: dynamicTypeSize)
    }

    private let supportEmailURL = URL(string: "mailto:xnuapp@gmail.com")
    private let websiteURL = URL(string: "https://xnu.app/countmydays")

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

                    Menu {
                        Button {
                            dismissAnd(onImport)
                        } label: {
                            Label("Import JSON from File", systemImage: "tray.and.arrow.down")
                        }
                        Button {
                            dismissAnd(onImportText)
                        } label: {
                            Label("Import from Clipboard", systemImage: "doc.on.doc")
                        }
                        Button {
                            dismissAnd(onExport)
                        } label: {
                            Label("Export JSON", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Label("Manage Data", systemImage: "folder.badge.gear")
                    }
                }

                Section("Support") {
                    if let supportEmailURL {
                        Button {
                            dismissAndOpen(supportEmailURL)
                        } label: {
                            Label("Email Support", systemImage: "envelope")
                        }
                    }

                    if let websiteURL {
                        Button {
                            dismissAndOpen(websiteURL)
                        } label: {
                            Label("Visit Website", systemImage: "globe")
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
            .modifier(CenteredListModifier(layout: layout))
        }
    }

    private func dismissAnd(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.async { action() }
    }

    private func dismissAndOpen(_ url: URL) {
        dismiss()
        DispatchQueue.main.async {
            openURL(url)
        }
    }
}

private struct SettingsLayout {
    let contentWidth: CGFloat?
    let horizontalPadding: CGFloat

    init(horizontalSizeClass: UserInterfaceSizeClass?, dynamicTypeSize: DynamicTypeSize) {
        let useWideLayout = horizontalSizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
        contentWidth = useWideLayout ? 520 : nil
        horizontalPadding = useWideLayout ? 24 : 0
    }
}

private struct CenteredListModifier: ViewModifier {
    let layout: SettingsLayout

    func body(content: Content) -> some View {
        Group {
            if let width = layout.contentWidth {
                content
                    .frame(maxWidth: width)
                    .padding(.horizontal, layout.horizontalPadding)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                content
            }
        }
    }
}
