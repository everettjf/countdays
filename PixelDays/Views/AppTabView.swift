import SwiftUI
import UniformTypeIdentifiers

struct AppTabView: View {
    private enum Tab: Hashable {
        case all
        case pinned
        case archived

        var title: String {
            switch self {
            case .all: return "All"
            case .pinned: return "Pinned"
            case .archived: return "Archived"
            }
        }

        var systemImage: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .pinned: return "pin"
            case .archived: return "archivebox"
            }
        }

        var filter: EntryStore.Filter {
            switch self {
            case .all: return .all
            case .pinned: return .pinned
            case .archived: return .archived
            }
        }
    }

    @EnvironmentObject private var store: EntryStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var selection: Tab = .all

    @State private var showImporter = false
    @State private var importSummary: ImportService.Summary?
    @State private var showImportSummary = false
    @State private var showShareSheet = false
    @State private var exportedURL: URL?
    @State private var showTextImport = false
    @State private var pastedJSON: String = ""
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var showSettings = false

    private var supportsLiquidGlass: Bool {
        horizontalSizeClass == .regular && verticalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize
    }

    private var adaptiveSheetDetents: Set<PresentationDetent> {
        supportsLiquidGlass ? [.fraction(0.55), .fraction(0.8), .large] : [.medium, .large]
    }

    private var adaptiveSheetCornerRadius: CGFloat {
        supportsLiquidGlass ? 32 : 20
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if supportsLiquidGlass {
                LiquidGlassTabBackground()
                    .transition(.opacity)
            }

            TabView(selection: $selection) {
                ForEach([Tab.all, .pinned, .archived], id: \.self) { tab in
                    HomeView(initialFilter: tab.filter,
                             showsFilterPicker: false,
                             onShowSettings: { showSettings = true })
                        .tabItem {
                            Label(tab.title, systemImage: tab.systemImage)
                        }
                        .tag(tab)
                }
            }
            .tabViewStyle(.automatic)
            .toolbarBackground(supportsLiquidGlass ? .hidden : .visible, for: .tabBar)
            .toolbarBackground(supportsLiquidGlass ? .hidden : .visible, for: .bottomBar)
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], onCompletion: handleFileImport)
        .sheet(isPresented: $showImportSummary, content: importSummarySheet)
        .sheet(isPresented: $showShareSheet, onDismiss: { exportedURL = nil }, content: shareSheet)
        .sheet(isPresented: $showTextImport, content: textImportSheet)
        .sheet(isPresented: $showSettings, content: settingsSheet)
        .alert("Error", isPresented: $showErrorAlert, actions: {
            Button("OK", role: .cancel) { showErrorAlert = false }
        }, message: {
            Text(errorMessage)
        })
    }

    private func presentTextImport() {
        pastedJSON = ""
        showTextImport = true
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let summary = ImportService(store: store).importEntries(from: url)
            importSummary = summary
            showImportSummary = true
        case .failure(let error):
            let status = ImportService.RowStatus(title: "Import Failed", state: .skipped(error.localizedDescription))
            importSummary = ImportService.Summary(statuses: [status])
            showImportSummary = true
        }
    }

    private func handlePastedJSON(_ text: String) {
        do {
            let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else { throw TextImportError.empty }
            guard let data = cleaned.data(using: .utf8) else { throw TextImportError.invalidEncoding }
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
            try data.write(to: tempURL, options: .atomic)
            let summary = ImportService(store: store).importEntries(from: tempURL)
            importSummary = summary
            showImportSummary = true
        } catch TextImportError.empty {
            errorMessage = "Paste some JSON before importing."
            showErrorAlert = true
        } catch TextImportError.invalidEncoding {
            errorMessage = "The pasted text is not valid UTF-8."
            showErrorAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        showTextImport = false
        pastedJSON = ""
    }

    private func exportEntries() {
        do {
            let items = store.allItems()
            guard !items.isEmpty else {
                errorMessage = "Nothing to export yet. Add an entry first."
                showErrorAlert = true
                return
            }
            let url = try ExportService().export(entries: items)
            exportedURL = url
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    @ViewBuilder
    private func importSummarySheet() -> some View {
        if let summary = importSummary {
            ImportSummaryView(summary: summary)
                .presentationDetents(adaptiveSheetDetents)
                .presentationCornerRadius(adaptiveSheetCornerRadius)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func shareSheet() -> some View {
        if let url = exportedURL {
            ShareSheet(activityItems: [url])
                .presentationDetents(adaptiveSheetDetents)
                .presentationCornerRadius(adaptiveSheetCornerRadius)
        }
    }

    private func textImportSheet() -> some View {
        TextImportSheet(initialText: pastedJSON) { text in
            handlePastedJSON(text)
        } onCancel: {
            showTextImport = false
            pastedJSON = ""
        }
        .presentationDetents(adaptiveSheetDetents)
        .presentationCornerRadius(adaptiveSheetCornerRadius)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func settingsSheet() -> some View {
        SettingsView(onImport: {
            showImporter = true
        },
                     onImportText: { presentTextImport() },
                     onExport: exportEntries)
        .presentationDetents(adaptiveSheetDetents)
        .presentationCornerRadius(adaptiveSheetCornerRadius)
        .presentationDragIndicator(.visible)
    }

    private enum TextImportError: Error {
        case empty
        case invalidEncoding
    }
}

private struct LiquidGlassTabBackground: View {
    private let cornerRadius: CGFloat = 28

    var body: some View {
        GeometryReader { proxy in
            let width = min(proxy.size.width - 48, 620)

            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(colors: [Color.white.opacity(0.32), Color.white.opacity(0.05)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            )
                            .blendMode(.plusLighter)
                            .opacity(0.7)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 18, x: 0, y: 12)
                    .frame(width: width, height: 72)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 12))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
}
