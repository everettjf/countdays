import SwiftUI
import Combine
import UIKit

struct EntryCardView: View {
    let snapshot: EntrySnapshot
    @State private var now: Date = Date()
    @Environment(\.colorScheme) private var colorScheme

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var accent: Color { Color(hex: snapshot.colorHex) }

    // Fixed professional colors - not affected by system color scheme
    private var titleColor: Color { palette.primaryTextColor }
    private var secondaryColor: Color { palette.secondaryTextColor }

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
                    PixelTag(text: snapshot.entryType.label,
                             tint: accent,
                             textColorOverride: palette.primaryTextColor)
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
            .stroke(palette.frame, lineWidth: 2.4)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(palette.innerStroke.opacity(0.5), lineWidth: 1)
            )
    }

    private var cardShadowColor: Color {
        palette.shadow
    }

    private var palette: CardPalette {
        CardPalette(accent: accent, accentHex: snapshot.colorHex, colorScheme: colorScheme)
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
    let primaryTextColor: Color
    let secondaryTextColor: Color

    init(accent: Color, accentHex: String, colorScheme: ColorScheme) {
        if let trending = TrendingCardPalettes.palette(for: accentHex) {
            let components = CardPalette.trendingComponents(from: trending)
            top = components.top
            middle = components.middle
            bottom = components.bottom
            glowStart = components.glowStart
            glowEnd = components.glowEnd
            innerStroke = components.innerStroke
            frame = components.frame
            cornerFill = components.cornerFill
            cornerStroke = components.cornerStroke
            shadow = components.shadow
            (primaryTextColor, secondaryTextColor) = CardPalette.recommendedTextColors(for: components.top,
                                                                                       middle: components.middle,
                                                                                       bottom: components.bottom)
            return
        }

        let uiAccent = UIColor(accent)

        func resolved(_ candidate: UIColor?) -> UIColor { candidate ?? uiAccent }

        if colorScheme == .dark {
            // Dark theme: Softer, modern colors with subtle glow
            let baseColor = resolved(uiAccent.adjusted(brightness: 0.1, saturation: 0.3))
            let topColor = resolved(baseColor.adjusted(brightness: 0.4, saturation: 0.1))
            let middleColor = resolved(baseColor.adjusted(brightness: 0.2, saturation: 0.2))
            let bottomColor = resolved(baseColor.adjusted(brightness: 0.0, saturation: 0.25))

            let subtleGlow = resolved(uiAccent.adjusted(brightness: 0.3, saturation: 0.4))
            let frameColor = resolved(subtleGlow.adjusted(brightness: 0.0, saturation: 0.15))
            let cornerColor = resolved(subtleGlow.adjusted(brightness: 0.3, saturation: 0.0))
            let shadowColor = resolved(bottomColor.adjusted(brightness: -0.2, saturation: 0.1))

            top = Color(topColor)
            middle = Color(middleColor)
            bottom = Color(bottomColor)
            glowStart = Color(subtleGlow.withAlphaComponent(0.4))
            glowEnd = Color(bottomColor.withAlphaComponent(0.3))
            innerStroke = Color(subtleGlow.withAlphaComponent(0.6))
            frame = Color(frameColor.withAlphaComponent(0.8))
            cornerFill = Color(cornerColor)
            cornerStroke = Color(subtleGlow.withAlphaComponent(0.7))
            shadow = Color(shadowColor.withAlphaComponent(0.6))
            (primaryTextColor, secondaryTextColor) = CardPalette.recommendedTextColors(for: Color(topColor),
                                                                                       middle: Color(middleColor),
                                                                                       bottom: Color(bottomColor))
        } else {
            // Light theme: Soft, pastel colors with gentle gradients
            let baseColor = resolved(uiAccent.adjusted(brightness: 0.6, saturation: 0.25))
            let topColor = resolved(baseColor.adjusted(brightness: 0.2, saturation: -0.15))
            let middleColor = resolved(baseColor.adjusted(brightness: 0.1, saturation: 0.05))
            let bottomColor = resolved(baseColor.adjusted(brightness: 0.0, saturation: 0.15))

            let softGlow = resolved(uiAccent.adjusted(brightness: 0.4, saturation: 0.3))
            let frameColor = resolved(softGlow.adjusted(brightness: 0.0, saturation: 0.2))
            let cornerColor = resolved(softGlow.adjusted(brightness: 0.3, saturation: 0.1))
            let shadowColor = resolved(bottomColor.adjusted(brightness: -0.15, saturation: 0.1))

            top = Color(topColor)
            middle = Color(middleColor)
            bottom = Color(bottomColor)
            glowStart = Color(softGlow.withAlphaComponent(0.4))
            glowEnd = Color(bottomColor.withAlphaComponent(0.3))
            innerStroke = Color(softGlow.withAlphaComponent(0.5))
            frame = Color(frameColor.withAlphaComponent(0.7))
            cornerFill = Color(cornerColor)
            cornerStroke = Color(UIColor.white.withAlphaComponent(0.8))
            shadow = Color(shadowColor.withAlphaComponent(0.3))
            (primaryTextColor, secondaryTextColor) = CardPalette.recommendedTextColors(for: Color(topColor),
                                                                                       middle: Color(middleColor),
                                                                                       bottom: Color(bottomColor))
        }
    }

    private static func trendingComponents(from palette: TrendingCardPalette) -> (top: Color,
                                                                                middle: Color,
                                                                                bottom: Color,
                                                                                glowStart: Color,
                                                                                glowEnd: Color,
                                                                                innerStroke: Color,
                                                                                frame: Color,
                                                                                cornerFill: Color,
                                                                                cornerStroke: Color,
                                                                                shadow: Color,
                                                                                primaryTextColor: Color,
                                                                                secondaryTextColor: Color) {
        func uiColor(for hex: String) -> UIColor {
            UIColor(Color(hex: hex))
        }

        let colors = palette.colors.map(uiColor(for:))
        let fallback = UIColor(Color(hex: "#606C38"))

        func paletteColor(at index: Int, fallback fallbackColor: UIColor) -> UIColor {
            colors.indices.contains(index) ? colors[index] : fallbackColor
        }

        let topColor = paletteColor(at: 0, fallback: fallback)
        let midColor = paletteColor(at: 2, fallback: topColor)
        let bottomColor = colors.last ?? midColor
        let glowStartColor = paletteColor(at: 1, fallback: topColor)
        let glowEndColor = paletteColor(at: 3, fallback: bottomColor)

        let topSwiftColor = Color(topColor)
        let midSwiftColor = Color(midColor)
        let bottomSwiftColor = Color(bottomColor)
        let textColors = CardPalette.recommendedTextColors(for: topSwiftColor,
                                                          middle: midSwiftColor,
                                                          bottom: bottomSwiftColor)

        return (
            top: topSwiftColor,
            middle: midSwiftColor,
            bottom: bottomSwiftColor,
            glowStart: Color(glowStartColor.withAlphaComponent(0.55)),
            glowEnd: Color(glowEndColor.withAlphaComponent(0.35)),
            innerStroke: Color(glowStartColor.withAlphaComponent(0.65)),
            frame: Color(glowEndColor.withAlphaComponent(0.7)),
            cornerFill: Color(midColor),
            cornerStroke: Color(topColor.withAlphaComponent(0.75)),
            shadow: Color(bottomColor.withAlphaComponent(0.4)),
            primaryTextColor: textColors.0,
            secondaryTextColor: textColors.1
        )
    }

    static func recommendedTextGradient(for top: Color, middle: Color, bottom: Color) -> LinearGradient {
        let colors = recommendedTextColors(for: top, middle: middle, bottom: bottom)
        return LinearGradient(colors: [colors.0, colors.1], startPoint: .top, endPoint: .bottom)
    }

    private static func recommendedTextColors(for top: Color, middle: Color, bottom: Color) -> (Color, Color) {
        let luminance = averageLuminance(colors: [top, middle, bottom])
        if luminance > 0.6 {
            return (
                Color.black.opacity(0.9),
                Color.black.opacity(0.68)
            )
        } else {
            return (
                Color.white,
                Color.white.opacity(0.78)
            )
        }
    }

    private static func averageLuminance(colors: [Color]) -> CGFloat {
        let luminances = colors.compactMap { UIColor($0).relativeLuminance }
        guard !luminances.isEmpty else { return 0.5 }
        let sum = luminances.reduce(0, +)
        return sum / CGFloat(luminances.count)
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

private extension UIColor {
    var relativeLuminance: CGFloat? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        func adjusted(_ value: CGFloat) -> CGFloat {
            value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        let r = adjusted(red)
        let g = adjusted(green)
        let b = adjusted(blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
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
        colorHex: TrendingCardPalettes.defaultHex,
        iconEmoji: "🌞",
        notes: "Prep campaign materials and shoot bright imagery.",
        isPinned: true,
        isArchived: false
    )
    return EntryCardView(snapshot: snapshot)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
