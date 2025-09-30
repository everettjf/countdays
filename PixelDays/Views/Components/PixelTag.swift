import SwiftUI

struct PixelTag: View {
    let text: String
    var tint: Color = Color(hex: "#00E5FF")
    var textColorOverride: Color?

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .kerning(1.3)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .foregroundColor(textColor)
            .background(tagBackground)
    }

    private var tagBackground: some View {
        Capsule(style: .continuous)
            .fill(backgroundGradient)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderGradient, lineWidth: 1.1)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(highlightGradient, lineWidth: 0.9)
                    .blur(radius: 0.6)
                    .opacity(0.55)
            )
            .shadow(color: tint.opacity(0.12), radius: 8, x: 0, y: 3)
    }

    private var textColor: Color {
        textColorOverride ?? PixelTag.recommendedTextColor(for: [topTint, midTint, baseTint])
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                topTint.opacity(0.85),
                midTint.opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                topTint.opacity(0.55),
                baseTint.opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                topTint.opacity(0.4),
                midTint.opacity(0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var topTint: Color { tint }
    private var midTint: Color { tint.opacity(0.6) }
private var baseTint: Color { tint.opacity(0.4) }

    private static func recommendedTextColor(for colors: [Color]) -> Color {
        let luminance = averageLuminance(colors: colors)
        if luminance > 0.6 {
            return Color.black.opacity(0.9)
        } else {
            return Color.white
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
    PixelTag(text: "Cumulative")
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
