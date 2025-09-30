import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var store: EntryStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var filter: EntryStore.Filter = .all
    @State private var searchText: String = ""
    @State private var editingEntry: Entry?
    @State private var activeDraft: EntryDraft?
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
    private var layout: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: horizontalSizeClass,
                      verticalSizeClass: verticalSizeClass,
                      dynamicTypeSize: dynamicTypeSize)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: layout.minColumnWidth, maximum: layout.maxColumnWidth),
                  spacing: layout.gridSpacing)]
    }

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("CountMyDays")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent() }
        }
        .sheet(isPresented: $showSettings, content: settingsSheet)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], onCompletion: handleFileImport)
        .sheet(isPresented: $showImportSummary, content: importSummarySheet)
        .sheet(isPresented: $showShareSheet, onDismiss: { exportedURL = nil }, content: shareSheet)
        .sheet(isPresented: $showTextImport, content: textImportSheet)
        .confirmationDialog("Delete Entry?", isPresented: $showDeleteConfirm, presenting: entryPendingDeletion, actions: { entry in
            deleteDialogActions(for: entry)
        }, message: { entry in
            deleteDialogMessage(entry)
        })
        .sheet(item: $activeDraft, content: editorSheet(for:))
        .onAppear(perform: configureInitialFilter)
        .onChange(of: filter) { _, newFilter in
            updateFilter(newFilter)
        }
        .onChange(of: searchText) { _, newSearch in
            updateSearch(newSearch)
        }
        .alert("Error", isPresented: $showErrorAlert, actions: {
            errorAlertActions()
        }, message: {
            errorAlertMessage()
        })
        .onChange(of: activeDraft) { _, newDraft in
            syncEditingEntry(newDraft)
        }
    }

    private var header: some View {
        contentContainer {
            Group {
                if layout.usesHorizontalHeader {
                    HStack(alignment: .center, spacing: layout.horizontalHeaderSpacing) {
                        if let maxWidth = layout.filterMaxWidth {
                            filterPickerView
                                .frame(maxWidth: maxWidth)
                        } else {
                            filterPickerView
                        }
                        searchFieldView
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(alignment: .leading, spacing: layout.headerSpacing) {
                        filterPickerView
                            .frame(maxWidth: .infinity)
                        searchFieldView
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.top, layout.headerTopPadding)
        .padding(.bottom, layout.headerBottomPadding)
    }

    private var entriesGrid: some View {
        contentContainer {
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: layout.gridSpacing) {
                if entries.isEmpty {
                    emptyState
                        .gridCellColumns(gridColumns.count)
                } else {
                    ForEach(entries) { entry in
                        entryItem(for: entry)
                    }
                }
            }
            .padding(.top, layout.gridTopPadding)
            .padding(.bottom, layout.gridBottomPadding)
        }
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
        .padding(layout.emptyStatePadding)
        .padding(.top, layout.emptyStateTopSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [6]))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
        )
    }

    private var mainContent: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    entriesGrid
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                editingEntry = nil
                activeDraft = EntryDraft(entryType: .countUp, startDate: Date(), timezone: .current)
            } label: {
                Label("Add Entry", systemImage: "plus")
            }
        }
    }

    @ViewBuilder
    private func entryItem(for entry: Entry) -> some View {
        EntryListItemView(entry: entry) { tappedEntry, action in
            handle(action: action, for: tappedEntry)
        }
    }

    private func handle(action: EntryAction, for entry: Entry) {
        switch action {
        case .edit:
            editingEntry = entry
            activeDraft = EntryDraft(entry: entry)
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
            editingEntry = nil
            activeDraft = nil
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func showTextImporter() {
        print("🔍 Debug: Paste JSON button clicked - showing text importer")
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
        activeDraft = nil
        editingEntry = nil
        entryPendingDeletion = nil
        showDeleteConfirm = false
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
    private func settingsSheet() -> some View {
        SettingsView(onImport: {
            print("🔍 Debug: Import JSON button clicked - showing file importer")
            showImporter = true
        },
                     onImportText: { showTextImporter() },
                     onExport: exportEntries)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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

    @ViewBuilder
    private func importSummarySheet() -> some View {
        if let summary = importSummary {
            ImportSummaryView(summary: summary)
        }
    }

    @ViewBuilder
    private func shareSheet() -> some View {
        if let url = exportedURL {
            ShareSheet(activityItems: [url])
        }
    }

    private func textImportSheet() -> some View {
        TextImportSheet(initialText: pastedJSON) { text in
            handlePastedJSON(text)
        } onCancel: {
            showTextImport = false
            pastedJSON = ""
        }
    }

    @ViewBuilder
    private func deleteDialogActions(for entry: Entry) -> some View {
        Button("Delete", role: .destructive) {
            delete(entry: entry)
        }
        Button("Cancel", role: .cancel) {}
    }

    private func deleteDialogMessage(_ entry: Entry) -> Text {
        Text("This action cannot be undone.")
    }

    private func editorSheet(for draft: EntryDraft) -> some View {
        EntryEditView(draft: draft, isNew: editingEntry == nil) { newDraft in
            save(draft: newDraft)
        } onDelete: {
            if let entry = editingEntry {
                delete(entry: entry)
            }
        }
        .presentationDetents([.large])
    }

    private func configureInitialFilter() {
        store.set(filter: filter)
    }

    private func updateFilter(_ filter: EntryStore.Filter) {
        store.set(filter: filter)
    }

    private func updateSearch(_ text: String) {
        store.set(search: text)
    }

    @ViewBuilder
    private func errorAlertActions() -> some View {
        Button("OK") { showErrorAlert = false }
    }

    private func errorAlertMessage() -> Text {
        Text(errorMessage)
    }

    private func syncEditingEntry(_ draft: EntryDraft?) {
        if draft == nil {
            editingEntry = nil
        }
    }
}

// MARK: - Layout Helpers

private extension HomeView {
    func contentContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            if let width = layout.contentWidth {
                content()
                    .frame(maxWidth: width, alignment: .leading)
            } else {
                content()
            }
        }
        .padding(.horizontal, layout.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: layout.contentAlignment)
    }

    var filterPickerView: some View {
        Picker("Filter", selection: $filter) {
            ForEach(EntryStore.Filter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    var searchFieldView: some View {
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
    }
}

private struct LayoutMetrics {
    let contentWidth: CGFloat?
    let horizontalPadding: CGFloat
    let usesHorizontalHeader: Bool
    let headerSpacing: CGFloat
    let horizontalHeaderSpacing: CGFloat
    let filterMaxWidth: CGFloat?
    let headerTopPadding: CGFloat
    let headerBottomPadding: CGFloat
    let gridSpacing: CGFloat
    let gridTopPadding: CGFloat
    let gridBottomPadding: CGFloat
    let emptyStatePadding: CGFloat
    let emptyStateTopSpacing: CGFloat
    let minColumnWidth: CGFloat
    let maxColumnWidth: CGFloat
    let contentAlignment: Alignment

    init(horizontalSizeClass: UserInterfaceSizeClass?,
         verticalSizeClass: UserInterfaceSizeClass?,
         dynamicTypeSize: DynamicTypeSize) {
        let prefersWideLayout = horizontalSizeClass == .regular && verticalSizeClass != .compact
        let isAccessibility = dynamicTypeSize.isAccessibilitySize
        let useWide = prefersWideLayout && !isAccessibility

        usesHorizontalHeader = useWide
        contentWidth = useWide ? 840 : nil
        horizontalPadding = useWide ? 32 : 16
        headerSpacing = useWide ? 16 : 10
        horizontalHeaderSpacing = useWide ? 20 : 12
        filterMaxWidth = useWide ? 340 : nil
        headerTopPadding = useWide ? 28 : 12
        headerBottomPadding = useWide ? 8 : 12
        gridSpacing = useWide ? 28 : 20
        gridTopPadding = useWide ? 8 : 12
        gridBottomPadding = useWide ? 140 : 84
        emptyStatePadding = useWide ? 28 : 20
        emptyStateTopSpacing = useWide ? 48 : 32
        minColumnWidth = useWide ? 320 : 260
        maxColumnWidth = useWide ? 420 : 360
        contentAlignment = useWide ? .center : .leading
    }
}
