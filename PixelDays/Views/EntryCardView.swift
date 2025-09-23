import SwiftUI
import Combine
import UIKit

struct EntryCardView: View {
    let snapshot: EntrySnapshot
    @State private var now: Date = Date()
    @Environment(\.colorScheme) private var colorScheme

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var accent: Color { Color(hex: snapshot.colorHex) }
    private var titleColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.8) : Color.black.opacity(0.7)
    }

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
                        .font(.system(size: 19, weight: .black, design: .monospaced))
                        .foregroundStyle(titleColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text("\(dateLabel): \(dateLine)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
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
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(cardBackground)
        .overlay(pixelFrame)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: cardShadowColor, radius: 20, x: 0, y: 10)
        .shadow(color: cardShadowColor.opacity(0.3), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onReceive(timer) { now = $0 }
    }

    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return ZStack {
            // Main gradient background
            shape.fill(cardBaseGradient)

            // Accent glow overlay
            shape.fill(cardGlowOverlay)

            // Inner border
            shape.stroke(cardInnerStroke, lineWidth: 2)
        }
    }

    private var cardBaseGradient: LinearGradient {
        LinearGradient(
            colors: [palette.top, palette.middle, palette.bottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardGlowOverlay: LinearGradient {
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
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(palette.frame, lineWidth: 3)
            .overlay(alignment: .topLeading) { modernCorner(x: -8, y: -8) }
            .overlay(alignment: .topTrailing) { modernCorner(x: 8, y: -8) }
            .overlay(alignment: .bottomLeading) { modernCorner(x: -8, y: 8) }
            .overlay(alignment: .bottomTrailing) { modernCorner(x: 8, y: 8) }
    }

    private func modernCorner(x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(palette.cornerFill)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(pixelCornerBorderColor, lineWidth: 2)
            )
            .shadow(color: palette.cornerFill.opacity(0.5), radius: 4, x: 0, y: 2)
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
            // Dark theme: Deep, rich colors with high contrast
            let baseColor = resolved(uiAccent.adjusted(brightness: -0.2, saturation: 0.3))
            let topColor = resolved(baseColor.adjusted(brightness: 0.1, saturation: -0.1))
            let middleColor = resolved(baseColor.adjusted(brightness: -0.1, saturation: 0.1))
            let bottomColor = resolved(baseColor.adjusted(brightness: -0.3, saturation: 0.2))

            let accentGlow = resolved(uiAccent.adjusted(brightness: 0.2, saturation: 0.4))
            let frameColor = resolved(bottomColor.adjusted(brightness: -0.4, saturation: 0.3))
            let cornerColor = resolved(accentGlow.adjusted(brightness: 0.1, saturation: -0.2))
            let shadowColor = resolved(bottomColor.adjusted(brightness: -0.5, saturation: 0.1))

            top = Color(topColor)
            middle = Color(middleColor)
            bottom = Color(bottomColor)
            glowStart = Color(accentGlow.withAlphaComponent(0.4))
            glowEnd = Color(bottomColor.withAlphaComponent(0.6))
            innerStroke = Color(accentGlow.withAlphaComponent(0.8))
            frame = Color(frameColor.withAlphaComponent(1.0))
            cornerFill = Color(cornerColor)
            cornerStroke = Color(accentGlow.withAlphaComponent(0.9))
            shadow = Color(shadowColor.withAlphaComponent(0.8))
        } else {
            // Light theme: Vibrant, clean colors with soft gradients
            let baseColor = resolved(uiAccent.adjusted(brightness: 0.3, saturation: 0.2))
            let topColor = resolved(baseColor.adjusted(brightness: 0.4, saturation: -0.3))
            let middleColor = resolved(baseColor.adjusted(brightness: 0.2, saturation: -0.1))
            let bottomColor = resolved(baseColor.adjusted(brightness: 0.0, saturation: 0.1))

            let accentGlow = resolved(uiAccent.adjusted(brightness: 0.5, saturation: 0.3))
            let frameColor = resolved(bottomColor.adjusted(brightness: -0.2, saturation: 0.2))
            let cornerColor = resolved(accentGlow.adjusted(brightness: 0.3, saturation: -0.1))
            let shadowColor = resolved(bottomColor.adjusted(brightness: -0.3, saturation: 0.1))

            top = Color(topColor)
            middle = Color(middleColor)
            bottom = Color(bottomColor)
            glowStart = Color(accentGlow.withAlphaComponent(0.5))
            glowEnd = Color(bottomColor.withAlphaComponent(0.4))
            innerStroke = Color(accentGlow.withAlphaComponent(0.7))
            frame = Color(frameColor.withAlphaComponent(0.9))
            cornerFill = Color(cornerColor)
            cornerStroke = Color(UIColor.white.withAlphaComponent(1.0))
            shadow = Color(shadowColor.withAlphaComponent(0.4))
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
