import SwiftUI

struct PixelNumberView: View {
    let value: Int
    var label: String = "Days"
    var color: Color = Color(hex: "#00E0A4")
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 44, weight: .heavy, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
                .foregroundColor(textColor)
            Text(label.uppercased())
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(secondaryTextColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(background)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(backgroundColor)
            .overlay(
                LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(color.opacity(0.65), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) { pixelCorner(x: -4, y: -4) }
            .overlay(alignment: .bottomTrailing) { pixelCorner(x: 4, y: 4) }
            .shadow(color: color.opacity(0.25), radius: 6, x: 0, y: 3)
    }

    private var backgroundColor: Color {
        // Fixed professional dark background for consistent look
        Color.black.opacity(0.85)
    }

    private var gradientColors: [Color] {
        // Fixed professional gradient - consistent regardless of system theme
        [color.opacity(0.6), color.opacity(0.3)]
    }

    private var textColor: Color {
        // Fixed professional color - always use high contrast
        Color.white
    }

    private var secondaryTextColor: Color {
        // Fixed professional color - always use consistent secondary
        Color.white.opacity(0.85)
    }

    private func pixelCorner(x: CGFloat, y: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
            )
            .offset(x: x, y: y)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PixelNumberView(value: 421)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
