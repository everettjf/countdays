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
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(background)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(backgroundGradient)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderGradient, lineWidth: 1.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(highlightColor, lineWidth: 1)
                    .blur(radius: 1)
                    .opacity(0.6)
            )
            .shadow(color: color.opacity(0.22), radius: 12, x: 0, y: 6)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(colorScheme == .dark ? 0.45 : 0.35),
                color.opacity(colorScheme == .dark ? 0.25 : 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(0.65),
                color.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var textColor: Color {
        Color.white
    }

    private var secondaryTextColor: Color {
        Color.white.opacity(0.75)
    }

    private var highlightColor: Color {
        color.opacity(colorScheme == .dark ? 0.45 : 0.35)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PixelNumberView(value: 421)
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        }
