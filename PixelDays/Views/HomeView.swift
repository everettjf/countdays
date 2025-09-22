import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var store: EntryStore

    @State private var filter: EntryStore.Filter = .all
    @State private var searchText: String = ""
    @State private var isPresentingEditor = false
    @State private var editingEntry: Entry?
    @State private var draft = EntryDraft()
    @State private var showImporter = false
    @State private var importSummary: ImportService.Summary?
    @State private var showImportSummary = false
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    @State private var showSettings = false
    @State private var showShareSheet = false
    @State private var exportedURL: URL?
    @State private var showDeleteConfirm = false
    @State private var entryPendingDeletion: Entry?
    @State private var showTextImport = false
    @State private var pastedJSON: String = ""

    private var entries: [Entry] { store.entries }
    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 300), spacing: 20)]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        header
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                            if entries.isEmpty {
                                emptyState
                                    .gridCellColumns(columns.count)
                            } else {
                                ForEach(entries) { entry in
                                    EntryListItemView(entry: entry) { entry, action in
                                        handle(action: action, for: entry)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 72)
                    }
                }
                addButton
            }
            .navigationTitle("PixelDays")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(onImport: { showImporter = true },
                             onImportText: { showTextImporter() },
                             onExport: exportEntries)
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
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
            .sheet(isPresented: $showImportSummary) {
                if let summary = importSummary {
                    ImportSummaryView(summary: summary)
                }
            }
            .sheet(isPresented: $showShareSheet, onDismiss: { exportedURL = nil }) {
                if let url = exportedURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showTextImport) {
                TextImportSheet(initialText: pastedJSON) { text in
                    handlePastedJSON(text)
                } onCancel: {
                    showTextImport = false
                    pastedJSON = ""
                }
            }
            .confirmationDialog("Delete Entry?", isPresented: $showDeleteConfirm, presenting: entryPendingDeletion) { entry in
                Button("Delete", role: .destructive) {
                    delete(entry: entry)
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This action cannot be undone.")
            }
            .sheet(isPresented: $isPresentingEditor) {
                EntryEditView(draft: draft, isNew: editingEntry == nil) { newDraft in
                    save(draft: newDraft)
                } onDelete: {
                    if let entry = editingEntry {
                        delete(entry: entry)
                    }
                }
                .presentationDetents([.large, .fraction(0.9)])
            }
            .onAppear {
                store.set(filter: filter)
            }
            .onChange(of: filter) { _, newValue in
                store.set(filter: newValue)
            }
            .onChange(of: searchText) { _, newValue in
                store.set(search: newValue)
            }
            .alert("Error", isPresented: $showErrorAlert, actions: {
                Button("OK") { showErrorAlert = false }
            }, message: {
                Text(errorMessage)
            })
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Filter", selection: $filter) {
                ForEach(EntryStore.Filter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(.secondaryLabel))
                TextField("Search", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .foregroundStyle(Color(.label))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(.separator), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemBackground)))
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 0)
    }

    private var addButton: some View {
        Button {
            draft = EntryDraft(entryType: .countUp, startDate: Date(), timezone: .current)
            editingEntry = nil
            isPresentingEditor = true
        } label: {
            Label("Add Entry", systemImage: "plus")
                .font(.system(.headline, design: .monospaced).weight(.bold))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(addButtonBackground)
                .foregroundColor(.white)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add new entry")
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No entries yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color(.label))
            Text("Tap the + button to add your first countdown or cumulative day tracker.")
                .font(.body)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [6]))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
        )
        .padding(.horizontal, 16)
        .padding(.top, 40)
    }

    private func handle(action: EntryAction, for entry: Entry) {
        switch action {
        case .edit:
            editingEntry = entry
            draft = EntryDraft(entry: entry)
            isPresentingEditor = true
        case .togglePin:
            store.togglePin(entry)
        case .duplicate:
            store.duplicate(entry)
        case .toggleArchive:
            store.toggleArchive(entry)
        case .delete:
            requestDelete(entry)
        }
    }

    private func save(draft: EntryDraft) {
        do {
            try store.upsert(from: draft)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func showTextImporter() {
        pastedJSON = ""
        showTextImport = true
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

    private enum TextImportError: Error {
        case empty
        case invalidEncoding
    }

    private func requestDelete(_ entry: Entry) {
        entryPendingDeletion = entry
        showDeleteConfirm = true
    }

    private func delete(entry: Entry) {
        do {
            try store.delete(entry)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        entryPendingDeletion = nil
        showDeleteConfirm = false
    }

    private var addButtonBackground: some View {
        let base = Color(hex: "#FF6B6B")
        return RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(base)
            .overlay(
                LinearGradient(colors: [base.opacity(0.9), base.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) { pixelCorner(x: -6, y: -6, color: base) }
            .overlay(alignment: .bottomTrailing) { pixelCorner(x: 6, y: 6, color: base) }
            .shadow(color: base.opacity(0.35), radius: 10, x: 0, y: 6)
    }

    private func pixelCorner(x: CGFloat, y: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .offset(x: x, y: y)
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
}
