import SwiftUI
import Combine

struct EntryCardView: View {
    let snapshot: EntrySnapshot
    @State private var now: Date = Date()

    private var accent: Color { Color(hex: snapshot.colorHex) }
    private var supportingColor: Color { accent.opacity(0.7) }

    private var dateLine: String {
        guard let date = snapshot.entryType == .countUp ? snapshot.startDate : snapshot.targetDate else { return "--" }
        let formatter = DateFormatters.cardDateFormatter(for: snapshot.timezone)
        return formatter.string(from: date)
    }

    private var dateLabel: String {
        snapshot.entryType == .countUp ? "Start Date" : "Target Date"
    }

    private var days: Int { DayCounter.days(for: snapshot, now: now) }
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    PixelTag(text: snapshot.entryType.label, tint: supportingColor)
                    Text(snapshot.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text("\(dateLabel): \(dateLine)")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    if let emoji = snapshot.iconEmoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 32))
                            .shadow(color: accent.opacity(0.5), radius: 0, x: 1, y: 1)
                    }
                    PixelNumberView(value: days, label: "Days", color: accent)
                }
            }
            if let notes = snapshot.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .background(pixelBackground)
        .overlay(pixelBorder)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onReceive(timer) { value in
            now = value
        }
    }

    private var pixelBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(hex: "#0B0F14").opacity(0.92))
            .overlay(
                LinearGradient(colors: [accent.opacity(0.25), Color.black.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .blendMode(.screen)
            )
    }

    private var pixelBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .inset(by: 1)
            .stroke(accent.opacity(0.6), lineWidth: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .inset(by: 4)
                    .stroke(accent.opacity(0.25), lineWidth: 2)
            )
    }
}

#Preview {
    let snapshot = EntrySnapshot(
        id: UUID(),
        title: "TOEFL",
        entryType: .countDown,
        startDate: nil,
        targetDate: Date().addingTimeInterval(86400 * 32),
        timezone: .current,
        colorHex: "#00E5FF",
        iconEmoji: "🎯",
        notes: "Focus on reading.",
        isPinned: true,
        isArchived: false
    )
    return EntryCardView(snapshot: snapshot)
        .padding()
        .background(Color(hex: "#04070A"))
        .previewLayout(.sizeThatFits)
}
