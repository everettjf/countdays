import SwiftUI

struct TextImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    let onImport: (String) -> Void
    let onCancel: () -> Void

    init(initialText: String = "", onImport: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _text = State(initialValue: initialText)
        self.onImport = onImport
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Paste your JSON below. Make sure it follows the CountMyDays schema with { \"version\": 1, \"entries\": [...] }.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .border(Color.secondary, width: 1)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(minHeight: 240)

                Spacer()
            }
            .padding()
            .navigationTitle("Paste JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onImport(text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
