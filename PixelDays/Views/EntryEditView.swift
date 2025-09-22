import SwiftUI

struct EntryEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    var isNew: Bool
    var onSave: (EntryDraft) -> Void
    var onDelete: (() -> Void)?

    @State private var showingTimeZonePicker = false
    @FocusState private var focusTitle: Bool

    private let colorPalette: [String] = [
        "#6C8BD6", "#00E5FF", "#00E0A4", "#FF2D55", "#FFD966",
        "#F35F5F", "#8E67FF", "#2EC4B6", "#FB6F92", "#1B998B"
    ]

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
                        DatePicker("Start Date", selection: Binding($draft.startDate, replacingNilWith: Date()), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                    } else {
                        DatePicker("Target Date", selection: Binding($draft.targetDate, replacingNilWith: Date()), displayedComponents: [.date, .hourAndMinute])
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colorPalette, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(draft.colorHex == hex ? 0.9 : 0.2), lineWidth: draft.colorHex == hex ? 3 : 1)
                                    )
                                    .onTapGesture { draft.colorHex = hex }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    TextField("Emoji", text: Binding($draft.iconEmoji, replacingNilWith: ""))
                        .font(.system(size: 32))
                        .multilineTextAlignment(.center)
                    TextEditor(text: Binding($draft.notes, replacingNilWith: ""))
                        .frame(minHeight: 80)
                }

                Section("Preview") {
                    EntryCardView(snapshot: EntrySnapshot(draft: draft))
                        .padding(.vertical, 8)
                }

                if !isNew, let onDelete {
                    Section {
                        Button(role: .destructive) {
                            onDelete()
                            dismiss()
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#05080E").ignoresSafeArea())
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
        .onChange(of: draft.entryType) { newValue in
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
