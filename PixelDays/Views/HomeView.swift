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

    private var entries: [Entry] { store.entries }

    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 300), spacing: 20)]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color(hex: "#0B0F14").ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
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
                        .padding(.bottom, 96)
                    }
                }
                addButton
            }
            .navigationTitle(String(localized: "PixelDays"))
            .toolbarBackground(Color(hex: "#0F141D"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label(String(localized: "Settings"), systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showImporter = true
                    } label: {
                        Label(String(localized: "Import JSON"), systemImage: "tray.and.arrow.down")
                    }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    let summary = ImportService(store: store).importEntries(from: url)
                    importSummary = summary
                    showImportSummary = true
                case .failure(let error):
                    let status = ImportService.RowStatus(title: String(localized: "Import Failed"), state: .skipped(error.localizedDescription))
                    importSummary = ImportService.Summary(statuses: [status])
                    showImportSummary = true
                }
            }
            .sheet(isPresented: $showImportSummary) {
                if let summary = importSummary {
                    ImportSummaryView(summary: summary)
                }
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
            .onChange(of: filter) { newValue in
                store.set(filter: newValue)
            }
            .onChange(of: searchText) { newValue in
                store.set(search: newValue)
            }
            .alert(String(localized: "Error"), isPresented: $showErrorAlert, actions: {
                Button(String(localized: "OK")) { showErrorAlert = false }
            }, message: {
                Text(errorMessage)
            })
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker(String(localized: "Filter"), selection: $filter) {
                ForEach(EntryStore.Filter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.6))
                TextField(String(localized: "Search"), text: $searchText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 2)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(hex: "#121A23")))
            )
            .padding(.horizontal, 16)
        }
        .padding(.top, 24)
    }

    private var addButton: some View {
        Button {
            draft = EntryDraft(entryType: .countUp, startDate: Date(), timezone: .current)
            editingEntry = nil
            isPresentingEditor = true
        } label: {
            Label(String(localized: "Add Entry"), systemImage: "plus")
                .font(.system(.headline, design: .monospaced).weight(.bold))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#00E5FF"))
                        .shadow(color: Color(hex: "#00E5FF").opacity(0.6), radius: 12, x: 0, y: 8)
                )
                .foregroundStyle(Color(hex: "#0B0F14"))
        }
        .padding(24)
        .accessibilityLabel(String(localized: "Add new entry"))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "No entries yet"))
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text(String(localized: "Tap the + button to add your first countdown or cumulative day tracker."))
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [6]))
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "#101720")))
        )
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
            delete(entry: entry)
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

    private func delete(entry: Entry) {
        do {
            try store.delete(entry)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
