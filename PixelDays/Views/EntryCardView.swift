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
        .shadow(color: cardShadowColor, radius: 12, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onReceive(timer) { now = $0 }
    }

    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return shape
            .fill(cardBaseGradient)
            .overlay(shape.fill(cardNoiseOverlay))
            .overlay(shape.stroke(cardInnerStroke, lineWidth: 1))
    }

    private var cardBaseGradient: LinearGradient {
        LinearGradient(
            colors: [palette.top, palette.middle, palette.bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardNoiseOverlay: LinearGradient {
        LinearGradient(
            colors: [palette.glowStart, palette.glowEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardInnerStroke: Color {
        palette.innerStroke
    }

    private var pixelFrame: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(palette.frame, lineWidth: 2)
            .overlay(alignment: .topLeading) { pixelCorner(x: -6, y: -6) }
            .overlay(alignment: .topTrailing) { pixelCorner(x: 6, y: -6) }
            .overlay(alignment: .bottomLeading) { pixelCorner(x: -6, y: 6) }
            .overlay(alignment: .bottomTrailing) { pixelCorner(x: 6, y: 6) }
    }

    private func pixelCorner(x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(palette.cornerFill)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .stroke(pixelCornerBorderColor, lineWidth: 1)
            )
            .offset(x: x, y: y)
    }

    private var pixelCornerBorderColor: Color {
        palette.cornerStroke
    }

    private var cardShadowColor: Color {
        palette.shadow
    }

    private var palette: CardPalette {
        CardPalette(accent: accent, colorScheme: colorScheme)
    }
}

private struct CardPalette {
    let top: Color
    let middle: Color
    let bottom: Color
    let glowStart: Color
    let glowEnd: Color
    let innerStroke: Color
    let frame: Color
    let cornerFill: Color
    let cornerStroke: Color
    let shadow: Color

    init(accent: Color, colorScheme: ColorScheme) {
        let uiAccent = UIColor(accent)

        func resolved(_ candidate: UIColor?) -> UIColor { candidate ?? uiAccent }

        if colorScheme == .dark {
            let topColor = resolved(uiAccent.adjusted(brightness: 0.34, saturation: -0.32))
            let middleColor = resolved(uiAccent.adjusted(brightness: 0.14, saturation: -0.2))
            let bottomColor = resolved(uiAccent.adjusted(brightness: -0.08, saturation: -0.1))

            let haloStart = resolved(topColor.adjusted(brightness: 0.08, saturation: -0.22))
            let haloEnd = resolved(bottomColor.adjusted(brightness: -0.1, saturation: 0.04))
            let frameColor = resolved(bottomColor.adjusted(brightness: -0.16, saturation: -0.08))
            let cornerColor = resolved(topColor.adjusted(brightness: 0.04, saturation: -0.16))
            let shadowColor = resolved(bottomColor.adjusted(brightness: -0.14, saturation: -0.12))

            top = Color(topColor)
            middle = Color(middleColor)
            bottom = Color(bottomColor)
            glowStart = Color(haloStart.withAlphaComponent(0.38))
            glowEnd = Color(haloEnd.withAlphaComponent(0.5))
            innerStroke = Color(topColor.withAlphaComponent(0.28))
            frame = Color(frameColor.withAlphaComponent(0.64))
            cornerFill = Color(cornerColor)
            cornerStroke = Color(UIColor.white.withAlphaComponent(0.24))
            shadow = Color(shadowColor.withAlphaComponent(0.48))
        } else {
            let topColor = resolved(uiAccent.adjusted(brightness: 0.26, saturation: -0.36))
            let middleColor = resolved(uiAccent.adjusted(brightness: 0.08, saturation: -0.22))
            let bottomColor = resolved(uiAccent.adjusted(brightness: -0.2, saturation: 0.02))

            let haloStart = resolved(topColor.adjusted(brightness: 0.12, saturation: -0.28))
            let haloEnd = resolved(bottomColor.adjusted(brightness: -0.12, saturation: 0.05))
            let frameColor = resolved(bottomColor.adjusted(brightness: -0.18, saturation: -0.06))
            let cornerColor = resolved(topColor.adjusted(brightness: 0.08, saturation: -0.2))
            let shadowColor = resolved(bottomColor.adjusted(brightness: -0.1, saturation: -0.12))

            top = Color(topColor)
            middle = Color(middleColor)
            bottom = Color(bottomColor)
            glowStart = Color(haloStart.withAlphaComponent(0.5))
            glowEnd = Color(haloEnd.withAlphaComponent(0.26))
            innerStroke = Color(topColor.withAlphaComponent(0.32))
            frame = Color(frameColor.withAlphaComponent(0.52))
            cornerFill = Color(cornerColor)
            cornerStroke = Color(UIColor.white.withAlphaComponent(0.74))
            shadow = Color(shadowColor.withAlphaComponent(0.22))
        }
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

    func blended(withFraction fraction: CGFloat, of color: UIColor) -> UIColor {
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)

        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r = r1 + (r2 - r1) * fraction
        let g = g1 + (g2 - g1) * fraction
        let b = b1 + (b2 - b1) * fraction
        let a = a1 + (a2 - a1) * fraction

        return UIColor(red: r, green: g, blue: b, alpha: a)
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
