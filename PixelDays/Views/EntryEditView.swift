import SwiftUI

struct EntryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    var isNew: Bool
    var onSave: (EntryDraft) -> Void
    var onDelete: (() -> Void)?

    @State private var showingTimeZonePicker = false
    @FocusState private var focusTitle: Bool
    @State private var showDeleteConfirmation = false

    private let colorPalette: [TrendingCardPalette] = TrendingCardPalettes.all

    init(draft: EntryDraft, isNew: Bool, onSave: @escaping (EntryDraft) -> Void, onDelete: (() -> Void)? = nil) {
        _draft = State(initialValue: draft)
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $draft.title)
                        .font(.system(.body, design: .rounded))
                        .focused($focusTitle)
                    Picker("Type", selection: $draft.entryType) {
                        ForEach(EntryType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(draft.entryType == .countUp ? "Start" : "Target") {
                    if draft.entryType == .countUp {
                        DatePicker("Start Date", selection: Binding($draft.startDate, replacingNilWith: Date()), displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    } else {
                        DatePicker("Target Date", selection: Binding($draft.targetDate, replacingNilWith: Date()), displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                    }

                    Button {
                        showingTimeZonePicker = true
                    } label: {
                        HStack {
                            Text("Time Zone")
                            Spacer()
                            Text(draft.timezone.displayName)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 12), count: 5), spacing: 12) {
                            ForEach(colorPalette) { palette in
                                Circle()
                                    .fill(LinearGradient(
                                        colors: palette.colors.map { Color(hex: $0) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                Color.white.opacity(isSelected(palette) ? 0.9 : 0.2),
                                                lineWidth: isSelected(palette) ? 3 : 1
                                            )
                                    )
                                    .onTapGesture {
                                        draft.colorHex = palette.primaryHex
                                    }
                            }
                        }

                        Text("Notes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                        TextEditor(text: Binding($draft.notes, replacingNilWith: ""))
                            .frame(minHeight: 80)
                    }
                    .padding(.vertical, 4)
                }

                Section("Preview") {
                    EntryCardView(snapshot: EntrySnapshot(draft: draft))
                        .padding(.vertical, 8)
                }

                if !isNew, onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isNew ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isFormValid)
                }
            }
            .sheet(isPresented: $showingTimeZonePicker) {
                TimeZonePickerView { selection in
                    draft.timezone = selection
                }
            }
        }
        .onAppear {
            focusTitle = draft.title.isEmpty
        }

        .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .onChange(of: draft.entryType) { _, newValue in
            switch newValue {
            case .countUp:
                if draft.startDate == nil { draft.startDate = Date() }
                draft.targetDate = nil
            case .countDown:
                if draft.targetDate == nil { draft.targetDate = Date().addingTimeInterval(86_400) }
                draft.startDate = nil
            }
        }
    }

    private func isSelected(_ palette: TrendingCardPalette) -> Bool {
        TrendingCardPalettes.normalize(draft.colorHex) == TrendingCardPalettes.normalize(palette.primaryHex)
    }

    private var isFormValid: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && dateIsValid
    }

    private var dateIsValid: Bool {
        switch draft.entryType {
        case .countUp:
            return draft.startDate != nil
        case .countDown:
            return draft.targetDate != nil
        }
    }

    private func save() {
        onSave(draft)
        dismiss()
    }
}

private extension Binding where Value == Date {
    init(_ source: Binding<Date?>, replacingNilWith fallback: Date) {
        self.init(get: {
            source.wrappedValue ?? fallback
        }, set: { newValue in
            source.wrappedValue = newValue
        })
    }
}

private extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith fallback: String) {
        self.init(get: {
            source.wrappedValue ?? fallback
        }, set: { newValue in
            source.wrappedValue = newValue.isEmpty ? nil : newValue
        })
    }
}
