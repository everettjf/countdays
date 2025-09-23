import SwiftUI
import Combine
import UIKit

struct EntryCardView: View {
    let snapshot: EntrySnapshot
    @State private var now: Date = Date()
    @Environment(\.colorScheme) private var colorScheme

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var accent: Color { Color(hex: snapshot.colorHex) }
    private var titleColor: Color { Color(.label) }
    private var secondaryColor: Color { Color(.secondaryLabel) }

    private var dateLine: String {
        guard let date = snapshot.entryType == .countUp ? snapshot.startDate : snapshot.targetDate else { return "--" }
        let formatter = DateFormatters.cardDateFormatter(for: snapshot.timezone)
        return formatter.string(from: date)
    }

    private var dateLabel: String {
        snapshot.entryType == .countUp ? "Start Date" : "Target Date"
    }

    private var days: Int { DayCounter.days(for: snapshot, now: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    PixelTag(text: snapshot.entryType.label, tint: accent)
                    Text(snapshot.title)
                        .font(.system(size: 19, weight: .heavy, design: .rounded))
                        .foregroundStyle(titleColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("\(dateLabel): \(dateLine)")
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(secondaryColor)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 6) {
                    if let emoji = snapshot.iconEmoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 32))
                            .shadow(color: accent.opacity(0.3), radius: 0, x: 1, y: 1)
                    }
                    PixelNumberView(value: days, label: "Days", color: accent)
                }
            }
            if let notes = snapshot.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay(pixelFrame)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: accent.opacity(0.18), radius: 12, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onReceive(timer) { now = $0 }
    }

    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return shape
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                shape
                    .fill(highlightGradient)
            )
            .overlay(
                shape
                    .fill(glowOverlay)
            )
    }

    private var gradientColors: [Color] {
        [
            accentAdjusted(brightness: lightnessBoost + 0.18, saturation: -0.16),
            accentAdjusted(brightness: lightnessBoost + 0.04),
            accentAdjusted(brightness: lightnessBoost - 0.14, saturation: 0.12)
        ]
    }

    private var highlightGradient: RadialGradient {
        RadialGradient(
            colors: [
                accentAdjusted(brightness: lightnessBoost + 0.28, saturation: -0.28)
                    .opacity(colorScheme == .dark ? 0.36 : 0.46),
                Color.clear
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: 220
        )
    }

    private var glowOverlay: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.22),
                Color.white.opacity(0.0),
                accentAdjusted(brightness: lightnessBoost - 0.22, saturation: 0.18)
                    .opacity(colorScheme == .dark ? 0.35 : 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var lightnessBoost: CGFloat {
        colorScheme == .dark ? -0.06 : 0.08
    }

    private var pixelFrame: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(frameColor, lineWidth: 2)
            .overlay(alignment: .topLeading) { pixelCorner(x: -6, y: -6) }
            .overlay(alignment: .topTrailing) { pixelCorner(x: 6, y: -6) }
            .overlay(alignment: .bottomLeading) { pixelCorner(x: -6, y: 6) }
            .overlay(alignment: .bottomTrailing) { pixelCorner(x: 6, y: 6) }
    }

    private var frameColor: Color {
        accentAdjusted(brightness: lightnessBoost - 0.22, saturation: 0.08)
            .opacity(colorScheme == .dark ? 0.65 : 0.48)
    }

    private func pixelCorner(x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(accentAdjusted(brightness: 0.08))
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(pixelCornerBorderColor, lineWidth: 1)
            )
            .offset(x: x, y: y)
    }

    private var pixelCornerBorderColor: Color {
        Color.white.opacity(colorScheme == .dark ? 0.32 : 0.68)
    }

    private func accentAdjusted(brightness: CGFloat = 0, saturation: CGFloat = 0) -> Color {
        guard let adjusted = UIColor(accent).adjusted(brightness: brightness, saturation: saturation) else {
            return accent
        }
        return Color(adjusted)
    }
}

private extension UIColor {
    func adjusted(brightness: CGFloat, saturation: CGFloat) -> UIColor? {
        var hue: CGFloat = 0
        var sat: CGFloat = 0
        var bright: CGFloat = 0
        var alpha: CGFloat = 0
        guard getHue(&hue, saturation: &sat, brightness: &bright, alpha: &alpha) else {
            return nil
        }
        let clampedBrightness = min(max(bright + brightness, 0), 1)
        let clampedSaturation = min(max(sat + saturation, 0), 1)
        return UIColor(hue: hue, saturation: clampedSaturation, brightness: clampedBrightness, alpha: alpha)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let snapshot = EntrySnapshot(
        id: UUID(),
        title: "Summer Launch",
        entryType: .countDown,
        startDate: nil,
        targetDate: Date().addingTimeInterval(86400 * 32),
        timezone: .current,
        colorHex: "#FF8A65",
        iconEmoji: "🌞",
        notes: "Prep campaign materials and shoot bright imagery.",
        isPinned: true,
        isArchived: false
    )
    return EntryCardView(snapshot: snapshot)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
